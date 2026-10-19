#!/usr/bin/env bash
# lifecycle: tune-able hook (owner ruling D6, 2026-10-19)
# instrument: reads the format gate's own block rows (warn-log.sh --hook format-gate)
# review-by: 2026-11-19
# retire-if: the format gate's repeat-block rate does not drop over two weeks
# format-reminder-ups.sh: a one-line reminder, sent only to a session that just
# had a reply bounced by format-gate-stop.sh, so the next replies are written
# right the first time instead of being rewritten.
#
# The gate writes /tmp/claude-format-tripped-<sid8> (ts, classes, cap) on every
# block. This UserPromptSubmit hook reads it and, for the next two prompts after
# a trip, adds one additionalContext line naming only the classes that tripped
# and the length cap in the gate's own words ("prose cap N chars"). A clean
# session gets no output at all. Counting lives in /tmp/claude-format-reminded-<sid8>
# ("<trip ts> <reminders sent>"), so the gate's file is never modified.
#
# Mute: touch ~/.claude/.no-format-gate (same file as the gate) or FORMAT_GATE_OFF=1.
# Never exits non-zero.

set -uo pipefail
[ "${FORMAT_GATE_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-format-gate" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
sid8="${sid:0:8}"

TRIPPED="/tmp/claude-format-tripped-${sid8}"
[ -f "$TRIPPED" ] || exit 0

ts=""; classes=""; cap=""
while IFS='=' read -r k v; do
  case "$k" in ts) ts="$v" ;; classes) classes="$v" ;; cap) cap="$v" ;; esac
done < "$TRIPPED"
[ -n "$ts" ] && [ -n "$classes" ] || exit 0
case "$cap" in ''|*[!0-9]*) cap="${TERSE_LIMIT:-2600}" ;; esac

REMINDED="/tmp/claude-format-reminded-${sid8}"
r_ts=""; r_n=0
if [ -f "$REMINDED" ]; then read -r r_ts r_n < "$REMINDED" 2>/dev/null || true; fi
case "$r_n" in ''|*[!0-9]*) r_n=0 ;; esac
# A newer trip restarts the count.
[ "$r_ts" = "$ts" ] || r_n=0
[ "$r_n" -lt 2 ] || exit 0

parts=""
old_ifs="$IFS"; IFS=','
for c in $classes; do
  case "$c" in
    filename-dot) p="never put a period right after a file path" ;;
    emdash) p="no em-dashes" ;;
    terse-reply) p="prose cap ${cap} chars" ;;
    relpath) p="give the full absolute path of any file you name, at least once" ;;
    *) continue ;;
  esac
  parts="${parts}${parts:+; }${p}"
done
IFS="$old_ifs"
[ -n "$parts" ] || exit 0

printf '%s %s' "$ts" $((r_n + 1)) > "$REMINDED" 2>/dev/null || true
msg="Format gate tripped on your recent reply, so for this reply: ${parts}."
jq -cn --arg m "$msg" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$m}}' 2>/dev/null || true
exit 0
