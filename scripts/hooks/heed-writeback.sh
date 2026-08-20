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
# NOT INSTRUMENTED, AND WHY. The five loudest advisory hooks still record nothing.
# Each was examined 2026-08-18 and left alone deliberately, because the cheap check
# available for it would report a number rather than measure one — and a plausible
# wrong number is what this whole file exists to stop. Read this before adding one.
#
#   prefer-glob-over-find   306 fires. The nudge says "use the Glob TOOL", and a
#                           Glob call is not a Bash command, so no Bash hook can
#                           ever witness the success case. A check here could only
#                           ever detect repeats, which manufactures a 0% rate by
#                           construction. Needs a PreToolUse[Glob] observer first.
#
#   guard-speculative-export 614 fires, the loudest of them, and answerable in
#                           principle: at Stop, either the export is gone or a
#                           caller exists, both readable from disk. The blocker is
#                           that "a caller exists" is not a grep — the hook has
#                           lenient/strict rules where a test file, a comment, and
#                           a string literal do not count. Re-deriving those here
#                           makes a second definition that drifts from the hook's.
#                           Needs that reference counter extracted and shared.
#
#   guard-cluster-e-smells  509 fires. Answerable by re-linting the same file, but
#                           needs per-file state rather than per-session, since a
#                           session edits many files and each nudge is about one.
#
#   warn-git-add-enumeration 394 fires. Same-door answerable on the next `git add`.
#                           Most sessions never run a second one, so nearly every
#                           fire would sit unresolved. Cheap to add, low yield.
#
#   guard-env-access        120 fires. Same shape as cluster-e: per-file, not
#                           per-session.
#
# The shared lesson: a hook is instrumentable when the world can answer POSITIVELY
# that the advice was taken. An absence of repetition is not that answer, because
# "they stopped" and "the situation never came up again" are the same silence.
#
# A SESSION MAY ONLY JUDGE ITS OWN NUDGES. resolve reads the Stop payload's
# session_id and touches only markers armed by that session. Two reasons, and the
# second is a live bug the first cut had. A Stop in session X cannot testify about
# whether session Y acted on its advice; and persona-adopted compares against a
# GLOBAL line count in the usage log, so with many sessions armed at once, session
# B adopting persona P would credit session A's untouched suggestion of P. Markers
# belonging to other sessions are left alone here and time out below.
#
# Markers whose session never comes back are REAPED, never scored. A session can
# end mid-window, and the alternative — letting some other session's Stops run the
# window down — manufactures a miss nobody earned. 130 such markers had piled up
# by the time this was written. An unscored fire is an honest gap; a fabricated
# heeded:false is a corrupt instrument, and this file's whole job is the instrument.
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

# How long a marker may sit before it is dropped unscored. Sized well past a long
# working session so an idle stretch is never mistaken for an abandoned one.
#
# Validated, because the failure is silent and total. `find -mmin +N` with a
# negative N is true for every file on disk, so HEED_REAP_HOURS=-1 or 0 deletes
# every live marker on the next Stop with no ledger line and no error — the whole
# instrument, wiped, looking exactly like a quiet day. A non-numeric value is worse
# than useless under `set -u`: bash arithmetic treats it as a variable name and
# throws an unbound-variable line to stderr on every call. Anything that is not a
# positive integer falls back to the default rather than being honoured.
REAP_HOURS="${HEED_REAP_HOURS:-48}"
case "$REAP_HOURS" in
  ''|*[!0-9]*) REAP_HOURS=48 ;;    # negative, fractional, or non-numeric
  0)           REAP_HOURS=48 ;;    # 0 means "reap everything", never what anyone wants
esac

