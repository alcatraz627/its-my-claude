#!/usr/bin/env python3
"""Links Agent dispatches to seat records (PreToolUse) and lands them on return
(PostToolUse). A dispatch with no [seat ...] header only gets a warning, never a
block (owner ruling b, 2026-10-10). Never fails the tool call."""
import json
import os
import re
import subprocess
import sys

SEAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "seat")
SEATS = os.environ.get("SEATS_DIR", os.path.expanduser("~/.claude/seats"))


def main():
    try:
        inp = json.load(sys.stdin)
    except ValueError:
        return 0
    if inp.get("tool_name") != "Agent":
        return 0
    prompt = (inp.get("tool_input") or {}).get("prompt") or ""
    m = re.search(r"\[seat (s-\d{8}-\d{6}-[0-9a-f]{4})\]", prompt)
    event = inp.get("hook_event_name")
    if not m:
        if event == "PreToolUse" and len(prompt) < 4000:
            print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext":
                  "This sub-agent dispatch has no seat header. Outside a skill, build it with "
                  "`seat template` + `seat compose` so the prompt is complete and the seat is recorded."}}))
        return 0
    sid = m.group(1)
    rec_p = os.path.join(SEATS, sid + ".json")
    if not os.path.exists(rec_p):
        return 0
    with open(rec_p) as f:
        rec = json.load(f)
    if event == "PreToolUse":
        rec["state"] = "dispatched"
        rec["background"] = bool((inp.get("tool_input") or {}).get("run_in_background"))
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
