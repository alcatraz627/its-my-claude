#!/usr/bin/env bash
# SessionStart injector: inside a versable-git clone, tells the session which
# branch is staging, which is release, and which GCP project the repo runs in,
# so no agent has to ask the owner. Prints nothing anywhere else.
# Registered in session-mgmt/sessionstart-inject.sh. Mute: touch ~/.claude/.no-versable-envs

[ -f "$HOME/.claude/.no-versable-envs" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

cwd=$(jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0

line=$(cd "$cwd" && python3 "$HOME/.claude/scripts/versable/envs.py" --brief 2>/dev/null)
[ -n "$line" ] || exit 0

jq -n --arg c "[versable envs] $line" '{additionalContext: $c}'
