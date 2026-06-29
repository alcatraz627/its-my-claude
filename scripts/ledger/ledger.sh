#!/usr/bin/env bash
# ledger.sh — the read/query surface over the gcc event-ledger family.
#
# One dispatcher across the durable judgment ledgers (atone, affirm, pinned,
# proposals, personas) + the alert ledger. Generalizes atone's loved ergonomics
# (list/search/show/stats) over the union, adds the cross-domain `timeline` the
# unified session_id key unlocks, and gives agents a cheap, cited `ask`/`status`.
#
# Design choices (per design-red-alert / the critique):
#   - Filters key on session_id / tags / id / ts / the DOMAIN-declared classifier —
#     never a global --kind/--severity (those are domain-owned, so a global filter
#     would silently return nothing for most domains).
#   - `ask` returns CITED FACTS, not LLM prose (the caller is already an LLM).
#   - `ask`/`status` read the ledger + alert-state ONLY, never the daemon `::logs`
#     firehoses (valence/introspection/injections) — they are capped/rewritten and
#     out of the family.
#   - No `why` command in v1 (its cross-event `corr` join needs a field v1 lacks).
#
# Read-only. Spec: ~/.claude/skills/shared/ledger-format.md
set -uo pipefail

# The ::ledger family: domain | path | classifier(jq) | summary(jq)
_streams() {
  printf '%s\t%s\t%s\t%s\n' \
    atone     "$HOME/.claude/atone/events.jsonl"          '(.slug//"")+" ["+(.severity//"")+"]"' '(.issue//.title//"")' \
    affirm    "$HOME/.claude/affirm/events.jsonl"         '(.slug//"")+" ["+(.cluster//"")+"]"'  '(.title//.behavior//"")' \
    pinned    "$HOME/.claude/pinned/events.jsonl"         '(.framing//"pin")'                      '(.text//"")' \
    proposals "$HOME/.claude/proposals.jsonl"             '(.category//"")+"/"+(.status//"")'      '(.title//"")' \
    personas  "$HOME/.claude/personas/usage/events.jsonl" '(.persona//"")+"/"+(.mode//"")'         '(.task//"")' \
    alerts    "$HOME/.claude/ledger/alerts.jsonl"         '(.detector//"")+" ["+(.tier//"")+"]"'   '(.instruction//"")'
}

# Normalized rows from every stream: ts \t domain \t id \t session \t classifier \t summary
_emit() {
  local only="${1:-}"
  _streams | while IFS=$'\t' read -r dom path cls sum; do
    [ -n "$only" ] && [ "$only" != "$dom" ] && continue
    [ -f "$path" ] || continue
    jq -rc --arg dom "$dom" \
      "select(.id != null) | [(.ts//\"\"), \$dom, (.id//\"?\"), (.session_id//\"\"), ($cls), ($sum)] | @tsv" \
      "$path" 2>/dev/null
  done
}

_trunc() { awk -F'\t' -v OFS='\t' '{ if (length($6)>72) $6=substr($6,1,69)"..."; print }'; }
_tbl()  { awk -F'\t' '{ printf "  %-20s %-10s %-26s %s\n", substr($1,1,19), $2, $5, $6 }'; }

cmd_list() {  # list [--src D] [--session S] [--since ISO] [--limit N]
  local src="" session="" since="" limit=25
  while [ $# -gt 0 ]; do case "$1" in
    --src) src="$2"; shift 2;; --session) session="$2"; shift 2;;
    --since) since="$2"; shift 2;; --limit) limit="$2"; shift 2;;
    *) shift;; esac; done
  _emit "$src" | awk -F'\t' -v s="$session" -v d="$since" \
    '($1!="") && (s=="" || $4==s) && (d=="" || $1>=d)' \
    | sort -rt$'\t' -k1 | head -n "$limit" | _trunc | _tbl
}

cmd_timeline() {  # timeline <session> — every domain's events in one session, in order
  [ -n "${1:-}" ] || { echo "usage: ledger timeline <session-id>" >&2; return 2; }
  _emit | awk -F'\t' -v s="$1" '$4==s' | sort -t$'\t' -k1 | _trunc | _tbl
}

