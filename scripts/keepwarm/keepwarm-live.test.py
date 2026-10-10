"""Live check: a real interactive Claude session arms the keep-warm one-shot,
gets woken by it, does its upkeep, and stops. Uses Haiku and a 1-minute due
time, in a throwaway folder. Takes about 4 minutes and a few cents.

Run: python3 ~/.claude/scripts/keepwarm/keepwarm-live.test.py
"""
import fcntl, json, os, pty, select, struct, subprocess, sys, tempfile, termios, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "zrecover"))
from testlib import expect, finish  # noqa: E402

T = tempfile.mkdtemp(prefix="kw-live-")
KWDIR = os.path.join(T, "kw")
SWITCH = os.path.join(T, "on")
open(SWITCH, "w").close()
env = dict(os.environ, KEEPWARM_DIR=KWDIR, KEEPWARM_SWITCH=SWITCH,
           KEEPWARM_DUE_MIN="1", TERM="xterm-256color")

master, slave = pty.openpty()
fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 140, 0, 0))
proc = subprocess.Popen(["claude", "--model", "haiku", "--dangerously-skip-permissions"],
                        stdin=slave, stdout=slave, stderr=slave, cwd=T, env=env, start_new_session=True)
os.close(slave)
out = b""


def pump(seconds):
    global out
    end = time.time() + seconds
    while time.time() < end:
        r, _, _ = select.select([master], [], [], 0.5)
        if r:
            try:
                out += os.read(master, 65536)
            except OSError:
                return


def events():
    p = os.path.join(KWDIR, "events.jsonl")
    return [json.loads(l) for l in open(p)] if os.path.exists(p) else []


pump(10)
if b"trust" in out.lower():
    os.write(master, b"\x1b[B\r")    # same answer test_wrap.py gives the folder-trust dialog
    pump(8)
with open(os.path.join(T, "screen.log"), "wb") as f:
    f.write(out)
if proc.poll() is not None:
    print("claude exited early; screen in", os.path.join(T, "screen.log"))
os.write(master, b"Reply with the single word ready.\r")
pump(60)                         # first reply, which also arms the cron
wakes = []
deadline = time.time() + 240
while time.time() < deadline and not any(e.get("ev") == "wake" for e in events()):
    pump(10)
pump(60)                         # let the wake's upkeep finish and a later wake be skipped
ev = events()
wakes = [e for e in ev if e.get("ev") == "wake"]
expect("a real session was woken by keep-warm", len(wakes) >= 1)
if wakes:
    expect("the wake named its upkeep (a light session: one note, then stop)",
           wakes[0].get("action") == "note" and wakes[0].get("klass") == "light")
notes = []
for root, _, files in os.walk(T):
    notes += [os.path.join(root, f) for f in files if f.endswith(".md") and "session-notes" in root]
expect("the wake wrote the session note", bool(notes))
st_files = [f for f in os.listdir(KWDIR) if f.endswith(".json")] if os.path.isdir(KWDIR) else []
st = json.load(open(os.path.join(KWDIR, st_files[0]))) if st_files else {}
expect("keep-warm finished after the light session's one wake", st.get("stopped") is True)
print("events:", json.dumps(ev)[:600])
os.write(master, b"\x03")
pump(1)
os.write(master, b"\x03")
pump(3)
try:
    proc.terminate()
    proc.wait(timeout=5)
except Exception:
    proc.kill()
finish()
