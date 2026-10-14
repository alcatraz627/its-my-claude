#!/usr/bin/env bash
# 06-guidance.sh — UserPromptSubmit hinter. Surfaces the user's standing
# directives (guidance/notes.md) that are relevant to THIS turn. Directives
# tagged with a keyword come back on every prompt that mentions it; directives
# scoped `all` apply to every prompt, so they are shown once per session and
# again after a /clear (post-clear-counter-reset.sh forgets what the session
# was shown). Reads the prompt from stdin (per the hinter contract).
set -uo pipefail

PROMPT=$(cat 2>/dev/null || true)
[ -n "$PROMPT" ] || exit 0

G="$HOME/.claude/scripts/guidance.sh"
[ -x "$G" ] || exit 0
. "$HOME/.claude/scripts/hooks/inject-once.sh" 2>/dev/null || true

matched=$("$G" relevant "$PROMPT" 2>/dev/null)
[ -n "$matched" ] || exit 0

SID="${CLAUDE_HINT_SID:-${CLAUDE_CODE_SESSION_ID:-}}"
out=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  tags=$(printf '%s' "$line" | sed -n 's/^- [^[]*\[\([^]]*\)\].*/\1/p' | tr 'A-Z' 'a-z' | tr ',' ' ')
  is_all=0
  for kw in $tags; do [ "$kw" = "all" ] && is_all=1; done
  if [ "$is_all" = 1 ] && [ -n "$SID" ] && command -v inject_once_session >/dev/null 2>&1; then
    inject_once_session "$SID" guidance-all "$line" || continue
  fi
  out="${out}${line}"$'\n'
done <<< "$matched"
[ -n "$out" ] || exit 0

printf '[guidance] standing user directives relevant to this turn — internalize, weigh in your choices:\n%s' "${out%$'\n'}"
