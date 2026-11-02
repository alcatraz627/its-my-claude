"""Live check on a real interactive Claude session: the recurring job arms, fires that
are not due cost no turn, a due fire gets its upkeep, and the cold gate stops a message
with no API call. Uses Haiku in a throwaway folder. About 6 minutes and a few cents.

It drives the session through tmux, which shows the screen as the owner would see it.
A bare pty lost the first message, and its output was too scattered to tell why.

Run: python3 ~/.claude/scripts/keepwarm/keepwarm-live.test.py
"""
import glob, json, os, re, shlex, subprocess, sys, tempfile, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "zrecover"))
from testlib import expect, finish  # noqa: E402

T = os.path.realpath(tempfile.mkdtemp(prefix="kw-live-"))
KWDIR = os.path.join(T, "kw")
SWITCH = os.path.join(T, "on")
open(SWITCH, "w").close()
BASE = dict(os.environ, KEEPWARM_DIR=KWDIR, KEEPWARM_SWITCH=SWITCH,
            KEEPWARM_ONESHOT_FILE=os.path.join(T, "no-oneshot"))
# Inside tmux, a client from the owner's own server must not be reused.
BASE.pop("TMUX", None)
SOCK = "kw-live-%d" % os.getpid()


def tmux(*args, env=None):
    return subprocess.run(["tmux", "-L", SOCK] + list(args), capture_output=True, text=True, env=env or BASE)


def start(argv, env):
    tmux("new-session", "-d", "-s", "s", "-x", "140", "-y", "40", "-c", T, shlex.join(argv), env=env)


def screen():
    return tmux("capture-pane", "-p", "-t", "s").stdout


def reach_prompt():
    """Wait for the input box, answering the folder-trust dialog when it appears."""
    deadline = time.time() + 90
    while time.time() < deadline:
        text = screen()
        if "Yes, I trust this folder" in text:
            # "No, exit" is selected first, so Enter alone quits the session.
            tmux("send-keys", "-t", "s", "Down")
            time.sleep(1)
            tmux("send-keys", "-t", "s", "Enter")
        elif "bypass permissions" in text:
            time.sleep(3)
            return True
        time.sleep(2)
    return False


def send(text):
    tmux("send-keys", "-t", "s", "-l", text)
    time.sleep(1)
    tmux("send-keys", "-t", "s", "Enter")


def input_box():
    """What is typed in the input box right now."""
    rows = [l for l in screen().splitlines() if l.startswith("❯")]
    return rows[-1][1:].strip() if rows else ""


def stop():
    tmux("kill-server")
    time.sleep(1)


def events():
    p = os.path.join(KWDIR, "events.jsonl")
    return [json.loads(l) for l in open(p)] if os.path.exists(p) else []


def transcript():
    # Claude Code names a project's folder with every non-alphanumeric character as a dash.
    found = sorted(glob.glob(os.path.expanduser("~/.claude/projects/%s/*.jsonl" % re.sub(r"[^a-zA-Z0-9]", "-", T))))
    return found[-1] if found else None


def answers():
    path = transcript()
    if not path:
        return 0
    return sum(1 for line in open(path, errors="replace") if '"type":"assistant"' in line and '"usage"' in line)


start(["claude", "--model", "haiku", "--dangerously-skip-permissions"],
      dict(BASE, KEEPWARM_CADENCE_MIN="1", KEEPWARM_WARM_DUE_MIN="3"))
expect("the session reached its prompt", reach_prompt())
send("Reply with the single word ready.")
time.sleep(60)                       # first reply, which also arms the job
deadline = time.time() + 300
while time.time() < deadline and not any(e.get("ev") == "wake" for e in events()):
    time.sleep(10)
ev = events()
waits = [e for e in ev if e.get("ev") == "wait"]
wakes = [e for e in ev if e.get("ev") == "wake"]
if not transcript():
    print(screen())
    stop()
    expect("the first message was submitted", False)
    finish()
expect("the session armed a recurring job", any('"name":"CronCreate"' in line and "[keepwarm]" in line for line in open(transcript(), errors="replace")))
print("arming events:", json.dumps([e for e in ev if e.get("ev") in ("relink", "arm-failed")]))
sid = os.path.basename(transcript())[:-6]
expect("keep-warm confirmed the job from the real transcript", json.load(open(os.path.join(KWDIR, sid + ".json"))).get("job_seen") is True)
expect("fires that were not due were blocked", len(waits) >= 1)
expect("a due fire reached the model with its upkeep", len(wakes) >= 1 and wakes[0].get("action") == "warm")
time.sleep(30)                       # let the wake's own turn finish
before, waits_before = answers(), len([e for e in events() if e.get("ev") == "wait"])
time.sleep(100)
fired = len([e for e in events() if e.get("ev") == "wait"]) - waits_before
expect("more fires were blocked while it stayed warm", fired >= 1)
expect("and they cost no turn", answers() == before)
print("answers before and after %d blocked fires: %d, %d" % (fired, before, answers()))
print("events:", json.dumps(events())[:900])
open(os.path.join(T, "screen.log"), "w").write(screen())
stop()

# The cold gate: resume with a threshold low enough that this session counts as cold.
time.sleep(70)
count = answers()
start(["claude", "--model", "haiku", "--dangerously-skip-permissions", "--resume", sid],
      dict(BASE, KEEPWARM_COLD_MIN="1", KEEPWARM_COLD_TOKENS="1", KEEPWARM_CADENCE_MIN="60"))
expect("the resumed session reached its prompt", reach_prompt())
MESSAGE = "Reply with the single word second."
send(MESSAGE)
time.sleep(25)
expect("the cold gate stopped the message", any(e.get("ev") == "cold-gate" for e in events()))
expect("no API call was made for it", answers() == count)
open(os.path.join(T, "screen-cold.log"), "w").write(screen())
print("screen at the cold gate:\n" + screen())

# The gate's message promises that the blocked text is back in the input box.
restored = MESSAGE in input_box()
expect("the blocked message is back in the input box", restored)
if restored:
    tmux("send-keys", "-t", "s", "Enter")
else:
    tmux("send-keys", "-t", "s", "C-u")
    send(MESSAGE)
time.sleep(40)
expect("sending again went through", any(e.get("ev") == "cold-pass" for e in events()))
expect("and got an answer", answers() > count)
print("screens in", T)
stop()
finish()
