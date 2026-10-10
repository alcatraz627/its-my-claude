#!/usr/bin/env python3
"""The terminal side of a split zrecover session: the only part that lives in
your terminal window, and the only part allowed to die with it.

It puts the terminal in raw mode and copies keys to the session and output
back, so the session looks exactly like bare claude. Closing the window, a
crashed terminal, or killing this process only detaches: the session keeps
running and `zrecover attach PID|ALIAS` brings it back in any terminal.
`zrecover end PID|ALIAS` is the deliberate way to hang a session up.

Usage (normally through zrecover):
  client.py run [--name L] [--every S] [--grace S] -- <command> [args...]
  client.py attach [PID|ALIAS]
  client.py end PID|ALIAS
"""
import json, os, select, signal, socket, subprocess, sys, termios, time, tty

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from hold import (DATA, END, EVICT, EXIT, HELLO, INFO, LOG, REFUSE, RESIZE, ROOT, SOCKS, STATUS, WRAPS,  # noqa: E402
                  FrameReader, Modes, frame, pty_size, resize_payload, sock_path)
from reaper import alive  # noqa: E402

KEEPER = os.path.join(HERE, "keeper.py")
SESSIONS = os.path.join(ROOT, "sessions.json")
OUT_CAP = 1 << 20      # input queued to the holder before we stop reading the keyboard
RECONNECT_FOR = 10.0   # how long to look for a restarted holder after the socket drops


def say(msg):
    try:
        os.write(2, f"zrecover: {msg}\r\n".encode())
    except OSError:
        pass


def die(msg, code=1):
    print(f"zrecover: {msg}", file=sys.stderr)
    sys.exit(code)


def write_out(data):
    """Blocking write to the terminal. A terminal that cannot take output is gone."""
    view = memoryview(data)
    while view:
        try:
            n = os.write(1, view)
        except BlockingIOError:
            select.select([], [1], [])
            continue
        view = view[n:]


