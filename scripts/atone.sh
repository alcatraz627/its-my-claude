#!/usr/bin/env bash
# atone.sh — mistake-tracker CLI for the /atone skill.
#
# Append-only event log at ~/.claude/atone/events.jsonl.
# Mirrors propose.sh's flock + jq pattern.
# After Stage 2 migration, the file is chflags-locked via `atone.sh lock` —
# append still works (O_APPEND is permitted), but other modifications are
# blocked at the kernel level.
#
# See ~/.claude/conventions/cli-help-design.md for help-text conventions.

set -uo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/atone-common.sh"

ATONE_DIR="$HOME/.claude/atone"
STORE="$ATONE_DIR/events.jsonl"
LOCK_FILE="$ATONE_DIR/events.jsonl.lock"
RCA_DIR="$ATONE_DIR/rca"

# Migration override (e.g., write to events.jsonl.draft)
[ -n "${ATONE_STORE_OVERRIDE:-}" ] && STORE="$ATONE_DIR/$ATONE_STORE_OVERRIDE"

mkdir -p "$ATONE_DIR" "$RCA_DIR" 2>/dev/null || true

# ─── Help ─────────────────────────────────────────────────────────

show_help() {
  printf '\n  %s%satone%s %s—%s Mistake-tracker CLI\n' \
    "$C_BOLD" "$C_MAGENTA" "$C_RESET" "$C_DIM" "$C_RESET"
  printf '  %sAppend-only event log; auto-committed to git; kernel-locked after stage-2.%s\n' \
    "$C_DIM" "$C_RESET"

  _section "USAGE"
  _cmd 'atone add [...]'              'log a new mistake event'
  _cmd 'atone list [filters]'         'tabular listing'
  _cmd 'atone search <query>'         'free-text search across fields'
  _cmd 'atone show <id>'              'full event + RCA if any'
  _cmd 'atone slugs'                  'list distinct slugs with counts'
  _cmd 'atone stats'                  'severity distribution + top recurrers + recent rate'
  _cmd 'atone triggers <kw>'          'lookup matching triggers (deeper context)'
  _cmd 'atone feedback ...'           'record trigger-effectiveness signal'
  _cmd 'atone juror ...'              'record one juror verdict (used by /atone)'
  _cmd 'atone judgments [list|show|stats]'  'inspect judgment records'
  _cmd 'atone lock'                   'apply kernel append-only flag'
  _cmd 'atone unlock-check'           'print current flag state'
  _cmd 'atone help'                   'this help'

  _section "EXAMPLES"
  _ex  'atone add --slug forgot-flag --title "..." --severity S2 ...'
  _exd 'Log a new event (all required fields enforced)'
  echo
  _ex  'atone list --severity S3 --since 7d'
  _exd 'All S3 events from the last week (--since not yet wired)'
  echo
  _ex  'atone list --slug generalize-before-enumerate'
  _exd 'All occurrences of one slug (recurrence trail)'
  echo
  _ex  'atone search "process.env"'
  _exd 'Substring search across slug/title/issue/cause/fix/tags'
  echo
  _ex  'atone show mist-20260514-232119-46'
  _exd 'Pretty-print one event + attached RCA if present'
  echo
  _ex  'atone slugs | head -10'
  _exd 'Top 10 most-recurrent slugs'

  _section "ADD FLAGS"
  _opt '--slug S'        'kebab-case pattern name (REUSE existing slug for recurrences)'
  _opt '--title T'       '≤80-char one-line summary'
  _opt '--issue I'       'what happened, with file:line if applicable'
  _opt '--cause C'       'why it happened (false assumption / skipped step)'
  _opt '--fix F'         'what was done to repair it'
  _opt '--what-not W'    'imperative ≤2-sentence future-self instruction'
  _opt '--severity X'    'S1 | S2 | S3 (required)'
  _opt '--precheck P'    'optional: yes/no check that resolves at draft time'
  _opt '--tags "a b c"'  'space-separated tags (shared with affirm/)'
  _opt '--cluster X'     'A–E (or null; cron may assign during consolidation)'
  _opt '--project PATH'  'absolute project path or empty'
  _opt '--files "p:N"'   'space-separated file:line locations'
  _opt '--rca-content S' 'full RCA body (S3 path) — file is written with chflags uchg'
  _opt '--rca-file PATH' 'load RCA body from a file (alternative to --rca-content)'

  _section "LIST FILTERS"
  _opt '--severity S'    'S1 | S2 | S3'
  _opt '--cluster X'     'A | B | C | D | E'
  _opt '--slug S'        'one specific slug'
  _opt '--since SPEC'    '(not yet wired)'

  _section "FILES"
  _dim "raw log     ~/.claude/atone/events.jsonl  (chflags uappnd post-lock)"
  _dim "RCA files   ~/.claude/atone/rca/<id>.md   (chflags uchg per file)"
  _dim "git history ~/.claude/atone/.git           (auto-commit on every add)"
  _dim "snapshots   ~/.claude/atone-snapshots/    (daily, hardlink-deduped)"
  echo
}

# ─── Helpers ──────────────────────────────────────────────────────

_new_id() {
  local hex
  hex=$(printf '%02x' $((RANDOM % 256)))
  printf 'mist-%s-%s\n' "$(date -u '+%Y%m%d-%H%M%S')" "$hex"
}

_ts() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

_git_commit() {
  # Idempotent. Commits if events.jsonl or rca/* changed; silent if not.
  ( cd "$ATONE_DIR" && \
    git add events.jsonl rca/ 2>/dev/null && \
    if ! git diff --cached --quiet 2>/dev/null; then
      git commit -q -m "$1" 2>/dev/null
    fi ) || true
}

# ─── add ──────────────────────────────────────────────────────────

