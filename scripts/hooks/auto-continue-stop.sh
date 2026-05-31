#!/usr/bin/env bash
# auto-continue-stop.sh — Stop hook for opt-in, per-session error recovery.
#
# When a session the user enabled (via auto-continue.sh on) ends a turn that was
# cut short by a TRANSIENT API error (rate limit / 5xx / overloaded / timeout)
# that Claude Code did not recover from, this waits a cooldown and tells the
# agent to resume — using the native Stop `decision:block` lever. No keystroke
# injection, no dependency on Claude's servers for the scheduling (the delay is a
# local sleep). Clean turn-ends are NOT re-driven: the session stops and waits.
#
# Loop safety: a consecutive-error STREAK, capped at max_retries (default 3). The
# streak resets to 0 the instant a turn completes cleanly (progress = the error
# was transient). So a blip costs one retry and resets; a sustained outage tries
# max_retries times, gives up, and waits for you — never an endless loop.
#
# Inert unless a per-session flag exists; every decision is logged.
# Enable:  bash ~/.claude/scripts/auto-continue.sh on [max_retries] [cooldown]
# Disable: bash ~/.claude/scripts/auto-continue.sh off

set -uo pipefail
DIR="$HOME/.claude/auto-continue"

input=$(cat 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
flag="$DIR/${sid:0:8}.json"
[ -f "$flag" ] || exit 0                      # not opted in → normal stop

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$1" >> "$DIR/${sid:0:8}.log" 2>/dev/null || true; }
set_field() { local tmp; tmp=$(mktemp 2>/dev/null) && jq "$1" "$flag" > "$tmp" 2>/dev/null && mv "$tmp" "$flag"; }

streak=$(jq -r '.streak // 0'        "$flag" 2>/dev/null)
maxr=$(jq -r   '.max_retries // 3'   "$flag" 2>/dev/null)
cooldown=$(jq -r '.cooldown // 30'   "$flag" 2>/dev/null)

tx=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$tx" ] && [ -f "$tx" ] || { log "no transcript → normal stop"; exit 0; }

# Did the tail of the transcript show a transient, unrecovered API error? Scan
# only the last slice so a stale earlier error doesn't keep re-firing.
tail_txt=$(tail -c 6000 "$tx" 2>/dev/null)
if ! printf '%s' "$tail_txt" | rg -qi 'rate.?limit|overloaded|"(status|code)": ?(429|5[0-9][0-9])|api_error|request timed out|ETIMEDOUT|ECONNRESET'; then
  # clean turn-end = progress → reset the error streak, then stop normally
  [ "${streak:-0}" -gt 0 ] 2>/dev/null && { set_field '.streak = 0'; log "clean turn-end → streak reset, normal stop"; } || true
  exit 0
fi

if [ "${streak:-0}" -ge "${maxr:-3}" ] 2>/dev/null; then
  log "transient error but streak ${streak} ≥ max_retries ${maxr} → giving up, waiting for you"
  exit 0
fi

next=$((streak + 1))
set_field ".streak = $next"
log "transient error → cooldown ${cooldown}s then re-drive (attempt ${next}/${maxr})"
sleep "${cooldown:-30}" 2>/dev/null || true

jq -cn --arg r "Your previous turn was cut short by a transient API error (rate-limit / 5xx / timeout) and the cooldown has passed. Resume exactly where you left off and finish the task. [auto-continue retry ${next} of ${maxr} for this error run; the counter resets as soon as a turn completes cleanly.]" \
  '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
