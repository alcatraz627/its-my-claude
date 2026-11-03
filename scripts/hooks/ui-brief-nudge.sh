#!/usr/bin/env bash
# Hands an agent the UI brief the first time it edits a page, because the guidance only
# worked when someone remembered to open it. The service hub's builder read none of it
# until the owner had rejected the page (owner, 2026-11-01: "auto-fire best practices when
# building ui tools for any kind"). A nudge and never a block.
#
# Fires once per project for each agent, so a sub-agent building a page gets it too.
# PreToolUse on Edit, Write and MultiEdit. Mute: touch ~/.claude/.no-ui-brief-nudge
[ -f "$HOME/.claude/.no-ui-brief-nudge" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$file" ] || exit 0

case "$file" in
  *.html|*.htm|*.css|*.scss|*.jsx|*.tsx|*.vue|*.svelte) ;;
  # Plain JS is mostly not UI, so it counts only inside a folder that holds pages.
  */page/*.js|*/pages/*.js|*/public/*.js|*/static/*.js|*/views/*.js|*/components/*.js|*/ui/*.js) ;;
  *) exit 0 ;;
esac
case "$file" in
  */node_modules/*|*/dist/*|*/build/*|*/.next/*|*/vendor/*|*/coverage/*|*.test.*|*.spec.*|*.min.*|*/tests/*|*/__tests__/*|*/fixtures/*|*/.claude/output/*|*/assets/reports/*|*/scratchpad/*) exit 0 ;;
esac

agent=$(printf '%s' "$input" | jq -r '.agent_id // "main"' 2>/dev/null)
dir=$(dirname "$file")
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root="$dir"
marks="$HOME/.claude/state/ui-brief-nudged"
key=$(printf '%s|%s|%s' "$sid" "$agent" "$root" | shasum | cut -c1-16)
[ -f "$marks/$key" ] && exit 0
mkdir -p "$marks" 2>/dev/null
touch "$marks/$key" 2>/dev/null

jq -cn --arg c "UI edit: read ~/.claude/conventions/ui-brief.md before going further, small tools included. The page check proves a page works, not that it reads well. The most missed: look up what the owner already rejected on this surface; colour means state, so no brand fill down a list; say what each value is; render md and lg at full width and under OS light; induce crash, empty, busy and failed-read states with a stand-in API; read the render." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$c}}'
exit 0
