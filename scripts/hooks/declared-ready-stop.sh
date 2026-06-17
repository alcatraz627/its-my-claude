#!/usr/bin/env bash
# declared-ready-stop.sh — Stop hook that refuses to let the turn END when the
# agent claims success ("done / works / fixed / passing / verified") but no test
# or program was actually RUN this turn.
#
# This is the mechanical enforcement for the atone pattern
# `declared-ready-without-runtime-exercise` (S3, 5–6× recurrence across projects
# and models). Advisory text never bound it; only a Stop hook sees the completed
# turn and can refuse a premature "done".
#
# Contract (mirrors review-gate-stop.sh — a DIRECT settings.json Stop hook, NOT
# via the hook-orchestrator whose task stdout → /dev/null can't carry a decision):
#   - block:    {"decision":"block","reason":…}  → reason fed to agent, turn stays open
#   - surface:  {"systemMessage":…}              → non-blocking note
#   - silent:   exit 0
#
# Tuning posture (per features/declared-ready-stop-hook.md): UNDER-fire, never
# over-fire. A guard that traps the agent gets muted, and a muted guard enforces
# nothing. So: only fires when (a) source/test files were edited this session,
# (b) the final message makes a success claim about the change, and (c) no run
# signal appears in this turn. Loop-safe: blocks once per claim-signature, then
# steps aside. Mute: touch ~/.claude/.no-declared-ready-gate

set -uo pipefail
[ -f "$HOME/.claude/.no-declared-ready-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"

# Gate 0: only consider turns that actually changed source/test files this
# session. A "done" with no edits is almost always conversational ("done
# reading") — not the failure mode this guard exists for. Reuse the session
# edit-list maintained by track-edits-session.sh.
EDITED="/tmp/claude-edited-files-${sid8}"
[ -s "$EDITED" ] || exit 0
# Require at least one source/test file (not just docs/config) in the edit set.
if ! rg -qi '\.(py|ts|tsx|js|jsx|mjs|cjs|go|rs|swift|rb|java|kt|c|cc|cpp|h|hpp|sh)$' "$EDITED" 2>/dev/null; then
  exit 0
fi

# Read only the tail — the current turn is at the end, and transcripts can be
# many MB. 400 lines comfortably covers one turn; scanning a little extra only
# makes the run-detection MORE lenient (the safe direction).
tail_json=$(tail -n 400 "$tp" 2>/dev/null) || exit 0
[ -n "$tail_json" ] || exit 0

# ── Detection 1: did the FINAL assistant message claim success? ──────────────
# Use the last assistant message only (precise), not the whole tail.
last_asst=$(printf '%s\n' "$tail_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -n 1)
[ -n "$last_asst" ] || exit 0
claim_text=$(printf '%s' "$last_asst" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$claim_text" ] || exit 0

# Success word AND a self-referential subject in the same message — narrow on
# purpose. "done reading the file" lacks the subject; "the fix works" has it.
claimed=0
if printf '%s' "$claim_text" \
   | rg -qiP '\b(done|works|working|shipped|fixed|passing|passes|verified|complete|completed|good to go|all set|ready to (ship|go|commit))\b' 2>/dev/null \
 && printf '%s' "$claim_text" \
   | rg -qiP '\b(the (fix|feature|change|bug|test|tests|build|code|implementation|patch|hook|script)|it|this|everything|all (the )?(tests|of it))\b' 2>/dev/null; then
  claimed=1
fi
[ "$claimed" = 1 ] || exit 0

# ── Detection 2: did anything actually RUN this turn? ────────────────────────
# Two evidence sources; either one means "ran" → stay silent.
ran=0

# (a) A run/test/build command in this turn's Bash tool calls — with the
#     carve-out that collect/compile/lint/dry-run DO NOT count as a run.
bash_cmds=$(printf '%s\n' "$tail_json" \
  | jq -r 'select(.type=="assistant") | .message.content[]?
            | select(.type=="tool_use" and .name=="Bash") | .input.command // empty' 2>/dev/null)
if [ -n "$bash_cmds" ]; then
  real_cmds=$(printf '%s\n' "$bash_cmds" \
    | rg -v -iP '(--collect-only|--no-?emit|--dry-run|--list-tests|--co\b|^[[:space:]]*(eslint|ruff|tsc|mypy|flake8|prettier)\b)' 2>/dev/null || true)
  if printf '%s\n' "$real_cmds" | rg -qiP \
     '(pytest|python3?[[:space:]]+[^|]*\.py|go[[:space:]]+test|cargo[[:space:]]+(test|run)|npm[[:space:]]+(test|run|start)|pnpm[[:space:]]+(test|run|dev|start)|yarn[[:space:]]+(test|dev|start)|node[[:space:]]+[^|]+|swift[[:space:]]+(test|run)|xcodebuild[[:space:]]+test|make[[:space:]]+(test|run|check)|\./[A-Za-z0-9._/-]+|bash[[:space:]]+[^|]*\.sh|curl[[:space:]]+[^|]*localhost|jest|vitest|playwright[[:space:]]+test)' 2>/dev/null; then
    ran=1
  fi
fi

# (b) A real pass/fail run-signal in this turn's tool outputs. This is the
#     strongest evidence and naturally excludes collect-only (which prints
#     "N collected", never "N passed/failed").
if [ "$ran" = 0 ]; then
  outputs=$(printf '%s\n' "$tail_json" \
    | jq -r 'select(.type=="user") | .message.content[]? | select(.type=="tool_result")
              | (.content // "") | if type=="array" then (map(.text? // "") | join("\n")) else . end' 2>/dev/null)
  if [ -n "$outputs" ] && printf '%s' "$outputs" | rg -qiP \
     '([0-9]+[[:space:]]+(passed|failed|error|errors|xfailed)|\bPASS\b|\bFAIL\b|\bok\b[[:space:]]+[0-9]|tests? (passed|ran)|Test Suite.*(passed|failed)|[0-9]+[[:space:]]+(test|spec)s?[[:space:]]+(passed|ran)|✓|✗)' 2>/dev/null; then
    ran=1
  fi
fi

[ "$ran" = 0 ] || exit 0   # something ran → trust the claim, stay silent

# ── Claim made, nothing ran → block (loop-safe) ─────────────────────────────
MARK="/tmp/claude-declared-ready-${sid8}"
sig=$(printf '%s' "$claim_text" | shasum 2>/dev/null | awk '{print $1}')
prev=""; [ -f "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)
if [ "$sig" = "$prev" ] && [ -n "$sig" ]; then
  # Already blocked for this exact claim last Stop — the agent saw it and chose
  # to proceed, or it's a false positive. Step aside (visible, non-blocking).
  msg="⚠ declared-ready (not re-blocking): you edited source/test files and declared success, but I saw no test/program actually run this turn. If you did verify out-of-band or this is a false positive, carry on. Mute: touch ~/.claude/.no-declared-ready-gate"
  jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
  exit 0
fi
printf '%s' "$sig" > "$MARK" 2>/dev/null || true

reason="⚠ DECLARED READY WITHOUT RUNNING IT — you edited source/test files and your message claims success (done/works/fixed/passing), but no test or program actually ran this turn.

  collect ≠ run:  pytest --collect-only, tsc --noEmit, an import-check, or a lint
  are NOT a run — none of them executes an assertion. Run the code path in the
  state that matters and read the actual pass/fail line before declaring done.

This is the 'declared-ready-without-runtime-exercise' pattern (S3, recurs 5–6×).
If you genuinely ran it out-of-band, or this is a false positive, say so and proceed — this won't block again for the same claim. Mute: touch ~/.claude/.no-declared-ready-gate"
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
