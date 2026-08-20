#!/usr/bin/env bash
# summarize-store.sh <task-dir> — one line describing a task store's real totals.
#
#   "1 in-progress, 6 pending, 45 done | active: <up to three subjects>"
#
# Its own file rather than a heredoc inside stop-sync.sh, because the test for it
# was a COPY of the logic and therefore passed while the caller was mutated to
# skip it entirely. A test that re-implements what it checks pins the arithmetic
# and not the wiring. Both the hook and the suite now run this.
#
# Counts from the STORE, which is the whole queue. The alternative source,
# replay_tasks.py, reconstructs the list from a session's transcript and so sees
# only tasks TOUCHED since the last clear. That is the right signal for drift
# (a question about activity) and the wrong one for a summary a reader will take
# as current state: it once reported 3 pending and 11 done against a real store
# of 6 open and 44 done.
#
# Prints nothing and exits 1 when the directory is absent, so the caller can
# choose its own fallback rather than being handed a confident zero.

set -uo pipefail
dir="${1:-}"
[ -n "$dir" ] && [ -d "$dir" ] || exit 1

python3 - "$dir" <<'PY' 2>/dev/null || exit 1
import sys, os, json, glob
ip = pend = done = 0
active = []
for fn in glob.glob(os.path.join(sys.argv[1], "*.json")):
    try:
        o = json.load(open(fn))
    except Exception:
        continue                      # a half-written task file is not fatal
    s = o.get("status", "pending")
    if s == "in_progress":
        ip += 1
        active.append(o.get("subject", ""))
    elif s == "completed":
        done += 1
    else:
        pend += 1
out = f"{ip} in-progress, {pend} pending, {done} done"
if active:
    out += " | active: " + "; ".join(active[:3])
print(out)
PY
