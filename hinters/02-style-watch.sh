#!/usr/bin/env bash
# 02-style-watch.sh — delivers the style watcher's pending verdicts.
#
# The watcher's worker (style-watch-worker.sh) runs detached after a turn ends
# and drops verdicts into style/pending-watch-notes.txt; this hinter injects
# the first fresh note for THIS project at the next prompt and consumes what
# it delivered. Notes older than 24h age out silently (stale advice is noise).
# Contract: prompt on stdin (unused), at most one hint line on stdout.
set -uo pipefail

NOTES="${STYLE_WATCH_NOTES:-$HOME/.claude/style/pending-watch-notes.txt}"
[ -s "$NOTES" ] || exit 0
cat >/dev/null 2>&1 || true   # drain stdin per hinter contract

NOW=$(date -u +%s)
CWD_NOW=$(pwd)
TMP=$(mktemp) || exit 0

awk -F'|' -v now="$NOW" -v cwd="$CWD_NOW" -v keep="$TMP" '
{
    ts = $1 + 0
    if (now - ts > 86400) next                 # aged out: drop
    if ($2 == cwd && delivered == 0) {         # first fresh note for this project
        msg = $3
        for (i = 4; i <= NF; i++) msg = msg "|" $i
        out = msg; delivered = 1; next         # consumed: drop from file
    }
    if ($2 == cwd && delivered == 1) { extra++; next }   # consume siblings, summarize
    print $0 >> keep                           # other projects: keep
}
END {
    if (delivered) {
        if (extra > 0) out = out " (+" extra " more file(s) flagged — logs/style-watch.jsonl)"
        print out
    }
}' "$NOTES"

mv -f "$TMP" "$NOTES" 2>/dev/null || rm -f "$TMP"
exit 0
