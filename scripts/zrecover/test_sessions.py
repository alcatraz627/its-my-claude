#!/usr/bin/env python3
"""Exercises sessions.py against this machine's real transcripts and a scratch
bundle directory. Read-only on Claude's files; writes only under a temp dir.

Run: /usr/bin/python3 ~/.claude/scripts/zrecover/test_sessions.py
"""
import json, os, shutil, sys, tempfile, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sessions as sess  # noqa: E402
from testlib import expect, finish  # noqa: E402

# 1. transcript tail on a synthetic transcript with the real line shape
tmp = tempfile.mkdtemp(prefix="zrecover-sess-")
tp = os.path.join(tmp, "abc.jsonl")
with open(tp, "w") as f:
    f.write(json.dumps({"type": "user", "message": {"role": "user", "content": "<command-name>/clear</command-name>"}}) + "\n")
    f.write(json.dumps({"type": "user", "message": {"role": "user", "content": "fix the login bug please"}, "timestamp": "t1"}) + "\n")
    f.write(json.dumps({"type": "assistant", "message": {"role": "assistant", "content": [
        {"type": "tool_use", "name": "Read"}, {"type": "text", "text": "Found it in auth.py; patching."}]}, "timestamp": "t2"}) + "\n")
    f.write(json.dumps({"type": "user", "isSidechain": True, "message": {"role": "user", "content": "subagent noise"}}) + "\n")
    f.write(json.dumps({"type": "user", "message": {"role": "user", "content": [{"type": "tool_result", "content": "x"}]}}) + "\n")
t = sess.transcript_tail(tp)
expect("tail: last real user prompt, commands and tool results skipped", t["last_user"] == "fix the login bug please")
expect("tail: assistant text block extracted", t["last_assistant"] == "Found it in auth.py; patching.")
expect("tail: sidechain lines ignored, one real turn counted", t["turns_in_tail"] == 1)

# 2. tail on the biggest real transcript reads only the end
big = max((os.path.join(d, n) for d, _, ns in os.walk(sess.PROJECTS) for n in ns if n.endswith(".jsonl")),
          key=lambda p: os.stat(p).st_size, default=None)
if big:
    t0 = time.time()
    t = sess.transcript_tail(big)
    expect(f"tail on a {os.stat(big).st_size >> 20} MB transcript takes under a second", time.time() - t0 < 1.0 and t["mtime"])

# 3. slug inversion for a real project dir
pd = sess.project_dir(os.path.expanduser("~/.claude"))
expect("cwd_from_project_dir inverts the ~/.claude slug", sess.cwd_from_project_dir(pd) == os.path.expanduser("~/.claude"))

# 4. reconstruction around the 2026-10-10 panic finds interactive sessions only
panic = sess.latest_panic_ts()
expect("latest_panic_ts reads the panic report", panic is not None)
if panic:
    rows = sess.sessions_before_crash(panic, hours=10)
    expect("reconstruct: finds sessions and none is an automated sweep",
           rows and all(r["transcript_bytes"] > sess.SWEEP_MAX_BYTES or r.get("tty") for r in rows))
    expect("reconstruct: every row has a resume command with its id",
           all(r["resume"].endswith(r["session_id"]) for r in rows))
    expect("reconstruct: sorted newest first", [r["last_activity"] for r in rows] == sorted((r["last_activity"] for r in rows), reverse=True))

# 5. bundle writing in a scratch dir
sess.BUNDLES = os.path.join(tmp, "bundles")
md = sess.write_bundle([{"pid": 1, "session_id": "nonexistent-sid", "cwd": tmp, "alias": "t-alias"}], boot=123.0, keep_days=14)
body = open(md).read()
expect("bundle: markdown written with the session heading and resume command", "## 1. t-alias" in body and "zrecover run claude --resume nonexistent-sid" in body)
expect("bundle: latest.md points at it", os.path.realpath(os.path.join(sess.BUNDLES, "latest.md")) == os.path.realpath(md))
expect("bundle: list_bundles sees it with the boot", sess.list_bundles()[0]["boot"] == 123.0)
expect("bundle: last_bundle_before_boot picks a previous boot's bundle", sess.last_bundle_before_boot(time.time() + 1)["boot"] == 123.0)
expect("bundle: none when the only bundle is this boot's", sess.last_bundle_before_boot(123.0) is None)
shutil.rmtree(tmp)
finish()
