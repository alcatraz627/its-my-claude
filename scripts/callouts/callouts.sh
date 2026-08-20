#!/usr/bin/env bash
# callouts.sh — the owner's review findings, persisted until the owner retires them.
#
# A call-out from a review round used to die with the round, so the next "done"
# was verified against the agent's criteria instead of the owner's accumulated
# ones, and the same spot regressed (owner, 2026-08-20: their single biggest
# pain). This ledger makes each call-out a row with a re-runnable check. A done
# claim on a surface re-runs every open row first (`gate`), and only the owner
# retires a row; the agent may only claim it fixed.
#
#   callouts.sh add "<owner's words>" --surface <name> [--check "how to re-verify"]
#                   [--category visual|literary|technical|behavior]
#   callouts.sh list [--surface s] [--all]
#   callouts.sh recheck <id> pass|fail [--evidence "..."]
#   callouts.sh claim <id>              agent says "fixed"; row stays open
#   callouts.sh retire <id> --by owner  the only way a row closes
#   callouts.sh gate <surface>          exit 1 + the unmet rows, 0 when clean
#
# Store: <project-root>/.claude/callouts.jsonl (the gcc uses ~/.claude/callouts.jsonl,
# because its project-scoped .claude/ is write-guarded). Mutating ledger, proposals
# style: status changes rewrite the row, so it is never kernel-sealed.
# Test override: CALLOUTS_STORE.
set -uo pipefail

command -v jq >/dev/null 2>&1 || { echo "callouts: jq required" >&2; exit 2; }
source "$(dirname "${BASH_SOURCE[0]}")/../ledger/ledger-common.sh"

_store() {
  if [ -n "${CALLOUTS_STORE:-}" ]; then printf '%s' "$CALLOUTS_STORE"; return; fi
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  if [ "$root" = "$HOME/.claude" ]; then printf '%s' "$HOME/.claude/callouts.jsonl"
  else printf '%s' "$root/.claude/callouts.jsonl"; fi
}

# Rewrite one row by id through a jq filter. Same load-mutate-save shape as
# propose.sh, serialized by the same lock the appends use.
_mutate() {
  local id="$1" filter="$2" store; store=$(_store)
  [ -f "$store" ] || { echo "callouts: no store at $store" >&2; return 1; }
  rg -q "\"id\": ?\"$id\"" "$store" || { echo "callouts: no row $id" >&2; return 1; }
  local tmp; tmp=$(mktemp)
  jq -c --arg id "$id" --arg now "$(ledger_ts)" "if .id == \$id then ($filter) else . end" "$store" > "$tmp" \
    && mv -f "$tmp" "$store"
}

cmd_add() {
  local words="${1:-}"; shift || true
  [ -n "$words" ] || { echo "callouts add: the owner's words are required" >&2; exit 2; }
  local surface="" check="" category=""
  while [ $# -gt 0 ]; do case "$1" in
    --surface) surface="$2"; shift 2;; --check) check="$2"; shift 2;;
    --category) category="$2"; shift 2;;
    *) echo "callouts add: unknown flag $1" >&2; exit 2;;
  esac; done
  [ -n "$surface" ] || { echo "callouts add: --surface required (the page, file, doc, or feature the call-out is about)" >&2; exit 2; }
  local store id line; store=$(_store); mkdir -p "$(dirname "$store")"
  id=$(ledger_id co)
  # Burst-collision guard: ledger_id's 2-hex tail repeats within one second.
  while [ -f "$store" ] && rg -q "\"id\": ?\"$id\"" "$store"; do id=$(ledger_id co); sleep 0.05; done
  line=$(jq -cn --arg id "$id" --arg ts "$(ledger_ts)" --arg w "$words" --arg s "$surface" \
    --arg c "$check" --arg cat "$category" --arg sid "${CLAUDE_CODE_SESSION_ID:-}" \
    '{id:$id, ts:$ts, surface:$s, words:$w, check:$c, category:$cat, session_id:$sid,
      status:"open", rechecks:[]} | with_entries(select(.value != "" and .value != null))')
  ledger_append "$store" "$store.lock" "$line"
  echo "$id"
}

