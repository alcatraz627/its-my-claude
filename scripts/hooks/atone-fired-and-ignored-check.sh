#!/usr/bin/env bash
# atone-fired-and-ignored-check.sh — Stop hook (side-effect only, via the
# hook-orchestrator's Stop.tasks; its stdout is discarded, which is fine — this
# writes a file and decides nothing).
#
# Turns the atone loop's central blind spot into an OBJECTIVE counted signal.
# feedback.jsonl's `fired-and-ignored` was a structural under-count: recording one
# required the agent to run the full feedback step — the very diligence whose
# absence IS the failure being measured. So the log showed 1 fired-and-ignored
# against 100+ fired-and-useful, which tells us nothing. This derives the signal
# mechanically instead, trusting no agent diligence.
#
# Objective rule: a slug recorded >=2x in ONE session (the F1 per-session counter
# at ~/.claude/.session-atone-slugs/<session>.json). The first atone proves the
# agent already had the pattern in hand this session; a second same-session
# occurrence is the trigger having fired and the mistake landing anyway — exactly
# fired-and-ignored. Emits one feedback line per (session, slug) the first time it
# crosses 2, deduped so it isn't re-counted every turn.
#
# Honest under-count (documented, not a bug): only catches recurrences that
# produced a SECOND atone. A recurrence the agent never atoned for leaves no
# record and is invisible here — there is no signal for it to read.
#
# Side-effect only: writes via `atone.sh feedback`, prints nothing, always exit 0.
# Mute: touch ~/.claude/atone/.no-fired-ignored-check

set -uo pipefail
[ -f "$HOME/.claude/atone/.no-fired-ignored-check" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
sid=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
# Same key derivation as atone.sh add uses when writing the counter.
SESSION_KEY="${sid:-${CLAUDE_SESSION_ID:-$(date +%Y-%m-%d)}}"

SDIR="$HOME/.claude/.session-atone-slugs"
COUNTER="$SDIR/${SESSION_KEY}.json"
EMITTED="$SDIR/${SESSION_KEY}.fi-emitted"
ATONE="$HOME/.claude/scripts/atone.sh"
[ -s "$COUNTER" ] || exit 0

# Slugs recorded >=2x this session: slug<TAB>count<TAB>latest-event-id.
REPEATS=$(jq -rs '
  group_by(.slug)
  | map(select(length >= 2))
  | .[] | [.[0].slug, (length|tostring), (.[-1].event_id // "")] | @tsv
' "$COUNTER" 2>/dev/null)
[ -z "$REPEATS" ] && exit 0

while IFS=$'\t' read -r slug count eid; do
  [ -z "$slug" ] && continue
  # Emit once per slug per session.
  if [ -f "$EMITTED" ] && grep -qxF "$slug" "$EMITTED" 2>/dev/null; then
    continue
  fi
  notes="objective: slug recorded ${count}x in session ${SESSION_KEY} — same-session recurrence after the first atone (fired-and-ignored detector)"
  args=(feedback --kind fired-and-ignored --slug "$slug" --notes "$notes")
  [ -n "$eid" ] && args+=(--event-id "$eid")
  ( bash "$ATONE" "${args[@]}" >/dev/null 2>&1 & ) &
  printf '%s\n' "$slug" >> "$EMITTED" 2>/dev/null || true
done <<EOF
$REPEATS
EOF

exit 0