cmd_add() {
  local slug="" title="" issue="" cause="" fix="" what_not=""
  local severity="" precheck="" tags_str="" cluster=""
  local project="" files_str="" rca_content="" rca_file=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --slug)         slug="$2"; shift 2 ;;
      --title)        title="$2"; shift 2 ;;
      --issue)        issue="$2"; shift 2 ;;
      --cause)        cause="$2"; shift 2 ;;
      --fix)          fix="$2"; shift 2 ;;
      --what-not)     what_not="$2"; shift 2 ;;
      --precheck)     precheck="$2"; shift 2 ;;
      --severity)     severity="$2"; shift 2 ;;
      --tags)         tags_str="$2"; shift 2 ;;
      --cluster)      cluster="$2"; shift 2 ;;
      --project)      project="$2"; shift 2 ;;
      --files)        files_str="$2"; shift 2 ;;
      --rca-content)  rca_content="$2"; shift 2 ;;
      --rca-file)     rca_file="$2"; shift 2 ;;
      -h|--help)      show_help; exit 0 ;;
      *) _die "add: unknown flag: $1" ;;
    esac
  done

  for f in slug title issue cause fix what_not severity; do
    if [ -z "${!f}" ]; then
      _die "add: --${f//_/-} required"
    fi
  done

  case "$severity" in
    S1|S2|S3) ;;
    *) _die "add: --severity must be S1|S2|S3 (got: $severity)" ;;
  esac

  _require jq

  # Same-session repeat detection: if this slug already appeared in events.jsonl
  # with today's UTC date, auto-bump severity by one tier and add tag.
  # The signal is high: "I logged this earlier today and did it again."
  # Disable via ATONE_NO_REPEAT_BUMP=1 (for testing or migration).
  local repeat_bumped=0
  if [ "${ATONE_NO_REPEAT_BUMP:-0}" != "1" ] && [ -s "$STORE" ]; then
    local today_utc same_day_count
    today_utc=$(date -u '+%Y-%m-%d')
    same_day_count=$(jq -r --arg s "$slug" --arg d "$today_utc" '
      select(.slug == $s and (.ts | startswith($d))) | .id
    ' "$STORE" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$same_day_count" -gt 0 ]; then
      local bumped_sev
      case "$severity" in
        S1) bumped_sev=S2 ;;
        S2) bumped_sev=S3 ;;
        S3) bumped_sev=S3 ;;  # already max
      esac
      _warn "same-session-repeat detected: slug '$slug' has $same_day_count event(s) today (UTC)"
      if [ "$bumped_sev" != "$severity" ]; then
        printf '  %sauto-bumping severity:%s %s → %s\n' "$C_BOLD" "$C_RESET" "$severity" "$bumped_sev"
        severity="$bumped_sev"
      else
        _info "severity already at S3 — no further bump available"
      fi
      # Append same-session-repeat tag (if not already present)
      if ! echo " $tags_str " | grep -q " same-session-repeat "; then
        tags_str="$tags_str same-session-repeat"
      fi
      repeat_bumped=1
    fi
  fi

  # Fuzzy-slug check: warn if a near-duplicate slug already exists.
  # Heuristic: Levenshtein < 3 OR token overlap ≥ 50%.
  # Skips if env ATONE_NO_FUZZY=1 (for scripts/migration that already validated).
  if [ "${ATONE_NO_FUZZY:-0}" != "1" ] && [ -s "$STORE" ]; then
    local existing_slugs near_match
    existing_slugs=$(jq -r '.slug' "$STORE" | sort -u)
    near_match=$(ATONE_NEW_SLUG="$slug" ATONE_EXISTING_SLUGS="$existing_slugs" python3 - <<'PY' 2>/dev/null
import os
new = os.environ.get("ATONE_NEW_SLUG", "").lower()
existing = os.environ.get("ATONE_EXISTING_SLUGS", "")
new_tokens = set(new.split("-"))
def lev(a, b):
    if a == b: return 0
    if not a or not b: return max(len(a), len(b))
    prev = list(range(len(b)+1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j]+1, cur[-1]+1, prev[j-1] + (ca != cb)))
        prev = cur
    return prev[-1]

best = None
for slug in existing.split():
    slug = slug.strip()
    if not slug or slug == new:
        continue  # exact match — recurrence path is fine
    d = lev(slug, new)
    overlap = len(new_tokens & set(slug.split("-"))) / max(1, len(new_tokens | set(slug.split("-"))))
    if d < 3 or overlap >= 0.5:
        score = -d + overlap * 10
        if best is None or score > best[0]:
            best = (score, slug, d, overlap)
if best:
    print(f"{best[1]}\t{best[2]}\t{best[3]:.2f}")
