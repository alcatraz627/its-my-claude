#!/usr/bin/env bash
# heed-writeback.sh — close the loop on an advisory nudge whose heed lands in a
# channel the nudging hook never looks at again.
#
# THE PROBLEM. 34 of 38 hooks measure nothing about whether they worked. The four
# that do (prose-smell, filename-dot, prefer-tmp-py, review-gate) all share one
# mechanism: the hook fires, and a LATER fire of the SAME hook can see the
# artifact again and judge it. That only works when the evidence arrives back
# through the same door. A nudge to create tasks is answered by TaskCreate; a
# persona suggestion is answered by a persona adoption; a "use rg" warning is
# answered by a different command next turn. None of those come back through the
# hook, so the hook is blind by construction rather than by neglect, and a hook
# that fires once per session has no second fire to judge from anyway.
#
# THE MECHANISM. Split observation from firing. At fire time a hook calls
#   heed-writeback.sh arm <hook-id> <check> [arg]
# which drops a marker recording what to look for. At every Stop this same script
# runs in resolve mode, re-reads the world, and writes a kind:heed line through
# warn-log.sh when the answer is knowable. The hook stays a one-shot; the
# observation becomes a loop.
#
# READ THIS BEFORE USING THE NUMBERS. A quiet hook is not a dead hook. Silence
# has at least three causes and they are not distinguishable from fire-rate
# alone: nobody needed the nudge, the nudge worked so well it stopped being
# needed (internalization), or something else absorbed the job. no-task-nudge sat
# silent for six days while the harness's own todo reminder covered the same
# ground, which reads identically to decay in a chart. So heeded:false is
# evidence about ONE fire, never about the hook's worth, and no retirement
# verdict may rest on fire-rate alone. Pair it with a periodic check of whether
# the behaviour is present anyway, and retire only when the behaviour holds
# WITHOUT the hook.
#
# Checks are enumerated here rather than pluggable, because there is exactly one
# real caller today. Add a branch when a second hook needs one; do not build a
# registry for a caller that does not exist.
#
#   persona-adopted <persona>        heeded when an adoption of that persona is
#                                    appended to personas/usage/events.jsonl after
#                                    the fire. Answers persona-suggest, which had
#                                    1381 fires and zero heed lines: it suggests in
#                                    the hook channel and is answered in a ledger
#                                    it never reads. Compares against a LINE COUNT
#                                    taken at arm time rather than timestamps,
#                                    because the usage log's sid is null on these
#                                    rows and its ts would need parsing to order.
#
#   task-store-nonempty <sid>        heeded when the session's task store gains
#                                    any task after the fire. Answers no-task-nudge.
#                                    Takes the SESSION ID, not a directory, and
#                                    resolves the store at check time. It cannot
#                                    take a path: at fire time the store does not
#                                    exist yet (an empty task list is the whole
#                                    reason the nudge fired), so a path captured
#                                    then is the legacy fallback shape and stays
#                                    frozen there while the real store appears
#                                    beside it under session-<sid8>. Every fire
#                                    would then read an empty directory forever
#                                    and score a miss the user did not earn.
#
# Mute: touch ~/.claude/.no-heed-writeback (machine-wide until removed).

set -uo pipefail
[ -f "$HOME/.claude/.no-heed-writeback" ] && exit 0

WARN_LOG="$HOME/.claude/scripts/hooks/warn-log.sh"
MARK_PREFIX="${TMPDIR:-/tmp}/claude-heed-"

# How many Stops a marker may stay unresolved before it is called unheeded. The
# window exists because "no tasks yet" at the first Stop is not the same as "they
# never made any" — the user may still be reading the nudge.
MAX_STOPS="${HEED_MAX_STOPS:-3}"

# ── arm ─────────────────────────────────────────────────────────────────────
# arm <hook-id> <check> [arg] [sid]
arm() {
  local hook="${1:-}" check="${2:-}" arg="${3:-}" sid="${4:-${CLAUDE_SESSION_ID:-}}"
  [ -n "$hook" ] && [ -n "$check" ] || return 0
  [ -n "$sid" ] || sid="nosid"
  local m="${MARK_PREFIX}${hook}-${sid:0:8}"
  [ -f "$m" ] && return 0                       # already armed this session
  # Some checks need a "before" reading, because they ask whether something was
  # APPENDED rather than whether it exists. Take it now, while now is still now.
  local baseline=0
  if [ "$check" = persona-adopted ]; then
    baseline=$(wc -l < "$HOME/.claude/personas/usage/events.jsonl" 2>/dev/null | tr -d ' ')
    baseline=${baseline:-0}
  fi
  {
    printf 'hook=%s\n' "$hook"
    printf 'sid=%s\n'  "$sid"
    printf 'check=%s\n' "$check"
    printf 'arg=%s\n'  "$arg"
    printf 'baseline=%s\n' "$baseline"
    printf 'stops=0\n'
  } > "$m" 2>/dev/null || true
}

