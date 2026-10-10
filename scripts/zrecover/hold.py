#!/usr/bin/env python3
"""The zrecover session holder: the relay between a running Claude session and
whichever terminal is currently showing it.

The keeper owns the session's pty and hands this process a copy of it. The
holder moves bytes between that pty and at most one terminal client, feeds a
copy of the output to the screen recorder, and lets a terminal come and go
without the session noticing. If the holder dies, the keeper starts a new one
and the client reconnects; the session itself never sees the gap.

Runtime contract: started only by keeper.py. It listens on
~/.claude/zrecover/sock/<child-pid>.sock, owns wraps/<child-pid>.json for its
lifetime, starts and restarts record.py, and exits after the child does.

Caveats: everything is non-blocking with a capped queue per peer, because a
stuck terminal or a stuck recorder must never stop the holder draining the pty
(if it stops, Claude blocks on its own output). Nothing here parses the screen;
the only scanning is a small regex that tracks terminal modes so a new terminal
can be put into the state Claude left the old one in.
"""
import fcntl, json, os, re, select, shlex, signal, socket, struct, subprocess, sys, termios, time, traceback
from collections import deque

HOME = os.path.expanduser("~")
ROOT = os.path.join(HOME, ".claude", "zrecover")
SOCKS = os.path.join(ROOT, "sock")
WRAPS = os.path.join(ROOT, "wraps")
SCREENS = os.path.join(ROOT, "screens")
LOG = os.path.join(ROOT, "split.log")
HERE = os.path.dirname(os.path.abspath(__file__))
RECORD = os.path.join(HERE, "record.py")

RING_MAX = 64 * 1024        # recent output kept to prime a restarted recorder
PEER_CAP = 1 << 20          # queued bytes a peer may fall behind before it is dropped
INQ_CAP = 256 * 1024        # queued input before the holder stops reading the client
MAX_FRAME = 1 << 20         # a longer frame means a broken or hostile peer
HELLO_TIMEOUT = 5.0
RECORDER_EVERY = 5.0        # a recorder is restarted at most once per this many seconds
KILL_AFTER = 5.0            # SIGHUP, then SIGKILL this long after if the child is still there
GRACE_DEFAULT = 1800.0      # a detached session is hung up after this long with no output
EXIT_WAIT = 2.5             # how long the exit sequence waits for the client and recorder
WIGGLE_S = 0.3              # how long the pty stays one column narrow to force a repaint

# The grace timer must not count time the laptop spent asleep; monotonic does not
# advance during sleep on macOS, wall time does.
clock = time.monotonic

# frame kinds: one byte, then a 4-byte big-endian length, then the payload
DATA, RESIZE, HELLO, EXIT, EVICT, REFUSE, INFO, END, STATUS = (
    b"D", b"R", b"H", b"X", b"V", b"N", b"P", b"K", b"S")
KINDS = {DATA, RESIZE, HELLO, EXIT, EVICT, REFUSE, INFO, END, STATUS}


def frame(kind, payload=b""):
    return kind + struct.pack(">I", len(payload)) + payload


def resize_payload(rows, cols):
    return struct.pack(">HH", rows, cols)


class FrameReader:
    """Reassembles frames from a byte stream; raises ValueError on a bad header."""

    def __init__(self):
        self.buf = bytearray()

    def feed(self, data):
        self.buf += data
        out = []
        while len(self.buf) >= 5:
            kind = bytes(self.buf[:1])
            n = struct.unpack(">I", bytes(self.buf[1:5]))[0]
            if kind not in KINDS or n > MAX_FRAME:
                raise ValueError(f"bad frame kind={kind!r} len={n}")
            if len(self.buf) < 5 + n:
                break
            out.append((kind, bytes(self.buf[5:5 + n])))
            del self.buf[:5 + n]
        return out


CSI_RE = re.compile(rb"\x1b\[([?<>=]?)([\d;]*)([hlum])")
PARTIAL_CSI = re.compile(rb"\x1b(\[[\x30-\x3f]*[\x20-\x2f]*)?\Z")


