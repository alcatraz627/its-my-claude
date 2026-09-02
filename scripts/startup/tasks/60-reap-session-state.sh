#!/usr/bin/env bash
# 60-reap-session-state.sh — prune leaked session state that the Stop hook never
# cleaned up.
#
# The lifecycle model cleans up on the Stop hook at turn end. Every abnormal exit
# (crash, kill, /clear, a wedged turn) skips Stop, so the session's turn-state
# sentinel, its checkpoint files, and its env dir all leak. Nothing pruned them,
# so they accumulated (7,280 turn-state files since May at build time) and any
# consumer that read a leaked sentinel as "alive" wedged on it (the warden's
# 10-day skip). This is the reaper the model always assumed existed.
#
# Owner ruling 2026-09-02 (decision page lifecycle-fixes-0902, D1a). Retention
# windows are his: turn-state 7d, orphaned checkpoints 30d, session-env 14d.
#
# SAFETY: files are session-scoped and recreated on demand by their owning
# hooks. Only entries older than their window are dropped, so any live session's
# state (touched recently) is safe. A checkpoint file still referenced by
# checkpoints/index.jsonl is NEVER dropped regardless of age — a resume needs it.
# Runs at startup after the narrower reapers (10/20/50).

set -uo pipefail

CLAUDE="${HOME}/.claude"
DRY_RUN=0
TURN_STATE_DAYS=7
CHECKPOINT_DAYS=30
SESSION_ENV_DAYS=14

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --turn-state-days)  TURN_STATE_DAYS="${2:-7}";  shift ;;
    --checkpoint-days)  CHECKPOINT_DAYS="${2:-30}"; shift ;;
    --session-env-days) SESSION_ENV_DAYS="${2:-14}"; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
  shift
done

drop_file() { # $1 = path
  if (( DRY_RUN )); then return 0; fi
  rm -f "$1" 2>/dev/null
}

# ── turn-state debris older than the window. The whole dir is session-scoped
#    ephemera recreated on demand: per-turn sentinels (<sid>.json), heartbeat
#    counters, the speculative-atone counter-<sid> and spec-atone-* nag files.
#    Match by AGE, not by a name list — a pattern list silently misses whatever
#    sentinel type gets added next (the counter-<uuid> files, 94% of the pile at
#    build time, were exactly this miss).
reap_turn_state() {
  local dir="$CLAUDE/.turn-state" removed=0 current=0 f
  [ -d "$dir" ] || { printf '  %-14s (absent)\n' turn-state; return; }
  while IFS= read -r -d '' f; do
    current=$((current + 1))
    if [ -n "$(find "$f" -mtime "+${TURN_STATE_DAYS}" 2>/dev/null)" ]; then
      drop_file "$f" && removed=$((removed + 1))
    fi
  done < <(find "$dir" -maxdepth 1 -type f -print0 2>/dev/null)
  printf '  %-14s removed=%d / total=%d  (>%dd, all types)\n' turn-state "$removed" "$current" "$TURN_STATE_DAYS"
}

# ── checkpoint files older than the window AND not referenced by the index
reap_checkpoints() {
  local dir="$CLAUDE/checkpoints" idx="$CLAUDE/checkpoints/index.jsonl"
  local removed=0 current=0 kept_indexed=0 f base
  [ -d "$dir" ] || { printf '  %-14s (absent)\n' checkpoints; return; }
  # basenames still referenced by any index row. The index carries THREE keys a
  # pointer can be reached by: checkpoint_path, session_id, and (newer schema)
  # session_uuid. Miss any one and a referenced pointer gets reaped — a
  # uuid-only-referenced checkpoint was deleted in an adversarial fixture before
  # session_uuid was added here (2026-09-02).
  local refs=""
  [ -f "$idx" ] && refs=$(jq -r '(.checkpoint_path // ""), (.session_id // ""), (.session_uuid // "")' "$idx" 2>/dev/null \
                          | sed 's#.*/##' | sort -u)
  while IFS= read -r -d '' f; do
    current=$((current + 1))
    base=$(basename "$f")
    if printf '%s\n' "$refs" | grep -qxF "$base" 2>/dev/null; then
      kept_indexed=$((kept_indexed + 1)); continue
    fi
    # also keep if the session_id (basename minus extension) is referenced
    if printf '%s\n' "$refs" | grep -qxF "${base%.*}" 2>/dev/null; then
      kept_indexed=$((kept_indexed + 1)); continue
    fi
    # also keep a collision-preserved pointer <slug>.<uuid8>.json (write.sh:122,
    # served by resolve.sh's "$safe".*.json glob): protected when its SLUG (the
    # part before the first dot) is an indexed session. An adversarial re-review
    # found 24 of these unprotected, the oldest days from the 30d window.
    if printf '%s\n' "$refs" | grep -qxF "${base%%.*}" 2>/dev/null; then
      kept_indexed=$((kept_indexed + 1)); continue
    fi
    if [ -n "$(find "$f" -mtime "+${CHECKPOINT_DAYS}" 2>/dev/null)" ]; then
      drop_file "$f" && removed=$((removed + 1))
    fi
  done < <(find "$dir" -maxdepth 1 -type f \( -name '*.json' -o -name '*.md' \) -print0 2>/dev/null)
  printf '  %-14s removed=%d / total=%d  (>%dd, kept %d indexed)\n' \
    checkpoints "$removed" "$current" "$CHECKPOINT_DAYS" "$kept_indexed"
}

# ── session-env dirs whose newest file is older than the window (empty ones are
#    handled by 50-cleanup-empty-session-env.sh; this covers non-empty debris)
reap_session_env() {
  local dir="$CLAUDE/session-env" removed=0 current=0 d newest
  [ -d "$dir" ] || { printf '  %-14s (absent)\n' session-env; return; }
  while IFS= read -r -d '' d; do
    current=$((current + 1))
    # Stale needs BOTH: no file inside touched within the window, AND the dir's
    # OWN mtime is older than the window. Without the dir-mtime check an EMPTY
    # dir passes vacuously (no files to be recent), so a dir created seconds ago
    # would be rm -rf'd — an adversarial fixture hit exactly that (2026-09-02).
    newest=$(find "$d" -type f -mtime "-${SESSION_ENV_DAYS}" -print -quit 2>/dev/null)
    local dir_fresh; dir_fresh=$(find "$d" -maxdepth 0 -mtime "-${SESSION_ENV_DAYS}" -print 2>/dev/null)
    if [ -z "$newest" ] && [ -z "$dir_fresh" ]; then
      if (( DRY_RUN )); then removed=$((removed + 1))
      else rm -rf "$d" 2>/dev/null && removed=$((removed + 1)); fi
    fi
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  printf '  %-14s removed=%d / total=%d  (>%dd, non-empty)\n' \
    session-env "$removed" "$current" "$SESSION_ENV_DAYS"
}

(( DRY_RUN )) && echo "60-reap-session-state: DRY RUN (nothing deleted)"
reap_turn_state
reap_checkpoints
reap_session_env
