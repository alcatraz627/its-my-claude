#!/usr/bin/env bash
# Auto-extracted from atone-consolidate.sh by the split refactor (2026-05-15).
# This file is intended to be sourced (not executed) by atone-consolidate.sh.
# Functions defined here rely on env vars + helpers from atone-common.sh
# and atone-consolidate/helpers.sh.

# ─── Triggers.json builder ────────────────────────────────────────

build_triggers() {
  local out="$DERIVED/triggers.json"
  # Tuned so single-event S3/S2 patterns are included (medium); only stale or
  # very-low-recency patterns drop to low and get excluded.
  local high_threshold=3.0 med_threshold=0.5

  {
    printf '['
    local first=1
    while IFS=$'\t' read -r src slug cnt sev_str ts cluster title latest_id; do
      [ -z "$slug" ] && continue
      local sev_int days score weight
      sev_int=$(_sev_max_to_int "$sev_str")
      days=$(_days_since "${ts:0:10}")
      score=$(_score_for "$sev_int" "$days" "$cnt")
      # Weight bands
      if awk -v s="$score" -v t="$high_threshold" 'BEGIN{exit (s>=t)?0:1}'; then
        weight=high
      elif awk -v s="$score" -v t="$med_threshold" 'BEGIN{exit (s>=t)?0:1}'; then
        weight=medium
      else
        weight=low
      fi
      [ "$weight" = "low" ] && continue  # skip low-weight in triggers.json

      [ "$first" = "1" ] || printf ','
      first=0
      jq -cn \
        --arg src "$src" --arg slug "$slug" --arg weight "$weight" \
        --arg score "$score" --arg sev "$sev_str" --arg cluster "$cluster" \
        --arg title "$title" --arg latest_id "$latest_id" \
        --argjson cnt "$cnt" \
        '{
          id: ("trig-" + $slug),
          from_slug: $slug,
          from_source: $src,
          weight: $weight,
          confidence_score: ($score | tonumber),
          actionable: true,
          severity_band: $sev,
          cluster: (if $cluster == "" then null else $cluster end),
          count: $cnt,
          match: {
            tool_signatures: [],
            content_regex: null,
            topic_keywords: ($slug | split("-") | map(select(length>2)))
          },
          instruction: $title,
          deep_link: ("~/.claude/atone/events.jsonl#" + $latest_id)
        }'
    done < <(
      aggregate_slugs atone "${EVENTS_VIEW:-$EVENTS}"
      aggregate_slugs affirm "$AFFIRM_EVENTS"
    )
    printf ']\n'
  } > "$out.tmp" && mv "$out.tmp" "$out"
  _ok "wrote triggers.json ($(jq 'length' "$out") entries)"
}

