#!/usr/bin/env bash
# PostToolUse hook: increments tool call counters per session
# Writes to /tmp/claude-tools-$PPID as key=value (tool_name=count)
# Statusline reads this file to show tool frequency
#
# Uses mkdir-based lock + atomic tmp→mv to prevent lost increments
# when multiple PostToolUse hooks fire in parallel.

set -uo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null) || true
[[ -z "$tool_name" ]] && exit 0

# Normalize tool names to short labels
case "$tool_name" in
  Read)    key="R" ;;
  Edit)    key="E" ;;
  Write)   key="W" ;;
  Bash)    key="B" ;;
  Glob)    key="G" ;;
  Grep)    key="Gr" ;;
  Agent)   key="Ag" ;;
  Skill)   key="Sk" ;;
  mcp__*)  key="MCP" ;;
  *)       key="O" ;;  # Other
esac

# Counter file keyed by the Claude process
COUNTER_FILE="/tmp/claude-tools-${PPID}"

# Drop the tally if a /clear happened this process. /clear does not restart the
# process, so PPID (hence this file) persists — a source==clear SessionStart
# injector leaves a session-keyed sentinel that hook_clear_reset acts on here,
# where the correct PPID is known. Idempotent (the rewrite below beats it).
_hc="$HOME/.claude/scripts/hooks/hook-common.sh"
if [ -r "$_hc" ]; then
  . "$_hc"
  _sid=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null) || true
  hook_clear_reset "$(hook_sid8 "$_sid")" "$COUNTER_FILE"
fi

LOCK_DIR="${COUNTER_FILE}.lockdir"

# mkdir-based lock (portable, atomic on all filesystems)
_lock()   { for _ in 1 2 3 4 5; do mkdir "$LOCK_DIR" 2>/dev/null && return 0; sleep 0.05; done; return 1; }
_unlock() { rmdir "$LOCK_DIR" 2>/dev/null || true; }
trap _unlock EXIT

if ! _lock; then
  # Failed to acquire lock after retries — skip this increment rather than block
  exit 0
fi

# Atomic read-modify-write: rebuild entire file with updated counters
tmp="${COUNTER_FILE}.tmp"
found_key=0
found_total=0
{
  if [[ -f "$COUNTER_FILE" ]]; then
    while IFS='=' read -r k v; do
      [[ -z "$k" ]] && continue
      if [[ "$k" == "$key" ]]; then
        echo "${k}=$((v + 1))"
        found_key=1
      elif [[ "$k" == "_total" ]]; then
        echo "_total=$((v + 1))"
        found_total=1
      else
        echo "${k}=${v}"
      fi
    done < "$COUNTER_FILE"
  fi
  # Append new entries if not found
  (( found_key ))   || echo "${key}=1"
  (( found_total )) || echo "_total=1"
} > "$tmp"
mv -f "$tmp" "$COUNTER_FILE"

_unlock

# Auto-checkpoint nudges — recurring every 30 tools (30, 60, 90, …), not a
# one-shot, and suppressed right after a checkpoint so a fresh /core-dump doesn't
# get nagged. The mkdir lock above serializes increments, so the total passes
# through each exact multiple of 30 — modulo never skips one.
new_total=$(grep '^_total=' "$COUNTER_FILE" 2>/dev/null | cut -d= -f2)
new_total=${new_total:-0}

if (( new_total > 0 && new_total % 30 == 0 )); then
  # Suppress if a checkpoint (core-dump OR pre-compact) landed in the last 5 min.
  cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null) || true
  now=$(date +%s)
  recent_ckpt=0
  for cf in "$cwd/_checkpoint.claude.md" "$HOME/.claude/_checkpoint.claude.md"; do
    [[ -f "$cf" ]] || continue
    m=$(stat -f %m "$cf" 2>/dev/null || echo 0)
    (( now - m < 300 )) && recent_ckpt=1
  done
  # Owner ruling 2026-08-18, verbatim: "no context nudging before 50% context, no
  # matter how many tool calls". A tool count measures no context, but the old
  # wording ("context may auto-compact soon") read as if it did, and three agents
  # in three days ran a mini core-dump at ~30% on its say-so (atone slug
  # unmeasured-context-capacity-claim, mist-20260818-130537-c0 S3 and two
  # siblings). So the nudge is gated on the MEASURED context percentage, read the
  # way ctx-pressure-nudge.sh reads it: the payload's context_window field, else
  # the file the statusline persists for this claude pid. Unknown means silent.
  used=""
  rem=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null) || true
  if [[ -z "$rem" || "$rem" == "null" ]]; then
    ctx_file="${CTX_FILE_OVERRIDE:-/tmp/claude-ctx-${PPID}}"
    [[ -f "$ctx_file" ]] && rem=$(tr -dc '0-9.' < "$ctx_file" 2>/dev/null)
  fi
  [[ "$rem" =~ ^[0-9]+(\.[0-9]+)?$ ]] && used=$(awk -v r="$rem" 'BEGIN { printf "%d", 100 - r }' 2>/dev/null)
  if (( ! recent_ckpt )) && [[ -n "$used" ]] && (( used >= 50 )); then
    if (( new_total == 30 )); then
      msg="Tool count 30, context ~${used}% full — consider a WAL checkpoint to preserve session state."
    else
      msg="Tool count ${new_total}, context ~${used}% full (measured) — consider /core-dump mini at the next task boundary."
    fi
    jq -nc --arg m "[auto-checkpoint] $msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
  fi
fi

exit 0
