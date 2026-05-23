#!/usr/bin/env bash
# 06-guidance.sh — UserPromptSubmit hinter. Surfaces the user's standing
# directives (guidance/notes.md) that are relevant to THIS turn — scope `all`,
# or a tag matching the prompt. Relevance-gated by design so context stays light
# as the notes file grows. Reads the prompt from stdin (per the hinter contract).
set -uo pipefail

PROMPT=$(cat 2>/dev/null || true)
[ -n "$PROMPT" ] || exit 0

G="$HOME/.claude/scripts/guidance.sh"
[ -x "$G" ] || exit 0

matched=$("$G" relevant "$PROMPT" 2>/dev/null)
[ -n "$matched" ] || exit 0

printf '[guidance] standing user directives relevant to this turn — internalize, weigh in your choices:\n%s' "$matched"