# ── arm ─────────────────────────────────────────────────────────────────────
# arm <hook-id> <check> [arg] [sid]
arm() {
  local hook="${1:-}" check="${2:-}" arg="${3:-}" sid="${4:-${CLAUDE_SESSION_ID:-}}"
  [ -n "$hook" ] && [ -n "$check" ] || return 0
  [ -n "$sid" ] || sid="nosid"
  # Named by the sid's first 8 chars, matching every other hook's marker on this
  # machine. Two sessions sharing those 8 chars share this filename, so the second
  # one silently gets no instrumentation for this hook. That is a coverage gap, not
  # a wrong answer: ownership is compared on the FULL sid at resolve time, so
  # neither session can ever be handed the other's verdict.
  local m="${MARK_PREFIX}${hook}-${sid:0:8}"
  local tmp; tmp="$(dirname "$m")/.heedtmp-$$-${hook}-${sid:0:8}"
  [ -f "$m" ] && return 0                       # already armed this session
  # Some checks need a "before" reading, because they ask whether something was
  # APPENDED rather than whether it exists. Take it now, while now is still now.
  # HEED_BASELINE lets a caller that ALREADY computed the before-reading pass it
  # in, rather than this file re-deriving it and becoming a second definition
  # that can drift from the caller's.
  local baseline=0
  if [ -n "${HEED_BASELINE:-}" ]; then
    baseline="$HEED_BASELINE"
  elif [ "$check" = persona-adopted ]; then
    baseline=$(wc -l < "$HOME/.claude/personas/usage/events.jsonl" 2>/dev/null | tr -d ' ')
    baseline=${baseline:-0}
  fi
  # Written to a temp file and renamed, because a concurrent Stop in ANOTHER
  # session globs this directory and reads whatever is there. A plain redirect
  # leaves a half-written marker visible for the duration of six printfs, and a
  # reader that finds one cannot tell it from corruption. rename is atomic on the
  # same filesystem, so a reader sees either no marker or a complete one.
  {
    printf 'hook=%s\n' "$hook"
    printf 'sid=%s\n'  "$sid"
    printf 'check=%s\n' "$check"
    printf 'arg=%s\n'  "$arg"
    printf 'baseline=%s\n' "$baseline"
    printf 'stops=0\n'
  # The temp name must NOT match the marker glob, or a concurrent resolve picks up
  # the half-written temp file and we have reinvented the bug.
  } > "$tmp" 2>/dev/null && mv -f "$tmp" "$m" 2>/dev/null || rm -f "$tmp" 2>/dev/null
  return 0
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
    # Read the value, do NOT launder it. `tr -dc '0-9'` strips the sign, so a
    # corrupt "-5" arrives as 5 and scores a heed for tasks that never existed.
    # A highwatermark that is not a plain non-negative integer is unreadable, and
    # unreadable is not evidence of anything — fall through to the *.json check.
    local hw; hw=$(tr -d '[:space:]' < "$dir/.highwatermark" 2>/dev/null)
    case "$hw" in
      ''|*[!0-9]*) : ;;
      *) [ "$hw" -gt 0 ] 2>/dev/null && { echo yes; return; } ;;
    esac
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

# check_kanban_asks_sorted <slug> <baseline-pending-count>
# Heeded means the count went DOWN, not that it is zero: an agent that sorts two
# of five asks acted on the nudge. A store that will not parse is unknown, never
# no, or a broken file would score a miss every Stop.
check_kanban_asks_sorted() {
  local slug="${1:-}" base="${2:-0}"
  # honours KANBAN_ROOT like every other reader, so a suite can exercise this
  # against a throwaway store instead of the owner's real one
  local kroot="${KANBAN_ROOT:-$HOME/.claude/kanban}"
  local items="$kroot/items.json" landings="$kroot/landings.json"
  [ -f "$items" ] || { echo unknown; return; }
  local now
  now=$(jq -r --slurpfile L <(cat "$landings" 2>/dev/null || echo '{"landings":{}}') --arg slug "$slug" '
    def scope: if ((.boards // []) | length) > 0 then .boards elif .slug then [.slug] else null end;
    ($L[0].landings // {}) as $done
    | [ .items[]? | select($done[.id] == null)
        | select((scope == null) or (scope | index($slug) != null)) ] | length' "$items" 2>/dev/null)
  case "$now" in ''|*[!0-9]*) echo unknown; return ;; esac
  [ "$now" -lt "$base" ] 2>/dev/null && { echo yes; return; }
  echo no
}

run_check() {
  case "${1:-}" in
    task-store-nonempty) check_task_store_nonempty "${2:-}" ;;
    persona-adopted)     check_persona_adopted "${2:-}" "${3:-0}" ;;
    kanban-asks-sorted)  check_kanban_asks_sorted "${2:-}" "${3:-0}" ;;
    *)                   echo unknown ;;
  esac
}

