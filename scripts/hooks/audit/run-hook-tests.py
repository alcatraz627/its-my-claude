#!/usr/bin/env python3
"""Run every hook test and report which pass, and whether any wrote to the live ledger.

Each suite runs on its own with a time limit, because one hung suite should not hide the
rest. The ledger is compared afterwards: warn-log stamps each row with the run id set
below, whatever session id a test chose, so another session's real rows never read as
test pollution.

    run-hook-tests.py [name-filter]
"""
import glob
import json
import os
import subprocess
import sys
import uuid

HOOKS = os.path.expanduser("~/.claude/scripts/hooks")
LEDGER = os.path.expanduser("~/.claude/hooks/warn-events.jsonl")
RUN_ID = "hook-tests-" + uuid.uuid4().hex[:8]


def rows_from_this_run(start):
    with open(LEDGER, errors="replace") as handle:
        handle.seek(start)
        return [line for line in handle if RUN_ID in line]


def main():
    pattern = sys.argv[1] if len(sys.argv) > 1 else ""
    tests = sorted(f for f in glob.glob(HOOKS + "/**/*.test.*", recursive=True)
                   if "/retired/" not in f and "/fixtures/" not in f and pattern in f)
    start = os.path.getsize(LEDGER)
    env = dict(os.environ, HOOK_TEST_RUN=RUN_ID)
    failed = []
    for path in tests:
        cmd = ["bash", path] if path.endswith(".sh") else [sys.executable, path]
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=240, env=env, cwd=os.path.dirname(path),
                               stdin=subprocess.DEVNULL)
            code = r.returncode
            tail = (r.stdout + r.stderr).strip().splitlines()[-1:] or [""]
        except subprocess.TimeoutExpired:
            code, tail = "timeout", [""]
        if code != 0:
            failed.append(path.replace(HOOKS + "/", ""))
        print("%-4s %-52s %s" % ("ok" if code == 0 else "FAIL", path.replace(HOOKS + "/", ""), tail[0][:60]), flush=True)
    leaked = rows_from_this_run(start)
    print("\n%d suites, %d failed. Rows written to the live ledger by this run: %d" % (len(tests), len(failed), len(leaked)))
    for line in leaked[:5]:
        print("  leaked:", json.loads(line).get("hook_id"))
    return 1 if failed or leaked else 0


if __name__ == "__main__":
    sys.exit(main())
