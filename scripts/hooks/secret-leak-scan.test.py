#!/usr/bin/env python3
"""Checks that secret-leak-scan.py alerts on a token that appears where it matters and stays quiet otherwise.

Every run uses a throwaway HOME, so the real leak log and warn ledger are never written.
The tokens are fakes assembled at run time. SCAN_UNDER_TEST points the suite at a
deliberately broken copy for mutation runs.

Run: python3 ~/.claude/scripts/hooks/secret-leak-scan.test.py   (exit 0 = pass)
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.environ.get("SCAN_UNDER_TEST", os.path.join(HERE, "secret-leak-scan.py"))

GH = "ghp_" + "Qx7Lm2Vb9Kd4" * 3          # GitHub-shaped fake, not in the allowlist
SLACK = "xoxb-" + "7391-8842-Zq1Wm5Rt8Yc3Nf6Hj0Ps"
ANTHROPIC = "sk-ant-" + "Tz4Rk8Wm2Qa6Ne9Lc3Vb7Xd1Hy5Gs0Pf"
PEM = "-----BEGIN RSA PRIVATE KEY-----"

passed = failed = 0


def check(name, got, want):
    global passed, failed
    if got == want:
        passed += 1
    else:
        failed += 1
        print(f"  FAIL: {name}: got [{got}] want [{want}]")


def fp(value):
    return hashlib.sha256(value.encode()).hexdigest()[:8]


def run(payload, home, script=None, raw=None):
    """Feed the hook one event; return (exit code, stdout, leak-log rows)."""
    env = dict(os.environ, HOME=home, HOOK_TEST="1", WARN_LOG_STORE=os.path.join(home, "warn.jsonl"))
    stdin = raw if raw is not None else json.dumps(payload)
    p = subprocess.run([sys.executable, script or SCRIPT], input=stdin, capture_output=True, text=True, env=env, timeout=30)
    log = os.path.join(home, ".claude", "logs", "secret-leaks.jsonl")
    rows = [json.loads(line) for line in open(log)] if os.path.exists(log) else []
    return p.returncode, p.stdout, rows


def alerts(tool, tool_input, tool_response="", session="s1"):
    """True when one event makes the hook speak and log, in a fresh HOME."""
    home = tempfile.mkdtemp()
    try:
        rc, out, rows = run({"tool_name": tool, "tool_input": tool_input, "tool_response": tool_response,
                             "session_id": session, "cwd": "/x"}, home)
        check(f"{tool} exit code", rc, 0)
        return bool(out.strip()) and bool(rows)
    finally:
        shutil.rmtree(home, ignore_errors=True)


print("-- a token where it matters: must alert --")
check("Bash output", alerts("Bash", {"command": "echo hi"}, {"stdout": GH}), True)
check("Bash input", alerts("Bash", {"command": f"curl -H {SLACK} x"}, {"stdout": ""}), True)
check("Read output", alerts("Read", {"file_path": "/a"}, {"file": {"content": GH}}), True)
check("Write content", alerts("Write", {"file_path": "/a", "content": f"k = '{GH}'"}, {"type": "create"}), True)
check("Edit new_string", alerts("Edit", {"file_path": "/a", "old_string": "x", "new_string": GH}, {}), True)
check("MultiEdit edits", alerts("MultiEdit", {"file_path": "/a", "edits": [{"old_string": "a", "new_string": GH}]}, {}), True)
check("private key header in new_string", alerts("Edit", {"file_path": "/a", "old_string": "x", "new_string": PEM}, {}), True)

print("-- a token only in the file an edit echoes back: must stay quiet --")
echo = {"filePath": "/a", "originalFile": f"fixture = '{GH}'\n{PEM}\n", "oldString": GH}
check("Edit, token in old_string and response", alerts("Edit", {"file_path": "/a", "old_string": GH, "new_string": "gone"}, echo), False)
check("Write, token only in response", alerts("Write", {"file_path": "/a", "content": "clean"}, echo), False)

print("-- one alert per token per session --")
home = tempfile.mkdtemp()
ev = {"tool_name": "Bash", "tool_input": {"command": "x"}, "tool_response": {"stdout": GH}, "session_id": "sess-a"}
_, out1, _ = run(ev, home)
_, out2, rows = run(ev, home)
check("first sighting alerts", bool(out1.strip()), True)
check("repeat in the same session is silent", out2.strip(), "")
check("only one log row", len(rows), 1)
_, out3, rows = run(dict(ev, session_id="sess-b"), home)
check("a new session alerts again", bool(out3.strip()), True)
check("two log rows now", len(rows), 2)
other = dict(ev, tool_response={"stdout": SLACK})
_, out4, _ = run(other, home)
check("a different token in the same session alerts", bool(out4.strip()), True)
shutil.rmtree(home, ignore_errors=True)

print("-- a value that fits two key shapes is reported once --")
home = tempfile.mkdtemp()
_, out, rows = run({"tool_name": "Bash", "tool_input": {"command": "x"}, "tool_response": {"stdout": ANTHROPIC}, "session_id": "s"}, home)
check("one log row", len(rows), 1)
check("reported as the Anthropic kind", rows[0]["kind"] if rows else None, "Anthropic API key")
shutil.rmtree(home, ignore_errors=True)

print("-- allowlist beside the script --")
tmp = tempfile.mkdtemp()
copy = os.path.join(tmp, "secret-leak-scan.py")
shutil.copy(SCRIPT, copy)
home = tempfile.mkdtemp()
ev = {"tool_name": "Bash", "tool_input": {"command": "x"}, "tool_response": {"stdout": GH}, "session_id": "al"}
_, out, _ = run(ev, home, script=copy)
check("no allowlist file: alerts", bool(out.strip()), True)
with open(os.path.join(tmp, "secret-leak-scan.allow"), "w") as f:
    f.write(f"# note\n{fp(GH)}  # fixture\n")
home2 = tempfile.mkdtemp()
_, out, rows = run(ev, home2, script=copy)
check("listed fingerprint: silent", out.strip(), "")
check("listed fingerprint: nothing logged", rows, [])
_, out, _ = run(dict(ev, tool_response={"stdout": SLACK}), home2, script=copy)
check("unlisted token still alerts", bool(out.strip()), True)
for d in (tmp, home, home2):
    shutil.rmtree(d, ignore_errors=True)

print("-- the hook never blocks --")
home = tempfile.mkdtemp()
rc, out, _ = run(None, home, raw="not json")
check("garbage stdin: exit 0", rc, 0)
check("garbage stdin: silent", out.strip(), "")
rc, out, _ = run({"tool_name": "Edit", "tool_input": "a string, not a dict", "tool_response": None}, home)
check("odd input shape: exit 0", rc, 0)
shutil.rmtree(home, ignore_errors=True)

print(f"\npass={passed} fail={failed}")
sys.exit(1 if failed else 0)
