#!/usr/bin/env bash
# checkpoint/resolve.sh — Resolve which checkpoint /catchup should use.
#
# Resolution order:
#   1. --session-id ID       → ~/.claude/checkpoints/<id>.json if exists
#   2. --pick N              → Nth most recent entry in index.jsonl (1-based)
#   3. --auto                → if only ONE entry in index is younger than 30 min, use it
#                              otherwise exit 2 (caller should prompt user)
#   4. (back-compat) fallback to ~/.claude/_last-checkpoint.json if nothing else
#
# Output: prints the resolved checkpoint JSON to stdout. Exit codes:
#   0  found
#   2  ambiguous (caller should run list.sh and prompt)
#   3  none found
#
# Used by /catchup. Keep dumb — picker UX lives in the skill, not here.

set -uo pipefail

MODE="" SESSION_ID="" PICK_N=""
INDEX="${HOME}/.claude/checkpoints/index.jsonl"
CKPT_DIR="${HOME}/.claude/checkpoints"
LEGACY="${HOME}/.claude/_last-checkpoint.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id) MODE="session"; SESSION_ID="$2"; shift ;;
    --pick)       MODE="pick";    PICK_N="$2";    shift ;;
    --auto)       MODE="auto" ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

case "$MODE" in
  session)
    safe=$(printf '%s' "$SESSION_ID" | LC_ALL=C tr -c 'A-Za-z0-9._-' '_')
    f="$CKPT_DIR/$safe.json"
    if [[ -f "$f" ]]; then cat "$f"; exit 0; fi
    # Collision-preserved pointers: <slug>.<uuid8>.json (written by write.sh when
    # a later session reused the slug). Serve the newest whose recorded session_id
    # actually equals the query — the glob alone would also match the PRIMARY
    # pointer of a different session whose dotted slug starts with "$safe."
    # (querying "web" must not silently serve "web.api").
    newest=""; n=0
    for f in $(ls -t "$CKPT_DIR/$safe".*.json 2>/dev/null); do
      [[ -f "$f" ]] || continue
      fsid=$(python3 -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("session_id",""))
except Exception: print("")' "$f" 2>/dev/null)
      [[ "$fsid" == "$SESSION_ID" ]] || continue
      n=$((n+1))
      [[ -z "$newest" ]] && newest="$f"
    done
    if [[ -n "$newest" ]]; then
      (( n > 1 )) && printf 'note: %s collision-preserved pointers exist for "%s" — use --pick to reach older ones\n' "$n" "$SESSION_ID" >&2
      cat "$newest"; exit 0
    fi
    # Fallback: maybe legacy holds it
    if [[ -f "$LEGACY" ]] && grep -q "\"$SESSION_ID\"" "$LEGACY"; then
      cat "$LEGACY"; exit 0
    fi
    exit 3
    ;;
  pick)
    [[ -f "$INDEX" ]] || exit 3
    # Get the Nth most-recent line.
    line=$(tail -n 100 "$INDEX" | awk 'NF' | tail -r 2>/dev/null | sed -n "${PICK_N}p")
    # macOS: tail -r reverses. If unavailable, use awk to pull.
    if [[ -z "$line" ]]; then
      line=$(awk 'NF' "$INDEX" | python3 -c "
import sys
lines = [l for l in sys.stdin if l.strip()]
n = int('$PICK_N')
print(lines[-n] if n <= len(lines) else '', end='')
")
    fi
    [[ -n "$line" ]] || exit 3
    printf '%s\n' "$line"
    exit 0
    ;;
  auto)
    [[ -f "$INDEX" ]] || {
      # No new index — fall back to legacy if it's fresh.
      [[ -f "$LEGACY" ]] || exit 3
      age=$(( $(date +%s) - $(stat -f %m "$LEGACY") ))
      (( age < 1800 )) && { cat "$LEGACY"; exit 0; }
      exit 2
    }
    fresh=$(python3 - "$INDEX" <<'PY'
import json, sys, os
from datetime import datetime, timezone
rows = []
total = 0
with open(sys.argv[1]) as f:
    for ln in f:
        ln = ln.strip()
        if not ln: continue
        try: r = json.loads(ln)
        except: continue
        try:
            t = datetime.strptime(r["ts"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        except: continue
        total += 1
        age = (datetime.now(timezone.utc) - t).total_seconds()
        if age < 1800:  # 30 min
            rows.append((age, r))
rows.sort()
if len(rows) == 1:
    print(json.dumps(rows[0][1]))
elif len(rows) > 1:
    sys.exit(2)
elif total > 0:
    sys.exit(2)   # stale entries exist: the caller shows the picker (contract rc=2)
else:
    sys.exit(3)   # genuinely nothing indexed
PY
    ) || exit $?
    printf '%s\n' "$fresh"
    exit 0
    ;;
  *)
    printf 'specify one of: --session-id ID, --pick N, --auto\n' >&2
    exit 2
    ;;
esac
