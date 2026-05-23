#!/usr/bin/env bash
# Auto-extracted from atone-consolidate.sh by the split refactor (2026-05-15).
# This file is intended to be sourced (not executed) by atone-consolidate.sh.
# Functions defined here rely on env vars + helpers from atone-common.sh
# and atone-consolidate/helpers.sh.

# ─── _meta.json ───────────────────────────────────────────────────

build_meta() {
  local out="$META"
  local hash event_count slug_count affirm_count
  hash=$(_input_hash)
  event_count=0; slug_count=0; affirm_count=0
  [ -f "$EVENTS" ]        && event_count=$(wc -l < "$EVENTS" | tr -d ' ')
  [ -f "$EVENTS" ]        && slug_count=$(jq -r '.slug' "$EVENTS" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  [ -f "$AFFIRM_EVENTS" ] && affirm_count=$(wc -l < "$AFFIRM_EVENTS" | tr -d ' ')
  jq -n --arg ts "$NOW_UTC" --arg hash "$hash" \
    --argjson events "$event_count" --argjson slugs "$slug_count" \
    --argjson affirms "$affirm_count" \
    '{
       generated_at: $ts,
       input_hash: $hash,
       event_count: $events,
       slug_count: $slugs,
       affirm_count: $affirms
     }' > "$out.tmp" && mv "$out.tmp" "$out"
  _ok "wrote _meta.json"
}

