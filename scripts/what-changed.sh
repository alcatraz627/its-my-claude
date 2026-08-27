#!/usr/bin/env bash
# what-changed.sh — the owner's one morning read: what moved since they last looked,
# in the order they act on it, each line carrying the id that zooms in.
#
# SYNC-DESIGN.md step 4 (2026-08-26). Reads the stores that already exist; writes
# nothing but its own "last look" stamp, per owner not per session, so it survives
# every /clear. Sections, in order:
#   RULINGS NEEDED   USER: rows the owner can act on today (blocked-by rows excluded)
#   CLOSED           tasks completed since the last look
#   STARTED          tasks that went in_progress since the last look
#   LANES            session-state files changed since the last look (working/blocked/finished)
#   REVIVES          revive / ipc-wake verdict lines since the last look
#
#   what-changed.sh [--since <ISO|Nh|Nd>] [--mark]   (--mark stamps now as the last look)
set -uo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
STAMP="${WHAT_CHANGED_STAMP:-$HOME/.claude/.what-changed.last}"; T="$HOME/.claude/tasks"; S="$HOME/.claude/session-state"; W="$HOME/.claude/warden"
since=""; mark=0
while [ $# -gt 0 ]; do case "$1" in --since) since="$2"; shift 2;; --mark) mark=1; shift;; *) echo "usage: what-changed.sh [--since ISO|Nh|Nd] [--mark]" >&2; exit 2;; esac; done
now=$(date +%s)
case "$since" in
  "")     cut=$(cat "$STAMP" 2>/dev/null || echo $(( now - 86400 ))) ;;
  *h)     cut=$(( now - ${since%h}*3600 )) ;;
  *d)     cut=$(( now - ${since%d}*86400 )) ;;
  *)      cut=$(date -j -f %Y-%m-%dT%H:%M:%S "${since%Z}" +%s 2>/dev/null || date -j -f %Y-%m-%dT%H:%M "$since" +%s 2>/dev/null || echo $(( now - 86400 ))) ;;
esac
cutiso=$(date -u -r "$cut" +%FT%TZ)
printf 'WHAT CHANGED since %s  (%s ago)\n' "$cutiso" "$(( (now - cut) / 3600 ))h"
# task rows: one pass over every store, classify by mtime and status
rows=$(for f in "$T"/session-*/*.json; do [ -f "$f" ] || continue; m=$(stat -f %m "$f"); s8=$(basename "$(dirname "$f")"); s8="${s8#session-}"; jq -c --arg s8 "$s8" --argjson m "$m" '{id:("task://"+$s8+"/"+(.id|tostring)),subject:(.subject|.[0:90]),status,blocked_on:(.metadata.blocked_on // ""),m:$m}' "$f" 2>/dev/null; done)
echo; echo "RULINGS NEEDED (you can act today)"
printf '%s\n' "$rows" | jq -r 'select(.status!="completed" and (.blocked_on|test("^\\s*USER\\s*:";"i"))) | "  \(.id)  \(.subject)\n      \(.blocked_on|.[0:100])"' | head -40
echo; echo "CLOSED since last look"
printf '%s\n' "$rows" | jq -r --argjson c "$cut" 'select(.status=="completed" and .m>$c) | "  \(.id)  \(.subject)"' | head -30
echo; echo "STARTED since last look"
printf '%s\n' "$rows" | jq -r --argjson c "$cut" 'select(.status=="in_progress" and .m>$c) | "  \(.id)  \(.subject)"' | head -20
echo; echo "LANES (session-state changed)"
for f in "$S"/*.json; do [ -f "$f" ] || continue; m=$(stat -f %m "$f"); [ "$m" -gt "$cut" ] || continue; jq -r '"  \(.sid[0:8])  \(.state)  \(.reason|.[0:80])  store=\(.store)"' "$f"; done
echo; echo "REVIVES / WAKES"
awk -v c="$cutiso" '$1>=c && ($2=="revive" || $2=="ipc-wake") && ($0 ~ /WOKEN|REVIVING|REFUSED|capped|gated|budget/)' "$W/beat.log" 2>/dev/null | cut -c1-140 | tail -20
[ "$mark" = 1 ] && { printf '%s' "$now" > "$STAMP"; echo; echo "(last look stamped: now)"; }
exit 0
