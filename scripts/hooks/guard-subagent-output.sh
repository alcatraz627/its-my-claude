#!/usr/bin/env bash
# guard-subagent-output.sh — PreToolUse hook on Agent/Task.
#
# When you hand a sub-agent material work — research, an audit, analysis, a
# design, a review — its findings must be written to a file before it returns;
# the return summary is a pointer, not the artifact. Otherwise the work lives
# only in a context that gets compacted away (rules/sub-agent-outputs.md). This
# warns, at dispatch time, when the prompt looks like it asks for material output
# but never tells the agent to persist it.
#
# Graduated from atone slug sub-agent-material-output-left-in-conversation-only
# (S3, worsening despite the rule — reflect shows warned≈72, still recurring).
#
# STAKES-SCALED (atone T1.1). A dispatch can legitimately be a quick lookup
# ("find where X is defined"), so the bar to BLOCK is deliberately high:
#   - high-stakes repo (per stakes-tier.sh) + an EXPLICIT material verb
#     (research / audit / analysis / design / review …) + NO persist instruction
#     at all → BLOCK the dispatch, so a material result can't be lost to
#     compaction. The bare length trigger (a long non-material prompt) and the
#     "write-verb-but-no-path-given" case both stay advisory — only the
#     unambiguous "material work, zero persistence" case blocks.
#   - everything else → the original advisory additionalContext note, exit 0.
# (This file used to be advisory in ALL repos; the MAGI atone-recurrence
# deliberation escalated the unambiguous subset to a stakes-gated block.)
#
# Mute:          touch ~/.claude/.subagent-output-off
# One-shot skip: SUBAGENT_OUTPUT_OFF=1

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
echo "$INPUT" | jq empty 2>/dev/null || exit 0

[ "${SUBAGENT_OUTPUT_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.subagent-output-off" ] && exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in Agent | Task) ;; *) exit 0 ;; esac

# The dispatch prompt — the only thing we can inspect at dispatch time. Both the
# Agent and Task tools carry it as tool_input.prompt; fall back to description.
PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // .tool_input.description // empty')
[ -z "$PROMPT" ] && exit 0

# Heuristic 1 — does this look like MATERIAL work (vs a quick lookup)? Either a
# substantial prompt, or explicit material-output verbs. Lookups stay silent.
material=0
material_verb=0
[ "${#PROMPT}" -gt 400 ] && material=1
if printf '%s' "$PROMPT" | grep -qiE '\b(research|analy[sz]e|analysis|audit|review|synthesi[sz]e|investigate|comprehensive|findings|report|write-?up|proposal|design (doc|the)|deep.?dive|catalogue|catalog)\b'; then
  material=1; material_verb=1
fi
[ "$material" -eq 0 ] && exit 0

# Heuristic 2 — did the prompt ALREADY instruct the agent to persist output?
# Needs BOTH a write/save verb AND a file-ish target (a path or a filename).
has_write=0
printf '%s' "$PROMPT" | grep -qiE '\b(write|save|persist|output)\b.{0,40}\b(to|into|at|disk|file)\b|\bbefore returning\b|\bwrite (it|them|your|the) .{0,30}(file|disk|path)' && has_write=1
has_target=0
printf '%s' "$PROMPT" | grep -qiE '(/[A-Za-z0-9._-]+){2,}|~/|\.claude/output|\b[A-Za-z0-9_-]+\.(md|json|txt|csv|html)\b' && has_target=1

# Complied if it has both a write instruction and a concrete target.
if [ "$has_write" -eq 1 ] && [ "$has_target" -eq 1 ]; then
  exit 0
fi

# High-stakes + an explicit material verb + NO persist instruction at all →
# BLOCK the dispatch. Tighter than the advisory: the bare >400-char trigger (a
# long but non-material prompt) and the write-verb-but-no-path case (intent to
# persist, softer miss) both fall through to the advisory below — only the
# unambiguous "material work, zero persistence" case blocks, and only where a
# lost artifact actually costs.
if [ "$material_verb" -eq 1 ] && [ "$has_write" -eq 0 ]; then
  cwd=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
  [ -z "$cwd" ] && cwd="$PWD"
  stakes=$(bash "$HOME/.claude/scripts/stakes-tier.sh" "$cwd" 2>/dev/null || echo low)
  if [ "$stakes" = "high" ]; then
    reason="⛔ MATERIAL SUB-AGENT DISPATCH WITH NO PERSISTENCE (high-stakes repo) — this prompt asks for material work (research / audit / analysis / design / review) but never tells the agent to write its output to a file. The return summary is a pointer, not the artifact; once this context compacts an un-written result is gone (rules/sub-agent-outputs.md).

  Add to the dispatch prompt: (1) an absolute output path, e.g. <project>/.claude/output/<date>-<slug>/<agent>.md, and (2) 'write your full output to that path BEFORE returning; return a short abstract + the path'. Then verify the file exists before relying on the findings.

A genuine quick lookup mis-flagged as material? Mute: touch ~/.claude/.subagent-output-off"
    jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
    exit 0
  fi
fi

msg="[subagent-output] This dispatch looks like it produces material content (research / audit / analysis / design / review) but the prompt doesn't tell the agent to persist it. The return summary is a pointer, not the artifact — once this context compacts an un-written result is gone (rules/sub-agent-outputs.md). Add to the dispatch prompt: (1) an absolute output path e.g. <project>/.claude/output/<date>-<slug>/<agent>.md, (2) 'write your full output to that path BEFORE returning; return a short abstract + the path' — then verify the file exists before relying on the findings. (mute: touch ~/.claude/.subagent-output-off)"

# additionalContext (stdout JSON) → the agent — the only non-blocking channel
# any audience reads (user-transcript channels are all invisible; see
# hooks-tui-limits). The directive makes the agent relay this to the user.
msg="$msg  →→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."
jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}'
exit 0
