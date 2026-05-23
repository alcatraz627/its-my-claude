#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Edit/Write
# Receives JSON on stdin with tool_name, tool_input, tool_output fields

set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Exit if no file path
[[ -z "$file_path" ]] && exit 0

# Only format known file types
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.md|*.html|*.svelte|*.vue)
    ;;
  *)
    exit 0
    ;;
esac

# Skip if file doesn't exist (deleted files)
[[ -f "$file_path" ]] || exit 0

# Find the project root (nearest package.json with prettier)
dir=$(dirname "$file_path")
while [[ "$dir" != "/" ]]; do
  if [[ -f "$dir/node_modules/.bin/prettier" ]]; then
    "$dir/node_modules/.bin/prettier" --write "$file_path" 2>/dev/null || true
    exit 0
  fi
  dir=$(dirname "$dir")
done

# Fallback: try global npx prettier (silent, don't block on install)
if command -v prettier &>/dev/null; then
  prettier --write "$file_path" 2>/dev/null || true
fi

exit 0
