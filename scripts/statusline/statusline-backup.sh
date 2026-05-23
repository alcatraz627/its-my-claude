#!/usr/bin/env bash
# Rotates statusline config backups: bak_1 → bak_2, current → bak_1
# Usage: statusline-backup.sh [reason]
# Keeps max 2 backups. Only backs up if bak_1 differs from current.

set -uo pipefail

CONF="$HOME/.claude/statusline.conf"
BAK_DIR="$HOME/.claude"
BAK1="${BAK_DIR}/bak_1_statusline.conf"
BAK2="${BAK_DIR}/bak_2_statusline.conf"
REASON="${1:-manual}"

[[ ! -f "$CONF" ]] && echo "No statusline.conf to back up" && exit 1

# Skip if current matches bak_1 (no meaningful change since last backup)
if [[ -f "$BAK1" ]] && diff -q "$CONF" "$BAK1" >/dev/null 2>&1; then
  echo "Skip: current config unchanged from bak_1"
  exit 0
fi

# Rotate: bak_1 → bak_2
[[ -f "$BAK1" ]] && cp -f "$BAK1" "$BAK2"

# Current → bak_1 (with timestamp + reason in a comment header)
{
  echo "# Backup: $(date '+%Y-%m-%d %H:%M') — ${REASON}"
  cat "$CONF"
} > "$BAK1"

echo "Backed up statusline.conf → bak_1 (reason: ${REASON})"
[[ -f "$BAK2" ]] && echo "  Previous bak_1 rotated → bak_2" || true
