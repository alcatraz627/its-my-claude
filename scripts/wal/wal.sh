#!/usr/bin/env bash
# wal.sh — write a JSONL line to .claude/wal.jsonl (or ~/.claude/wal.jsonl for
# cross-project work). Wraps jq -cn so escaping is always correct.
#
# Usage:
#   wal.sh session_start <session_id> "<user-msg>" "<intent>"
#   wal.sh action        <session_id> <verb> <target> "<outcome>"
#   wal.sh decision      <session_id> "<choice>" "<why>"
#   wal.sh agent_start   <session_id> <agent> "<task>"
#   wal.sh agent_done    <session_id> <agent> "<result>"
#   wal.sh checkpoint    <session_id> "<goal>" "<done[]>" "<current>" "<next>" "<blockers[]>" "<learnings[]>"
#   wal.sh session_end   <session_id>
#
# Array fields for checkpoint: pass a pipe-separated list, e.g.
#   wal.sh checkpoint fix-auth-3b "Add guard" "Read route.ts|Wrote mw|Tests pass" "Wiring mw" "Run suite" "" "Zod inference saved the custom type"
#
# Environment:
#   WAL_FILE     — path to target file (default: ./.claude/wal.jsonl or $HOME/.claude/wal.jsonl if ~/.claude is CWD)
#
# Exits 0 on write-path failures (silent, never blocks an agent). Malformed
# calls are the exception: unknown kinds and blob-in-session_id checkpoints
# exit non-zero with usage, because a silently-empty checkpoint is worse for
# the caller than a loud error (/catchup's fast path depends on the fields).

set -uo pipefail

KIND="${1:-}"; shift || true

if [ -z "$KIND" ]; then
  cat >&2 <<EOF
usage: wal.sh <kind> <session_id> [args...]
kinds: session_start | action | decision | agent_start | agent_done | checkpoint | session_end
EOF
  exit 1
fi

# Resolve target file.
# Uses shared helper to prevent ".claude/.claude/" double-nesting when CWD is ~/.claude.
source "$HOME/.claude/skills/shared/resolve-claude-path.sh"
if [ -n "${WAL_FILE:-}" ]; then
  TARGET="$WAL_FILE"
else
  TARGET=$(resolve_claude_path "wal.jsonl")
fi

mkdir -p "$(dirname "$TARGET")" 2>/dev/null || true

TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Helper: split pipe-separated list into JSON array
split_json_array() {
  local raw="$1"
  [ -z "$raw" ] && { echo '[]'; return; }
  echo "$raw" | jq -Rc 'split("|")'
}

LINE=""
case "$KIND" in
  session_start)
    SID="${1:-}"; USER_MSG="${2:-}"; INTENT="${3:-}"
    LINE=$(jq -cn --arg ts "$TS" --arg sid "$SID" --arg u "$USER_MSG" --arg i "$INTENT" \
      '{ts:$ts, kind:"session_start", session_id:$sid, user:$u, intent:$i} | with_entries(select(.value != ""))') || exit 0
    ;;
  action)
    SID="${1:-}"; VERB="${2:-}"; TARGET_STR="${3:-}"; OUTCOME="${4:-}"
    LINE=$(jq -cn --arg ts "$TS" --arg sid "$SID" --arg v "$VERB" --arg t "$TARGET_STR" --arg o "$OUTCOME" \
      '{ts:$ts, kind:"action", session_id:$sid, verb:$v, target:$t, outcome:$o} | with_entries(select(.value != ""))') || exit 0
    ;;
  decision)
    SID="${1:-}"; CHOICE="${2:-}"; WHY="${3:-}"
    LINE=$(jq -cn --arg ts "$TS" --arg sid "$SID" --arg c "$CHOICE" --arg w "$WHY" \
      '{ts:$ts, kind:"decision", session_id:$sid, choice:$c, why:$w}') || exit 0
    ;;
  agent_start)
    SID="${1:-}"; AGENT="${2:-}"; TASK="${3:-}"
    LINE=$(jq -cn --arg ts "$TS" --arg sid "$SID" --arg a "$AGENT" --arg t "$TASK" \
      '{ts:$ts, kind:"agent_start", session_id:$sid, agent:$a, task:$t}') || exit 0
    ;;
  agent_done)
    SID="${1:-}"; AGENT="${2:-}"; RESULT="${3:-}"
    LINE=$(jq -cn --arg ts "$TS" --arg sid "$SID" --arg a "$AGENT" --arg r "$RESULT" \
      '{ts:$ts, kind:"agent_done", session_id:$sid, agent:$a, result:$r}') || exit 0
    ;;
  checkpoint)
    SID="${1:-}"; GOAL="${2:-}"; DONE="${3:-}"; CUR="${4:-}"; NEXT="${5:-}"; BLK="${6:-}"; LEARN="${7:-}"
    # A summary blob passed as the only arg lands in session_id and writes an
    # empty checkpoint the /catchup fast path can't use. Refuse and show the
    # corrected call instead of recording garbage.
    BAD=""
    [ -z "$GOAL" ] && BAD="needs at least <session_id> and <goal>"
    [ -z "$SID" ] && BAD="needs at least <session_id> and <goal>"
    [ ${#SID} -gt 64 ] && BAD="session_id is ${#SID} chars — that's a summary blob, not an id"
    case "$SID" in *[[:space:]]*) BAD="session_id ('${SID:0:40}...') contains spaces — prose belongs in goal/done/current/next" ;; esac
    # Flag-style calls (wal.sh checkpoint --goal "..." ...) shift every field by
    # one and land '--goal' here; the args are positional, so refuse loudly.
    case "$SID" in --*) BAD="session_id is '$SID' — this writer takes POSITIONAL args, not flags" ;; esac
    if [ -n "$BAD" ]; then
      echo "wal.sh checkpoint: $BAD" >&2
      echo "usage: wal.sh checkpoint <session_id> \"<goal>\" \"<done|pipe|list>\" \"<current>\" \"<next>\" \"<blockers|list>\" \"<learnings|list>\"" >&2
      exit 2
    fi
    DONE_JSON=$(split_json_array "$DONE")
    BLK_JSON=$(split_json_array "$BLK")
    LEARN_JSON=$(split_json_array "$LEARN")
    LINE=$(jq -cn --arg ts "$TS" --arg sid "$SID" --arg g "$GOAL" \
                  --argjson d "$DONE_JSON" --arg c "$CUR" --arg n "$NEXT" \
                  --argjson b "$BLK_JSON" --argjson l "$LEARN_JSON" \
      '{ts:$ts, kind:"checkpoint", session_id:$sid, goal:$g, done:$d, current:$c, next:$n, blockers:$b, learnings:$l}') || exit 0
    ;;
  session_end)
    SID="${1:-}"
    LINE=$(jq -cn --arg ts "$TS" --arg sid "$SID" \
      '{ts:$ts, kind:"session_end", session_id:$sid}') || exit 0
    ;;
  *)
    echo "unknown kind: $KIND" >&2
    exit 1
    ;;
esac

[ -z "$LINE" ] && exit 0

# Concurrent sessions in one project share this file — serialize appends with a
# best-effort flock (no flock binary → plain O_APPEND, as before). Long lines
# (checkpoint kind) can exceed PIPE_BUF, where bare >> may interleave. The lock
# object is the SIDECAR "$TARGET.lock", matching rotate-wal.sh — so appends also
# serialize against rotation's gzip-then-truncate window, not just each other.
( flock -x 9 2>/dev/null || true; printf '%s\n' "$LINE" >> "$TARGET" ) 9>>"$TARGET.lock" 2>/dev/null || true
exit 0
