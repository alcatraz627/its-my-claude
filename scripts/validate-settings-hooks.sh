#!/bin/bash
# Validates ~/.claude/settings.json hook entries against the documented schema.
# Each entry inside hooks.<EventName>[*] must have a `hooks` array. Common
# regression: installers append a bare {command, type} object instead of
# wrapping it in {hooks: [{type, command}]}, which /doctor flags as
# "Expected array, but received undefined".
# Non-blocking — surfaces a warning via SessionStart additionalContext when
# drift is detected, and stays silent when settings are clean.

set -u
SETTINGS="$HOME/.claude/settings.json"
[ -f "$SETTINGS" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

malformed=$(jq -r '
  [.hooks | to_entries[] | .key as $event
    | .value | to_entries[]
    | select(.value.hooks == null)
    | "hooks.\($event)[\(.key)]"]
  | .[]
' "$SETTINGS" 2>/dev/null)

[ -z "$malformed" ] && exit 0

count=$(printf '%s\n' "$malformed" | wc -l | tr -d ' ')
noun=$([ "$count" -eq 1 ] && echo "entry" || echo "entries")
indented=$(printf '%s\n' "$malformed" | sed 's/^/    /')

msg=$(printf '⚠ settings.json hook schema drift: %d malformed %s\n%s\n\nEach entry must be wrapped: { "hooks": [ { "type": "command", "command": "..." } ] }\nFix by editing ~/.claude/settings.json or removing the offending entries.' \
  "$count" "$noun" "$indented")

jq -n --arg ctx "$msg" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'

exit 0
