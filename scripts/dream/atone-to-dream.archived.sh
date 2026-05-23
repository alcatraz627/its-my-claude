#!/usr/bin/env bash
# ============================================================================
# ARCHIVED — DO NOT RUN. Reference artifact only. (retired 2026-05-21)
# ============================================================================
#
# WHAT THIS WAS
#   A bridge to feed atone mistake patterns (recurring/S3 slugs, by cluster)
#   into the i-dream ingest queue so they would participate in the dream
#   daemon's association detection. It mapped each signal slug onto the same
#   JSON schema `subconscious/scripts/ingest-checkpoint.sh` produces.
#
# WHY IT WAS RETIRED
#   It rested on an UNVERIFIED, FALSE premise: "the existing daemon consumes
#   ingest-queue with zero engine changes." It does not. The ONLY consumer of
#   ingest-queue is `subconscious/scripts/aggregate-todos.sh`, which extracts
#   `pending[]` into the forgotten-todos backlog (pending-todos.jsonl). The
#   i-dream Rust daemon has NO ingest-queue reader (`rg "ingest-queue" src/`
#   is empty, per the i-dream agent who owns that source). So this bridge
#   produced ZERO dream associations and would have polluted forgotten-todos
#   with atone prechecks. Mistake class: structural-claim-without-reading-code.
#
# THE CANONICAL PATH (use this instead)
#   The i-dream dream-domain PLUGIN reads `~/.claude/atone/events.jsonl`
#   directly; its cross-domain join pass produces the slug/cluster correlations
#   this bridge was trying to create (verified: a real pass produced 5 atone
#   insights + cross-domain links). atone reaches dreaming via that plugin, plus
#   the `_tldr` staple in `scripts/dream/dream-insights.sh`. Do not re-wire this.
#
# WHAT IT'S A USEFUL REFERENCE FOR
#   Keep ONLY as a pattern source. If the daemon ever gains a DELIBERATE
#   ingest-queue→associations consumer (a chosen parallel target to the plugin),
#   the reusable pieces below are:
#     1. atone-event → ingest-schema field mapping (issue→didnt_work,
#        cause→gotchas, fix/what_not→notes, precheck→pending, slug/cluster/
#        severity→tags) — see the jq block ~line 80 below.
#     2. cluster-map.tsv → jq object overlay (line ~33) — same trick build-
#        clusters.sh uses to bucket null-cluster events.
#     3. Idempotency marker pattern (.dream-bridged.tsv): slug→latest-event-id,
#        re-emit only when the latest id changes. Aggregate-to-temp + exit-check
#        before touching the marker so a jq failure can't blank it (line ~40).
#     4. Signal selection: severity S3 OR recurrence count>=2.
#
# CONTEXT POINTERS
#   - Report: ~/.claude/assets/reports/20260521-atone-dream-bridge/report.md
#     (carries the CORRECTION banner explaining the retirement).
#   - atone event: search `bash ~/.claude/scripts/atone.sh search structural-claim`.
# ============================================================================

echo "atone-to-dream.archived.sh is ARCHIVED — reference only, not for execution." >&2
echo "See the header for the canonical path (i-dream dream-domain plugin)." >&2
exit 2

# --- ORIGINAL LOGIC PRESERVED BELOW FOR REFERENCE (unreachable) -------------

set -uo pipefail

ATONE_DIR="$HOME/.claude/atone"
SRC="$ATONE_DIR/derived/.events-view.jsonl"
[ -f "$SRC" ] || SRC="$ATONE_DIR/events.jsonl"
[ -f "$SRC" ] || { echo "atone-to-dream: no events to bridge"; exit 0; }

MAP="$ATONE_DIR/cluster-map.tsv"
QUEUE="$HOME/.claude/subconscious/dreams/ingest-queue"
MARK="$ATONE_DIR/derived/.dream-bridged.tsv"
[ -d "$(dirname "$QUEUE")" ] || { echo "atone-to-dream: dream queue parent missing — is i-dream installed?"; exit 0; }
mkdir -p "$QUEUE" "$(dirname "$MARK")"

