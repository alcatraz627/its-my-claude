#!/usr/bin/env bash
# skill-log.sh — efficacy residue trail for ~/.claude skills.
#
# Records one append-only JSONL event per skill run so a skill's efficacy can be
# reviewed over time. Sibling of persona-log.sh: skills are not personas, so they
# get their own namespace and stream, but the model is identical — "success" is
# hard to know at write time, so an event stores PROXIES (was the output accepted,
# did the loop converge, how many correction rounds, how many user corrections
# followed) plus a free-text residue note and an optional per-skill metrics blob.
# No single fabricated success bit; the summary view aggregates the noisy proxies.
#
# Efficacy is result per unit of the USER's effort counting rework — never speed.
# So the load-bearing proxies are `outcome` (did they keep it) and `corrections`
# (how much rework followed), not wall-clock.
#
# Callers: a skill calls `record <skill>` once at completion (its docs/retro
# stage). /bloop records its validation-gate verdict + fix rounds; /deadline
# records turns-used-vs-planned + assumptions vetoed via --metrics.
#
# Usage:
#   skill-log.sh record <skill> [flags]
#   skill-log.sh summary [--skill X] [--since YYYY-MM-DD]
#   skill-log.sh list [--skill X] [--limit N]
#   skill-log.sh help
#
# Test override: SKILL_LOG_EVENTS relocates the stream so tests never touch live.
set -euo pipefail

EVENTS="${SKILL_LOG_EVENTS:-${HOME}/.claude/skills/usage/events.jsonl}"

command -v jq >/dev/null 2>&1 || { echo "skill-log: jq required" >&2; exit 2; }
mkdir -p "$(dirname "$EVENTS")"

# The append goes through the gcc ledger family's one sanctioned writer (mkdir
# lock, best-effort after ~2s, seal-safe), so this stream is a member of the family
# ledger.sh reads, not a look-alike. The id keeps its original shape
# (skl-<stamp>-<rand>, the persona-log style ledger-format.md lists as legal) so
# history and citations stay valid.
source "$(dirname "${BASH_SOURCE[0]}")/ledger/ledger-common.sh"
_now() { ledger_ts; }

# Emit a numeric value for jq --argjson, else `null` — a fat-fingered --corrections
# must not crash the event under set -e (jq --argjson rejects non-JSON).
_numjson() { case "$1" in ''|*[!0-9]*) printf 'null';; *) printf '%s' "$1";; esac; }
# Emit valid JSON as-is for --metrics, else `null` — never let a malformed blob
# (or an empty arg, which jq accepts as empty output, not an error) abort the record.
_objjson() {
  [ -z "$1" ] && { printf 'null'; return; }
  printf '%s' "$1" | jq -c . 2>/dev/null || printf 'null'
}

cmd_record() {
  local skill="${1:-}"; shift || true
  [ -n "$skill" ] || { echo "skill-log record: <skill> required" >&2; exit 2; }
  local task="" outcome="" loop="" iterations="" corrections="" gate="" cost="" session="" note="" metrics=""
  # Validate first (known flag AND a value present), then assign, then one shift.
  # A dangling flag must fail clean (exit 2), never crash on $2 under set -u.
  while [ $# -gt 0 ]; do
    case "$1" in
      --task|--outcome|--loop|--iterations|--corrections|--gate|--cost-tokens|--session|--note|--metrics)
        [ "$#" -ge 2 ] || { echo "skill-log record: $1 needs a value" >&2; exit 2; } ;;
      *) echo "skill-log record: unknown flag $1" >&2; exit 2 ;;
    esac
    case "$1" in
      --task) task="$2";;
      --outcome) outcome="$2";;         # accepted | revised | discarded | unknown
      --loop) loop="$2";;               # converged | partial | skipped
      --iterations) iterations="$2";;   # fix/refine rounds run
      --corrections) corrections="$2";; # user corrections that followed
      --gate) gate="$2";;               # pass | pass-with-notes | issues-found (bloop)
      --cost-tokens) cost="$2";;
      --session) session="$2";;
      --note) note="$2";;
      --metrics) metrics="$2";;         # optional per-skill JSON blob
    esac
    shift 2
  done
  [ -n "$session" ] || session="${CLAUDE_CODE_SESSION_ID:-unknown}"

  # A /validate record must name a real second seat and >=1 parity row run, or
  # carry the owner's waiver; the SKILL.md mandate binds only at this write.
  if [ "$skill" = "validate" ] && ! printf '%s' "$note" | rg -q 'seat-waived=owner'; then
    local vseat vrows
    vseat=$(printf '%s' "$note" | rg -o 'second-seat=[^ ]+' 2>/dev/null | head -1 | cut -d= -f2) || true
    vrows=$(printf '%s' "$note" | rg -o 'rows-run=[0-9]+' 2>/dev/null | head -1 | cut -d= -f2) || true
    case "$(printf '%s' "$vseat" | tr '[:upper:]' '[:lower:]')" in
      ""|self*|none|n/a|na|yes|no|0|lol)
        echo "skill-log record: validate needs second-seat=<real seat> in --note, or seat-waived=owner" >&2; exit 2;;
    esac
    if ! [ "${vrows:-0}" -ge 1 ] 2>/dev/null; then
      echo "skill-log record: validate needs rows-run>=1 in --note, or seat-waived=owner" >&2; exit 2
    fi
  fi

  local id; id="skl-$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}"
  local line
  line=$(jq -nc \
    --arg id "$id" --arg ts "$(_now)" --arg skill "$skill" --arg session "$session" \
    --arg task "$task" --arg outcome "$outcome" --arg loop "$loop" --arg gate "$gate" --arg note "$note" \
    --argjson iterations "$(_numjson "$iterations")" --argjson corrections "$(_numjson "$corrections")" \
    --argjson cost "$(_numjson "$cost")" --argjson metrics "$(_objjson "$metrics")" \
    '{id:$id, ts:$ts, skill:$skill, session:$session, task:$task, outcome:$outcome,
      loop:$loop, iterations:$iterations, corrections:$corrections, gate:$gate,
      cost_tokens:$cost, metrics:$metrics, note:$note}
     | with_entries(select(.value != "" and .value != null))')
  ledger_append "$EVENTS" "${EVENTS}.lock" "$line"
  echo "$id"
}

