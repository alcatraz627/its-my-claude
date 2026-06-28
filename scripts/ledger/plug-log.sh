#!/usr/bin/env bash
# plug-log.sh — record one session-plug firing to the plug-events ledger.
#
# A thin wrapper over ledger-common.sh (the sanctioned ledger writer). Session
# plugs fire a handful of times per session and each firing is human-meaningful
# ("ctx-pressure fired at band 80 this session, 760 chars") — that is a ledger,
# not high-volume ::logs, so it belongs here. Keyed on session_id (the join key
# the /plugs reader needs; a script can't reliably pin the session from $PPID).
#
# This is the FIRED side of efficacy. The ACTED side (was the injection used? was
# the proposal promoted?) is a separate, harder signal and is intentionally not
# recorded here yet.
#
# Usage:
#   plug-log.sh --plug <name> --lifecycle <start|turn|compact|end> \
#               --outcome <fired|injected|stubbed|surfaced|silent> \
#               [--chars N] [--session SID] [--summary "..."] [--tags "a b c"]
#
# Best-effort: never blocks the calling hook; always exits 0.
# Mute: touch ~/.claude/.no-plug-events   (test isolation: LEDGER_DIR=<tmp>)

set -uo pipefail
[ -f "$HOME/.claude/.no-plug-events" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
# shellcheck disable=SC1091
source "$HOME/.claude/scripts/ledger/ledger-common.sh" 2>/dev/null || exit 0

plug="" lifecycle="" outcome="" chars="" session="" summary="" tags=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plug)      plug="$2"; shift 2 ;;
    --lifecycle) lifecycle="$2"; shift 2 ;;
    --outcome)   outcome="$2"; shift 2 ;;
    --chars)     chars="$2"; shift 2 ;;
    --session)   session="$2"; shift 2 ;;
    --summary)   summary="$2"; shift 2 ;;
    --tags)      tags="$2"; shift 2 ;;
    *)           shift ;;
  esac
done
[ -z "$plug" ] && exit 0

DIR="${LEDGER_DIR:-$HOME/.claude/ledger}"
STORE="$DIR/plug-events.jsonl"
LOCK="$DIR/.plug-events.lock"
mkdir -p "$DIR" 2>/dev/null || true

# Empty -> JSON null so the strip rule drops it; numeric chars stays a number.
case "$chars" in ''|*[!0-9]*) chars_json="null" ;; *) chars_json="$chars" ;; esac
if [ -n "$tags" ]; then tags_json=$(ledger_split_array " " "$tags"); else tags_json="null"; fi

line=$(jq -cn \
  --arg id "$(ledger_id plug)" --arg ts "$(ledger_ts)" \
  --arg plug "$plug" --arg lifecycle "$lifecycle" --arg outcome "$outcome" \
  --arg session_id "$session" --arg summary "$summary" \
  --argjson chars "$chars_json" --argjson tags "$tags_json" \
  "{id:\$id, ts:\$ts, plug:\$plug, lifecycle:\$lifecycle, outcome:\$outcome, session_id:\$session_id, chars:\$chars, summary:\$summary, tags:\$tags} | $LEDGER_STRIP_EMPTY")

ledger_append "$STORE" "$LOCK" "$line"
exit 0
