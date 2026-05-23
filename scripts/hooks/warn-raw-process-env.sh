#!/usr/bin/env bash
# warn-raw-process-env.sh — PreToolUse hook on Edit/Write/MultiEdit.
#
# Graduated from atone pattern: raw-process-env-instead-of-project-flag (S2).
# When the agent inserts `process.env.NODE_ENV` / `process.env.NEXT_*` into
# .ts/.tsx files, the project usually already has an `isDevelopment` flag or
# similar helper. Raw env reads fragment the convention.
#
# This hook is ADVISORY (always exits 0). It warns when about to write
# matching content into a TS/TSX file. Skip for backend files (.py), config
# boundary files (.env*, .config.*), and the helper file itself.

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
echo "$INPUT" | jq empty 2>/dev/null || exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac

[ "${ATONE_NO_ENV_WARN:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/atone/.env-warn-off" ] && exit 0

FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FP" ] && exit 0

# Only fire on TS/TSX files. Skip the helper file boundaries.
case "$FP" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac
case "$FP" in
  */flags.ts|*/flags.tsx|*.env*|*/config.ts|*/config/*) exit 0 ;;
esac

# Pull new content from the right field per tool
NEW_CONTENT=""
case "$TOOL" in
  Write)     NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty') ;;
  Edit)      NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty') ;;
  MultiEdit) NEW_CONTENT=$(echo "$INPUT" | jq -r '[.tool_input.edits[]?.new_string] | join("\n") // empty') ;;
esac
[ -z "$NEW_CONTENT" ] && exit 0

if echo "$NEW_CONTENT" | grep -qE 'process\.env\.(NODE_ENV|NEXT_[A-Z_]+|VERCEL_[A-Z_]+)'; then
  ( bash "$HOME/.claude/scripts/atone.sh" feedback \
      --kind fired-and-useful \
      --slug raw-process-env-instead-of-project-flag \
      --trigger-id trig-raw-process-env-instead-of-project-flag \
      --notes "advisory fired on $TOOL of $FP" \
      >/dev/null 2>&1 & ) &

  cat >&2 <<EOF
[warn-raw-process-env] new content contains \`process.env.*\` in $FP

  Pattern: raw-process-env-instead-of-project-flag (atone S2)
  Risk:    most projects have a documented flag helper that wraps env reads.
           Raw reads at call-sites fragment the convention.

  Before this write — check the file's existing imports:
    grep -n "isDevelopment\|isProd\|Config" $FP

  Likely helpers (project-dependent):
    import { isDevelopment } from "@/utils/core/flags"       # FE
    from lib.config import Config                            # BE

  Mute: touch ~/.claude/atone/.env-warn-off
  One-shot bypass: ATONE_NO_ENV_WARN=1
EOF
fi
exit 0
