#!/usr/bin/env bash
# PreCompact hook: comprehensive checkpoint before compaction
# Shell-equivalent of /core-dump mini — captures all structured state that
# can be derived without LLM analysis of the conversation.
#
# Writes:
#   _precompact-checkpoint.claude.md  — rich snapshot (this script)
#   _checkpoint.claude.md             — symlink → above (for /catchup compat)
#   .claude/wal.md                    — CHECKPOINT block appended
#
# Fires on BOTH auto-compaction and manual /compact

set -uo pipefail

input=$(cat)
trigger=$(echo "$input" | jq -r '.trigger // "unknown"')
cwd=$(echo "$input" | jq -r '.cwd // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

if [[ "$trigger" == "auto" ]]; then
  echo "⚠️  AUTO-COMPACTION — Writing comprehensive checkpoint before compaction." >&2
else
  echo "📋 MANUAL COMPACT — Writing comprehensive checkpoint before compaction." >&2
fi

# ── 1. Write WAL CHECKPOINT ──────────────────────────────────────────────────
for wal_path in "$cwd/.claude/wal.md" "$HOME/.claude/wal.md"; do
  if [[ -f "$wal_path" ]]; then
    ts=$(date "+%H:%M")
    cat >> "$wal_path" << EOF

=== CHECKPOINT [$ts] ($trigger compaction) ===
Goal: [see above — $trigger compaction fired, preserving state]
Done: [actions logged above]
Current: Compaction imminent ($trigger trigger)
Next: Continue from this checkpoint after compaction
Blockers: None
Learnings: Compaction fired ($trigger) — if auto, consider delegating heavy subtasks to subagents (context: fork)
===
EOF
    echo "  WAL CHECKPOINT written to $wal_path" >&2
    break
  fi
done

# ── 2. Gather structured data ─────────────────────────────────────────────────

# --- Session stats ---
sid_short="${session_id:0:8}"
turn_count="unknown"
TURN_FILE="/tmp/claude-turns-${sid_short}"
[[ -f "$TURN_FILE" ]] && turn_count=$(cat "$TURN_FILE" 2>/dev/null | tr -d '[:space:]') || true

tool_count="unknown"
TOOL_FILE="/tmp/claude-tools-${PPID}"
[[ -f "$TOOL_FILE" ]] && tool_count=$(grep '^_total=' "$TOOL_FILE" 2>/dev/null | cut -d= -f2) || true

# --- Git data ---
recent_files=""
git_diff_stat=""
recent_commits=""
current_branch=""
if [[ -n "$cwd" ]] && command -v git >/dev/null 2>&1; then
  cd "$cwd" 2>/dev/null || true
  current_branch=$(git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null) || true
  recent_files=$(git diff --name-only HEAD 2>/dev/null | head -20) || true
  [[ -z "$recent_files" ]] && recent_files=$(git diff --name-only 2>/dev/null | head -20) || true
  git_diff_stat=$(git diff --stat HEAD 2>/dev/null | tail -5) || true
  recent_commits=$(git log --oneline -8 2>/dev/null) || true
  cd - >/dev/null 2>&1 || true
fi

# Format recent files as markdown list
recent_files_md="- _(no git changes detected — check WAL for file references)_"
if [[ -n "$recent_files" ]]; then
  recent_files_md=""
  while IFS= read -r f; do
    recent_files_md+="- \`${f}\`"$'\n'
  done <<< "$recent_files"
fi

# --- Last WAL checkpoint block ---
wal_checkpoint_block=""
for wal_path in "$cwd/.claude/wal.md" "$HOME/.claude/wal.md"; do
  if [[ -f "$wal_path" ]]; then
    # Extract last two CHECKPOINT blocks (most recent state)
    wal_checkpoint_block=$(awk '/=== CHECKPOINT/,/^===$/{print}' "$wal_path" 2>/dev/null | tail -30) || true
    break
  fi
done

# --- Active scratchpad plan ---
scratchpad_content=""
scratchpad_source=""
if [[ -n "$cwd" && -d "$cwd/.claude/scratchpad" ]]; then
  latest_plan=$(ls -t "$cwd/.claude/scratchpad"/*.md 2>/dev/null | head -1) || true
  if [[ -n "$latest_plan" ]]; then
    scratchpad_content=$(head -60 "$latest_plan" 2>/dev/null) || true
    scratchpad_source=$(basename "$latest_plan")
  fi
fi

# --- Recent runtime notes (last session entry) ---
runtime_notes_excerpt=""
for notes_path in "$cwd/.claude/skills/runtime-notes.md" "$HOME/.claude/skills/runtime-notes.md"; do
  if [[ -f "$notes_path" ]]; then
    # Grab first 40 lines (most recent session entry)
    runtime_notes_excerpt=$(head -40 "$notes_path" 2>/dev/null) || true
    break
  fi
done

# --- User goals from previous checkpoint ---
prev_goal=""
prev_checkpoint="${cwd:-$HOME/.claude}/_checkpoint.claude.md"
if [[ -f "$prev_checkpoint" ]]; then
  # Extract Initial Goal section (between ## Initial Goal and next ##)
  prev_goal=$(awk '/^## Initial Goal/{found=1; next} /^## /{if(found) exit} found{print}' "$prev_checkpoint" 2>/dev/null | head -10) || true
  # Trim leading/trailing blank lines
  prev_goal=$(echo "$prev_goal" | sed '/^$/d') || true
fi

# --- User goals from WAL ---
wal_goal=""
for wal_path in "$cwd/.claude/wal.md" "$HOME/.claude/wal.md"; do
  if [[ -f "$wal_path" ]]; then
    # Try CHECKPOINT Goal: line first (more descriptive than session header)
    wal_goal=$(grep -m 1 '^Goal:' "$wal_path" 2>/dev/null | sed 's/^Goal: //' | sed 's/ *\[.*$//' ) || true
    # Fall back to session header if Goal line is generic
    if [[ -z "$wal_goal" || "$wal_goal" == *"see above"* ]]; then
      wal_goal=$(grep -m 1 '^## Session:' "$wal_path" 2>/dev/null | sed 's/^## Session: //' | sed 's/ — [0-9].*//' ) || true
    fi
    break
  fi
done

# --- Session todos from scratchpad ---
session_todos=""
if [[ -n "$cwd" && -d "$cwd/.claude/scratchpad" ]]; then
  # Look for unchecked todo items across scratchpad files
  for sp_file in "$cwd/.claude/scratchpad"/*.md; do
    [[ -f "$sp_file" ]] || continue
    todos=$(grep -n '^\s*- \[ \]' "$sp_file" 2>/dev/null | head -10) || true
    if [[ -n "$todos" ]]; then
      sp_name=$(basename "$sp_file")
      session_todos+="### $sp_name"$'\n'
      session_todos+="$todos"$'\n'$'\n'
    fi
  done
fi

# --- Todos from task system (if temp file exists) ---
task_todos=""
TASK_FILE="/tmp/claude-tasks-${sid_short}"
if [[ -f "$TASK_FILE" ]]; then
  task_todos=$(cat "$TASK_FILE" 2>/dev/null) || true
fi

# --- Workspace session-notes (the live Todos/Notes/Decisions that survive /clear) ---
# The richest semantic source: sync-todos mirrors the live Task list into it and
# the human keeps Notes/Decisions there. Prefer this session's own file
# (multi-session safe), falling back to the _active.md symlink.
workspace_notes=""
workspace_source=""
if [[ -n "$cwd" ]]; then
  notes_dir="$cwd/.claude/session-notes"
  { [[ "$cwd" == "$HOME/.claude" ]] || [[ "$cwd" == */.claude ]]; } && notes_dir="$cwd/session-notes"
  notes_file=""
  if [[ -n "$session_id" && -f "$notes_dir/${session_id}.md" ]]; then
    notes_file="$notes_dir/${session_id}.md"
  elif [[ -f "$notes_dir/_active.md" ]]; then
    notes_file="$notes_dir/_active.md"
  fi
  if [[ -n "$notes_file" ]]; then
    workspace_notes=$(head -100 "$notes_file" 2>/dev/null) || true
    workspace_source=$(basename "$(readlink "$notes_file" 2>/dev/null || echo "$notes_file")")
  fi
