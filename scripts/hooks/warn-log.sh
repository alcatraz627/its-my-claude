#!/usr/bin/env bash
# warn-log.sh — telemetry for WARN-emitting hooks (an event-ledger writer).
#
# A WARN hook calls this when it fires so hook fire-rate becomes continuously
# observable — instead of needing a forensic transcript replay to discover a hook
# has gone noisy. Each call appends ONE ledger-format line to the warn-events
# stream, keyed by hook_id (the SAME id used in the hook registry + feedback.jsonl),
# so a reader can join a fire back to the specific hook that raised it.
#
# The line carries two load-bearing envelope fields on top of the telemetry:
#   - id   — makes the line visible to ledger.sh (its reader drops id-less lines).
#   - kind:"warn" — the classifier the hook-warn-burn detector keys on.
#
# Contract (unchanged, and itself load-bearing — a WARN hook must never be broken
# by its own telemetry):
#   - CLI:        warn-log.sh --hook <id> [--action block|soft|nudge|muted] [--heeded true|false|unknown]
#                              [--cwd <dir>] [--target <file>] [--detail <short-reason>]
#   - heed line:  warn-log.sh --hook <id> --heed-of <fire-id-or-key> --heeded true|false [--cwd <dir>]
#   - never-fail: any internal error is swallowed; it ALWAYS exits 0.
#   - silent no-op when called without --hook.
#
# Diagnosis context (all OPTIONAL — a call with none of them is byte-identical to
# the pre-enrichment line, so the ~194 existing lines and every existing caller
# stay valid):
#   --cwd     the absolute working dir the hook fired in.
#   --target  the file path a file-scoped gate fired on (omit for session Stop gates).
#   --detail  a short (<80 char) reason, e.g. "31-line docstring".
# `project` is NOT a flag — warn-log derives it from --cwd (git-toplevel basename
# if inside a repo, else cwd basename). Each of cwd/project/target/detail is written
# only when non-empty (LEDGER_STRIP_EMPTY drops empties); no empty/null key is emitted.
#
# --heed-of records whether an EARLIER fire of this hook was heeded. It emits a
# resolution line with kind:"heed" (NOT "warn") and NO action field, carrying a
# `ref` back to the fire it resolves ({sid, hook_id} key or a fire id). Because the
# burn detectors match on the action field regardless of kind (action==block|soft|
# nudge), a heed line — which has no action — is ignored by every burn detector by
# construction; it only feeds the heed-rate readers.
#
# --action names WHAT the fire did: block = denied the tool call/turn (decision:block
# or exit 2); soft = a systemMessage / step-aside note; nudge = an additionalContext
# advisory; muted = would have fired but a mute file suppressed it. An absent OR
# unrecognized value omits the field (never rejects, never fails) — so old callers,
# legacy lines, and typos all stay valid. It replaces the old hook_id-suffix
# convention (declared-ready-block / -soft) so per-hook grouping is native and blocks
# get their own detector budget separate from advisory noise.
#
# Test override: WARN_LOG_STORE relocates the store so tests never touch the live
# path. Spec: ~/.claude/skills/shared/ledger-format.md
set -uo pipefail

LOG="${WARN_LOG_STORE:-$HOME/.claude/hooks/warn-events.jsonl}"
LOCK="$(dirname "$LOG")/.warn-events.lock"

hook_id="" heeded="unknown" action="" ref="" cwd="" target="" detail=""
while [ $# -gt 0 ]; do
  case "$1" in
    --hook)    hook_id="${2:-}"; shift 2 ;;
    --action)  action="${2:-}"; shift 2 ;;
    --heeded)  heeded="${2:-unknown}"; shift 2 ;;
    --heed-of) ref="${2:-}"; shift 2 ;;
    --cwd)     cwd="${2:-}"; shift 2 ;;
    --target)  target="${2:-}"; shift 2 ;;
    --detail)  detail="${2:-}"; shift 2 ;;
    # Callers are hooks that must never be broken, so a bad flag still writes the
    # record (a partial row beats no row) — but it says so on stderr, because a
    # silently-dropped field is how nine audit trails were lost (2026-07-10).
    --*|-?*)   echo "warn-log: unknown flag '$1' — ignored; record written without it" >&2; shift ;;
    *) shift ;;
  esac
