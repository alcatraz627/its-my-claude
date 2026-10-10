#!/usr/bin/env python3
"""Drives the split zrecover wrapper (keeper, holder, client, recorder) from
outer ptys, the way a terminal would, and checks that no wrapper failure costs
the session. The last case runs the real `claude` TUI and takes about 30 s.

Run: ~/.claude/scripts/zrecover/.venv/bin/python ~/.claude/scripts/zrecover/test_split.py [--no-claude]
"""
import fcntl, hashlib, json, os, pty, select, signal, struct, subprocess, sys, tempfile, termios, time, uuid

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from testlib import expect, finish  # noqa: E402
import hold  # noqa: E402
import reaper  # noqa: E402

PY = sys.executable
ZR = [PY, os.path.join(HERE, "zrecover.py")]
WRAPS, SCREENS = hold.WRAPS, hold.SCREENS
TMP = tempfile.mkdtemp(prefix="zrecover-split-test-")
NOTIFY_LOG = os.path.join(TMP, "notify.log")
NOTIFY_SCRIPT = os.path.join(TMP, "notify.py")
with open(NOTIFY_SCRIPT, "w") as f:
    f.write(f"import sys\nopen({NOTIFY_LOG!r}, 'a').write(' | '.join(sys.argv[1:]) + '\\n')\n")
ENV = {"TERM": "xterm-256color", "ZRECOVER_NOTIFY_CMD": f"{PY} {NOTIFY_SCRIPT}"}
STARTED = []   # child pids, for cleanup


def uniq(label):
    return f"t-{label}-{uuid.uuid4().hex[:6]}"


def is_up(pid):
    return bool(pid) and reaper.alive(int(pid))


def wait_for(pred, timeout, step=0.1):
    end = time.time() + timeout
    while time.time() < end:
        if pred():
            return True
        time.sleep(step)
    return bool(pred())


def wrap_named(name):
    try:
        names = os.listdir(WRAPS)
    except OSError:
        return None
    for n in names:
        try:
            with open(os.path.join(WRAPS, n)) as f:
                w = json.load(f)
        except (OSError, ValueError):
            continue
        if w.get("name") == name and w.get("pid") not in STARTED:
            return w
    return None


def wrap_of(pid):
    try:
        with open(os.path.join(WRAPS, f"{pid}.json")) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def screen_of(pid):
    try:
        with open(os.path.join(SCREENS, f"{pid}.txt")) as f:
            return f.read()
    except OSError:
        return ""


def set_ctty():
    fcntl.ioctl(0, termios.TIOCSCTTY, 0)


class Term:
    """An outer pty hosting a zrecover command, as a terminal window would.
    The command gets the pty as its controlling terminal, so closing the master
    delivers the same SIGHUP a closed window does."""

    def __init__(self, argv, rows=40, cols=120, cwd=None, env=None):
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
        self.proc = subprocess.Popen(argv, stdin=slave, stdout=slave, stderr=slave, cwd=cwd,
                                     start_new_session=True, preexec_fn=set_ctty,
                                     env={**os.environ, **ENV, **(env or {})})
        os.close(slave)
        self.out = b""
        self.stamps = []   # (time, total bytes) after each read
        self.closed = False

    def pump(self, seconds):
        end = time.time() + seconds
        while time.time() < end and not self.closed:
            r, _, _ = select.select([self.master], [], [], 0.05)
            if r:
                try:
                    data = os.read(self.master, 65536)
                except OSError:
                    return
                if not data:
                    return
                self.out += data
                self.stamps.append((time.time(), len(self.out)))

    def pump_until(self, needle, timeout):
        end = time.time() + timeout
        while time.time() < end:
            if needle in self.out:
                return True
            self.pump(0.1)
        return needle in self.out

    def type(self, s):
        try:
            os.write(self.master, s.encode() if isinstance(s, str) else s)
        except OSError:
            pass   # the program on this pty is gone; the caller's check will fail

    def exited(self, timeout):
        end = time.time() + timeout
        while time.time() < end:
            if self.proc.poll() is not None:
                return True
            self.pump(0.1)
        return self.proc.poll() is not None

    def close_window(self):
        """What closing a Ghostty window does: the pty master goes away, and the
        shell sends SIGHUP to every job's process group on its way out."""
        os.close(self.master)
        self.closed = True
        try:
            os.killpg(self.proc.pid, signal.SIGHUP)
        except ProcessLookupError:
            pass

    def stop(self):
        if self.proc.poll() is None:
            self.proc.kill()
        try:
            self.proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            pass
        if not self.closed:
            os.close(self.master)
            self.closed = True


