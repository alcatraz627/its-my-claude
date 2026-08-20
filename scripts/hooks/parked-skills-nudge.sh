#!/usr/bin/env bash
# parked-skills-nudge.sh — SessionStart, the owner's two-way parked-skills check.
#
# When a session opens in a real project (not the gcc), this asks parked.sh two
# questions and surfaces the answers as one 🪝 hook box: which parked skills match
# this project's markers (offer the copy), and which friction shapes here have hit
# the twice threshold (ask the owner about commissioning a skill). Silent when
# both are empty, which is most sessions.
# Mute: touch ~/.claude/.no-parked-nudge
set -uo pipefail
[ -f "$HOME/.claude/.no-parked-nudge" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
PARKED_SH="${PARKED_SH:-$HOME/.claude/scripts/parked/parked.sh}"
[ -f "$PARKED_SH" ] || exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
cwd=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd="$PWD"
case "$cwd" in "$HOME/.claude"*) exit 0;; esac
[ -d "$cwd/.git" ] || [ -d "$cwd/.claude" ] || exit 0

matches=$(bash "$PARKED_SH" match --project "$cwd" 2>/dev/null | head -6)
# Skills already copied into the project stop being suggestions.
if [ -n "$matches" ]; then
  matches=$(printf '%s\n' "$matches" | while IFS= read -r m; do
    [ -d "$cwd/.claude/skills/$m" ] || printf '%s\n' "$m"
  done)
fi
friction=$(bash "$PARKED_SH" friction check --project "$cwd" 2>/dev/null | head -4)
[ -z "$matches" ] && [ -z "$friction" ] && exit 0

body=""
[ -n "$matches" ] && body="│ parked skills matching this project: $(printf '%s' "$matches" | tr '\n' ' ')
│   copy one in: bash ~/.claude/scripts/parked/parked.sh copy <name> --to $cwd
"
[ -n "$friction" ] && body="${body}│ friction shapes here at the twice threshold (owner ruling: ask about a skill):
$(printf '%s\n' "$friction" | sed 's/^/│  /')
"
msg="┌─ 🪝 hook · parked-skills ──────────────────────── two-way check ──
${body}│ ▸ $HOME/.claude/skills-parked/INDEX.md
│ → weigh these against the session's goal; suggest to the owner in one line, never auto-copy
└────────────────────────────────────────────────────────────────────
Surface this box verbatim to the user (rules/surface-hook-nudges-to-user.md), then continue."

jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}' 2>/dev/null || true
exit 0
