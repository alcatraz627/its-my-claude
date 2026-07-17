#!/usr/bin/env bash
# block-nested-claude.sh — reject tool calls that would WRITE into ~/.claude/.claude/.
#
# The nesting happens one way: when cwd is ~/.claude itself, a relative path like
# ".claude/output/..." resolves to ~/.claude/.claude/output/... rather than to
# ~/.claude/output. Skill templates cause it because they assume cwd is a project
# root with a .claude/ subdirectory.
#
# Correct targets when cwd is ~/.claude:
#   Reports -> ~/.claude/assets/reports/   Scripts -> ~/.claude/scripts/
#   Skills  -> ~/.claude/skills/           Scratch -> ~/.claude/scratchpad/
#
# Two things this guard must not get backwards:
#
#   Writing is the harm; naming is not. Reading the nested dir, grepping for the
#   pattern, testing for a marker inside it, or writing prose about it are all how
#   you AUDIT the nesting. A guard that matches command text blocks the audit and
#   still misses the accident, because the accident never spells the path out.
#
#   cwd decides, not the text. A relative ".claude/output" is CORRECT in a normal
#   project (its .claude/ is a real subdir) and wrong only when cwd is the gcc.
#
# Scope, stated plainly: this catches accidental writes via the common shell verbs
# and redirects. It is not a sandbox — a write buried in `python3 -c "open(...)"`
# is not detected, and is not the accident this guard exists for.
#
# Tests: bash ~/.claude/scripts/block-nested-claude.test.sh

set -uo pipefail

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
notebook_path=$(printf '%s' "$input" | jq -r '.tool_input.notebook_path // empty' 2>/dev/null)
command_str=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)

GCC="$HOME/.claude"
offender=""
why=""

# 1. Write/Edit/NotebookEdit declare their target outright — check it directly.
for p in "$file_path" "$notebook_path"; do
  [ -n "$p" ] || continue
  case "$p" in
    */.claude/.claude/*|*/.claude/.claude) offender="$p"; why="write target is already nested"; break ;;
  esac
done

# 2. Bash names no target, so infer one — but only for commands that can WRITE.
if [ -z "$offender" ] && [ -n "$command_str" ]; then
  # A quoted span is data, not a target: `rg '/.claude/.claude/'` is a search.
  blanked=$(printf '%s' "$command_str" | sed "s/'[^']*'/''/g; s/\"[^\"]*\"/\"\"/g")
  # Noise redirects never write the nest; leaving them in reads as a write.
  blanked=$(printf '%s' "$blanked" | sed -E 's/[0-9]*>&[0-9]+//g; s/[0-9]*>>?[[:space:]]*\/dev\/null//g')

  writes_cmd='(^|[;&|(]|&&|\|\|)[[:space:]]*(sudo[[:space:]]+)?(mkdir|touch|cp|mv|tee|install|ln|dd|rsync)([[:space:]]|$)'
  writes_redir='>>?[[:space:]]*[^[:space:]|&;<]'

  if printf '%s' "$blanked" | grep -qE "$writes_cmd" || printf '%s' "$blanked" | grep -qE "$writes_redir"; then
    case "$blanked" in
      */.claude/.claude/*|*/.claude/.claude)
        offender="$command_str"; why="writes to an already-nested absolute path" ;;
    esac
    # The actual root cause: a relative .claude/ write while cwd IS the gcc.
    if [ -z "$offender" ] && [ "$cwd" = "$GCC" ]; then
      if printf '%s' "$blanked" | grep -qE '(^|[[:space:]=>])\.claude/'; then
        offender="$command_str"
        why="relative .claude/ write while cwd is $GCC — resolves into the nest"
      fi
    fi
  fi
fi

[ -n "$offender" ] || exit 0

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook block-nested-claude --action block --heeded unknown >/dev/null 2>&1 || true
cat >&2 <<EOF
BLOCKED: this would write into the nested .claude directory.

Reason: $why
Offending call:
  $offender

When cwd is $GCC, a relative ".claude/output/..." does NOT mean "$GCC/output" —
it resolves one level deeper, into a directory nothing reads.

Correct targets when working inside the gcc:
  - Reports -> $GCC/assets/reports/
  - Scripts -> $GCC/scripts/
  - Skills  -> $GCC/skills/
  - Scratch -> $GCC/scratchpad/

Use an absolute path, or drop the ".claude/" segment.

Reading, grepping, or testing that path is NOT blocked — only writing to it.
EOF
exit 2
