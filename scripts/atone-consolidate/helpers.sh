#!/usr/bin/env bash
# Auto-extracted from atone-consolidate.sh by the split refactor (2026-05-15).
# This file is intended to be sourced (not executed) by atone-consolidate.sh.
# Functions defined here rely on env vars + helpers from atone-common.sh
# and atone-consolidate/helpers.sh.

# ─── Safety guards (raw immutability) ─────────────────────────────

assert_no_writes_to_raw() {
  # Sanity: every write target must be under derived/, not raw paths.
  local p
  for p in "$@"; do
    case "$p" in
      "$EVENTS"|"$EVENTS".*|"$ATONE_DIR/rca/"*|"$AFFIRM_EVENTS"|"$AFFIRM_EVENTS".*)
        _die "internal: refusing to write raw path: $p"
        ;;
    esac
  done
}

# Compute content hash from raw inputs (stable signal for "anything changed?")
_input_hash() {
  {
    [ -f "$EVENTS" ] && cat "$EVENTS"
    [ -f "$AFFIRM_EVENTS" ] && cat "$AFFIRM_EVENTS"
    find "$ATONE_DIR/rca" -type f -name '*.md' 2>/dev/null | sort | xargs cat 2>/dev/null
  } | shasum -a 256 | awk '{print $1}'
}

# Compute weight per slug. severity: S3=3 S2=2 S1=1; recency: exp(-days/14); count: log(n+1)
# All in awk for portability — no python dep here.
_score_for() {
  # args: severity_max(int) days_since_latest(int) count(int)
  awk -v sev="$1" -v days="$2" -v cnt="$3" \
    'BEGIN { printf "%.4f\n", sev * exp(-days/14.0) * log(cnt+1) }'
}

_days_since() {
  # args: ISO date YYYY-MM-DD
  local d="$1" today_epoch d_epoch
  today_epoch=$(date +%s)
  d_epoch=$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null || echo "$today_epoch")
  echo $(( (today_epoch - d_epoch) / 86400 ))
}

_sev_max_to_int() {
  case "$1" in S3) echo 3 ;; S2) echo 2 ;; S1) echo 1 ;; *) echo 1 ;; esac
}

# ─── Aggregate per-slug ───────────────────────────────────────────
# Output rows: SOURCE\tSLUG\tCOUNT\tMAX_SEV\tLATEST_TS\tCLUSTER\tTITLE\tLATEST_ID

aggregate_slugs() {
  # Emits TSV with 8 columns. Empty cluster/title rendered as "-" so bash IFS=tab
  # read doesn't collapse consecutive tabs (bash treats tab as whitespace IFS).
  local source="$1" file="$2"
  [ -f "$file" ] && [ -s "$file" ] || return 0
  jq -r --arg src "$source" '
    [.] | flatten |
    group_by(.slug) |
    map({
      source: $src,
      slug: .[0].slug,
      count: length,
      max_sev: ([.[] | (.severity // "S2")] | sort | reverse | .[0]),
      latest_ts: ([.[] | .ts] | sort | reverse | .[0]),
      cluster: ([.[] | (.cluster // "")] | unique | map(select(length>0)) | (.[0] // "-")),
      title:   ((.[0].title // "-") | if . == "" then "-" else . end),
      latest_id: ([.[] | {ts, id}] | sort_by(.ts) | reverse | .[0].id)
    }) |
    .[] | [.source, .slug, (.count|tostring), .max_sev, .latest_ts, .cluster, .title, .latest_id] | @tsv
  ' < <(jq -s '.' "$file" 2>/dev/null || echo '[]')
}

# ─── Per-cluster files ────────────────────────────────────────────

cluster_name() {
  case "$1" in
    A) echo "Ungrounded assertion" ;;
    B) echo "Claim-ready-before-runtime" ;;
    C) echo "Literal-list-as-action" ;;
    D) echo "Output-shape laziness" ;;
    E) echo "Convention-blind code" ;;
  esac
}

cluster_slug() {
  cluster_name "$1" | tr ' ' '-' | tr '[:upper:]' '[:lower:]'
}

# Slugs that have ANY existing prevention proposal — open, done, OR rejected.
# Rejected slugs intentionally do NOT auto-re-draft (the user explicitly
# said no). To re-enable proposing for a slug, re-open the prior proposal
# manually via propose.sh (no auto-resurrection).
already_proposed_slugs() {
  [ -f "$PROPOSALS_JSONL" ] || return 0
  jq -r '
    select(((.tags // []) | any(. == "atone-prevention")))
    | (.tags // [])
    | map(select(. != "atone-prevention"
              and . != "hook-draft"
              and . != "skill-enhancement"
              and . != "project-claude-md"
              and . != "claude-md-rule"
              and . != "rules-entry"))
    | .[0] // empty
  ' "$PROPOSALS_JSONL" 2>/dev/null | sort -u
}

# Decide the target type for a slug. Inputs: slug, severity, count, cluster, tags-json, has-project
# Echoes one of: hook-draft|skill-enhancement|project-claude-md|claude-md-rule|rules-entry
route_target() {
  local slug="$1" sev="$2" count="$3" cluster="$4" tags="$5" project="$6"

  # Mechanically detectable? Hookable if precheck contains git/process.env/file
  # patterns OR slug indicates a clearly tool-call-shaped action.
  case "$slug" in
    *git-add*|unsolicited-index*|*-staging*|generalize-before-enumerate)
      echo "hook-draft"; return ;;
    raw-process-env*|adding-env-var-reads*)
      echo "hook-draft"; return ;;
    ascii-art-tables*|html-outputs-missing*|blank-lines-inside-markdown*)
      echo "hook-draft"; return ;;
    *declared-ready*|*ready-without-runtime*)
      echo "hook-draft"; return ;;
  esac

  # Project-specific marker in tags
  if echo "$tags" | jq -e 'any(. == "frontend" or . == "backend" or . == "versable")' >/dev/null 2>&1; then
    if [ -n "$project" ] && [ "$project" != "null" ]; then
      echo "project-claude-md"; return
    fi
  fi

  # Skill-domain tags
  if echo "$tags" | jq -e 'any(. == "git" or . == "frontend" or . == "ts" or . == "css")' >/dev/null 2>&1; then
    echo "skill-enhancement"; return
  fi

  # S3 + cross-cutting + short → CLAUDE.md Tier-0
  if [ "$sev" = "S3" ] && [ -z "$cluster" -o "$cluster" = "-" -o "$cluster" = "null" ]; then
    echo "claude-md-rule"; return
  fi

  # Default for behavioral patterns
  echo "rules-entry"
}

# ─── Idempotency / last-run guards ────────────────────────────────

last_run_seconds_ago() {
  [ -f "$LAST_RUN_MARKER" ] || { echo 999999; return; }
  local last_epoch now_epoch
  last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$(cat "$LAST_RUN_MARKER")" +%s 2>/dev/null || echo 0)
  now_epoch=$(date +%s)
  echo $(( now_epoch - last_epoch ))
}

