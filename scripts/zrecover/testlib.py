"""Shared bits for the zrecover test scripts: a pass/fail line and the tally."""
import sys

results = []


def expect(name, ok):
    results.append(bool(ok))
    print(("PASS " if ok else "FAIL ") + name)


def finish():
    print(f"\n{sum(results)}/{len(results)} passed")
    sys.exit(0 if all(results) else 1)
