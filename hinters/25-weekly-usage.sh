#!/usr/bin/env bash
# 25-weekly-usage.sh — UserPromptSubmit hinter: cost-confirm big actions when
# the WEEKLY usage window runs hot (owner ruling 2026-08-21).
#
# Arms at week > 80% (statusline telemetry). Fires at most once per 45 minutes
# per session; the injected text carries the press-on rule, so one owner "go"
# holds until the next fire. The 5h window and session context have no bearing.
# Fires append to logs/weekly-usage-hint.jsonl for the week-1 validation review.
# Mute: touch ~/.claude/.no-weekly-usage-hint
set -uo pipefail
PROMPT=$(cat 2>/dev/null || echo "")
[ -f "$HOME/.claude/.no-weekly-usage-hint" ] && exit 0
SID="${CLAUDE_HINT_SID:-${CLAUDE_CODE_SESSION_ID:-}}"; [ -n "$SID" ] || exit 0
case "$PROMPT" in "<system-reminder>"*|"<command-name>"*|"<local-command"*|"Caveat:"*|"Base directory for this skill:"*|"Stop hook feedback:"*|"<task-notification>"*|"Another Claude session sent"*|"Wake check."*|"Warden 3h check-in"*) exit 0;; esac

LIMITS="${WEEKLY_HINT_LIMITS:-$HOME/.claude/widgets/.limits.json}"
[ -f "$LIMITS" ] || exit 0
age=$(( $(date +%s) - $(stat -f %m "$LIMITS" 2>/dev/null || echo 0) ))
[ "$age" -gt 1800 ] && exit 0
wk=$(jq -r '(.week.pct | tonumber? | floor) // empty' "$LIMITS" 2>/dev/null)
[[ "$wk" =~ ^[0-9]+$ ]] || exit 0
[ "$wk" -gt "${WEEKLY_HINT_PCT:-80}" ] || exit 0

STATE="/tmp/claude-weeklyhint-${SID:0:8}"
# A /clear wipes the model's memory but not this sid-keyed cooldown, so the
# fresh context would not know the window is hot. hook_clear_reset drops the
# stale cooldown once per clear (owner ask 2026-08-21: it fires so it KNOWS).
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null && hook_clear_reset "${SID:0:8}" "$STATE"
now=$(date +%s); last=$(cat "$STATE" 2>/dev/null || echo 0)
[[ "$last" =~ ^[0-9]+$ ]] || last=0
[ $(( now - last )) -lt 2700 ] && exit 0
echo "$now" > "$STATE"
printf '{"ts":"%s","sid":"%s","week_pct":%s}\n' "$(date -u +%FT%TZ)" "${SID:0:8}" "$wk" >> "$HOME/.claude/logs/weekly-usage-hint.jsonl" 2>/dev/null || true

echo "[weekly-usage] Weekly window at ${wk}% — before any BIG action (workflow/fleet, large ingestion, opus-or-higher seat, long generation), estimate its cost in one line, tell the user, and get an explicit go. One ask per 45m window: if the user already pressed on since this nudge, proceed without re-asking until the next one. The 5h window and session context have NO bearing on this. (mute: touch ~/.claude/.no-weekly-usage-hint)"
