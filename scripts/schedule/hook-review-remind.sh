#!/usr/bin/env bash
# Fired by the one-shot launchd job 'hook-telemetry-review' (2026-07-28). Its job
# is to REMIND — notify the user that ~3 weeks of hook telemetry has accumulated
# and a review session should be started. The Calendar companion is the primary
# reminder; this adds a desktop notification + a durable due-log line. Never fails.
set -uo pipefail
BRIEF="$HOME/.claude/assets/reports/20260728-hook-telemetry-review/BRIEF.md"
osascript -e 'display notification "3 weeks of hook telemetry ready — start a review session (see the review BRIEF)." with title "Hook Telemetry Review Due" sound name "Glass"' 2>/dev/null || true
mkdir -p "$HOME/.claude/scheduled" 2>/dev/null || true
printf '%s review-due — brief: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$BRIEF" >> "$HOME/.claude/scheduled/review-due.log" 2>/dev/null || true
exit 0