done
[ -n "$hook_id" ] || exit 0   # silent no-op on misuse; never break the calling hook
# Only a recognized action reaches the line; anything else (absent, typo, junk)
# leaves action empty so LEDGER_STRIP_EMPTY drops the field. Never reject.
case "$action" in block|block-dry|soft|nudge|muted) : ;; *) action="" ;; esac

# Diagnosis context (all OPTIONAL — omitted when absent, so old callers and the
# ~194 existing lines stay byte-identical). `project` is DERIVED here from --cwd:
# the git-toplevel basename when cwd is inside a repo, else the cwd basename. Any
# git failure (not a repo, cwd gone) silently falls back to the basename — this
# must never break the calling hook. Overlong detail is clipped to keep lines small.
project=""
if [ -n "$cwd" ]; then
  top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$top" ]; then project=$(basename "$top" 2>/dev/null || true)
  else project=$(basename "$cwd" 2>/dev/null || true); fi
fi
[ ${#detail} -gt 79 ] && detail="${detail:0:79}"

# The sanctioned ledger writer (id-gen + timestamp + flock append). If it can't be
# sourced, fall back to byte-compatible inline equivalents so telemetry still works
# and the calling hook is never broken by a missing shared lib.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../ledger/ledger-common.sh" 2>/dev/null || true
if ! declare -f ledger_id >/dev/null 2>&1; then
  ledger_id()     { printf '%s-%s-%02x\n' "$1" "$(date -u '+%Y%m%d-%H%M%S')" $((RANDOM % 256)); }
  ledger_ts()     { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
  ledger_append() { ( flock -x 9 2>/dev/null || true; printf '%s\n' "$3" >> "$1"; ) 9>>"$2"; }
fi
: "${LEDGER_STRIP_EMPTY:=with_entries(select(.value != \"\" and .value != null))}"

sid="${CLAUDE_SESSION_ID:-}"
[ -z "$sid" ] && [ -f "$HOME/.claude/.current-session-id" ] && sid=$(cat "$HOME/.claude/.current-session-id" 2>/dev/null)

{
  ts=$(ledger_ts)
  mkdir -p "$(dirname "$LOG")"
  if [ -n "$ref" ]; then
    # Heed resolution line: kind:"heed", NO action field, carries a ref to the fire
    # it resolves. Burn detectors match on action (regardless of kind), so a line
    # with no action never counts toward any burn budget.
    id=$(ledger_id heed)
    line=$(jq -cn --arg id "$id" --arg ts "$ts" --arg h "$hook_id" --arg sid "$sid" --arg heeded "$heeded" --arg ref "$ref" --arg cwd "$cwd" \
      "{id:\$id, ts:\$ts, kind:\"heed\", hook_id:\$h, sid:\$sid, heeded:\$heeded, ref:\$ref, cwd:\$cwd} | $LEDGER_STRIP_EMPTY")
  else
    id=$(ledger_id warn)
    line=$(jq -cn --arg id "$id" --arg ts "$ts" --arg h "$hook_id" --arg action "$action" --arg sid "$sid" --arg heeded "$heeded" --arg cwd "$cwd" --arg project "$project" --arg target "$target" --arg detail "$detail" \
      "{id:\$id, ts:\$ts, kind:\"warn\", hook_id:\$h, action:\$action, sid:\$sid, fired:1, heeded:\$heeded, cwd:\$cwd, project:\$project, target:\$target, detail:\$detail} | $LEDGER_STRIP_EMPTY")
  fi
  ledger_append "$LOG" "$LOCK" "$line"
} 2>/dev/null || true
exit 0
