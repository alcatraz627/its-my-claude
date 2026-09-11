#!/usr/bin/env python3
"""May a Codex seat be dispatched right now? The Codex-side sibling of
scripts/cron/usage-gate.sh, same output contract.

Prints one TAB-separated line, VERDICT<TAB>detail, and exits:
  0  PASS   headroom in every window the account reports, or an honest UNKNOWN
            (a broken read must never silently kill the seats; the detail says so)
  1  GATED  a window's usedPercent is at or above the threshold; do not dispatch

Reads the numbers from Codex itself: spawns `codex app-server` on stdio, sends
the JSON-RPC handshake (initialize, initialized) and `account/rateLimits/read`,
and parses the reply. There is no CLI flag that prints them (verified against
the 0.153.4 manual, App Server section). The last good reading is cached at
$CODEX_GATE_CACHE (default ~/.claude/adapters/codex/state/limits.json) so hooks
that fire on every seat start can answer from the cache within its TTL instead
of spawning an app-server each time.

Env:
  CODEX_GATE_PCT         used-percent threshold, default 75 (owner default:
                         stand down at 25% remaining, ruled 2026-09-11)
  CODEX_GATE_CACHE       cache path
  CODEX_GATE_MAX_AGE_S   cache TTL, default 600
  CODEX_GATE_TIMEOUT_S   app-server round trip cap, default 20
  ~/.claude/.no-codex-usage-gate   owner mute (machine-wide, listed by muted-gates)
Flags:  --fresh (ignore cache)  --json (print the raw rateLimits object)
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
PCT = int(os.environ.get("CODEX_GATE_PCT", "75") or 75)
CACHE = Path(os.environ.get("CODEX_GATE_CACHE", HOME / ".claude/adapters/codex/state/limits.json"))
MAX_AGE = int(os.environ.get("CODEX_GATE_MAX_AGE_S", "600") or 600)
TIMEOUT = int(os.environ.get("CODEX_GATE_TIMEOUT_S", "20") or 20)
MUTE = HOME / ".claude/.no-codex-usage-gate"


def say(verdict, detail, code):
    print(f"{verdict}\t{detail}")
    sys.exit(code)


def read_live():
    """One app-server round trip. Returns the rateLimits result dict or raises."""
    proc = subprocess.Popen(
        ["codex", "app-server", "--listen", "stdio://"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
    )
    msgs = [
        {"method": "initialize", "id": 0, "params": {"clientInfo": {"name": "gcc_codex_usage_gate", "title": "gcc codex usage gate", "version": "1.0.0"}}},
        {"method": "initialized", "params": {}},
        {"method": "account/rateLimits/read", "id": 1},
    ]
    try:
        for m in msgs:
            proc.stdin.write(json.dumps(m) + "\n")
        proc.stdin.flush()
        deadline = time.time() + TIMEOUT
        while time.time() < deadline:
            line = proc.stdout.readline()
            if not line:
                break
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            if rec.get("id") == 1:
                if "error" in rec:
                    raise RuntimeError(f"rpc error: {rec['error']}")
                return rec.get("result", {})
        raise TimeoutError(f"no rateLimits reply within {TIMEOUT}s")
    finally:
        try:
            proc.kill()
        except OSError:
            pass


def windows(result):
    """Yield (label, usedPercent, resetsAt) for every window the account reports."""
    seen = []
    def add(label, w):
        if not isinstance(w, dict):
            return
        try:
            pct = int(float(w.get("usedPercent")))  # a numeric string counts too (validator minor)
        except (TypeError, ValueError):
            return
        seen.append((label, pct, w.get("resetsAt"), w.get("windowDurationMins")))
    rl = result.get("rateLimits") or {}
    add("primary", rl.get("primary")); add("secondary", rl.get("secondary"))
    for lid, obj in (result.get("rateLimitsByLimitId") or {}).items():
        if lid == rl.get("limitId"):
            continue
        add(f"{lid}.primary", (obj or {}).get("primary")); add(f"{lid}.secondary", (obj or {}).get("secondary"))
    return seen


def main():
    fresh = "--fresh" in sys.argv
    want_json = "--json" in sys.argv
    if MUTE.exists():
        say("PASS", f"MUTED: {MUTE} present (owner mute)", 0)
    result, source = None, "cache"
    if not fresh and CACHE.exists() and time.time() - CACHE.stat().st_mtime < MAX_AGE:
        try:
            result = json.loads(CACHE.read_text())
        except (OSError, ValueError):
            result = None
    if result is None:
        source = "live"
        try:
            result = read_live()
            CACHE.parent.mkdir(parents=True, exist_ok=True)
            CACHE.write_text(json.dumps(result))
        except Exception as e:  # noqa: BLE001 - any failure is an honest UNKNOWN
            say("PASS", f"UNKNOWN: could not read rate limits ({type(e).__name__}: {e})", 0)
    if want_json:
        print(json.dumps(result, indent=2))
    ws = windows(result)
    if not ws:
        say("PASS", f"UNKNOWN: no usedPercent windows in reply ({source})", 0)
    detail = " ".join(f"{l}={p}%" + (f"/{d}m" if d else "") for l, p, _, d in ws)
    reached = (result.get("rateLimits") or {}).get("rateLimitReachedType")
    hot = [l for l, p, _, _ in ws if p >= PCT]
    if hot or reached:
        say("GATED", f"{detail} (threshold {PCT}% used{', reached=' + str(reached) if reached else ''}; {source})", 1)
    say("PASS", f"{detail} ({source})", 0)


if __name__ == "__main__":
    main()
