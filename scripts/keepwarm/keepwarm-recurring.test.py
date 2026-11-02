"""Checks keep-warm's recurring job, its decision function, the return model, the cold gate and /away.

Run: python3 ~/.claude/scripts/keepwarm/keepwarm-recurring.test.py
"""
import datetime as dt
import importlib.util
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
open(SWITCH, "w").close()
LIMITS = os.path.join(T, "limits.json")
MODEL = os.path.join(T, "model.json")
INDEX = os.path.join(T, "index.jsonl")
# Copernican coefficients: 50% at an hour away, 25% at 3 hours, whatever the clock says.
json.dump({"coef": [0, -1, 0, 0, 0, 0]}, open(MODEL, "w"))
ENV = dict(os.environ, KEEPWARM_DIR=os.path.join(T, "kw"), KEEPWARM_SWITCH=SWITCH, CLAUDE_CODE_ENTRYPOINT="cli",
           KEEPWARM_NO_STATUSLINE="1", USAGE5H_LIMITS=LIMITS, USAGE5H_DIR=os.path.join(T, "u5"),
           USAGE5H_CLAUDE_JSON=os.path.join(T, "claude.json"), KEEPWARM_TASK_STORE=os.path.join(T, "tasks"),
           KEEPWARM_ONESHOT_FILE=os.path.join(T, "oneshot"), KEEPWARM_MODEL=MODEL, KEEPWARM_HOUR="15",
           KEEPWARM_COLD_GATE_MUTE=os.path.join(T, "mute"), KEEPWARM_CHECKPOINTS=INDEX,
           USAGE_GATE_FILE=os.path.join(T, "gate.json"), USAGE_GATE_PCT="90")
os.makedirs(ENV["KEEPWARM_TASK_STORE"])
json.dump({"oauthAccount": {"organizationUuid": "org-a"}}, open(ENV["USAGE5H_CLAUDE_JSON"], "w"))
json.dump({"5h": {"pct": 10}, "week": {"pct": 10}}, open(ENV["USAGE_GATE_FILE"], "w"))


def limits(pct, reset_s=7200):
    json.dump({"5h": {"pct": pct}, "resets_at": str(int(time.time() + reset_s))}, open(LIMITS, "w"))


limits(10)


def transcript(tokens, age_min=None):
    p = os.path.join(T, "t-%d-%s.jsonl" % (tokens, age_min))
    row = {"type": "assistant", "message": {"usage": {"input_tokens": 0, "cache_read_input_tokens": tokens,
                                                      "cache_creation_input_tokens": 0}}}
    if age_min is not None:
        when = dt.datetime.now(dt.timezone.utc) - dt.timedelta(minutes=age_min)
        row["timestamp"] = when.isoformat().replace("+00:00", "Z")
    open(p, "w").write(json.dumps(row) + "\n")
    return p


def hook(cmd, env=None, **inp):
    r = subprocess.run([sys.executable, KW, cmd], input=json.dumps(inp), capture_output=True, text=True, env=env or ENV)
    return json.loads(r.stdout) if r.stdout.strip() else {}


def state(sid):
    return json.load(open(os.path.join(T, "kw", sid + ".json")))


def set_state(sid, **kw):
    st = state(sid)
    st.update(kw)
    json.dump(st, open(os.path.join(T, "kw", sid + ".json"), "w"))


def ctx(out):
    return (out.get("hookSpecificOutput") or {}).get("additionalContext", "")


def begin(sid):
    """A session that has armed its job and finished a turn."""
    hook("hook-start", session_id=sid)
    hook("hook-prompt", session_id=sid, prompt="work")
    hook("hook-stop", session_id=sid)


def fire(sid, tokens=300000, cache=45, away=None, env=None):
    now = time.time()
    set_state(sid, last_activity=now - cache * 60, work_at=now - (away if away is not None else cache) * 60)
    return hook("hook-prompt", env=env, session_id=sid, prompt="[keepwarm] idle check",
                transcript_path=transcript(tokens), cwd="/tmp/proj")


def events(sid):
    path = os.path.join(T, "kw", "events.jsonl")
    return [r for r in map(json.loads, open(path)) if r["sid"] == sid] if os.path.exists(path) else []


