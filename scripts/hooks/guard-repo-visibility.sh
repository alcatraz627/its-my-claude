#!/usr/bin/env bash
# Keeps every repo in the versable-git GitHub org private.
#
# The global default is public repos, but the owner ruled (2026-08-21) that the
# versable-git org is the exception: a public repo there leaks company code and
# is also silently cut off from the org's private reusable CI workflows
# (versable-forge-v6 was found public; its CI join failed with zero jobs).
#
# PreToolUse on Bash and on the GitHub MCP create_repository tool. Blocks:
#   gh repo create versable-git/<name> --public
#   gh repo edit versable-git/<name> --visibility public
#   mcp create_repository with organization versable-git and private not true
# Everything else passes. Mute: touch ~/.claude/.no-repo-visibility-gate

set -uo pipefail
[ -f "$HOME/.claude/.no-repo-visibility-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
ORG="versable-git"

block() {
  jq -cn --arg r "⛔ repo-visibility: $1 Every repo in the $ORG org is private (owner ruling 2026-08-21; rules/git.md). Use --private (gh repo create) or private: true (MCP). Mute: touch ~/.claude/.no-repo-visibility-gate" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}'
  exit 0
}

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
case "$tool" in
  mcp__github__create_repository)
    org=$(printf '%s' "$input" | jq -r '.tool_input.organization // .tool_input.org // empty')
    priv=$(printf '%s' "$input" | jq -r '.tool_input.private // false')
    [ "$org" = "$ORG" ] && [ "$priv" != "true" ] && block "this creates a public repo in $ORG."
    exit 0 ;;
  Bash) ;;
  *) exit 0 ;;
esac

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
printf '%s' "$cmd" | rg -q '\bgh\s+repo\s+(create|edit)\b' 2>/dev/null || exit 0
printf '%s' "$cmd" | rg -q "\b${ORG}/" 2>/dev/null || exit 0
if printf '%s' "$cmd" | rg -q '\bgh\s+repo\s+create\b' 2>/dev/null \
   && printf '%s' "$cmd" | rg -q -- '--public\b' 2>/dev/null; then
  block "this gh repo create makes a public repo in $ORG."
fi
if printf '%s' "$cmd" | rg -q '\bgh\s+repo\s+edit\b' 2>/dev/null \
   && printf '%s' "$cmd" | rg -q -- '--visibility[= ]+public\b' 2>/dev/null; then
  block "this gh repo edit makes a repo in $ORG public."
fi
exit 0