class Modes:
    """Tracks the terminal modes a program switched on (mouse reporting, bracketed
    paste, focus events, the alternate screen, the kitty keyboard stack), so a
    terminal attaching mid-session can be put into the same state, and a terminal
    being left can be put back."""

    TRANSIENT = {2026}      # synchronized output brackets a single frame; never replay it
    DEFAULT_ON = {7, 25}    # autowrap and a visible cursor are on in a fresh terminal

    def __init__(self):
        self.dec = {}
        self.kitty = []
        self.mok = None     # modifyOtherKeys level, as its raw parameter bytes
        self.tail = b""

    def feed(self, data):
        buf = self.tail + data
        for m in CSI_RE.finditer(buf):
            prefix, args, final = m.groups()
            if prefix == b"?" and final in (b"h", b"l"):
                for n in args.split(b";"):
                    if n:
                        self.dec[int(n)] = final == b"h"
            elif final == b"u" and prefix == b">":
                self.kitty = (self.kitty + [int(args or b"0")])[-16:]
            elif final == b"u" and prefix == b"<":
                n = int(args or b"1")
                self.kitty = self.kitty[:-n] if n < len(self.kitty) else []
            elif final == b"u" and prefix == b"=" and self.kitty:
                self.kitty[-1] = int(args.split(b";")[0] or b"0")
            elif final == b"m" and prefix == b">" and args.split(b";")[0] == b"4":
                parts = args.split(b";")
                self.mok = None if len(parts) < 2 or parts[1] in (b"", b"0") else parts[1]
        # a sequence cut off at the end of this chunk is finished by the next one
        m = PARTIAL_CSI.search(buf[-32:])
        self.tail = m.group(0) if m else b""

    def replay(self):
        """Bytes that put a fresh terminal into the tracked state."""
        out = [b"\x1b[?%d%s" % (n, b"h" if on else b"l")
               for n, on in sorted(self.dec.items()) if n not in self.TRANSIENT and n != 1049]
        if self.dec.get(1049):
            out.insert(0, b"\x1b[?1049h")
        out += [b"\x1b[>%du" % f for f in self.kitty]
        if self.mok:
            out.append(b"\x1b[>4;%sm" % self.mok)
        return b"".join(out)

    def reset(self):
        """Bytes that undo every non-default mode, for a terminal being left behind."""
        out = []
        for n, on in sorted(self.dec.items()):
            if n == 1049:
                continue
            default = n in self.DEFAULT_ON
            if on != default:
                out.append(b"\x1b[?%d%s" % (n, b"h" if default else b"l"))
        if self.kitty:
            out.append(b"\x1b[<%du" % len(self.kitty))
        if self.mok:
            out.append(b"\x1b[>4m")
        out.append(b"\x1b[0m")
        if self.dec.get(1049):
            out.append(b"\x1b[?1049l")
        return b"".join(out)


def grace_due(now, detached_since, last_output, grace):
    """True when a detached session has been silent for the whole grace period."""
    if detached_since is None:
        return False
    return now - max(detached_since, last_output) >= grace


def log(msg):
    """One line to split.log (the keeper points our stderr there)."""
    try:
        sys.stderr.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} hold[{os.getpid()}] {msg}\n")
        sys.stderr.flush()
    except (OSError, ValueError):
        pass


# wrap.py has twins of the three helpers below, but it imports pyte at module
# load, and the holder and keeper must stay stdlib-only so an emulator fault can
# never reach them. client.py and record.py import these from here.
def write_file_atomically(path, text):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def pty_size(fd):
    raw = fcntl.ioctl(fd, termios.TIOCGWINSZ, b"\0" * 8)
    rows, cols = struct.unpack("HHHH", raw)[:2]
    return rows or 24, cols or 80


def set_pty_size(fd, rows, cols):
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))


def sock_path(child_pid):
    return os.path.join(SOCKS, f"{child_pid}.sock")


class Peer:
    """One connection: the terminal client, the recorder, or a one-shot control call."""

    def __init__(self, sock):
        sock.setblocking(False)
        try:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 256 * 1024)
        except OSError:
            pass
        self.sock = sock
        self.role = None
        self.reader = FrameReader()
        self.outq = deque()
        self.outlen = 0
        self.born = clock()
        self.closing_since = None
        self.info = {}

    def fileno(self):
        return self.sock.fileno()

    def send(self, kind, payload=b""):
        f = frame(kind, payload)
        self.outq.append(f)
        self.outlen += len(f)

    def flush(self):
        """Write what the socket will take now. False means the peer is gone."""
        while self.outq:
            head = self.outq[0]
            try:
                n = self.sock.send(head)
            except BlockingIOError:
                return True
            except OSError:
                return False
            self.outlen -= n
            if n == len(head):
                self.outq.popleft()
            else:
                self.outq[0] = head[n:]
                return True
        return True

    def close(self):
        try:
            self.sock.close()
        except OSError:
            pass


