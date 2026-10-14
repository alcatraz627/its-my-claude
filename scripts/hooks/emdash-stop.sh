#!/usr/bin/env bash
# lifecycle: tune-able hook (owner ruling D3, 2026-10-15)
# instrument: self (clean re-emit records heeded:true)
# review-by: 2026-11-15
# retire-if: heed-rate < 50% over 100 fires
# emdash-stop.sh — Stop hook: a reply to the owner that contains even one em-dash
# is sent back to be rewritten.
#
# The owner reads an em-dash as machine prose and has asked for a budget of zero
# (rules/audience-aware-writing.md). prose-smell-stop.sh used to count it as one
# tell among several and blocked only when two co-occurred, so a lone em-dash
# always slipped through. This hook owns the em-dash alone.
#
# Counts only prose: fenced code, inline code and blockquotes are stripped first,
# so a quoted file, a command or a pasted block carrying the character is fine.
# Judges the Stop input's last_assistant_message (the transcript tail lags one
# message at Stop time, see hook_last_assistant_text in hook-common.sh).
#
# Loop-safe: a reply is blocked once. An identical re-emit steps aside with a note
# instead of blocking again, and three consecutive blocks in a row end the loop
# even when the wording keeps changing. A clean reply after a block records heeded.
#
# Mute: EMDASH_OFF=1 (this process) · touch ~/.claude/.no-emdash-gate (machine-wide,
# ALL sessions until removed). Telemetry: warn-log.sh --hook emdash.

set -uo pipefail
[ "${EMDASH_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-emdash-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0
command -v shasum >/dev/null 2>&1 || exit 0

HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"
hook_snoozed emdash && exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
sid8=$(hook_sid8 "$sid")

text=$(hook_last_assistant_text "$input" "$tp")
[ -n "$text" ] || exit 0

prose=$(printf '%s\n' "$text" \
  | awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}' \
  | sed -e 's/`[^`]*`//g' -e '/^[[:space:]]*>/d')

LOG="$HOME/.claude/scripts/hooks/warn-log.sh"
MARK="/tmp/claude-emdash-${sid8}"   # "<signature> <consecutive blocks>"

n=$(printf '%s' "$prose" | rg -o '—' 2>/dev/null | wc -l | tr -d ' ')
if [ "${n:-0}" -lt 1 ]; then
  # A lingering marker means the reply that was blocked has since been fixed.
  if [ -f "$MARK" ]; then
    bash "$LOG" --hook emdash --heed-of "emdash:$sid8" --heeded true >/dev/null 2>&1 || true
    rm -f "$MARK" 2>/dev/null || true
  fi
  exit 0
fi

sig=$(printf '%s' "$prose" | shasum 2>/dev/null | awk '{print $1}')
prev_sig=""; prev_n=0
if [ -f "$MARK" ]; then read -r prev_sig prev_n < "$MARK" 2>/dev/null || true; fi
case "$prev_n" in ''|*[!0-9]*) prev_n=0 ;; esac

if [ -n "$sig" ] && [ "$sig" = "$prev_sig" ]; then
  bash "$LOG" --hook emdash --heed-of "emdash:$sid8" --heeded false >/dev/null 2>&1 || true
  jq -cn '{systemMessage:"⚠ emdash (not re-blocking the identical reply): an em-dash is still in the prose. Mute: touch ~/.claude/.no-emdash-gate"}' 2>/dev/null || true
  exit 0
fi
if [ "$prev_n" -ge 3 ]; then
  bash "$LOG" --hook emdash --heed-of "emdash:$sid8" --heeded false >/dev/null 2>&1 || true
  jq -cn '{systemMessage:"⚠ emdash (three blocks in a row, stepping aside): an em-dash is still in the prose. Mute: touch ~/.claude/.no-emdash-gate"}' 2>/dev/null || true
  exit 0
fi

printf '%s %s' "$sig" $((prev_n + 1)) > "$MARK" 2>/dev/null || true
first=$(printf '%s\n' "$prose" | rg -m1 '—' 2>/dev/null | cut -c1-90)
bash "$LOG" --hook emdash --action block --heeded unknown --detail "${n} em-dash" >/dev/null 2>&1 || true
reason="emdash: the reply has ${n} em-dash(es) in prose, and the owner's budget is zero. First one: \"${first}\". Re-emit the same reply with commas, periods, parentheses or 'and' instead; code, inline code and blockquotes may keep the character. Mute: touch ~/.claude/.no-emdash-gate (machine-wide) or EMDASH_OFF=1 (this process)."
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
