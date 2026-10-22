#!/usr/bin/env python3
"""Checks for usage5h.py against fixture limits files, heartbeats and transcripts."""
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "usage5h.py")
fails = []


def check(name, cond, detail=""):
    print(("ok   " if cond else "FAIL ") + name + ("" if cond else "  " + detail))
    if not cond:
        fails.append(name)


class Env:
    def __init__(self):
        self.root = tempfile.mkdtemp(prefix="usage5h-test-")
        self.limits = os.path.join(self.root, "limits.json")
        self.turn = os.path.join(self.root, "turn")
        self.dir = os.path.join(self.root, "state")
        self.projects = os.path.join(self.root, "projects")
        self.wakes = os.path.join(self.root, "wakes")
        self.kw_switch = os.path.join(self.root, "kw-on")
        os.makedirs(self.turn)
        os.makedirs(os.path.join(self.projects, "-p"))
        os.makedirs(self.wakes)

    def scheduled(self, sid, prompt):
        d = os.path.join(self.wakes, "claude-wakes-" + sid[:8])
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "crons"), "a") as f:
            f.write(hashlib.sha1(prompt.encode()).hexdigest()[:16] + "\n")

    def set(self, pct, reset_in_min=200, agents=2, stale=False):
        with open(self.limits, "w") as f:
            json.dump({"5h": {"pct": pct}, "resets_at": str(int(time.time() + reset_in_min * 60))}, f)
        if stale:
            old = time.time() - 4000
            os.utime(self.limits, (old, old))
        for name in os.listdir(self.turn):
            os.remove(os.path.join(self.turn, name))
        for i in range(agents):
            open(os.path.join(self.turn, "heartbeat-s%d" % i), "w").close()

    def transcript(self, sid, minutes_ago, tokens, cut_off=False, quoted=False, clean=False):
        ts = time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime(time.time() - minutes_ago * 60))
        p = os.path.join(self.projects, "-p", sid + ".jsonl")
        with open(p, "w") as f:
            # an old cut-off the session already recovered from must not count
            f.write(json.dumps({"type": "assistant", "timestamp": ts, "message": {"content": [{"type": "text",
                    "text": "You've hit your session limit"}], "usage": {"input_tokens": 0}}}) + "\n")
            if quoted:
                f.write(json.dumps({"type": "user", "message": {"content": [{"type": "tool_result",
                        "content": "[Usage limit reached; a short grace"}]}}) + "\n")
            f.write(json.dumps({"type": "assistant", "timestamp": ts,
                                "message": {"stop_reason": "end_turn" if clean else "tool_use",
                                            "usage": {"input_tokens": 10, "cache_read_input_tokens": tokens}}}) + "\n")
            if quoted:
                f.write(json.dumps({"type": "user", "message": {"content": [{"type": "tool_result",
                        "content": "[Usage limit reached; a short grace"}]}}) + "\n")
            if cut_off:
                f.write(json.dumps({"type": "assistant", "timestamp": ts, "message": {"content": [{"type": "text",
                        "text": "You've hit your session limit · resets 11:20pm"}], "usage": {"input_tokens": 0}}}) + "\n")
        return p

    def run(self, args, stdin=None):
        env = dict(os.environ, USAGE5H_LIMITS=self.limits, USAGE5H_TURN_STATE=self.turn,
                   USAGE5H_DIR=self.dir, USAGE5H_PROJECTS=self.projects, USAGE5H_WAKES=self.wakes,
                   KEEPWARM_SWITCH=self.kw_switch)
        r = subprocess.run([sys.executable, SCRIPT] + args, input=json.dumps(stdin) if stdin is not None else None,
                           capture_output=True, text=True, env=env, timeout=30)
        return r.stdout.strip()

    def prompt(self, sid, text, transcript=None):
        return self.run(["hook-prompt"], {"session_id": sid, "prompt": text, "transcript_path": transcript or ""})


def ctx(out):
    try:
        return json.loads(out)["hookSpecificOutput"]["additionalContext"]
    except (ValueError, KeyError, TypeError):
        return ""


