#!/usr/bin/env bash
# lifecycle: tune-able hook (dry-run build, owner words 2026-10-19: "I need this, and I see it not being followed")
# instrument: self (warn-log.sh --hook plan-gate; block-dry rows count would-be denials)
# review-by: 2026-11-19
# retire-if: a week of block-dry rows shows more than half were sessions the owner did not want gated
# plan-gate-pre.sh: PreToolUse on Write, Edit and MultiEdit. Notes when a session
# is about to touch its third code file with no plan on record.
#
# DRY RUN. It never denies. On the edit that would make the third distinct code
# file of the session, with no plan signal, it records a block-dry row through
# warn-log.sh and shows a visible advisory (systemMessage, plus the same text as
# additionalContext so the agent reads it). After a week of rows the plan is to
# promote it to a deny-once.
#
# Exempt, in order: sessions that are headless, sidechain or resumed, or whose
# owner prompt is an enumerated list (plan-signals.py); a sub-agent call (agent_id
# in the payload); paths that are not code (docs, reports, notes, scratchpad and
# tmp files, tests, generated and vendored dirs); any session that shows a plan
# signal (Task list, planning skill, plan file, plan text). It speaks once per
# session.
#
# Mute:          touch ~/.claude/.no-plan-gate (machine-wide, shared with plan-gate-ups.sh)
# One-shot skip: PLAN_GATE_OFF=1
# Telemetry:     warn-log.sh --hook plan-gate --action block-dry

set -uo pipefail
[ "${PLAN_GATE_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-plan-gate" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
case "$tool" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
agent=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$fp" ] || exit 0
[ -z "$agent" ] || exit 0
sid8="${sid:0:8}"

HERE="$(cd "$(dirname "$0")" && pwd)"
SIGNALS="${PLAN_SIGNALS_PY:-$HERE/plan-signals.py}"
LOG="$HERE/warn-log.sh"
SAID="/tmp/claude-plan-gate-${sid8}"
EDITED="/tmp/claude-edited-files-${sid8}"
[ -f "$SAID" ] && exit 0

# What counts as a code file: the same extensions review-marker.sh uses, minus
# docs, reports, notes, scratch and tmp locations, tests, and generated dirs.
CODE_RE='\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|sh|bash|rb|java|kt|swift|c|cc|cpp|h|hpp|sql)$'
EXCL_RE='/(node_modules|dist|build|coverage|vendor|__pycache__|\.next|\.venv|\.git|release[^/]*|reports|output|session-notes|assets|docs|notes|scratchpad|tmp|fixtures|generated|[A-Za-z0-9_-]*-review)/'
TEST_RE='(\.test\.|\.spec\.|_test\.|/tests?/|/__tests__/|/test_[^/]*$|(^|/)tests\.sh$)'
is_code() {
  local f="$1"
  [[ "$f" =~ $CODE_RE ]] || return 1
  case "$f" in /tmp/*|/private/tmp/*|/var/folders/*) return 1 ;; esac
  [[ "$f" =~ $EXCL_RE ]] && return 1
  [[ "$f" =~ $TEST_RE ]] && return 1
  return 0
}
is_code "$fp" || exit 0

# Distinct code files this session already edited, not counting this one.
prior=0
if [ -f "$EDITED" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && [ "$f" != "$fp" ] && is_code "$f" && prior=$((prior + 1))
  done < <(sort -u "$EDITED" 2>/dev/null)
fi
[ "$prior" -eq 2 ] || exit 0

command -v python3 >/dev/null 2>&1 && [ -f "$SIGNALS" ] || exit 0
verdict=$(python3 -I "$SIGNALS" "$tp" "$sid" 2>/dev/null) || exit 0
[ "$(printf '%s' "$verdict" | jq -r '.plan or .exempt' 2>/dev/null)" = "false" ] || exit 0

: > "$SAID" 2>/dev/null || true
bash "$LOG" --hook plan-gate --action block-dry --heeded unknown --cwd "$cwd" --target "$fp" --detail "third code file, no plan signal" >/dev/null 2>&1 || true
msg="[plan-gate dry-run] This edit is the third code file this session and there is no plan on record (no Task list, planning skill or plan text). A live gate would pause here. Post a short plan and TaskCreate its steps now. Mute: touch ~/.claude/.no-plan-gate"
jq -cn --arg m "$msg" '{systemMessage:$m, hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$m}}' 2>/dev/null || true
exit 0
