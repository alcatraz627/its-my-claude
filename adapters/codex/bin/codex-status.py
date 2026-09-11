#!/usr/bin/env python3
"""Where is Codex right now. One screen, read-only.

    codex-gcc status [--hours N] [--json]

Answers the question a Claude session or the owner otherwise needs four
commands for: is a Codex process alive, which seats ran recently, where each
one is (cwd, mid-turn or finished, last activity, last thing it said or ran),
whether it is on claude-ipc, and whether its gcc outbox has anything pending.

Sources, each named in the output so a reader knows what was measured:
  processes   pgrep -x codex (+ lsof for the cwd)
  rollouts    ~/.codex/sessions/**/rollout-*.jsonl modified in the window;
              session_meta for identity, the event stream for turn state
  claude-ipc  `claude-ipc peers --by-session` rows whose alias starts with cx-
  outbox      /tmp/codex-gcc/outbox/<sid>.jsonl (pending), .inflight, receipts
"""
import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

CODEX_HOME = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
OUTBOX = Path(os.environ.get("CODEX_GCC_OUTBOX", "/tmp/codex-gcc/outbox"))
NOW = time.time()


def age(ts):
    d = int(NOW - ts)
    if d < 60:
        return f"{d}s"
    if d < 3600:
        return f"{d // 60}m"
    if d < 86400:
        return f"{d // 3600}h{(d % 3600) // 60:02d}"
    return f"{d // 86400}d"


def run(cmd, timeout=8):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def processes():
    out = []
    for pid in run(["pgrep", "-x", "codex"]).split():
        args = run(["ps", "-o", "args=", "-p", pid]).strip()
        cwd = ""
        for line in run(["lsof", "-a", "-p", pid, "-d", "cwd", "-Fn"]).splitlines():
            if line.startswith("n"):
                cwd = line[1:]
        out.append({"pid": int(pid), "args": args[:120], "cwd": cwd})
    return out


def rollout_state(path):
    """Identity from session_meta; turn state from the tail of the event stream."""
    meta, last_evt, last_said, last_cmd, tools, turns_open = None, None, None, None, 0, 0
    try:
        with path.open(encoding="utf-8", errors="replace") as fh:
            for line in fh:
                try:
                    rec = json.loads(line)
                except json.JSONDecodeError:
                    continue
                t, p = rec.get("type"), rec.get("payload", {})
                if t == "session_meta" and meta is None:
                    meta = {
                        "id": p.get("id") or p.get("session_id"),
                        "started": p.get("timestamp"),
                        "cwd": p.get("cwd"),
                        "source": p.get("source"),
                        "originator": p.get("originator"),
                    }
                elif t == "event_msg":
                    et = p.get("type")
                    if et == "task_started":
                        turns_open += 1
                    elif et == "task_complete":
                        turns_open = max(0, turns_open - 1)
                    if et not in ("token_count",):
                        last_evt = (rec.get("timestamp"), et)
                elif t == "response_item":
                    pt = p.get("type")
                    if pt in ("custom_tool_call", "function_call"):
                        tools += 1
                        arg = p.get("input") or p.get("arguments") or ""
                        if isinstance(arg, str):
                            try:
                                arg = json.loads(arg)
                            except ValueError:
                                pass
                        if isinstance(arg, dict):
                            arg = arg.get("cmd") or arg.get("command") or json.dumps(arg)
                        last_cmd = str(arg).strip().replace("\n", " ")[:100]
                    elif pt == "message" and p.get("role") == "assistant":
                        texts = [c.get("text", "") for c in p.get("content", []) if c.get("type") == "output_text"]
                        s = " ".join(texts).strip().replace("\n", " ")
                        if s:
                            last_said = s[:120]
    except OSError:
        return None
    if not meta:
        return None
    meta.update({
        "file": str(path),
        "modified_age": age(path.stat().st_mtime),
        "state": "in a turn" if turns_open > 0 else ("no turn yet" if last_evt is None else "finished"),
        "last_event": last_evt[1] if last_evt else None,
        "tool_calls": tools,
        "last_command": last_cmd,
        "last_said": last_said,
    })
    return meta