PY
)
    if [ -n "$near_match" ]; then
      local near_slug lev_dist overlap_pct
      near_slug=$(echo "$near_match" | cut -f1)
      lev_dist=$(echo "$near_match" | cut -f2)
      overlap_pct=$(echo "$near_match" | cut -f3)
      _warn "near-duplicate slug detected — did you mean an existing one?"
      printf '\n  %sproposed:%s %s\n'  "$C_DIM" "$C_RESET" "$slug"
      printf '  %sexisting:%s %s%s%s  (Levenshtein=%s, token-overlap=%s)\n\n' \
        "$C_DIM" "$C_RESET" "$C_CYAN" "$near_slug" "$C_RESET" "$lev_dist" "$overlap_pct"

      # Only prompt if /dev/tty is available (interactive shell). Otherwise
      # emit the warning, default to keep-new, and continue. ATONE_NO_FUZZY=1
      # skips the check entirely.
      if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        printf '  %s[r] reuse existing slug   [k] keep new (force)   [a] abort%s ' "$C_BOLD" "$C_RESET"
        read -r choice </dev/tty || choice="k"
        case "$choice" in
          r|R) slug="$near_slug"; _ok "using existing slug: $slug" ;;
          a|A) _die "aborted (use ATONE_NO_FUZZY=1 to skip this check)" ;;
          *)   _info "keeping proposed new slug: $slug" ;;
        esac
      else
        _info "non-interactive — keeping proposed slug. To reuse instead:"
        _info "  re-run with --slug $near_slug"
      fi
    fi
  fi

  local id ts rca_id rca_path
  id=$(_new_id); ts=$(_ts); rca_id=""; rca_path=""

  if [ -n "$rca_file" ]; then
    [ -f "$rca_file" ] || _die "add: --rca-file not found: $rca_file"
    rca_content=$(cat "$rca_file")
  fi
  if [ -n "$rca_content" ]; then
    rca_id="$id"
    rca_path="$RCA_DIR/$rca_id.md"
    # Write to a temp file FIRST so we can lint before locking.
    local rca_tmp="$rca_path.lint-tmp"
    printf '%s\n' "$rca_content" > "$rca_tmp"

    # Lint — bypass via ATONE_NO_RCA_LINT=1.
    local lint_script
    lint_script="$(dirname "${BASH_SOURCE[0]}")/atone-rca-lint.sh"
    if [ -x "$lint_script" ] && [ "${ATONE_NO_RCA_LINT:-0}" != "1" ]; then
      if ! bash "$lint_script" "$rca_tmp" >&2; then
        rm -f "$rca_tmp" 2>/dev/null || true
        _die "RCA failed lint — fix the issues above and retry, or set ATONE_NO_RCA_LINT=1 to bypass."
      fi
    fi

    # Move temp into place, then chflags + chmod.
    mv "$rca_tmp" "$rca_path"
    chflags uchg "$rca_path" 2>/dev/null || true
    chmod 0444 "$rca_path" 2>/dev/null || true
  fi

  # ─── Juror enforcement gate for S3 events ──────────────────────
  # Spec compliance lesson learned from skill-spec-update-not-honored-by-running-
  # session (mist-20260516-002740-d6): the data path must enforce mandates,
  # because cached SKILL.md in running sessions can silently bypass spec-level
  # rules.
  #
  # For S3 events: require a linked judgment to exist (or explicit opt-out).
  # We can't check the linked_atone_event_id BEFORE the event is added (because
  # the event id is generated here), so instead we check: did a judgment land
  # in the recent past tagged for this slug? If yes → ok. If no AND
  # ATONE_NO_JUROR is not set → refuse.
  #
  # Skip this gate during migration / testing via ATONE_NO_JUROR=1.
  # judgment_id (event row forward-link) and suspect_fields populated below.
  local matched_judgment_id="" matched_verdict="" matched_ts="" suspect_fields_str=""

  if [ "$severity" = "S3" ] && [ "${ATONE_NO_JUROR:-0}" != "1" ]; then
    local cutoff
    cutoff="$(date -u -v-15M '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '15 minutes ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo '')"
    # STRICT slug match only — the old OR-clause `.linked_atone_event_id != null`
    # was a literal bypass (any judgment with a linked event id satisfied the
    # gate for any slug). Removed 2026-05-17.
    local match
    match=$(jq -r --arg slug "$slug" --arg cutoff "$cutoff" '
      select(.ts >= $cutoff) |
      select((.related_atone_slugs // []) | any(. == $slug)) |
      [.id, .verdict, .ts] | @tsv
    ' "$JUDGMENTS_LOG" 2>/dev/null | tail -1)

    if [ -z "$match" ]; then
      cat >&2 <<EOF
${C_RED:-}atone add: REFUSED${C_RESET:-}

This is an S3 event but no recent juror judgment was found whose
related_atone_slugs contains "$slug" (checked last 15 min of
~/.claude/atone/judgments.jsonl).

S3 events MUST have a linked juror verdict — anti-sycophancy gate.
Dispatching a juror from the SAME context as the atoning agent defeats the
purpose; the juror is supposed to be an independent second opinion. If you
just composed the juror JSON yourself, stop and dispatch a real sub-agent.

Options:

  1. (REQUIRED PATH) Dispatch a juror SUB-AGENT (Agent tool, fresh context)
     with ~/.claude/personas/juror.md + your case. Wait for its verdict.
     Then record via:
       bash ~/.claude/scripts/atone.sh juror --user-callout ... --verdict ... \\
         --related-slugs "$slug ..."
     Retry this add — the gate will find the recent judgment.

  2. (LOGGED BYPASS) ATONE_NO_JUROR=1 retry. The event will carry
     juror_bypassed:true so the bypass is auditable, not silent.

  3. (DOWNGRADE) Retry with --severity S2 if this isn't actually S3.
EOF
      exit 4
    fi
    matched_judgment_id="$(printf '%s' "$match" | awk -F'\t' '{print $1}')"
    matched_verdict="$(printf '%s' "$match" | awk -F'\t' '{print $2}')"
    matched_ts="$(printf '%s' "$match" | awk -F'\t' '{print $3}')"

    # Verdict threshold gate: if juror cleared the agent, don't auto-atone.
    if [ "$matched_verdict" = "probably-right" ] || [ "$matched_verdict" = "reasonably-right" ]; then
      if [ -z "${ATONE_OVERRIDE_VERDICT:-}" ]; then
        cat >&2 <<EOF
${C_RED:-}atone add: REFUSED — juror cleared the agent${C_RESET:-}

Matched judgment: $matched_judgment_id  verdict=$matched_verdict

The juror said the agent was '$matched_verdict' — recording an atone on
top of that contradicts the verdict and defeats the anti-sycophancy gate.
This is the "I'll atone anyway to please the user" failure mode.

If the user is overruling the juror (legitimate sometimes — juror is
fallible), retry with:
  ATONE_OVERRIDE_VERDICT="<reason user is overruling>" bash atone.sh add ...

The reason will be recorded on the event for audit.
EOF
        exit 5
      fi
      suspect_fields_str="${suspect_fields_str}|verdict-overridden:${matched_verdict}"
    fi

    # Synthetic-juror heuristic: real sub-agent dispatch takes ≥10s. A judgment
    # that landed <10s before this atone was almost certainly composed inline
    # by the same agent, not by a dispatched sub-agent.
    local now_epoch jud_epoch gap_s
    now_epoch="$(date -u '+%s')"
    jud_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$matched_ts" '+%s' 2>/dev/null || date -u -d "$matched_ts" '+%s' 2>/dev/null || echo "$now_epoch")"
    gap_s=$(( now_epoch - jud_epoch ))
    if [ "$gap_s" -lt 10 ]; then
      suspect_fields_str="${suspect_fields_str}|synthetic-juror-suspected:gap_${gap_s}s"
      _warn "juror→atone gap was ${gap_s}s — real sub-agent dispatch takes ≥10s. Flagging suspect_fields."
    fi

    _ok "juror gate: matched $matched_judgment_id (verdict=$matched_verdict, gap=${gap_s}s)"
  elif [ "${ATONE_NO_JUROR:-0}" = "1" ]; then
    suspect_fields_str="${suspect_fields_str}|juror-bypassed:ATONE_NO_JUROR=1"
    _warn "ATONE_NO_JUROR=1 — recording event with juror_bypassed:true"
  fi
  # Strip leading | from suspect_fields_str for cleaner downstream split.
  suspect_fields_str="${suspect_fields_str#|}"

  local line
  line=$(jq -cn \
    --arg id "$id" --arg ts "$ts" --arg slug "$slug" \
    --arg title "$title" --arg issue "$issue" --arg cause "$cause" \
    --arg fix "$fix" --arg what_not "$what_not" --arg precheck "$precheck" \
    --arg severity "$severity" --arg cluster "$cluster" --arg project "$project" \
    --arg tags_str "$tags_str" --arg files_str "$files_str" --arg rca_id "$rca_id" \
    --arg judgment_id "$matched_judgment_id" \
    --arg verdict "$matched_verdict" \
    --arg suspect_fields_str "$suspect_fields_str" \
    --arg override_reason "${ATONE_OVERRIDE_VERDICT:-}" \
    --arg juror_bypassed "$([ "${ATONE_NO_JUROR:-0}" = "1" ] && echo true || echo false)" \
    '{
       id: $id, ts: $ts, slug: $slug, title: $title,
       issue: $issue, cause: $cause, fix: $fix, what_not_to_do: $what_not,
       precheck: (if $precheck == "" then null else $precheck end),
       severity: $severity,
       cluster: (if $cluster == "" then null else $cluster end),
       project: (if $project == "" then null else $project end),
       tags:  ($tags_str  | split(" ") | map(select(length > 0))),
       files: ($files_str | split(" ") | map(select(length > 0))),
       rca_id: (if $rca_id == "" then null else $rca_id end),
       judgment_id: (if $judgment_id == "" then null else $judgment_id end),
       juror_verdict: (if $verdict == "" then null else $verdict end),
       juror_bypassed: ($juror_bypassed == "true"),
       override_reason: (if $override_reason == "" then null else $override_reason end),
       suspect_fields: ($suspect_fields_str | split("|") | map(select(length > 0)))
     }')

  (
    flock -x 9 2>/dev/null || true
    printf '%s\n' "$line" >> "$STORE"
  ) 9>>"$LOCK_FILE"

  _git_commit "atone: $id $slug ($severity)"

  # Fast-path: refresh triggers.json + _tldr.txt so hinters pick up the new event.
  # Run in background so caller doesn't wait for the ~1s consolidation.
  ( bash "$HOME/.claude/scripts/atone-consolidate.sh" --triggers-only \
      >/dev/null 2>&1 & ) &

  _ok "logged $id"
  gum_kv "slug"     "$slug"
  gum_kv "severity" "$severity"
  [ -n "$cluster" ]  && gum_kv "cluster" "$cluster"
  [ -n "$rca_path" ] && gum_kv "rca"     "$rca_path"
  return 0    # explicit — guards against the [ -n ... ] && pattern above returning 1 on empty
}

# ─── list ─────────────────────────────────────────────────────────

cmd_list() {
  local f_sev="" f_cluster="" f_slug="" f_since=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --severity) f_sev="$2"; shift 2 ;;
      --cluster)  f_cluster="$2"; shift 2 ;;
      --slug)     f_slug="$2"; shift 2 ;;
      --since)    f_since="$2"; shift 2 ;;
      -h|--help)  show_help; exit 0 ;;
      *) _die "list: unknown flag: $1" ;;
    esac
  done

  if [ ! -s "$STORE" ]; then
    _info "no events logged yet"
    return 0
  fi
  _require jq

  local filter='.'
  [ -n "$f_sev" ]     && filter="$filter | select(.severity == \"$f_sev\")"
  [ -n "$f_cluster" ] && filter="$filter | select(.cluster == \"$f_cluster\")"
  [ -n "$f_slug" ]    && filter="$filter | select(.slug == \"$f_slug\")"

  # Header (color only on TTY)
  if [ "$ATONE_TTY" = "1" ]; then
    printf '%s%-10s  %-26s  %-3s  %-2s  %-44s  %s%s\n' \
      "$C_BOLD$C_DIM" "DATE" "ID" "SEV" "CL" "SLUG" "TITLE" "$C_RESET"
  fi

  jq -r "$filter | [.ts[:10], .id, .severity, (.cluster // \"-\"), .slug, .title] | @tsv" "$STORE" | \
    awk -F'\t' '{
      # Truncate slug/title for column fit
      slug=$5; if (length(slug)>44) slug=substr(slug,1,41)"…"
      title=$6; if (length(title)>50) title=substr(title,1,47)"…"
      printf "%-10s  %-26s  %-3s  %-2s  %-44s  %s\n", $1, $2, $3, $4, slug, title
    }'
}

