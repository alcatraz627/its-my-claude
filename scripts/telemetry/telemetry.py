#!/usr/bin/env python3
"""Session telemetry: where the tokens went, what sub-agents cost, and whether
returning to an idle session found its cache warm or cold.

Reads Claude Code transcripts (~/.claude/projects/*/<session>.jsonl and their
subagents/ folders) and writes one row per session per day to
~/.claude/telemetry/sessions.jsonl. Rows for a day are rebuilt on every run, so
re-running is safe. The weekly gcc session reads `telemetry report`.

A "return" is the owner's next prompt after 45+ idle minutes. It is warm when
the reply mostly read the prompt cache, cold when it mostly re-created it. Turns
started by a "[keepwarm]" prompt are keep-warm wakes; a return after wakes that
found the cache warm counts as saved.

Usage:
  telemetry.py collect [--days N]        rebuild the last N days (default 2)
  telemetry.py report  [--days N] [--json]
"""
import argparse
import datetime as dt
import glob
import json
import os
import sys
from collections import defaultdict

HOME = os.path.expanduser("~")
PROJECTS = os.path.join(HOME, ".claude", "projects")
OUT_DIR = os.path.join(HOME, ".claude", "telemetry")
OUT = os.path.join(OUT_DIR, "sessions.jsonl")
RETURN_GAP_MIN = 45
KEEPWARM = "[keepwarm]"


def local_day(ts):
    t = dt.datetime.strptime(ts[:19], "%Y-%m-%dT%H:%M:%S").replace(tzinfo=dt.timezone.utc).astimezone()
    return t.strftime("%Y-%m-%d"), t


