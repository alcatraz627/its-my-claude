#!/usr/bin/env bash
# session-artifacts.sh — find everything tied to a Claude session id.
#
# A session leaves traces across several stores; this gathers them in one place
# so "what happened in session X" is one command, not five greps. Matches the
# full session UUID OR a user-given short id (substring), since serious sessions
# get an explicit id and casual ones use the implicit UUID.
#
# Usage: session-artifacts.sh <session-id-or-substring>
#        session-artifacts.sh            # defaults to $CLAUDE_CODE_SESSION_ID

set -uo pipefail
sid="${1:-${CLAUDE_CODE_SESSION_ID:-}}"
[ -n "$sid" ] || { echo "usage: session-artifacts.sh <session-id>  (or set CLAUDE_CODE_SESSION_ID)" >&2; exit 2; }
A="$HOME/.claude/atone"

hdr() { printf '\n\033[1m%s\033[0m\n' "$1"; }

hdr "atone events (session_id ~ $sid)"
# contains() = literal substring (test() would treat $sid as a regex and choke
# on metachars in a user-given id).
jq -rc --arg s "$sid" 'select((.session_id // "") | contains($s)) | "  \(.ts[:16])  \(.id)  [\(.severity)]  \(.slug)"' \
  "$A/events.jsonl" 2>/dev/null || true

hdr "atone judgments"
jq -rc --arg s "$sid" 'select((.session_id // "") | contains($s)) | "  \(.ts[:16])  \(.id)  \(.verdict)"' \
  "$A/judgments.jsonl" 2>/dev/null || true

hdr "persisted juror verdicts"
ls "$A/verdicts/" 2>/dev/null | rg -i -- "$sid" | sed 's/^/  /' || true

hdr "checkpoints (session-keyed)"
rg -l -- "$sid" "$HOME/.claude/checkpoints/"*.json 2>/dev/null | sed 's|.*/|  |' || true

hdr "reports / sub-agent outputs mentioning this session"
rg -rl --no-ignore -- "$sid" "$HOME/.claude/assets/reports/" 2>/dev/null | sed "s|$HOME/.claude/|  |" | head -20 || true

echo