# ─── search ───────────────────────────────────────────────────────

cmd_search() {
  [ $# -lt 1 ] && _die "search: query required"
  local q="$1"
  if [ ! -s "$STORE" ]; then _info "no events logged yet"; return 0; fi
  _require jq

  jq -c --arg q "$q" '
    select(
      (.slug // "") + " " + (.title // "") + " " + (.issue // "") + " " +
      (.cause // "") + " " + (.fix // "") + " " + (.what_not_to_do // "") + " " +
      (.precheck // "") + " " + ((.tags // []) | join(" "))
      | ascii_downcase | contains($q | ascii_downcase)
    )' "$STORE" | jq -r '[.ts[:10], .id, .severity, .slug, .title] | @tsv' | \
    awk -F'\t' '{ printf "%-10s  %-26s  %-3s  %-44s  %s\n", $1, $2, $3, $4, $5 }'
}

# ─── show ─────────────────────────────────────────────────────────

cmd_show() {
  [ $# -lt 1 ] && _die "show: id required"
  local id="$1"
  _require jq

  local event
  event=$(jq -c --arg id "$id" 'select(.id == $id)' "$STORE")
  [ -z "$event" ] && _die "show: id not found: $id"

  echo "$event" | jq .
  local rca_id
  rca_id=$(echo "$event" | jq -r '.rca_id // empty')
  if [ -n "$rca_id" ] && [ -f "$RCA_DIR/$rca_id.md" ]; then
    echo
    _subhead "RCA  ($RCA_DIR/$rca_id.md)"
    cat "$RCA_DIR/$rca_id.md"
  fi
}

# ─── slugs ────────────────────────────────────────────────────────

cmd_slugs() {
  if [ ! -s "$STORE" ]; then _info "no events logged yet"; return 0; fi
  _require jq
  jq -r '.slug' "$STORE" | sort | uniq -c | sort -rn | \
    awk -v c="$C_DIM" -v r="$C_RESET" -v cy="$C_CYAN" '
      { printf "  %s%4d×%s  %s%s%s\n", c, $1, r, cy, $2, r }'
}

# ─── lock ─────────────────────────────────────────────────────────

cmd_lock() {
  [ -f "$STORE" ] || _die "lock: $STORE does not exist yet"

  if chflags uappnd "$STORE" 2>/dev/null; then
    _ok "chflags uappnd applied to events.jsonl"
  else
    _warn "uappnd may already be set or chflags failed (events.jsonl)"
  fi

  if [ -f "$JUDGMENTS_LOG" ]; then
    if chflags uappnd "$JUDGMENTS_LOG" 2>/dev/null; then
      _ok "chflags uappnd applied to judgments.jsonl"
    else
      _warn "uappnd may already be set or chflags failed (judgments.jsonl)"
    fi
  fi

  local count=0
  if [ -d "$RCA_DIR" ]; then
    while IFS= read -r -d '' f; do
      chflags uchg "$f" 2>/dev/null && count=$((count+1)) || true
      chmod 0444 "$f" 2>/dev/null || true
    done < <(find "$RCA_DIR" -type f -name '*.md' -print0)
  fi
  _ok "chflags uchg applied to $count RCA file(s)"

  echo
  _subhead "Flag state"
  ls -lO "$STORE"          2>/dev/null | awk '{ printf "  events.jsonl     %s\n", $5 }' | head -1
  ls -lO "$JUDGMENTS_LOG"  2>/dev/null | awk '{ printf "  judgments.jsonl  %s\n", $5 }' | head -1
}

# ─── unlock-check ─────────────────────────────────────────────────

cmd_unlock_check() {
  _subhead "Raw file flag state"
  if [ -f "$STORE" ]; then
    local flags
    flags=$(ls -lO "$STORE" 2>/dev/null | awk '{ print $5 }' | head -1)
    gum_kv "events.jsonl" "${flags:--}"
  else
    gum_kv "events.jsonl" "(not yet created)"
  fi
  if [ -d "$RCA_DIR" ]; then
    local n
    n=$(find "$RCA_DIR" -type f -name '*.md' | wc -l | tr -d ' ')
    gum_kv "rca/ files" "$n total"
    find "$RCA_DIR" -type f -name '*.md' -exec ls -lO {} \; 2>/dev/null | \
      awk '{ printf "    %s  %s\n", $5, $NF }'
  fi
}

# ─── feedback ─────────────────────────────────────────────────────
# Records signal-to-noise data for the trigger system:
#   - "fired-and-useful"   : trigger appeared, agent acted on it productively
#   - "fired-and-ignored"  : trigger appeared, agent ignored, mistake happened
#   - "fired-and-irrelevant": trigger appeared but wasn't applicable
#   - "missed"             : mistake happened, no trigger fired (atone covers
#                            this implicitly — the event itself is the signal)
# Foundation for L2 dream integration (pattern correlation).

FEEDBACK_LOG="$HOME/.claude/atone/feedback.jsonl"
FEEDBACK_LOCK="$HOME/.claude/atone/feedback.jsonl.lock"

cmd_feedback() {
  local kind="" slug="" event_id="" trigger_id="" notes=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --kind)       kind="$2"; shift 2 ;;
      --slug)       slug="$2"; shift 2 ;;
      --event-id)   event_id="$2"; shift 2 ;;
      --trigger-id) trigger_id="$2"; shift 2 ;;
      --notes)      notes="$2"; shift 2 ;;
      -h|--help)
        cat <<EOF

  atone feedback — record trigger-effectiveness signal

  Flags:
    --kind X       fired-and-useful | fired-and-ignored | fired-and-irrelevant | missed
    --slug S       atone/affirm slug the feedback is about
    --event-id E   (optional) specific event id this feedback responds to
    --trigger-id T (optional) the trigger id from triggers.json
    --notes N      (optional) free-form context

  Writes to ~/.claude/atone/feedback.jsonl (append-only).
