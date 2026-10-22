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
LIMITS = os.path.join(T, "limits.json")
ENV = dict(os.environ, KEEPWARM_DIR=os.path.join(T, "kw"), KEEPWARM_SWITCH=SWITCH,
           CLAUDE_CODE_ENTRYPOINT="cli", KEEPWARM_NO_STATUSLINE="1",
           USAGE5H_LIMITS=LIMITS, USAGE5H_DIR=os.path.join(T, "u5"),
           USAGE5H_CLAUDE_JSON=os.path.join(T, "claude.json"))


def signed_in(org):
    with open(ENV["USAGE5H_CLAUDE_JSON"], "w") as f:
        json.dump({"oauthAccount": {"organizationUuid": org}}, f)


signed_in("org-a")


def limits(pct):
    with open(LIMITS, "w") as f:
        json.dump({"5h": {"pct": pct}, "resets_at": str(int(time.time() + 7200))}, f)


limits(10)


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

# The re-arm comes after the answer, never before it.
expect("the start asks to answer first, then re-arm", "Answer the owner's next message first" in ctx(out))

# Opened, asked, interrupted before any answer (session 90d2e6ca): no paid
# wakes and no core-dump of an empty session.
hook("hook-start", session_id="s11")
hook("hook-prompt", session_id="s11", prompt="a question interrupted before the answer")
expect("a session with no finished turn skips its wake", wake("s11", 300000, 56).get("decision") == "block")
expect("and stays stopped", wake("s11", 300000, 56).get("decision") == "block")
hook("hook-start", session_id="s12")
hook("hook-prompt", session_id="s12", prompt="a real question")
hook("hook-stop", session_id="s12")
expect("once a turn finished, the wake runs", "decision" not in wake("s12", 300000, 56))

# Small session (60k of 200k = 30%): warm, warm, full dump, stop.
hook("hook-prompt", session_id="s1", prompt="real work")
hook("hook-stop", session_id="s1")
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

# Health check: after a wake's turn, did the ping actually find the cache warm?
EVENTS = os.path.join(T, "kw", "events.jsonl")


def usage_transcript(name, read, create):
    p = os.path.join(T, "u-%s.jsonl" % name)
    with open(p, "w") as f:
        f.write(json.dumps({"type": "assistant", "message": {"usage": {
            "input_tokens": 1, "cache_read_input_tokens": read, "cache_creation_input_tokens": create}}}) + "\n")
    return p


def health(sid):
    rows = [json.loads(line) for line in open(EVENTS)] if os.path.exists(EVENTS) else []
    return [r for r in rows if r["sid"] == sid and r["ev"] == "ping-health"]


def wake_then_stop(sid, tp):
    hook("hook-prompt", session_id=sid, prompt="x")
    wake(sid, 300000, 56)
    hook("hook-stop", session_id=sid, transcript_path=tp)
    return health(sid)


h = wake_then_stop("h1", usage_transcript("warm", 300000, 5000))
expect("health: a read-heavy wake turn is judged warm", len(h) == 1 and h[0]["verdict"] == "warm"
       and h[0]["cache_read"] == 300000 and h[0]["cache_creation"] == 5000)
h = wake_then_stop("h2", usage_transcript("cold", 0, 200000))
expect("health: a cold rebuild (no read) is judged cold", len(h) == 1 and h[0]["verdict"] == "cold")
h = wake_then_stop("h3", usage_transcript("rewrite", 100000, 10000))
expect("health: a write at 10% of the read is cold (the bar is under 10%)", h[0]["verdict"] == "cold")
h = wake_then_stop("h4", usage_transcript("edge", 100000, 9999))
expect("health: a write just under 10% of the read is warm", h[0]["verdict"] == "warm")
h = wake_then_stop("h5", os.path.join(T, "no-such-transcript.jsonl"))
expect("health: no usage to read is logged unknown, never guessed", len(h) == 1 and h[0]["verdict"] == "unknown")
hook("hook-prompt", session_id="h6", prompt="x")
hook("hook-stop", session_id="h6", transcript_path=usage_transcript("warm", 300000, 5000))
expect("health: an ordinary turn's Stop logs no verdict", health("h6") == [])

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

