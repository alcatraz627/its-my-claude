#!/usr/bin/env bash
# log-run.sh <skill-name> <message>
# Appends a timestamped entry to .claude/skills/shared/run.log
# Usage: bash .claude/skills/shared/log-run.sh "project-index" "Run started"

set -euo pipefail

SKILL_NAME="${1:-unknown}"
MESSAGE="${2:-}"
LOG_FILE="$(dirname "$0")/run.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

echo "[$TIMESTAMP] [$SKILL_NAME] $MESSAGE" >> "$LOG_FILE"
echo "Logged: [$TIMESTAMP] [$SKILL_NAME] $MESSAGE"
