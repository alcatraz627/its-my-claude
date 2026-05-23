#!/usr/bin/env bash
# Auto-extracted from atone-consolidate.sh by the split refactor (2026-05-15).
# This file is intended to be sourced (not executed) by atone-consolidate.sh.
# Functions defined here rely on env vars + helpers from atone-common.sh
# and atone-consolidate/helpers.sh.

# ─── TL;DR builder ────────────────────────────────────────────────

build_tldr() {
  local out="$DERIVED/_tldr.txt"
  {
    printf 'Top mistake patterns to watch this session:\n'
    aggregate_slugs atone "${EVENTS_VIEW:-$EVENTS}" | while IFS=$'\t' read -r src slug cnt sev_str ts cluster title latest_id; do
      [ -z "$slug" ] && continue
      local sev_int days score
      sev_int=$(_sev_max_to_int "$sev_str")
      days=$(_days_since "${ts:0:10}")
      score=$(_score_for "$sev_int" "$days" "$cnt")
      printf '%s\t%s\t%dx\t%s\t%s\n' "$score" "$sev_str" "$cnt" "$slug" "$title"
    done | sort -rn | head -5 | awk -F'\t' '{
      printf "  ⚠️  [%s, %s] %s — %s\n", $2, $3, $4, $5
    }'

    if [ -f "$AFFIRM_EVENTS" ] && [ -s "$AFFIRM_EVENTS" ]; then
      printf '\nAffirmed-good behaviors to repeat:\n'
      aggregate_slugs affirm "$AFFIRM_EVENTS" | while IFS=$'\t' read -r src slug cnt sev_str ts cluster title latest_id; do
        [ -z "$slug" ] && continue
        local days score
        days=$(_days_since "${ts:0:10}")
        score=$(_score_for 1 "$days" "$cnt")
        printf '%s\t%dx\t%s\t%s\n' "$score" "$cnt" "$slug" "$title"
      done | sort -rn | head -3 | awk -F'\t' '{
        printf "  ✓   [%s] %s — %s\n", $2, $3, $4
      }'
    fi
  } > "$out.tmp" && mv "$out.tmp" "$out"
  _ok "wrote _tldr.txt"
}

