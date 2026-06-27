#!/usr/bin/env bash
# propose.sh — cross-session improvement backlog.
#
# Any Claude session (or the human) can file an improvement proposal that
# persists in ~/.claude/proposals.jsonl and gets surfaced on demand.
# This decouples *noticing* an improvement (any session, any time) from
# *acting on it* (a future dedicated session) so good ideas don't disappear
# in the compaction gap between conversations.
#
# Storage: JSONL, one proposal per line.
#   {"id":"prop-20260417-024851-a3", "ts":"...", "session_id":"...",
#    "title":"...", "body":"...", "category":"hooks|scripts|skills|config|docs|other",
#    "effort":"small|medium|large", "status":"open|done|rejected",
#    "tags":["t1","t2"], "reason":"..." (on reject)}
#
# Subcommands:
#   add      — file a new proposal
#   list     — human-readable summary table
#   show     — print full body for one id
#   done     — mark proposal completed
#   reject   — mark proposal rejected (with optional reason)
#   help     — show usage
#
# Example (as used by a Claude session mid-task):
#   bash ~/.claude/scripts/propose.sh add \
#     --title "Share session ID via CLAUDE_SESSION_ID env var" \
#     --body "wal.sh and emit-event.sh both encode session ID separately..." \
#     --category hooks --effort medium --tags "session-id wal events"

set -uo pipefail

STORE="${PROPOSE_STORE:-$HOME/.claude/proposals.jsonl}"
LOCK="${PROPOSE_LOCK:-$HOME/.claude/.proposals.lock}"

mkdir -p "$(dirname "$STORE")" 2>/dev/null || true
touch "$STORE" 2>/dev/null || true

usage() {
  sed -n '2,30p' "$0"
}

# -----------------------------------------------------------------------------
# add
# -----------------------------------------------------------------------------
cmd_add() {
  local title="" body="" body_file="" category="other" effort="medium"
  local tags_str="" session_id=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --title)       title="$2"; shift 2 ;;
      --body)        body="$2"; shift 2 ;;
      --body-file)   body_file="$2"; shift 2 ;;
      --category)    category="$2"; shift 2 ;;
      --effort)      effort="$2"; shift 2 ;;
      --tags)        tags_str="$2"; shift 2 ;;
      --session)     session_id="$2"; shift 2 ;;
      *)             echo "propose add: unknown flag: $1" >&2; exit 2 ;;
    esac
  done

  if [ -z "$title" ]; then
    echo "propose add: --title required" >&2
    exit 2
  fi

  if [ -n "$body_file" ]; then
    if [ ! -f "$body_file" ]; then
      echo "propose add: --body-file not found: $body_file" >&2
      exit 2
    fi
    body=$(cat "$body_file")
  fi
  [ -z "$body" ] && body="(no details provided)"

  case "$category" in
    hooks|scripts|skills|config|docs|other) ;;
    *) echo "propose add: invalid --category '$category' (want: hooks|scripts|skills|config|docs|other)" >&2; exit 2 ;;
  esac
  case "$effort" in
    small|medium|large) ;;
    *) echo "propose add: invalid --effort '$effort' (want: small|medium|large)" >&2; exit 2 ;;
  esac

  local ts id hex
  ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  hex=$(printf '%02x' $((RANDOM % 256)))
  id="prop-$(date -u '+%Y%m%d-%H%M%S')-$hex"

  # Convert space-separated tags to a JSON array via jq
  local line
  line=$(jq -cn \
    --arg id "$id" \
    --arg ts "$ts" \
    --arg session_id "$session_id" \
    --arg title "$title" \
    --arg body "$body" \
    --arg category "$category" \
    --arg effort "$effort" \
    --arg tags_str "$tags_str" \
    '{
       id: $id,
       ts: $ts,
       session_id: $session_id,
       title: $title,
       body: $body,
       category: $category,
       effort: $effort,
       status: "open",
       tags: ($tags_str | split(" ") | map(select(length > 0)))
     } | with_entries(select(.value != "" and .value != null))')

  (
    flock -x 9 2>/dev/null || true
    printf '%s\n' "$line" >> "$STORE"
  ) 9>>"$LOCK"

  echo "✓ filed $id"
  echo "  title:    $title"
  echo "  category: $category  effort: $effort"
}