def run_split(name, cmd, grace=None, env=None, cwd=None):
    argv = ZR + ["run", "--split", "--name", name, "--every", "1"]
    if grace is not None:
        argv += ["--grace", str(grace)]
    t = Term(argv + ["--"] + cmd, env=env, cwd=cwd)
    w = None
    end = time.time() + 6
    while time.time() < end and not w:
        t.pump(0.1)
        w = wrap_named(name)
    if w:
        STARTED.append(w["pid"])
    return t, w


def term_attach(pid):
    return Term(ZR + ["attach", str(pid)])


def zr_end(pid):
    return subprocess.run(ZR + ["end", str(pid)], capture_output=True, text=True, timeout=20)


def echo_works(t, word, timeout=4.0):
    t.type(word + "\n")
    return t.pump_until(b"echo:" + word.encode(), timeout)


def all_gone(w, timeout=6):
    return wait_for(lambda: not any(is_up(w[k]) for k in ("pid", "holder_pid", "keeper_pid")), timeout)


# An echo child, with the wide-glyph churn that froze a real session on 2026-10-10.
ECHO = [PY, "-u", "-c",
        "import sys, time\n"
        "for _ in range(40): print('\\U0001F916\\ra', end='', flush=True); time.sleep(0.05)\n"
        "print()\n"
        "for line in sys.stdin:\n"
        "    if line.strip() == 'quit': break\n"
        "    print('echo:' + line.strip(), flush=True)\n"]

# Switches on the modes Claude Code uses, then echoes.
MODES = [PY, "-u", "-c",
         "import sys\n"
         "sys.stdout.write('\\x1b[?1000h\\x1b[?1006h\\x1b[?2004h\\x1b[?1004hready\\n'); sys.stdout.flush()\n"
         "for line in sys.stdin:\n"
         "    print('echo:' + line.strip(), flush=True)\n"]

# Reports every resize the moment it sees it.
WINCH = [PY, "-u", "-c",
         "import os, signal, time\n"
         "def h(*_):\n"
         "    s = os.get_terminal_size(0); os.write(1, b'size %d %d\\r\\n' % (s.lines, s.columns))\n"
         "signal.signal(signal.SIGWINCH, h)\n"
         "os.write(1, b'ready\\r\\n')\n"
         "while True: time.sleep(1)\n"]

PASTE_N = 1 << 20
PASTE = [PY, "-u", "-c",
         "import os, sys, tty, threading, time, hashlib\n"
         "tty.setraw(0)\n"
         "os.write(1, b'ready\\r\\n')\n"
         "def tick():\n"
         "    for i in range(25): os.write(1, b'tick%d\\r\\n' % i); time.sleep(0.1)\n"
         "threading.Thread(target=tick, daemon=True).start()\n"
         "time.sleep(2)\n"
         "os.write(1, b'reading\\r\\n')\n"
         f"buf = b''\nwhile len(buf) < {PASTE_N}: buf += os.read(0, 65536)\n"
         "os.write(1, b'got %d %s\\r\\n' % (len(buf), hashlib.sha1(buf).hexdigest().encode()))\n"
         "time.sleep(0.5)\n"]

