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
#    "effort":"small|medium|large", "tier":"minor|moderate|project",
#    "project":"<scope>", "links":["path/doc/rule"],
#    "status":"open|done|rejected|superseded|deferred|obsolete",
#    "tags":["t1"], "updates":[{"ts":"...","note":"..."}], "reason":"..." (on close)}
#
#   tier = kind/ambition (a passing note vs a real project), distinct from effort
#   (work-size). project scopes a proposal so a successor agent can focus on it.
#
# Subcommands:
#   add      — file a new proposal (--tier --project --links --effort --category --tags)
#   list     — query table; filter --status --tier --project --category --since --tag --link
#   search   — full-text search over title/body/tags
#   show     — print full detail (incl. updates trail) for one id
#   update   — append a timestamped note/point to a proposal
#   tier     — set/change a proposal's tier
#   retire   — close with a terminal status (--as done|rejected|superseded|deferred|obsolete)
#   done     — mark completed (alias for retire --as done)
#   reject   — mark rejected (alias for retire --as rejected)
#   help     — show usage
#
# Example (as used by a Claude session mid-task):
#   bash ~/.claude/scripts/propose.sh add \
#     --title "Share session ID via CLAUDE_SESSION_ID env var" \
#     --body "wal.sh and emit-event.sh both encode session ID separately..." \
#     --category hooks --effort medium --tier moderate \
#     --project gcc --links "features/wal.md rules/git.md" --tags "session-id wal"

set -uo pipefail

STORE="${PROPOSE_STORE:-$HOME/.claude/proposals.jsonl}"
LOCK="${PROPOSE_LOCK:-$HOME/.claude/.proposals.lock}"

mkdir -p "$(dirname "$STORE")" 2>/dev/null || true
touch "$STORE" 2>/dev/null || true

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/ledger/ledger-common.sh" 2>/dev/null || true

# Allowed value sets, shared across add / tier / retire.
VALID_TIERS="minor moderate project"
VALID_RETIRE="done rejected superseded deferred obsolete"
# exact whole-value membership (a multi-word value must NOT match as a substring)
in_set() { local x="$1" e; shift; for e in "$@"; do [ "$x" = "$e" ] && return 0; done; return 1; }

usage() {
  # the leading comment block (line 2 to the first code line)
  sed -n '2,/^set /p' "$0" | sed '/^set /d'
}

# -----------------------------------------------------------------------------
# add
# -----------------------------------------------------------------------------
cmd_add() {
  local title="" body="" body_file="" category="other" effort="medium"
  local tags_str="" session_id="" tier="" project="" links_str=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --title)       title="$2"; shift 2 ;;
      --body)        body="$2"; shift 2 ;;
      --body-file)   body_file="$2"; shift 2 ;;
      --category)    category="$2"; shift 2 ;;
      --effort)      effort="$2"; shift 2 ;;
      --tier)        tier="$2"; shift 2 ;;
      --project)     project="$2"; shift 2 ;;
      --links)       links_str="$2"; shift 2 ;;
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
  if [ -n "$tier" ] && ! in_set "$tier" $VALID_TIERS; then
    echo "propose add: invalid --tier '$tier' (want: $VALID_TIERS)" >&2; exit 2
  fi

  local ts id
  ts=$(ledger_ts)
  id=$(ledger_id prop)

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
    --arg tier "$tier" \
    --arg project "$project" \
    --arg links_str "$links_str" \
    --arg tags_str "$tags_str" \
    '{
       id: $id,
       ts: $ts,
       session_id: $session_id,
       title: $title,
       body: $body,
       category: $category,
       effort: $effort,
       tier: $tier,
       project: $project,
       status: "open",
       links: ($links_str | split(" ") | map(select(length > 0))),
       tags: ($tags_str | split(" ") | map(select(length > 0)))
     } | with_entries(select(.value != "" and .value != null and .value != []))')

  ledger_append "$STORE" "$LOCK" "$line"

  echo "✓ filed $id"
  echo "  title:    $title"
  echo "  category: $category  effort: $effort${tier:+  tier: $tier}${project:+  project: $project}"
}

