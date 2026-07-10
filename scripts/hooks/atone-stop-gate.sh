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
# Mute (session): touch ~/.claude/atone/.gate-off  (the gate's OWN mute — distinct
#   from the heuristic-nudge mute .nudge-off, which does NOT silence this gate).
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

# ── Scope guard: only the top-level interactive session can RECEIVE a user-typed
# /atone, so only it should ever be gated. A child/sub-agent session (Task/Agent
# sidechain → CLAUDE_CODE_CHILD_SESSION=1) or the atone juror's own headless
# `claude -p` (ATONE_JUROR_SESSION=1, exported by atone-juror-dispatch.sh) reads
# the SAME date-keyed marker (SESSION_KEY falls back to a date, below) yet cannot
# run `atone.sh add` — so a block there is always a false positive, and it loops
# (identical block re-fires every forced continuation). Suppress outright.
# ATONE_JUROR_SESSION is the guaranteed-correct signal (set only for the juror);
# CHILD_SESSION is the broader catch for Agent-tool juror sub-agents. The .gate-off
# mute remains the universal escape if a future runtime ever sets CHILD_SESSION in
# the top session.
[ "${ATONE_JUROR_SESSION:-}" = "1" ] && exit 0
[ "${CLAUDE_CODE_CHILD_SESSION:-}" = "1" ] && exit 0

# Marker key: stdin session_id first (the authoritative per-session identity a
# hook receives), then the env ids, then the legacy UTC-date key. Sanitized to a
# filename-safe token and capped — a polluted env var once produced a marker
# literally named after an error message. Derivation is MIRRORED in
# atone-stop-check.sh and atone.sh:_add_exit_trap; all writers/readers must
# agree. Session-keying fixes the cross-session collision (two same-day sessions
# sharing one marker; observed cross-fire 2026-06-25, prop-20260625-172436-8b).
_sid=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$_sid" ] || _sid="${CLAUDE_CODE_SESSION_ID:-${CLAUDE_SESSION_ID:-}}"
[ -n "$_sid" ] || _sid="$(date +%Y-%m-%d)"
SESSION_KEY=$(printf '%s' "$_sid" | tr -c 'A-Za-z0-9._-' '-' | cut -c1-64)
STATE_DIR="$HOME/.claude/atone/.session-state"
PMARK="$STATE_DIR/$SESSION_KEY.pending-atone"
FMARK="$STATE_DIR/$SESSION_KEY.atone-add-failed"
# Transition fallback: a marker armed under the legacy date key (by an older
# writer, or a session where no id was derivable) is still honored. The 1h
# freshness window retires stragglers naturally.
_legacy_key="$(date +%Y-%m-%d)"
[ -f "$PMARK" ] || { [ -f "$STATE_DIR/$_legacy_key.pending-atone" ] && PMARK="$STATE_DIR/$_legacy_key.pending-atone"; }
[ -f "$FMARK" ] || { [ -f "$STATE_DIR/$_legacy_key.atone-add-failed" ] && FMARK="$STATE_DIR/$_legacy_key.atone-add-failed"; }
EVENTS="$HOME/.claude/atone/events.jsonl"
MAX_BLOCKS="${ATONE_GATE_MAX_BLOCKS:-2}"
FRESH_SECONDS="${ATONE_GATE_FRESH_SECONDS:-3600}"   # ignore markers older than 1h

