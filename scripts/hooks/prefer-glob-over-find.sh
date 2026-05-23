#!/usr/bin/env bash
# prefer-glob-over-find.sh — PreToolUse[Bash] nudge.
# `find X -name Y` → Glob tool. Critical because Bash sandbox SILENTLY
# no-ops `find` on /tmp + ~/ (we hit this 5+ times during the gcc audit).
#
# Skip: -mtime, -exec, -prune, -delete, -newer, -size, -type pruned-cases
# (those are legitimate find-only features).
#
# Mute: touch ~/.claude/.no-find-hint

set -uo pipefail
[[ -f "$HOME/.claude/.no-find-hint" ]] && exit 0

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# Skip complex find features Glob can't replace
echo "$CMD" | rg -q 'find\s.*-(mtime|exec|prune|delete|newer|size|type\s+[df])\b' 2>/dev/null && exit 0

# Match simple `find <path> -name <pattern>` (Glob's exact use case)
if echo "$CMD" | rg -q '(^|\s|;|&&|\|\|)\s*find\s+\S+\s+-name\s+\S+' 2>/dev/null; then
  cat <<'EOF'
[hint] `find -name` → consider the Glob tool. Glob is faster for shallow
patterns AND sorts by mtime by default. Critical: Bash sandbox SILENTLY
no-ops `find` on /tmp + ~/ paths (returns 0 results instead of erroring) —
this trap bit us 5+ times during the gcc audit. Glob works correctly there.
Mute: touch ~/.claude/.no-find-hint
EOF
fi
exit 0