EOF
        exit 0 ;;
      *) _die "feedback: unknown flag: $1" ;;
    esac
  done
  [ -z "$kind" ] && _die "feedback: --kind required"
  [ -z "$slug" ] && _die "feedback: --slug required"
  case "$kind" in
    fired-and-useful|fired-and-ignored|fired-and-irrelevant|missed) ;;
    *) _die "feedback: --kind must be one of fired-and-useful|fired-and-ignored|fired-and-irrelevant|missed" ;;
  esac

  _require jq
  local line
  line=$(jq -cn \
    --arg id "fbk-$(date -u '+%Y%m%d-%H%M%S')-$(printf '%02x' $((RANDOM % 256)))" \
    --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --arg kind "$kind" --arg slug "$slug" --arg event_id "$event_id" \
    --arg trigger_id "$trigger_id" --arg notes "$notes" \
    '{
       id: $id, ts: $ts, kind: $kind, slug: $slug,
       event_id: (if $event_id == "" then null else $event_id end),
       trigger_id: (if $trigger_id == "" then null else $trigger_id end),
       notes: (if $notes == "" then null else $notes end)
     }')

  (
    flock -x 9 2>/dev/null || true
    printf '%s\n' "$line" >> "$FEEDBACK_LOG"
  ) 9>>"$FEEDBACK_LOCK"

  _ok "recorded feedback for slug=$slug kind=$kind"
}