# -----------------------------------------------------------------------------
# list
# -----------------------------------------------------------------------------
cmd_list() {
  local f_status="open" f_tier="" f_project="" f_category="" f_since="" f_tag="" f_link=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --status)   f_status="$2"; shift 2 ;;
      --tier)     f_tier="$2"; shift 2 ;;
      --project)  f_project="$2"; shift 2 ;;
      --category) f_category="$2"; shift 2 ;;
      --since)    f_since="$2"; shift 2 ;;   # ISO date/prefix, e.g. 2026-07-01
      --tag)      f_tag="$2"; shift 2 ;;     # exact tag match
      --link)     f_link="$2"; shift 2 ;;    # substring of a linked path
      *)          echo "propose list: unknown flag: $1" >&2; exit 2 ;;
    esac
  done

  if [ ! -s "$STORE" ]; then
    echo "(no proposals filed yet)"
    return 0
  fi

  # one select, shared by the count and the rows
  local sel='
    select(
      ($s == "all" or (.status // "open") == $s)
      and ($tier == "" or (.tier // "") == $tier)
      and ($project == "" or (.project // "") == $project)
      and ($category == "" or (.category // "") == $category)
      and ($since == "" or (.ts // "") >= $since)
      and ($tag == "" or ((.tags // []) | map(. == $tag) | any))
      and ($link == "" or ((.links // []) | map(contains($link)) | any))
    )'
  local jqargs=( --arg s "$f_status" --arg tier "$f_tier" --arg project "$f_project"
                 --arg category "$f_category" --arg since "$f_since" --arg tag "$f_tag" --arg link "$f_link" )

  local count
  count=$(jq -c "${jqargs[@]}" "$sel" "$STORE" 2>/dev/null | wc -l | tr -d ' ')

  local desc="status=$f_status"
  [ -n "$f_tier" ]     && desc="$desc tier=$f_tier"
  [ -n "$f_project" ]  && desc="$desc project=$f_project"
  [ -n "$f_category" ] && desc="$desc cat=$f_category"
  [ -n "$f_since" ]    && desc="$desc since=$f_since"
  [ -n "$f_tag" ]      && desc="$desc tag=$f_tag"
  [ -n "$f_link" ]     && desc="$desc link=$f_link"
  echo "Proposals ($desc): $count"
  echo

  jq -r "${jqargs[@]}" "$sel"' | [
      .id, (.status // "open"), (.tier // "-"), (.category // "other"),
      (.project // "-"), (.title // "(no title)")
    ] | @tsv' "$STORE" 2>/dev/null | awk -F'\t' '
    BEGIN { fmt = "%-28s  %-11s  %-8s  %-8s  %-11s  %s\n"
            printf fmt, "ID", "STATUS", "TIER", "CAT", "PROJECT", "TITLE"
            printf fmt, "----", "------", "----", "---", "-------", "-----" }
    {
      title = $6; if (length(title) > 58) title = substr(title, 1, 55) "..."
      proj  = $5; if (length(proj)  > 11) proj  = substr(proj, 1, 10) "."
      printf fmt, $1, $2, $3, $4, proj, title
    }
  '
}

# -----------------------------------------------------------------------------
# search — full-text over title / body / tags (case-insensitive)
# -----------------------------------------------------------------------------
cmd_search() {
  local term="${1:-}"
  [ -z "$term" ] && { echo "propose search: <term> required" >&2; exit 2; }
  if [ ! -s "$STORE" ]; then echo "(no proposals filed yet)"; return 0; fi
  jq -r --arg q "$term" '
    select(((((.title // "") | tostring) + " " + ((.body // "") | tostring) + " "
        + ((.tags // []) | map(tostring) | join(" "))) | ascii_downcase)
      | contains($q | ascii_downcase))
    | [.id, (.status // "open"), (.tier // "-"), (.title // "(no title)")] | @tsv
  ' "$STORE" 2>/dev/null | awk -F'\t' -v q="$term" '
    BEGIN { fmt = "%-28s  %-11s  %-8s  %s\n"; printf "matches for \"%s\":\n\n", q
            printf fmt, "ID", "STATUS", "TIER", "TITLE"
            printf fmt, "----", "------", "----", "-----" }
    { title=$4; if (length(title) > 66) title=substr(title,1,63) "..."; printf fmt, $1, $2, $3, title }
    END { if (NR == 0) print "(no matches)" }
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
    "Status:   \(.status)\(if .decided_ts then "  (decided \(.decided_ts))" else "" end)",
    "Category: \(.category)  Effort: \(.effort)\(if .tier then "  Tier: \(.tier)" else "" end)",
    (if .project then "Project:  \(.project)" else empty end),
    (if (.links // []) | length > 0 then "Links:    \(.links | join(", "))" else empty end),
    (if (.tags // []) | length > 0 then "Tags:     \(.tags | join(", "))" else empty end),
    "Title:    \(.title)",
    "",
    "\(.body)",
    (if (.updates // []) | length > 0 then "\n--- updates ---" else empty end),
    ((.updates // [])[] | "  [\(.ts)] \(.note)"),
    (if .superseded_by then "\n--- superseded by: \(.superseded_by)" else empty end),
    (if .reason then "\n--- reason: \(.reason)" else empty end)
  '
}

# -----------------------------------------------------------------------------
# mutations — each rewrites the record with matching id, in place under lock.
# -----------------------------------------------------------------------------

# Apply a jq transform to the record whose id matches (the program sees $id plus
# any extra --arg you pass). Refuses loudly if there is no such id.
mutate_record() {
  local id="$1" prog="$2"; shift 2
  if ! jq -e --arg id "$id" 'select(.id == $id)' "$STORE" >/dev/null 2>&1; then
    # Tell "corrupt store" apart from "no such id": one malformed JSONL line makes
    # the id lookup fail for EVERY id, which is otherwise baffling to debug.
    if ! jq empty "$STORE" >/dev/null 2>&1; then
      echo "propose: $STORE has a malformed JSONL line — fix it before mutating" >&2
    else
      echo "propose: no proposal with id=$id" >&2
    fi
    exit 1
  fi
  local tmp rc=0
  tmp=$(mktemp "${STORE}.XXXXXX") || { echo "propose: cannot create a temp file beside $STORE" >&2; exit 1; }
  # Portable mkdir-lock — there is NO flock on macOS (see ledger-common.sh), so the
  # old `flock … || true` idiom silently degraded to no locking and raced concurrent
  # sessions' read-modify-write. Best-effort: give up after ~2s rather than hang.
  local dirlock="${LOCK}.d" i=0 held=0
  while ! mkdir "$dirlock" 2>/dev/null; do i=$((i + 1)); [ "$i" -ge 20 ] && break; sleep 0.1; done
  [ "$i" -lt 20 ] && held=1
  if jq -c --arg id "$id" "$@" "$prog" "$STORE" > "$tmp"; then
    mv "$tmp" "$STORE" || rc=$?
  else
    rc=$?   # jq failed — $tmp is discarded, $STORE left byte-identical (no corruption)
  fi
  [ "$held" = 1 ] && rmdir "$dirlock" 2>/dev/null
  rm -f "$tmp" 2>/dev/null || true
  return "$rc"
}

# Close a proposal with a terminal status (+ optional reason / superseding id).
# decided_ts makes drain-rate measurable (census 2026-07-12 finding #10).
mutate_status() {
  local new_status="$1" id="$2" reason="${3:-}" by="${4:-}"
  [ -z "$id" ] && { echo "propose $new_status: <id> required" >&2; exit 2; }
  # A reason that IS a flag means the caller used a syntax this tool lacks
  # (e.g. --resolution) — the text would be silently dropped. Refuse loudly;
  # nine audit-trail entries were lost this way on 2026-07-10.
  case "$reason" in
    --*) echo "propose $new_status: reason looks like a flag ('$reason') — pass it positionally: propose.sh retire <id> --as $new_status \"<reason>\"" >&2; exit 2 ;;
  esac
  local dts; dts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mutate_record "$id" '
    if .id == $id then
      .status = $ns | .decided_ts = $dts
      | (if $reason != "" then .reason = $reason else . end)
      | (if $by != "" then .superseded_by = $by else . end)
    else . end
  ' --arg ns "$new_status" --arg dts "$dts" --arg reason "$reason" --arg by "$by" \
    || { echo "propose $new_status: write failed for $id (store unchanged)" >&2; exit 1; }
  echo "✓ $id → $new_status${by:+ (superseded by $by)}"
}

# retire — close with any terminal status; the general form of done/reject.
cmd_retire() {
  local id="${1:-}"; shift || true
  local as="done" reason="" by=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --as)  as="$2"; shift 2 ;;
      --by)  by="$2"; shift 2 ;;
      --*)   echo "propose retire: unknown flag: $1" >&2; exit 2 ;;
      *)     reason="${reason:+$reason }$1"; shift ;;   # join words (unquoted reason)
    esac
  done
  [ -z "$id" ] && { echo "propose retire: <id> required (--as $VALID_RETIRE)" >&2; exit 2; }
  in_set "$as" $VALID_RETIRE || { echo "propose retire: invalid --as '$as' (want: $VALID_RETIRE)" >&2; exit 2; }
  mutate_status "$as" "$id" "$reason" "$by"
}

cmd_done() { mutate_status "done" "$@"; }

cmd_reject() {
  local id="${1:-}"; shift || true
  local reason=""
  # Reason is positional (matching cmd_done and the documented usage);
  # --reason kept for back-compat. Unknown --flags still refuse loudly.
  while [ $# -gt 0 ]; do
    case "$1" in
      --reason) reason="$2"; shift 2 ;;
      --*)      echo "propose reject: unknown flag: $1" >&2; exit 2 ;;
      *)        reason="${reason:+$reason }$1"; shift ;;   # join words (unquoted reason)
    esac
  done
  mutate_status "rejected" "$id" "$reason"
}

# update — append a timestamped note/point (append-only; keeps the original body).
cmd_update() {
  local id="${1:-}"; shift || true
  local note="$*"
  [ -z "$id" ] && { echo "propose update: <id> \"note\" required" >&2; exit 2; }
  [ -z "$note" ] && { echo "propose update: note text required" >&2; exit 2; }
  case "$note" in --*) echo "propose update: note looks like a flag — pass it positionally: propose.sh update <id> \"<note>\"" >&2; exit 2 ;; esac
  local ts; ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mutate_record "$id" '
    if .id == $id then .updates = ((.updates // []) + [{ts:$ts, note:$note}]) else . end
  ' --arg ts "$ts" --arg note "$note" \
    || { echo "propose update: write failed for $id (store unchanged)" >&2; exit 1; }
  echo "✓ $id + update"
}

# tier — set/change a proposal's tier (minor|moderate|project).
cmd_tier() {
  local id="${1:-}" tier="${2:-}"
  { [ -z "$id" ] || [ -z "$tier" ]; } && { echo "propose tier: <id> <$VALID_TIERS> required" >&2; exit 2; }
  in_set "$tier" $VALID_TIERS || { echo "propose tier: invalid tier '$tier' (want: $VALID_TIERS)" >&2; exit 2; }
  mutate_record "$id" 'if .id == $id then .tier = $tier else . end' --arg tier "$tier" \
    || { echo "propose tier: write failed for $id (store unchanged)" >&2; exit 1; }
  echo "✓ $id → tier $tier"
}

# -----------------------------------------------------------------------------
# dispatch
# -----------------------------------------------------------------------------
SUBCMD="${1:-help}"
shift || true

case "$SUBCMD" in
  add)            cmd_add "$@" ;;
  list|ls)        cmd_list "$@" ;;
  search)         cmd_search "$@" ;;
  show)           cmd_show "$@" ;;
  update)         cmd_update "$@" ;;
  tier)           cmd_tier "$@" ;;
  retire)         cmd_retire "$@" ;;
  done)           cmd_done "$@" ;;
  reject)         cmd_reject "$@" ;;
  help|-h|--help) usage ;;
  *)              echo "propose: unknown subcommand '$SUBCMD'" >&2; usage >&2; exit 2 ;;
esac