# Claude Code discards a block from an async hook, so a passing test above proves nothing
# unless the real registration can deliver it. Reads the live settings file.
with open(os.path.expanduser("~/.claude/settings.json")) as f:
    registered = [h for g in json.load(f)["hooks"]["Stop"] for h in g["hooks"] if "keepwarm.py hook-stop" in h.get("command", "")]
expect("the Stop hook is registered once", len(registered) == 1)
expect("the Stop hook is not async, so its block reaches the session", not registered[0].get("async"))


def job_transcript(name, rows):
    """A transcript holding the given rows, for checking what counts as a created job."""
    p = os.path.join(T, "job-%s.jsonl" % name)
    with open(p, "w") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")
    return p


def cron_row(prompt="[keepwarm] idle check", age_s=0):
    when = dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=-age_s)
    return {"type": "assistant", "timestamp": when.isoformat().replace("+00:00", "Z"), "message": {"content": [
        {"type": "tool_use", "name": "CronCreate", "input": {"cron": "1-59/20 * * * *", "prompt": prompt}}]}}


# The model was told to create its job and did not (the ~/Movies session, 2026-11-02).
quiet = job_transcript("none", [{"type": "assistant", "message": {"content": [{"type": "text", "text": "done"}]}}])
hook("hook-start", session_id="jm1")
hook("hook-prompt", session_id="jm1", prompt="work")
out = hook("hook-stop", session_id="jm1", transcript_path=quiet)
expect("a turn that never created the job is blocked once", out.get("decision") == "block")
expect("the block carries the arm instruction", "CronCreate" in out.get("reason", ""))
expect("the statusline no longer promises a ping", "armed_at" not in state("jm1"))
out = hook("hook-stop", session_id="jm1", transcript_path=quiet, stop_hook_active=True)
expect("the re-asked turn is not blocked again", out == {})
expect("and an unconfirmed job still promises no ping", "armed_at" not in state("jm1"))

# Created after being told: confirmed, and the statusline may show the ping.
made = job_transcript("made", [cron_row()])
hook("hook-start", session_id="jm2")
hook("hook-prompt", session_id="jm2", prompt="work")
time.sleep(0.01)
made = job_transcript("made", [cron_row()])
out = hook("hook-stop", session_id="jm2", transcript_path=made)
expect("a created job is not re-asked", out == {})
expect("a created job is recorded", state("jm2").get("job_seen") is True)
expect("a created job shows its next ping", "armed_at" in state("jm2"))

# A job from before a resume died with its process, so it does not count.
old = job_transcript("old", [cron_row(age_s=3600)])
hook("hook-start", session_id="jm3", source="resume")
hook("hook-prompt", session_id="jm3", prompt="work")
out = hook("hook-stop", session_id="jm3", transcript_path=old)
expect("a job older than the instruction does not count", out.get("decision") == "block")

# Reading about the job is not creating it, nor is a job for something else. Each row
# carries a real tool_use shape, so only the check it is aimed at can reject it, and a
# mention of [keepwarm] keeps the other job's row past the fast string filter.
for sid, row_type, prompt, label in (
        ("jm4a", "user", "[keepwarm] idle check", "a user row quoting the tool call does not count"),
        ("jm4b", "assistant", "[other] thing, not the [keepwarm] job", "a job for something else does not count")):
    hook("hook-start", session_id=sid)
    hook("hook-prompt", session_id=sid, prompt="work")
    time.sleep(0.01)
    # Stamped after the instruction, so its age cannot be what rejects it.
    row = cron_row(prompt=prompt)
    row["type"] = row_type
    out = hook("hook-stop", session_id=sid, transcript_path=job_transcript(sid, [row]))
    expect(label, out.get("decision") == "block")

# The re-ask is capped, so a model that keeps ignoring it cannot nag every turn.
hook("hook-start", session_id="jm5")
hook("hook-prompt", session_id="jm5", prompt="work")
results = [hook("hook-stop", session_id="jm5", transcript_path=quiet).get("decision") for _ in range(5)]
expect("re-asks stop after the cap", results == ["block", "block", "block", None, None])
expect("giving up is logged once", sum(e["ev"] == "arm-failed" for e in events("jm5")) == 1)

