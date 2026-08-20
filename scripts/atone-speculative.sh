#!/usr/bin/env bash
# atone-speculative.sh — the speculative half of the atone system.
#
# The nightly residue review nominates atone-worthy moments it saw in a session's
# transcript. A nomination is NOT an atone: it lands here, in its own ledger, and
# the audited session MUST resolve it one of two ways — confirm (file the real
# /atone and link it) or refute (cite evidence). The hinter re-injects unresolved
# rows every turn, so silence is not one of the options; that asymmetry is the
# owner's design ("if it doesn't make the atone system bother the agent it will
# pick the easier path", 2026-08-20). The real ledger (atone/events.jsonl) is
# kernel-locked and only /atone writes it; this file never touches it.
#
#   atone-speculative.sh add --session <alias|uuid> --slug <guess> --severity <S1|S2|S3> \
#       --issue "<what the auditor saw>" --cite "<turn/file citation>" [--run <run-id>]
#   atone-speculative.sh pending [--session <s>]        unresolved rows (all sessions bare)
#   atone-speculative.sh confirm <id> --atone <mist-id>
#   atone-speculative.sh refute <id> --evidence "<why the auditor is wrong, cited>"
#   atone-speculative.sh stats                          nominated / confirmed / refuted by run
#
# Store: ~/.claude/atone/speculative.jsonl (mutating ledger, proposals style; never
# sealed). Test override: SPEC_ATONE_STORE.
set -uo pipefail

command -v jq >/dev/null 2>&1 || { echo "atone-speculative: jq required" >&2; exit 2; }
source "$(dirname "${BASH_SOURCE[0]}")/ledger/ledger-common.sh"
STORE="${SPEC_ATONE_STORE:-$HOME/.claude/atone/speculative.jsonl}"

_mutate() {
  local id="$1" filter="$2"
  [ -f "$STORE" ] || { echo "atone-speculative: no store" >&2; return 1; }
  rg -q "\"id\": ?\"$id\"" "$STORE" || { echo "atone-speculative: no row $id" >&2; return 1; }
  local tmp; tmp=$(mktemp)
  jq -c --arg id "$id" --arg now "$(ledger_ts)" "if .id == \$id then ($filter) else . end" "$STORE" > "$tmp" \
    && mv -f "$tmp" "$STORE"
}

cmd_add() {
  local session="" slug="" severity="" issue="" cite="" run=""
  while [ $# -gt 0 ]; do case "$1" in
    --session) session="$2"; shift 2;; --slug) slug="$2"; shift 2;;
    --severity) severity="$2"; shift 2;; --issue) issue="$2"; shift 2;;
    --cite) cite="$2"; shift 2;; --run) run="$2"; shift 2;;
    *) echo "atone-speculative add: unknown flag $1" >&2; exit 2;;
  esac; done
  [ -n "$session" ] && [ -n "$issue" ] || { echo "atone-speculative add: --session and --issue required" >&2; exit 2; }
  mkdir -p "$(dirname "$STORE")"
  local id; id=$(ledger_id spec)
  # ledger_id's 2-hex tail collides within a burst (seen live: 10 adds in one
  # second produced a duplicate, and _mutate rewrites every row sharing an id).
  while [ -f "$STORE" ] && rg -q "\"id\": ?\"$id\"" "$STORE"; do id=$(ledger_id spec); sleep 0.05; done
  local line
  line=$(jq -cn --arg id "$id" --arg ts "$(ledger_ts)" --arg s "$session" --arg sl "$slug" \
    --arg sev "$severity" --arg i "$issue" --arg c "$cite" --arg r "$run" \
    '{id:$id, ts:$ts, session:$s, slug:$sl, severity:$sev, issue:$i, cite:$c, run:$r,
      status:"pending"} | with_entries(select(.value != "" and .value != null))')
  ledger_append "$STORE" "$STORE.lock" "$line"
  echo "$id"
}

cmd_pending() {
  local session=""
  while [ $# -gt 0 ]; do case "$1" in --session) session="$2"; shift 2;; *) shift;; esac; done
  [ -f "$STORE" ] || return 0
  jq -r --arg s "$session" '
    select(.status == "pending") | select(($s == "") or (.session == $s) or ((.session | startswith($s))))
    | "  \(.id)  [\(.severity // "?")] \(.slug // "unslugged")  \(.issue[0:90])\n     cite: \(.cite // "-")  session: \(.session)"' "$STORE"
}

cmd_confirm() {
  local id="${1:-}"; shift || true
  local atone=""
  while [ $# -gt 0 ]; do case "$1" in --atone) atone="$2"; shift 2;; *) shift;; esac; done
  [ -n "$id" ] && [ -n "$atone" ] || { echo "atone-speculative confirm: <id> --atone <mist-id> (file the real /atone first; this links it)" >&2; exit 2; }
  case "$atone" in mist-*) ;; *) echo "atone-speculative confirm: --atone must be a real mist- id from atone/events.jsonl" >&2; exit 2;; esac
  # The link is only honest if the real event exists.
  rg -q "\"id\": ?\"$atone\"" "$HOME/.claude/atone/events.jsonl" 2>/dev/null \
    || { echo "atone-speculative confirm: $atone not found in the real atone ledger — run /atone first" >&2; exit 2; }
  _mutate "$id" '.status = "confirmed" | .atone_id = "'"$atone"'" | .resolved_ts = $now' \
    && echo "confirmed: $id -> $atone"
}

cmd_refute() {
  local id="${1:-}"; shift || true
  local evidence=""
  while [ $# -gt 0 ]; do case "$1" in --evidence) evidence="$2"; shift 2;; *) shift;; esac; done
  [ -n "$id" ] || { echo "atone-speculative refute: <id> --evidence required" >&2; exit 2; }
  [ ${#evidence} -ge 40 ] || { echo "atone-speculative refute: evidence under 40 chars is a dismissal, not a refutation — cite the turn or file:line that disproves it" >&2; exit 2; }
  _mutate "$id" ".status = \"refuted\" | .evidence = $(jq -cn --arg e "$evidence" '$e') | .resolved_ts = \$now" \
    && echo "refuted: $id"
}

cmd_stats() {
  [ -f "$STORE" ] || { echo "no speculative atones yet"; return 0; }
  jq -r '[.run // "unattributed", .status] | @tsv' "$STORE" | sort | uniq -c \
    | awk '{ printf "  %-28s %-10s %s\n", $2, $3, $1 }'
}

case "${1:-}" in
  add) shift; cmd_add "$@";;
  pending) shift; cmd_pending "$@";;
  confirm) shift; cmd_confirm "$@";;
  refute) shift; cmd_refute "$@";;
  stats) shift; cmd_stats "$@";;
  *) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//';;
esac
