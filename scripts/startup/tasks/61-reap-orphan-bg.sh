#!/usr/bin/env bash
# reap-orphan-bg.sh — reconcile background-process TRACKING left active by a
# session that exited abnormally.
#
# shell-mem marks a [BG] command [BG:DONE] via session-end-shell.sh, which is a
# Stop hook. Every abnormal exit skips Stop, so the dead session's BG rows stay
# "active" forever (lifecycle audit D2b). This reconciles the TRACKING: for a BG
# row whose owning session is dead (its transcript untouched beyond the window,
# or absent) it marks the row done. The live session is never touched.
#
# SCOPE, deliberately: this reconciles the LEDGER, it does not kill processes.
# The shell-mem log records no PID, so a specific orphaned process cannot be
# identified or signalled from here; the process-killing half of D2b needs PID
# tracking added to track-bash.sh first, which is a separate change. Dev-server
# orphans are already reaped by ports.sh / svc-reap on their own TTL. Marking a
# row done is safe and reversible (the log is append-only history).
#
# Usage:  reap-orphan-bg.sh [--dry-run] [--stale-hours N] [--live-sid SID]
# Default stale window 6h: a live session touches its transcript far more often.

set -uo pipefail

CLAUDE="${HOME}/.claude"
PROJ="$CLAUDE/projects"
DRY_RUN=0
STALE_HOURS=6
LIVE_SID="${CLAUDE_CODE_SESSION_ID:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --stale-hours) STALE_HOURS="${2:-6}"; shift ;;
    --live-sid) LIVE_SID="${2:-}"; shift ;;
  esac
  shift
done

now=$(date +%s)
cutoff=$(( STALE_HOURS * 3600 ))
reconciled=0; live_skipped=0; total=0

# session is dead when its transcript's mtime is older than the window (or gone)
session_dead() {
  local sid="$1" tp mt
  tp=$(ls "$PROJ"/*/"$sid".jsonl 2>/dev/null | head -1)
  [ -n "$tp" ] || return 0                       # no transcript → dead
  mt=$(stat -f %m "$tp" 2>/dev/null || echo 0)
  [ $(( now - mt )) -gt "$cutoff" ]              # stale beyond window → dead
}

# Mark every [BG] row of a dead sid as [BG:DONE], directly, across the recent log
# files. Marking by sid (not by command fragment) sidesteps shell-log-mark-done's
# unescaped-grep matcher, which silently fails on a command containing a `[` (the
# `until [ -f …` waiters) and always exits 0 so a caller cannot tell. The sid is
# hex + hyphens, safe in a sed address; [BG] is a fixed literal.
mark_sid_done() { # $1 = dead sid → echoes count flipped
  local sid="$1" flipped=0 f before after d
  for d in 0 1 2 3; do
    f=$(bash "$CLAUDE/scripts/shell-mem/shell-log-file.sh" "$(date -v-"$d"d +%Y-%m-%d 2>/dev/null)" 2>/dev/null)
    [ -f "$f" ] || continue
    before=$(grep -c "\[sid:$sid\].*\[BG\]" "$f" 2>/dev/null | tr -d ' '); before=${before:-0}
    # only lines with this sid AND [BG] AND not already [BG:DONE]
    [ "$before" -gt 0 ] || continue
    local lock="/tmp/diy-mem-$(date +%Y-%m-%d).lock"
    until mkdir "$lock" 2>/dev/null; do sleep 0.05; done
    trap "rmdir '$lock' 2>/dev/null" RETURN
    sed -i '' "/\[sid:$sid\]/{/\[BG:DONE\]/!s/\[BG\]/[BG:DONE]/;}" "$f" 2>/dev/null
    rmdir "$lock" 2>/dev/null; trap - RETURN
    after=$(grep -c "\[sid:$sid\].*\[BG\]\([^:]\|$\)" "$f" 2>/dev/null | tr -d ' '); after=${after:-0}
    flipped=$(( flipped + before - after ))
  done
  echo "$flipped"
}

(( DRY_RUN )) && echo "reap-orphan-bg: DRY RUN (no rows marked done)"

# collect DEAD sids from the active roster (dedup), keeping the live session
seen=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  total=$((total + 1))
  sid=$(printf '%s' "$line" | sed -n 's/.*\[sid:\([0-9a-f-]*\)\].*/\1/p')
  [ -n "$sid" ] || continue
  if [ "$sid" = "$LIVE_SID" ]; then live_skipped=$((live_skipped + 1)); continue; fi
  case " $seen " in *" $sid "*) continue ;; esac   # dedup
  if ! session_dead "$sid"; then live_skipped=$((live_skipped + 1)); continue; fi
  seen="$seen $sid"
  if (( DRY_RUN )); then
    n=$(grep -l "\[sid:$sid\].*\[BG\]" "$CLAUDE"/shell-logs/*.md 2>/dev/null | wc -l | tr -d ' ')
    printf '  would reconcile dead sid %s (rows in %s log file[s])\n' "${sid:0:8}" "$n"
  else
    fl=$(mark_sid_done "$sid")
    printf '  reconciled dead sid %s (%s row[s] → BG:DONE)\n' "${sid:0:8}" "$fl"
    reconciled=$(( reconciled + fl ))
  fi
done < <(bash "$CLAUDE/scripts/shell-mem.sh" shell-log-active 2>/dev/null)

printf 'orphan-bg: %d rows reconciled (%d live-session rows kept, %d active rows scanned)\n' \
  "$reconciled" "$live_skipped" "$total"