def blocked(out):
    return '"block"' in out


e = Env()
RESUME = "[usage-resume] The 5h window has reset. Continue the work you parked."
NATIVE = "Your claude.ai usage limit has reset. Continue the task you were working on when the limit was reached."
PING = "[usage-carry] keep the cache warm"

# zones and share
e.set(50)
check("ok below amber", json.loads(e.run(["pressure", "--json"]))["zone"] == "ok")
e.set(85, agents=4)
p = json.loads(e.run(["pressure", "--json"]))
check("amber at 85", p["zone"] == "amber", str(p))
check("share splits what is left by live agents", p["share"] == 3.0, str(p))
e.set(92)
check("red at 92", json.loads(e.run(["pressure", "--json"]))["zone"] == "red")
e.set(97)
check("brake at 97", json.loads(e.run(["pressure", "--json"]))["zone"] == "brake")
e.set(95, stale=True)
check("stale reading is unknown, not a zone", json.loads(e.run(["pressure", "--json"]))["zone"] == "unknown")

# nudge cadence and the wake arm ask
e.set(85)
hook = {"session_id": "aaaa1111-0000-0000-0000-000000000000"}
check("amber fires on entry", "amber" in e.run(["hook-post"], hook))
check("amber does not repeat", e.run(["hook-post"], hook) == "")
e.set(92)
out = e.run(["hook-post"], hook)
check("red fires on entry with the plan and the wake to arm", "plan --work" in out and "[usage-resume]" in out, out)
e.run(["hook-post"], dict(hook, tool_name="CronCreate", tool_input={"prompt": RESUME}))
quiet = [e.run(["hook-post"], hook) for _ in range(13)]
check("red stays quiet between repeats", all(q == "" for q in quiet))
out = e.run(["hook-post"], hook)
check("red repeats on the 15th, without the arm ask once armed", "red" in out and "[usage-resume]" not in out, out)
sub = dict(hook, agent_id="agent-x")
out = e.run(["hook-post"], sub)
check("subagent gets its own scoped text", "You are a subagent" in out and "plan --work" not in out, out)

# agent dispatch bump: once, then through
out = e.run(["hook-pre-agent"], hook)
check("first red dispatch is bounced", '"deny"' in out, out)
check("re-issued dispatch goes through", e.run(["hook-pre-agent"], hook) == "")
e.set(85)
check("amber never bounces a dispatch", e.run(["hook-pre-agent"], {"session_id": "bbbb"}) == "")

# plan and record
e.set(91, reset_in_min=150)
e.transcript("cccc2222-0000-0000-0000-000000000000", 1, 230000)
out = e.run(["plan", "--work", "some", "--sid", "cccc2222"])
check("work left plans an in-place resume with a wake and pings", "strategy: resume" in out
      and "[usage-resume]" in out and "[usage-carry]" in out, out)
e.set(91, reset_in_min=40)
out = e.run(["plan", "--work", "some", "--sid", "cccc2222"])
check("a reset within the hour needs no pings", "[usage-resume]" in out and "[usage-carry]" not in out, out)
out = e.run(["plan", "--work", "none", "--sid", "cccc2222"])
check("no work left plans finish, with a dump for a large context", "strategy: finish" in out and "/core-dump" in out, out)
e.transcript("dddd3333-0000-0000-0000-000000000000", 1, 40000)
check("a small finished session skips the dump", "/core-dump" not in e.run(["plan", "--work", "none", "--sid", "dddd3333"]))

