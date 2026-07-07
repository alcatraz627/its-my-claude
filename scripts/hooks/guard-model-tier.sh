#!/usr/bin/env bash
# guard-model-tier.sh — PreToolUse hook on Agent/Task: the model-tier routing gate.
#
# Three jobs, in order (rules/model-tier-routing.md · features/model-tier-harness.md):
#   1. TELEMETRY (always, even when muted): every sub-agent dispatch appends
#      {ts, session_id, tool, model, prompt_head} to ~/.claude/logs/model-dispatch.jsonl
#      — the efficacy-review data feed (tier-telemetry-review, Aug-04).
#   2. HARD BLOCK (no self-mute): model = fable/mythos-class. That tier is priced
#      per-token OUTSIDE the subscription cap; a sub-agent on it multiplies uncapped
#      spend (user decision 2026-07-07 — the block keys on pricing, not flagship-ness).
#   3. WARN (muteable): dispatch carries no model pin — an unpinned spawn can inherit
#      the session flagship (rules/subagent-model-ceiling.md).
#
# Mute (warn path only): touch ~/.claude/.model-tier-off   One-shot: MODEL_TIER_OFF=1

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
echo "$INPUT" | jq empty 2>/dev/null || exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in Agent | Task) ;; *) exit 0 ;; esac

MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // empty')
SID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# 1 — telemetry, unconditional (mutes silence nudges, never data).
mkdir -p "$HOME/.claude/logs"
echo "$INPUT" | jq -c '{ts: (now | todate), session_id: (.session_id // "unknown"),
  tool: .tool_name, model: (.tool_input.model // null),
  prompt_head: ((.tool_input.prompt // .tool_input.description // "") | .[0:160])}' \
  >> "$HOME/.claude/logs/model-dispatch.jsonl" 2>/dev/null || true

# 2 — the hard block. No mute file, no env override: only the human lifts this,
# by changing the rule (same posture as guard-anthropic-credentials.sh).
if printf '%s' "$MODEL" | grep -qiE 'fable|mythos'; then
  reason="⛔ FLAGSHIP-AS-SUB-AGENT BLOCKED — '$MODEL' is priced per-token OUTSIDE the subscription cap; a sub-agent on it multiplies uncapped spend for no quality gain (rules/model-tier-routing.md + rules/subagent-model-ceiling.md; user decision 2026-07-07). Re-dispatch on sonnet (default) or opus (judgment seats). The flagship is for the supervising main loop only. This block has no self-mute."
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook model-tier --action block --heeded unknown >/dev/null 2>&1 || true
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
fi

# 3 — the missing-pin warn (muteable).
[ "${MODEL_TIER_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.model-tier-off" ] && exit 0

if [ -z "$MODEL" ]; then
  msg="[model-tier] This dispatch has NO model pin — an unpinned spawn can inherit the session flagship (uncapped per-token cost). Pin it: sonnet = default (research/inventory/mechanical, effort liberal), opus = judgment seats (medium), haiku = trivial. Also consider the free lanes: lm fleet for judged batch work, lm gemini for large-context ingestion (rules/model-tier-routing.md). (mute: touch ~/.claude/.model-tier-off)  →→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."
  jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}'
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook model-tier --action nudge --heeded unknown >/dev/null 2>&1 || true
fi
exit 0
