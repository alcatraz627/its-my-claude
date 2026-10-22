#!/usr/bin/env python3
"""One glance at every agent working on this machine, for whoever keeps the fleet going.

Lists each session that wrote to its transcript in the last few hours, with what
it is doing now: working, hibernating until a wake, cut off at the usage limit
(and whether the reset has come and gone without it resuming), or idle. Idle
rows show the end of the last reply, so a stall or a question to the owner is
visible without opening the session. No model call; reads only.

Usage: fleet-watch.py [--hours N] [--json]
"""
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import usage5h  # noqa: E402

WORKING_S = 300          # a transcript written this recently is mid-work


def aliases():
    try:
        out = subprocess.run(["claude-ipc", "peers", "--by-session"], capture_output=True, text=True, timeout=10).stdout
        return {p["sessionId"]: (p.get("aliases") or [""])[0] for p in json.loads(out).get("peers", [])}
    except (OSError, ValueError, subprocess.SubprocessError):
        return {}


def last_reply(transcript):
    for line in reversed(usage5h.tail_lines(transcript, 300000)):
        try:
            o = json.loads(line)
        except ValueError:
            continue
        msg = o.get("message")
        if o.get("type") == "assistant" and isinstance(msg, dict) and isinstance(msg.get("content"), list):
            text = " ".join(b.get("text", "") for b in msg["content"] if isinstance(b, dict) and b.get("type") == "text")
            if text.strip():
                return " ".join(text.split())
    return ""


def first_cwd(transcript):
    try:
        with open(transcript, errors="replace") as f:
            for _ in range(50):
                line = f.readline()
                if not line:
                    break
                try:
                    cwd = json.loads(line).get("cwd")
                except ValueError:
                    continue
                if cwd:
                    return cwd
    except OSError:
        pass
    return ""


def rows(hours):
    now = time.time()
    r = usage5h.reading() or {}
    reset = r.get("reset_epoch")
    names = aliases()
    out = []
    for proj in os.listdir(usage5h.PROJECTS):
        d = os.path.join(usage5h.PROJECTS, proj)
        if not os.path.isdir(d):
            continue
        for name in os.listdir(d):
            if not name.endswith(".jsonl"):
                continue
            p = os.path.join(d, name)
            try:
                mtime = os.path.getmtime(p)
            except OSError:
                continue
            if now - mtime > hours * 3600:
                continue
            sid = name[:-6]
            last, ctx = usage5h.last_turn(p)
            st = usage5h.load(sid)
            h = usage5h.hibernating(sid, st)
            if now - mtime < WORKING_S:
                state = "working"
            elif h:
                state = "hibernating, wake %s" % usage5h.clock((h.get("reset_epoch") or 0) + usage5h.WAKE_PAD_S)
            elif usage5h.limit_was_hit(p):
                # The reset epoch in the limits file moves to the NEXT window once this
                # one resets, so a cut-off older than the current window start is overdue.
                window_start = (reset - 5 * 3600) if reset else None
                overdue = window_start is not None and last is not None and last < window_start - 600
                state = "CUT OFF, reset passed, not resumed" if overdue else "cut off, waiting for reset"
            else:
                state = "idle"
            out.append({"sid": sid, "alias": names.get(sid, ""), "cwd": os.path.basename(first_cwd(p) or proj),
                        "state": state, "idle_min": round((now - mtime) / 60),
                        "ctx_k": (ctx // 1000) if ctx else None, "last": last_reply(p)[-160:]})
    out.sort(key=lambda x: x["idle_min"])
    return r, out


def main(argv):
    hours = float(argv[argv.index("--hours") + 1]) if "--hours" in argv else 6
    r, out = rows(hours)
    if "--json" in argv:
        print(json.dumps({"window": r, "sessions": out}, indent=1))
        return 0
    if r:
        print("5h window: %s%% used, resets %s" % (r.get("pct", "?"), usage5h.clock(r.get("reset_epoch"))))
    else:
        print("5h window: no current reading (nothing has rendered since the last reset, or the file is stale)")
    for x in out:
        print("%-9s %-18s %-14s %-40s idle %4dm ctx %sk" % (x["sid"][:8], x["alias"][:18], x["cwd"][:14],
                                                          x["state"], x["idle_min"], x["ctx_k"] or "?"))
        if x["state"] != "working":
            print("          last: %s" % x["last"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
