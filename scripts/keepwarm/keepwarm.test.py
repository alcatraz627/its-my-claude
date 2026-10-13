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
expect("off: a wake is blocked", wake("s0", 300000, 50).get("decision") == "block")

open(SWITCH, "w").close()
out = hook("hook-start", session_id="s1")
expect("on: session start asks for one one-shot cron", "CronCreate" in ctx(out) and "recurring false" in ctx(out)
       and "delete any job" in ctx(out))
env_p = dict(ENV, CLAUDE_CODE_ENTRYPOINT="sdk-cli")
r = subprocess.run([sys.executable, KW, "hook-start"], input='{"session_id":"h"}', capture_output=True, text=True, env=env_p)
expect("a headless session is never armed", r.stdout.strip() == "")

# Small session (60k of 200k = 30%): warm, warm, full dump, stop.
hook("hook-prompt", session_id="s1", prompt="real work")
early = wake("s1", 300000, 40)
expect("a wake 40 min after activity is not due and never blocked", "decision" not in early)
expect("it only re-arms and says the one word", "not due" in ctx(early) and "recurring false" in ctx(early)
       and "one word: warm" in ctx(early))
w1 = wake("s1", 300000, 56)
expect("small: wake 1 at 56 min only keeps warm", "only keeps the cache warm" in ctx(w1))
expect("a due wake also arms the next one", "Re-arm keep-warm" in ctx(w1))
expect("small: wake 2 keeps warm", "only keeps the cache warm" in ctx(wake("s1", 300000, 56)))
last = wake("s1", 300000, 56)
expect("small: wake 3 is the last and writes the full core-dump",
       "the last" in ctx(last) and "full /core-dump" in ctx(last) and "not mini" in ctx(last))
expect("the last wake does not arm another", "Re-arm keep-warm" not in ctx(last))
expect("after the last wake, wakes are skipped", wake("s1", 300000, 56).get("decision") == "block")
hook("hook-prompt", session_id="s1", prompt="I'm back")
expect("the owner returning resets keep-warm", "only keeps the cache warm" in ctx(wake("s1", 300000, 56)))

# Large session (150k = 75%): warm once, then the full dump, then stop.
hook("hook-prompt", session_id="s2", prompt="x")
expect("large: wake 1 keeps warm", "only keeps the cache warm" in ctx(wake("s2", 750000, 56)))
expect("large: wake 2 is the full dump", "full /core-dump" in ctx(wake("s2", 750000, 56)))
expect("large: then stops", wake("s2", 750000, 56).get("decision") == "block")

# The wake's own turn ending must not reset the idle clock (the double-wake bug).
hook("hook-prompt", session_id="s5", prompt="x")
wake("s5", 300000, 56)
p5 = os.path.join(T, "kw", "s5.json")
at_wake = json.load(open(p5))["last_activity"]
time.sleep(1.1)
hook("hook-stop", session_id="s5")
st5 = json.load(open(p5))
expect("a wake turn's Stop leaves the clock at the wake", st5["last_activity"] == at_wake
       and "in_wake" not in st5)
hook("hook-stop", session_id="s5")
expect("an ordinary turn's Stop still moves the clock", json.load(open(p5))["last_activity"] > at_wake)
st5 = json.load(open(p5))
st5["last_activity"] -= 56 * 60
json.dump(st5, open(p5, "w"))
nxt = hook("hook-prompt", session_id="s5", prompt="[keepwarm] idle check", transcript_path=transcript(300000))
expect("so the next wake 56 min later is due, not a re-arm", "only keeps the cache warm" in ctx(nxt))

# The Stop hook moves the clock: a turn that just ended makes the next wake early.
hook("hook-prompt", session_id="s4", prompt="x")
age("s4", 50)
hook("hook-stop", session_id="s4")
out = hook("hook-prompt", session_id="s4", prompt="[keepwarm] idle check", transcript_path=transcript(300000))
expect("a turn that just ended defers the wake by re-arming, not blocking", "decision" not in out and "not due" in ctx(out))

# A broken one-shot chain is re-linked on the owner's next prompt, once.
hook("hook-start", session_id="s6")
expect("an owner prompt while a wake is pending adds nothing",
       ctx(hook("hook-prompt", session_id="s6", prompt="work")) == "")
p6 = os.path.join(T, "kw", "s6.json")
st6 = json.load(open(p6))
st6["armed_at"] = time.time() - 3600
json.dump(st6, open(p6, "w"))
relink = ctx(hook("hook-prompt", session_id="s6", prompt="back after the wake never fired"))
expect("a missed wake is re-armed on the owner's next prompt",
       "no wake is pending" in relink and "CronCreate" in relink and "delete any job" in relink)
expect("and only once", ctx(hook("hook-prompt", session_id="s6", prompt="next")) == "")
hook("hook-prompt", session_id="s7", prompt="x")
wake("s7", 750000, 56)
wake("s7", 750000, 56)
st7 = json.load(open(os.path.join(T, "kw", "s7.json")))
st7["armed_at"] = time.time() - 3600
json.dump(st7, open(os.path.join(T, "kw", "s7.json"), "w"))
expect("a finished cycle re-arms when the owner returns",
       "no wake is pending" in ctx(hook("hook-prompt", session_id="s7", prompt="back")))

# A broken input never blocks the owner.
r = subprocess.run([sys.executable, KW, "hook-prompt"], input="not json", capture_output=True, text=True, env=ENV)
expect("bad hook input never blocks", r.returncode == 0 and "block" not in r.stdout)
finish()
