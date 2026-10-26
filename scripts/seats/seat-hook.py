#!/usr/bin/env python3
"""Links Agent dispatches to seat records (PreToolUse) and lands them on return
(PostToolUse). A dispatch with no [seat ...] header only gets a warning, never a
block (owner ruling b, 2026-10-10; re-affirmed 2026-10-26: "make header warn for
now, will escalate later to block if warn isn't enough (ensure telemetry)").
Every dispatch is logged to seats/dispatch.jsonl so `seat weekly` can show
whether the warning is working. Never fails the tool call."""
import datetime as dt
import json
import os
import re
import subprocess
import sys

SEAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "seat")
SEATS = os.environ.get("SEATS_DIR", os.path.expanduser("~/.claude/seats"))

# What each of the five dispatch clauses looks like in a prompt. A floor, not an
# audit: it reads wording, so a clause phrased some new way reads as missing.
CLAUSE_RE = {
    "nesting": re.compile(r"do not spawn|don'?t spawn|no sub-?agents|pin sonnet or lower", re.I),
    "scope_close": re.compile(r"scope.?close|work is done,? stop|do not pick up other tasks|auto-dispatch", re.I),
    "output_path": re.compile(r"(/Users/|~/)\S+\.(md|json|jsonl|txt|html)\b.*|before returning", re.I | re.S),
    "one_command": re.compile(r"one command per bash|do not chain|never chain|no chaining", re.I),
}


def log_dispatch(ti, prompt, sid, warned):
    try:
        os.makedirs(SEATS, exist_ok=True)
        row = {"ts": dt.datetime.now().isoformat(timespec="seconds"), "seated": bool(sid), "seat": sid or "",
               "warned": warned, "prompt_len": len(prompt), "background": bool(ti.get("run_in_background")),
               "model": ti.get("model") or "", "type": ti.get("subagent_type") or "",
               "clauses": {"model_pin": bool(ti.get("model")),
                           **{k: bool(r.search(prompt)) for k, r in CLAUSE_RE.items()}},
               "session": os.environ.get("CLAUDE_CODE_SESSION_ID", "")}
        with open(os.path.join(SEATS, "dispatch.jsonl"), "a") as f:
            f.write(json.dumps(row) + "\n")
    except OSError:
        pass


def main():
    try:
        inp = json.load(sys.stdin)
    except ValueError:
        return 0
    if inp.get("tool_name") != "Agent":
        return 0
    ti = inp.get("tool_input") or {}
    prompt = ti.get("prompt") or ""
    m = re.search(r"\[seat (s-\d{8}-\d{6}-[0-9a-f]{4})\]", prompt)
    event = inp.get("hook_event_name")
    if event == "PreToolUse":
        # Background seats finish long after their tool call returns, so any
        # dispatch is a chance to land the ones that have since written output.
        subprocess.run([sys.executable, SEAT, "sweep", "--quiet"], capture_output=True, timeout=10)
    if not m:
        if event == "PreToolUse":
            log_dispatch(ti, prompt, None, True)
            print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext":
                  "This sub-agent dispatch has no seat header. Seat it in one call: "
                  "`seat header --role R --model M --output /abs/path --goal \"...\"` prints the header line "
                  "to put first in the prompt. For a full brief use `seat template` + `seat compose`."}}))
        return 0
    sid = m.group(1)
    rec_p = os.path.join(SEATS, sid + ".json")
    if not os.path.exists(rec_p):
        if event == "PreToolUse":
            log_dispatch(ti, prompt, None, True)
        return 0
    with open(rec_p) as f:
        rec = json.load(f)
    if event == "PreToolUse":
        log_dispatch(ti, prompt, sid, False)
        rec["state"] = "dispatched"
        rec["dispatched"] = dt.datetime.now().isoformat(timespec="seconds")
        rec["background"] = bool(ti.get("run_in_background"))
        tmp = rec_p + ".tmp"
        with open(tmp, "w") as f:
            json.dump(rec, f, indent=2)
        os.replace(tmp, rec_p)
    elif event == "PostToolUse" and not rec.get("background"):
        outcome = "ok" if rec.get("output") and os.path.exists(rec["output"]) else "partial"
        subprocess.run([sys.executable, SEAT, "land", sid, "--outcome", outcome,
                        "--note", "landed by hook"], capture_output=True)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
