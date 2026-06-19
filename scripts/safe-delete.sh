#!/usr/bin/env bash
# PreToolUse hook: intercept Bash rm commands and redirect to macOS Trash
# Receives JSON on stdin with tool_name, tool_input fields
# Outputs JSON to block the command and provide replacement guidance

set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

# Only intercept Bash commands
[[ "$tool_name" == "Bash" ]] || exit 0

command=$(echo "$input" | jq -r '.tool_input.command // empty')
[[ -n "$command" ]] || exit 0

# Match against a de-quoted copy so an `rm` named INSIDE a string literal — a
# commit message, an `echo`, RCA prose passed to another tool — is treated as
# data, not a command. A real deletion lives OUTSIDE quotes. Same idiom as
# guard-system-dir-writes.sh; closes the `echo "...; rm ..."` false positive.
scan=$(printf '%s' "$command" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")

# Detect rm commands (rm, rm -f, rm -rf, rm -r, etc.)
# Match: standalone rm at start of command or after && ; | etc.
# Skip: commands like "npm rm", "cargo rm", "git rm" (package manager operations)
if echo "$scan" | grep -qE '(^|[;&|]\s*)rm\s+'; then
  # Don't intercept git rm (staging area operation, not file deletion)
  if echo "$scan" | grep -qE '(^|[;&|]\s*)git\s+rm\b'; then
    exit 0
  fi

  # Extract the paths being deleted for the warning message
  # Split command on ; & | separators, find the rm fragment, strip rm + flags
  paths=$(echo "$command" | tr ';&|' '\n' | while IFS= read -r part; do
    if echo "$part" | grep -qE '^\s*rm\s'; then
      # Remove "rm", then remove standalone flags (words starting with -)
      echo "$part" | sed -E 's/^[[:space:]]*rm[[:space:]]+//' | tr ' ' '\n' | grep -v '^-' | tr '\n' ' ' | xargs
      break
    fi
  done)
  [[ -z "$paths" ]] && paths="<files>"

  # Output block decision with yellow-highlighted message
  cat <<BLOCK_JSON
{
  "decision": "block",
  "reason": "\u001b[33m⚠️  SAFE DELETE: 'rm' is blocked. Use 'trash' instead to move files to macOS Trash.\u001b[0m\n\n\u001b[33mBlocked command:\u001b[0m  $command\n\u001b[33mReplacement:\u001b[0m     Replace 'rm [-rf]' with 'trash' — e.g.: trash $paths\n\n\u001b[33m💡 Recovery:\u001b[0m If a file was already deleted, check:\n   • Finder → Trash (⌘+Shift+Delete to empty)\n   • CLI: ls ~/.Trash/\n   • Restore: mv ~/.Trash/<filename> <original-path>"
}
BLOCK_JSON
  exit 0
fi

# Not an rm command — allow through
exit 0
