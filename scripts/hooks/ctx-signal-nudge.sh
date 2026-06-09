#!/usr/bin/env bash
# Surfaces a "you may be at a task boundary" nudge so the agent can choose
# between staying in the session, /compact, or /core-dump + /clear.
#
# A shell hook can't read context-window %, but it can spot the two cheap signals
# that most reliably mark a boundary: the working directory changed (you switched
# project/task) or you returned after a long idle (the prompt cache is cold, so a
# /clear is "free" anyway). When either trips it emits ONE advisory line; the
# agent decides. Rate-limited to once per 15 min so it never becomes noise.
#
# Runtime contract: UserPromptSubmit hook. Reads the payload on stdin
# ({session_id, cwd, prompt, ...}); prints a single {additionalContext} JSON
# object when a boundary signal fires, nothing otherwise. State lives in
# /tmp/claude-ctxsig-<sid> (last turn's timestamp + cwd + last-nudge time).
# Always exits 0 — an advisory hook must never block a prompt.

set -uo pipefail

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[[ -z "$sid" ]] && exit 0

now=$(date +%s)
STATE="/tmp/claude-ctxsig-${sid:0:8}"

last_ts=0; last_cwd=""; last_nudge=0
if [[ -f "$STATE" ]]; then
  last_ts=$(grep    '^ts='    "$STATE" 2>/dev/null | cut -d= -f2);  last_ts=${last_ts:-0}
  last_cwd=$(grep   '^cwd='   "$STATE" 2>/dev/null | cut -d= -f2-)
  last_nudge=$(grep '^nudge=' "$STATE" 2>/dev/null | cut -d= -f2);  last_nudge=${last_nudge:-0}
fi

# Persist this turn's state for the next comparison (preserve last_nudge).
{ echo "ts=$now"; echo "cwd=$cwd"; echo "nudge=$last_nudge"; } > "$STATE"

# First turn of a session has nothing to compare against.
(( last_ts == 0 )) && exit 0

idle=$(( now - last_ts ))
since_nudge=$(( now - last_nudge ))

reason=""
if [[ -n "$last_cwd" && "$cwd" != "$last_cwd" ]]; then
  reason="working directory changed (${last_cwd##*/} → ${cwd##*/})"
elif (( idle > 1800 )); then
  reason="resumed after $(( idle / 60 ))-min idle (prompt cache is cold — a /clear costs nothing now)"
fi

# Fire at most once per 15 min.
if [[ -n "$reason" ]] && (( since_nudge > 900 )); then
  { echo "ts=$now"; echo "cwd=$cwd"; echo "nudge=$now"; } > "$STATE"
  jq -nc --arg m "[ctx-signal] Possible task boundary: ${reason}. If switching focus, /core-dump + /clear gives a clean low-token context; if continuing the same thread, ignore this." \
    '{additionalContext:$m}'
fi

exit 0