class TerminalClient:
    def __init__(self, sock, mode, info=None):
        self.sock, self.mode, self.info = sock, mode, info or {}
        self.reader = FrameReader()
        self.modes = Modes()
        self.outq = bytearray()
        self.saved = None
        self.flags = set()

    def hello(self):
        rows, cols = pty_size(0)
        tty_name = os.ttyname(0) if os.isatty(0) else None
        self.outq += frame(HELLO, json.dumps({"role": "client", "mode": self.mode, "rows": rows, "cols": cols,
                                              "tty": tty_name, "pid": os.getpid()}).encode())

    def leave(self, code, msg=None):
        """Put the terminal back the way we found it and exit."""
        try:
            write_out(self.modes.reset())
        except OSError:
            pass
        if self.saved is not None:
            try:
                termios.tcsetattr(0, termios.TCSADRAIN, self.saved)
            except termios.error:
                pass
        if msg:
            say(msg)
        sys.exit(code)

    def detach_message(self):
        pid = self.info.get("pid")
        return f"detached; the session is still running. Reattach: zrecover attach {pid}" if pid else "detached"

    def run(self):
        self.saved = termios.tcgetattr(0)
        wake_r, wake_w = os.pipe()
        os.set_blocking(wake_r, False)
        os.set_blocking(wake_w, False)
        signal.set_wakeup_fd(wake_w)
        signal.signal(signal.SIGWINCH, lambda *_: self.flags.add("winch"))
        # every way the terminal can go away means detach, never hang up
        for s in (signal.SIGHUP, signal.SIGTERM, signal.SIGINT, signal.SIGQUIT):
            signal.signal(s, lambda *_: self.flags.add("detach"))
        tty.setraw(0)
        self.hello()
        while True:
            rl = [self.sock, wake_r] + ([0] if len(self.outq) < OUT_CAP else [])
            wl = [self.sock] if self.outq else []
            try:
                ready_r, ready_w, _ = select.select(rl, wl, [], 1.0)
            except OSError:
                self.leave(129)
            if wake_r in ready_r:
                try:
                    os.read(wake_r, 512)
                except OSError:
                    pass
            if "detach" in self.flags:
                self.leave(129, self.detach_message())
            if "winch" in self.flags:
                self.flags.discard("winch")
                try:
                    self.outq += frame(RESIZE, resize_payload(*pty_size(0)))
                except OSError:
                    pass
            if 0 in ready_r:
                try:
                    data = os.read(0, 65536)
                except OSError:
                    data = b""
                if not data:
                    self.leave(129)   # the terminal is gone; the session stays
                self.outq += frame(DATA, data)
            if self.sock in ready_w:
                try:
                    n = self.sock.send(self.outq)
                    del self.outq[:n]
                except BlockingIOError:
                    pass
                except OSError:
                    self.reconnect()
                    continue
            if self.sock in ready_r:
                try:
                    data = self.sock.recv(262144)
                except BlockingIOError:
                    continue
                except OSError:
                    data = b""
                if not data:
                    self.reconnect()
                    continue
                try:
                    frames = self.reader.feed(data)
                except ValueError:
                    self.reconnect()
                    continue
                for kind, payload in frames:
                    self.on_frame(kind, payload)

    def on_frame(self, kind, payload):
        if kind == DATA:
            self.modes.feed(payload)
            try:
                write_out(payload)
            except OSError:
                self.leave(129)
        elif kind == INFO:
            self.info = json.loads(payload)
        elif kind == EXIT:
            read_exit_note(self.info.get("pid"))   # delivered the normal way; the fallback note is spent
            self.leave(exit_code(payload.decode()))
        elif kind == EVICT:
            self.leave(0, "this terminal was detached: the session was attached from another terminal")
        elif kind == REFUSE:
            self.leave(1, "another terminal took this session over; this one is detached")

    def reconnect(self):
        """The holder vanished. If the session lives, a new holder will be up in a
        moment: rejoin it without disturbing the screen."""
        try:
            self.sock.close()
        except OSError:
            pass
        pid, path = self.info.get("pid"), self.info.get("sock")
        if not pid:
            self.leave(1, "lost the session before it started; see " + LOG)
        deadline = time.monotonic() + RECONNECT_FOR
        while time.monotonic() < deadline:
            if not alive(pid):
                self.leave(exit_code(read_exit_note(pid)))
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            try:
                s.connect(path)
            except OSError:
                s.close()
                time.sleep(0.2)
                continue
            s.setblocking(False)
            self.sock, self.reader, self.mode, self.outq = s, FrameReader(), "resume", bytearray()
            self.hello()
            return
        self.leave(1, f"lost the holder; the session may still be running: zrecover attach {pid}")


def read_exit_note(pid):
    p = os.path.join(SOCKS, f"{pid}.exit")
    try:
        with open(p) as f:
            status = f.read().strip()
        os.unlink(p)
        return status
    except OSError:
        return "unknown"


def exit_code(status):
    try:
        n = int(status)
    except ValueError:
        return 1
    return n & 0xFF if n >= 0 else 128 - n


def parse_run(a):
    name, every, grace = None, 5.0, None
    while a and a[0].startswith("-"):
        if a[0] == "--":
            a = a[1:]
            break
        if a[0] in ("--name", "--every", "--grace") and len(a) > 1:
            if a[0] == "--name":
                name = a[1]
            elif a[0] == "--every":
                every = float(a[1])
            else:
                grace = float(a[1])
            a = a[2:]
        else:
            die(f"unknown option {a[0]}", 2)
    if not a:
        die("usage: zrecover run --split [--name L] [--every S] [--grace S] -- <command> [args]", 2)
    return a, name or os.path.basename(a[0]), every, grace


def start_session(a):
    cmd, name, every, grace = parse_run(a)
    if not os.isatty(0):
        os.execvp(cmd[0], cmd)   # no terminal to hold; be a plain exec, like wrap.py
    rows, cols = pty_size(0)
    mine, theirs = socket.socketpair()
    meta = {"name": name, "cmd": cmd, "cwd": os.getcwd(), "every": every, "grace": grace,
            "py": sys.executable, "started": time.time()}
    os.makedirs(ROOT, exist_ok=True)
    with open(LOG, "a") as log, open(os.devnull) as null:
        p = subprocess.Popen([sys.executable, KEEPER, "--sock-fd", str(theirs.fileno()), "--rows", str(rows),
                              "--cols", str(cols), "--meta", json.dumps(meta), "--"] + cmd,
                             pass_fds=(theirs.fileno(),), stdin=null, stdout=log, stderr=log,
                             start_new_session=True)
    theirs.close()
    p.wait()   # the keeper forks away at once; this only reaps the launcher
    mine.setblocking(False)
    TerminalClient(mine, "take").run()


