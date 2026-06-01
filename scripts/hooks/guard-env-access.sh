#!/usr/bin/env bash
# guard-env-access.sh — PreToolUse hook on Edit/Write/MultiEdit.
#
# Env vars should be reached through ONE accessor a project defines once, not
# scattered raw reads — but every project does it differently (a config module,
# a validated schema, a typed wrapper). So the first time a session adds env
# access to a project, this nudges the agent to *establish the convention once*
# (ask the user how env access should work here, record it), and thereafter to
# route through that cached convention instead of adding another raw read.
#
# Run-once-and-cache: the decision is made one time per project, persisted at
# <root>/.claude/conventions/env-access.md, and reused every time after.
#
# Generalizes the old warn-raw-process-env.sh (TS-only, NODE_ENV/NEXT/VERCEL
# allowlist, advisory) to all languages + any env var. Graduated from atone slug
# adding-env-var-reads-without-checking-config (S3, worsening).
#
# ADVISORY — always exits 0. (You can't force "ask the user" mid-write; the
# nudge + the cached convention are the lever, not a block.)
#
# Mute:          touch ~/.claude/.env-access-off
# One-shot skip: ENV_ACCESS_OFF=1

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
echo "$INPUT" | jq empty 2>/dev/null || exit 0

[ "${ENV_ACCESS_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.env-access-off" ] && exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in Edit | Write | MultiEdit) ;; *) exit 0 ;; esac

FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FP" ] && exit 0

# Skip boundary + convention files: the .env files themselves, the convention
# doc, and anything that reads as the central config/flags accessor or a test.
case "$FP" in
  *.env|*.env.*|*/env-access.md) exit 0 ;;
  */config.*|*/config/*|*/flags.*|*/settings.py|*/env.ts|*/env.py) exit 0 ;;
  *.test.*|*.spec.*|*_test.*|*_spec.*|*/test/*|*/tests/*|*/__tests__/*|*/spec/*) exit 0 ;;
esac
# Only known code files (keep the detector honest, avoid prose false-positives).
case "$FP" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.py|*.rb|*.go|*.rs|*.java|*.php) ;;
  *) exit 0 ;;
esac

NEW_CONTENT=""
case "$TOOL" in
  Write)     NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty') ;;
  Edit)      NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty') ;;
  MultiEdit) NEW_CONTENT=$(echo "$INPUT" | jq -r '[.tool_input.edits[]?.new_string] | join("\n") // empty') ;;
esac
[ -z "$NEW_CONTENT" ] && exit 0

# Broad env-access detection across languages.
ENV_RE='process\.env|import\.meta\.env|Deno\.env\.get|os\.getenv|os\.environ|os\.Getenv|os\.LookupEnv|System\.getenv|std::env::var|ENV\[|\$_ENV\[|[^A-Za-z_]getenv\('
printf '%s' "$NEW_CONTENT" | grep -qE "$ENV_RE" || exit 0

# Walk up from the file to the project root (nearest .git or .claude dir) so the
# convention is scoped per-project. No root → can't scope; stay silent.
dir=$(dirname "$FP")
root=""
while [ "$dir" != "/" ] && [ -n "$dir" ]; do
  if [ -d "$dir/.git" ] || [ -d "$dir/.claude" ]; then root="$dir"; break; fi
  dir=$(dirname "$dir")
done
[ -z "$root" ] && exit 0

CONV="$root/.claude/conventions/env-access.md"

if [ -f "$CONV" ]; then
  cat >&2 <<EOF
[env-access] new env read in $(basename "$FP"). This project has an established
env-access convention — route through it instead of adding a raw read:
  $CONV
  Mute: touch ~/.claude/.env-access-off   ·   One-shot: ENV_ACCESS_OFF=1
EOF
else
  cat >&2 <<EOF
[env-access] new env read in $(basename "$FP"), and this project hasn't
established how env access should be done (rules/env-var-config-pattern.md).

  Establish it ONCE: ask the user how env vars should be accessed here — a
  central config module? a validated schema (zod/pydantic)? a typed wrapper? —
  then record the answer + a single accessor at
    $CONV
  and route this (and future) reads through that accessor, defined once.

  Mute: touch ~/.claude/.env-access-off   ·   One-shot: ENV_ACCESS_OFF=1
EOF
fi
exit 0