# ── resolve ─────────────────────────────────────────────────────────────────
# resolve <current-sid> — judges only markers armed by that session; every other
# marker is left untouched unless it has aged past the reap window.
resolve() {
  local me="${1:-}" m hook sid check arg stops baseline verdict
  for m in "${MARK_PREFIX}"*; do
    [ -f "$m" ] || continue

    # Reap first, and by the marker's own mtime rather than by a stop count, so a
    # session that ended mid-window leaves nothing behind and scores nothing. find
    # is given the file directly, which sidesteps the BSD symlinked-start-point
    # trap that makes `find /tmp …` match nothing (rules/shell.md).
    if [ -n "$(find "$m" -mmin "+$((REAP_HOURS * 60))" 2>/dev/null)" ]; then
      rm -f "$m" 2>/dev/null || true
      continue
    fi

    hook=""; sid=""; check=""; arg=""; stops=0; baseline=0
    # shellcheck disable=SC1090
    while IFS='=' read -r k v; do
      case "$k" in
        hook) hook="$v" ;; sid) sid="$v" ;; check) check="$v" ;;
        arg)  arg="$v"  ;; stops) stops="$v" ;; baseline) baseline="$v" ;;
      esac
    done < "$m"
    # A marker that does not parse belongs to SOMEBODY, and arm() can be caught
    # mid-write, so a half-written file is a live session's instrumentation a
    # moment before it becomes valid — not garbage. Deleting it here destroyed
    # another session's marker with no ledger trace. Leave it alone; if nobody
    # ever completes it, the reap above collects it.
    [ -n "$hook" ] && [ -n "$check" ] && [ -n "$sid" ] || continue

    # Another session's marker. Not ours to judge, and not ours to delete either —
    # that session may still be working and owes itself the verdict. It ages out
    # above if it never does. Compared on the FULL session id: two sessions whose
    # ids share their first 8 hex chars would otherwise resolve and delete each
    # other's markers, writing a verdict under the wrong session's name.
    [ "$sid" = "$me" ] || continue

    verdict=$(run_check "$check" "$arg" "$baseline")
    stops=$(( ${stops:-0} + 1 ))

    if [ "$verdict" = yes ]; then
      CLAUDE_SESSION_ID="$sid" bash "$WARN_LOG" --hook "$hook" --heed-of "${hook}:${sid:0:8}" --heeded true \
        >/dev/null 2>&1 || true
      rm -f "$m" 2>/dev/null || true
    elif [ "$verdict" = no ] && [ "$stops" -ge "$MAX_STOPS" ]; then
      # Grace window spent. Records ONE unheeded fire, which per the header note
      # is not a verdict on the hook.
      CLAUDE_SESSION_ID="$sid" bash "$WARN_LOG" --hook "$hook" --heed-of "${hook}:${sid:0:8}" --heeded false \
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
  resolve)
    # The Stop payload on stdin is the ONLY reliable statement of which session is
    # stopping. CLAUDE_SESSION_ID is unset in hook processes, and
    # ~/.claude/.current-session-id is written by whichever session touched it last
    # — on the machine this was written, it named a session other than the one
    # running. Reading it would attribute one session's heed to another.
    payload=$(cat 2>/dev/null || true)
    me=$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null || true)
    [ -n "$me" ] || me="${HEED_SID:-${CLAUDE_SESSION_ID:-}}"
    resolve "$me"
    ;;
  *)       exit 0 ;;
esac
exit 0