# ─── juror — record one verdict to judgments.jsonl ───────────────
# Called by the /atone skill after a sub-agent dispatch returned a JSON
# verdict (or by hand for testing). Append-only — never updates existing
# judgment lines. Outcome can be set via --outcome (atoned | pushed-back-then-
# atoned | pushed-back-then-accepted | pending).

JUDGMENTS_LOG="$HOME/.claude/atone/judgments.jsonl"
JUDGMENTS_LOCK="$HOME/.claude/atone/judgments.jsonl.lock"

cmd_juror() {
  local user_callout="" agent_did="" agent_defense="" context_summary=""
  local verdict="" confidence="" reasoning="" should_have_done=""
  local outcome="pending" linked_atone_event_id=""
  local slips_str="" constraints_str="" related_slugs_str=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --user-callout)        user_callout="$2"; shift 2 ;;
      --agent-did)           agent_did="$2"; shift 2 ;;
      --agent-defense)       agent_defense="$2"; shift 2 ;;
      --context)             context_summary="$2"; shift 2 ;;
      --verdict)             verdict="$2"; shift 2 ;;
      --confidence)          confidence="$2"; shift 2 ;;
      --reasoning)           reasoning="$2"; shift 2 ;;
      --slips)               slips_str="$2"; shift 2 ;;
      --constraints)         constraints_str="$2"; shift 2 ;;
      --should-have-done)    should_have_done="$2"; shift 2 ;;
      --related-slugs)       related_slugs_str="$2"; shift 2 ;;
      --outcome)             outcome="$2"; shift 2 ;;
      --linked-event-id)     linked_atone_event_id="$2"; shift 2 ;;
      -h|--help)
        cat <<'EOF'

  atone juror — record one juror verdict

  Required:
    --user-callout S       verbatim user message that triggered atone
    --agent-did S          what the agent did (1-2 sentences)
    --agent-defense S      agent's case for what it did (1 paragraph)
    --context S            codebase / task / scope summary (≤500 chars)
    --verdict X            very-wrong | understandably-wrong | ambiguous
                           | probably-right | reasonably-right
    --confidence X         low | medium | high
    --reasoning S          juror's reasoning paragraphs

  Optional:
    --slips "a|b|c"        pipe-delimited slip descriptions
    --constraints "a|b"    pipe-delimited constraints considered
    --should-have-done S   alternative action the agent could have taken
    --related-slugs "a b"  space-separated atone slugs this incident matches
    --outcome X            atoned | pushed-back-then-atoned
                           | pushed-back-then-accepted | pending  (default: pending)
    --linked-event-id ID   atone event id this judgment links to (if /atone proceeded)

  Returns: the new judgment id on stdout.