def rollouts(hours):
    cutoff = NOW - hours * 3600
    rows = []
    sessions = CODEX_HOME / "sessions"
    if not sessions.is_dir():
        return rows
    for p in sessions.rglob("rollout-*.jsonl"):
        try:
            if p.stat().st_mtime < cutoff:
                continue
        except OSError:
            continue
        st = rollout_state(p)
        if st:
            rows.append(st)
    rows.sort(key=lambda r: Path(r["file"]).stat().st_mtime, reverse=True)
    return rows


def ipc_peers():
    out = run(["claude-ipc", "peers", "--by-session"])
    try:
        peers = json.loads(out).get("peers", [])
    except ValueError:
        return None  # broker down or CLI absent: say so, never fabricate an empty roster
    return {
        p.get("sessionId"): {"alias": ",".join(p.get("aliases", [])), "status": p.get("status"), "since": p.get("sinceSeenS")}
        for p in peers
        if any(a.startswith("cx-") for a in p.get("aliases", []))
    }


def outbox():
    rows = {}
    if not OUTBOX.is_dir():
        return rows
    for f in OUTBOX.iterdir():
        name = f.name
        if name.endswith(".receipts.jsonl"):
            sid = name[: -len(".receipts.jsonl")]
            rows.setdefault(sid, {})["receipts"] = sum(1 for _ in f.open())
        elif ".inflight." in name:
            sid = name.split(".inflight.")[0]
            rows.setdefault(sid, {})["inflight"] = rows.get(sid, {}).get("inflight", 0) + 1
        elif name.endswith(".jsonl"):
            sid = name[: -len(".jsonl")]
            rows.setdefault(sid, {})["pending"] = sum(1 for _ in f.open())
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--hours", type=float, default=24, help="rollout window (default 24)")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    procs = processes()
    rolls = rollouts(a.hours)
    peers = ipc_peers()
    ob = outbox()

    if a.json:
        json.dump({"processes": procs, "rollouts": rolls, "ipc": peers, "outbox": ob}, sys.stdout, indent=2)
        print()
        return

    print(f"codex processes: {len(procs)}" + ("" if procs else " (none alive)"))
    for p in procs:
        print(f"  pid {p['pid']}  cwd {p['cwd'] or '?'}  {p['args']}")

    print(f"\nseats in the last {a.hours:g}h (rollouts): {len(rolls)}")
    for r in rolls:
        sid8 = (r["id"] or "?")[:8]
        ipc = "ipc: not registered"
        if peers is None:
            ipc = "ipc: broker unreachable"
        elif r["id"] in peers:
            q = peers[r["id"]]
            ipc = f"ipc: {q['alias']} {q['status']} (seen {age(NOW - (q['since'] or 0))} ago)"
        ob_s = ""
        if r["id"] in ob:
            o = ob[r["id"]]
            ob_s = f"  outbox: {o.get('pending', 0)} pending, {o.get('inflight', 0)} inflight, {o.get('receipts', 0)} receipts"
        print(f"  {sid8}  {r['state']:<11} last activity {r['modified_age']:>5} ago  {r['source'] or '?'}/{r['originator'] or '?'}  {r['cwd']}")
        print(f"          {ipc}{ob_s}  tool calls: {r['tool_calls']}  last event: {r['last_event']}")
        if r["last_command"]:
            print(f"          last ran:  {r['last_command']}")
        if r["last_said"]:
            print(f"          last said: {r['last_said']}")
    if not rolls:
        print("  (none)")

    strays = [s for s in ob if s not in {r["id"] for r in rolls} and (ob[s].get("pending") or ob[s].get("inflight"))]
    if strays:
        print("\noutbox entries with no recent rollout (stale or ephemeral seats):")
        for s in strays:
            print(f"  {s[:8]}  {ob[s]}")
    print("\nbasis: pgrep -x codex · ~/.codex/sessions rollouts (mtime) · claude-ipc peers (heartbeat at turn end, not a process check) · /tmp/codex-gcc/outbox")


if __name__ == "__main__":
    main()
