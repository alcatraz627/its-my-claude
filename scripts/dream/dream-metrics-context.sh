#!/bin/bash
# dream-metrics-context.sh — SessionStart hook that injects a compact summary
# of dream-extracted session metrics into Claude's context.
#
# Output: JSON {"additionalContext": "..."} to stdout if metrics exist, else silent exit.
# Reads: ~/.claude/subconscious/dreams/dream-metrics.json

METRICS_FILE="$HOME/.claude/subconscious/dreams/dream-metrics.json"

[ -f "$METRICS_FILE" ] || exit 0

python3 - "$METRICS_FILE" <<'PYEOF'
import sys, json

metrics_file = sys.argv[1]
try:
    with open(metrics_file, 'r') as f:
        m = json.load(f)
except (OSError, json.JSONDecodeError):
    sys.exit(0)

# Build compact context — just the actionable parts, not raw data
lines = ["## Session Analytics (Dream-Extracted)"]

# Quality summary
sq = m.get('session_quality', {})
lines.append(f"_Avg session quality: {sq.get('average_score', '?')}/100 across {m.get('sessions_analyzed', '?')} sessions._")

# Error summary
et = m.get('error_taxonomy', {})
if et.get('total_errors', 0) > 0:
    top_errors = ', '.join(f"{t}({n})" for t, n in list(et.get('by_tool', {}).items())[:3])
    lines.append(f"_Errors: {et['total_errors']} total (rate {et.get('error_rate_overall', 0):.1%}). Top: {top_errors}._")

# Topic drift
td = m.get('topic_drift', {})
lines.append(f"_Focus: {td.get('primary_focus', '?')}. Drift rate: {td.get('drift_rate', 0):.0%} ({td.get('total_switches', 0)} project switches)._")

# Collaboration style
cs = m.get('collaboration_style', {})
lines.append(f"_Style: {cs.get('style_label', '?')} (corrections {cs.get('correction_rate', 0):.0%}, confirmations {cs.get('confirmation_rate', 0):.0%}, terse {cs.get('terse_rate', 0):.0%})._")

print(json.dumps({"additionalContext": "\n".join(lines)}))
PYEOF
