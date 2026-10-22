#!/usr/bin/env python3
"""How much a rewrite grew or shrank a text, measured rather than guessed.

A voice or clarity pass reports this line so the owner sees the size change of
every rewrite; growth is allowed when each added part names what it adds.

Usage:
  size-delta.py <before-file> <after-file>
  size-delta.py --git <rev> <file>     before = the file at <rev>, after = the file now
Prints one line: words and characters before -> after, with the percent change.
"""
import subprocess
import sys


def measure(text):
    return len(text.split()), len(text)


def main(argv):
    if len(argv) == 3 and argv[0] == "--git":
        before = subprocess.run(["git", "show", "%s:./%s" % (argv[1], argv[2])], capture_output=True, text=True,
                                cwd=None).stdout
        with open(argv[2], encoding="utf-8", errors="replace") as f:
            after = f.read()
    elif len(argv) == 2:
        with open(argv[0], encoding="utf-8", errors="replace") as f:
            before = f.read()
        with open(argv[1], encoding="utf-8", errors="replace") as f:
            after = f.read()
    else:
        print(__doc__)
        return 2
    (bw, bc), (aw, ac) = measure(before), measure(after)
    pct = 100.0 * (aw - bw) / bw if bw else 0.0
    print("size: %d -> %d words (%+.0f%%), %d -> %d characters" % (bw, aw, pct, bc, ac))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
