#!/usr/bin/env bash
# Fired by the one-shot 'ipc-metrics-recheck' (2026-07-26). Re-measures the
# claude-ipc pain numbers two weeks after the wake-plugin deployment and drops
# a dated report: all-time vs post-deployment (--since 2026-07-11) windows.
# The success criterion (activation report 06): stuck-queued % and ask-fail %
# must have collapsed for the post-deployment window. Never fails.
set -uo pipefail
OUT="$HOME/.claude/assets/reports/20260726-ipc-metrics-recheck.md"
METRICS="$HOME/Code/Claude/claude-ipc/scripts/ipc-metrics.sh"
{
  echo "# ipc metrics recheck — scheduled 2026-07-26 (baseline: 20260710-ipc-activation/01-data-profile.md)"
  echo "Baseline (2026-07-10, filtered organic): stuck-queued 67% · ask success 30%."
  echo
  echo "## All-time"
  bash "$METRICS" 2>&1
  echo
  echo "## Post-wake-deployment window"
  bash "$METRICS" --since 2026-07-11 2>&1
} > "$OUT" 2>/dev/null || true
HEAD="$(rg -o 'headline.*' "$OUT" 2>/dev/null | tail -2 | tr '\n' ' ' || true)"
osascript -e "display notification \"ipc post-deploy numbers ready: ${HEAD:-see report} — $OUT\" with title \"IPC Metrics Recheck\" sound name \"Glass\"" 2>/dev/null || true
printf '%s review-due — report: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$OUT" >> "$HOME/.claude/scheduled/review-due.log" 2>/dev/null || true
exit 0