# -----------------------------------------------------------------------------
# list
# -----------------------------------------------------------------------------
cmd_list() {
  local filter_status="open"
  while [ $# -gt 0 ]; do
    case "$1" in
      --status) filter_status="$2"; shift 2 ;;
      *)        echo "propose list: unknown flag: $1" >&2; exit 2 ;;
    esac
  done

  if [ ! -s "$STORE" ]; then
    echo "(no proposals filed yet)"
    return 0
  fi

  local count
  if [ "$filter_status" = "all" ]; then
    count=$(wc -l < "$STORE" | tr -d ' ')
  else
    count=$(jq -c --arg s "$filter_status" 'select(.status == $s)' "$STORE" 2>/dev/null | wc -l | tr -d ' ')
  fi

  echo "Proposals (status=$filter_status): $count"
  echo

  local filter='.'
  [ "$filter_status" != "all" ] && filter="select(.status == \"$filter_status\")"

  # Columns: id, status, category, effort, title (truncated)
  jq -r --arg s "$filter_status" '
    select($s == "all" or .status == $s) |
    [
      .id,
      (.status // "open"),
      (.category // "other"),
      (.effort // "medium"),
      (.title // "(no title)")
    ] | @tsv
  ' "$STORE" 2>/dev/null | awk -F'\t' '
    BEGIN { printf "%-28s  %-8s  %-8s  %-7s  %s\n", "ID", "STATUS", "CAT", "EFFORT", "TITLE"
            printf "%-28s  %-8s  %-8s  %-7s  %s\n", "----", "------", "----", "------", "-----" }
    {
      title = $5
      if (length(title) > 70) title = substr(title, 1, 67) "..."
      printf "%-28s  %-8s  %-8s  %-7s  %s\n", $1, $2, $3, $4, title
    }
  '
}

# -----------------------------------------------------------------------------
# show
# -----------------------------------------------------------------------------
cmd_show() {
  local id="${1:-}"
  [ -z "$id" ] && { echo "propose show: <id> required" >&2; exit 2; }

  local entry
  entry=$(jq -c --arg id "$id" 'select(.id == $id)' "$STORE" 2>/dev/null | head -1)
  if [ -z "$entry" ]; then
    echo "propose show: no proposal with id=$id" >&2
    exit 1
  fi

  echo "$entry" | jq -r '
    "ID:       \(.id)",
    "Filed:    \(.ts)  by \(.session_id // "(unknown)")",
    "Status:   \(.status)",
    "Category: \(.category)  Effort: \(.effort)",
    (if (.tags // []) | length > 0 then "Tags:     \(.tags | join(", "))" else empty end),
    "Title:    \(.title)",
    "",
    "\(.body)",
    (if .reason then "\n---\nReason: \(.reason)" else empty end)
  '
}

# -----------------------------------------------------------------------------
# done / reject — mutate status. Rewrite file under lock.
# -----------------------------------------------------------------------------
mutate_status() {
  local new_status="$1"
  local id="$2"
  local reason="${3:-}"

  [ -z "$id" ] && { echo "propose $new_status: <id> required" >&2; exit 2; }

  if ! jq -e --arg id "$id" 'select(.id == $id)' "$STORE" >/dev/null 2>&1; then
    echo "propose $new_status: no proposal with id=$id" >&2
    exit 1
  fi

  local tmp
  tmp=$(mktemp "${STORE}.XXXXXX")

  (
    flock -x 9 2>/dev/null || true
    jq -c --arg id "$id" --arg new_status "$new_status" --arg reason "$reason" '
      if .id == $id then
        .status = $new_status
        | (if $reason != "" then .reason = $reason else . end)
      else . end
    ' "$STORE" > "$tmp" && mv "$tmp" "$STORE"
  ) 9>>"$LOCK"

  rm -f "$tmp" 2>/dev/null || true
  echo "✓ $id → $new_status"
}

cmd_done() { mutate_status "done" "$@"; }

cmd_reject() {
  local id="${1:-}"
  shift || true
  local reason=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --reason) reason="$2"; shift 2 ;;
      *)        echo "propose reject: unknown flag: $1" >&2; exit 2 ;;
    esac
  done
  mutate_status "rejected" "$id" "$reason"
}

# -----------------------------------------------------------------------------
# dispatch
# -----------------------------------------------------------------------------
SUBCMD="${1:-help}"
shift || true

case "$SUBCMD" in
  add)      cmd_add "$@" ;;
  list|ls)  cmd_list "$@" ;;
  show)     cmd_show "$@" ;;
  done)     cmd_done "$@" ;;
  reject)   cmd_reject "$@" ;;
  help|-h|--help) usage ;;
  *)        echo "propose: unknown subcommand '$SUBCMD'" >&2; usage >&2; exit 2 ;;
esac
