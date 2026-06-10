#!/usr/bin/env bash
# atone-stop-gate.sh — the teeth behind an explicit /atone.
#
# A Stop hook that REFUSES turn-end (decision:block) when the user explicitly
# invoked /atone but no event was recorded — forcing the agent to actually log
# the mistake before it can stop. This is the enforcement the rest of the atone
# pipeline lacked: a user-typed /atone was advisory, and the existing Stop check
# lives inside the hook-orchestrator (run.sh:57 runs each task `>/dev/null 2>&1`),
# so any decision it emitted was thrown away. This hook is registered DIRECTLY in
# settings.json Stop precisely so its stdout reaches Claude Code.
#
# Two independent block conditions:
#   1. EXPLICIT /atone unaddressed — a .pending-atone marker with explicit:true
#      (armed by hinters/30-atone-nudge.sh Part 0) and NO event in events.jsonl
#      since the marker was armed.
#   2. Last `atone.sh add` FAILED — a .atone-add-failed marker (written by the
#      cmd_add EXIT trap in atone.sh) meaning the agent tried to record but the
#      write bounced (commonly: RCA missing YAML frontmatter). The mistake is
#      still unrecorded, so the agent must fix and retry.
#
# Bounded so it can NEVER trap the agent: each condition blocks at most
# ATONE_GATE_MAX_BLOCKS times (a per-marker counter that survives the forced
# continuations), then steps aside and clears the marker (logging a `missed`
# feedback). A freshness window drops stale markers so a cross-day/cross-session
# leftover can't block a fresh turn.
#
# Mute (session): touch ~/.claude/atone/.nudge-off  (shared with the nudge pipeline)
#
# Block contract (verified from review-gate-stop.sh on this machine):
#   print {"decision":"block","reason":"…"} to stdout, exit 0 → Stop is refused
#   and `reason` is fed back to the agent. Otherwise exit 0 silently.

set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || echo '{}')

# The gate has its OWN mute, separate from the heuristic-nudge mute (.nudge-off).
# Rationale: a user who silenced the noisy keyword nudges did not thereby ask to
# stop enforcing their own explicit /atone calls. Opt out of enforcement with:
#   touch ~/.claude/atone/.gate-off
[ -f "$HOME/.claude/atone/.gate-off" ] && exit 0

# Marker key derived IDENTICALLY to the writer (30-atone-nudge.sh) and the
# sibling check (atone-stop-check.sh) so all three agree on the path. NOTE:
# CLAUDE_SESSION_ID is typically unset (the live id is in CLAUDE_CODE_SESSION_ID),
# so this falls back to a date key — matching the existing convention. Upgrading
# the whole subsystem to session-keying is a separate change.
SESSION_KEY="${CLAUDE_SESSION_ID:-$(date +%Y-%m-%d)}"
STATE_DIR="$HOME/.claude/atone/.session-state"
PMARK="$STATE_DIR/$SESSION_KEY.pending-atone"
FMARK="$STATE_DIR/$SESSION_KEY.atone-add-failed"
EVENTS="$HOME/.claude/atone/events.jsonl"
MAX_BLOCKS="${ATONE_GATE_MAX_BLOCKS:-2}"
FRESH_SECONDS="${ATONE_GATE_FRESH_SECONDS:-3600}"   # ignore markers older than 1h