def prompt_text(o):
    """The owner's typed text for a user record, or None for tool results and meta."""
    if o.get("type") != "user" or o.get("isMeta") or o.get("isSidechain"):
        return None
    c = (o.get("message") or {}).get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        texts = [b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text"]
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
            return None
        return "\n".join(texts) if texts else None
    return None


def usage_of(o):
    u = (o.get("message") or {}).get("usage") or {}
    return (u.get("input_tokens") or 0, u.get("output_tokens") or 0,
            u.get("cache_read_input_tokens") or 0, u.get("cache_creation_input_tokens") or 0)


def new_row(day, sid, project):
    return {"day": day, "session": sid, "project": project, "models": defaultdict(int), "turns": 0,
            "tokens": {"input": 0, "output": 0, "cache_read": 0, "cache_created": 0},
            "subagents": {"count": 0, "tokens": 0, "by_type": defaultdict(lambda: {"count": 0, "tokens": 0}),
                          "by_model": defaultdict(int)},
            "returns": [], "keepwarm": {"wakes": 0, "tokens": 0, "wasted_wakes": 0}}


def scan_session(path, days):
    """Rows for one session transcript, keyed by local day."""
    sid = os.path.basename(path)[:-6]
    project = os.path.basename(os.path.dirname(path))
    rows = {}
    last_real = None        # timestamp of the last assistant turn not started by a wake
    wakes_since = 0
    in_wake = False
    pending_return = None   # a return waiting for its first assistant usage
    for line in open(path, errors="replace"):
        try:
            o = json.loads(line)
        except ValueError:
            continue
        ts = o.get("timestamp")
        if not ts:
            continue
        try:
            day, t = local_day(ts)
        except ValueError:
            continue
        if o.get("cwd"):
            project = o["cwd"].replace(HOME, "~")   # the folder name mangles dashes; cwd does not
            for r in rows.values():
                r["project"] = project
        text = prompt_text(o)
        if text is not None:
            if text.lstrip().startswith(KEEPWARM):
                in_wake = True
                wakes_since += 1
                if day in days:
                    rows.setdefault(day, new_row(day, sid, project))["keepwarm"]["wakes"] += 1
                continue
            idle = (t - last_real).total_seconds() / 60 if last_real else 0
            if idle >= RETURN_GAP_MIN and day in days:
                pending_return = {"at": t.strftime("%H:%M"), "idle_min": int(idle), "wakes": wakes_since}
            in_wake = False
            wakes_since = 0
            continue
        if o.get("type") != "assistant":
            continue
        i, out, cr, cc = usage_of(o)
        if not (i or out or cr or cc):
            continue
        if day in days:
            r = rows.setdefault(day, new_row(day, sid, project))
            r["turns"] += 1
            r["models"][(o.get("message") or {}).get("model") or "?"] += 1
            for k, v in (("input", i), ("output", out), ("cache_read", cr), ("cache_created", cc)):
                r["tokens"][k] += v
            if in_wake:
                r["keepwarm"]["tokens"] += i + out + cr + cc
            if pending_return is not None:
                warm = cc <= 0.2 * (cr + cc)
                verdict = ("saved" if pending_return["wakes"] else "warm") if warm else \
                          ("missed" if pending_return["wakes"] else "cold")
                pending_return.update({"warm": warm, "recached": cc, "read": cr, "verdict": verdict})
                r["returns"].append(pending_return)
                pending_return = None
        if not in_wake:
            last_real = t
    if wakes_since and rows:     # wakes at the end with no return after them
        last_day = max(rows)
        rows[last_day]["keepwarm"]["wasted_wakes"] += wakes_since
    scan_subagents(os.path.join(os.path.dirname(path), sid, "subagents"), days, rows, sid, project)
    return rows


def scan_subagents(folder, days, rows, sid, project):
    for path in glob.glob(os.path.join(folder, "agent-*.jsonl")):
        meta = {}
        try:
            with open(path[:-6] + ".meta.json") as f:
                meta = json.load(f)
        except (OSError, ValueError):
            pass
        per_day = defaultdict(int)
        for line in open(path, errors="replace"):
            try:
                o = json.loads(line)
            except ValueError:
                continue
            if o.get("type") != "assistant" or not o.get("timestamp"):
                continue
            try:
                day, _ = local_day(o["timestamp"])
            except ValueError:
                continue
            if day in days:
                i, out, cr, cc = usage_of(o)
                per_day[day] += i + 1.25 * cc + 0.1 * cr   # same input-equivalent unit as sessions
        for day, tok in per_day.items():
            r = rows.setdefault(day, new_row(day, sid, project))
            s = r["subagents"]
            s["count"] += 1
            s["tokens"] += tok
            bt = s["by_type"][meta.get("agentType") or "?"]
            bt["count"] += 1
            bt["tokens"] += tok
            s["by_model"][meta.get("model") or "?"] += 1


def cmd_collect(ndays):
    today = dt.date.today()
    days = {(today - dt.timedelta(days=k)).isoformat() for k in range(ndays)}
    cutoff = dt.datetime.combine(today - dt.timedelta(days=ndays), dt.time()).timestamp()
    fresh = []
    for path in glob.glob(os.path.join(PROJECTS, "*", "*.jsonl")):
        try:
            if os.path.getmtime(path) < cutoff:
                continue
            rows = scan_session(path, days)
        except OSError:
            continue
        fresh.extend(rows.values())
    kept = []
    if os.path.exists(OUT):
        for line in open(OUT):
            try:
                o = json.loads(line)
            except ValueError:
                continue
            if o.get("day") not in days:
                kept.append(o)
    os.makedirs(OUT_DIR, exist_ok=True)
    tmp = OUT + ".tmp"
    with open(tmp, "w") as f:
        for o in kept + fresh:
            f.write(json.dumps(o, sort_keys=True) + "\n")
    os.replace(tmp, OUT)
    print("telemetry: %d session-day rows for %s (%d kept from earlier days)"
          % (len(fresh), ", ".join(sorted(days)), len(kept)))
    return 0


def weighted(tok):
    """Input-equivalent cost: cache reads cost 0.1x, cache writes 1.25x."""
    return tok["input"] + 1.25 * tok["cache_created"] + 0.1 * tok["cache_read"]


def summarize(ndays):
    since = (dt.date.today() - dt.timedelta(days=ndays - 1)).isoformat()
    rows = []
    if os.path.exists(OUT):
        for line in open(OUT):
            try:
                o = json.loads(line)
            except ValueError:
                continue
            if o.get("day", "") >= since:
                rows.append(o)
    s = {"days": ndays, "since": since, "sessions": len({r["session"] for r in rows}),
         "by_project": defaultdict(float), "by_model": defaultdict(int), "output_tokens": 0,
         "weighted_input": 0.0, "subagents": {"count": 0, "tokens": 0, "by_type": defaultdict(int)},
         "returns": defaultdict(int), "recached_on_cold": 0,
         "keepwarm": {"wakes": 0, "tokens": 0, "wasted_wakes": 0}}
    for r in rows:
        w = weighted(r["tokens"])
        s["weighted_input"] += w
        s["output_tokens"] += r["tokens"]["output"]
        s["by_project"][r["project"]] += w
        for m, n in r["models"].items():
            s["by_model"][m] += n
        s["subagents"]["count"] += r["subagents"]["count"]
        s["subagents"]["tokens"] += r["subagents"]["tokens"]
        for t, v in r["subagents"]["by_type"].items():
            s["subagents"]["by_type"][t] += v["count"]
        for ret in r["returns"]:
            s["returns"][ret["verdict"]] += 1
            if not ret["warm"]:
                s["recached_on_cold"] += ret["recached"]
        for k in ("wakes", "tokens", "wasted_wakes"):
            s["keepwarm"][k] += r["keepwarm"][k]
    return s


def human(n):
    n = float(n)
    for unit, div in (("B", 1e9), ("M", 1e6), ("k", 1e3)):
        if n >= div:
            return "%.1f%s" % (n / div, unit)
    return "%d" % n


def cmd_report(ndays, as_json):
    s = summarize(ndays)
    if as_json:
        print(json.dumps(s, indent=2, default=dict))
        return 0
    print("Last %d days (since %s): %d sessions" % (ndays, s["since"], s["sessions"]))
    print("  input-equivalent tokens %s, output tokens %s" % (human(s["weighted_input"]), human(s["output_tokens"])))
    print("  top projects: " + ", ".join("%s %s" % (p[:40], human(v))
                                        for p, v in sorted(s["by_project"].items(), key=lambda x: -x[1])[:5]))
    print("  turns by model: " + ", ".join("%s %d" % (m, n) for m, n in sorted(s["by_model"].items(), key=lambda x: -x[1])[:5]))
    sa = s["subagents"]
    print("  sub-agents: %d, %s input-equivalent tokens; by type: %s" % (sa["count"], human(sa["tokens"]),
          ", ".join("%s %d" % kv for kv in sorted(sa["by_type"].items(), key=lambda x: -x[1])[:5]) or "none"))
    r = s["returns"]
    print("  returns after %d+ idle min: %d warm, %d cold (re-cached %s on cold returns)"
          % (RETURN_GAP_MIN, r["warm"] + r["saved"], r["cold"] + r["missed"], human(s["recached_on_cold"])))
    k = s["keepwarm"]
    print("  keep-warm: %d wakes, %s tokens; %d returns saved, %d missed, %d wakes with no return"
          % (k["wakes"], human(k["tokens"]), r["saved"], r["missed"], k["wasted_wakes"]))
    return 0


def main(argv):
    p = argparse.ArgumentParser(prog="telemetry", description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("collect"); c.add_argument("--days", type=int, default=2)
    r = sub.add_parser("report"); r.add_argument("--days", type=int, default=7); r.add_argument("--json", action="store_true")
    a = p.parse_args(argv)
    return cmd_collect(a.days) if a.cmd == "collect" else cmd_report(a.days, a.json)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
