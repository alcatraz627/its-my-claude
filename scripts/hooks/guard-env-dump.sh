#!/usr/bin/env bash
# Stops an agent from printing the whole shell environment into a transcript.
#
# The owner keeps live API tokens exported (Render, Linear, GitHub, Slack) so
# tools work without setup. A bare `env` or `printenv` copies every one of them
# into the session log. Reading one named variable stays allowed; only the
# whole-environment dump is refused (owner ruling 2026-10-14).
#
# PreToolUse on Bash. Refuses: env, printenv, set, export, export -p,
# declare -x/-p, typeset -x with no further arguments, alone or piped.
# Mute: touch ~/.claude/.no-env-dump-gate

set -uo pipefail

[ -f "$HOME/.claude/.no-env-dump-gate" ] && exit 0
input=$(cat 2>/dev/null)
cmd=$(printf '%s' "$input" | jq -r 'select(.tool_name == "Bash") | .tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# Quoted text and heredoc bodies are prose, not commands.
SCAN="$HOME/.claude/scripts/hooks/strip-payloads.py"
if [ -x "$SCAN" ]; then
  scanned=$(printf '%s' "$cmd" | python3 "$SCAN" 2>/dev/null)
  [ -n "$scanned" ] && cmd="$scanned"
fi

# A segment that is only the dump verb (plus a listing flag), ending at a
# separator, a pipe, a redirect or the end of the command.
DUMP='(^|[;&|(]|\n)[[:space:]]*(/usr/bin/)?(env|printenv|set|export([[:space:]]+-p)?|declare[[:space:]]+-[xp]+|typeset[[:space:]]+-x)[[:space:]]*($|[;&|)>]|\n)'
# Process inspectors that print each process's environment: pm2's detail
# verbs, ps with the macOS environment flags (-e, -E or the e keyword), and
# docker inspect.
PROC='(^|[;&|(]|\n)[[:space:]]*(pm2[[:space:]]+(jlist|prettylist|env|show|describe)|ps[[:space:]]+(-[a-zA-Z]*[eE][a-zA-Z]*|[a-z]*e[a-z]*)([[:space:]]|$)|docker[[:space:]]+(container[[:space:]]+)?inspect)'
printf '%s' "$cmd" | grep -qE "$DUMP|$PROC" || exit 0

reason="[env-dump] Refused: this prints the whole environment, which holds live API tokens the owner keeps exported so tools work (Render, Linear, GitHub, Slack). A dump copies them into the transcript. Read one variable instead: printenv NAME, or check it exists without printing it: [ -n \"\$NAME\" ] && echo set. Owner ruling 2026-10-14. If this blocks real work, tell the owner rather than working around it."
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-env-dump --action block --heeded unknown >/dev/null 2>&1 || true
jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
