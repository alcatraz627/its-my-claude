#!/usr/bin/env python3
"""Drives wrap.py from an outer pty, the way a terminal would, and checks that
unsent keystrokes show up in the screen snapshot. The second case runs the real
`claude` TUI, so it needs the claude binary and takes about 20 seconds.

Run: ~/.claude/scripts/zrecover/.venv/bin/python ~/.claude/scripts/zrecover/test_wrap.py [--no-claude]
"""
import fcntl, os, pty, select, struct, subprocess, sys, tempfile, termios, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from testlib import expect, finish  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
WRAP = os.path.join(HERE, "wrap.py")
PY = sys.executable
SCREENS = os.path.expanduser("~/.claude/zrecover/screens")


class Term:
    """An outer pty hosting the wrapper, with the wrapper's child pid exposed."""

    def __init__(self, cmd, rows=40, cols=120, cwd=None, env=None):
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
        self.proc = subprocess.Popen([PY, WRAP, "--every", "1", "--"] + cmd, stdin=slave, stdout=slave,
                                     stderr=slave, cwd=cwd, start_new_session=True,
                                     env={**os.environ, "TERM": "xterm-256color", **(env or {})})
        os.close(slave)
        self.out = b""

    def pump(self, seconds):
        end = time.time() + seconds
        while time.time() < end:
            r, _, _ = select.select([self.master], [], [], 0.2)
            if r:
                try:
                    self.out += os.read(self.master, 65536)
                except OSError:
                    return

    def type(self, s):
        os.write(self.master, s.encode())

    def child_pid(self):
        out = subprocess.run(["pgrep", "-P", str(self.proc.pid)], capture_output=True, text=True).stdout
        pids = [int(x) for x in out.split()]
        return pids[0] if pids else None

    def screen(self):
        pid = self.child_pid()
        p = os.path.join(SCREENS, f"{pid}.txt") if pid else None
        return open(p).read() if p and os.path.exists(p) else ""

    def stop(self):
        try:
            self.proc.terminate()
            self.proc.wait(timeout=5)
        except Exception:
            self.proc.kill()
        os.close(self.master)


# 1. a plain input() prompt: the unsent text is in the snapshot
t = Term([PY, "-c", "input('prompt> ')"])
t.pump(1.0)
t.type("hello unsent draft")
t.pump(2.5)
snap = t.screen()
expect("plain prompt: unsent text is captured", "prompt> hello unsent draft" in snap)
expect("plain prompt: bytes passed through to the terminal", b"prompt> hello unsent draft" in t.out)
t.type("\n")
t.pump(1.0)
expect("wrapper exits with the child", t.proc.poll() == 0)

# 1b. the child exits while a grandchild still holds the pty: the wrapper must still exit
t = Term([PY, "-c", "import subprocess, sys; subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(30)']); print('parent done')"])
t.pump(3.0)
expect("wrapper exits when the child dies even if a grandchild holds the pty", t.proc.poll() == 0)
subprocess.run(["pkill", "-f", "import time; time.sleep\\(30\\)"], capture_output=True)

# 1c. the input that froze a real session on 2026-10-10: a wide glyph whose left
# half is overwritten leaves a cell pyte's .display cannot render
import pyte  # noqa: E402
from wrap import render_lines  # noqa: E402
s = pyte.Screen(20, 2)
pyte.ByteStream(s).feed("🤖\ra 漢\x1b[1;4Hx".encode())
try:
    lines = render_lines(s)
    expect("screen read survives an overwritten wide glyph", lines[0].startswith("a"))
except Exception as e:
    expect("screen read survives an overwritten wide glyph (raised %r)" % e, False)

# An echo child: the relay is alive if typed lines come back.
ECHO = [PY, "-u", "-c",
        "import sys, time\n"
        "for _ in range(40): print('\\U0001F916\\ra', end='', flush=True); time.sleep(0.05)\n"
        "print()\n"
        "for line in sys.stdin:\n"
        "    if line.strip() == 'quit': break\n"
        "    print('echo:' + line.strip(), flush=True)\n"]


def relay_survives(label, env=None):
    t = Term(ECHO, env=env)
    t.pump(3.5)                      # the glyph churn plus a few flushes
    t.type("ping1\n")
    t.pump(1.5)
    expect(label + ": typing still reaches the child and output still returns", b"echo:ping1" in t.out)
    snap = t.screen()
    t.type("quit\n")
    t.pump(2.0)
    expect(label + ": wrapper exits cleanly with the child", t.proc.poll() == 0)
    if t.proc.poll() is None:        # a failed run must not leave a frozen wrapper behind
        child = t.child_pid()
        if child:
            subprocess.run(["kill", "-9", str(child)], capture_output=True)
        t.stop()
    return snap


snap = relay_survives("wide-glyph churn")
expect("wide-glyph churn: the recorder kept recording", "emulator stopped" not in snap)
snap = relay_survives("injected recorder failure", {"ZRECOVER_WRAP_FAULT": "flush"})
expect("injected recorder failure: the screen file says recording stopped", "emulator stopped in flush" in snap)
relay_survives("injected relay-loop failure", {"ZRECOVER_WRAP_FAULT": "loop"})

# 2. the real claude TUI
if "--no-claude" not in sys.argv:
    cwd = os.path.join(tempfile.gettempdir(), "zrecover-claude-test")
    os.makedirs(cwd, exist_ok=True)
    t = Term(["claude"], cwd=cwd)
    t.pump(8.0)
    if "trust this folder" in t.screen():   # first run in a new directory
        t.type("\x1b[B\r")
        t.pump(8.0)
    marker = "zrecover draft marker 90210 do not send"
    t.type(marker)
    t.pump(4.0)
    snap = t.screen()
    expect("claude TUI: draft in the prompt box is captured", marker in snap)
    expect("claude TUI: emulator kept up (no stop note)", "emulator stopped" not in snap)
    if marker not in snap:
        print("--- snapshot tail ---")
        print("\n".join(snap.splitlines()[-12:]))
    t.type("\x03")          # clear the draft
    t.pump(0.5)
    t.type("\x03")          # second Ctrl-C exits
    t.pump(3.0)
    t.stop()

finish()