# A fired wake proves the job, and an unreadable transcript never blocks.
hook("hook-start", session_id="jm6")
hook("hook-prompt", session_id="jm6", prompt="work")
out = hook("hook-stop", session_id="jm6", transcript_path=os.path.join(T, "missing.jsonl"))
expect("an unreadable transcript does not block", out == {})
hook("hook-start", session_id="jm7")
hook("hook-prompt", session_id="jm7", prompt="work")
hook("hook-stop", session_id="jm7", transcript_path=quiet, stop_hook_active=True)
expect("no job is confirmed before a wake", state("jm7").get("job_seen") is None)
expect("and no ping is promised for it, even with no re-ask", "armed_at" not in state("jm7"))
hook("hook-prompt", session_id="jm7", prompt="[keepwarm] idle check")
expect("a wake arriving confirms the job", state("jm7").get("job_seen") is True)
out = hook("hook-stop", session_id="jm7", transcript_path=quiet)
expect("and a confirmed job is not asked for again", out.get("decision") != "block")

# What the first validation found unpinned.
hook("hook-start", session_id="jm9")
hook("hook-prompt", session_id="jm9", prompt="work")
for _ in range(4):
    hook("hook-stop", session_id="jm9", transcript_path=quiet)
set_state("jm9", recurring_at=time.time() - 8 * 86400, job_seen=False)
hook("hook-prompt", session_id="jm9", prompt="back again")
out = hook("hook-stop", session_id="jm9", transcript_path=quiet)
expect("a session that used its asks is asked again after a relink", out.get("decision") == "block")

hook("hook-start", session_id="jm10")
hook("hook-prompt", session_id="jm10", prompt="work")
time.sleep(0.01)
hook("hook-stop", session_id="jm10", transcript_path=job_transcript("m10", [cron_row()]))
expect("a confirmed job is recorded before a resume", state("jm10").get("job_seen") is True)
hook("hook-start", session_id="jm10", source="resume")
hook("hook-prompt", session_id="jm10", prompt="work")
expect("a resume forgets the old job, which died with its process", state("jm10").get("job_seen") is None)
out = hook("hook-stop", session_id="jm10", transcript_path=quiet)
expect("so a resumed session must create it again", out.get("decision") == "block")

hook("hook-start", session_id="jm11")
hook("hook-prompt", session_id="jm11", prompt="work")
set_state("jm11", stopped=True)
expect("a finished session is not asked", hook("hook-stop", session_id="jm11", transcript_path=quiet) == {})
hook("hook-start", session_id="jm12")
hook("hook-prompt", session_id="jm12", prompt="work")
off = dict(ENV, KEEPWARM_SWITCH=os.path.join(T, "absent"))
expect("with the switch off nobody is asked", hook("hook-stop", env=off, session_id="jm12", transcript_path=quiet) == {})
hook("hook-start", session_id="jm13")
hook("hook-prompt", session_id="jm13", prompt="work")
open(ENV["KEEPWARM_ONESHOT_FILE"], "w").close()
expect("one-shot mode is not asked", hook("hook-stop", session_id="jm13", transcript_path=quiet) == {})
os.unlink(ENV["KEEPWARM_ONESHOT_FILE"])

hook("hook-start", session_id="jm14")
hook("hook-prompt", session_id="jm14", prompt="work")
time.sleep(0.01)
timeless = cron_row()
del timeless["timestamp"]
expect("a job row with no time counts as created", hook("hook-stop", session_id="jm14", transcript_path=job_transcript("m14", [timeless])) == {})

hook("hook-start", session_id="jm15")
hook("hook-prompt", session_id="jm15", prompt="work")
for _ in range(4):
    hook("hook-stop", session_id="jm15", transcript_path=quiet)
hook("hook-start", session_id="jm15", source="resume")
hook("hook-prompt", session_id="jm15", prompt="work")
expect("a new start gets a new budget", hook("hook-stop", session_id="jm15", transcript_path=quiet).get("decision") == "block")

hook("hook-start", session_id="jm16")
hook("hook-prompt", session_id="jm16", prompt="work")
time.sleep(0.01)
other_tool = cron_row()
other_tool["message"]["content"][0]["name"] = "SomeOtherTool"
other_tool["message"]["content"][0]["input"]["note"] = "CronCreate"
expect("another tool with the same words does not count", hook("hook-stop", session_id="jm16", transcript_path=job_transcript("m16", [other_tool])).get("decision") == "block")

