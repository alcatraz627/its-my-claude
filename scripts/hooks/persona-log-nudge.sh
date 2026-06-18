#!/usr/bin/env bash
# Nudges the agent to log a working-mode persona usage it appears to have adopted
# but not recorded.
#
# Dispatch personas log mechanically from their dispatch script/skill. Working-
# mode personas are adopted by reading the file, so their usage log is a
# convention — and a convention with no gate gets skipped (the
# skill-spec-update-not-honored lesson). This PostToolUse hook is that gate: once
# a session has Read a working-mode persona file and done a little work without
# writing a persona-log event, it emits ONE advisory reminder. PostToolUse is the
# channel deliberately chosen — Stop-time advisory output is swallowed, but
# PostToolUse additionalContext reaches the agent mid-session.
#
# Runtime contract: PostToolUse hook. Reads {session_id, tool_name, tool_input}
# on stdin. State: /tmp/claude-personalog-<sid8> (persona=, since=, nudged=).
# Mute: touch ~/.claude/personas/usage/.nudge-off. Always exits 0.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
[[ -f "$HOME/.claude/personas/usage/.nudge-off" ]] && exit 0
input=$(cat 2>/dev/null) || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[[ -z "$sid" ]] && exit 0
STATE="/tmp/claude-personalog-${sid:0:8}"

persona=""; since=0; nudged=0
if [[ -f "$STATE" ]]; then
  persona=$(grep '^persona=' "$STATE" 2>/dev/null | cut -d= -f2-)
  since=$(grep   '^since='   "$STATE" 2>/dev/null | cut -d= -f2); since=${since:-0}
  nudged=$(grep  '^nudged='  "$STATE" 2>/dev/null | cut -d= -f2); nudged=${nudged:-0}
fi
[[ "$nudged" == "1" ]] && exit 0   # already nudged this session — cheap exit

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# Detect adoption: a Read of a working-mode persona file (exclude README + usage/).
if [[ "$tool" == "Read" && "$path" == *"/.claude/personas/"*.md ]]; then
  base="${path##*/}"; name="${base%.md}"
  if [[ "$name" != "README" && "$path" != *"/personas/usage/"* ]]; then
    # Only working-mode personas log by convention; dispatch ones log mechanically.
    if grep -qx 'type: working-mode' "$path" 2>/dev/null; then
      persona="$name"
    fi
  fi
fi

# Count tool calls once a persona has been adopted.
[[ -n "$persona" ]] && since=$(( since + 1 ))
{ echo "persona=$persona"; echo "since=$since"; echo "nudged=$nudged"; } > "$STATE"

# Fire once, after a few tool calls of work, if nothing's been logged this session.
THRESH="${PERSONA_LOG_NUDGE_AFTER:-5}"
[[ -z "$persona" ]] && exit 0
(( since < THRESH )) && exit 0

EVENTS="$HOME/.claude/personas/usage/events.jsonl"
if [[ -f "$EVENTS" ]] && grep -q "\"session\":\"${sid}\"" "$EVENTS" 2>/dev/null; then
  exit 0   # already logged something this session
fi

{ echo "persona=$persona"; echo "since=$since"; echo "nudged=1"; } > "$STATE"
jq -nc --arg p "$persona" --arg m "[persona] You've been working under the ${persona} persona but haven't logged it. Before you wrap up, record it for the efficacy trail: bash ~/.claude/scripts/persona-log.sh record ${persona} --mode adopted --task \"<1-line>\" --outcome accepted|revised|discarded --loop converged|partial --note \"<what worked / what it missed>\". (Advisory; once per session. Mute: touch ~/.claude/personas/usage/.nudge-off)" \
  '{additionalContext:$m}'
exit 0
