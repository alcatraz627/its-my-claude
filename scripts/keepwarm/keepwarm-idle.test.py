"""Checks keep-warm's quiet background waiter: it wakes the model only when something is
due, stays silent otherwise, and gives way to any newer turn.

Run: python3 ~/.claude/scripts/keepwarm/keepwarm-idle.test.py
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
open(SWITCH, "w").close()
MODEL = os.path.join(T, "model.json")
json.dump({"coef": [0, -1, 0, 0, 0, 0]}, open(MODEL, "w"))
ENV = dict(os.environ, KEEPWARM_DIR=os.path.join(T, "kw"), KEEPWARM_SWITCH=SWITCH, CLAUDE_CODE_ENTRYPOINT="cli",
           KEEPWARM_NO_STATUSLINE="1", USAGE5H_LIMITS=os.path.join(T, "limits.json"), USAGE5H_DIR=os.path.join(T, "u5"),
           USAGE5H_CLAUDE_JSON=os.path.join(T, "claude.json"), KEEPWARM_TASK_STORE=os.path.join(T, "tasks"),
           KEEPWARM_ONESHOT_FILE=os.path.join(T, "oneshot"), KEEPWARM_CRON_FILE=os.path.join(T, "cron"),
           KEEPWARM_MODEL=MODEL, KEEPWARM_HOUR="15", KEEPWARM_COLD_GATE_MUTE=os.path.join(T, "mute"),
           KEEPWARM_CHECKPOINTS=os.path.join(T, "index.jsonl"), USAGE_GATE_FILE=os.path.join(T, "gate.json"),
           USAGE_GATE_PCT="90", KEEPWARM_IDLE_SETTLE_S="0", KEEPWARM_IDLE_TICK_S="0.2")
os.makedirs(ENV["KEEPWARM_TASK_STORE"])
os.makedirs(ENV["KEEPWARM_DIR"])
json.dump({"5h": {"pct": 10}, "week": {"pct": 10}}, open(ENV["USAGE_GATE_FILE"], "w"))
json.dump({"oauthAccount": {"organizationUuid": "org-a"}}, open(ENV["USAGE5H_CLAUDE_JSON"], "w"))


def state(sid, **fields):
    now = time.time()
    st = dict(last_activity=now, work_at=now, wakes=0, stopped=False, answered=True, account="org-a")
    st.update(fields)
    json.dump(st, open(os.path.join(ENV["KEEPWARM_DIR"], sid + ".json"), "w"))


def read_state(sid):
    return json.load(open(os.path.join(ENV["KEEPWARM_DIR"], sid + ".json")))


def idle(sid, timeout=8, env=None):
    return subprocess.run([sys.executable, KW, "hook-idle"], input=json.dumps({"session_id": sid}),
                          capture_output=True, text=True, env=env or ENV, timeout=timeout)


def hook(cmd, **inp):
    r = subprocess.run([sys.executable, KW, cmd], input=json.dumps(inp), capture_output=True, text=True, env=ENV)
    return json.loads(r.stdout) if r.stdout.strip() else {}


def ago(minutes):
    return time.time() - minutes * 60


# A due cache wakes the model, and the instruction reaches it on stderr.
state("due", last_activity=ago(53), work_at=ago(53))
r = idle("due")
expect("a due session wakes the model", r.returncode == 2)
expect("with the one word instruction", "Keep-warm wake 1" in r.stderr and "warm" in r.stderr)
expect("and no job to delete", "CronDelete" not in r.stderr)
expect("nothing on stdout", r.stdout == "")
st = read_state("due")
expect("the wake is recorded", st["wakes"] == 1 and st.get("in_wake") is True)
expect("the cache clock moves", time.time() - st["last_activity"] < 5)

# The wake reaches the session as a prompt, which must not read as the owner or end the ping.
marker = os.path.join(T, "wake")
os.makedirs(marker)
wake_env = dict(ENV, KEEPWARM_WAKE_DIR=marker)
state("mk", last_activity=ago(53), work_at=ago(53))
idle("mk", env=wake_env)
flag = os.path.join(marker, "claude-keepwarm-wake-mk")
expect("a wake marks its turn, so advice gates can skip it", os.path.exists(flag))
subprocess.run([sys.executable, KW, "hook-prompt"], capture_output=True, text=True, env=wake_env,
               input=json.dumps({"session_id": "mk", "prompt": "<task-notification>\n<summary>Stop hook feedback</summary>"}))
expect("the wake's own prompt keeps that mark", os.path.exists(flag))
expect("and is not the owner returning", read_state("mk")["wakes"] == 1)
subprocess.run([sys.executable, KW, "hook-prompt"], capture_output=True, text=True, env=wake_env,
               input=json.dumps({"session_id": "mk", "prompt": "the owner is back"}))
expect("the owner's prompt clears it", not os.path.exists(flag))
expect("and resets the count", read_state("mk")["wakes"] == 0)

# Nothing due: the waiter keeps waiting, and printing nothing is the whole point.
state("wait", last_activity=ago(1), work_at=ago(1))
p = subprocess.Popen([sys.executable, KW, "hook-idle"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=subprocess.PIPE, text=True, env=ENV)
p.stdin.write(json.dumps({"session_id": "wait"}))
p.stdin.close()
time.sleep(1.5)
expect("a session that is not due keeps waiting", p.poll() is None)

# Any new turn replaces it: a prompt does not stop the process, so it must notice.
hook("hook-prompt", session_id="wait", prompt="the owner is back")
out, err = p.stdout.read(), p.stderr.read()
expect("a new prompt ends the waiter", p.wait(timeout=5) == 0)
expect("silently", out == "" and err == "")

# A later waiter replaces an earlier one, so two turns cannot ping the same cache twice.
state("two", last_activity=ago(1), work_at=ago(1))
first = subprocess.Popen([sys.executable, KW, "hook-idle"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE, text=True, env=ENV)
first.stdin.write(json.dumps({"session_id": "two"}))
first.stdin.close()
time.sleep(1.0)
second = subprocess.Popen([sys.executable, KW, "hook-idle"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True, env=ENV)
second.stdin.write(json.dumps({"session_id": "two"}))
second.stdin.close()
expect("an older waiter gives way to a newer one", first.wait(timeout=5) == 0)
expect("while the newer one keeps waiting", second.poll() is None)
second.kill()

# Reasons to end quietly.
state("done", last_activity=ago(53), work_at=ago(53), stopped=True)
r = idle("done")
expect("a finished session ends quietly", r.returncode == 0 and r.stderr == "")
state("fresh", last_activity=ago(53), work_at=ago(53), answered=False)
expect("a session with no finished turn ends quietly", idle("fresh").returncode == 0)
state("cold", last_activity=ago(70), work_at=ago(70))
r = idle("cold")
expect("a cold cache is not pinged", r.returncode == 0 and r.stderr == "")
expect("and the session is finished", read_state("cold")["stopped"] is True)
state("job", last_activity=ago(53), work_at=ago(53), recurring_at=time.time())
expect("a session holding a recurring job is not pinged twice", idle("job").returncode == 0)
state("off", last_activity=ago(53), work_at=ago(53))
off = dict(ENV, KEEPWARM_SWITCH=os.path.join(T, "absent"))
expect("the switch turns it off", idle("off", env=off).returncode == 0)
state("sdk", last_activity=ago(53), work_at=ago(53))
expect("a headless session has no waiter", idle("sdk", env=dict(ENV, CLAUDE_CODE_ENTRYPOINT="sdk-cli")).returncode == 0)

# The file switches go back to the job, for any reason the owner wants that.
open(ENV["KEEPWARM_CRON_FILE"], "w").close()
state("c", last_activity=ago(53), work_at=ago(53))
expect("the cron file turns the waiter off", idle("c").returncode == 0)
os.unlink(ENV["KEEPWARM_CRON_FILE"])

# A session start asks for nothing, and the session is never told to arm a job.
out = hook("hook-start", session_id="s1", source="startup")
text = out["hookSpecificOutput"]["additionalContext"]
expect("session start does not ask for a job", "CronCreate" not in text)
expect("it explains what a wake looks like", "Keep-warm wake" in text)
expect("no job is recorded", "recurring_at" not in read_state("s1"))
state("old", recurring_at=time.time())
hook("hook-start", session_id="old", source="resume")
expect("a resumed session moves to the waiter, its job died with its process",
       "recurring_at" not in read_state("old"))

# The turn end and the owner's return ask for nothing either.
state("s2")
expect("a turn's end does not ask for a job", hook("hook-stop", session_id="s2", transcript_path="") == {})
expect("the statusline still shows the next ping", read_state("s2").get("armed_at", 0) > time.time() + 40 * 60)
expect("the owner's prompt does not ask for a job",
       "CronCreate" not in json.dumps(hook("hook-prompt", session_id="s2", prompt="hello")))

with open(os.path.expanduser("~/.claude/settings.json")) as f:
    live = json.load(f)["hooks"]["Stop"]
reg = [h for g in live for h in g["hooks"] if "keepwarm.py hook-idle" in h.get("command", "")]
expect("the waiter is registered once", len(reg) == 1)
expect("as asyncRewake, the only form that can wake the model and stay quiet", reg and reg[0].get("asyncRewake") is True)
expect("with a limit longer than the wait", reg and reg[0].get("timeout", 0) >= 3600)

finish()