class Holder:
    def __init__(self, master, child, status_fd, meta, client_fd=None, restarts=0):
        self.master, self.child, self.status_fd, self.meta = master, child, status_fd, meta
        self.restarts = restarts
        self.grace = float(meta.get("grace") or GRACE_DEFAULT)
        os.set_blocking(master, False)
        os.set_blocking(status_fd, False)
        self.master_open = True
        self.status_open = True
        self.ring = bytearray()
        self.ring_from_start = restarts == 0   # a restarted holder joins the stream midway
        self.modes = Modes()
        self.inq = bytearray()
        self.client = None
        self.recorder = None
        self.pending = []
        self.closing = []
        self.last_output = clock()
        self.detached_since = clock()
        self.ever_attached = False
        self.kill_at = None
        self.hung_up = None
        self.unwiggle = None   # (rows, cols, when) to restore after a repaint nudge
        self.rec_proc = None
        self.rec_started = -RECORDER_EVERY
        self.notifiers = []
        self.exit_status = None
        self.exit_started = None
        self.done = False
        self.screen_path = os.path.join(SCREENS, f"{child}.txt")
        self.wrap_path = os.path.join(WRAPS, f"{child}.json")
        self.wrap = {}

        self.wake_r, wake_w = os.pipe()
        os.set_blocking(self.wake_r, False)
        os.set_blocking(wake_w, False)
        signal.set_wakeup_fd(wake_w)
        signal.signal(signal.SIGCHLD, lambda *_: None)
        for s in (signal.SIGHUP, signal.SIGINT, signal.SIGPIPE, signal.SIGTSTP, signal.SIGTTOU, signal.SIGTTIN):
            signal.signal(s, signal.SIG_IGN)

        self.listener = self._listen()
        os.makedirs(SCREENS, exist_ok=True)
        self.write_wrap(attached=False, tty=None, client_pid=None)
        if client_fd is not None:
            self.pending.append(Peer(socket.socket(fileno=client_fd)))
        log(f"up for child {child} (restart {restarts})")

    # setup
    def _listen(self):
        os.makedirs(SOCKS, mode=0o700, exist_ok=True)
        os.chmod(SOCKS, 0o700)
        path = sock_path(self.child)
        if os.path.exists(path):
            probe = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            probe.settimeout(1.0)
            try:
                probe.connect(path)
                answered = True
            except OSError:
                answered = False
            probe.close()
            if answered:
                raise SystemExit(f"another holder already answers on {path}")
            os.unlink(path)   # left by a holder that was killed
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        old = os.umask(0o077)
        try:
            s.bind(path)
        finally:
            os.umask(old)
        s.listen(8)
        s.setblocking(False)
        return s

    def write_wrap(self, **changes):
        """The wraps file says this session is wrapped, by whom, and whether a
        terminal is showing it. Written on events only, never per byte.
        For a split session wrapper_pid is the current holder (it changes on a
        holder restart); tty is the terminal of the latest attach."""
        if not self.wrap:
            self.wrap = {
                "pid": self.child, "split": True, "wrapper_pid": os.getpid(), "holder_pid": os.getpid(),
                "keeper_pid": os.getppid(), "recorder_pid": None, "name": self.meta.get("name"),
                "cmd": self.meta.get("cmd"), "cwd": self.meta.get("cwd"), "started": self.meta.get("started"),
                "screen": self.screen_path, "sock": sock_path(self.child), "restarts": self.restarts,
                "grace": self.grace, "detached_at": None}
        self.wrap.update(changes)
        try:
            os.makedirs(WRAPS, exist_ok=True)
            write_file_atomically(self.wrap_path, json.dumps(self.wrap))
        except OSError:
            log("could not write the wraps file:\n" + traceback.format_exc())

    # signals to the child
    def redraw(self):
        """Ask the program to repaint its whole screen. A bare SIGWINCH is not enough:
        Node (and so Claude Code) ignores one that leaves the size unchanged, so the
        pty goes one column narrower and is put back a moment later by timers()."""
        if self.unwiggle is not None:
            return
        try:
            rows, cols = pty_size(self.master)
            set_pty_size(self.master, rows, max(cols - 1, 2))
        except OSError:
            return
        self.unwiggle = (rows, cols, clock() + WIGGLE_S)

    def hang_up(self, why):
        if self.hung_up:
            return
        self.hung_up = why
        log(f"hanging up child {self.child}: {why}")
        try:
            os.kill(self.child, signal.SIGHUP)
        except ProcessLookupError:
            pass
        self.kill_at = clock() + KILL_AFTER

    def set_size(self, rows, cols):
        """Size the pty for the attached terminal. True when that changed the size,
        which the kernel turns into a SIGWINCH and so a repaint."""
        changed = False
        self.unwiggle = None   # a real size wins over a pending redraw nudge
        try:
            if pty_size(self.master) != (rows, cols):
                set_pty_size(self.master, rows, cols)
                changed = True
        except OSError:
            pass
        if self.recorder:
            self.recorder.send(RESIZE, resize_payload(rows, cols))
        return changed

    # output from the program
    def output(self, data):
        self.ring += data
        if len(self.ring) > RING_MAX:
            del self.ring[:len(self.ring) - RING_MAX]
            self.ring_from_start = False
        self.modes.feed(data)
        self.last_output = clock()
        for p in (self.client, self.recorder):
            if p is not None:
                p.send(DATA, data)
                if p.outlen > PEER_CAP:
                    self.drop(p, "fell more than 1 MB behind")

    def read_master(self):
        try:
            data = os.read(self.master, 65536)
        except BlockingIOError:
            return
        except OSError:
            data = b""
        if data:
            self.output(data)
        else:
            self.master_open = False   # every slave closed; the child exit arrives on the status pipe

    def write_master(self):
        try:
            n = os.write(self.master, bytes(self.inq[:65536]))
        except BlockingIOError:
            return
        except OSError:
            self.inq.clear()
            return
        del self.inq[:n]

    # peers
    def drop(self, p, why):
        log(f"dropping {p.role or 'pending'} peer: {why}")
        p.close()
        if p in self.pending:
            self.pending.remove(p)
        if p in self.closing:
            self.closing.remove(p)
        if p is self.recorder:
            self.recorder = None
        if p is self.client:
            self.client = None
            self.detached()

    def retire(self, p):
        """Let a peer's last frames drain, then close it."""
        if p is self.client:
            self.client = None
        if p is self.recorder:
            self.recorder = None
        if p in self.pending:
            self.pending.remove(p)
        p.closing_since = clock()
        self.closing.append(p)

    def detached(self):
        if self.exit_status is not None or self.client is not None:
            return
        self.detached_since = clock()
        self.write_wrap(attached=False, client_pid=None, detached_at=time.time())
        if self.ever_attached:
            name = self.meta.get("name") or "claude"
            mins = self.grace / 60
            self.notify(f"zrecover: {name} detached",
                        f"Session pid {self.child} is still running. Reattach with: zrecover attach {self.child}. "
                        f"It is hung up after {mins:.0f} min with no output. If that terminal is garbled, run reset.")

    def notify(self, title, body):
        """Fire and forget: a notifier that hangs or fails costs nothing here."""
        if os.environ.get("ZRECOVER_NOTIFY") == "0":
            return
        custom = os.environ.get("ZRECOVER_NOTIFY_CMD")
        tn = "/opt/homebrew/bin/terminal-notifier"
        if custom:
            argv = shlex.split(custom) + [title, body]
        elif os.path.exists(tn):
            argv = [tn, "-title", title, "-message", body, "-group", f"zrecover-{self.child}"]
        else:
            argv = ["osascript", "-e", f"display notification {json.dumps(body)} with title {json.dumps(title)}"]
        try:
            self.notifiers.append(subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                                   stderr=subprocess.DEVNULL, start_new_session=True))
        except OSError:
            pass

    def accept(self):
        try:
            s, _ = self.listener.accept()
        except OSError:
            return
        self.pending.append(Peer(s))

    def read_peer(self, p):
        try:
            data = p.sock.recv(65536)
        except BlockingIOError:
            return
        except OSError:
            data = b""
        if not data:
            self.drop(p, "closed")
            return
        try:
            frames = p.reader.feed(data)
        except ValueError as e:
            self.drop(p, str(e))
            return
        for kind, payload in frames:
            if p.closing_since is not None or p.sock.fileno() < 0:
                return
            self.handle(p, kind, payload)

    def handle(self, p, kind, payload):
        if p.role is None:
            if kind != HELLO:
                return self.drop(p, "spoke before hello")
            try:
                hello = json.loads(payload)
            except ValueError:
                return self.drop(p, "unreadable hello")
            self.pending.remove(p)
            p.role, p.info = hello.get("role"), hello
            if p.role == "client":
                self.attach(p, hello)
            elif p.role == "recorder":
                self.attach_recorder(p)
            elif p.role != "control":
                self.drop(p, f"unknown role {p.role!r}")
            return
        if p.role == "client" and p is self.client:
            if kind == DATA:
                self.inq += payload
            elif kind == RESIZE and len(payload) == 4:
                self.set_size(*struct.unpack(">HH", payload))
        elif p.role == "control":
            if kind == END:
                self.hang_up("zrecover end")
            p.send(STATUS, json.dumps(self.status()).encode())
            self.retire(p)

    def status(self):
        return {"pid": self.child, "holder_pid": os.getpid(), "attached": self.client is not None,
                "hung_up": self.hung_up, "restarts": self.restarts}

    def attach(self, p, hello):
        if hello.get("mode") == "resume" and self.client is not None:
            p.send(REFUSE, b"another terminal is attached")
            self.retire(p)
            return
        if self.client is not None:
            old = self.client
            old.send(EVICT, b"taken over by another terminal")
            self.retire(old)
            log("client taken over by a new attach")
        self.client = p
        self.detached_since = None
        p.send(INFO, json.dumps({"pid": self.child, "sock": sock_path(self.child),
                                 "name": self.meta.get("name")}).encode())
        # The session's first terminal gets the ring as is: it holds everything the
        # program has written, from byte zero. Any later one gets modes and a repaint.
        first = self.ring_from_start and not self.ever_attached
        p.send(DATA, bytes(self.ring) if first else self.modes.replay())
        rows, cols = int(hello.get("rows") or 24), int(hello.get("cols") or 80)
        if not self.set_size(rows, cols) and not first:
            self.redraw()
        self.ever_attached = True
        self.write_wrap(attached=True, tty=hello.get("tty"), client_pid=hello.get("pid"), detached_at=None)

    def attach_recorder(self, p):
        if self.recorder is not None:
            self.drop(self.recorder, "replaced by a new recorder")
        self.recorder = p
        rows, cols = self.unwiggle[:2] if self.unwiggle else pty_size(self.master)
        p.send(RESIZE, resize_payload(rows, cols))
        if self.ring:
            p.send(DATA, bytes(self.ring))
        if not self.ring_from_start:
            self.redraw()   # the ring starts mid-stream; only a repaint gives a whole screen

    # the recorder process
    def tend_recorder(self, now):
        if self.rec_proc is not None and self.rec_proc.poll() is not None:
            log(f"recorder exited with {self.rec_proc.returncode}")
            self.rec_proc = None
        if self.rec_proc is None and self.exit_status is None and now - self.rec_started >= RECORDER_EVERY:
            py = self.meta.get("py") or sys.executable
            try:
                self.rec_proc = subprocess.Popen(
                    [py, RECORD, "--sock", sock_path(self.child), "--pid", str(self.child),
                     "--meta", json.dumps(self.meta)], stdin=subprocess.DEVNULL)
                self.write_wrap(recorder_pid=self.rec_proc.pid)
            except OSError:
                log("could not start the recorder:\n" + traceback.format_exc())
            self.rec_started = now

    # the end
    def read_status(self):
        try:
            data = os.read(self.status_fd, 256)
        except BlockingIOError:
            return
        except OSError:
            data = b""
        if not data:
            self.status_open = False
            log("keeper closed the status pipe")
            return
        for line in data.decode(errors="replace").splitlines():
            if line.startswith("exit "):
                self.begin_exit(line.split()[1])

    def begin_exit(self, status):
        if self.exit_status is not None:
            return
        self.exit_status = status
        self.exit_started = clock()
        log(f"child {self.child} exited with {status}")
        while self.master_open:   # deliver what the child wrote last
            try:
                data = os.read(self.master, 65536)
            except BlockingIOError:
                break
            except OSError:
                data = b""
            if not data:
                break
            self.output(data)
        if self.client:
            self.client.send(EXIT, status.encode())
        if self.recorder:
            self.recorder.send(EXIT, status.encode())
        else:
            self.note_exit_in_screen(status)

    def note_exit_in_screen(self, status):
        try:
            with open(self.screen_path, "a") as f:
                f.write(f"# exited status {status} at {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        except OSError:
            pass

    def exit_finished(self, now):
        if now - self.exit_started > EXIT_WAIT:
            return True
        client_done = self.client is None or not self.client.outq
        rec_done = self.rec_proc is None or self.rec_proc.poll() is not None
        return client_done and rec_done

    def finish(self):
        if self.client:
            self.client.flush()
        if self.rec_proc is not None and self.rec_proc.poll() is None:
            self.rec_proc.kill()
        for p in [self.client, self.recorder] + self.pending + self.closing:
            if p is not None:
                p.close()
        for path in (self.wrap_path, sock_path(self.child)):
            try:
                os.unlink(path)
            except OSError:
                pass
        log("done")

    # the loop
    def timers(self, now):
        for p in list(self.pending):
            if now - p.born > HELLO_TIMEOUT:
                self.drop(p, "no hello")
        for p in list(self.closing):
            if not p.outq or now - p.closing_since > 1.0:
                p.flush()
                p.close()
                self.closing.remove(p)
        self.notifiers = [n for n in self.notifiers if n.poll() is None]
        if self.unwiggle is not None and now >= self.unwiggle[2]:
            rows, cols, _ = self.unwiggle
            self.unwiggle = None
            try:
                set_pty_size(self.master, rows, cols)
            except OSError:
                pass
        self.tend_recorder(now)
        if self.exit_status is None:
            if self.client is None and grace_due(now, self.detached_since, self.last_output, self.grace):
                self.hang_up(f"detached and silent for {self.grace:.0f}s")
            if self.kill_at is not None and now >= self.kill_at:
                try:
                    os.kill(self.child, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                self.kill_at = None
            if not self.status_open:
                # no keeper to report the exit; notice the child going away ourselves
                try:
                    os.kill(self.child, 0)
                except ProcessLookupError:
                    self.begin_exit("unknown")
        elif self.exit_finished(now):
            self.done = True

    def run(self):
        while not self.done:
            self.timers(clock())
            if self.done:
                break
            peers = [p for p in [self.client, self.recorder] + self.pending + self.closing if p is not None]
            rl = [self.listener, self.wake_r] + [p for p in peers if p is not self.client]
            if self.client is not None and len(self.inq) < INQ_CAP:
                rl.append(self.client)
            if self.master_open:
                rl.append(self.master)
            if self.status_open:
                rl.append(self.status_fd)
            wl = [p for p in peers if p.outq]
            if self.inq and self.master_open:
                wl.append(self.master)
            ready_r, ready_w, _ = select.select(rl, wl, [], 0.05 if self.unwiggle else 0.25)
            if self.wake_r in ready_r:
                try:
                    os.read(self.wake_r, 512)
                except OSError:
                    pass
            if self.status_fd in ready_r:
                self.read_status()
            if self.master in ready_r:
                self.read_master()
            if self.master in ready_w:
                self.write_master()
            if self.listener in ready_r:
                self.accept()
            for p in ready_r:
                if isinstance(p, Peer) and p.sock.fileno() >= 0:
                    self.read_peer(p)
            for p in ready_w:
                if isinstance(p, Peer) and p.sock.fileno() >= 0 and not p.flush():
                    self.drop(p, "write failed")
        self.finish()


def main():
    a = sys.argv[1:]

    def opt(name, default=None):
        return a[a.index(name) + 1] if name in a else default
    client_fd = opt("--client-fd")
    h = Holder(int(opt("--master-fd")), int(opt("--child-pid")), int(opt("--status-fd")),
               json.loads(opt("--meta", "{}")), int(client_fd) if client_fd else None,
               int(opt("--restarts", "0")))
    h.run()


if __name__ == "__main__":
    main()
