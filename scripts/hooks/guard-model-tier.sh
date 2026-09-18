#!/usr/bin/env bash
# guard-model-tier.sh — PreToolUse hook on Agent/Task: the model-tier routing gate.
#
# Three jobs, in order (rules/model-tier-routing.md · features/model-tier-harness.md):
#   1. TELEMETRY (always, even when muted): every sub-agent dispatch appends
#      {ts, session_id, tool, model, prompt_head} to ~/.claude/logs/model-dispatch.jsonl
#      — the efficacy-review data feed (tier-telemetry-review, Aug-04).
#   2. HARD BLOCK (no self-mute): model = fable/mythos-class, unless the owner's
#      sentinel exists. The original reason was pricing (per-token outside the
#      subscription cap, user decision 2026-07-07). Anthropic brought fable inside
#      the subscription on 2026-08-25, so what the block now enforces is that the
#      lane gets chosen deliberately, not that it costs extra.
#   3. WARN (muteable): dispatch carries no model pin — an unpinned spawn can inherit
#      the session flagship (rules/model-tier-routing.md § sub-agent ceiling).
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

# 1 — telemetry, unconditional (mutes silence nudges, never data). Appends are
# flock-serialized (best-effort, same pattern as ledger_append) — concurrent
# sessions dispatch agents simultaneously and share this stream.
mkdir -p "$HOME/.claude/logs"
DISPATCH_LOG="$HOME/.claude/logs/model-dispatch.jsonl"
TLINE=$(echo "$INPUT" | jq -c '{ts: (now | todate), session_id: (.session_id // "unknown"),
  tool: .tool_name, model: (.tool_input.model // null),
  prompt_head: ((.tool_input.prompt // .tool_input.description // "") | .[0:160])}' 2>/dev/null)
[ -n "$TLINE" ] && ( flock -x 9 2>/dev/null || true; printf '%s\n' "$TLINE" >> "$DISPATCH_LOG" ) 9>>"$DISPATCH_LOG.lock" 2>/dev/null || true

# 2 — the hard block. No agent self-mute, no env override: the human lifts it
# by holding the consent sentinel below, and re-arms it by trashing the file.
# LIFTED since 2026-07-23 (owner instruction: "lift the fable hard-block
# altogether"). Telemetry above logs every dispatch either way, so flagship
# sub-agent spend stays reviewable (tier-telemetry-review).
# Fable is ENABLED by default (owner 2026-09-18: the scarcity that justified the
# block is gone). The block applies only while an explicit, expiring opt-out row
# exists: hook-snooze.sh add fable-restrict --for 7d --scope global --reason … --approved-by owner
if printf '%s' "$MODEL" | grep -qiE 'fable|mythos'; then
  if bash "$HOME/.claude/scripts/hooks/hook-snooze.sh" check fable-restrict-subagents >/dev/null 2>&1; then
    reason="⛔ FLAGSHIP-AS-SUB-AGENT BLOCKED: '$MODEL' is the flagship lane and the owner has an active fable-restrict row (hook-snooze.sh list shows who, until when and why). Re-dispatch on sonnet (default) or opus (judgment seats), or ask the owner to lift the row."
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook model-tier --action block --heeded unknown >/dev/null 2>&1 || true
    jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
    exit 0
  fi
fi

# 2a — usage-window advisory for a fable seat (owner D5 note, 2026-09-18). Never a
# block: policy.sh says WARN above 80% and STRONG above 90% of the general week,
# and the line asks the agent to weigh value, not to skip. Snoozable as
# model-tier-fable (group: fable).
if printf '%s' "$MODEL" | grep -qiE 'fable|mythos'; then
  . "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null
  if ! hook_snoozed model-tier-fable >/dev/null 2>&1; then
    pol=$(bash "$HOME/.claude/scripts/policy.sh" fable 2>/dev/null); prc=$?
    if [ "$prc" -eq 1 ] || [ "$prc" -eq 2 ]; then
      jq -cn --arg c "[model-tier · fable · ${pol%%	*}] ${pol#*	}. Advisory: the seat still runs; say what it buys in the Model Plan, or pick opus." '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}'
      bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook model-tier-fable --action nudge --heeded unknown --detail "${pol%%	*}" >/dev/null 2>&1 || true
    fi
  fi
fi

# 2b — a fable lane may not delegate its OWN work away (hard block, no self-mute).
#
# Owner ruling 2026-09-01. A fable session is the brains lane: it exists to do the
# involved thinking, and authoring docs IS the involved thinking. Measured over 30
# days, 129 docs-shaped dispatches went out and 100 of them landed on sonnet, one
# of which literally read "Adopt the dispatch persona at personas/doc-writer.md".
# Rules alone never bound this because nothing read them.
#
# The asymmetry is deliberate and runs one way only:
#   fable  -> sub-agent for AUTHORING  = blocked, fable does it itself
#   fable  -> sub-agent for review / verification / a cheap pass = fine
#   opus/sonnet -> fable sub-agent for docs = fine, gated by 2 above, not here
#
# Dispatcher model comes from the transcript, because the payload carries only the
# SUB-agent's pin. The last assistant entry's message.model is this session's own.
#
# Owner-lifted 2026-09-11 for a /magi run whose voter seats are authoring by
# construction: the sentinel below is the owner's, created on their word, and
# trashing it re-arms the block. An agent never creates it on its own.
TP=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
# Delegation from a fable lane is ALLOWED by default (owner 2026-09-18); the
# block binds only while an explicit fable-restrict row is live.
bash "$HOME/.claude/scripts/hooks/hook-snooze.sh" check fable-restrict-delegation >/dev/null 2>&1 || TP=""
if [ -n "$TP" ] && [ -f "$TP" ]; then
  PARENT=$(tail -n 400 "$TP" 2>/dev/null | jq -rc 'select(.type=="assistant") | .message.model // empty' 2>/dev/null | tail -n 1)
  case "$PARENT" in
    *fable*|*mythos*)
      PH=$(echo "$INPUT" | jq -r '.tool_input.prompt // empty' 2>/dev/null)
      # Allowed first: a seat that reads, checks or judges is exactly what a brains
      # lane SHOULD delegate. Checked before the authoring list because a review
      # brief legitimately says "the docs you wrote".
      if printf '%s' "$PH" | rg -qiP '\b(review|adversarial|verify|verification|validate|check|audit|critique|judge|proofread|lint|test|reproduce|fact.?check|second seat|read.only|sanity)\b' 2>/dev/null; then
        :
      elif printf '%s' "$PH" | rg -qiP '\b(write|author|draft|compose|rewrite|document|documentation|docs|readme|guide|handbook|spec|plan|design|implement|build|refactor|migrate)\b' 2>/dev/null; then
        reason="⛔ FABLE MAY NOT DELEGATE ITS OWN WORK. This session is running on '$PARENT', the brains lane, and this dispatch hands authoring work to a sub-agent. Authoring IS the work the lane exists for: do it yourself. Delegating review, verification, a cheap pass or a fact-check is fine and encouraged; delegating writing, planning, designing or implementing is not. Owner ruling 2026-09-01, after 100 of 129 docs-shaped dispatches in 30 days landed on sonnet. An opus or sonnet session may still dispatch fable for docs; this gate binds the fable lane only. No mute: the owner asked for a hard block."
        bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook model-tier --action block-fable-delegation --heeded unknown >/dev/null 2>&1 || true
        jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
        exit 0
      fi
      ;;
  esac
fi

# 3 — the missing-pin warn was retired by owner ruling D6a (2026-09-18): it sat
# muted for 37 days because the need had passed and models kept tripping on it.
# The two hard blocks above are rulings and stay. Usage-window advisories for
# fable live in the policy layer (see features/usage-policy.md), not here.
exit 0
