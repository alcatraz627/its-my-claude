#!/usr/bin/env bash
# prefer-read-over-cat.sh — PreToolUse[Bash] hook. Nudges toward the Read tool
# when `cat <file>` is used for file inspection (not for piping/redirect).
#
# Why: Read tool gives line-numbered output, respects token limits, supports
# offset/limit. `cat <file>` floods context with full content when only a
# slice is wanted.
#
# False-positive guards:
#   - `cat <<EOF` (HEREDOC) — never warn
#   - `cat foo > bar` (redirect) — never warn
#   - `cat file | tool` (piping into a transform, e.g., jq, rg) — never warn
#     (this is using cat as input adapter, not for inspection)
#   - `cat -` (stdin) — never warn
#
# Only warns on bare `cat <file>` (possibly with `| head`, `| tail` for slicing
# — those ARE the cases where Read with limit/offset is the win).
#
# Mute: touch ~/.claude/.no-cat-hint

set -uo pipefail
[[ -f "$HOME/.claude/.no-cat-hint" ]] && exit 0

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# Quick exits for common legitimate uses
echo "$CMD" | rg -q '<<\s*\w+|<<-\s*\w+' 2>/dev/null && exit 0    # heredoc
echo "$CMD" | rg -q 'cat\s+-\b|cat\s*$' 2>/dev/null && exit 0    # cat -, bare cat (rare)

# Detect `cat <file>` patterns. The trigger:
#   - starts with `cat` (possibly indented)
#   - followed by a path (not -, not <<, not -n / -A flags)
#   - either standalone OR piped to head/tail/wc/-l (slicing — Read can do)
#
# DOES NOT warn for:
#   - cat foo > bar  (redirect — Bash idiom)
#   - cat foo | jq   (input adapter for transform)
#   - cat foo | rg   (input adapter for search — though rg-file would be better)
if echo "$CMD" | rg -q '(^|;|&&|\|\|)\s*cat\s+[^-<|>]\S*\s*(\||$|;|&&)' 2>/dev/null; then
  # Further filter: skip if piped to non-slicing tool
  if echo "$CMD" | rg -q 'cat\s+\S+\s*\|\s*(jq|rg|grep|awk|sed|sort|uniq|cut|tr|xargs|python|node)' 2>/dev/null; then
    exit 0  # input-adapter use; legitimate
  fi
  cat <<'EOF'
[hint] `cat <file>` floods context with the whole file. Prefer the Read tool:
  - Read with `offset` + `limit` for partial views (replaces `cat | head -N`)
  - Read alone for full file (gives line-numbered output for accurate citing)
  - Bash `cat` is still right for HEREDOC, redirect, or stdin adapter — those
    cases aren't flagged here.
Mute: touch ~/.claude/.no-cat-hint
EOF
fi

exit 0
