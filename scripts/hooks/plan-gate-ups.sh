#!/usr/bin/env bash
# lifecycle: tune-able hook (dry-run build, owner words 2026-10-19: "I need this, and I see it not being followed")
# instrument: fire count in warn-log.sh (--hook plan-gate-ups); heed is read by comparing against sessions that got no hint
# review-by: 2026-11-19
# retire-if: sessions that got the hint plan no more often than sessions that did not, over 40 fires
# plan-gate-ups.sh: a UserPromptSubmit hint that asks for a short plan before a
# build starts, so the plan lands before the agent has picked a path.
#
# When the first build-shaped prompt of a session arrives and the session has no
# plan yet, one line of additionalContext asks for a two-line plan and a Task
# list before the first edit. It speaks once per session. Prompts that are not
# builds, sessions that already hold a plan signal, and the exempt kinds of
# session (headless, sidechain, resumed, an owner prompt that is an enumerated
# list) get no output at all. plan-signals.py decides all of that.
#
# This hook only ever adds context. It cannot block a prompt.
# Mute:          touch ~/.claude/.no-plan-gate (machine-wide, shared with plan-gate-pre.sh)
# One-shot skip: PLAN_GATE_OFF=1
# Telemetry:     warn-log.sh --hook plan-gate-ups --action nudge

set -uo pipefail
[ "${PLAN_GATE_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-plan-gate" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$prompt" ] || exit 0
sid8="${sid:0:8}"

HERE="$(cd "$(dirname "$0")" && pwd)"
SIGNALS="${PLAN_SIGNALS_PY:-$HERE/plan-signals.py}"
LOG="$HERE/warn-log.sh"
HINTED="/tmp/claude-plan-hint-${sid8}"

[ -f "$HINTED" ] && exit 0
# A slash command or a very short message is not a build request.
case "$prompt" in /*|"<"*) exit 0 ;; esac
[ "${#prompt}" -ge 25 ] || exit 0

lc=$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')
verb='(^|[^a-z])(build|implement|add|rewrite|refactor|port|migrate|fix)([^a-z]|$)'
noun='(^|[^a-z])(features?|files?|modules?|pages?|endpoints?|scripts?|hooks?|components?|pipelines?|commands?|tools?|systems?|flows?|integrations?|apis?|app|ui|cli|mods?|dashboards?|screens?|views?|routes?|services?)([^a-z]|$)'
[[ "$lc" =~ $verb ]] && [[ "$lc" =~ $noun ]] || exit 0

command -v python3 >/dev/null 2>&1 && [ -f "$SIGNALS" ] || exit 0
verdict=$(python3 -I "$SIGNALS" "$tp" "$sid" 2>/dev/null) || exit 0
[ "$(printf '%s' "$verdict" | jq -r '.plan or .exempt' 2>/dev/null)" = "false" ] || exit 0

# The prompt itself may be the enumerated plan; the transcript may not hold it yet.
if [ "$(printf '%s\n' "$prompt" | rg -c '^\s*(\d+[.)]|[-*•])\s+\S' 2>/dev/null || echo 0)" -ge 3 ]; then exit 0; fi

: > "$HINTED" 2>/dev/null || true
bash "$LOG" --hook plan-gate-ups --action nudge --heeded unknown --detail "build prompt, no plan signal" >/dev/null 2>&1 || true
msg="This reads as a build. Post a two-line plan and TaskCreate its steps before the first edit, so the steps stay verifiable and the Task list shows what is in progress."
jq -cn --arg m "$msg" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$m}}' 2>/dev/null || true
exit 0
