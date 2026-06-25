#!/usr/bin/env bash
# 10-atone-circuit-breaker.sh — UserPromptSubmit hinter (atone T2.1).
#
# The momentum circuit breaker. When the SAME atone slug is recorded twice in one
# session, that second occurrence is the documented repeat signature: the agent
# knew the rule, atoned for breaking it, and broke it again within the hour. The
# data shows awareness is already saturated — adding more reminders scores ~0 on
# behaviour change. What's missing is a hard stop at the proven failure point.
# This injects one, exactly once per repeated slug.
#
# It arms only when the repeat actually matters:
#   - the work is high-stakes (code that ships, or gcc itself), OR
#   - the slug belongs to a cluster the user weights heavily —
#       A (ungrounded assertion), C (literal-list-as-action), E (convention-blind).
# A low-stakes throwaway repeat does not arm it. By construction this fires on
# under 2% of sessions, which is why it can live as a hinter rather than a block.
#
# Data sources, all read-only, none kernel-locked:
#   counter   ~/.claude/.session-atone-slugs/<session>.json   per-atone, this session
#             (one JSON object per line: {slug, ts, severity, stakes, event_id})
#   clusters  ~/.claude/atone/derived/triggers.json           slug -> cluster + instruction
#   precheck  ~/.claude/atone/events.jsonl                    most-recent precheck text
# The per-event `cluster` field is read from triggers.json, NOT the counter: the
# counter omits it and the raw event often has it null at write time (the cron
# assigns clusters later). `stakes` is read from the counter, where it is stamped
# reliably at write time. Each field is read from where it is actually populated.
#
# Dedup: ~/.claude/.session-atone-slugs/<session>.breaker-fired (one slug per line).
# Mute (rare — this is the load-bearing signal, not keyword noise, so it does NOT
# honour the general .nudge-off): touch ~/.claude/atone/.breaker-off
#
# Latency budget: <100ms (a couple of small jq passes; the events.jsonl scan only
# runs on the rare turn a slug has actually armed).

set -uo pipefail

PROMPT=$(cat)
[ -z "$PROMPT" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0
[ -f "$HOME/.claude/atone/.breaker-off" ] && exit 0

SESSION_KEY="${CLAUDE_SESSION_ID:-$(date +%Y-%m-%d)}"
SDIR="$HOME/.claude/.session-atone-slugs"
COUNTER="$SDIR/${SESSION_KEY}.json"
FIRED="$SDIR/${SESSION_KEY}.breaker-fired"
TRIGGERS="$HOME/.claude/atone/derived/triggers.json"
EVENTS="$HOME/.claude/atone/events.jsonl"

# Nothing recorded this session → nothing can have repeated.
[ -s "$COUNTER" ] || exit 0

# Slugs recorded >=2 times this session, with whether any of those records was
# high-stakes. JSONL → slurp into an array, group by slug.
REPEATS=$(jq -rs '
  group_by(.slug)
  | map(select(length >= 2))
  | map({slug: .[0].slug,
         count: length,
         high: (any(.[]; .stakes == "high"))})
  | .[] | [.slug, (.count|tostring), (if .high then "high" else "low" end)] | @tsv
' "$COUNTER" 2>/dev/null)

[ -z "$REPEATS" ] && exit 0

OUT=""
NEWLY_FIRED=""
while IFS=$'\t' read -r slug count stakes; do
  [ -z "$slug" ] && continue

  # Fire once per slug per session.
  if [ -f "$FIRED" ] && grep -qxF "$slug" "$FIRED" 2>/dev/null; then
    continue
  fi

  # cluster + instruction from the derived trigger map (best-effort: a brand-new
  # slug the cron has not clustered yet shows "-", which simply won't arm via the
  # cluster branch — the stakes branch still can).
  cluster=$(jq -r --arg s "$slug" \
    'map(select(.from_slug == $s)) | (.[0].cluster // "-")' "$TRIGGERS" 2>/dev/null)
  [ -z "$cluster" ] && cluster="-"

  # Arm: high-stakes OR a heavily-weighted cluster.
  armed=0
  [ "$stakes" = "high" ] && armed=1
  case "$cluster" in A|C|E) armed=1 ;; esac
  [ "$armed" = "1" ] || continue

  # Richest precheck = the most-recent non-empty precheck recorded for this slug.
  # Fall back to the trigger instruction, then to a generic line.
  precheck=$(jq -rs --arg s "$slug" '
    map(select(.slug == $s and .precheck != null and .precheck != ""))
    | if length > 0 then .[-1].precheck else "" end' "$EVENTS" 2>/dev/null)
  if [ -z "$precheck" ]; then
    precheck=$(jq -r --arg s "$slug" \
      'map(select(.from_slug == $s)) | (.[0].instruction // "")' "$TRIGGERS" 2>/dev/null)
  fi
  [ -z "$precheck" ] && precheck="re-read the rule for this slug before proceeding"

  # Qualifier: what made it arm.
  qual=""
  [ "$stakes" = "high" ] && qual="high-stakes"
  case "$cluster" in A|C|E)
    if [ -n "$qual" ]; then qual="$qual, cluster $cluster"; else qual="cluster $cluster"; fi ;;
  esac

  OUT="${OUT}⛔ [atone-circuit-breaker] MOMENTUM STOP — \`${slug}\` recorded ${count}× this session (${qual}).
   The second same-session occurrence is the documented repeat signature: you atoned for this and slipped again. Awareness is saturated; the missing piece is a hard stop, so here is one.
   Before your next edit, claim, or tool action:
     1. STOP and surface a one-line plan for the current step. State how it differs from the prior slip.
     2. Run the precheck for this slug:
        → ${precheck}
     3. Proceed only after both.
"
  if [ -n "$NEWLY_FIRED" ]; then NEWLY_FIRED="${NEWLY_FIRED}"$'\n'"${slug}"; else NEWLY_FIRED="${slug}"; fi
done <<EOF
$REPEATS
EOF

[ -z "$OUT" ] && exit 0

# Record what fired so it stays a once-per-slug signal, not a per-turn nag.
printf '%s\n' "$NEWLY_FIRED" >> "$FIRED" 2>/dev/null || true

printf '%s   (Fires once per repeated slug. Rare by design. Mute: touch ~/.claude/atone/.breaker-off)\n' "$OUT"