_now_epoch() { date -u '+%s'; }
_ts_epoch()  { date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" '+%s' 2>/dev/null \
                 || date -u -d "$1" '+%s' 2>/dev/null || echo 0; }

# A short "if you can't reach ~/.claude, hand it to the user" line appended to
# every block. A directory-scoped session (shell perms confined to a subdir) may
# be unable to run atone.sh at all; this gives it a comply path other than the
# block re-firing until MAX_BLOCKS. The gate cannot detect that scoping from a
# Stop hook, so it offers the escape unconditionally rather than trap the turn.
# The mute-file pointer lives ONCE at each block's tail — a scoped-out session
# cannot touch ~/.claude itself, so here we ask the USER to run (or mute) instead.
HANDOFF="If you cannot run atone.sh here (shell scoped to a subdir / no access to ~/.claude), tell the user and ask them to run the add — or to mute the gate — for you; do not just re-stop."

_block() {  # $1 = reason. Emit the decision and stop processing.
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook atone-stop-gate --action block --heeded unknown >/dev/null 2>&1 || true
  jq -cn --arg r "$1" '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
}

_give_up() {  # $1 = marker path, $2 = slug, $3 = note. Clear + log missed.
  # Gave up after MAX_BLOCKS with no event recorded → the blocks were not heeded.
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook atone-stop-gate --heed-of "atone-stop-gate:$SESSION_KEY" --heeded false >/dev/null 2>&1 || true
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
    # A failed re-run of an add whose slug is ALREADY on record is a FALSE alarm,
    # not an unrecorded mistake: a duplicate / near-duplicate rejection, or a
    # same-session-repeat bump that exits nonzero AFTER the original event
    # committed, still fires the EXIT trap and arms this marker. If an event with
    # this slug landed within the freshness window, the obligation is satisfied —
    # drop the marker instead of forcing a fix for an add that already succeeded.
    # (Degrades safely: a marker with no .slug — e.g. a genuine first-attempt RCA
    # lint failure, which never reached a slug-bearing write — still blocks below.)
    FSLUG=$(jq -r '.slug // empty' "$FMARK" 2>/dev/null)
    if [ -n "$FSLUG" ]; then
      FCUT=$(( $(_now_epoch) - FRESH_SECONDS ))
      FREC=$(jq -r --arg s "$FSLUG" 'select(.slug == $s) | .ts' "$EVENTS" 2>/dev/null | tail -1)
      if [ -n "$FREC" ] && [ "$(_ts_epoch "$FREC")" -ge "$FCUT" ]; then
        bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook atone-stop-gate --heed-of "atone-stop-gate:$SESSION_KEY" --heeded true >/dev/null 2>&1 || true
        rm -f "$FMARK" 2>/dev/null || true   # slug already recorded → not a real failure
      fi
    fi
  else
    rm -f "$FMARK" 2>/dev/null || true   # stale or malformed → drop
  fi
  # Re-test: the slug cross-check or the freshness check above may have cleared it.
  if [ -f "$FMARK" ]; then
    FB=$(jq -r '.blocks // 0' "$FMARK" 2>/dev/null)
    if [ "$FB" -lt "$MAX_BLOCKS" ]; then
      jq -c --argjson n "$((FB+1))" '.blocks=$n' "$FMARK" > "$FMARK.tmp" 2>/dev/null \
        && mv "$FMARK.tmp" "$FMARK"
      _block "⚠ atone gate — your last \`atone.sh add\` did NOT record an event: ${FREASON}. The mistake is still UNRECORDED. Fix the cause (most often: the RCA must start with '---' YAML frontmatter on line 1) and re-run the add; or bypass the RCA lint for one event with ATONE_NO_RCA_LINT=1. ${HANDOFF} Mute the gate for this session: touch ~/.claude/atone/.gate-off"
    else
      _give_up "$FMARK" "unaddressed-failed-atone-add" \
        "atone-stop-gate: atone add stayed failed after ${MAX_BLOCKS} blocks. reason=${FREASON}"
    fi
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
  # Event landed at/after the /atone marker → the explicit /atone was addressed.
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook atone-stop-gate --heed-of "atone-stop-gate:$SESSION_KEY" --heeded true >/dev/null 2>&1 || true
  rm -f "$PMARK" 2>/dev/null || true   # recorded — clean close
  exit 0
fi

# No event yet → block, bounded by MAX_BLOCKS.
BLK=$(jq -r '.turns_unaddressed // 0' "$PMARK" 2>/dev/null)
if [ "$BLK" -lt "$MAX_BLOCKS" ]; then
  jq -c --argjson n "$((BLK+1))" '.turns_unaddressed=$n' "$PMARK" > "$PMARK.tmp" 2>/dev/null \
    && mv "$PMARK.tmp" "$PMARK"
  _block "⚠ atone gate — you invoked /atone but NO event was recorded this turn. Do not stop yet: run the /atone flow now (gather context → reuse-or-pick a slug → write the event with ~/.claude/scripts/atone.sh add). If the juror would genuinely clear you, run the add anyway — its exit-5 path resolves this without recording. If it was not a real correction, ask the user to say 'never mind'. ${HANDOFF} Or mute the gate: touch ~/.claude/atone/.gate-off"
else
  _give_up "$PMARK" "unaddressed-explicit-atone" \
    "atone-stop-gate: explicit /atone left unrecorded after ${MAX_BLOCKS} blocks. snippet=$(jq -r '.correction_snippet // ""' "$PMARK" 2>/dev/null | head -c 200)"
fi
exit 0
