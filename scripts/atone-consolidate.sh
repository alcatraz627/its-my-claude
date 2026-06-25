#!/usr/bin/env bash
# atone-consolidate.sh — regenerate derived views from the raw atone log.
#
# READS  (read-only):  ~/.claude/atone/events.jsonl
#                      ~/.claude/atone/rca/*.md
#                      ~/.claude/affirm/events.jsonl  (if present)
# WRITES (regenerate): ~/.claude/atone/derived/index.md
#                      ~/.claude/atone/derived/archive.md
#                      ~/.claude/atone/derived/clusters/<A-E>.md
#                      ~/.claude/atone/derived/_meta.json
#                      ~/.claude/atone/derived/_tldr.txt
#                      ~/.claude/atone/derived/triggers.json
#                      ~/.claude/atone/derived/intervention-efficacy.json
#                      ~/.claude/mistake-patterns.md            (v2 curated)
#                      ~/.claude/compliments.md                 (v2, if affirm/)
#                      ~/.claude/topics/atone-consolidate-YYYY-MM-DD.md (report)
#
# MUST NOT touch:      anything in atone/events.jsonl, atone/rca/, affirm/events.jsonl
#
# Modes:
#   (default)             full regeneration
#   --triggers-only       fast-path: rebuild only triggers.json + _tldr.txt (<1s)
#   --first-run           skip the "23h since last run" idempotency guard
#   --force               same as --first-run but also rebuilds even if hash matches
#   --help

# Note: bash 3.2 (macOS default) lacks `declare -A`; we use a function instead.
# `set -u` is too brittle for shell of this size — keep pipefail only.
set -o pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/atone-common.sh"

# ─── Source split builder files ──────────────────────────────────
SPLIT_DIR="$(dirname "${BASH_SOURCE[0]}")/atone-consolidate"
# shellcheck disable=SC1091
for f in helpers.sh build-triggers.sh build-tldr.sh build-index.sh \
         build-clusters.sh build-curated-atone.sh build-curated-affirm.sh \
         build-proposals.sh build-meta.sh build-efficacy.sh build-topics-report.sh; do
  source "$SPLIT_DIR/$f"
done


ATONE_DIR="$HOME/.claude/atone"
AFFIRM_DIR="$HOME/.claude/affirm"
DERIVED="$ATONE_DIR/derived"
DERIVED_BAK="$ATONE_DIR/derived.bak"
EVENTS="$ATONE_DIR/events.jsonl"
AFFIRM_EVENTS="$AFFIRM_DIR/events.jsonl"
META="$DERIVED/_meta.json"
LAST_RUN_MARKER="$DERIVED/.last-run-ts"

# Synthetic test/debug slugs generated while building the atone/juror system —
# kept in the immutable raw log, but excluded from the human-facing VIEWS so
# they don't skew the curated top-20, TL;DR, proposals, or cluster counts.
# ANCHORED to the specific synthetic stems (each `^`-rooted) rather than loose
# substrings, so real slugs like `final-exit-handler`, `not-gated-properly`, or
# `test-driven-dev` are NOT swept up. A new synthetic stem gets a new alternative.
EVENTS_VIEW="$DERIVED/.events-view.jsonl"
ATONE_TEST_SLUG_RE='^(smoke-bypass|repeat-test|brand-new-slug|totally-unique|stop-hook-test|stop-test|test-gate-bypass|test-juror|test-s2-not-gated|test-final-exit)'
TOPICS_DIR="$HOME/.claude/topics"
CURATED="$HOME/.claude/mistake-patterns.md"
COMPLIMENTS="$HOME/.claude/compliments.md"
TODAY=$(date +%Y-%m-%d)
NOW_UTC=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# ─── Help ─────────────────────────────────────────────────────────

show_help() {
  printf '\n  %s%satone-consolidate%s %s—%s Regenerate derived views from raw event log\n' \
    "$C_BOLD" "$C_MAGENTA" "$C_RESET" "$C_DIM" "$C_RESET"

  _section "USAGE"
  _cmd 'atone-consolidate.sh'              'full regen (skip if <23h since last run)'
  _cmd 'atone-consolidate.sh --triggers-only'  'fast (~1s): rebuild triggers.json + _tldr.txt only'
  _cmd 'atone-consolidate.sh --first-run'  'bypass 23h idempotency guard'
  _cmd 'atone-consolidate.sh --force'      'rebuild even if content hash unchanged'

  _section "WRITES"
  _dim "~/.claude/mistake-patterns.md             v2 curated (TL;DR + top 20)"
  _dim "~/.claude/compliments.md                  v2 affirm view"
  _dim "~/.claude/atone/derived/index.md          full event index"
  _dim "~/.claude/atone/derived/archive.md        ranks 21+"
  _dim "~/.claude/atone/derived/clusters/A-E.md   per-cluster aggregations"
  _dim "~/.claude/atone/derived/triggers.json     unified lookup (atone+affirm)"
  _dim "~/.claude/atone/derived/_tldr.txt         pre-rendered top-5 (hinter input)"
  _dim "~/.claude/atone/derived/_meta.json        run metadata + content hash"
  _dim "~/.claude/topics/atone-consolidate-<date>.md  human-readable report"
  echo
}