# An owner-run /core-dump ends keep-warm for this absence (enh-scrape kept waking at 76%).
hook("hook-prompt", session_id="s8", prompt="x")
expect("an owner /core-dump adds no re-arm", ctx(hook("hook-prompt", session_id="s8", prompt="/core-dump")) == "")
expect("a wake after an owner dump is skipped with no turn", wake("s8", 760000, 56).get("decision") == "block")
expect("even a not-due wake after a dump is skipped", wake("s8", 760000, 20).get("decision") == "block")
hook("hook-prompt", session_id="s8", prompt="back again")
expect("the owner's next prompt resumes keep-warm", "only keeps the cache warm" in ctx(wake("s8", 760000, 56)))
hook("hook-prompt", session_id="s9", prompt="fix the core-dump skill, then /catchup later")
expect("prose about core-dump does not stop keep-warm", "only keeps the cache warm" in ctx(wake("s9", 300000, 56)))

# A /clear arms nothing; a wake armed before it is skipped; the next prompt re-links.
expect("a cleared session start asks for no cron", hook("hook-start", session_id="s10", source="clear") == {})
expect("a pre-clear wake is skipped with no turn", wake("s10", 90000, 56).get("decision") == "block")
expect("the owner's first prompt after the clear re-links",
       "no wake is pending" in ctx(hook("hook-prompt", session_id="s10", prompt="/catchup")))
expect("a startup session start still arms", "CronCreate" in ctx(hook("hook-start", session_id="s11", source="startup")))

# Prompts the owner did not type are not the owner coming back (clanky-opus, 2026-10-21).
hook("hook-prompt", session_id="s12", prompt="x")
st12 = json.load(open(os.path.join(T, "kw", "s12.json")))
st12["armed_at"] = time.time() - 3600
st12["wakes"] = 1
json.dump(st12, open(os.path.join(T, "kw", "s12.json"), "w"))
for p in ("Your claude.ai usage limit has reset. Continue the task you were working on.",
          "<task-notification> done </task-notification>", "Another Claude session sent a message: hi",
          "[usage-carry] reply with one word: warm"):
    expect("not the owner, no re-arm: " + p[:24], ctx(hook("hook-prompt", session_id="s12", prompt=p)) == "")
expect("and the wake count survives them", json.load(open(os.path.join(T, "kw", "s12.json")))["wakes"] == 1)
expect("the owner's own prompt still re-links", "no wake is pending" in ctx(hook("hook-prompt", session_id="s12", prompt="back")))

# A spent 5h window: the wake would be refused, so it is skipped before the model runs.
hook("hook-prompt", session_id="s13", prompt="x")
limits(100)
expect("a wake into a spent window is skipped", wake("s13", 300000, 56).get("decision") == "block")
expect("even a not-due one", wake("s13", 300000, 10).get("decision") == "block")
limits(10)
expect("an open window wakes as before", "only keeps the cache warm" in ctx(wake("s13", 300000, 56)))

# A hibernating session keeps itself warm; keep-warm must not ping it a second time.
hook("hook-prompt", session_id="s14", prompt="x")
os.makedirs(os.path.join(T, "u5"), exist_ok=True)
json.dump({"hibernate": {"strategy": "resume", "at": time.time(), "reset_epoch": time.time() + 7200}},
          open(os.path.join(T, "u5", "s14.json"), "w"))
expect("a wake while hibernating is skipped", wake("s14", 300000, 56).get("decision") == "block")
expect("not a re-arm either", wake("s14", 300000, 10).get("decision") == "block")
expect("a hibernation wake prompt is not the owner",
       ctx(hook("hook-prompt", session_id="s14", prompt="[usage-resume] The 5h window has reset.")) == "")

# The owner switched accounts while away: the cache went with the old one, so a
# wake would only pay the new account to rebuild it (2026-10-22).
hook("hook-start", session_id="s15")
hook("hook-prompt", session_id="s15", prompt="a real question")
hook("hook-stop", session_id="s15")
expect("same account: the wake runs", "decision" not in wake("s15", 300000, 56))
hook("hook-prompt", session_id="s16", prompt="a real question")
hook("hook-stop", session_id="s16")
signed_in("org-b")
expect("switched account: the wake is skipped", wake("s16", 300000, 56).get("decision") == "block")
expect("and the chain stays stopped", wake("s16", 300000, 56).get("decision") == "block")
hook("hook-prompt", session_id="s16", prompt="back on the new account")
hook("hook-stop", session_id="s16")
expect("an owner turn on the new account re-baselines it", "decision" not in wake("s16", 300000, 56))
signed_in("org-a")

# A broken input never blocks the owner.
r = subprocess.run([sys.executable, KW, "hook-prompt"], input="not json", capture_output=True, text=True, env=ENV)
expect("bad hook input never blocks", r.returncode == 0 and "block" not in r.stdout)
finish()
