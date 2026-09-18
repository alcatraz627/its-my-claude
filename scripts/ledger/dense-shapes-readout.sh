#!/usr/bin/env bash
# dense-shapes-readout.sh — the pre-registered readout for dense-briefing-shapes-stop.sh.
#
# The decision rule lives in ~/Code/Claude/i-dream/.claude/output/20260918-3wk-review/next-tracks.md
# (track 2) and was fixed before the first fire, so the number cannot argue for
# itself. This prints fires per day, distinct sessions and projects, and the ten
# most recent session ids so the replies can be read by hand.
#   bash ~/.claude/scripts/ledger/dense-shapes-readout.sh [--since YYYY-MM-DD]
set -uo pipefail
LEDGER="${WARN_EVENTS:-$HOME/.claude/hooks/warn-events.jsonl}"
SINCE="2026-09-18"
while [ $# -gt 0 ]; do case "$1" in --since) SINCE="$2"; shift 2;; *) shift;; esac; done
[ -f "$LEDGER" ] || { echo "no ledger at $LEDGER"; exit 0; }
python3 - "$LEDGER" "$SINCE" <<'PY'
import json, sys, collections
p, since = sys.argv[1], sys.argv[2]
rows = []
for line in open(p, errors="replace"):
    try: r = json.loads(line)
    except ValueError: continue
    if r.get("hook_id") != "dense-briefing-shapes": continue
    if (r.get("ts") or "")[:10] < since: continue
    rows.append(r)
print(f"dense-briefing-shapes fires since {since}: {len(rows)}")
if not rows: sys.exit(0)
by_day = collections.Counter(r["ts"][:10] for r in rows)
for d in sorted(by_day): print(f"  {d}  {by_day[d]}")
print("distinct sessions:", len({r.get('sid') or r.get('session') for r in rows}))
print("projects:", collections.Counter(r.get("project", "?") for r in rows).most_common(6))
print("actions:", collections.Counter(r.get("action") for r in rows))
print("most recent session ids (read these replies by hand):")
for r in rows[-10:]: print("  ", r["ts"], r.get("sid") or r.get("session") or "?", r.get("project", ""))
PY
