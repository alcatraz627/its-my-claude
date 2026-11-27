"""Feeds seat-hook.py the Agent PreToolUse/PostToolUse JSON Claude Code sends.

Run: python3 ~/.claude/scripts/seats/seat-hook.test.py
"""
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "zrecover"))
from testlib import expect, finish  # noqa: E402

T = tempfile.mkdtemp(prefix="seathook-")
ENV = dict(os.environ, SEATS_DIR=T, SEATS_DOMAIN=os.path.join(T, "d"), SEAT_HINT_DIR=T)
OUT = os.path.join(T, "report.md")
sid = "s-20261010-200000-abcd"
with open(os.path.join(T, sid + ".json"), "w") as f:
    json.dump({"id": sid, "role": "reviewer", "provider": "claude", "model": "sonnet", "persona": "",
               "output": OUT, "state": "composed", "feedback": []}, f)


def hook(event, prompt, background=False, session="sessAAAA-1111"):
    inp = {"hook_event_name": event, "tool_name": "Agent", "session_id": session,
           "tool_input": {"prompt": prompt, "run_in_background": background}}
    return subprocess.run([sys.executable, os.path.join(HERE, "seat-hook.py")], input=json.dumps(inp),
                          capture_output=True, text=True, env=ENV)


def seat_record():
    with open(os.path.join(T, sid + ".json")) as f:
        return json.load(f)


r = hook("PreToolUse", "Review the diff please")
expect("an unseated dispatch gets a warning, not a block",
       "no seat header" in r.stdout and '"block"' not in r.stdout and r.returncode == 0)
r2 = hook("PreToolUse", "Another unseated dispatch, same session")
expect("a second unseated dispatch in the same session gets no hint", r2.stdout == "" and r2.returncode == 0)
r3 = hook("PreToolUse", "A third one", session="sessAAAA-1111")
expect("a third stays quiet too", r3.stdout == "")
rb = hook("PreToolUse", "An unseated dispatch in a different session", session="sessBBBB-2222")
expect("the first unseated dispatch of another session still gets the hint", "no seat header" in rb.stdout)
rn = hook("PreToolUse", "No session id at all", session="")
expect("a dispatch with no session id hints once, then stays quiet",
       "no seat header" in rn.stdout and hook("PreToolUse", "again", session="").stdout == "")
rows = [json.loads(line) for line in open(os.path.join(T, "dispatch.jsonl"))]
expect("every unseated dispatch is still logged, with warned true only where the hint showed",
       [x["warned"] for x in rows] == [True, False, False, True, True, False])
hook("PreToolUse", "[seat %s] role=reviewer\nthe prompt" % sid)
expect("a seated dispatch marks the record dispatched", seat_record()["state"] == "dispatched")
open(OUT, "w").close()
hook("PostToolUse", "[seat %s] role=reviewer\nthe prompt" % sid)
expect("the return lands the seat, ok because its output exists",
       seat_record()["state"] == "landed" and seat_record()["outcome"] == "ok")
r = subprocess.run([sys.executable, os.path.join(HERE, "seat-hook.py")], input="garbage",
                   capture_output=True, text=True, env=ENV)
expect("bad input never fails the tool call", r.returncode == 0)
finish()