# ─── Mode parsing ─────────────────────────────────────────────────

MODE=full
case "${1:-}" in
  -h|--help|help)   show_help; exit 0 ;;
  --triggers-only)  MODE=triggers ;;
  --first-run)      MODE=force ;;
  --force)          MODE=force ;;
  # A6: i-dream's DreamPass invokes consolidation with --read-only (per
  # .i-dream-domain.toml). Rebuild the derived VIEWS but skip the only external
  # side-effects: drafting proposals + git-committing. Used by the dream pass to
  # refresh inputs without mutating the proposals backlog.
  --read-only)      MODE=force; ATONE_READONLY=1 ;;
  '') ;;
  *) _err "unknown flag: $1"; show_help; exit 2 ;;
esac

_require jq


# ─── Helpers ──────────────────────────────────────────────────────

mkdir -p "$DERIVED/clusters" "$DERIVED_BAK" "$TOPICS_DIR"














# ─── Proposal routing ─────────────────────────────────────────────
# For each qualifying pattern (≥3 recurrences OR S3), pick a graduation target
# based on slug characteristics, draft a proposal payload, and append to
# ~/.claude/proposals.jsonl via propose.sh — UNLESS we've already proposed for
# this slug (idempotency check).
#
# Targets (routing matrix):
#   hook-draft        → ~/.claude/hinters/<n>-X.sh    (mechanically detectable)
#   skill-enhancement → skills/<name>/SKILL.md         (domain matches a skill)
#   project-claude-md → <project>/.claude/CLAUDE.md    (project-specific)
#   claude-md-rule    → ~/.claude/CLAUDE.md (Tier-0)   (short cross-cutting)
#   rules-entry       → ~/.claude/rules/<slug>.md      (nuanced behavioral)
#
# All proposals get type=atone-prevention with the source slug for lineage.
# Nothing auto-applies. User reviews via: bash ~/.claude/scripts/propose.sh list

PROPOSALS_JSONL="$HOME/.claude/proposals.jsonl"







# ─── Main ─────────────────────────────────────────────────────────

# Build the filtered view EVERY human-facing builder reads (the raw log is never
# touched). Built here, before the mode branch, so the --triggers-only fast-path
# — which feeds the per-session TL;DR hinter and triggers.json — is filtered too.
# On any failure, fall back to the raw log so a bad regex can't blank the views.
if [ -f "$EVENTS" ] && jq -c --arg re "$ATONE_TEST_SLUG_RE" 'select((.slug // "") | test($re) | not)' "$EVENTS" > "$EVENTS_VIEW.tmp" 2>/dev/null; then
  mv "$EVENTS_VIEW.tmp" "$EVENTS_VIEW"
else
  EVENTS_VIEW="$EVENTS"
fi

if [ "$MODE" = "triggers" ]; then
  _info "fast-path: rebuilding triggers.json + _tldr.txt only"
  build_triggers
  build_tldr
  exit 0
fi

# Idempotency guard (full mode)
if [ "$MODE" != "force" ]; then
  if [ "$(last_run_seconds_ago)" -lt 82800 ]; then  # 23h
    _info "<23h since last run — use --force to rebuild anyway"
    exit 0
  fi
  if [ -f "$META" ]; then
    prev_hash=$(jq -r '.input_hash // empty' "$META" 2>/dev/null)
    cur_hash=$(_input_hash)
    if [ -n "$prev_hash" ] && [ "$prev_hash" = "$cur_hash" ]; then
      _info "input hash unchanged — skipping (use --force to rebuild)"
      exit 0
    fi
  fi
fi

_info "full consolidation: backing up derived/ → derived.bak/"
rsync -a --delete "$DERIVED/" "$DERIVED_BAK/" 2>/dev/null || true
_info "view: $(wc -l < "$EVENTS_VIEW" 2>/dev/null | tr -d ' ') of $(wc -l < "$EVENTS" 2>/dev/null | tr -d ' ') events (test slugs filtered)"

build_index
build_clusters
build_curated_atone
build_curated_affirm
build_triggers
build_tldr
build_proposals
build_meta
build_efficacy
build_topics_report

# Mark last-run
echo "$NOW_UTC" > "$LAST_RUN_MARKER"

echo
_subhead "Done"
gum_kv "events"   "$(wc -l < "$EVENTS" 2>/dev/null | tr -d ' ')"
gum_kv "triggers" "$(jq 'length' "$DERIVED/triggers.json" 2>/dev/null || echo 0)"
gum_kv "report"   "$TOPICS_DIR/atone-consolidate-$TODAY.md"
