#!/usr/bin/env bash
# prefer-tmp-py-over-inline.sh — PreToolUse[Bash] nudge, with heed measurement.
# Multi-line `python3 -c '...'` has no traceback line numbers in Bash output
# and is shell-quoting-sensitive. Suggests /tmp/<slug>.py for debuggability.
#
# Threshold: >5 newlines in the -c arg. Short one-liners are fine.
#
# Heed measurement (added 2026-07-18): this was the highest-volume nudge in the
# whole config with zero heed data — 696 fires, never once checked. It now records
# whether the nudge worked, mirroring the Stop-hook pattern in prose-smell-stop.sh
# but adapted for a PreToolUse gate:
#   - on a nudge, drop a session-scoped marker.
#   - on the NEXT python3 invocation in that session, resolve it: switching to a
#     script file (`python3 foo.py`) is heeded=true; another inline `python3 -c`
#     with >5 newlines is heeded=false. Anything else leaves the marker for later.
# The resolve check runs BEFORE the nudge's own early-exit, because a heeded run
# has no `-c` and would otherwise exit unrecorded. A nudge that is simply never
# followed by more python is left unresolved on purpose — an honest gap beats a
# guessed verdict (the heed rate reads over observed follow-ups only).
#
# Mute: touch ~/.claude/.no-inline-py-hint
# Tests: scripts/hooks/prefer-tmp-py-over-inline.test.sh

set -uo pipefail
[[ -f "$HOME/.claude/.no-inline-py-hint" ]] && exit 0

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# Session-scoped marker, same derivation as prose-smell-stop.sh.
sid="${CLAUDE_SESSION_ID:-}"
[[ -z "$sid" && -f "$HOME/.claude/.current-session-id" ]] && sid=$(cat "$HOME/.claude/.current-session-id" 2>/dev/null)
sid8="${sid:0:8}"; [[ -z "$sid8" ]] && sid8="nosid"
MARK="/tmp/claude-tmp-py-nudge-${sid8}"

# Classify the current command's relationship to inline python. python3 itself
# parses it, so multi-line -c bodies and quoting don't fool a bash regex.
kind=$(python3 - "$CMD" <<'PY' 2>/dev/null
import sys, re
cmd = sys.argv[1]
# inline: python3 -c '<body>' — capture the body to count newlines
m = re.search(r"python3?\s+-c\s+(['\"])((?:(?!\1).|\n)*)\1", cmd)
if m:
    print("inline", m.group(2).count("\n"))
    sys.exit()
# script: python3 <something>.py  (a file invocation, not -c)
if re.search(r"python3?\s+(?!-c\b)[^\s]*\.py(\s|$)", cmd):
    print("script", 0)
    sys.exit()
print("other", 0)
PY
)
verb="${kind%% *}"; nl="${kind##* }"; verb="${verb:-other}"; nl="${nl:-0}"

# --- Heed resolution: settle a prior nudge based on what happened next. ---
# Only fires when a marker from an earlier nudge exists AND the current command is
# a python invocation we can read a verdict from. "other" commands leave it alone.
if [[ -f "$MARK" ]]; then
  if [[ "$verb" == "script" ]]; then
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prefer-tmp-py-over-inline \
      --heed-of "prefer-tmp-py-over-inline:$sid8" --heeded true >/dev/null 2>&1 || true
    rm -f "$MARK" 2>/dev/null || true
  elif [[ "$verb" == "inline" && "$nl" -gt 5 ]]; then
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prefer-tmp-py-over-inline \
      --heed-of "prefer-tmp-py-over-inline:$sid8" --heeded false >/dev/null 2>&1 || true
    rm -f "$MARK" 2>/dev/null || true    # a fresh nudge below re-drops it
  fi
fi

# --- Nudge: same trigger as before (inline python3 -c with >5 newlines). ---
[[ "$verb" == "inline" && "$nl" -gt 5 ]] || exit 0

msg="[hint] python3 -c with $nl newlines: tracebacks show \"<string>\" instead of real line numbers. Prefer writing the script to /tmp/<slug>.py (heredoc) then 'python3 /tmp/<slug>.py' — real line numbers in tracebacks, re-runnable, no shell-quote bugs. (mute: touch ~/.claude/.no-inline-py-hint)  →→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."
jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
printf '%s' "$sid8" > "$MARK" 2>/dev/null || true    # arm heed detection for the next python run
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prefer-tmp-py-over-inline --action nudge --heeded unknown >/dev/null 2>&1 || true
exit 0
