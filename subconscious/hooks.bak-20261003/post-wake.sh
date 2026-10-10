#!/usr/bin/env bash
# post-wake.sh — hook called after each i-dream Wake consolidation phase.
#
# This script is intended to run after the daemon logs "Wake: promoted N insights"
# (see src/modules/dreaming.rs, Wake phase completion).
#
# Integration options:
#   A. Manual invocation: bash ~/.claude/subconscious/hooks/post-wake.sh
#   B. Cron (runs every 2h, aligns with typical Wake cycle):
#        0 */2 * * * bash ~/.claude/subconscious/hooks/post-wake.sh
#   C. From Rust daemon: spawn this script after the Wake phase returns.
#      In dreaming.rs, after `tracing::info!("Wake: promoted {} insights", n)`:
#        std::process::Command::new("bash")
#            .arg(format!("{}/.claude/subconscious/hooks/post-wake.sh",
#                         std::env::var("HOME").unwrap_or_default()))
#            .spawn().ok();
#
# This script is idempotent (safe to run any number of times).

set -euo pipefail

INJECT_SCRIPT="${HOME}/.claude/scripts/inject-dream-insights.sh"

if [[ ! -f "$INJECT_SCRIPT" ]]; then
    echo "post-wake: inject script not found at $INJECT_SCRIPT" >&2
    exit 1
fi

bash "$INJECT_SCRIPT"

# Stage high-confidence dream-learned rules as config proposals for user review
PROPOSE_SCRIPT="${HOME}/.claude/scripts/propose-config-from-insights.sh"
if [[ -f "$PROPOSE_SCRIPT" ]]; then
    bash "$PROPOSE_SCRIPT"
fi

# Extract actionable session metrics from event log
METRICS_SCRIPT="${HOME}/.claude/scripts/dream-metrics.sh"
if [[ -f "$METRICS_SCRIPT" ]]; then
    bash "$METRICS_SCRIPT"
fi
