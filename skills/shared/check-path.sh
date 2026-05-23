#!/usr/bin/env bash
# check-path.sh <path>
# Exits 1 with a warning if the given path matches a forbidden pattern.
# Usage: bash .claude/skills/shared/check-path.sh "src/some/file.ts"

set -euo pipefail

PATH_ARG="${1:-}"

if [[ -z "$PATH_ARG" ]]; then
  echo "Usage: check-path.sh <path>" >&2
  exit 2
fi

FORBIDDEN_PATTERNS=(
  "node_modules"
  "\.git/"
  "^dist/"
  "^\.next/"
  "^build/"
  "^out/"
  "^coverage/"
  "^\.turbo/"
  "^\.cache/"
  "\.env"
  "\.pem$"
  "\.key$"
  "\.cert$"
)

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if echo "$PATH_ARG" | grep -qE "$pattern"; then
    echo "BLOCKED: '$PATH_ARG' matches forbidden pattern '$pattern'" >&2
    exit 1
  fi
done

echo "OK: '$PATH_ARG' is allowed"
exit 0
