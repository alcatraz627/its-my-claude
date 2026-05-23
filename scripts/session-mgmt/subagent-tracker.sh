#!/usr/bin/env bash
# SubagentStart/SubagentStop hook: track active subagents in a temp file
# Used by statusline.sh to show active subagent count + names
# Handles both events — dispatches on hook_event_name
set -uo pipefail

input=$(cat)
event=$(echo "$input" | jq -r '.hook_event_name // empty' 2>/dev/null) || true
agent_type=$(echo "$input" | jq -r '.agent_type // empty' 2>/dev/null) || true
agent_id=$(echo "$input" | jq -r '.agent_id // empty' 2>/dev/null) || true
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null) || true

[[ -z "$session_id" || -z "$agent_type" ]] && exit 0

sid="${session_id:0:8}"
AGENTS_FILE="/tmp/claude-agents-${sid}"
LOCK_DIR="${AGENTS_FILE}.lockdir"

# mkdir-based lock (portable to macOS)
_lock()   { for _ in 1 2 3 4 5; do mkdir "$LOCK_DIR" 2>/dev/null && return 0; sleep 0.1; done; return 1; }
_unlock() { rmdir "$LOCK_DIR" 2>/dev/null || true; }
trap _unlock EXIT

case "$event" in
  SubagentStart)
    ts=$(date +%s)
    if _lock; then
      echo "${agent_id}|${agent_type}|${ts}" >> "$AGENTS_FILE"
      _unlock
    fi
    ;;

  SubagentStop)
    if _lock; then
      if [[ -f "$AGENTS_FILE" ]]; then
        now=$(date +%s)
        tmp="${AGENTS_FILE}.tmp"
        while IFS='|' read -r aid atype ats; do
          [[ "$aid" == "$agent_id" ]] && continue
          age=$(( now - ${ats:-0} ))
          (( age > 300 )) && continue  # drop entries older than 5 min
          echo "${aid}|${atype}|${ats}"
        done < "$AGENTS_FILE" > "$tmp"
        mv -f "$tmp" "$AGENTS_FILE"
      fi
      _unlock
    fi
    ;;
esac