# hibernation, pings, wake
S = "cccc2222-0000-0000-0000-000000000000"
e.set(92, reset_in_min=150)
out = e.run(["record", "--strategy", "resume", "--sid", "cccc2222", "--note", "ship step 9"])
check("record resume prints the wake and the first ping", "[usage-resume]" in out and "[usage-carry]" in out, out)
c = ctx(e.prompt(S, PING))
check("a ping while hibernating says warm and re-arms the next", "warm" in c and "[usage-carry]" in c, c)
c = ctx(e.prompt(S, "<task-notification> done </task-notification>"))
check("a notification while hibernating is noted, not worked", "hibernating" in c and "end the turn" in c, c)
e.set(99, reset_in_min=150)
check("a ping into a spent window is skipped", blocked(e.prompt(S, PING)))
e.set(5, reset_in_min=300)
c = ctx(e.prompt(S, RESUME))
check("the session's own wake resumes it with its note", "Carry on" in c and "ship step 9" in c, c)
check("then the native resume is a duplicate", blocked(e.prompt(S, NATIVE)))
check("and a stray ping after waking is skipped", blocked(e.prompt(S, PING)))

# the owner coming back cancels
S2 = "eeee4444-0000-0000-0000-000000000000"
e.transcript(S2, 1, 230000)
e.set(92, reset_in_min=150)
e.run(["record", "--strategy", "resume", "--sid", "eeee4444"])
c = ctx(e.prompt(S2, "keep going, I'll watch it"))
check("an owner prompt cancels the hibernation", "cancelled" in c, c)
check("so the armed wake is skipped", blocked(e.prompt(S2, RESUME)))
check("as is the native resume", blocked(e.prompt(S2, NATIVE)))

# no hibernation record
F = "ffff5555-0000-0000-0000-000000000000"
t = e.transcript(F, 90, 230000, cut_off=True)
check("cut off without hibernating: the own wake resumes", "Carry on" in ctx(e.prompt(F, RESUME, t)))
G = "gggg6666-0000-0000-0000-000000000000"
t = e.transcript(G, 10, 230000, quoted=True)
check("not cut off (only quoted, or recovered): the own wake is skipped", blocked(e.prompt(G, RESUME, t)))
H = "hhhh7777-0000-0000-0000-000000000000"
t = e.transcript(H, 90, 230000)
check("the native resume of a session cut off mid-work resumes", "Carry on" in ctx(e.prompt(H, NATIVE, t)))
K = "kkkk8888-0000-0000-0000-000000000000"
t = e.transcript(K, 90, 230000, cut_off=True, clean=True)
check("the native resume of a session that had closed out is skipped (clanky-opus)",
      blocked(e.prompt(K, NATIVE, t)))
check("and so is its own wake", blocked(e.prompt(K, RESUME, t)))
e.run(["record", "--strategy", "finish", "--sid", "dddd3333"])
check("a finished session's native resume is skipped",
      blocked(e.prompt("dddd3333-0000-0000-0000-000000000000", NATIVE)))
check("an owner prompt in a quiet session is untouched", e.prompt("iiii", "hello") == "")
check("a ping with nothing hibernating is skipped", blocked(e.prompt("jjjj", PING)))

# A reset already past is not a reading: no "brake now", no wake for a minute gone by.
e.set(97, reset_in_min=-10)
check("a past reset reads as unknown", json.loads(e.run(["pressure", "--json"]))["zone"] == "unknown")
check("and fires no nudge", e.run(["hook-post"], {"session_id": "pppp"}) == "")

# The session's own crons are not the owner, even with no known prefix.
L = "llll9999-0000-0000-0000-000000000000"
e.transcript(L, 1, 230000)
e.set(92, reset_in_min=150)
e.run(["record", "--strategy", "resume", "--sid", "llll9999"])
e.scheduled(L, "check CI on PR 412 and report")
c = ctx(e.prompt(L, "check CI on PR 412 and report"))
check("a self-scheduled cron while hibernating is a notification, not a cancel", "hibernating" in c, c)
for grace in ("[Usage limit reached; a short grace allowance remains", "[Earlier usage-limit notes no longer apply.]"):
    check("harness text does not cancel: " + grace[:22], "hibernating" in ctx(e.prompt(L, grace)))
check("the hibernation survived them", "Carry on" in ctx(e.prompt(L, RESUME)))

