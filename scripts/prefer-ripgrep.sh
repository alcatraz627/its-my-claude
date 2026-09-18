#!/usr/bin/env bash
# lifecycle: tune-able hook (owner 2026-09-18); the mechanical guards carry no such header
# instrument: none-yet
# review-by: 2026-10-16
# retire-if: no instrument by review-by: retire or instrument
# PreToolUse hook: intercept Bash grep commands and redirect to ripgrep (rg)
# Benchmark: rg is 18–65× faster than /usr/bin/grep on the ~/.claude corpus.
# Receives JSON on stdin with tool_name, tool_input fields.
# Outputs JSON to block and provide rg replacement guidance.
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null; hook_snoozed prefer-ripgrep && exit 0

set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

[[ "$tool_name" == "Bash" ]] || exit 0

command=$(echo "$input" | jq -r '.tool_input.command // empty')
[[ -n "$command" ]] || exit 0

# ── Detect grep usage ────────────────────────────────────────────────────────
# Match: bare `grep`, `/usr/bin/grep`, `/bin/grep` at the start of a command
# or after shell separators (&&, ||, ;, |, newline).
# Skip: git grep (git's own index search, not a file system search)
#       package-manager operations: brew/npm/pip/cargo "grep" (name match, not the binary)
#       grep used as a variable name in scripts (var=grep)

# Heredoc bodies and quoted strings are prose. Without this, a message or a doc
# that QUOTES a search command was blocked as though it ran one (2026-09-04).
SCAN="$HOME/.claude/scripts/hooks/strip-payloads.py"
if [ -x "$SCAN" ]; then
  scanned=$(printf '%s' "$command" | python3 "$SCAN" 2>/dev/null) || scanned="$command"
  [ -n "$scanned" ] || scanned="$command"
else
  scanned="$command"
fi
command_raw="$command"
command="$scanned"

if echo "$command" | grep -qE '(^|[;&|]{1,2}|\n)\s*(\/usr\/bin\/grep|\/bin\/grep|grep)\s+'; then

  # Allow git grep — operates on git index, rg cannot replace it
  if echo "$command" | grep -qE '(^|[;&|]{1,2}|\n)\s*git\s+grep\b'; then
    # Only allow if the ONLY grep is git grep
    non_git=$(echo "$command" | sed 's/git[[:space:]]\+grep//g')
    if ! echo "$non_git" | grep -qE '(^|[;&|]{1,2}|\n)\s*(\/usr\/bin\/grep|\/bin\/grep|grep)\s+'; then
      exit 0
    fi
  fi

  # Detect whether rg is available
  RG_PATH=""
  for candidate in /opt/homebrew/bin/rg /usr/local/bin/rg; do
    [[ -x "$candidate" ]] && RG_PATH="$candidate" && break
  done

  if [[ -n "$RG_PATH" ]]; then
    INSTALL_NOTE=""
    AVAIL_LINE="ripgrep is available at [32m$RG_PATH[0m"
  else
    INSTALL_NOTE="\n\n[33m⚠  ripgrep not found. Install first:[0m\n   brew install ripgrep\n   Then retry with rg."
    AVAIL_LINE="ripgrep [31mnot found[0m on this machine"
  fi

  # Determine if this is a pipe-filter use vs file-search use
  # Pipe-filter: grep appears after | (pattern filter on stdin stream)
  # File-search: grep appears with -r/-R/-l/-c or with explicit paths
  IS_PIPE_FILTER=false
  if echo "$command" | grep -qE '\|\s*(\/usr\/bin\/grep|\/bin\/grep|grep)\s+'; then
    # Check it's not also a file search within the pipe
    if ! echo "$command" | grep -qE '(grep\s+.*-[rRlc])|(grep\s+-[a-zA-Z]*[rRlc])'; then
      IS_PIPE_FILTER=true
    fi
  fi

  if $IS_PIPE_FILTER; then
    USAGE_HINT="For pipe filtering:\n   [36mcmd | rg \"PATTERN\"[0m\n   [36mcmd | rg -i \"PATTERN\"    # case-insensitive[0m\n   [36mcmd | rg -v \"PATTERN\"    # invert match[0m"
  else
    USAGE_HINT="For file/directory search:\n   [36mrg --no-ignore --hidden \"PATTERN\" /path/          # full scope (equiv to grep -r)[0m\n   [36mrg --no-ignore --hidden -i \"PATTERN\" /path/       # case-insensitive[0m\n   [36mrg --no-ignore --hidden -l \"PATTERN\" /path/       # list files only[0m\n   [36mrg --no-ignore --hidden -g \"*.jsonl\" \"PATTERN\" /  # file-type scoped[0m\n   [36mrg --no-ignore --hidden -E \"REGEX\" /path/         # extended regex[0m"
  fi

  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prefer-ripgrep --action nudge --heeded unknown >/dev/null 2>&1 || true
  MESSAGE=$(printf '%b' "\033[33m⚡ PREFER RIPGREP: rg is much faster here. This ran; use rg next time.\033[0m\n\n\033[33mCommand:\033[0m  $command\n\033[33mStatus:\033[0m $AVAIL_LINE$INSTALL_NOTE\n\n\033[33mReplacement:\033[0m\n   $USAGE_HINT\n\n\033[33mFlag reference:\033[0m\n   grep -r   ->  rg --no-ignore --hidden\n   grep -i   ->  rg -i\n   grep -l   ->  rg -l\n   grep -c   ->  rg -c\n   grep -E   ->  rg (default)\n   grep -v   ->  rg -v\n   grep -n   ->  rg -n (on by default)\n\nWhen grep is genuinely required (rg missing, strict POSIX BRE, binary offsets), say so rather than switching silently.")
  jq -nc --arg m "$MESSAGE" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$m}}'

  exit 0
fi

# Not a grep command — allow through
exit 0
