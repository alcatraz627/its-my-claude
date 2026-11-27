"""Checks that keep-warm follows the default an agent declares when it stops.

An agent that ends a turn with "If no reply: <action>" has said what it will do if the
owner stays away. The next keep-warm wake hands that action back instead of telling it
to sit idle. "If no reply: hold, <why>" keeps the one-word warm ping. A reply with no
such line gets a wake that allows, but does not force, its own named work.

Run: python3 ~/.claude/scripts/keepwarm/keepwarm-declared.test.py
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
           USAGE_GATE_PCT="90", KEEPWARM_IDLE_SETTLE_S="0", KEEPWARM_IDLE_TICK_S="0.2",
           KEEPWARM_WAKE_DIR=os.path.join(T, "wake"))
for d in ("KEEPWARM_TASK_STORE", "KEEPWARM_DIR", "KEEPWARM_WAKE_DIR"):
    os.makedirs(ENV[d])
json.dump({"5h": {"pct": 10}, "week": {"pct": 10}}, open(ENV["USAGE_GATE_FILE"], "w"))
json.dump({"oauthAccount": {"organizationUuid": "org-a"}}, open(ENV["USAGE5H_CLAUDE_JSON"], "w"))


def path(sid):
    return os.path.join(ENV["KEEPWARM_DIR"], sid + ".json")


def state(sid, **fields):
    now = time.time()
    st = dict(last_activity=now, work_at=now, wakes=0, stopped=False, answered=True, account="org-a")
    st.update(fields)
    json.dump(st, open(path(sid), "w"))


def read_state(sid):
    return json.load(open(path(sid)))


def stop(sid, reply):
    subprocess.run([sys.executable, KW, "hook-stop"], capture_output=True, text=True, env=ENV,
                   input=json.dumps({"session_id": sid, "transcript_path": "", "last_assistant_message": reply}))


def age(sid, minutes):
    st = read_state(sid)
    st["last_activity"] = st["work_at"] = time.time() - minutes * 60
    json.dump(st, open(path(sid), "w"))


def wake(sid):
    r = subprocess.run([sys.executable, KW, "hook-idle"], input=json.dumps({"session_id": sid}),
                       capture_output=True, text=True, env=ENV, timeout=8)
    return r.returncode, r.stderr


# A declared action is recorded at the turn's end and handed back by the next wake.
state("act")
stop("act", "Suites are green on main.\n\nIf no reply: cut release v1.4.2 and post the notes.")
st = read_state("act")
expect("the declared action is recorded", (st.get("declared") or {}).get("kind") == "act")
expect("with its words", "cut release v1.4.2" in (st.get("declared") or {}).get("text", ""))
age("act", 53)
code, text = wake("act")
expect("the wake fires", code == 2)
expect("the wake names the declared action", "cut release v1.4.2" in text)
expect("and asks for it to be done, not for one word", "Do that now" in text and "Start nothing else" not in text)
expect("the action is marked as handed over", read_state("act")["declared"].get("served") is True)

# A wake turn that replies "warm" keeps the declaration served, so the action is not handed out twice.
stop("act", "warm")
age("act", 53)
code, text = wake("act")
expect("a second wake does not hand the same action back", "cut release v1.4.2" not in text)

# A declared hold keeps today's one-word ping.
state("hold")
stop("hold", "Which of the two schemas do you want?\n\n**If no reply:** hold, the schema choice is yours.")
expect("a hold is recorded as a hold", read_state("hold")["declared"]["kind"] == "hold")
age("hold", 53)
code, text = wake("hold")
expect("a hold wake is the one-word ping", "exactly one word: warm" in text and "Start nothing else" in text)

# No declaration: the wake allows the agent's own named work, without forcing it.
state("none")
stop("none", "Pushed; the release is next.")
expect("no declaration records nothing", "declared" not in read_state("none"))
age("none", 53)
code, text = wake("none")
expect("the undeclared wake allows agent-side work", "waits on nothing from the owner" in text)
expect("and still offers the one-word ping", "exactly one word: warm" in text)

# A newer owner turn with no declaration clears the old one.
state("clear")
stop("clear", "If no reply: merge the branch.")
stop("clear", "Done, all merged.")
expect("an owner turn without the line clears a stale declaration", "declared" not in read_state("clear"))

# Only the last line counts, and a quoted line is someone else's words.
state("last")
stop("last", "If no reply: run the batch.\n\nThen I changed my mind.\n\nIf no reply: hold, I need the budget.")
expect("the last declaration wins", read_state("last")["declared"]["kind"] == "hold")
state("quote")
stop("quote", "The reviewer wrote:\n\n> If no reply: merge it.\n\nI answered.")
expect("a quoted declaration is not this agent's", "declared" not in read_state("quote"))

# The session start teaches the line, so an agent knows it before any gate has to.
r = subprocess.run([sys.executable, KW, "hook-start"], capture_output=True, text=True, env=ENV,
                   input=json.dumps({"session_id": "brief", "source": "startup"}))
brief = json.loads(r.stdout)["hookSpecificOutput"]["additionalContext"] if r.stdout.strip() else ""
expect("session start names the If no reply line", "If no reply: hold" in brief)

finish()
