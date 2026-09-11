#!/usr/bin/env bash
# receipts.sh — the unread receipts for one codex session, as text for the model.
#
# drain-outbox.sh appends one line per replayed call to <sid>.receipts.jsonl.
# This prints the lines past the cursor and advances it, so a receipt is shown
# exactly once (at the next UserPromptSubmit). Prints nothing when caught up.
#   receipts.sh <sid>
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
sid="${1:-}"; [ -n "$sid" ] || exit 0
f="$GCC_OUTBOX_DIR/$sid.receipts.jsonl"; cur="$GCC_OUTBOX_DIR/$sid.receipts.cursor"
[ -s "$f" ] || exit 0
seen=0; [ -f "$cur" ] && seen=$(cat "$cur" 2>/dev/null); seen=${seen:-0}
total=$(wc -l < "$f" | tr -d ' ')
[ "$total" -gt "$seen" ] || exit 0
tail -n +"$((seen + 1))" "$f" | jq -r '"  #\(.n) \(.verb): " + (if .exit == 0 then "ok" else "FAILED (exit \(.exit))" end) + (if (.out|length) > 0 then " — " + (.out | gsub("\n"; " ") | .[0:200]) else "" end)'
printf '%s' "$total" > "$cur"
