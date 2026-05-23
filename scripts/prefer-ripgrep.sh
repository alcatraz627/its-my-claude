#!/usr/bin/env bash
# PreToolUse hook: intercept Bash grep commands and redirect to ripgrep (rg)
# Benchmark: rg is 18–65× faster than /usr/bin/grep on the ~/.claude corpus.
# Receives JSON on stdin with tool_name, tool_input fields.
# Outputs JSON to block and provide rg replacement guidance.

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

  cat <<BLOCK_JSON
{
  "decision": "block",
  "reason": "[33m⚡ PREFER RIPGREP: 'grep' is blocked — rg is 18–65× faster on this machine.[0m\n\n[33mBlocked command:[0m  $command\n[33mStatus:[0m           $AVAIL_LINE$INSTALL_NOTE\n\n[33mReplacement:[0m\n   $USAGE_HINT\n\n[33m📋 Flag reference (rg equiv for common grep flags):[0m\n   grep -r   →  rg --no-ignore --hidden\n   grep -i   →  rg -i\n   grep -l   →  rg -l\n   grep -c   →  rg -c\n   grep -E   →  rg (default, uses Rust regex)\n   grep -v   →  rg -v\n   grep -n   →  rg -n  (default: line numbers on)\n\n[33m⚠  When grep MUST be used (confirm with user first):[0m\n   1. rg is unavailable AND brew install fails (no network, restricted env)\n   2. Strict POSIX BRE syntax required (-P Perl features differ in edge cases)\n   3. Binary file scanning with specific byte offsets (use grep -a)\n   In these cases: ask the user before falling back to /usr/bin/grep."
}
BLOCK_JSON
  exit 0
fi

# Not a grep command — allow through
exit 0
