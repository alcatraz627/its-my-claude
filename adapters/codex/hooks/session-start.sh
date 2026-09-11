#!/usr/bin/env bash
# session-start.sh — codex SessionStart: join the fabric, brief the contractor.
#
# 1. Registers this codex session on claude-ipc as cx-<dir>-<id8> and drains
#    its backlog, using claude-ipc's own compiled hook (same stdin contract).
# 2. Adds the gcc briefing a codex seat would otherwise never see: how to
#    write to the ledgers from inside the sandbox, the current mistake
#    patterns, and which handback/checkpoint files exist in the cwd.
# Emits one SessionStart JSON object. Always exits 0.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
gcc_read_input
gcc_export_env

# Dispatch gates, for seats a Claude lane launched (codex-gcc exec sets
# GCC_DISPATCH; the openai-codex plugin sets CODEX_COMPANION_SESSION_ID). The
# owner's own TUI sessions are never gated here. A refused seat gets
# continue:false with the reason, which codex records as the stop reason, plus
# a receipt line in the outbox so `codex-gcc status` shows why nothing ran.
# Born from 2026-08-27 (parallel lanes spent the quota); owner defaults
# 2026-09-11: gate at 25% remaining, cap 3 seats per project per day.
if [ -n "${GCC_DISPATCH:-}${CODEX_COMPANION_SESSION_ID:-}" ] && [ ! -f "$HOME/.claude/.no-codex-usage-gate" ]; then
  verdict=$(python3 "$CODEX_GCC_ROOT/bin/codex-usage-gate.py" 2>/dev/null); grc=$?
  if [ "$grc" -ne 0 ]; then
    jq -cn --arg r "codex usage gate: ${verdict#*	}" '{continue:false, stopReason:$r, systemMessage:$r}'
    exit 0
  fi
  CAP="${CODEX_SEAT_CAP:-3}"
  STATE="$CODEX_GCC_ROOT/state"; mkdir -p "$STATE" 2>/dev/null
  proj=$(cd "$CWD" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || printf '%s' "$CWD")
  ledger="$STATE/dispatch-$(date +%Y-%m-%d).jsonl"
  today=0; [ -f "$ledger" ] && today=$(jq -r --arg p "$proj" 'select(.project == $p) | .sid' "$ledger" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  if [ "$today" -ge "$CAP" ]; then
    jq -cn --arg r "codex seat cap: $today seats already dispatched today for $proj (cap $CAP; CODEX_SEAT_CAP overrides, ~/.claude/.no-codex-usage-gate mutes)" '{continue:false, stopReason:$r, systemMessage:$r}'
    exit 0
  fi
  jq -cn --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" --arg sid "$SID" --arg p "$proj" --arg by "${CLAUDE_CODE_SESSION_ID_PARENT:-${CODEX_COMPANION_SESSION_ID:-codex-gcc}}" \
    '{ts:$ts, sid:$sid, project:$p, dispatched_by:$by}' >> "$ledger"
fi

parts=()

ipc_bin=$(gcc_ipc_bin ipc-session-start)
if [ -n "$ipc_bin" ]; then
  out=$(printf '%s' "$INPUT" | timeout 8 "$ipc_bin" 2>/dev/null)
  ctx=$(gcc_ctx_of "$out")
  [ -n "$ctx" ] && parts+=("$ctx")
fi

alias=$(gcc_alias)
brief="[gcc·codex] You are ${alias} (codex session ${SID:0:8}), a contractor under the owner's gcc; the working agreement is in AGENTS.md.
Ledger and IPC writes from inside your sandbox go through ONE command:
  bash ~/.claude/adapters/codex/bin/gcc <ipc|propose|atone|affirm|pin|checkpoint|ledger> <args as the underlying tool takes them>
It runs the call directly when the sandbox allows, otherwise queues it; a hook applies the queue within seconds and the receipt appears at your next turn. Never call propose.sh, atone.sh, affirm.sh, i-dream pin or claude-ipc directly; the sandbox blocks them and, worse, the environment carries the PARENT Claude session's id, so a direct claude-ipc call would speak as that session."

tldr="$HOME/.claude/atone/derived/_tldr.txt"
if [ -s "$tldr" ]; then
  brief="$brief
Mistake patterns this owner is watching (from the atone ledger; the same blind spots apply to you):
$(sed -n '2,6p' "$tldr")"
fi

pointers=""
[ -e "$CWD/_codex-handback.claude.md" ] && pointers="$pointers
  your last run's handback: $CWD/$(readlink "$CWD/_codex-handback.claude.md" 2>/dev/null || printf '_codex-handback.claude.md')"
[ -e "$CWD/_checkpoint.claude.md" ] && pointers="$pointers
  the owner's Claude checkpoint: $CWD/_checkpoint.claude.md (read it first)"
[ -n "$pointers" ] && brief="$brief
Briefing files present in $CWD:$pointers"

parts+=("$brief")

text=$(printf '%s\n\n' "${parts[@]}")
gcc_emit_ctx SessionStart "$text"
exit 0