cmd_search() {  # search <query> [--src D]
  local q="${1:-}"; shift || true; local src=""
  [ "${1:-}" = "--src" ] && src="$2"
  [ -n "$q" ] || { echo "usage: ledger search <query> [--src D]" >&2; return 2; }
  _emit "$src" | rg -i --no-config -- "$q" 2>/dev/null | sort -rt$'\t' -k1 | head -30 | _trunc | _tbl
}

cmd_show() {  # show <id> — full record from whichever stream holds it
  [ -n "${1:-}" ] || { echo "usage: ledger show <id>" >&2; return 2; }
  _streams | while IFS=$'\t' read -r dom path cls sum; do
    [ -f "$path" ] || continue
    if jq -e --arg id "$1" 'select(.id==$id)' "$path" >/dev/null 2>&1; then
      echo "── $dom ──"
      jq --arg id "$1" 'select(.id==$id)' "$path" 2>/dev/null
      return 0
    fi
  done
  echo "id not found: $1" >&2; return 1
}

cmd_stats() {  # stats [--src D] — counts per domain + 7-day recency
  local src="${2:-}" cut7; cut7=$(date -u -v-7d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
  _emit "$src" | awk -F'\t' -v c="$cut7" '{ n[$2]++; if(c!=""&&$1>=c) r[$2]++ } END { for (d in n) printf "  %-12s %5d total  %4d in 7d\n", d, n[d], r[d] }' | sort
}

cmd_sources() {  # which ledgers exist + their classifier
  echo "  ::ledger family (system-of-record streams):"
  _streams | while IFS=$'\t' read -r dom path cls sum; do
    local n="-"; [ -f "$path" ] && n=$(wc -l < "$path" | tr -d ' ')
    printf "  %-12s %6s events   %s\n" "$dom" "$n" "${path/#$HOME/~}"
  done
}

cmd_status() {  # agent: has any detector tripped? read alert-state live (never cache)
  local st="$HOME/.claude/ledger/detector-state.json" al="$HOME/.claude/ledger/alerts.jsonl"
  [ -f "$st" ] || { echo "no detector state yet (evaluator runs daily 03:15)"; return 0; }
  local firing; firing=$(jq -r 'to_entries[] | select(.value.firing==true) | .key' "$st" 2>/dev/null)
  if [ -z "$firing" ]; then echo "ledger: no detectors firing"; else
    echo "ledger: FIRING — $firing"
    for d in $firing; do
      jq -r --arg d "$d" 'select(.detector==$d and .actionable==true) | "  "+.idempotence_key+": "+.instruction' "$al" 2>/dev/null | tail -1
    done
  fi
}

cmd_ask() {  # agent: cited facts about a topic (recency × substring), NOT prose
  local q="${1:-}"; shift || true; local src=""
  [ "${1:-}" = "--src" ] && src="$2"
  [ -n "$q" ] || { echo "usage: ledger ask <topic> [--src D]" >&2; return 2; }
  echo "ledger says about \"$q\" (most recent first; each cites a domain + id):"
  _emit "$src" | rg -i --no-config -- "$q" 2>/dev/null | sort -rt$'\t' -k1 | head -8 \
    | awk -F'\t' '{ printf "  [%s] %s#%s — %s\n", $2, $1, $3, substr($6,1,90) }'
}

case "${1:-help}" in
  list)     shift; cmd_list "$@";;
  timeline) shift; cmd_timeline "$@";;
  search)   shift; cmd_search "$@";;
  show)     shift; cmd_show "$@";;
  stats)    cmd_stats "$@";;
  sources)  cmd_sources;;
  status)   cmd_status;;
  ask)      shift; cmd_ask "$@";;
  *) printf 'ledger — query surface over the gcc event-ledger family\n\n'
     printf '  list [--src D] [--session S] [--since ISO] [--limit N]\n'
     printf '  timeline <session>     all domains, one session, in order\n'
     printf '  search <q> [--src D]   substring across the union\n'
     printf '  show <id>              full record\n'
     printf '  stats [--src D]        per-domain counts + 7-day recency\n'
     printf '  sources                which ledgers exist\n'
     printf '  status                 (agent) has a detector tripped?\n'
     printf '  ask <topic> [--src D]  (agent) cited facts, not prose\n';;
esac
