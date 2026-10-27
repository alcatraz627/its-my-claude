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

# shell-scan.py reads the command like a shell: an `rm` that is only a word in a
# commit message or an `echo` is data, while `\rm`, `/bin/rm`, `command rm`,
# `env rm`, `sudo rm`, `xargs rm`, `find -exec rm`, `find -delete`, `unlink` and
# `bash -c "rm ..."` are all the same deletion. NOT caught, because no static
# reading can see them: a deletion through a variable or alias (`$RM x`),
# `rmdir`, and a language runtime (`python3 -c "os.remove(...)"`, `perl unlink`).
# If the scanner is missing or fails, the older de-quoted grep below decides.
SHELL_SCAN="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/hooks/shell-scan.py"
hit=""
if scanned=$(printf '%s' "$command" | python3 "$SHELL_SCAN" rm 2>/dev/null); then
  hit=$(printf '%s\n' "$scanned" | head -1)
else
  scan=$(printf '%s' "$command" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")
  if echo "$scan" | grep -qE '(^|[;&|]\s*)rm\s+' && ! echo "$scan" | grep -qE '(^|[;&|]\s*)git\s+rm\b'; then
    hit=$(echo "$command" | tr ';&|' '\n' | grep -E '^\s*rm\s' | head -1)
  fi
fi

if [[ -n "$hit" ]]; then
  # The paths being deleted, for the warning message: drop the verb and its flags.
  paths=$(printf '%s' "$hit" | sed -E 's/^[[:space:]]*(rm|unlink|find)[[:space:]]+//' | tr ' ' '\n' | grep -v '^-' | tr '\n' ' ' | xargs || true)
  [[ -z "$paths" ]] && paths="<files>"

  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook safe-delete --action block --heeded unknown >/dev/null 2>&1 || true
  # Built with jq: the blocked command is spliced into the text, and a quote in
  # it (`bash -c "rm x"`) would otherwise make the JSON invalid and the block void.
  y=$'\033[33m'; z=$'\033[0m'
  reason="${y}⚠️  SAFE DELETE: 'rm' is blocked. Use 'trash' instead to move files to macOS Trash.${z}

${y}Blocked command:${z}  $command
${y}Replacement:${z}     Replace 'rm [-rf]' with 'trash': e.g.: trash $paths

${y}💡 Recovery:${z} If a file was already deleted, check:
   • Finder → Trash (⌘+Shift+Delete to empty)
   • CLI: ls ~/.Trash/
   • Restore: mv ~/.Trash/<filename> <original-path>"
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
  exit 0
fi

# Not a deletion: allow through
exit 0