cmd_list() {
  local surface="" all=0 store; store=$(_store)
  while [ $# -gt 0 ]; do case "$1" in
    --surface) surface="$2"; shift 2;; --all) all=1; shift;;
    *) echo "callouts list: unknown flag $1" >&2; exit 2;;
  esac; done
  [ -f "$store" ] || { echo "no call-outs recorded ($store)"; return 0; }
  jq -r --arg s "$surface" --argjson all "$all" '
    select(($all == 1) or .status == "open")
    | select(($s == "") or (.surface == $s))
    | [.id, .status + (if .claimed then "·claimed" else "" end), .surface,
       ((.rechecks | length | tostring) + " rechecks"), .words] | @tsv' "$store" \
  | awk -F'\t' '{ printf "  %-22s %-14s %-18s %-11s %s\n", $1, $2, $3, $4, substr($5,1,70) }'
}

cmd_recheck() {
  local id="${1:-}" result="${2:-}"; shift 2 || true
  local evidence=""
  [ "$result" = "pass" ] || [ "$result" = "fail" ] || { echo "callouts recheck: <id> pass|fail" >&2; exit 2; }
  while [ $# -gt 0 ]; do case "$1" in
    --evidence) evidence="$2"; shift 2;;
    *) echo "callouts recheck: unknown flag $1" >&2; exit 2;;
  esac; done
  _mutate "$id" ".rechecks += [{ts: \$now, result: \"$result\", evidence: $(jq -cn --arg e "$evidence" '$e')}]" \
    && echo "recheck $result recorded on $id"
}

cmd_claim() {
  local id="${1:-}"
  [ -n "$id" ] || { echo "callouts claim: <id>" >&2; exit 2; }
  _mutate "$id" '.claimed = $now' && echo "claimed fixed: $id (stays open until the owner retires it)"
}

cmd_retire() {
  local id="${1:-}"; shift || true
  local by=""
  while [ $# -gt 0 ]; do case "$1" in --by) by="$2"; shift 2;; *) shift;; esac; done
  [ "$by" = "owner" ] || { echo "callouts retire: only the owner retires a row (--by owner, on their word in the transcript)" >&2; exit 2; }
  _mutate "$id" '.status = "retired" | .retired_ts = $now' && echo "retired: $id"
}

# The done-claim gate: every open row on the surface needs a pass recheck strictly
# newer than the latest claim (a same-second tie fails closed: re-verify after you
# claim, not alongside). Exit 1 with the unmet rows.
cmd_gate() {
  local surface="${1:-}" store; store=$(_store)
  [ -n "$surface" ] || { echo "callouts gate: <surface>" >&2; exit 2; }
  [ -f "$store" ] || { echo "gate clean: no call-outs recorded"; return 0; }
  local unmet
  unmet=$(jq -r --arg s "$surface" '
    select(.status == "open" and .surface == $s)
    | . as $r
    | ((.rechecks // []) | map(select(.result == "pass")) | last) as $p
    | select($p == null or ($r.claimed != null and $p.ts <= $r.claimed))
    | "  \(.id)  \(.words[0:80])\n     check: \(.check // "owner did not give one; derive it from the words")"' "$store")
  if [ -n "$unmet" ]; then
    echo "GATE: open call-outs on '$surface' without a fresh pass; re-run each before claiming done:"
    printf '%s\n' "$unmet"
    return 1
  fi
  echo "gate clean: every open call-out on '$surface' has a fresh pass recheck"
}

case "${1:-}" in
  add) shift; cmd_add "$@";;
  list) shift; cmd_list "$@";;
  recheck) shift; cmd_recheck "$@";;
  claim) shift; cmd_claim "$@";;
  retire) shift; cmd_retire "$@";;
  gate) shift; cmd_gate "$@";;
  *) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//';;
esac
