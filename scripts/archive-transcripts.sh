#!/usr/bin/env bash
# archive-transcripts.sh
#
# Permanent, incremental mirror of Claude Code session transcripts.
#
# Claude Code deletes session transcripts under ~/.claude/projects/ older than
# `cleanupPeriodDays` (settings.json). This job copies every transcript to a
# separate archive that is NEVER pruned, so the full history survives regardless
# of the live-working-set cleanup. Idempotent: rsync copies only new/changed
# files, and with no --delete the archive only ever grows.
#
# Schedule: daily (see the Automations calendar companion / launchd plist).

set -euo pipefail

SRC="$HOME/.claude/projects/"
DST="$HOME/.claude/archive/transcripts/"
LOG="$HOME/.claude/archive/archive.log"

mkdir -p "$DST"

# Mirror the directory structure + every *.jsonl, nothing else. No --delete, so a
# transcript pruned from projects/ stays in the archive forever.
rsync -a --prune-empty-dirs \
    --include='*/' --include='*.jsonl' --exclude='*' \
    "$SRC" "$DST"

count=$(find "$DST" -name '*.jsonl' 2>/dev/null | wc -l | tr -d ' ')
size=$(du -sh "$DST" 2>/dev/null | cut -f1)
printf '%s  archived: %s transcripts, %s total\n' \
    "$(date '+%Y-%m-%dT%H:%M:%S')" "$count" "$size" >> "$LOG"
