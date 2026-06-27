#!/usr/bin/env bash
# backlog-surface.sh — SessionStart hook. Closes the improvement loop by pulling
# the human back to the triaged backlog, so the triage file does not become a new
# graveyard (the failure that befell preference-harvest's candidate files).
#
# When the weekly backlog-consolidate has produced PROMOTE candidates, this injects
# ONE terse line at session start naming the count + top items and pointing at
# /backlog-triage. It surfaces ONLY the triaged PROMOTE set (never the raw 50-item
# backlog — that would be noise), only when fresh, and at most once every few days
# so it never nags.
#
# Registered DIRECTLY in settings.json SessionStart (NOT via the orchestrator,
# whose run.sh sends every task's stdout to /dev/null — which would drop this
# injection, the same latent bug that currently dark-holes dream-insights and
# pending-proposals).
#
# Reads the machine-readable sidecar ~/.claude/.backlog-triage-latest.json written
# by backlog-consolidate.py. Prints {additionalContext} when it fires, nothing
# otherwise; always exits 0 (a SessionStart hook must never block).
# Mute: touch ~/.claude/.no-backlog-surface

set -uo pipefail
[ -f "$HOME/.claude/.no-backlog-surface" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

SIDECAR="$HOME/.claude/.backlog-triage-latest.json"
COOLDOWN_MARKER="$HOME/.claude/.backlog-surface-last"
COOLDOWN_SECONDS=$((2 * 24 * 3600))   # surface at most once every 2 days
FRESH_DAYS=14                          # ignore a triage file older than this

[ -s "$SIDECAR" ] || exit 0

# Only act when there are PROMOTE candidates to act on.
promote=$(jq -r '.counts.PROMOTE // 0' "$SIDECAR" 2>/dev/null)
[ -n "$promote" ] && [ "$promote" -gt 0 ] 2>/dev/null || exit 0

# Freshness: skip a stale triage file (consolidate hasn't run recently).
tdate=$(jq -r '.date // empty' "$SIDECAR" 2>/dev/null)
if [ -n "$tdate" ]; then
  tepoch=$(date -j -f "%Y-%m-%d" "$tdate" "+%s" 2>/dev/null || date -d "$tdate" "+%s" 2>/dev/null || echo 0)
  now=$(date +%s)
  [ "$tepoch" -gt 0 ] && (( now - tepoch > FRESH_DAYS * 24 * 3600 )) && exit 0
fi

# Cooldown: don't nag every new session.
now=$(date +%s)
if [ -f "$COOLDOWN_MARKER" ]; then
  last=$(cat "$COOLDOWN_MARKER" 2>/dev/null); last=${last:-0}
  (( now - last < COOLDOWN_SECONDS )) && exit 0
fi

# Build the line: count + up to 3 top PROMOTE titles.
tops=$(jq -r '.promote[:3] | map("• " + .title) | join("  ")' "$SIDECAR" 2>/dev/null)
[ -z "$tops" ] && tops="(see the triage file)"

msg="[backlog] ${promote} gcc improvement item(s) are triaged as PROMOTE and awaiting your decision: ${tops}. Run /backlog-triage to PROMOTE or DROP them. (Weekly consolidation; muted with ~/.claude/.no-backlog-surface.)"

printf '%s' "$now" > "$COOLDOWN_MARKER" 2>/dev/null || true
jq -nc --arg m "$msg" '{additionalContext: $m}'
exit 0