_now_epoch() { date -u '+%s'; }
_ts_epoch()  { date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" '+%s' 2>/dev/null \
                 || date -u -d "$1" '+%s' 2>/dev/null || echo 0; }

_block() {  # $1 = reason. Emit the decision and stop processing.
  jq -cn --arg r "$1" '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
}

_give_up() {  # $1 = marker path, $2 = slug, $3 = note. Clear + log missed.
  if [ "${ATONE_NO_FEEDBACK:-0}" != "1" ]; then
    ( bash "$HOME/.claude/scripts/atone.sh" feedback --kind missed \
        --slug "$2" --notes "$3" >/dev/null 2>&1 & ) &
  fi
  rm -f "$1" 2>/dev/null || true
}

# ── Condition 2 first: a bounced `atone.sh add` is the most concrete failure ──
if [ -f "$FMARK" ]; then
  FTS=$(jq -r '.ts // empty' "$FMARK" 2>/dev/null)
  FREASON=$(jq -r '.reason // "atone add failed"' "$FMARK" 2>/dev/null)
  if [ -n "$FTS" ] && [ "$(( $(_now_epoch) - $(_ts_epoch "$FTS") ))" -lt "$FRESH_SECONDS" ]; then
    FB=$(jq -r '.blocks // 0' "$FMARK" 2>/dev/null)
    if [ "$FB" -lt "$MAX_BLOCKS" ]; then
      jq -c --argjson n "$((FB+1))" '.blocks=$n' "$FMARK" > "$FMARK.tmp" 2>/dev/null \
        && mv "$FMARK.tmp" "$FMARK"
      _block "⚠ atone gate — your last \`atone.sh add\` did NOT record an event: ${FREASON}. The mistake is still UNRECORDED. Fix the cause (most often: the RCA must start with '---' YAML frontmatter on line 1) and re-run the add; or bypass the RCA lint for one event with ATONE_NO_RCA_LINT=1. Mute the gate for this session: touch ~/.claude/atone/.nudge-off"
    else
      _give_up "$FMARK" "unaddressed-failed-atone-add" \
        "atone-stop-gate: atone add stayed failed after ${MAX_BLOCKS} blocks. reason=${FREASON}"
    fi
  else
    rm -f "$FMARK" 2>/dev/null || true   # stale or malformed → drop
  fi
fi

# ── Condition 1: explicit /atone marker still unaddressed ─────────────────────
[ -f "$PMARK" ] || exit 0
[ "$(jq -r '.explicit // false' "$PMARK" 2>/dev/null)" = "true" ] || exit 0  # implicit → not ours

MTS=$(jq -r '.ts // empty' "$PMARK" 2>/dev/null)
[ -n "$MTS" ] || exit 0
if [ "$(( $(_now_epoch) - $(_ts_epoch "$MTS") ))" -ge "$FRESH_SECONDS" ]; then
  rm -f "$PMARK" 2>/dev/null || true   # stale → drop, don't block a fresh turn
  exit 0
fi

# Did an event land at/after the marker ts? (>= because both floor to seconds:
# the marker is written at UserPromptSubmit, the event necessarily later.)
RECENT=$(jq -r --arg ts "$MTS" 'select(.ts >= $ts) | .id' "$EVENTS" 2>/dev/null | head -1)
if [ -n "$RECENT" ]; then
  rm -f "$PMARK" 2>/dev/null || true   # recorded — clean close
  exit 0
fi

# No event yet → block, bounded by MAX_BLOCKS.
BLK=$(jq -r '.turns_unaddressed // 0' "$PMARK" 2>/dev/null)
if [ "$BLK" -lt "$MAX_BLOCKS" ]; then
  jq -c --argjson n "$((BLK+1))" '.turns_unaddressed=$n' "$PMARK" > "$PMARK.tmp" 2>/dev/null \
    && mv "$PMARK.tmp" "$PMARK"
  _block "⚠ atone gate — you invoked /atone but NO event was recorded this turn. Do not stop yet: run the /atone flow now (gather context → reuse-or-pick a slug → write the event with ~/.claude/scripts/atone.sh add). If the juror would genuinely clear you, run the add anyway — its exit-5 path resolves this without recording. If it was not a real correction, ask the user to say 'never mind', or mute: touch ~/.claude/atone/.nudge-off"
else
  _give_up "$PMARK" "unaddressed-explicit-atone" \
    "atone-stop-gate: explicit /atone left unrecorded after ${MAX_BLOCKS} blocks. snippet=$(jq -r '.correction_snippet // ""' "$PMARK" 2>/dev/null | head -c 200)"
fi
exit 0
