#!/usr/bin/env bash
# nudge-model-plan.sh — PreToolUse hook on ExitPlanMode: the plan-time half of
# model-tier routing (rules/model-tier-routing.md § The Model Plan).
#
# A plan that dispatches sub-agents, ingests a large corpus, or uses a modality
# tool must carry a "Model plan:" block (one line per stage: lane · model ·
# effort · why). This nudge fires when the plan text shows those signals but no
# block — advisory only (additionalContext), never a block: a missed nudge
# costs one noise line, a missed Model Plan costs an unrouted fleet
# (features/hook-design.md — consequence matched to cost-of-false-fire).
#
# Telemetry via warn-log.sh (hook: model-plan). Shares the model-tier mutes:
# touch ~/.claude/.model-tier-off   One-shot: MODEL_TIER_OFF=1

set -uo pipefail

[ "${MODEL_TIER_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.model-tier-off" ] && exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
echo "$INPUT" | jq empty 2>/dev/null || exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL" = "ExitPlanMode" ] || exit 0

PLAN=$(echo "$INPUT" | jq -r '.tool_input.plan // empty')
# The binary injects `plan` into tool_input from a plan FILE on disk
# (normalizeToolInput); whether that runs before PreToolUse is unproven, and the
# model-facing schema carries only planFilePath. Fall back to reading the file so
# the hook is correct under either ordering (review finding, 2026-07-10).
if [ -z "$PLAN" ]; then
  PLAN_FILE=$(echo "$INPUT" | jq -r '.tool_input.planFilePath // empty')
  [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ] && PLAN=$(cat "$PLAN_FILE" 2>/dev/null)
fi
[ -n "$PLAN" ] || exit 0

# Already routed — any "Model plan:" block satisfies the obligation.
if printf '%s' "$PLAN" | grep -qiE 'model[- ]plan\s*:'; then
  exit 0
fi

# Signals that the plan qualifies (sub-agents / workflows / large ingestion /
# modality tools). Word-bounded to keep false fires cheap-and-rare; this is a
# nudge, so a borderline miss is acceptable and a borderline fire is one line.
if printf '%s' "$PLAN" | grep -qiE '\b(sub-?agents?|workflows?|fan[- ]?out|agent fleet|parallel agents|dispatch(ing)? agents?|lm fleet|lm gemini|gemini session|ingest (the )?(corpus|codebase|logs)|imagegen|imagine\b)'; then
  msg="[model-plan] This plan involves sub-agents / workflows / ingestion but has no 'Model plan:' block. Add one line per stage — lane · model · effort · why (rules/model-tier-routing.md § The Model Plan). Even when the instinct doesn't change, the explicit thought is the point. (mute: touch ~/.claude/.model-tier-off)  →→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."
  jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}'
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook model-plan --action nudge --heeded unknown >/dev/null 2>&1 || true
fi
exit 0