command -v jq >/dev/null 2>&1 || { echo "atone-to-dream: jq required"; exit 0; }

# cluster-map.tsv → jq object literal (same overlay build-clusters uses).
map_inner=$(awk -F'\t' '$1 !~ /^#/ && NF>=2 {printf "%s\"%s\":\"%s\"", sep, $1, $2; sep=","}' "$MAP" 2>/dev/null)
map_json="{${map_inner}}"

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
emitted=0; skipped=0
AGG="$ATONE_DIR/derived/.dream-agg.jsonl"

# Aggregate to a temp file FIRST and check the exit code. If jq fails, abort
# WITHOUT touching the marker — otherwise an empty result would blank the marker
# and the next run would re-emit every slug as duplicates.
if ! jq -cs --argjson map "$map_json" '
    group_by(.slug)
    | map({ slug: .[0].slug, count: length,
            max_sev: (map(.severity // "S2") | max),
            latest: (sort_by(.ts) | last) })
    | map(select(.max_sev == "S3" or .count >= 2))
    | .[]
    | { slug, count, max_sev,
        cluster:  (.latest.cluster // ($map[.slug] // null)),
        id:       .latest.id,
        issue:    (.latest.issue // ""),
        cause:    (.latest.cause // ""),
        fix:      (.latest.fix // ""),
        what_not: (.latest.what_not_to_do // ""),
        precheck: (.latest.precheck // ""),
        project:  (.latest.project // ""),
        rca_id:   (.latest.rca_id // null) }
  ' "$SRC" > "$AGG" 2>/dev/null; then
  echo "atone-to-dream: aggregation failed — marker left untouched, nothing emitted" >&2
  exit 1
fi

: > "$MARK.tmp"

# One compact JSON object per SIGNAL slug (latest event's fields + cluster overlay).
while IFS= read -r obj; do
  [ -n "$obj" ] || continue
  slug=$(printf '%s' "$obj" | jq -r '.slug // empty')
  id=$(printf '%s' "$obj" | jq -r '.id // empty')
  [ -n "$slug" ] && [ -n "$id" ] || continue

  printf '%s\t%s\n' "$slug" "$id" >> "$MARK.tmp"
  prev=$(rg -N "^$(printf '%s' "$slug" | sed 's/[.[\*^$/]/\\&/g')\t" "$MARK" 2>/dev/null | head -1 | cut -f2)
  if [ "$prev" = "$id" ]; then skipped=$((skipped + 1)); continue; fi

  slug_safe=$(printf '%s' "$slug" | tr -cd 'a-z0-9-')
  out="$QUEUE/${ts//:/}-atone-${slug_safe}.json"
  printf '%s' "$obj" | jq --arg ts "$ts" --arg home "$HOME" '{
    ts: $ts,
    session_id: ("atone:" + .slug),
    project_root: (if (.project // "") == "" then ($home + "/.claude") else .project end),
    checkpoint_path: (if .rca_id then ($home + "/.claude/atone/rca/" + .rca_id + ".md")
                      else ($home + "/.claude/atone/events.jsonl#" + .id) end),
    source: "atone",
    insights: {
      worked: [],
      didnt_work: ([.issue] | map(select(. != ""))),
      gotchas:    ([.cause] | map(select(. != ""))),
      notes:      ([.fix, .what_not] | map(select(. != ""))),
      feedback: []
    },
    pending: ([.precheck] | map(select(. != ""))),
    tags: (["atone", .max_sev, .slug, ("count:" + (.count | tostring))]
           + (if .cluster then ["cluster:" + .cluster] else [] end))
  }' > "$out" 2>/dev/null && emitted=$((emitted + 1))
done < "$AGG"

mv -f "$MARK.tmp" "$MARK"
echo "atone-to-dream: emitted=$emitted skipped(unchanged)=$skipped → $QUEUE"
