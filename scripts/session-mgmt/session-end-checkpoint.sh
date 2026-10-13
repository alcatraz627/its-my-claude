#!/usr/bin/env bash
# Leaves a resumable checkpoint when a session ends without a /core-dump.
#
# Many sessions just exit or /clear without the agent running /core-dump, so the
# only durable trace is whatever landed in WAL/workspace mid-flight. This hook
# closes that gap: on SessionEnd it produces the same shell-only structural
# snapshot the PreCompact hook does, so a later /catchup (or retro-dump) always
# has an artifact to resume from. It then appends a free journal of the session
# (owner messages, final replies, commits, files, cost; see session-journal.py)
# and hands the snapshot to the dream ingester.
#
# Runtime contract: reads the SessionEnd payload on stdin
# ({session_id, cwd, reason, transcript_path, ...}), re-shapes it into the
# {trigger, cwd, session_id} shape pre-compact-checkpoint.sh consumes, and
# delegates — reusing all of that script's gathering logic instead of
# duplicating it. The checkpoint writer's 30-min smart-skip guard prevents this
# from shadowing a fresh /core-dump. Always exits 0; nothing here may block or
# slow shutdown, so every journal step is time-capped and failure only logs.

set -uo pipefail

input=$(cat 2>/dev/null) || input='{}'
command -v jq >/dev/null 2>&1 || exit 0

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
reason=$(printf '%s' "$input" | jq -r '.reason // "session-end"')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

# `clear` and normal exits are exactly when an unsaved session would lose state.
# `prompt_input_exit` (ctrl-c at an empty prompt) is a no-work bail — skip it to
# avoid churning a checkpoint for a session that did nothing.
[[ "$reason" == "prompt_input_exit" ]] && exit 0

jq -nc --arg cwd "$cwd" --arg sid "$session_id" \
    '{trigger:"session-end", cwd:$cwd, session_id:$sid}' \
  | PRECOMPACT_KIND_OVERRIDE="session-end" \
    bash "$HOME/.claude/scripts/session-mgmt/pre-compact-checkpoint.sh" >/dev/null 2>&1 || true

# ── Journal floor ────────────────────────────────────────────────────────────
# Same location rule as pre-compact-checkpoint.sh, so we append to the file it wrote.
journal_log() { printf '%s %s\n' "$(date +%FT%T)" "$*" >> "$HOME/.claude/logs/session-end-journal.log" 2>/dev/null || true; }

journal_and_ingest() {
  [[ -n "$session_id" ]] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  local dump_dir="${cwd:-$HOME/.claude}" dump_file helper journal
  [[ -n "$cwd" && -e "$cwd/.claude/checkpoints-in-dot-claude" ]] && dump_dir="$cwd/.claude"
  dump_file="$dump_dir/_precompact-checkpoint.claude.md"
  [[ -f "$dump_file" ]] || { journal_log "no snapshot at $dump_file"; return 0; }

  if [[ -z "$transcript" || ! -f "$transcript" ]]; then
    transcript=$(compgen -G "$HOME/.claude/projects/*/${session_id}.jsonl" | head -1)
  fi
  [[ -f "$transcript" ]] || { journal_log "no transcript for $session_id"; return 0; }

  helper="$HOME/.claude/scripts/session-mgmt/session-journal.py"
  [[ -f "$helper" ]] || helper="$(dirname "${BASH_SOURCE[0]}")/session-journal.py"
  local tmo=""; command -v timeout >/dev/null 2>&1 && tmo="timeout -k 1 9"
  # shellcheck disable=SC2086
  journal=$($tmo python3 "$helper" --transcript "$transcript" --cwd "$cwd" 2>>"$HOME/.claude/logs/session-end-journal.log") || journal=""
  [[ -n "$journal" ]] || { journal_log "empty journal for $session_id"; return 0; }

  # A rerun on the same file must not stack a second journal.
  awk '/^## Session Journal$/{f=1} END{exit !f}' "$dump_file" && return 0
  printf '\n%s\n' "$journal" >> "$dump_file" || return 0

  # A real /core-dump is ingested by write.sh; the shell snapshot is lower
  # fidelity, so skip it when this session already has a core-dump entry.
  local idx="$HOME/.claude/checkpoints/index.jsonl" dumped=""
  if [[ -f "$idx" ]]; then
    dumped=$(jq -r --arg s "$session_id" \
      'select(.kind=="core-dump" and (.session_id==$s or .session_uuid==$s)) | .ts' "$idx" 2>/dev/null | head -1)
  fi
  if [[ -n "$dumped" ]]; then
    journal_log "core-dump exists for $session_id ($dumped); not ingesting the snapshot"
    return 0
  fi
  local ing="$HOME/.claude/subconscious/scripts/ingest-checkpoint.sh"
  [[ -x "$ing" ]] || { journal_log "ingester missing: $ing"; return 0; }
  # Detached so the hook returns at once; the ingester is a quick parse.
  ( nohup $tmo "$ing" "$dump_file" --session-id "$session_id" --session-uuid "$session_id" \
      --project-root "${cwd:-$HOME/.claude}" >/dev/null 2>&1 & ) 2>/dev/null
}

mkdir -p "$HOME/.claude/logs" 2>/dev/null || true
journal_and_ingest || journal_log "journal step failed for ${session_id:-unknown}"

exit 0