# finding a session
def split_sessions():
    out = []
    try:
        names = os.listdir(WRAPS)
    except OSError:
        return out
    try:
        with open(SESSIONS) as f:
            alias_by_pid = {s["pid"]: s.get("alias") for s in json.load(f).get("sessions", [])}
    except (OSError, ValueError):
        alias_by_pid = {}
    for n in names:
        try:
            with open(os.path.join(WRAPS, n)) as f:
                w = json.load(f)
        except (OSError, ValueError):
            continue
        if w.get("split") and alive(int(w.get("pid", 0))):
            w["alias"] = alias_by_pid.get(w["pid"])
            out.append(w)
    return sorted(out, key=lambda w: w.get("started") or 0)


def describe(w):
    state = "attached" if w.get("attached") else "detached"
    return f"  {w['pid']:<7} {state:<9} {w.get('alias') or w.get('name') or '':<28} {w.get('cwd') or ''}"


def find_session(want):
    """The one split session `want` names: a pid, an alias, or a --name label.
    With no name, the only detached session. Anything else lists and exits 1."""
    rows = split_sessions()
    if want is None:
        hits = [w for w in rows if not w.get("attached")]
        what = "detached sessions"
    elif want.isdigit():
        hits = [w for w in rows if w["pid"] == int(want)]
        what = f"sessions with pid {want}"
    else:
        hits = [w for w in rows if want in (w.get("alias"), w.get("name"))]
        what = f"sessions named {want!r}"
    if len(hits) == 1:
        return hits[0]
    print(f"zrecover: {len(hits) or 'no'} {what}; name one by pid", file=sys.stderr)
    for w in hits or rows:
        print(describe(w), file=sys.stderr)
    sys.exit(1)


def attach_session(a):
    w = find_session(a[0] if a else None)
    if not os.isatty(0):
        die("attach needs a terminal", 2)
    path = w.get("sock") or sock_path(w["pid"])
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.connect(path)
    except OSError as e:
        die(f"cannot reach session {w['pid']}: {e.strerror or e}; its holder may be restarting, try again")
    s.setblocking(False)
    TerminalClient(s, "take", {"pid": w["pid"], "sock": path}).run()


def end_session(a):
    if not a:
        die("usage: zrecover end PID|ALIAS", 2)
    w = find_session(a[0])
    pid = w["pid"]
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(3.0)
    try:
        s.connect(w.get("sock") or sock_path(pid))
        s.sendall(frame(HELLO, json.dumps({"role": "control"}).encode()) + frame(END))
        reader, got = FrameReader(), []
        while not any(k == STATUS for k, _ in got):
            chunk = s.recv(4096)
            if not chunk:
                raise OSError("holder closed")
            got += reader.feed(chunk)
    except (OSError, ValueError):
        os.kill(pid, signal.SIGHUP)   # no holder to ask; hang it up directly
    finally:
        s.close()
    deadline = time.monotonic() + 8   # the holder sends SIGKILL 5 s after SIGHUP
    while alive(pid) and time.monotonic() < deadline:
        time.sleep(0.1)
    if alive(pid):
        os.kill(pid, signal.SIGKILL)
        time.sleep(0.5)
    if alive(pid):
        die(f"session {pid} is still running after SIGHUP and SIGKILL")
    print(f"ended session {pid}")


def main():
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0 if a else 2)
    fn = {"run": start_session, "attach": attach_session, "end": end_session}.get(a[0])
    if not fn:
        die(f"unknown command {a[0]!r}", 2)
    fn(a[1:])


if __name__ == "__main__":
    main()
