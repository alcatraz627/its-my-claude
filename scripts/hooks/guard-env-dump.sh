#!/usr/bin/env bash
# Stops an agent from printing the whole shell environment into a transcript.
#
# The owner keeps live API tokens exported (Render, Linear, GitHub, Slack) so
# tools work without setup. A bare `env` or `printenv` copies every one of them
# into the session log. Reading one named variable stays allowed; only the
# whole-environment dump is refused (owner ruling 2026-10-14).
#
# PreToolUse on Bash. Refuses: env, printenv, set, export, export -p,
# declare -x/-p, typeset -x with no further arguments, alone or piped; pm2 and
# ps and docker inspect views that show process environments; gcloud commands
# that print an access or identity token, unless captured in $( ) or a file;
# and any of the process views when run on another machine through ssh.
# Mute: touch ~/.claude/.no-env-dump-gate

set -uo pipefail

[ -f "$HOME/.claude/.no-env-dump-gate" ] && exit 0
input=$(cat 2>/dev/null)
cmd=$(printf '%s' "$input" | jq -r 'select(.tool_name == "Bash") | .tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

raw="$cmd"

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

# gcloud commands whose whole output is a credential. Fine when the token is
# captured, in $( ) or backticks or redirected to a file; refused when it
# would print.
TOKEN_CMD='(print-[a-z]+-token|config-helper)'
# A gcloud token command at a command position. `$(` is not a command
# position: that is the captured form.
GCLOUD_AT="(^|[;&|]|\n|[^\$]\()[[:space:]]*gcloud[[:space:]][^;&|)]*${TOKEN_CMD}[^;&|)]*"
# Standard output sent to a file (not stderr alone, not a descriptor).
STDOUT_TO_FILE='(^|[[:space:]]|1)>>?[[:space:]]*[^&>[:space:]]'

leaks_token() {
  local seg
  while IFS= read -r seg; do
    [ -n "$seg" ] || continue
    printf '%s' "$seg" | grep -qE "$STDOUT_TO_FILE" || return 0
  done < <(printf '%s' "$cmd" | sed -E 's/&>/ 1>/g' | grep -oE "$GCLOUD_AT")
  # A captured token handed straight to echo or printf is printed anyway.
  printf '%s' "$raw" | grep -qE "(^|[;&|(]|\n)[[:space:]]*(echo|printf)[[:space:]][^;&|]*(\\\$\(|\`)[[:space:]]*gcloud[[:space:]][^)\`]*${TOKEN_CMD}" && return 0
  return 1
}

# The command ssh runs on the other machine is a command like any other, even
# though it is quoted in the local line.
remote_dumps() {
  local remote
  while IFS= read -r remote; do
    [ -n "$remote" ] || continue
    printf '%s' "$remote" | grep -qE "$DUMP|$PROC" && return 0
  done < <(printf '%s' "$raw" | python3 "$HOME/.claude/scripts/hooks/ssh-remote-cmd.py" 2>/dev/null)
  return 1
}

if printf '%s' "$cmd" | grep -qE "$DUMP|$PROC"; then :
elif leaks_token; then :
elif remote_dumps; then :
else exit 0
fi

reason="[env-dump] Refused: this prints the whole environment, which can still hold live secrets (the Claude process inherits the owner's terminal). A dump copies them into the transcript. Read one variable instead: printenv NAME, or check it exists without printing it: [ -n \"\$NAME\" ] && echo set. Agent shells carry no Linear, Render, Slack or GitHub token by design; when a command needs one, run it as: with-token NAME -- <command> (see ~/.claude/features/api-tokens.md). Owner ruling 2026-10-14. If this blocks real work, tell the owner rather than working around it."
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-env-dump --action block --heeded unknown >/dev/null 2>&1 || true
jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
