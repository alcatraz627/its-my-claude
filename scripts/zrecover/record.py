#!/usr/bin/env python3
"""The zrecover screen recorder for a split session: it watches the session's
output and keeps ~/.claude/zrecover/screens/<pid>.txt holding what the screen
shows right now, including an unsent draft in Claude's prompt box.

Runtime contract: started and restarted by hold.py. It connects to the holder's
socket as a read-only peer, is primed with the holder's recent output, and
writes the screen file every few seconds. It is disposable: if it dies, the
holder starts a fresh one within five seconds and the session never notices.

Caveat: an emulator error on some byte sequence resets the emulator instead of
killing the recorder, so one odd escape cannot cost more than a stale screen
until the next redraw.
"""
import json, os, select, socket, sys, time, traceback

import pyte

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from hold import DATA, EXIT, HELLO, RESIZE, SCREENS, FrameReader, frame, write_file_atomically  # noqa: E402
from wrap import render_lines  # noqa: E402

FAULT = os.environ.get("ZRECOVER_REC_FAULT", "")   # tests only: "feed" raises once in the emulator


def log(msg):
    try:
        sys.stderr.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} record[{os.getpid()}] {msg}\n")
        sys.stderr.flush()
    except (OSError, ValueError):
        pass


class Screen:
    """The emulator plus the file it is mirrored to."""

    def __init__(self, pid, meta):
        self.pid, self.meta = pid, meta
        self.every = float(meta.get("every") or 5.0)
        self.path = os.path.join(SCREENS, f"{pid}.txt")
        self.rows, self.cols = 24, 80
        self.fresh()
        self.dirty, self.last_flush, self.resets, self.fault_armed = False, 0.0, 0, FAULT == "feed"
        os.makedirs(SCREENS, exist_ok=True)

    def fresh(self):
        self.screen = pyte.Screen(self.cols, self.rows)
        self.stream = pyte.ByteStream(self.screen)

    def resize(self, rows, cols):
        self.rows, self.cols = rows, cols
        try:
            self.screen.resize(rows, cols)
        except Exception:
            log("resize failed; starting a fresh emulator:\n" + traceback.format_exc())
            self.fresh()
        self.dirty = True

    def feed(self, data):
        try:
            if self.fault_armed and b"\n" in data:
                self.fault_armed = False
                raise IndexError("injected feed fault")
            self.stream.feed(data)
        except Exception:
            self.resets += 1
            log("emulator error; reset:\n" + traceback.format_exc())
            self.fresh()
        self.dirty = True

    def flush(self, force=False, tail=""):
        now = time.time()
        if not force and (not self.dirty or now - self.last_flush < self.every):
            return
        try:
            lines = [line.rstrip() for line in render_lines(self.screen)]
        except Exception:
            log("render failed:\n" + traceback.format_exc())
            return
        while lines and not lines[-1]:
            lines.pop()
        m = self.meta
        head = (f"# zrecover screen · pid {self.pid} · {m.get('name')} · {time.strftime('%Y-%m-%d %H:%M:%S')}\n"
                f"# cwd {m.get('cwd')}\n# cmd {' '.join(m.get('cmd') or [])}\n"
                f"# cursor row {self.screen.cursor.y} col {self.screen.cursor.x}\n")
        if self.resets:
            head += f"# emulator reset {self.resets}x after errors (see split.log)\n"
        try:
            write_file_atomically(self.path, head + "\n".join(lines) + "\n" + tail)
        except OSError:
            log("could not write the screen file:\n" + traceback.format_exc())
        self.dirty, self.last_flush = False, now


def main():
    a = sys.argv[1:]

    def opt(name):
        return a[a.index(name) + 1]
    path, pid, meta = opt("--sock"), int(opt("--pid")), json.loads(opt("--meta"))
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(path)
    sock.sendall(frame(HELLO, json.dumps({"role": "recorder", "pid": os.getpid()}).encode()))
    scr, reader = Screen(pid, meta), FrameReader()
    while True:
        r, _, _ = select.select([sock], [], [], 0.5)
        if r:
            data = sock.recv(262144)
            if not data:
                scr.flush(force=True)
                return 1   # the holder went away or dropped us; it starts a fresh recorder
            for kind, payload in reader.feed(data):
                if kind == DATA:
                    scr.feed(payload)
                elif kind == RESIZE:
                    rows, cols = int.from_bytes(payload[:2], "big"), int.from_bytes(payload[2:], "big")
                    scr.resize(rows, cols)
                elif kind == EXIT:
                    stamp = time.strftime('%Y-%m-%d %H:%M:%S')
                    scr.flush(force=True, tail=f"# exited status {payload.decode()} at {stamp}\n")
                    return 0
        scr.flush()


if __name__ == "__main__":
    sys.exit(main())
