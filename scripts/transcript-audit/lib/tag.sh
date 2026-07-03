#!/usr/bin/env bash
# ta tag — bookmark one (transcript, turn) into the bookmarks ledger.
#
# The accumulation layer of the transcript-audit tool: an audit marks the turns
# it found worth remembering, so the next audit builds on those marks instead of
# restarting. Writes one append-only event through the shared ledger writer
# (ledger-common.sh), so `ledger list --src bookmarks` and `ledger show <id>`
# see it like any other gcc ledger event.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GCC="$HOME/.claude"
# shellcheck source=/dev/null
source "$GCC/scripts/ledger/ledger-common.sh"

TRANSCRIPT="" TURN="" LABEL="" NOTE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --transcript) TRANSCRIPT="$2"; shift 2 ;;
    --turn)       TURN="$2"; shift 2 ;;
    --label)      LABEL="$2"; shift 2 ;;
    --note)       NOTE="$2"; shift 2 ;;
    -h|--help)
      printf 'usage: ta tag --transcript PATH --turn IDX --label SLUG [--note TEXT]\n'
      exit 0 ;;
    *) printf 'ta tag: unknown arg %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [ -z "$TRANSCRIPT" ] || [ -z "$TURN" ] || [ -z "$LABEL" ]; then
  printf 'usage: ta tag --transcript PATH --turn IDX --label SLUG [--note TEXT]\n' >&2
  exit 2
fi
[ -f "$TRANSCRIPT" ] || { printf 'ta tag: no such transcript: %s\n' "$TRANSCRIPT" >&2; exit 2; }

# Resolve session_id + project (the turn's cwd) via the shared turn model.
RESOLVED="$(python3 "$DIR/ta_core.py" resolve "$TRANSCRIPT" "$TURN" 2>&1)" || {
  printf 'ta tag: %s\n' "$RESOLVED" >&2; exit 2; }
IFS=$'\t' read -r SID PROJ <<<"$RESOLVED"

STORE="${TA_BOOKMARKS_STORE:-$GCC/ledger/bookmarks.jsonl}"
# Dotted lock name, matching the ledger family (.alerts.lock, .plug-events.lock).
LOCK="$(dirname "$STORE")/.$(basename "${STORE%.jsonl}").lock"
mkdir -p "$(dirname "$STORE")"

ID="$(ledger_id bkmk)"
TS="$(ledger_ts)"
LINE="$(jq -cn \
  --arg id "$ID" --arg ts "$TS" --arg kind "bookmark" \
  --arg project "$PROJ" --arg session_id "$SID" --arg transcript "$TRANSCRIPT" \
  --argjson turn_index "$TURN" --arg label "$LABEL" --arg note "$NOTE" \
  "{id:\$id, ts:\$ts, kind:\$kind, project:\$project, session_id:\$session_id, transcript:\$transcript, turn_index:\$turn_index, label:\$label, note:\$note} | $LEDGER_STRIP_EMPTY")"

ledger_append "$STORE" "$LOCK" "$LINE"
printf 'tagged: %s  [%s]  turn %s  %s\n' "$ID" "$LABEL" "$TURN" "$TRANSCRIPT"