# Coming back from hibernation re-links keep-warm when it is on.
open(e.kw_switch, "w").close()
M = "mmmm0000-0000-0000-000000000000"
e.transcript(M, 1, 230000)
e.set(92, reset_in_min=150)
e.run(["record", "--strategy", "resume", "--sid", "mmmm0000"])
c = ctx(e.prompt(M, RESUME))
check("a resume re-arms keep-warm", "[keepwarm] idle check" in c, c)
os.remove(e.kw_switch)

# Subagents count toward the share.
e.set(85, agents=1)
before = json.loads(e.run(["pressure", "--json"]))["agents"]
for a in ("sub-1", "sub-2", "sub-3"):
    e.run(["hook-post"], {"session_id": "nnnn1111-0000", "agent_id": a})
e.run(["hook-post"], {"session_id": "nnnn1111-0000", "agent_id": "sub-1"})
p = json.loads(e.run(["pressure", "--json"]))
check("three live subagents add three agents, each counted once", p["agents"] == before + 3,
      "before %s after %s" % (before, p["agents"]))

# A hibernation record survives subagent hooks firing on the same state.
e.set(92, reset_in_min=150)
O = "oooo2222-0000-0000-0000-000000000000"
e.transcript(O, 1, 230000)
env = dict(os.environ, USAGE5H_LIMITS=e.limits, USAGE5H_TURN_STATE=e.turn, USAGE5H_DIR=e.dir,
           USAGE5H_PROJECTS=e.projects, USAGE5H_WAKES=e.wakes)
# A subagent hook holds the state for a second; `record` lands in the middle of it.
# Without the lock the hook's save, made from its stale read, erases the record.
post = subprocess.Popen([sys.executable, SCRIPT, "hook-post"], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
                        env=dict(env, USAGE5H_TEST_HOLD_S="1.0"), text=True)
post.stdin.write(json.dumps({"session_id": O, "agent_id": "slow"}))
post.stdin.close()
time.sleep(0.4)
subprocess.run([sys.executable, SCRIPT, "record", "--strategy", "resume", "--sid", "oooo2222"],
               stdout=subprocess.DEVNULL, env=env)
post.wait()
with open(os.path.join(e.dir, O + ".json")) as f:
    kept = "hibernate" in json.load(f)
check("a hibernation record survives a subagent hook writing at the same moment", kept)

# The real incident: clanky-opus, cut at the reset prompt, must not be resumed.
REAL = os.path.expanduser("~/.claude/projects/-Users-alcatraz627-Code-Versable-slack-automation/"
                          "6b32d198-4cdc-46a2-84c3-578bae6b4f4b.jsonl")
if os.path.exists(REAL):
    cut = os.path.join(e.root, "clanky-cut.jsonl")
    with open(REAL, errors="replace") as src, open(cut, "w") as dst:
        for line in src:
            if '"timestamp":"2026-10-21T17:51:15' in line:
                break
            dst.write(line)
    S9 = "6b32d198-4cdc-46a2-84c3-578bae6b4f4b"
    check("replay: clanky-opus's native resume is skipped", blocked(e.prompt(S9, NATIVE, cut)))
    check("replay: so is an own wake", blocked(e.prompt(S9, RESUME, cut)))
else:
    print("skip real-transcript replay (transcript not on this machine)")

# The manual takeover path runs end to end on a session with no dump (it once crashed on first use).
R = "abcd3333-0000-0000-0000-000000000000"   # session ids are hex, and the resolver checks that
e.transcript(R, 30, 230000)
out_md = os.path.join(e.root, "digest.md")
r = subprocess.run([sys.executable, os.path.join(HERE, "resume-from.py"), "abcd3333", "--out", out_md],
                   capture_output=True, text=True, env=dict(env), timeout=120)
check("resume-from writes a digest for a session with no dump", r.returncode == 0 and os.path.exists(out_md)
      and "## Open tasks" in open(out_md).read(), r.stderr[-300:])

print("\n%d failed" % len(fails) if fails else "\nall passed")
sys.exit(1 if fails else 0)
