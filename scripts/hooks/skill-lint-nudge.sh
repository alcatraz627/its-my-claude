#!/usr/bin/env bash
# skill-lint-nudge.sh — PostToolUse[Edit|Write|MultiEdit], SYNCHRONOUS nudge.
#
# Runs scripts/skill-lint.py on a SKILL.md the moment it is written, and hands
# the findings back to the agent as additionalContext. Warn tier on purpose: a
# lint false positive costs one glance, and the failures it catches are the
# silent kind (a frontmatter field the harness ignores, a description the roster
# will drop, a relative skill path the nested-gcc guard refuses), so a nudge at
# write time is worth more than a block. For a skill under ~/.claude/skills/ it
# also regenerates skills/00-index.md, so a new or renamed skill reaches
# /pick-skill's menu without anyone remembering to run the script.
#
# Output: additionalContext on stdout. Exit 0 always. Silent when the file is not
# a SKILL.md, when the lint is clean, or when anything it needs is missing.
# Mute: touch ~/.claude/.no-skill-lint-gate
set -uo pipefail
[ -f "$HOME/.claude/.no-skill-lint-gate" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
LINT="${SKILL_LINT:-$HOME/.claude/scripts/skill-lint.py}"
INDEX="${SKILLS_INDEX:-$HOME/.claude/scripts/skills-index.sh}"
[ -f "$LINT" ] || exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
echo "$INPUT" | jq empty 2>/dev/null || exit 0
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in Edit | Write | MultiEdit) ;; *) exit 0 ;; esac
FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
case "$FP" in */skills/*/SKILL.md) ;; *) exit 0 ;; esac
[ -f "$FP" ] || exit 0

findings=$(python3 "$LINT" "$FP" 2>/dev/null)
rc=$?

# A gcc skill changed: refresh the retrieval menu (idempotent, under a second).
case "$FP" in
  "$HOME"/.claude/skills/*) [ -x "$INDEX" ] || [ -f "$INDEX" ] && bash "$INDEX" >/dev/null 2>&1 || true ;;
esac

[ "$rc" -eq 0 ] && exit 0
[ -z "$findings" ] && exit 0

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook skill-lint-nudge --action nudge --heeded unknown \
  --cwd "$(printf '%s' "$INPUT" | jq -r '.cwd//empty' 2>/dev/null)" --target "$FP" >/dev/null 2>&1 || true

body=$(printf '%s\n' "$findings" | sed "s#^$FP:#  line #" | head -12)
tier="warn"; [ "$rc" -eq 2 ] && tier="error"
msg="[skill-lint] $(basename "$(dirname "$FP")")/SKILL.md has lint findings ($tier tier; the harness silently ignores what it does not understand, so these fail quietly):
$body
Fix what applies (skills/GUIDELINES.md §8 + Authoring Conventions); the description cap is a budget the roster enforces by dropping long ones. Nudge only, never a block. (mute: touch ~/.claude/.no-skill-lint-gate)
→→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."

jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $c}}' 2>/dev/null || true
exit 0