try:
    # 0. the parts that can be checked without a process
    try:
        hold.FrameReader().feed(b"D" + struct.pack(">I", hold.MAX_FRAME + 1))
        expect("framing: an oversized frame length is refused", False)
    except ValueError:
        expect("framing: an oversized frame length is refused", True)
    m = hold.Modes()
    m.feed(b"text\x1b[?100")
    m.feed(b"0h\x1b[?2004h\x1b[?25l\x1b[?2026h\x1b[>1u")
    expect("modes: a sequence split across reads is tracked", m.dec.get(1000) is True and m.dec.get(2004) is True)
    rp, rs = m.replay(), m.reset()
    expect("modes: replay re-enables mouse, paste and the keyboard protocol",
           b"\x1b[?1000h" in rp and b"\x1b[?2004h" in rp and b"\x1b[>1u" in rp and b"2026" not in rp)
    expect("modes: reset turns them off and shows the cursor",
           b"\x1b[?1000l" in rs and b"\x1b[?2004l" in rs and b"\x1b[?25h" in rs and b"\x1b[<1u" in rs)
    expect("grace: counts from the later of detach and last output",
           hold.grace_due(100, 0, 50, 30) and not hold.grace_due(100, 0, 80, 30) and not hold.grace_due(100, None, 0, 1))
    expect("grace: runs on the monotonic clock, which stops while the laptop sleeps", hold.clock is time.monotonic)
    r = reaper.Reaper(reaper.load_config(), dry_run=True)
    for script in ("keeper.py", "hold.py", "record.py", "client.py"):
        cmd = f"/Users/x/.claude/scripts/zrecover/.venv/bin/python /Users/x/.claude/scripts/zrecover/{script} --meta {{}}"
        expect(f"reaper: never picks {script}", not r.killable({"pid": 999999, "cmd": cmd}))

    # 1. a plain prompt: the unsent text is captured; exit tears everything down
    name = uniq("plain")
    t, w = run_split(name, [PY, "-c", "input('prompt> ')"])
    expect("plain: the session started and registered", bool(w))
    t.pump(1.0)
    t.type("hello unsent draft")
    t.pump(2.5)
    expect("plain: unsent text is captured", "prompt> hello unsent draft" in screen_of(w["pid"]))
    expect("plain: bytes passed through to the terminal", b"prompt> hello unsent draft" in t.out)
    t.type("\n")
    expect("plain: the client exits with the child, status 0", t.exited(5) and t.proc.returncode == 0)
    expect("plain: holder and keeper exit too", all_gone(w))
    expect("plain: wraps file and socket removed",
           wait_for(lambda: not os.path.exists(os.path.join(WRAPS, f"{w['pid']}.json"))
                    and not os.path.exists(hold.sock_path(w["pid"])), 3))
    expect("plain: the screen file records the exit", "# exited status 0" in screen_of(w["pid"]))
    t.stop()

    # 2. exit status comes through, including a command that does not exist
    t, w = run_split(uniq("seven"), [PY, "-c", "import time, sys; time.sleep(0.5); sys.exit(7)"])
    expect("status: the client exits with the child's status (7)", t.exited(6) and t.proc.returncode == 7)
    t.stop()
    t = Term(ZR + ["run", "--split", "--", "zrecover-no-such-command"])
    expect("status: a missing command exits 127", t.exited(6) and t.proc.returncode == 127)
    expect("status: and says why", b"cannot run" in t.out)
    t.stop()

    # 3. the child exits while a grandchild still holds the pty
    t, w = run_split(uniq("grandchild"), [PY, "-c", "import subprocess, sys; subprocess.Popen([sys.executable, '-c', "
                                         "'import time; time.sleep(30)']); print('parent done')"])
    expect("grandchild: the client exits even though a grandchild holds the pty", t.exited(6) and t.proc.returncode == 0)
    expect("grandchild: holder and keeper exit too", all_gone(w))
    subprocess.run(["pkill", "-f", "import time; time.sleep\\(30\\)"], capture_output=True)
    t.stop()

    # 4. wide-glyph churn, and an emulator that throws on a feed
    t, w = run_split(uniq("churn"), ECHO)
    t.pump(3.0)
    expect("churn: typing reaches the child and output returns", echo_works(t, "ping1"))
    t.pump(2.0)
    snap = screen_of(w["pid"])
    expect("churn: the recorder kept recording", "echo:ping1" in snap and "emulator reset" not in snap)
    t.type("quit\n")
    expect("churn: clean exit", t.exited(5) and t.proc.returncode == 0)
    t.stop()

    t, w = run_split(uniq("feedfault"), ECHO, env={"ZRECOVER_REC_FAULT": "feed"})
    t.pump(3.0)
    expect("feed fault: the relay is untouched", echo_works(t, "ping1"))
    t.pump(2.0)
    expect("feed fault: the emulator reset and recording went on",
           "emulator reset" in screen_of(w["pid"]) and "echo:ping1" in screen_of(w["pid"]))
    expect("feed fault: the same recorder process is still running", is_up((wrap_of(w["pid"]) or {}).get("recorder_pid")))
    t.type("quit\n")
    t.exited(5)
    t.stop()

    # 5. R1: the recorder is killed mid-run
    t, w = run_split(uniq("reckill"), ECHO)
    t.pump(2.5)
    old_rec = (wrap_of(w["pid"]) or {}).get("recorder_pid")
    os.kill(old_rec, signal.SIGKILL)
    expect("recorder killed: typed text still echoes at once", echo_works(t, "ping1", 2.0))
    new_rec = None
    end = time.time() + 7
    while time.time() < end:
        t.pump(0.2)
        new_rec = (wrap_of(w["pid"]) or {}).get("recorder_pid")
        if new_rec and new_rec != old_rec and is_up(new_rec):
            break
    expect("recorder killed: a new recorder is running within 6 s", new_rec and new_rec != old_rec and is_up(new_rec))
    echo_works(t, "ping2")
    t.pump(2.5)
    expect("recorder killed: the screen file updates again", "echo:ping2" in screen_of(w["pid"]))
    t.type("quit\n")
    t.exited(5)
    t.stop()

    # 6. R2: the client is SIGKILLed; the session lives and attach brings it back
    t, w = run_split(uniq("clientkill"), ECHO)
    t.pump(2.5)
    pid = w["pid"]
    w = wrap_of(pid)
    for k in ("keeper_pid", "holder_pid", "recorder_pid"):
        cmdline = subprocess.run(["ps", "-o", "command=", "-p", str(w[k])], capture_output=True, text=True).stdout.strip()
        expect(f"reaper: the live {k.split('_')[0]} is protected", cmdline and not r.killable({"pid": w[k], "cmd": cmdline}))
    os.kill(t.proc.pid, signal.SIGKILL)
    t.stop()
    time.sleep(1.0)
    expect("client killed: the child is still alive", is_up(pid))
    expect("client killed: the wraps file says detached", wait_for(lambda: (wrap_of(pid) or {}).get("attached") is False, 3))
    expect("client killed: a detach notification fired with the attach command",
           wait_for(lambda: os.path.exists(NOTIFY_LOG) and f"zrecover attach {pid}" in open(NOTIFY_LOG).read(), 3))
    res = subprocess.run(ZR + ["attach"], capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=10)
    expect("client killed: bare `attach` picks the only detached session (then wants a terminal)",
           res.returncode == 2 and "needs a terminal" in res.stderr)
    b = term_attach(pid)
    b.pump(1.0)
    expect("client killed: attach reconnects and an echo round-trip works", echo_works(b, "back1"))
    res = zr_end(pid)
    expect("end: `zrecover end` hangs the session up", res.returncode == 0 and not is_up(pid))
    expect("end: the attached client exits with it", b.exited(5))
    b.stop()

    # 7. F1: the window is closed (the terminal's pty master goes away), not kill -9
    t, w = run_split(uniq("winclose"), ECHO)
    t.pump(2.5)
    pid = w["pid"]
    t.close_window()
    expect("window closed: the client exits", wait_for(lambda: t.proc.poll() is not None, 3))
    time.sleep(1.0)
    w = wrap_of(pid) or {}
    expect("window closed: child, keeper and holder all survive",
           is_up(pid) and is_up(w.get("keeper_pid")) and is_up(w.get("holder_pid")))
    b = term_attach(pid)
    b.pump(1.0)
    expect("window closed: attach from a new terminal works", echo_works(b, "back2"))

    # 8. F4: takeover, in both orders
    c = term_attach(pid)
    c.pump(1.0)
    expect("takeover: the older terminal is let go", b.exited(4) and b.proc.returncode == 0)
    expect("takeover: and is told why", b"attached from another terminal" in b.out)
    expect("takeover: the newer terminal works", echo_works(c, "back3"))
    b.stop()
    d = term_attach(pid)
    d.pump(1.0)
    expect("takeover: a third attach takes it from the second", c.exited(4) and echo_works(d, "back4"))
    expect("takeover: the session survived all of it", is_up(pid))
    c.stop()
    zr_end(pid)
    d.exited(5)
    d.stop()

    # 9. F2: SIGHUP to the client means detach, never hang up
    t, w = run_split(uniq("sighup"), ECHO)
    t.pump(2.5)
    os.kill(t.proc.pid, signal.SIGHUP)
    expect("sighup: the client exits", t.exited(3))
    time.sleep(1.5)
    expect("sighup: the child was not hung up", is_up(w["pid"]))
    t.stop()
    zr_end(w["pid"])

    # 10. F5: terminal modes are reset on the way out and present after reattach
    t, w = run_split(uniq("modes"), MODES)
    expect("modes: the child switched them on", t.pump_until(b"ready", 5))
    os.kill(t.proc.pid, signal.SIGTERM)
    t.exited(3)
    expect("modes: the detaching client switched mouse, paste and focus off",
           b"\x1b[?1000l" in t.out and b"\x1b[?2004l" in t.out and b"\x1b[?1004l" in t.out)
    t.stop()
    b = term_attach(w["pid"])
    b.pump(1.5)
    expect("modes: after reattach mouse, SGR mouse, paste and focus modes are on again",
           all(s in b.out for s in (b"\x1b[?1000h", b"\x1b[?1006h", b"\x1b[?2004h", b"\x1b[?1004h")))
    expect("modes: and input still works", echo_works(b, "m1"))
    zr_end(w["pid"])
    b.exited(5)
    b.stop()

    # 11. F3: the holder is SIGKILLed; the child lives, the client rejoins, attach works
    t, w = run_split(uniq("holdkill"), ECHO)
    t.pump(2.5)
    pid = w["pid"]
    old_holder = wrap_of(pid)["holder_pid"]
    os.kill(old_holder, signal.SIGKILL)
    expect("holder killed: a new holder takes over",
           wait_for(lambda: (wrap_of(pid) or {}).get("holder_pid") not in (None, old_holder), 5))
    expect("holder killed: the child is still alive", is_up(pid))
    expect("holder killed: the same terminal rejoins and works", echo_works(t, "rejoin1", 6))
    expect("holder killed: the client never exited", t.proc.poll() is None)
    b = term_attach(pid)
    b.pump(1.0)
    expect("holder killed: a new attach works", echo_works(b, "rejoin2"))
    t.exited(4)
    t.stop()
    b.type("quit\n")
    expect("holder killed: the exit status still arrives through the new holder", b.exited(5) and b.proc.returncode == 0)
    b.stop()

    # 11b. the keeper itself is SIGKILLed: the holder still holds the pty, so the session lives on
    t, w = run_split(uniq("keepkill"), ECHO)
    t.pump(2.5)
    os.kill(w["keeper_pid"], signal.SIGKILL)
    time.sleep(1.0)
    expect("keeper killed: the child is still alive", is_up(w["pid"]))
    expect("keeper killed: the terminal still works", echo_works(t, "k1"))
    t.type("quit\n")
    expect("keeper killed: the holder notices the exit and the client leaves", t.exited(6))
    expect("keeper killed: the holder exits too", wait_for(lambda: not is_up(w["holder_pid"]), 5))
    t.stop()

    # 11c. F6/F7: a frozen terminal and a frozen recorder cannot stall the session
    done_file = os.path.join(TMP, "burst-done")
    BURST = [PY, "-u", "-c",
             "import sys\n"
             "sys.stdin.readline()\n"
             "for i in range(60000): sys.stdout.write('burst line %06d ............................\\n' % i)\n"
             f"sys.stdout.flush(); open({done_file!r}, 'w').write('ok')\n"
             "for line in sys.stdin:\n"
             "    print('echo:' + line.strip(), flush=True)\n"]
    t, w = run_split(uniq("frozen"), BURST)
    t.pump(2.5)
    w = wrap_of(w["pid"])
    os.kill(w["recorder_pid"], signal.SIGSTOP)
    t.type("go\n")
    t.pump(0.3)
    os.kill(t.proc.pid, signal.SIGSTOP)
    expect("frozen: the child writes 3 MB with the terminal and the recorder both stopped",
           wait_for(lambda: os.path.exists(done_file), 10))
    os.kill(w["recorder_pid"], signal.SIGCONT)
    os.kill(t.proc.pid, signal.SIGCONT)
    t.pump(1.0)
    expect("frozen: the thawed terminal rejoins and works", echo_works(t, "thaw1", 6))
    expect("frozen: the dropped recorder was replaced",
           wait_for(lambda: (wrap_of(w["pid"]) or {}).get("recorder_pid") != w["recorder_pid"], 8))
    zr_end(w["pid"])
    t.exited(5)
    t.stop()

    # 12. F12: a 1 MB paste into a child that sleeps before reading
    t, w = run_split(uniq("paste"), PASTE)
    expect("paste: child ready", t.pump_until(b"ready", 5))
    blob = (b"0123456789abcdef" * (PASTE_N // 16))
    sent, t0 = 0, time.time()
    os.set_blocking(t.master, False)
    while sent < len(blob) and time.time() - t0 < 20:
        r_, w_, _ = select.select([t.master], [t.master], [], 0.1)
        if r_:
            t.pump(0.01)
        if w_:
            try:
                sent += os.write(t.master, blob[sent:sent + 4096])
            except BlockingIOError:
                pass
    os.set_blocking(t.master, True)
    got = t.pump_until(b"got ", 15)
    t.pump(0.3)
    want = b"got %d %s" % (PASTE_N, hashlib.sha1(blob).hexdigest().encode())
    expect("paste: all 1 MB arrived intact", got and want in t.out)
    # While the child sleeps, its ticks must keep arriving one by one. A holder
    # stuck writing the paste would deliver them all in one burst afterwards.
    reading_at = next((ts for ts, n in t.stamps if b"reading" in t.out[:n]), None) or 0
    during = [t.out[:n].count(b"tick") for ts, n in t.stamps if t0 + 0.3 < ts < reading_at - 0.05]
    arrivals = len(set(during))
    expect(f"paste: output kept flowing while the paste was stuck ({arrivals} tick arrivals during the stall)",
           arrivals >= 5)
    t.exited(5)
    t.stop()

    # 13. F13: a resize reaches the child at once, not on the next half-second tick
    t, w = run_split(uniq("winch"), WINCH)
    t.pump_until(b"ready", 5)
    t.pump(0.5)
    t0 = time.time()
    fcntl.ioctl(t.master, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
    expect("resize: the child sees the new size", t.pump_until(b"size 30 100", 3))
    seen = next((ts for ts, n in t.stamps if b"size 30 100" in t.out[:n]), None)
    expect("resize: within 0.3 s", seen and seen - t0 < 0.3)
    os.kill(t.proc.pid, signal.SIGKILL)
    t.stop()
    b = Term(ZR + ["attach", str(w["pid"])], rows=30, cols=100)
    expect("repaint: a same-size reattach still makes the program see a real size change",
           b.pump_until(b"size 30 99", 3) and b.pump_until(b"size 30 100", 3))
    zr_end(w["pid"])
    b.exited(5)
    b.stop()

    # 14. R4: a detached, silent session is hung up after the grace period; output keeps it alive
    t, w = run_split(uniq("grace"), [PY, "-c", "input('idle> ')"], grace=3)
    t.pump(1.5)
    os.kill(t.proc.pid, signal.SIGKILL)
    t.stop()
    killed = time.time()
    time.sleep(1.5)
    expect("grace: still alive before the grace period ends", is_up(w["pid"]))
    expect("grace: hung up after it", wait_for(lambda: not is_up(w["pid"]), 10))
    expect("grace: not before 3 s", time.time() - killed >= 3.0)
    expect("grace: holder and keeper exit", all_gone(w))
    t, w = run_split(uniq("busy"), [PY, "-u", "-c", "import time\nfor i in range(16): print('busy', i); time.sleep(0.5)"],
                     grace=2)
    t.pump(1.0)
    os.kill(t.proc.pid, signal.SIGKILL)
    t.stop()
    time.sleep(5.0)
    expect("grace: a detached session still producing output is not hung up", is_up(w["pid"]))
    zr_end(w["pid"])

    # 15. attach by name is refused when the name is ambiguous (the CLI stays non-interactive)
    name = uniq("dup")
    t1, w1 = run_split(name, [PY, "-c", "input('one> ')"])
    t2, w2 = run_split(name, [PY, "-c", "input('two> ')"])
    t1.pump(1.0)
    os.kill(t1.proc.pid, signal.SIGKILL)
    os.kill(t2.proc.pid, signal.SIGKILL)
    t1.stop()
    t2.stop()
    res = subprocess.run(ZR + ["attach", name], capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=10)
    expect("ambiguous attach: exits non-zero and lists both",
           res.returncode == 1 and str(w1["pid"]) in res.stderr and str(w2["pid"]) in res.stderr)
    zr_end(w1["pid"])
    zr_end(w2["pid"])

    # 16. without --split, `zrecover run` is the old single-process wrapper
    t = Term(ZR + ["run", "--name", uniq("classic"), "--every", "1", "--", PY, "-c", "input('x> ')"])
    t.pump(1.5)
    kids = subprocess.run(["pgrep", "-P", str(t.proc.pid)], capture_output=True, text=True).stdout.split()
    w = wrap_of(kids[0]) if kids else None
    expect("classic: the child is a direct child of the wrapper, no keeper or holder",
           w is not None and w.get("wrapper_pid") == t.proc.pid and not w.get("split"))
    t.type("\n")
    expect("classic: exits with the child", t.exited(5) and t.proc.returncode == 0)
    t.stop()
    res = subprocess.run(ZR + ["run", "--split", "--", "echo", "hi"], capture_output=True, text=True,
                         stdin=subprocess.DEVNULL, timeout=10)
    expect("no terminal: --split becomes a plain exec", res.returncode == 0 and res.stdout == "hi\n")

    # 17. the real claude TUI: a typed draft is captured, survives a killed client, and comes back on attach
    if "--no-claude" not in sys.argv:
        import pyte
        from wrap import render_lines
        cwd = os.path.join(tempfile.gettempdir(), "zrecover-claude-test")
        os.makedirs(cwd, exist_ok=True)
        t, w = run_split(uniq("claude"), ["claude"], cwd=cwd)
        pid = w["pid"]
        t.pump(8.0)
        if "trust this folder" in screen_of(pid):   # first run in a new directory
            t.type("\x1b[B\r")
            t.pump(8.0)
        marker = "zrecover draft marker 90210 do not send"
        t.type(marker)
        t.pump(4.0)
        snap = screen_of(pid)
        expect("claude TUI: draft in the prompt box is captured", marker in snap)
        if marker not in snap:
            print("--- snapshot tail ---")
            print("\n".join(snap.splitlines()[-12:]))
        os.kill(t.proc.pid, signal.SIGKILL)
        t.stop()
        time.sleep(1.0)
        expect("claude TUI: claude survives its client being killed", is_up(pid))
        b = term_attach(pid)
        b.pump(5.0)
        scr = pyte.Screen(120, 40)
        pyte.ByteStream(scr).feed(b.out)
        shown = "\n".join(render_lines(scr))
        frame_file = os.path.join(TMP, "claude-reattached.txt")
        with open(frame_file, "w") as f:
            f.write(shown)
        print(f"     (reattached frame saved to {frame_file} )")
        expect("claude TUI: after attach the redrawn screen shows the draft", marker in shown)
        if marker not in shown:
            print("--- reattached screen tail ---")
            print("\n".join(line.rstrip() for line in shown.splitlines()[-14:]))
        expect("claude TUI: mouse/paste modes Claude set are re-sent on attach",
               b"\x1b[?2004h" in b.out or b"\x1b[?1000h" in b.out or b"\x1b[?1004h" in b.out)
        b.type("\x03")
        b.pump(0.5)
        b.type("\x03")
        if not b.exited(8):
            zr_end(pid)
        expect("claude TUI: exits on double Ctrl-C and everything goes", all_gone(w, 8))
        b.stop()
finally:
    for p in STARTED:
        try:
            os.unlink(os.path.join(hold.SOCKS, f"{p}.exit"))
        except OSError:
            pass
        w = wrap_of(p)
        if not w:   # already gone; the pid may belong to someone else by now
            continue
        for target in (p, w.get("holder_pid"), w.get("keeper_pid"), w.get("recorder_pid")):
            if is_up(target):
                try:
                    os.kill(int(target), signal.SIGKILL)
                except ProcessLookupError:
                    pass

finish()