# ── checks ──────────────────────────────────────────────────────────────────
# Each prints yes | no | unknown. "unknown" means the world cannot answer yet and
# is NOT the same as no; it leaves the marker pending rather than scoring a miss.
check_task_store_nonempty() {
  local sid="${1:-}" dir
  [ -n "$sid" ] || { echo unknown; return; }
  # Current store shape first, then the handful of pre-2026-07 bare-id dirs.
  dir="$HOME/.claude/tasks/session-${sid:0:8}"
  [ -d "$dir" ] || dir="$HOME/.claude/tasks/$sid"
  if [ -f "$dir/.highwatermark" ]; then
    local hw; hw=$(tr -dc '0-9' < "$dir/.highwatermark" 2>/dev/null)
    [ "${hw:-0}" -gt 0 ] 2>/dev/null && { echo yes; return; }
  fi
  if [ -d "$dir" ] && ls "$dir"/*.json >/dev/null 2>&1; then echo yes; return; fi
  # The directory legitimately may not exist yet; that is "not yet", not "never".
  echo no
}

# check_persona_adopted <persona> <baseline-line-count>
# Only lines appended AFTER the fire count. Reading the whole file would score a
# heed for a persona adopted last week, which is the shape that makes a metric
# look healthy while measuring nothing.
check_persona_adopted() {
  local persona="${1:-}" base="${2:-0}" log="$HOME/.claude/personas/usage/events.jsonl"
  [ -n "$persona" ] || { echo unknown; return; }
  [ -f "$log" ] || { echo unknown; return; }
  local now; now=$(wc -l < "$log" 2>/dev/null | tr -d ' '); now=${now:-0}
  # The log shrank (rotated or truncated); the baseline is meaningless now.
  [ "$now" -lt "$base" ] 2>/dev/null && { echo unknown; return; }
  [ "$now" -eq "$base" ] 2>/dev/null && { echo no; return; }
  if tail -n "+$((base + 1))" "$log" 2>/dev/null \
     | rg -qF "\"persona\":\"${persona}\"" 2>/dev/null; then echo yes; else echo no; fi
}

run_check() {
  case "${1:-}" in
    task-store-nonempty) check_task_store_nonempty "${2:-}" ;;
    persona-adopted)     check_persona_adopted "${2:-}" "${3:-0}" ;;
    *)                   echo unknown ;;
  esac
}

# ── resolve ─────────────────────────────────────────────────────────────────
resolve() {
  local m hook sid check arg stops baseline verdict
  for m in "${MARK_PREFIX}"*; do
    [ -f "$m" ] || continue
    hook=""; sid=""; check=""; arg=""; stops=0; baseline=0
    # shellcheck disable=SC1090
    while IFS='=' read -r k v; do
      case "$k" in
        hook) hook="$v" ;; sid) sid="$v" ;; check) check="$v" ;;
        arg)  arg="$v"  ;; stops) stops="$v" ;; baseline) baseline="$v" ;;
      esac
    done < "$m"
    [ -n "$hook" ] && [ -n "$check" ] || { rm -f "$m" 2>/dev/null; continue; }

    verdict=$(run_check "$check" "$arg" "$baseline")
    stops=$(( ${stops:-0} + 1 ))

    if [ "$verdict" = yes ]; then
      bash "$WARN_LOG" --hook "$hook" --heed-of "${hook}:${sid:0:8}" --heeded true \
        >/dev/null 2>&1 || true
      rm -f "$m" 2>/dev/null || true
    elif [ "$verdict" = no ] && [ "$stops" -ge "$MAX_STOPS" ]; then
      # Grace window spent. Records ONE unheeded fire, which per the header note
      # is not a verdict on the hook.
      bash "$WARN_LOG" --hook "$hook" --heed-of "${hook}:${sid:0:8}" --heeded false \
        >/dev/null 2>&1 || true
      rm -f "$m" 2>/dev/null || true
    else
      sed -i '' "s/^stops=.*/stops=${stops}/" "$m" 2>/dev/null \
        || printf 'stops=%s\n' "$stops" >> "$m" 2>/dev/null || true
    fi
  done
}

case "${1:-resolve}" in
  arm)     shift; arm "$@" ;;
  resolve) cat >/dev/null 2>&1 || true    # drain Stop's stdin, we do not need it
           resolve ;;
  *)       exit 0 ;;
esac
exit 0
