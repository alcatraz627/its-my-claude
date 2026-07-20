#!/usr/bin/env bash
# metabolism.sh — the config's retirement ceremony (the first actuator).
#
# The gcc has a rich INTAKE path (propose.sh add, /atone, graduation to a rule) and
# almost no path OUT: 5 rules ever deleted in the whole history, every one an
# absorption, zero retired for lack of value. This is the missing counterpart —
# a way for a rule to LEAVE with a recorded reason, evidence, and a restore path,
# the same ceremony proposals already have via `propose.sh retire`.
#
# What it does NOT do: delete anything. It records a retirement CANDIDATE (status
# "proposed") to rules/retired.jsonl with the evidence and the current HEAD sha, so
# a human can review it and, only if they agree, git rm the file in a normal commit.
# The ledger entry is the permanent record; the removal is the human-gated step.
# This is the design's ironclad rule: propose, never auto-act. Unmeasurable is not
# worthless — a rule with no signal is EXEMPT from value-based retirement.
#
# The `metabolism.jsonl` schema can hold other pathway events later (promote,
# compress, distill); only `retire` is implemented, because only it has a real use
# today. No speculative stubs (generalize-before-enumerate).
#
# Usage:
#   metabolism.sh retire <rule-slug> --disposition <d> --reason <r> --evidence <e> [--into <survivor>]
#   metabolism.sh list [--status proposed|removed]
#   metabolism.sh help
#
# Test override: METABOLISM_LEDGER relocates the ledger so tests never touch live.
set -uo pipefail

G="$HOME/.claude"
LEDGER="${METABOLISM_LEDGER:-$G/rules/retired.jsonl}"
LOCK_DIR="${LEDGER}.lock"
RULES_DIR="${METABOLISM_RULES_DIR:-$G/rules}"

command -v jq >/dev/null 2>&1 || { echo "metabolism: jq required" >&2; exit 2; }
mkdir -p "$(dirname "$LEDGER")"

_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
_acquired=0
_lock() { local i=0; while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if [ -d "$LOCK_DIR" ]; then local age; age=$(( $(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0) )); [ "$age" -gt 30 ] && rmdir "$LOCK_DIR" 2>/dev/null && continue; fi
    i=$((i+1)); [ "$i" -ge 20 ] && return 0; sleep 0.1; done; _acquired=1; }
_unlock() { [ "$_acquired" = 1 ] && rmdir "$LOCK_DIR" 2>/dev/null; _acquired=0; }
trap _unlock EXIT INT TERM

# The dispositions a rule may retire under. "retired-no-value" is the ONLY one that
# needs an adherence signal; the others are structural and always admissible.
_valid_disposition() {
  case "$1" in absorbed|superseded-by-hook|obsoleted-by-change|retired-no-value) return 0;; *) return 1;; esac
}

cmd_retire() {
  local slug="${1:-}"; shift || true
  [ -n "$slug" ] || { echo "metabolism retire: <rule-slug> required" >&2; exit 2; }
  local disposition="" reason="" evidence="" into="" session=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --disposition|--reason|--evidence|--into|--session)
        [ "$#" -ge 2 ] || { echo "metabolism retire: $1 needs a value" >&2; exit 2; } ;;
      *) echo "metabolism retire: unknown flag $1" >&2; exit 2 ;;
    esac
    case "$1" in
      --disposition) disposition="$2";; --reason) reason="$2";;
      --evidence) evidence="$2";; --into) into="$2";; --session) session="$2";;
    esac
    shift 2
  done
  # Evidence and reason are MANDATORY — a retirement without them is a git rm with
  # extra steps, which is the thing this ceremony exists to prevent.
  [ -n "$disposition" ] || { echo "metabolism retire: --disposition required (absorbed|superseded-by-hook|obsoleted-by-change|retired-no-value)" >&2; exit 2; }
  _valid_disposition "$disposition" || { echo "metabolism retire: invalid disposition '$disposition'" >&2; exit 2; }
  [ -n "$reason" ]   || { echo "metabolism retire: --reason required (why, in plain words)" >&2; exit 2; }
  [ -n "$evidence" ] || { echo "metabolism retire: --evidence required (the signal that justifies it)" >&2; exit 2; }

  # The rule file should exist (you cannot retire what is not there) — warn, don't block.
  [ -f "$RULES_DIR/$slug.md" ] || echo "metabolism: warning — no rule file $slug.md at $RULES_DIR (recording anyway)" >&2
  # Capture the current HEAD sha so the retired rule is one `git show <sha>:rules/$slug.md` away.
  local sha; sha=$(git -C "$G" rev-parse --short HEAD 2>/dev/null || echo "unknown")
  [ -n "$session" ] || session="${CLAUDE_CODE_SESSION_ID:-unknown}"

  local id; id="ret-$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}"
  local line
  line=$(jq -nc \
    --arg id "$id" --arg ts "$(_now)" --arg rule "$slug" --arg disposition "$disposition" \
    --arg reason "$reason" --arg evidence "$evidence" --arg into "$into" \
    --arg restorable_from "$sha" --arg session "$session" \
    '{id:$id, ts:$ts, pathway:"retire", status:"proposed", rule:$rule,
      disposition:$disposition, reason:$reason, evidence:$evidence, into:$into,
      restorable_from:$restorable_from, session:$session}
     | with_entries(select(.value != "" and .value != null))')
  _lock; printf '%s\n' "$line" >> "$LEDGER"; _unlock
  echo "$id"
  echo "recorded as a PROPOSED retirement — no file removed." >&2
  echo "to complete: a human reviews, then git rm rules/$slug.md in a normal commit." >&2
  echo "to undo the record: it is append-only; file a corrective note. the rule is at git show $sha:rules/$slug.md" >&2
}

cmd_list() {
  local status=""
  while [ $# -gt 0 ]; do case "$1" in
    --status) [ "$#" -ge 2 ] || { echo "metabolism list: --status needs a value" >&2; exit 2; }; status="$2"; shift 2;;
    *) echo "metabolism list: unknown flag $1" >&2; exit 2;; esac; done
  [ -f "$LEDGER" ] || { echo "No retirements recorded yet ($LEDGER)"; return 0; }
  jq -R 'fromjson? // empty' "$LEDGER" | jq -rc --arg s "$status" 'select($s=="" or .status==$s)
    | "\(.ts)  [\(.status)]  \(.rule)  (\(.disposition))  — \(.reason)"'
}

cmd_help() {
  cat <<'EOF'
metabolism.sh — the config's retirement ceremony (records intent, never deletes)

  retire <rule-slug> --disposition <d> --reason <r> --evidence <e> [--into <survivor>]
    --disposition  absorbed | superseded-by-hook | obsoleted-by-change | retired-no-value
    --reason       why, in plain words (MANDATORY)
    --evidence     the signal that justifies it (MANDATORY): e.g.
                   "superseded-by safe-delete.sh" / "atone slug zero since 2026-05"
                   / "heed-rate 4% over N fires" / "hook never fired in 90d"
    --into         the survivor rule/hook, if absorbed or superseded
  list [--status proposed|removed]
  help

Records a PROPOSED retirement to rules/retired.jsonl with the current HEAD sha as
restorable_from. Removes NOTHING — a human reviews, then git rm's the rule if they
agree. Unmeasurable rules (no hook, no atone lineage) are EXEMPT from retired-no-value.
EOF
}

case "${1:-help}" in
  retire) shift; cmd_retire "$@";;
  list) shift; cmd_list "$@";;
  help|-h|--help) cmd_help;;
  *) echo "metabolism: unknown command '$1'" >&2; cmd_help; exit 2;;
esac
