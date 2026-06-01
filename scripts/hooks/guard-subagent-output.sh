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
# ADVISORY — always exits 0, never blocks. A dispatch can legitimately be a quick
# lookup ("find where X is defined"); blocking those would be noise. The warning
# names the fix so it's cheap to comply or dismiss.
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
[ "${#PROMPT}" -gt 400 ] && material=1
if printf '%s' "$PROMPT" | grep -qiE '\b(research|analy[sz]e|analysis|audit|review|synthesi[sz]e|investigate|comprehensive|findings|report|write-?up|proposal|design (doc|the)|deep.?dive|catalogue|catalog)\b'; then
  material=1
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

cat >&2 <<'EOF'
[subagent-output] This dispatch looks like it produces material content
(research / audit / analysis / design / review) but the prompt doesn't tell the
agent to persist it. The return summary is a pointer, not the artifact — once
this context compacts, an un-written result is gone (rules/sub-agent-outputs.md).

  Add to the dispatch prompt:
    • an absolute output path (e.g. <project>/.claude/output/<date>-<slug>/<agent>.md)
    • "write your full output to that path BEFORE returning; return a short
      abstract + the path"
  Then verify the file exists before relying on the findings.

  Mute: touch ~/.claude/.subagent-output-off   ·   One-shot: SUBAGENT_OUTPUT_OFF=1
EOF
exit 0
