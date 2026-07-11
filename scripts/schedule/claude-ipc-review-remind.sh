#!/usr/bin/env bash
# Fired by the one-shot 'claude-ipc-review' (2026-07-28). Reminds the user that
# the deferred wake-arc review findings are due — the BRIEF carries the agenda.
# Never fails.
set -uo pipefail
BRIEF="$HOME/.claude/assets/reports/20260728-claude-ipc-review/BRIEF.md"
osascript -e 'display notification "claude-ipc review due: drain-guard residual, snooze semantics, trivia — see the BRIEF." with title "claude-ipc Review Due" sound name "Glass"' 2>/dev/null || true
printf '%s review-due — brief: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$BRIEF" >> "$HOME/.claude/scheduled/review-due.log" 2>/dev/null || true
exit 0
