"""Drives keepwarm.py's hooks with the JSON Claude Code sends, in a temp folder.

Run: python3 ~/.claude/scripts/keepwarm/keepwarm.test.py
"""
import json
import os
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "zrecover"))
from testlib import expect, finish  # noqa: E402

KW = os.path.join(HERE, "keepwarm.py")
T = tempfile.mkdtemp()
SWITCH = os.path.join(T, "on")
ENV = dict(os.environ, KEEPWARM_DIR=os.path.join(T, "kw"), KEEPWARM_SWITCH=SWITCH,
           CLAUDE_CODE_ENTRYPOINT="cli", KEEPWARM_NO_STATUSLINE="1")


def transcript(tokens):
    p = os.path.join(T, "t-%d.jsonl" % tokens)
    with open(p, "w") as f:
        f.write(json.dumps({"type": "assistant", "message": {"usage": {
            "input_tokens": 0, "cache_read_input_tokens": tokens, "cache_creation_input_tokens": 0}}}) + "\n")
    return p


def hook(cmd, **inp):
    r = subprocess.run([sys.executable, KW, cmd], input=json.dumps(inp), capture_output=True, text=True, env=ENV)
    return json.loads(r.stdout) if r.stdout.strip() else {}


def age(sid, minutes):
    p = os.path.join(T, "kw", sid + ".json")
    st = json.load(open(p))
    st["last_activity"] = time.time() - minutes * 60
    json.dump(st, open(p, "w"))


def wake(sid, tokens, idle):
    age(sid, idle)
    return hook("hook-prompt", session_id=sid, prompt="[keepwarm] idle check",
                transcript_path=transcript(tokens), cwd="/tmp/proj")


def ctx(out):
    return (out.get("hookSpecificOutput") or {}).get("additionalContext", "")


# Off: no arming, every wake skipped.
expect("off: session start asks nothing", hook("hook-start", session_id="s0") == {})
hook("hook-prompt", session_id="s0", prompt="hello")
expect("off: a wake is blocked", wake("s0", 60000, 50).get("decision") == "block")

open(SWITCH, "w").close()
out = hook("hook-start", session_id="s1")
expect("on: session start asks to arm the cron", "CronCreate" in ctx(out) and "7,22,37,52" in ctx(out))
env_p = dict(ENV, CLAUDE_CODE_ENTRYPOINT="sdk-cli")
r = subprocess.run([sys.executable, KW, "hook-start"], input='{"session_id":"h"}', capture_output=True, text=True, env=env_p)
expect("a headless session is never armed", r.stdout.strip() == "")

# Worked session (60k of 200k = 30%): note, dump, inbox..., stop at wake 10.
hook("hook-prompt", session_id="s1", prompt="real work")
expect("a wake 20 min after activity is skipped", wake("s1", 60000, 20).get("decision") == "block")
expect("wake 1 at 45 min writes the note", "workspace note" in ctx(wake("s1", 60000, 45)))
expect("wake 2 writes the core-dump", "/core-dump" in ctx(wake("s1", 60000, 45)))
expect("wake 3 checks the inbox", "inbox" in ctx(wake("s1", 60000, 45)))
for _ in range(6):
    wake("s1", 60000, 45)
expect("wake 10 is the last and parks", "the last" in ctx(wake("s1", 60000, 45)))
expect("after the last wake, wakes are skipped", wake("s1", 60000, 45).get("decision") == "block")
hook("hook-prompt", session_id="s1", prompt="I'm back")
expect("the owner returning resets keep-warm", "workspace note" in ctx(wake("s1", 60000, 45)))

# Full session (150k = 75%): note, then dump and stop.
hook("hook-prompt", session_id="s2", prompt="x")
expect("full: wake 1 notes", "workspace note" in ctx(wake("s2", 150000, 45)))
expect("full: wake 2 dumps", "/core-dump" in ctx(wake("s2", 150000, 45)))
expect("full: then stops", wake("s2", 150000, 45).get("decision") == "block")

# Light session (10k = 5%): one note, then stop.
hook("hook-prompt", session_id="s3", prompt="x")
expect("light: one note", "workspace note" in ctx(wake("s3", 10000, 45)))
expect("light: then stops", wake("s3", 10000, 45).get("decision") == "block")

# The Stop hook moves the clock: a turn that just ended makes the next wake early.
hook("hook-prompt", session_id="s4", prompt="x")
age("s4", 50)
hook("hook-stop", session_id="s4")
out = hook("hook-prompt", session_id="s4", prompt="[keepwarm] idle check", transcript_path=transcript(60000))
expect("a turn that just ended defers the wake", out.get("decision") == "block")

# A broken input never blocks the owner.
r = subprocess.run([sys.executable, KW, "hook-prompt"], input="not json", capture_output=True, text=True, env=ENV)
expect("bad hook input never blocks", r.returncode == 0 and "block" not in r.stdout)
finish()