EOF
        exit 0 ;;
      *) _die "juror: unknown flag: $1" ;;
    esac
  done

  for f in user_callout agent_did agent_defense context_summary verdict confidence reasoning; do
    if [ -z "${!f}" ]; then
      _die "juror: --${f//_/-} required"
    fi
  done

  case "$verdict" in
    very-wrong|understandably-wrong|ambiguous|probably-right|reasonably-right) ;;
    *) _die "juror: --verdict must be one of: very-wrong | understandably-wrong | ambiguous | probably-right | reasonably-right (got: $verdict)" ;;
  esac
  case "$confidence" in
    low|medium|high) ;;
    *) _die "juror: --confidence must be low | medium | high (got: $confidence)" ;;
  esac
  case "$outcome" in
    atoned|pushed-back-then-atoned|pushed-back-then-accepted|pending) ;;
    *) _die "juror: --outcome must be atoned | pushed-back-then-atoned | pushed-back-then-accepted | pending (got: $outcome)" ;;
  esac

  _require jq

  local id ts
  id=$(printf 'judg-%s-%02x' "$(date -u '+%Y%m%d-%H%M%S')" $((RANDOM % 256)))
  ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

  # Convert pipe-delimited / space-delimited strings to JSON arrays via jq
  local line
  line=$(jq -cn \
    --arg id "$id" --arg ts "$ts" \
    --arg session_id "${CLAUDE_SESSION_ID:-}" \
    --arg user_callout "$user_callout" \
    --arg agent_did "$agent_did" \
    --arg agent_defense "$agent_defense" \
    --arg context_summary "$context_summary" \
    --arg verdict "$verdict" --arg confidence "$confidence" \
    --arg reasoning "$reasoning" --arg should_have_done "$should_have_done" \
    --arg slips_str "$slips_str" --arg constraints_str "$constraints_str" \
    --arg related_slugs_str "$related_slugs_str" \
    --arg outcome "$outcome" --arg linked_event_id "$linked_atone_event_id" \
    '{
       id: $id, ts: $ts, session_id: ($session_id // ""),
       user_callout: $user_callout,
       agent_did: $agent_did,
       agent_defense: $agent_defense,
       context_summary: $context_summary,
       verdict: $verdict, confidence: $confidence,
       reasoning: $reasoning,
       slips_identified:       ($slips_str          | split("|") | map(select(length > 0))),
       constraints_considered: ($constraints_str    | split("|") | map(select(length > 0))),
       should_have_done: $should_have_done,
       related_atone_slugs:    ($related_slugs_str  | split(" ") | map(select(length > 0))),
       outcome: $outcome,
       linked_atone_event_id: (if $linked_event_id == "" then null else $linked_event_id end)
     }')

  (
    flock -x 9 2>/dev/null || true
    printf '%s\n' "$line" >> "$JUDGMENTS_LOG"
  ) 9>>"$JUDGMENTS_LOCK"

  # Auto-commit (same git repo as events)
  ( cd "$ATONE_DIR" && git add judgments.jsonl 2>/dev/null && \
    if ! git diff --cached --quiet 2>/dev/null; then
      git commit -q -m "juror: $id verdict=$verdict outcome=$outcome" 2>/dev/null
    fi ) || true

  _ok "recorded judgment $id"
  gum_kv "verdict"    "$verdict"
  gum_kv "confidence" "$confidence"
  gum_kv "outcome"    "$outcome"
  echo "$id"
}

# ─── judgments — list / show / stats ──────────────────────────────

cmd_judgments() {
  local sub="${1:-list}"
  shift 2>/dev/null || true

  case "$sub" in
    list)
      local f_verdict="" f_outcome="" f_slug=""
      while [ $# -gt 0 ]; do
        case "$1" in
          --verdict) f_verdict="$2"; shift 2 ;;
          --outcome) f_outcome="$2"; shift 2 ;;
          --slug)    f_slug="$2"; shift 2 ;;
          *) _die "judgments list: unknown flag: $1" ;;
        esac
      done
      [ -s "$JUDGMENTS_LOG" ] || { _info "no judgments recorded yet"; return 0; }
      _require jq
      local filter='.'
      [ -n "$f_verdict" ] && filter="$filter | select(.verdict == \"$f_verdict\")"
      [ -n "$f_outcome" ] && filter="$filter | select(.outcome == \"$f_outcome\")"
      [ -n "$f_slug" ]    && filter="$filter | select(.related_atone_slugs // [] | any(. == \"$f_slug\"))"
      jq -r "$filter | [.ts[:10], .id, .verdict, .confidence, .outcome] | @tsv" "$JUDGMENTS_LOG" | \
        awk -F'\t' '{ printf "%-10s  %-26s  %-22s  %-7s  %s\n", $1, $2, $3, $4, $5 }'
      ;;

    show)
      [ $# -lt 1 ] && _die "judgments show: id required"
      _require jq
      jq -c --arg id "$1" 'select(.id == $id)' "$JUDGMENTS_LOG" | jq .
      ;;

    stats)
      [ -s "$JUDGMENTS_LOG" ] || { _info "no judgments recorded yet"; return 0; }
      _require jq
      _subhead "Verdict distribution"
      jq -r '.verdict' "$JUDGMENTS_LOG" | sort | uniq -c | sort -rn | \
        awk -v g="$C_GREEN" -v r="$C_RESET" -v d="$C_DIM" \
          '{ printf "  %s%-22s%s  %s%4d%s\n", g, $2, r, d, $1, r }'
      _subhead "Outcome distribution"
      jq -r '.outcome' "$JUDGMENTS_LOG" | sort | uniq -c | sort -rn | \
        awk -v c="$C_CYAN" -v r="$C_RESET" -v d="$C_DIM" \
          '{ printf "  %s%-32s%s  %s%4d%s\n", c, $2, r, d, $1, r }'
      _subhead "Confidence distribution"
      jq -r '.confidence' "$JUDGMENTS_LOG" | sort | uniq -c | sort -rn | \
        awk -v r="$C_RESET" -v d="$C_DIM" \
          '{ printf "  %-10s  %s%4d%s\n", $2, d, $1, r }'

      _subhead "Pushback effectiveness"
      local total pb_atoned pb_accepted
      total=$(wc -l < "$JUDGMENTS_LOG" | tr -d ' ')
      pb_atoned=$(jq -r 'select(.outcome == "pushed-back-then-atoned") | .id' "$JUDGMENTS_LOG" | wc -l | tr -d ' ')
      pb_accepted=$(jq -r 'select(.outcome == "pushed-back-then-accepted") | .id' "$JUDGMENTS_LOG" | wc -l | tr -d ' ')
      gum_kv "total judgments"          "$total"
      gum_kv "pushed-back-then-atoned"  "$pb_atoned (user overruled juror)"
      gum_kv "pushed-back-then-accepted" "$pb_accepted (juror saved an unjustified atone)"
      if [ "$((pb_atoned + pb_accepted))" -gt 0 ]; then
        local accept_pct=$(awk -v a="$pb_accepted" -v t="$((pb_atoned + pb_accepted))" 'BEGIN { printf "%.0f", 100*a/t }')
        gum_kv "juror save-rate"          "${accept_pct}% of pushbacks survived"
      fi
      ;;

    -h|--help|help)
      cat <<'EOF'

  atone judgments — inspect judgment records

  Subcommands:
    list [--verdict X] [--outcome Y] [--slug Z]   tabular listing
    show <id>                                      full record + reasoning
    stats                                          verdict/outcome/confidence dist