cmd_summary() {
  local skill="" since=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --skill) skill="$2"; shift 2;;
      --since) since="$2"; shift 2;;
      *) echo "skill-log summary: unknown flag $1" >&2; exit 2;;
    esac
  done
  [ -f "$EVENTS" ] || { echo "No skill usage recorded yet ($EVENTS)"; return 0; }
  jq -R 'fromjson? // empty' "$EVENTS" | jq -rs --arg skill "$skill" --arg since "$since" '
    map(select(($skill=="" or .skill==$skill) and ($since=="" or .ts>=$since)))
    | group_by(.skill)
    | "SKILL EFFICACY SUMMARY" ,
      "======================" ,
      ( .[] |
        ( .[0].skill ) as $s
        | "▸ \($s)  (\(length) run\(if length==1 then "" else "s" end))"
        , "    outcome:    " + ( [ .[] | .outcome // "unrecorded" ] | group_by(.) | map("\(.[0])×\(length)") | join("  ") )
        , "    loop:       " + ( [ .[] | .loop // "unrecorded" ]    | group_by(.) | map("\(.[0])×\(length)") | join("  ") )
        , "    gate:       " + ( [ .[] | .gate // "unrecorded" ]    | group_by(.) | map("\(.[0])×\(length)") | join("  ") )
        , "    corrections:" + ( [ .[] | .corrections // empty ] as $c | if ($c|length)>0 then " avg \(($c|add)/($c|length)|.*10|round/10) over \($c|length)" else " n/a" end )
        , "    last notes: " + ( [ .[] | select(.note) ] | sort_by(.ts) | reverse | .[0:2] | map("• " + .note) | join("  ") )
        , ""
      )
  '
}

cmd_list() {
  local skill="" limit="20"
  while [ $# -gt 0 ]; do
    case "$1" in
      --skill) skill="$2"; shift 2;;
      --limit) limit="$2"; shift 2;;
      *) echo "skill-log list: unknown flag $1" >&2; exit 2;;
    esac
  done
  [ -f "$EVENTS" ] || { echo "No skill usage recorded yet"; return 0; }
  jq -R 'fromjson? // empty' "$EVENTS" | jq -rc --arg skill "$skill" 'select($skill=="" or .skill==$skill)
    | "\(.ts)  \(.skill)  [\(.outcome // "?")/\(.gate // "-")]  \(.task // "")"' | tail -n "$limit"
}

cmd_help() {
  cat <<'EOF'
skill-log.sh — efficacy residue trail for ~/.claude skills

  record <skill> [flags]   append one usage event (prints the event id)
    --task "<1-line>"       what the skill run was asked to do
    --outcome accepted|revised|discarded|unknown   did the user keep the output
    --loop converged|partial|skipped               did the refine/validate loop close
    --iterations N          fix/refine rounds run
    --corrections N         user corrections that followed
    --gate pass|pass-with-notes|issues-found        (bloop) the validation verdict
    --cost-tokens N         tokens spent
    --metrics '<json>'      optional per-skill numbers (e.g. deadline turns used/planned)
    --session <id>          defaults to $CLAUDE_CODE_SESSION_ID
    --note "<residue>"     free-text: what worked / what the run missed

  summary [--skill X] [--since YYYY-MM-DD]   per-skill efficacy aggregation
  list    [--skill X] [--limit N]            recent raw events
  help

Events: ~/.claude/skills/usage/events.jsonl (append-only JSONL)
Efficacy = result per unit of the user's effort counting rework — never speed.
EOF
}

case "${1:-help}" in
  record) shift; cmd_record "$@";;
  summary) shift; cmd_summary "$@";;
  list) shift; cmd_list "$@";;
  help|-h|--help) cmd_help;;
  *) echo "skill-log: unknown command '$1'" >&2; cmd_help; exit 2;;
esac