hook("hook-start", session_id="jm17")
hook("hook-prompt", session_id="jm17", prompt="work")
time.sleep(0.01)
filler = [{"type": "assistant", "message": {"content": [{"type": "text", "text": "x" * 1000}]}}] * 1200
expect("a job a megabyte back in the transcript is still seen", hook("hook-stop", session_id="jm17", transcript_path=job_transcript("m17", [cron_row()] + filler)) == {})

# Headless and switched-off sessions are never asked.
hook("hook-start", session_id="jm8")
hook("hook-prompt", session_id="jm8", prompt="work")
out = hook("hook-stop", env=dict(ENV, CLAUDE_CODE_ENTRYPOINT="sdk-cli"), session_id="jm8", transcript_path=quiet)
expect("a headless session is not asked", out == {})

# Decision function, with plain numbers.
spec = importlib.util.spec_from_file_location("keepwarm_mod", KW)
os.environ.update({k: ENV[k] for k in ("KEEPWARM_MODEL", "KEEPWARM_DIR", "KEEPWARM_SWITCH")})
K = importlib.util.module_from_spec(spec)
spec.loader.exec_module(K)

# Rows Claude Code never writes must not crash the search for the job.
odd = job_transcript("m18", [["CronCreate", "[keepwarm]"], {"type": "assistant", "message": "CronCreate [keepwarm]"},
                             {"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "CronCreate", "input": ["[keepwarm]"]}]}}])
expect("malformed rows are not a job, and do not raise", K.job_created_since(odd, 0) is False)


def step(ctx_tokens=300000, pct=10, reset_min=120, gated=False, wakes=0, away=60, cache=45, hour=15, hint=None,
         chains=1, left=None, dumped=False):
    return K.next_step(ctx_tokens, pct, reset_min, 98, gated, wakes, away, cache, hour, hint, 1000.0, chains, left, dumped)[0]


expect("a fresh cache waits", step(cache=30) == "wait")
expect("a due fire pings while return is likely", step(cache=45, away=60) == "warm")
expect("unlikely return dumps instead", step(ctx_tokens=800000, cache=45, away=600) == "dump")
expect("a small session is held longer than a large one at the same point",
       step(ctx_tokens=100000, away=400) == "warm" and step(ctx_tokens=1000000, away=400) == "dump")
expect("a cold cache never pings, whatever else is true", step(cache=70, hint={"until": 9e9, "kind": "hard"}) == "stop")
expect("95% writes the mini dump", step(pct=96) == "mini")
expect("the window not lasting writes the full dump", step(pct=90, reset_min=120) == "dump")
expect("a closed usage gate writes the full dump", step(gated=True) == "dump")
expect("no window dump for someone just here", step(pct=96, away=5, cache=45) == "warm")
expect("a spent window with someone just here waits", step(pct=99, away=5, cache=45) == "wait")
expect("a window dump already written ends it", step(pct=96, dumped=True) == "stop")
expect("a hold pings past where the rule would dump", step(ctx_tokens=800000, away=600, hint={"until": 2000, "kind": "soft"}) == "warm")
expect("a hold that ran out goes back to the rule", step(ctx_tokens=800000, away=600, hint={"until": 500, "kind": "hard"}) == "dump")
expect("a hold still waits for the cache to need it", step(cache=10, hint={"until": 2000, "kind": "hard"}) == "wait")
expect("a hard hold carries on after a window dump", step(pct=90, dumped=True, hint={"until": 2000, "kind": "hard"}) == "warm")
expect("a soft hold does not", step(pct=90, dumped=True, hint={"until": 2000, "kind": "soft"}) == "stop")
expect("a hard hold still gives way to the mini line", step(pct=96, dumped=True, hint={"until": 2000, "kind": "hard"}) == "stop")
expect("done dumps at the next fire, due or not", step(cache=2, away=2, hint={"done": True}) == "dump")
expect("done after a dump stops", step(cache=2, away=2, hint={"done": True}, dumped=True) == "stop")
expect("all tasks done dumps on the first ping", step(left=False, wakes=0) == "dump")
expect("but a hold outranks that", step(left=False, wakes=0, hint={"until": 2000, "kind": "soft"}) == "warm")
expect("pings are capped", step(wakes=K.MAX_PINGS, ctx_tokens=100, away=60) == "dump")
expect("not knowing the window is not an alarm", step(pct=None, reset_min=None) == "warm")
expect("same numbers, same answer", all(step(away=200) == step(away=200) for _ in range(5)))

# Each session its own minute, and never on the hour.
specs = [K.cron_spec("session-%d" % i) for i in range(20)]
expect("job minutes are spread out and valid", len(set(specs)) > 3 and all(s.endswith("-59/20 * * * *") and not s.startswith("0-") for s in specs))
expect("a session keeps its minute", K.cron_spec("abc") == K.cron_spec("abc"))

# Real saved model: the owner's rhythm, if a fit exists on this machine.
spec_m = importlib.util.spec_from_file_location("return_model", os.path.join(HERE, "return_model.py"))
M = importlib.util.module_from_spec(spec_m)
spec_m.loader.exec_module(M)
expect("the Copernican prior is 50% at an hour away", abs(M.predict(M.PRIOR, 60, 12) - 0.5) < 1e-9)
expect("the prior gives 25% at 3 hours away", abs(M.predict(M.PRIOR, 180, 12) - 0.25) < 1e-9)
synthetic = [(M.features(a, h), 1.0 if a < 100 and i % 10 else 0.0, a, h) for i, (a, h) in enumerate(
    (a, h) for a in M.CHECKPOINTS for h in range(24) for _ in range(5))]
fitted = M.fit_logistic(synthetic)
expect("a fit moves away from the prior on enough data", M.predict(fitted, 30, 12) > 0.7 and M.predict(fitted, 480, 12) < 0.2)
thin = M.fit_logistic([(M.features(60, 12), 1.0, 60, 12)] * 3)
expect("a few rows barely move the prior", abs(M.predict(thin, 180, 12) - 0.25) < 0.1)
real = os.path.expanduser("~/.claude/keepwarm/return-model.json")
if os.path.exists(real):
    coef = json.load(open(real))["coef"]
    expect("real model: longer away, lower chance", M.predict(coef, 55, 15) > M.predict(coef, 165, 15) > M.predict(coef, 480, 15))
    expect("real model: more likely by day than at night at 2 hours", M.predict(coef, 110, 15) > M.predict(coef, 110, 3))
    expect("real model: no hard edge across 23:00", abs(M.predict(coef, 110, 22.9) - M.predict(coef, 110, 23.1)) < 0.03)

# The job itself.
out = hook("hook-start", session_id="a1")
expect("session start arms one recurring job", "recurring true" in ctx(out) and "-59/20" in ctx(out) and "delete any job" in ctx(out))
expect("the arm comes after the answer", "Answer the owner's next message first" in ctx(out))
begin("a2")
out = fire("a2", cache=10)
expect("a fire that is not due is blocked with no turn", out.get("decision") == "block")
expect("and leaves no in-flight marker", "in_wake" not in state("a2"))
expect("and is logged for the review", any(e["ev"] == "wait" for e in events("a2")))
expect("and does not move any clock", state("a2")["wakes"] == 0)
out = fire("a2", cache=45)
expect("a due fire gets one cached turn", "only keeps the cache warm" in ctx(out) and "decision" not in out)
expect("with no re-arm to get wrong", "CronCreate" not in ctx(out))
expect("the wake records its reasoning", [e for e in events("a2") if e["ev"] == "wake"][-1].get("chance") is not None)
expect("a ping refreshes the cache clock but not time away", time.time() - state("a2")["last_activity"] < 60
       and time.time() - state("a2")["work_at"] > 40 * 60)
wake_at = state("a2")["last_activity"]
work_at = state("a2")["work_at"]
hook("hook-stop", session_id="a2")
expect("a wake's Stop leaves the clocks alone", state("a2")["last_activity"] == wake_at and state("a2")["work_at"] == work_at)
expect("a ping does not make the owner look back", state("a2")["wakes"] == 1)

begin("a3")
out = fire("a3", tokens=900000, away=600)
expect("the last wake dumps", "full /core-dump" in ctx(out))
expect("and removes its own job", "CronDelete" in ctx(out))
expect("and is finished", state("a3")["stopped"] is True and "recurring_at" not in state("a3"))
expect("later fires are blocked", fire("a3").get("decision") == "block")
out = hook("hook-prompt", session_id="a3", prompt="back")
expect("the owner returning arms it again", "no wake is pending" in ctx(out) and "recurring true" in ctx(out))
expect("and only once", ctx(hook("hook-prompt", session_id="a3", prompt="next")) == "")

begin("a4")
limits(96)
out = fire("a4", away=60)
expect("above 95% a fire writes the mini dump", "/core-dump mini" in ctx(out) and "96%" in ctx(out) and "Build the full dump" in ctx(out))
limits(10)

begin("a5")
limits(100)
expect("a full window blocks", fire("a5", cache=45).get("decision") == "block")
expect("without ending the job", "recurring_at" in state("a5") and not state("a5").get("stopped"))
limits(10)
expect("so it recovers by itself when the window resets", "only keeps the cache warm" in ctx(fire("a5", cache=45)))

begin("a6")
out = fire("a6", cache=70)
expect("a cold cache is not pinged", out.get("decision") == "block" and state("a6")["stopped"] is True)
expect("and says why in the log", any("cold" in e.get("why", "") for e in events("a6")))

# Sessions already running on a one-shot move over at their next fire.
hook("hook-prompt", session_id="a7", prompt="work")
hook("hook-stop", session_id="a7")
st = state("a7")
st.pop("recurring_at", None)
json.dump(st, open(os.path.join(T, "kw", "a7.json"), "w"))
out = hook("hook-prompt", session_id="a7", prompt="[keepwarm] idle check", transcript_path=transcript(300000))
expect("an old one-shot session is moved over", "recurring true" in ctx(out) and "one word: warm" in ctx(out))
expect("that turn is not counted as a ping", state("a7")["wakes"] == 0 and state("a7").get("in_wake") is True)

begin("a8")
set_state("a8", recurring_at=time.time() - 7 * 86400)
expect("a job about to expire is replaced at the owner's next prompt",
       "recurring true" in ctx(hook("hook-prompt", session_id="a8", prompt="x")))
begin("a9")
out = hook("hook-prompt", session_id="a9", prompt="/core-dump")
expect("an owner /core-dump removes the job", "CronDelete" in ctx(out) and "CronCreate" not in ctx(out))
expect("/clear arms nothing", hook("hook-start", session_id="a10", source="clear") == {})

# Revert path.
open(ENV["KEEPWARM_ONESHOT_FILE"], "w").close()
out = hook("hook-start", session_id="b1")
expect("with the revert file, sessions use the one-shot", "recurring false" in ctx(out))
hook("hook-prompt", session_id="b1", prompt="work")
hook("hook-stop", session_id="b1")
out = fire("b1", cache=10)
expect("and a not-due fire takes a turn as before", "not due" in ctx(out) and "decision" not in out)
os.remove(ENV["KEEPWARM_ONESHOT_FILE"])

# The cold gate.
begin("c1")
cold = transcript(500000, age_min=180)
out = hook("hook-prompt", session_id="c1", prompt="hello again", transcript_path=cold)
expect("a message to a cold session is blocked", out.get("decision") == "block")
expect("with the idle time and the rebuild size", "3h 00m" in out.get("reason", "") and "500k" in out.get("reason", ""))
expect("and how to go ahead", "again within" in out.get("reason", "") and "/catchup" in out.get("reason", ""))
expect("no suppressOutput, so the owner sees it", "suppressOutput" not in out)
set_state("c1", wakes=2)
before = state("c1")["last_activity"]
out = hook("hook-prompt", session_id="c1", prompt="hello again", transcript_path=cold)
expect("sending again goes through", out.get("decision") != "block")
expect("and only then counts as the owner returning", state("c1")["last_activity"] > before and state("c1")["wakes"] == 0)
expect("the gate re-arms for the next absence", "cold_asked_at" not in state("c1"))
begin("c2")
hook("hook-prompt", session_id="c2", prompt="x", transcript_path=cold)
set_state("c2", wakes=2)
snapshot = state("c2")["last_activity"]
expect("a blocked send does not look like the owner returning", state("c2")["wakes"] == 2 and state("c2")["last_activity"] == snapshot)
set_state("c2", cold_asked_at=time.time() - 11 * 60)
expect("a confirmation too late asks again", hook("hook-prompt", session_id="c2", prompt="x", transcript_path=cold).get("decision") == "block")
begin("c3")
expect("a warm session is not asked", hook("hook-prompt", session_id="c3", prompt="x", transcript_path=transcript(500000, 30)).get("decision") != "block")
expect("a small session is not asked", hook("hook-prompt", session_id="c3", prompt="x", transcript_path=transcript(50000, 180)).get("decision") != "block")
expect("/clear is never asked", hook("hook-prompt", session_id="c3", prompt="/clear", transcript_path=cold).get("decision") != "block")
expect("a transcript with no times is never asked", hook("hook-prompt", session_id="c3", prompt="x", transcript_path=transcript(500000)).get("decision") != "block")
env_p = dict(ENV, CLAUDE_CODE_ENTRYPOINT="sdk-cli")
expect("a headless run is never asked", hook("hook-prompt", env=env_p, session_id="c3", prompt="x", transcript_path=cold).get("decision") != "block")
open(ENV["KEEPWARM_COLD_GATE_MUTE"], "w").close()
begin("c4")
expect("the mute works", hook("hook-prompt", session_id="c4", prompt="x", transcript_path=cold).get("decision") != "block")
os.remove(ENV["KEEPWARM_COLD_GATE_MUTE"])
begin("c5")
expect("a task notification is not asked", hook("hook-prompt", session_id="c5", prompt="<task-notification> done", transcript_path=cold).get("decision") != "block")
set_state("c5", last_activity=time.time() - 45 * 60, work_at=time.time() - 45 * 60)
expect("a keep-warm fire is not asked", "Cache is cold" not in hook("hook-prompt", session_id="c5", prompt="[keepwarm] idle check", transcript_path=cold).get("reason", ""))
json.dump({"kind": "core-dump", "session_id": "named", "session_uuid": "c6", "checkpoint_path": "/x/_dump.claude.md"}, open(INDEX, "w"))
begin("c6")
out = hook("hook-prompt", session_id="c6", prompt="x", transcript_path=cold)
expect("the gate offers this session's newest dump", "/x/_dump.claude.md" in out.get("reason", ""))

# /away, as an agent would run it.


def away(sid, *args):
    env = dict(ENV, CLAUDE_CODE_SESSION_ID=sid)
    return subprocess.run([sys.executable, KW, "away"] + list(args), capture_output=True, text=True, env=env)


begin("d1")
r = away("d1", "3h", "reading the docs")
hint = state("d1")["hint"]
expect("/away 3h records a hard hold", r.returncode == 0 and hint["kind"] == "hard" and abs(hint["until"] - time.time() - 10800) < 60)
expect("it does not touch the clocks or stop anything", not state("d1").get("stopped"))
expect("a held session pings past where the rule would dump", "only keeps the cache warm" in ctx(fire("d1", tokens=900000, away=600)))
hook("hook-prompt", session_id="d1", prompt="back early")
expect("the owner's next message clears the hold", "hint" not in state("d1"))
begin("d2")
away("d2", "3h")
expect("an agent's soft hold does not replace the owner's", "keeping the owner" in away("d2", "1h", "--soft").stdout and state("d2")["hint"]["kind"] == "hard")
begin("d3")
away("d3", "1h", "--soft")
expect("the owner's replaces a soft one", away("d3", "4h").returncode == 0 and state("d3")["hint"]["kind"] == "hard")
begin("d4")
away("d4", "done", "wrapping up")
expect("/away done is recorded and stops nothing yet", state("d4")["hint"]["done"] is True and not state("d4").get("stopped"))
expect("the next fire dumps and stops", "full /core-dump" in ctx(fire("d4", cache=2, away=2)) and state("d4")["stopped"] is True)
begin("d5")
away("d5", "3h")
expect("/away soon clears a hold", away("d5", "soon").returncode == 0 and "hint" not in state("d5"))
begin("d6")
expect("a clock time works", away("d6", "23:59").returncode == 0 and state("d6")["hint"]["until"] > time.time())
expect("nonsense is refused", away("d6", "whenever").returncode == 2)
begin("d7")
set_state("d7", ctx=600000)
expect("a long hold states its price", "costs" in away("d7", "8h").stdout)
expect("a short one does not", "costs" not in away("d7", "1h").stdout)
env_plan = dict(ENV, CLAUDE_CODE_SESSION_ID="d7")
plan = subprocess.run([sys.executable, KW, "plan"], capture_output=True, text=True, env=env_plan)
expect("plan prints the next step and why", plan.returncode == 0 and "next fire:" in plan.stdout and "chance of return" in plan.stdout)

expect("bad hook input never blocks", subprocess.run([sys.executable, KW, "hook-prompt"], input="not json", capture_output=True, text=True, env=ENV).returncode == 0)
finish()
