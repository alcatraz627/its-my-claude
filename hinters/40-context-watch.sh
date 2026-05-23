#!/usr/bin/env bash
# 40-context-watch.sh — UserPromptSubmit hinter.
#
# Estimates current context usage from the transcript file size and emits a
# graduated nudge at 70/80/90%. Pairs with CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=92
# so the urgent (90%) nudge fires BEFORE auto-compaction.
#
# Why this is a heuristic, not a measurement:
#   Claude Code does not expose live token-usage to hooks. The transcript
#   JSONL file size correlates with conversation tokens — enough for a
#   threshold-crossing alarm, not enough for precision. Tune CTX_CAP_BYTES
#   if the alarms fire too early/late in YOUR sessions.
#
# Mute: touch ~/.claude/.context-watch-off
# Throttle: state file at /tmp/claude-ctxwatch-<session-id> tracks
#           highest-threshold fired-this-session (so 70% fires once, not
#           on every prompt while sitting at 71-79%).
# Tune:    ~/.claude/.context-watch.conf — KEY=VALUE pairs override defaults.

set -uo pipefail

[[ -f "$HOME/.claude/.context-watch-off" ]] && exit 0

# Source optional config overrides.
CONF="$HOME/.claude/.context-watch.conf"
# Defaults — bytes corresponding to ~200K-token context window.
# Claude 4 context = 200K tokens; transcript ≈ 5 bytes/token average.
CTX_CAP_BYTES=1000000   # 1 MB ≈ 200K tokens (rough)
THRESH_GENTLE=70
THRESH_MEDIUM=80
THRESH_URGENT=90
# shellcheck disable=SC1090
[[ -f "$CONF" ]] && source "$CONF"

INPUT=$(cat)
[[ -z "$INPUT" ]] && exit 0

# Stdin schema for UserPromptSubmit hooks includes transcript_path + session_id.
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
SID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

[[ -n "$SID" ]] || exit 0

# Get transcript size; fall back to turn count if unavailable.
PCT=0
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
  bytes=$(stat -f %z "$TRANSCRIPT" 2>/dev/null || stat -c %s "$TRANSCRIPT" 2>/dev/null || echo 0)
  PCT=$(( bytes * 100 / CTX_CAP_BYTES ))
else
  # Turn-count fallback. Calibration: ~150 turns ≈ 70%, ~200 turns ≈ 90%.
  sid_short="${SID:0:8}"
  turns_file="/tmp/claude-turns-${sid_short}"
  if [[ -f "$turns_file" ]]; then
    turns=$(cat "$turns_file" 2>/dev/null | tr -d '[:space:]')
    [[ -z "$turns" ]] && turns=0
    # 150 turns = 70%, 200 turns = 90% → 1% per 2.5 turns above turn 0
    PCT=$(( turns * 100 / 215 ))
  fi
fi

(( PCT < THRESH_GENTLE )) && exit 0

# Throttle: don't re-fire the same tier within a session.
STATE="/tmp/claude-ctxwatch-${SID:0:8}"
LAST_FIRED=0
[[ -f "$STATE" ]] && LAST_FIRED=$(cat "$STATE" 2>/dev/null | tr -d '[:space:]')
LAST_FIRED=${LAST_FIRED:-0}

emit_nudge() {
  local tier="$1" pct="$2"
  case "$tier" in
    gentle)
      cat <<EOF
[CTX-HINT] Context at ~${pct}% — if you haven't /core-dump'd in the last
30 minutes, consider \`/core-dump mini\` now. (Auto-compact at
${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-92}%.)
EOF
      ;;
    medium)
      cat <<EOF
[CTX-WARN] Context at ~${pct}% — \`/core-dump\` (or at minimum
\`/core-dump mini\`) is strongly suggested before the next compaction.
Synthesis takes a few turns; budget accordingly.
EOF
      ;;
    urgent)
      cat <<EOF
[CTX-CRIT] Context at ~${pct}% — auto-compaction is imminent. RUN
\`/core-dump mini\` NOW (full mode may not fit in the remaining budget).
After compaction, /catchup will restore from the index.
EOF
      ;;
  esac
}

# Determine current tier; only emit if it's STRICTLY HIGHER than last.
TIER_NUM=0
TIER_NAME=""
if   (( PCT >= THRESH_URGENT )); then TIER_NUM=3; TIER_NAME="urgent"
elif (( PCT >= THRESH_MEDIUM )); then TIER_NUM=2; TIER_NAME="medium"
elif (( PCT >= THRESH_GENTLE )); then TIER_NUM=1; TIER_NAME="gentle"
fi

if (( TIER_NUM > LAST_FIRED )); then
  emit_nudge "$TIER_NAME" "$PCT"
  echo "$TIER_NUM" > "$STATE"
fi

exit 0