EOF
      ;;
    *) _die "judgments: unknown subcommand: $sub" ;;
  esac
}

# ─── stats ────────────────────────────────────────────────────────

cmd_stats() {
  if [ ! -s "$STORE" ]; then _info "no events logged yet"; return 0; fi
  _require jq

  _subhead "Severity distribution"
  jq -r '.severity' "$STORE" | sort | uniq -c | sort -rn | \
    awk -v g="$C_GREEN" -v r="$C_RESET" -v d="$C_DIM" \
      '{ printf "  %s%-2s%s  %s%4d events%s\n", g, $2, r, d, $1, r }'

  _subhead "Cluster distribution"
  jq -r '.cluster // "-"' "$STORE" | sort | uniq -c | sort -rn | \
    awk -v c="$C_CYAN" -v r="$C_RESET" -v d="$C_DIM" \
      '{ printf "  %s%-2s%s  %s%4d events%s\n", c, $2, r, d, $1, r }'

  _subhead "Top 10 recurring slugs"
  jq -r '.slug' "$STORE" | sort | uniq -c | sort -rn | head -10 | \
    awk -v d="$C_DIM" -v r="$C_RESET" -v cy="$C_CYAN" \
      '{ printf "  %s%4d×%s  %s%s%s\n", d, $1, r, cy, $2, r }'

  _subhead "Recent event rate"
  local total now_epoch
  total=$(wc -l < "$STORE" | tr -d ' ')
  now_epoch=$(date +%s)
  # Last 7 days
  local last_7d
  last_7d=$(jq -r --argjson cutoff "$((now_epoch - 7*86400))" '
    select((.ts | fromdateiso8601) > $cutoff) | .id
  ' "$STORE" 2>/dev/null | wc -l | tr -d ' ')
  local last_30d
  last_30d=$(jq -r --argjson cutoff "$((now_epoch - 30*86400))" '
    select((.ts | fromdateiso8601) > $cutoff) | .id
  ' "$STORE" 2>/dev/null | wc -l | tr -d ' ')
  gum_kv "total events"    "$total"
  gum_kv "last 7 days"     "$last_7d"
  gum_kv "last 30 days"    "$last_30d"

  _subhead "Latest event"
  jq -c '.' "$STORE" | tail -1 | jq -r '"  " + .ts[:10] + "  " + .id + "  [" + .severity + "]  " + .slug'
}

# ─── triggers ─────────────────────────────────────────────────────

cmd_triggers() {
  [ $# -lt 1 ] && _die "triggers: keyword required"
  local kw="$1"
  local file="$HOME/.claude/atone/derived/triggers.json"
  [ -f "$file" ] || _die "triggers: no triggers.json yet — run atone-consolidate.sh"
  _require jq

  # First — gather slugs whose underlying events have a matching tag.
  # Search BOTH the atone log and the affirm log.
  local matching_slugs affirm_store="$HOME/.claude/affirm/events.jsonl"
  matching_slugs=$(
    {
      [ -f "$STORE" ]        && cat "$STORE"
      [ -f "$affirm_store" ] && cat "$affirm_store"
    } | jq -r --arg kw "$kw" '
      select((.tags // []) | join(" ") | ascii_downcase | contains($kw | ascii_downcase))
      | .slug
    ' 2>/dev/null | sort -u
  )

  jq -r --arg kw "$kw" --arg slugs "$matching_slugs" '
    ($slugs | split("\n") | map(select(length>0))) as $tagged
    | [.[] | . as $e | select(
        (.from_slug | ascii_downcase | contains($kw | ascii_downcase)) or
        ((.match.topic_keywords // []) | any(. | ascii_downcase | contains($kw | ascii_downcase))) or
        ((.instruction // "") | ascii_downcase | contains($kw | ascii_downcase)) or
        ($tagged | index($e.from_slug))
      )]
    | sort_by([(.weight | (if . == "high" then 3 elif . == "medium" then 2 else 1 end)), .confidence_score])
    | reverse | .[]
    | "[\(.weight) · \(.from_source)] \(.from_slug)\n  \(.instruction)\n  → \(.deep_link)\n"
  ' "$file"
}

# ─── Dispatch ─────────────────────────────────────────────────────

case "${1:-help}" in
  add)             shift; cmd_add "$@" ;;
  list)            shift; cmd_list "$@" ;;
  search)          shift; cmd_search "$@" ;;
  show)            shift; cmd_show "$@" ;;
  slugs)           shift; cmd_slugs "$@" ;;
  stats)           shift; cmd_stats "$@" ;;
  triggers)        shift; cmd_triggers "$@" ;;
  feedback)        shift; cmd_feedback "$@" ;;
  juror)           shift; cmd_juror "$@" ;;
  judgments)       shift; cmd_judgments "$@" ;;
  lock)            shift; cmd_lock "$@" ;;
  unlock-check)    shift; cmd_unlock_check "$@" ;;
  help|-h|--help)  show_help ;;
  *) _err "unknown subcommand: $1"; show_help; exit 2 ;;
esac
