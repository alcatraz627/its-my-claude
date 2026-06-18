#!/usr/bin/env bash
# persona-log.sh — usage residue trail for ~/.claude/personas.
#
# Records one append-only JSONL event per persona invocation so the efficacy of
# a persona can be reviewed over time. "Success" is genuinely hard to know at
# write time, so an event stores PROXIES (was the output accepted, how many
# corrections followed, did the refinement loop converge), a self-assessment,
# and a free-text residue note — never a single fabricated success bit. The
# `summary` view aggregates the proxies so trends surface even though any one
# row is noisy.
#
# Two callers:
#   - dispatch personas (juror, skeptical-reviewer): their dispatch script calls
#     `record --mode dispatched ...` — mechanical, reliable.
#   - working-mode personas (planner, doc-writer, web-researcher): the agent
#     calls `record --mode adopted ...` once at the end of the persona's work —
#     a convention, nudged by a hook (see features/persona-activation.md).
#
# Usage:
#   persona-log.sh record <persona> [flags]
#   persona-log.sh summary [--persona X] [--since YYYY-MM-DD]
#   persona-log.sh list [--persona X] [--limit N]
#   persona-log.sh help
set -euo pipefail

PERSONA_DIR="${HOME}/.claude/personas"
USAGE_DIR="${PERSONA_DIR}/usage"
EVENTS="${USAGE_DIR}/events.jsonl"
LOCK_DIR="${EVENTS}.lock"
VALID_PERSONAS_GLOB="${PERSONA_DIR}/*.md"

command -v jq >/dev/null 2>&1 || { echo "persona-log: jq required" >&2; exit 2; }
mkdir -p "$USAGE_DIR"

_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

_lock() {  # mkdir-based lock; ~2s budget, then proceed (a dropped log beats a hang)
  local i=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    i=$((i+1)); [ "$i" -ge 20 ] && return 0
    sleep 0.1
  done
}
_unlock() { rmdir "$LOCK_DIR" 2>/dev/null || true; }

_persona_exists() { [ -f "${PERSONA_DIR}/$1.md" ]; }

cmd_record() {
  local persona="${1:-}"; shift || true
  [ -n "$persona" ] || { echo "persona-log record: <persona> required" >&2; exit 2; }
  local mode="" depth="" task="" outcome="" loop="" iterations="" corrections="" cost="" session="" note=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --mode) mode="$2"; shift 2;;
      --depth) depth="$2"; shift 2;;
      --task) task="$2"; shift 2;;
      --outcome) outcome="$2"; shift 2;;       # accepted | revised | discarded | unknown
      --loop) loop="$2"; shift 2;;             # converged | partial | skipped
      --iterations) iterations="$2"; shift 2;;
      --corrections) corrections="$2"; shift 2;;
      --cost-tokens) cost="$2"; shift 2;;
      --session) session="$2"; shift 2;;
      --note) note="$2"; shift 2;;
      *) echo "persona-log record: unknown flag $1" >&2; exit 2;;
    esac
  done
  [ -n "$session" ] || session="${CLAUDE_CODE_SESSION_ID:-unknown}"
  _persona_exists "$persona" || echo "persona-log: warning — no persona file ${persona}.md (logging anyway)" >&2

  local id; id="puse-$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}"
  local line
  line=$(jq -nc \
    --arg id "$id" --arg ts "$(_now)" --arg persona "$persona" --arg session "$session" \
    --arg mode "$mode" --arg depth "$depth" --arg task "$task" --arg outcome "$outcome" \
    --arg loop "$loop" --arg note "$note" \
    --argjson iterations "${iterations:-null}" --argjson corrections "${corrections:-null}" \
    --argjson cost "${cost:-null}" \
    '{id:$id, ts:$ts, persona:$persona, session:$session, mode:$mode, depth:$depth,
      task:$task, outcome:$outcome, loop:$loop, iterations:$iterations,
      corrections:$corrections, cost_tokens:$cost, note:$note}
     | with_entries(select(.value != "" and .value != null))')
  _lock; printf '%s\n' "$line" >> "$EVENTS"; _unlock
  echo "$id"
}

cmd_summary() {
  local persona="" since=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --persona) persona="$2"; shift 2;;
      --since) since="$2"; shift 2;;
      *) echo "persona-log summary: unknown flag $1" >&2; exit 2;;
    esac
  done
  [ -f "$EVENTS" ] || { echo "No persona usage recorded yet ($EVENTS)"; return 0; }
  jq -rs --arg persona "$persona" --arg since "$since" '
    map(select(($persona=="" or .persona==$persona) and ($since=="" or .ts>=$since)))
    | group_by(.persona)
    | "PERSONA EFFICACY SUMMARY" ,
      "========================" ,
      ( .[] |
        ( .[0].persona ) as $p
        | "▸ \($p)  (\(length) invocation\(if length==1 then "" else "s" end))"
        , "    outcome:    " + ( [ .[] | .outcome // "unrecorded" ] | group_by(.) | map("\(.[0])×\(length)") | join("  ") )
        , "    loop:       " + ( [ .[] | .loop // "unrecorded" ]    | group_by(.) | map("\(.[0])×\(length)") | join("  ") )
        , "    mode:       " + ( [ .[] | .mode // "unrecorded" ]    | group_by(.) | map("\(.[0])×\(length)") | join("  ") )
        , "    corrections:" + ( [ .[] | .corrections // empty ] as $c | if ($c|length)>0 then " avg \(($c|add)/($c|length)|.*10|round/10) over \($c|length)" else " n/a" end )
        , "    last notes: " + ( [ .[] | select(.note) ] | sort_by(.ts) | reverse | .[0:2] | map("• " + .note) | join("  ") )
        , ""
      )
  ' "$EVENTS"
}

cmd_list() {
  local persona="" limit="20"
  while [ $# -gt 0 ]; do
    case "$1" in
      --persona) persona="$2"; shift 2;;
      --limit) limit="$2"; shift 2;;
      *) echo "persona-log list: unknown flag $1" >&2; exit 2;;
    esac
  done
  [ -f "$EVENTS" ] || { echo "No persona usage recorded yet"; return 0; }
  jq -rc --arg persona "$persona" 'select($persona=="" or .persona==$persona)
    | "\(.ts)  \(.persona)  [\(.mode // "?")/\(.outcome // "?")]  \(.task // "")"' "$EVENTS" | tail -n "$limit"
}

cmd_help() {
  cat <<'EOF'
persona-log.sh — usage residue trail for ~/.claude/personas

  record <persona> [flags]   append one usage event (prints the event id)
    --mode adopted|dispatched     how the persona ran
    --depth L1|L2|L3              depth level used (working-mode)
    --task "<1-line>"            what the persona was asked to do
    --outcome accepted|revised|discarded|unknown   did the user keep the output
    --loop converged|partial|skipped               did the refinement loop close
    --iterations N               loop iterations run
    --corrections N              user corrections/atone events that followed
    --cost-tokens N              tokens spent
    --session <id>               defaults to $CLAUDE_CODE_SESSION_ID
    --note "<residue>"          free-text: what worked / what the persona missed

  summary [--persona X] [--since YYYY-MM-DD]   per-persona efficacy aggregation
  list    [--persona X] [--limit N]            recent raw events
  help

Events: ~/.claude/personas/usage/events.jsonl (append-only JSONL)
EOF
}

case "${1:-help}" in
  record) shift; cmd_record "$@";;
  summary) shift; cmd_summary "$@";;
  list) shift; cmd_list "$@";;
  help|-h|--help) cmd_help;;
  *) echo "persona-log: unknown command '$1'" >&2; cmd_help; exit 2;;
esac
