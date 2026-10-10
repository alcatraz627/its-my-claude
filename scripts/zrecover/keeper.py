#!/usr/bin/env python3
"""The zrecover keeper: the one process a wrapped session's life depends on.

It starts the program (normally `claude`) on a new pty, holds the pty open, and
waits. Everything that can go wrong (relaying bytes, sockets, the screen
recorder) happens in the holder, which the keeper restarts whenever it dies, so
a wrapper fault never closes the pty and never hangs up the session.

Runtime contract: started by client.py in a new session with stdio pointed at
/dev/null and the split log. Usage:
  keeper.py --sock-fd N --rows R --cols C --meta JSON -- <command> [args...]
It exits with the program's exit status after the holder has delivered it.

Caveat: the keeper ignores SIGHUP, SIGINT, SIGTSTP and SIGPIPE so nothing the
old terminal does can reach it; the child gets those back at their defaults.
"""
import os, pty, signal, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from hold import SOCKS, WRAPS, set_pty_size  # noqa: E402  (stdlib-only module)

HOLD = os.path.join(HERE, "hold.py")
SHIELDED = (signal.SIGHUP, signal.SIGINT, signal.SIGTSTP, signal.SIGPIPE, signal.SIGTTOU, signal.SIGTTIN)


def log(msg):
    try:
        sys.stderr.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} keeper[{os.getpid()}] {msg}\n")
        sys.stderr.flush()
    except (OSError, ValueError):
        pass


def signal_quietly(pid, sig):
    try:
        os.kill(pid, sig)
    except ProcessLookupError:
        pass


def prune_exit_notes():
    """Exit-status notes are read by a client that lost its holder at the very end;
    a day later nobody will read them."""
    os.makedirs(SOCKS, mode=0o700, exist_ok=True)
    cutoff = time.time() - 86400
    for n in os.listdir(SOCKS):
        p = os.path.join(SOCKS, n)
        try:
            if n.endswith(".exit") and os.stat(p).st_mtime < cutoff:
                os.unlink(p)
        except OSError:
            pass


def start_holder(master, child, meta, restarts, client_fd):
    """Start a holder on the pty. Returns (holder pid or None, the status pipe's write end)."""
    status_r, status_w = os.pipe()
    argv = [sys.executable, HOLD, "--master-fd", str(master), "--child-pid", str(child),
            "--status-fd", str(status_r), "--meta", meta, "--restarts", str(restarts)]
    fds = [master, status_r]
    if client_fd is not None:
        argv += ["--client-fd", str(client_fd)]
        fds.append(client_fd)
    try:
        pid = subprocess.Popen(argv, pass_fds=fds, stdin=subprocess.DEVNULL).pid
    except OSError as e:
        log(f"cannot start the holder: {e}")
        pid = None
    os.close(status_r)
    return pid, status_w


def main():
    a = sys.argv[1:]
    cmd, head = a[a.index("--") + 1:], a[:a.index("--")]

    def opt(name):
        return head[head.index(name) + 1]
    sock_fd, rows, cols, meta = int(opt("--sock-fd")), int(opt("--rows")), int(opt("--cols")), opt("--meta")

    # The client started us with setsid; fork once more so the keeper is not a
    # session leader and can never pick up a controlling terminal.
    if os.fork():
        os._exit(0)
    for s in SHIELDED:
        signal.signal(s, signal.SIG_IGN)
    os.set_inheritable(sock_fd, False)
    prune_exit_notes()

    child, master = pty.fork()
    if child == 0:
        for s in SHIELDED:
            signal.signal(s, signal.SIG_DFL)
        os.closerange(3, 4096)
        try:
            os.execvp(cmd[0], cmd)
        except OSError as e:
            os.write(2, f"zrecover: cannot run {cmd[0]}: {e.strerror}\r\n".encode())
        os._exit(127)
    set_pty_size(master, rows, cols)
    # a reaper or `kill` aimed at the keeper is meant for the session
    signal.signal(signal.SIGTERM, lambda *_: signal_quietly(child, signal.SIGTERM))
    log(f"child {child}: {' '.join(cmd)}")

    holder, status_w, client_fd, restarts, last_start = None, None, sock_fd, 0, 0.0
    while True:
        if holder is None:
            if restarts > 1:   # the first restart is immediate, later ones at most once a second
                time.sleep(max(0.0, last_start + 1.0 - time.time()))
            holder, status_w = start_holder(master, child, meta, restarts, client_fd)
            if client_fd is not None:
                os.close(client_fd)
                client_fd = None
            last_start = time.time()
            if holder is None:
                os.close(status_w)
                restarts += 1
                continue
        done, st = os.wait()
        if done == child:
            code = os.waitstatus_to_exitcode(st)
            break
        if done == holder:
            log(f"holder {holder} exited ({os.waitstatus_to_exitcode(st)}); the child lives, restarting it")
            os.close(status_w)
            holder, restarts = None, restarts + 1

    log(f"child {child} exited with {code}")
    try:
        with open(os.path.join(SOCKS, f"{child}.exit"), "w") as f:
            f.write(str(code))
    except OSError:
        pass
    if holder is not None:
        try:
            os.write(status_w, f"exit {code}\n".encode())
        except OSError:
            pass
        deadline = time.time() + 5
        while os.waitpid(holder, os.WNOHANG)[0] == 0:
            if time.time() > deadline:
                signal_quietly(holder, signal.SIGKILL)
                os.waitpid(holder, 0)
                break
            time.sleep(0.05)
    for leftover in (os.path.join(WRAPS, f"{child}.json"), os.path.join(SOCKS, f"{child}.sock")):
        try:
            os.unlink(leftover)
        except OSError:
            pass
    os._exit(code & 0xFF if code >= 0 else 128 - code)


if __name__ == "__main__":
    main()
