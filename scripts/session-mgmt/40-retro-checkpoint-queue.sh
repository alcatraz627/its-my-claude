#!/usr/bin/env bash
# 40-retro-checkpoint-queue.sh — SessionStart hook.
#
# When a new Claude session starts in a project, check if the PREVIOUS sessions
# in this CWD ended without a /core-dump (i.e., their UUID is not in
# checkpoints/index.jsonl). If yes, enqueue them for retroactive dump.
#
# Doesn't run the dump here — just enqueues. The startup task
# 30-retro-checkpoint-flush.sh actually processes the queue.
#
# Mute: touch ~/.claude/.retro-queue-off

set -uo pipefail

[[ -f "$HOME/.claude/.retro-queue-off" ]] && exit 0

INPUT=$(cat 2>/dev/null || true)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[[ -n "$CWD" ]] || CWD="$PWD"

# Only act if CWD has a .claude/ subdir (i.e., it's a real project).
[[ -d "$CWD/.claude" ]] || exit 0

# Encode CWD the way projects/ uses (/ → -, . → -).
ENCODED=$(printf '%s' "$CWD" | sed 's|/|-|g' | sed 's|\.|-|g')
PROJECT_TRANSCRIPTS="$HOME/.claude/projects/$ENCODED"
[[ -d "$PROJECT_TRANSCRIPTS" ]] || exit 0

# Run retro-scan scoped to this project, enqueue results.
"$HOME/.claude/scripts/checkpoint/retro-scan.sh" \
  --enqueue \
  --min-turns 5 \
  --max-age-days 7 \
  --limit 5 \
  >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0
