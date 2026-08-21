#!/bin/bash
# cron-duty.sh — a name and a liveness verdict for session-scoped cron duties.
#
# CronCreate jobs live in the harness process's memory: they survive /clear and
# /compact, and die only with the process (5h cap, crash, closed terminal). A
# checkpoint can therefore only say what was armed at dump time, and a job id
# says nothing across sessions. This ledger gives each recurring DUTY a stable
# slug, records which harness process armed it, and answers the one question a
# resuming or sibling session has: is this duty already armed by a process that
# is still alive? (Provenance: duplicate check-in crons at :23, 2026-08-21 —
# the resume re-armed a duty whose process had survived the /clear.)
#
# Usage:
#   cron-duty.sh record <slug> --job <id> --schedule "<cron expr>" [--prompt-head "<line>"]
#   cron-duty.sh check  <slug>     # exit 0 ARMED-LIVE · exit 1 not armed (absent or process dead)
#   cron-duty.sh list              # every duty with a LIVE/DEAD verdict
#   cron-duty.sh clear  <slug>     # run alongside CronDelete
#
# Liveness = recorded pid is alive AND its start time still matches (pid-reuse
# guard). DEAD means the duty is definitely unarmed and safe to re-arm. The
# ledger is advisory bookkeeping around the harness's authoritative CronList:
# in-session, CronList remains the ground truth; this ledger is what OTHER
# sessions (and resumes that lost their transcript) can read.
#
# Test overrides: CRON_DUTY_PID / CRON_DUTY_LSTART replace the ancestor walk,
# so the DEAD branch is exercisable without killing a real harness.
set -uo pipefail

DIR="${CRON_DUTY_DIR:-$HOME/.claude/cron-duties}"

die() { printf 'cron-duty: %s\n' "$1" >&2; exit 2; }

# The harness is the nearest ancestor whose command is `claude`. Record its pid
# and start time; the pair is the liveness identity for everything this session
# arms.
find_harness() {
  if [ -n "${CRON_DUTY_PID:-}" ]; then
    printf '%s\t%s\n' "$CRON_DUTY_PID" "${CRON_DUTY_LSTART:-test-override}"
    return 0
  fi
  local p=$$ comm i
  for i in 1 2 3 4 5 6 7 8; do
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ') || return 1
    [ -n "$p" ] && [ "$p" != "0" ] && [ "$p" != "1" ] || return 1
    comm=$(ps -o comm= -p "$p" 2>/dev/null | tr -d ' ')
    if [ "$comm" = "claude" ]; then
      printf '%s\t%s\n' "$p" "$(ps -o lstart= -p "$p")"
      return 0
    fi
  done
  return 1
}

# LIVE when the pid exists and its start time matches the record; anything else
# is DEAD (gone, or the pid was reused by an unrelated process).
verdict_for() {
  local pid="$1" lstart="$2" now
  if [ "$lstart" = "test-override" ]; then
    kill -0 "$pid" 2>/dev/null && { printf 'LIVE'; return; }
    printf 'DEAD'; return
  fi
  now=$(ps -o lstart= -p "$pid" 2>/dev/null)
  if [ -n "$now" ] && [ "$now" = "$lstart" ]; then printf 'LIVE'; else printf 'DEAD'; fi
}

cmd_record() {
  local slug="${1:?usage: cron-duty.sh record <slug> --job <id> --schedule "<expr>"}"; shift
  local job="" sched="" head=""
  while [ $# -gt 0 ]; do case "$1" in
    --job)         job="${2:?}"; shift 2 ;;
    --schedule)    sched="${2:?}"; shift 2 ;;
    --prompt-head) head="${2:?}"; shift 2 ;;
    *) die "unknown flag: $1" ;;
  esac; done
  [ -n "$job" ] && [ -n "$sched" ] || die "record needs --job and --schedule"
  local hp; hp=$(find_harness) || die "no claude ancestor found; record only works from inside a session (or set CRON_DUTY_PID)"
  local pid lstart; pid=${hp%%$'\t'*}; lstart=${hp#*$'\t'}
  mkdir -p "$DIR"
  jq -n --arg slug "$slug" --arg job "$job" --arg sched "$sched" --arg head "$head" \
        --arg sid "${CLAUDE_CODE_SESSION_ID:-unknown}" --arg pid "$pid" --arg lstart "$lstart" \
        --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        '{slug:$slug, job_id:$job, schedule:$sched, prompt_head:$head, sid:$sid,
          harness_pid:($pid|tonumber), harness_lstart:$lstart, armed_at:$ts}' \
        > "$DIR/$slug.json"
  printf 'recorded: %s (job %s, %s) armed by pid %s\n' "$slug" "$job" "$sched" "$pid"
}

cmd_clear() {
  local slug="${1:?usage: cron-duty.sh clear <slug>}"
  if [ -f "$DIR/$slug.json" ]; then rm -f -- "$DIR/$slug.json"; printf 'cleared: %s\n' "$slug"
  else printf 'cron-duty: no record for %s (already clear)\n' "$slug"; fi
}

row_line() { # <file> -> "<verdict>\t<render>"
  local f="$1" slug job sched sid pid lstart at v
  slug=$(jq -r .slug "$f"); job=$(jq -r .job_id "$f"); sched=$(jq -r .schedule "$f")
  sid=$(jq -r .sid "$f"); pid=$(jq -r .harness_pid "$f"); lstart=$(jq -r .harness_lstart "$f")
  at=$(jq -r .armed_at "$f")
  v=$(verdict_for "$pid" "$lstart")
  printf '%s\t%-6s %-28s %-16s job %-10s sid %.8s pid %-6s armed %s\n' \
    "$v" "$v" "$slug" "$sched" "$job" "$sid" "$pid" "$at"
}

cmd_check() {
  local slug="${1:?usage: cron-duty.sh check <slug>}"
  [ -f "$DIR/$slug.json" ] || { printf 'UNARMED %s — no record\n' "$slug"; exit 1; }
  local line; line=$(row_line "$DIR/$slug.json")
  printf '%s\n' "${line#*$'\t'}"
  [ "${line%%$'\t'*}" = "LIVE" ] || exit 1
}

cmd_list() {
  local any=0 f
  for f in "$DIR"/*.json; do
    [ -f "$f" ] || continue
    any=1
    local line; line=$(row_line "$f")
    printf '%s\n' "${line#*$'\t'}"
  done
  [ "$any" = 1 ] || printf 'no duties recorded\n'
}

case "${1:-}" in
  record) shift; cmd_record "$@" ;;
  clear)  shift; cmd_clear  "$@" ;;
  check)  shift; cmd_check  "$@" ;;
  list)   shift; cmd_list   "$@" ;;
  *) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
