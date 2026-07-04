#!/usr/bin/env bash
# preference-graduation-remind.sh — the monthly nudge to run the graduation pass.
#
# Preference graduation has two halves: surfacing candidate signals (automatable)
# and deciding which to bake into GLOSSARY / memory / rules (needs human judgment,
# per conventions/preference-graduation.md). A cron can only do the first half.
# So this script produces a consolidated month-window candidate file via the
# harvester, then posts a macOS notification reminding the human to run
# /preference-graduation to triage it. It never writes to GLOSSARY / memory / rules.
#
# Runtime contract: run by the com.alcatraz.preference-graduation-monthly launchd
# job on the 1st of each month. Prints a one-line summary; always exits 0.
set -uo pipefail

HARVEST="$HOME/.claude/scripts/preference-harvest.sh"
OUT=""
[ -x "$HARVEST" ] || [ -f "$HARVEST" ] && OUT="$(bash "$HARVEST" --days 31 2>/dev/null)"

# Count candidate bullets so the reminder says how much is waiting.
n=0
[ -n "$OUT" ] && [ -f "$OUT" ] && n=$(grep -c '^- ' "$OUT" 2>/dev/null || echo 0)

# Human-facing reminder. Non-fatal if osascript is unavailable (headless boot).
osascript -e "display notification \"${n} candidate(s) waiting. Run /preference-graduation to triage.\" with title \"Preference graduation due\" sound name \"Glass\"" 2>/dev/null || true

echo "preference-graduation-remind: ${n} candidate(s) in ${OUT:-<none>}"
