#!/usr/bin/env bash
# 14-day cadence gate for the repo-sync schedule.
#
# launchd can only fire on point-events (every Thursday), not intervals, so this
# wrapper turns a weekly fire into a bi-weekly one: it runs the sync only when at
# least 14 days have elapsed since the last successful launch, otherwise it exits
# quietly. Keying the cadence off elapsed days (not the calendar tick) keeps it
# correct even if the Mac was asleep on a fire time and launchd fired late on wake.
#
# On an eligible fire it opens a fresh opus Ghostty session seeded to run the
# two-repo sync brief. The stamp is bumped only after the window actually opens,
# so a failed handoff retries next Thursday instead of skipping a fortnight.
set -uo pipefail

STAMP="$HOME/.claude/scheduled/.repo-sync-last-run"   # epoch seconds of last run
INTERVAL=$((14 * 86400))                              # 14 days
LAUNCH="$HOME/.claude/scripts/schedule/launch-claude-new.sh"
BRIEF="$HOME/.claude/scheduled/repo-sync-brief.md"
PROMPT="Read $BRIEF and run the bi-weekly two-repo sync it describes, end to end."

now=$(date +%s)

write_meta() { [[ -n "${GCC_SCHED_META:-}" ]] && printf '%s\n' "$@" > "$GCC_SCHED_META"; return 0; }

# Cadence gate — skip if <14 days since the last recorded run.
if [[ -f "$STAMP" ]]; then
  last=$(cat "$STAMP" 2>/dev/null || echo 0)
  elapsed=$(( now - last ))
  if (( elapsed < INTERVAL )); then
    days=$(( elapsed / 86400 ))
    echo "[$(date '+%F %T')] repo-sync skipped — only ${days}d since last run (need 14d)"
    write_meta "outcome=ok" "reason=cadence_skip" "stage=gate" "detail=${days}d_elapsed"
    exit 0
  fi
fi

echo "[$(date '+%F %T')] repo-sync eligible — launching opus sync session"
if bash "$LAUNCH" opus acceptEdits "$PROMPT" "$HOME/.claude"; then
  printf '%s\n' "$now" > "$STAMP"     # bump cadence only on a confirmed window open
  echo "[$(date '+%F %T')] launched; stamp updated"
  exit 0
else
  rc=$?
  echo "[$(date '+%F %T')] launch failed (rc=$rc) — stamp NOT bumped, will retry next Thursday" >&2
  write_meta "outcome=failed" "reason=launch_failed" "stage=open" "exit=$rc"
  exit "$rc"
fi
