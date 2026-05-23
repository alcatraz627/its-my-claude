#!/usr/bin/env bash
# scripts/migrate-hint.sh — PreToolUse hook on Bash.
#
# Detects structural commands targeting ~/.claude/ that should be accompanied
# by a migration entry, and injects a hint suggesting /migrate.
#
# Triggers on: mv, ln, rmdir, rename, mkdir of a NEW top-level dir under
# ~/.claude/, or trash of a script referenced by settings.json.
#
# Does NOT block — just nudges. Mute with: touch ~/.claude/.no-migrate-hint
#
# Output: empty (silent) OR a hint to stdout (Claude Code surfaces hooks'
# stdout as additionalContext for the next turn).

set -uo pipefail

[[ -f "$HOME/.claude/.no-migrate-hint" ]] && exit 0

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# Pattern match for structural commands against ~/.claude/
should_nudge=0

# (a) mv/rename/ln/rmdir/trash with ~/.claude/ in the args
if echo "$CMD" | rg -q "(^|\s)(mv|rename|ln -s|rmdir|trash)\s+.*(\.claude/|~/\.claude/)" 2>/dev/null; then
  should_nudge=1
fi

# (b) mkdir creating a new top-level dir under ~/.claude/
if echo "$CMD" | rg -q "mkdir.*~?/\.claude/[^/]+/?(\s|$)" 2>/dev/null; then
  should_nudge=1
fi

(( should_nudge )) || exit 0

# Recent migration created in last 30 min?
recent=$(find "$HOME/.claude/migrations" -name '00*.md' -mmin -30 2>/dev/null | head -1)
[[ -n "$recent" ]] && exit 0  # User already filed one, don't repeat

cat <<EOF
[migrate-hint] Structural command on ~/.claude/ detected. If this is a
structural change (path move, rename, hook-arch update, schema change —
see conventions/gcc-hygiene.md), file a migration entry first:

  /migrate --title "<short title>"

Mute future hints: touch ~/.claude/.no-migrate-hint
EOF

exit 0
