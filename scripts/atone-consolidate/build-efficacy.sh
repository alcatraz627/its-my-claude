#!/usr/bin/env bash
# build-efficacy.sh — sourced by atone-consolidate.sh (not executed directly).
# Relies on env vars + helpers from atone-common.sh and atone-consolidate/helpers.sh.
#
# ─── intervention-efficacy.json (atone T3.1) ──────────────────────────────────
#
# The falsifiability backbone. The atone system keeps shipping rules and hooks to
# stop recurring mistakes, but until now nothing measured whether any of them
# actually reduced the recurrence rate. This writes, per slug, the count of
# occurrences BEFORE vs AFTER its intervention shipped — split by stakes — so the
# user can see at a glance which interventions bent the curve and which didn't.
#
# The honest caveats, stated in the output so it can't be over-read:
#   - ship_date is INFERRED: the earliest git-add date of any rules/ or hooks/
#     file that references the slug by name. Slugs whose rule is named differently
#     (infra-before-grep -> grep-scope-before-claiming-absence.md) are matched by
#     the "Graduated from atone slug <slug>" reference the rule files carry.
#   - n per slug is small -> this is DIRECTIONAL, not significance-tested.
#   - the `stakes` field only exists on events written after F1 shipped; older
#     events bucket as "unknown" in the by-stakes splits.

build_efficacy() {
  local out="$DERIVED/intervention-efficacy.json"
  local gcc="$HOME/.claude"
  local view="${EVENTS_VIEW:-$EVENTS}"
  [ -f "$view" ] || { printf '{"slugs":[]}\n' > "$out"; _ok "wrote intervention-efficacy.json (no events)"; return 0; }

  # Precompute file -> earliest-add-date for every candidate intervention file,
  # ONCE, so the per-slug loop only does cheap lookups (bounds git calls to the
  # number of files, not the number of slugs).
  local datemap; datemap=$(mktemp "/tmp/atone-efficacy-dates-XXXXXX") || return 0
  (
    cd "$gcc" 2>/dev/null || exit 0
    for f in rules/*.md scripts/hooks/*.sh; do
      [ -f "$f" ] || continue
      local d
      d=$(git log --diff-filter=A --follow --format=%aI -- "$f" 2>/dev/null | tail -1)
      [ -n "$d" ] && printf '%s\t%s\n' "$f" "$d"
    done
  ) > "$datemap"

  # slug -> inferred ship_date, as a TSV we convert to a JSON map for one jq pass.
  local shiptsv; shiptsv=$(mktemp "/tmp/atone-efficacy-ship-XXXXXX") || { rm -f "$datemap"; return 0; }
  local slug files f d earliest
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    # Intervention files that reference this slug by name (rules + hooks).
    files=$(cd "$gcc" 2>/dev/null && rg -l --fixed-strings "$slug" rules/ scripts/hooks/ 2>/dev/null)
    [ -z "$files" ] && continue
    earliest=""
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      d=$(awk -F'\t' -v ff="$f" '$1==ff{print $2; exit}' "$datemap")
      [ -z "$d" ] && continue
      if [ -z "$earliest" ] || [[ "$d" < "$earliest" ]]; then earliest="$d"; fi
    done <<EOF
$files
EOF
    [ -n "$earliest" ] && printf '%s\t%s\n' "$slug" "$earliest"
  done < <(jq -r '.slug // empty' "$view" 2>/dev/null | sort -u) > "$shiptsv"

  local shipmap
  shipmap=$(jq -Rn '[inputs | split("\t") | {(.[0]): .[1]}] | add // {}' < "$shiptsv" 2>/dev/null)
  [ -z "$shipmap" ] && shipmap='{}'

  # One pass over the view: group by slug, compute before/after vs ship_date and
  # the by-stakes splits.
  jq -s --argjson ship "$shipmap" --arg ts "$NOW_UTC" '
    def bystakes: group_by(.stakes // "unknown") | map({(.[0].stakes // "unknown"): length}) | add;
    ( group_by(.slug)
      | map(
          (.[0].slug) as $s
          | ($ship[$s]) as $sd
          | {
              slug: $s,
              total: length,
              ship_date: ($sd // null),
              before: (if $sd then (map(select(.ts <  $sd)) | length) else null end),
              after:  (if $sd then (map(select(.ts >= $sd)) | length) else null end),
              after_by_stakes: (if $sd then (map(select(.ts >= $sd)) | bystakes) else null end),
              total_by_stakes: bystakes
            }
        )
      | sort_by(-.total)
    ) as $slugs
    | {
        generated_at: $ts,
        note: "Per-slug recurrence before vs after its intervention (rule/hook) shipped, split by stakes. DIRECTIONAL only: low n per slug; ship_date is inferred from the earliest git-add of any rules/ or scripts/hooks/ file that references the slug by name; a slug with ship_date=null has no matching intervention file. before/after compare event ts to ship_date.",
        stakes_caveat: "The stakes field exists only on events written after F1 shipped; older events bucket as \"unknown\" in the by-stakes splits.",
        ship_date_caveat: "git-add date floors at the gcc repo-init commit, so an intervention authored before the repo existed reads as shipping at init. Recent (post-init) interventions are dated accurately; treat pre-init ship_dates as \"at least this old\".",
        intervened: ($slugs | map(select(.ship_date != null)) | length),
        slugs: $slugs
      }' "$view" > "$out.tmp" 2>/dev/null && mv "$out.tmp" "$out"

  rm -f "$datemap" "$shiptsv" 2>/dev/null || true
  _ok "wrote intervention-efficacy.json ($(jq '.intervened' "$out" 2>/dev/null || echo 0) slugs with a shipped intervention)"
}
