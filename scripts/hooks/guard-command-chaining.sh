#!/usr/bin/env bash
# guard-command-chaining.sh — PreToolUse[Bash], SYNCHRONOUS, BLOCK tier.
#
# Owner ruling 2026-09-04, re-stated 2026-09-05: one command per Bash call, no
# `&&`, no `;`, no pipe. This enforces it, because prose did not.
#
# WHY THIS BLOCKS RATHER THAN WARNS, which is the bar features/hook-design.md
# sets. Every segment of a compound must match an allow entry, so ONE unlisted
# segment prompts the human about the whole chain. Measured 2026-09-03: 149
# permission prompts in a day against 1 to 6 before, 93 percent of them carrying
# a chaining operator, and 84 of the 149 never ran at all. The cost of a miss is
# not a click. gcc-work, diagnosing it: "They do not merely cost him a click,
# they HALT you until he arrives." A halted overnight session is the whole night.
#
# The worse case is a dispatched sub-agent that chains: the owner then answers a
# dialog for work he never saw dispatched, on a seat he cannot see.
#
# WHY THE MATCHING IS IN PYTHON. `&&`, `;` and `|` all appear constantly inside
# things that are not operators: a regex alternation, a quoted message, an
# escaped find terminator, a jq filter, a heredoc body, a for/while/until loop
# whose semicolons are syntax. A naive grep fires on every one, and the
# zsh-path guard already learned in production that a block whose only
# real-world fire is a false positive is worse than no guard. chain-scan.py
# walks the string tracking quotes, escapes, $( ) depth and heredoc bodies, and
# reports an operator only at top level. Its suite has 19 cases, 13 of them
# false-fire cases, and the quote-tracking guard is mutation-pinned: remove it
# and two tests go red.
#
# Mute: CHAIN_GUARD_OFF=1 (this process) · touch ~/.claude/.no-chain-guard
# (MACHINE-WIDE, every concurrent and future session, until removed).

set -uo pipefail
[ -n "${CHAIN_GUARD_OFF:-}" ] && exit 0
[ -f "$HOME/.claude/.no-chain-guard" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool_name" = "Bash" ] || exit 0
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$command" ] || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)

SCAN="$HOME/.claude/scripts/hooks/chain-scan.py"
hit=$(printf '%s' "$command" | python3 "$SCAN" 2>/dev/null)
rc=$?
if [ "$rc" -ne 0 ]; then
  # Fail open, but never silently: a broken scanner makes this a no-op.
  marker="${TMPDIR:-/tmp}/chain-guard-scanfail-$(date +%Y%m%d)"
  if [ ! -f "$marker" ]; then
    : > "$marker"
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-command-chaining --action muted \
      --detail "scanner failed rc=$rc; guard inactive" --heeded unknown >/dev/null 2>&1 || true
  fi
  exit 0
fi
[ -n "$hit" ] || exit 0

msg="[chaining] This command chains with: ${hit}. One command per Bash call, no && ; or pipe (owner ruling 2026-09-04, rules/shell.md). This is not style: every segment of a compound must match an allow entry, so one unlisted segment prompts the owner about the whole chain AND HALTS THIS SESSION until he answers. On 2026-09-03 that produced 149 prompts in a day, 84 of which never ran. Send the commands separately; the Bash tool keeps its working directory between calls, so 'cd X && cmd' is never needed. To filter output, ask the tool for less (rg -m 5, sed -n '1,40p', git log -5, pytest -q) or redirect to a file in one call and read it in the next. Mute: CHAIN_GUARD_OFF=1 (process) or touch ~/.claude/.no-chain-guard (machine-wide)."

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-command-chaining --action block \
  --cwd "$cwd" --detail "$hit" --heeded unknown >/dev/null 2>&1 || true

jq -n --arg r "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}' 2>/dev/null || true
exit 0
