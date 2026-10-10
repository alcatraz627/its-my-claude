#!/usr/bin/env python3
"""zrecover run: a see-through terminal wrapper that remembers what was on screen.

The wrapped program (normally `claude`) gets a real pty and every byte passes
straight through in both directions, so it renders exactly as it would bare.
On the side, the output stream also drives an in-memory terminal emulator
(pyte), and every few seconds the current screen is written as plain text to
~/.claude/zrecover/screens/<child-pid>.txt. After a crash that file holds the
last thing you saw, including an unsent draft in the Claude prompt box.

Usage: wrap.py [--name LABEL] [--every SECONDS] -- <command> [args...]
"""
import fcntl, json, os, pty, select, signal, struct, sys, termios, time, tty

import pyte

HOME = os.path.expanduser("~")
ROOT = os.path.join(HOME, ".claude", "zrecover")
SCREENS = os.path.join(ROOT, "screens")
WRAPS = os.path.join(ROOT, "wraps")


def winsize(fd):
    raw = fcntl.ioctl(fd, termios.TIOCGWINSZ, b"\0" * 8)
    rows, cols = struct.unpack("HHHH", raw)[:2]
    return rows or 24, cols or 80


def set_winsize(fd, rows, cols):
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))


def write_all(fd, data):
    while data:
        try:
            n = os.write(fd, data)
        except BlockingIOError:
            select.select([], [fd], [])
            continue
        data = data[n:]


def atomic_write(path, text):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


class Recorder:
    """Keeps a parsed copy of the child's screen and flushes it to disk."""

    def __init__(self, child_pid, name, cmd, every):
        self.pid, self.name, self.cmd, self.every = child_pid, name, cmd, every
        self.screen = pyte.Screen(80, 24)
        self.stream = pyte.ByteStream(self.screen)
        self.dirty = False
        self.last_flush = 0.0
        self.broken = False
        os.makedirs(SCREENS, exist_ok=True)
        os.makedirs(WRAPS, exist_ok=True)
        self.screen_path = os.path.join(SCREENS, f"{child_pid}.txt")
        self.wrap_path = os.path.join(WRAPS, f"{child_pid}.json")
        atomic_write(self.wrap_path, json.dumps({
            "pid": child_pid, "wrapper_pid": os.getpid(), "name": name, "cmd": cmd,
            "cwd": os.getcwd(), "started": time.time(), "screen": self.screen_path,
            "tty": os.ttyname(0) if os.isatty(0) else None}))

    def resize(self, rows, cols):
        self.screen.resize(rows, cols)
        self.dirty = True

    def feed(self, data):
        if self.broken:
            return
        try:
            self.stream.feed(data)
            self.dirty = True
        except Exception as e:  # the emulator must never break passthrough
            self.broken = True
            self.note = f"emulator stopped: {e!r}"

    def flush(self, force=False):
        now = time.time()
        if not force and (not self.dirty or now - self.last_flush < self.every):
            return
        lines = [line.rstrip() for line in self.screen.display]
        while lines and not lines[-1]:
            lines.pop()
        head = (f"# zrecover screen · pid {self.pid} · {self.name} · {time.strftime('%Y-%m-%d %H:%M:%S')}\n"
                f"# cwd {os.getcwd()}\n# cmd {' '.join(self.cmd)}\n"
                f"# cursor row {self.screen.cursor.y} col {self.screen.cursor.x}\n")
        if self.broken:
            head += f"# {self.note}\n"
        atomic_write(self.screen_path, head + "\n".join(lines) + "\n")
        self.dirty, self.last_flush = False, now

    def close(self, status):
        self.flush(force=True)
        try:
            os.remove(self.wrap_path)
        except OSError:
            pass
        # keep the final screen for a clean exit too; restore prunes by age
        with open(self.screen_path, "a") as f:
            f.write(f"# exited status {status} at {time.strftime('%Y-%m-%d %H:%M:%S')}\n")


def run(cmd, name, every):
    stdin, stdout = 0, 1
    if not os.isatty(stdin):
        os.execvp(cmd[0], cmd)  # no terminal to mirror; be a plain exec
    rows, cols = winsize(stdin)
    pid, master = pty.fork()
    if pid == 0:
        os.execvp(cmd[0], cmd)
    set_winsize(master, rows, cols)
    rec = Recorder(pid, name, cmd, every)
    rec.resize(rows, cols)

    old = termios.tcgetattr(stdin)
    resized = [False]
    term_deadline = [None]   # set when TERM/HUP was forwarded; the child gets 5 s, then KILL
    signal.signal(signal.SIGWINCH, lambda *_: resized.__setitem__(0, True))

    def forward(sig):
        def h(*_):
            try:
                os.kill(pid, sig)
            except ProcessLookupError:
                pass
            term_deadline[0] = term_deadline[0] or time.time() + 5
        return h
    # a reaper or a closed window signals the wrapper; the child must get it too
    signal.signal(signal.SIGTERM, forward(signal.SIGTERM))
    signal.signal(signal.SIGHUP, forward(signal.SIGHUP))
    status = 1
    exited = []   # wait status once the child is reaped inside the loop
    try:
        tty.setraw(stdin)
        while True:
            if resized[0]:
                resized[0] = False
                r, c = winsize(stdin)
                set_winsize(master, r, c)
                rec.resize(r, c)
            if term_deadline[0] and time.time() > term_deadline[0]:
                try:
                    os.kill(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                term_deadline[0] = None
            try:
                ready, _, _ = select.select([stdin, master], [], [], 0.5)
            except InterruptedError:
                continue
            # grandchildren (MCP servers, statusline helpers) can hold the pty open
            # after the child dies, so EOF alone is not a reliable exit signal
            done_pid, st = os.waitpid(pid, os.WNOHANG)
            if done_pid == pid:
                exited = [st]
                try:
                    write_all(stdout, os.read(master, 65536))
                except OSError:
                    pass
                break
            if master in ready:
                try:
                    data = os.read(master, 65536)
                except OSError:
                    data = b""
                if not data:
                    break
                write_all(stdout, data)
                rec.feed(data)
            if stdin in ready:
                data = os.read(stdin, 65536)
                if data:
                    write_all(master, data)
            rec.flush()
    finally:
        termios.tcsetattr(stdin, termios.TCSADRAIN, old)
        try:
            st = exited[0] if exited else os.waitpid(pid, 0)[1]
            status = os.waitstatus_to_exitcode(st)
        except ChildProcessError:
            pass
        rec.close(status)
    return status


def main():
    a = sys.argv[1:]
    name, every = None, 5.0
    while a and a[0].startswith("-"):
        if a[0] == "--":
            a = a[1:]
            break
        if a[0] == "--name":
            name, a = a[1], a[2:]
        elif a[0] == "--every":
            every, a = float(a[1]), a[2:]
        else:
            print(__doc__, file=sys.stderr)
            sys.exit(2)
    if not a:
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    sys.exit(run(a, name or os.path.basename(a[0]), every))


if __name__ == "__main__":
    main()
