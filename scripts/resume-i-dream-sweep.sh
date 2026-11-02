#!/usr/bin/env bash
# Resume the i-dream improvement sweep. Scheduled for Wed 2026-07-15 13:00 via
# gcc-schedule (name: resume-i-dream-sweep). Cold-starts a Claude session in the
# project that catches up from the checkpoint and picks up the open sweep items.
# Safe to re-run.
set -uo pipefail

PROJECT="/Users/alcatraz627/Code/Claude/i-dream"
CHECKPOINT="_checkpoint.claude.md"

osascript -e 'display notification "Catching up on the improvement sweep…" with title "Resume i-dream" sound name "Glass"' 2>/dev/null || true
cd "$PROJECT" || exit 1

PROMPT="Resume the i-dream improvement sweep (session 79c1d286, closed 2026-07-08). This is a large UI/design/architecture overhaul of the i-dream menubar widget + native dashboard; most stages shipped, but these workspace todos are still OPEN: #34 top-bar widget review vs claude-instances/sys-monitor; #36 Stage 4 menu diet per that review; #37 D1 design tokens (type scale, spacing rhythm, chroma tiers, affordances); #38 D2 sidebar rebuild (item styling + structured metadata footer); #43 D7 cluster graph (explore options via the dataviz skill, rebuild properly). First run /catchup to restore full context from ${CHECKPOINT}, then give me a short done/remaining summary and ask which of the five open items to start."

"$HOME/.claude/scripts/ghostty/ghostty-open" --cwd "$PROJECT" -- "claude $(printf %q "$PROMPT")" \
  || echo "Start Claude here and paste: $PROMPT"