fi

# ── 3. Write comprehensive checkpoint file ────────────────────────────────────
dump_dir="${cwd:-$HOME/.claude}"
dump_file="$dump_dir/_precompact-checkpoint.claude.md"

{
  cat << HEADER
# Pre-Compaction Checkpoint — $(date -Iseconds)

<!-- sessions: ${session_id:+${session_id}@$(date +%Y-%m-%d)} -->

> Auto-generated by PreCompact hook ($trigger trigger).
> Shell-equivalent of /core-dump mini. Resume with: /catchup
> For full LLM-analyzed context, run: /core-dump

## Session Stats

| Field        | Value |
|--------------|-------|
| Trigger      | $trigger |
| Session ID   | ${session_id:-unknown} |
| Branch       | ${current_branch:-unknown} |
| Turns        | ${turn_count:-unknown} |
| Tools used   | ${tool_count:-unknown} |
| Timestamp    | $(date -Iseconds) |

## User Goals

**From WAL:** ${wal_goal:-_(no WAL session header found)_}
**From previous checkpoint:** ${prev_goal:-_(no prior checkpoint goal found)_}

> If these differ, the user likely pivoted mid-session. Resume the most recent goal.

## Working Directory

\`$cwd\`

## Recovery Sequence

After compaction, run \`/catchup\` — it will:
1. Check WAL for the last CHECKPOINT block (fast path)
2. Fall back to this file for structured state
3. Load targeted file context from pending items
4. Ask which pending item to resume

---

## Recently Modified Files

$recent_files_md
HEADER

  if [[ -n "$workspace_notes" ]]; then
    echo "## Workspace Notes — live, survives /clear (\`$workspace_source\`)"
    echo
    echo "> Todos/Notes/Decisions for this session. The Task list is mirrored here"
    echo "> by sync-todos; this is the primary thing to restore after compaction."
    echo
    echo "$workspace_notes"
    echo
  fi

  if [[ -n "$git_diff_stat" ]]; then
    echo "## Git Diff Summary"
    echo
    echo '```'
    echo "$git_diff_stat"
    echo '```'
    echo
  fi

  if [[ -n "$recent_commits" ]]; then
    echo "## Recent Commits"
    echo
    echo '```'
    echo "$recent_commits"
    echo '```'
    echo
  fi

  if [[ -n "$wal_checkpoint_block" ]]; then
    echo "## Last WAL Checkpoint"
    echo
    echo '```'
    echo "$wal_checkpoint_block"
    echo '```'
    echo
  fi

  if [[ -n "$scratchpad_content" ]]; then
    echo "## Active Scratchpad Plan (\`$scratchpad_source\`)"
    echo
    echo '```'
    echo "$scratchpad_content"
    echo '```'
    echo
  fi

  if [[ -n "$runtime_notes_excerpt" ]]; then
    echo "## Recent Runtime Notes"
    echo
    echo '```'
    echo "$runtime_notes_excerpt"
    echo '```'
    echo
  fi

  if [[ -n "$session_todos" ]]; then
    echo "## Session Todos (from scratchpad)"
    echo
    echo "$session_todos"
    echo
  fi

  if [[ -n "$task_todos" ]]; then
    echo "## Agent Tasks"
    echo
    echo '```'
    echo "$task_todos"
    echo '```'
    echo
  fi

  cat << FOOTER

## Additional Context Sources

- **WAL:** \`.claude/wal.md\` — full action log with checkpoints
- **Scratchpad:** \`.claude/scratchpad/\` — in-progress plans and learnings
- **Tasks:** run \`TaskList\` for pending agent tasks

---

_Auto-generated by pre-compact-checkpoint.sh ($trigger trigger)._
_Not a substitute for /core-dump (no LLM analysis of conversation history)._
FOOTER
} > "$dump_file"

echo "  Checkpoint written to $dump_file" >&2

# ── 4. Symlink _checkpoint.claude.md → _precompact-checkpoint.claude.md ──────
# /catchup defaults to _checkpoint.claude.md — this makes it find our file
symlink="$dump_dir/_checkpoint.claude.md"
ln -sf "_precompact-checkpoint.claude.md" "$symlink" 2>/dev/null || true
echo "  Symlink: $symlink → _precompact-checkpoint.claude.md" >&2

# ── 5. Preservation instructions for the compaction summary ───────────────────
echo "" >&2
echo "CRITICAL — Include these in your compaction summary:" >&2
echo "  • All modified file paths with line numbers" >&2
echo "  • All pending task IDs and their status" >&2
echo "  • The current goal and what step you're on" >&2
echo "  • Any architectural decisions made this session" >&2
echo "  • The session ID: ${session_id:-unknown}" >&2
echo "  • Test commands that were working" >&2
echo "  • User-specified constraints or preferences" >&2
echo "" >&2
echo "After compaction, run: /catchup" >&2
echo "  (reads $symlink via WAL fast path or checkpoint file)" >&2

# ── 6. Asset cleanup (non-blocking) ──────────────────────────────────────────
bash "$HOME/.claude/assets/asset.sh" cleanup >/dev/null 2>&1 || true

# ── 7. Register in checkpoints/index.jsonl (smart-skip + replace-latest) ─────
# Why: without this, /catchup --auto from a fresh session can't find pre-compact
# checkpoints. Smart-skip prevents shadowing a fresh /core-dump (guard 30min)
# and replace-latest ensures only ONE precompact entry per session at any time.
sid_short="${session_id:0:8}"
# kind defaults to precompact; the SessionEnd wrapper overrides it so /catchup's
# index distinguishes "session ended" snapshots from "about to compact" ones.
cp_kind="${PRECOMPACT_KIND_OVERRIDE:-precompact}"
"$HOME/.claude/scripts/checkpoint/write.sh" \
  --session-id        "${session_id:-unknown}" \
  --project-root      "${cwd:-$HOME/.claude}" \
  --checkpoint-path   "$dump_file" \
  --kind              "$cp_kind" \
  --mode              replace-latest \
  --guard-newer-than  1800 \
  --name              "${cp_kind}-${sid_short}" \
  --summary           "Auto ${cp_kind} (${trigger}) — shell-only structural snapshot, no LLM synthesis" \
  >/dev/null 2>&1 || true

exit 0
