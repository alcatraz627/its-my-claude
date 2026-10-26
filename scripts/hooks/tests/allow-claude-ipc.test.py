#!/usr/bin/env python3
"""allow-claude-ipc.py: a lone claude-ipc call is allowed; anything else that would run is not.

Run: python3 allow-claude-ipc.test.py   (HOOK=<path> points it at a mutated copy)
"""
import json
import os
import subprocess
import sys

HOOK = os.environ.get("HOOK", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "allow-claude-ipc.py"))
passed = failed = 0


def allowed(cmd):
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}})
    out = subprocess.run([sys.executable, HOOK], input=payload, capture_output=True, text=True).stdout
    return '"allow"' in out


def case(want, cmd):
    global passed, failed
    got = allowed(cmd)
    label = "allow" if want else "leave"
    if got == want:
        passed += 1
        print(f"  ok    {label}: {cmd!r:.70}")
    else:
        failed += 1
        print(f"  FAIL  {label}: {cmd!r:.70}  got {'allow' if got else 'no decision'}")


case(True, "claude-ipc inbox")
case(True, "claude-ipc send --to peer 'I ran git push origin main earlier'")
case(True, 'claude-ipc send --to peer "deploy with gcloud run deploy && wait"')
case(True, "claude-ipc send --to peer --file - <<'EOF'\n$(rm x) is only text here\nEOF")
case(True, "claude-ipc send --to peer 'x' 2>/dev/null")
case(False, "claude-ipc send --to peer hi && rm x")
case(False, "claude-ipc send --to peer hi; git push")
case(False, "claude-ipc send --to peer hi | sh")
case(False, 'claude-ipc send --to a "$(sudo rm x)"')
case(False, "claude-ipc send --to a `whoami`")
case(False, "claude-ipc send --to a --file - <<EOF\n$(rm x)\nEOF")
case(False, "echo hi | claude-ipc send --to a -")
case(False, "git push; claude-ipc send --to a hi")
case(False, "claude-ipc send --to a 'unclosed")
print(f"---- pass={passed} fail={failed}")
sys.exit(1 if failed else 0)
