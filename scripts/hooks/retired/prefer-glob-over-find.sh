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
  # Confirm this INVOKES find rather than merely quoting it, e.g. a message or a
  # doc string that happens to read `find . -name '*.md'`. Second stage only, so
  # the common path pays nothing. Fails open: no helper means nudge as before.
  if [ -r "$HOME/.claude/scripts/hooks/hook-common.sh" ]; then
    . "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || true
    type hook_cmd_skeleton >/dev/null 2>&1 &&
      ! printf '%s' "$CMD" | hook_cmd_skeleton \
        | rg -q '(^|\s|;|&&|\|\|)\s*find\s+\S+\s+-name\s+\S+' 2>/dev/null && exit 0
  fi
  # Ledger only: registered async on PreToolUse, whose stdout the harness never
  # returns (canary 2026-09-05; owner ruling: strip the payload, keep the telemetry).
  # To revive the nudge, register synchronous and emit additionalContext here.
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prefer-glob-over-find --action nudge --heeded unknown >/dev/null 2>&1 || true
fi
exit 0
