#!/usr/bin/env bash
# The checkpoint a fresh session in a folder should be offered for /catchup, if
# any: the file the last session there left behind. The statusline shows it as a
# chip until the session's first turn, the way the decide chip shows a waiting page.
#
# Same rules as the gcc-mods resume offer (mods/gcc-mods/hooks/register.tsx,
# findCheckpoint), so the band and the statusline never offer different files:
#   1. resolve.sh --auto --cwd DIR, when it finds one;
#   2. else the newest index entry whose project_root is DIR (not a session-end);
#   3. else the newest _*.claude.md in DIR, a _precompact snapshot only when
#      nothing else exists;
# and nothing older than 7 days. Prints the absolute path, or nothing. Exit 0.
#
# Usage: offer.sh --cwd DIR

set -uo pipefail
CWD=""
[ "${1:-}" = "--cwd" ] && CWD="${2:-}"
[ -n "$CWD" ] && [ -d "$CWD" ] || exit 0
GCC="${OFFER_GCC_ROOT:-$HOME/.claude}"
INDEX="$GCC/checkpoints/index.jsonl"
now=$(date +%s)
max_age=$(( 7 * 86400 ))

mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }
fresh() { [ -f "$1" ] && [ $(( now - $(mtime "$1") )) -le "$max_age" ]; }

p=$(bash "$GCC/scripts/checkpoint/resolve.sh" --auto --cwd "$CWD" 2>/dev/null | jq -r 'select(type == "object") | .checkpoint_path // empty' 2>/dev/null | head -1)
if [ -n "$p" ] && fresh "$p"; then printf '%s\n' "$p"; exit 0; fi

if [ -f "$INDEX" ]; then
  p=$(tail -n 200 "$INDEX" | jq -r --arg c "$CWD" 'select(.project_root == $c and .kind != "session-end" and (.checkpoint_path // "") != "") | "\(.ts // "")\t\(.checkpoint_path)"' 2>/dev/null | sort | tail -1 | cut -f2)
  if [ -n "$p" ] && fresh "$p"; then printf '%s\n' "$p"; exit 0; fi
fi

best=""; best_m=0; snap=""; snap_m=0
for f in "$CWD"/_*.claude.md; do
  [ -f "$f" ] || continue
  m=$(mtime "$f")
  case "${f##*/}" in
    _precompact*) [ "$m" -gt "$snap_m" ] && { snap="$f"; snap_m=$m; } ;;
    *)            [ "$m" -gt "$best_m" ] && { best="$f"; best_m=$m; } ;;
  esac
done
[ -z "$best" ] && best="$snap"
[ -n "$best" ] && fresh "$best" && printf '%s\n' "$best"
exit 0
