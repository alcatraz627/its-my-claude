#!/usr/bin/env bash
# 30-atone-nudge.sh — UserPromptSubmit hinter.
#
# TWO-PART LOGIC:
#
#  1. Stale-marker escalation (runs FIRST). If a prior turn flagged a correction
#     and no /atone happened, the marker at .session-state/<id>.pending-atone
#     persists. This block reads it and emits progressively stronger nudges:
#        turns_unaddressed = 0 → standard nudge (handled by part 2 below)
#        turns_unaddressed = 1 → reminder
#        turns_unaddressed = 2 → strong reminder
#        turns_unaddressed ≥ 3 → atone-stop-check.sh auto-clears + logs missed
#
#     Also clears the marker on "never mind" / "ignore that" / "actually fine"
#     phrasings, so false-positives don't compound.
#
#  2. Standard nudge (the original behavior). Fires on you/your+correction-keyword
#     with 3rd-person filter. Also writes a fresh marker for the Stop hook to track.
#
# Skip conditions:
#   - ~/.claude/atone/.nudge-off exists (mute everything)
#
# Latency budget: <100ms.

set -uo pipefail

PROMPT=$(cat)
[ -z "$PROMPT" ] && exit 0

SESSION_KEY="${CLAUDE_SESSION_ID:-$(date +%Y-%m-%d)}"
STATE_DIR="$HOME/.claude/atone/.session-state"
MARKER="$STATE_DIR/$SESSION_KEY.pending-atone"
mkdir -p "$STATE_DIR" 2>/dev/null || true

# ─── Part 0: explicit /atone invocation → always arm the gate ──────
# When the user literally types /atone, an event MUST be recorded this turn —
# this is the deterministic case, not a heuristic guess. Arm an explicit marker
# that the blocking Stop gate (atone-stop-gate.sh) enforces.
#
# This runs ABOVE the .nudge-off mute on purpose: muting the noisy keyword
# nudges (what .nudge-off does) must NOT also disable enforcement of an explicit
# request to record. The explicit gate has its OWN opt-out, .gate-off, default
# off. The /atone may not be at offset 0 (e.g. a second line after "Did you just
# skip the atone call?"), so match any line that *starts* with /atone — grep is
# line-oriented, so this scans every line of the prompt.
if [ ! -f "$HOME/.claude/atone/.gate-off" ] \
   && printf '%s' "$PROMPT" | grep -Eq '^[[:space:]]*/atone([[:space:]]|$)'; then
  if command -v jq >/dev/null 2>&1; then
    TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    SNIPPET=$(printf '%s' "$PROMPT" | head -c 200 | tr '\n' ' ')
    jq -cn --arg ts "$TS" --arg snip "$SNIPPET" \
      '{ts: $ts, turns_unaddressed: 0, correction_snippet: $snip, explicit: true}' \
      > "$MARKER" 2>/dev/null || true
  fi
  # No nudge text — the user already invoked /atone. Just arm the gate and
  # stay out of the way (the skill's own instructions drive the recording).
  exit 0
fi

# Heuristic nudges below are muted by .nudge-off. The explicit /atone gate above
# is deliberately NOT muted by it (it has its own .gate-off switch).
[ -f "$HOME/.claude/atone/.nudge-off" ] && exit 0

# ─── Part 1a: clear marker on "never mind" / "ignore that" ─────────
if [ -f "$MARKER" ]; then
  CLEAR_KEYWORD=$(echo "$PROMPT" | python3 -c '
import sys, re
text = sys.stdin.read().lower()
patterns = [
  r"\bnever mind\b", r"\bignore (that|it)\b", r"\bactually (that|it) (was|is) fine\b",
  r"\bdisregard (that|it)\b", r"\bthat (was|is) (fine|right|correct)\b",
  r"\bmy (bad|mistake|fault)\b", r"\bi (was|got) wrong\b",
]
for p in patterns:
  if re.search(p, text):
    print("clear"); break
' 2>/dev/null)
  if [ "$CLEAR_KEYWORD" = "clear" ]; then
    rm -f "$MARKER" 2>/dev/null || true
    cat <<'EOF'
[atone-nudge] Marker cleared — user signaled this wasn't a correction.
EOF
    # Don't fall through to standard nudge — the user is explicitly disclaiming.
    exit 0
  fi
fi

# ─── Part 1b: stale-marker escalation ──────────────────────────────
if [ -f "$MARKER" ] && command -v jq >/dev/null 2>&1; then
  TURNS_UNADDRESSED=$(jq -r '.turns_unaddressed // 0' "$MARKER" 2>/dev/null)
  SNIPPET=$(jq -r '.correction_snippet // ""' "$MARKER" 2>/dev/null | head -c 120)
  case "$TURNS_UNADDRESSED" in
    0) ;;  # fresh marker — no escalation yet; standard nudge will re-emit below
    1)
      cat <<EOF
[atone-nudge:reminder] You mentioned a correction last turn and didn't /atone.
  prior: "$SNIPPET"
  do:    invoke /atone now, OR signal "never mind" if it wasn't a correction
  mute:  touch ~/.claude/atone/.nudge-off
EOF
      exit 0
      ;;
    2)
      cat <<EOF
[atone-nudge:escalation-2] Two turns without /atone — this is the §1.5 hole.
  prior: "$SNIPPET"
  either invoke /atone NOW, or:
    - "never mind" to clear (false-positive)
    - touch ~/.claude/atone/.nudge-off (mute the whole pipeline)
  one more turn without action → marker auto-clears + logs a 'missed' event
EOF
      exit 0
      ;;
  esac
fi

# ─── Part 2: standard nudge — same logic as before ─────────────────
HIT=$(ATONE_PROMPT="$PROMPT" python3 - <<'PY' 2>/dev/null
import os, re
text = os.environ.get("ATONE_PROMPT", "").lower()

if re.search(r'\b(is it (bad|wrong)|would (it )?be (bad|wrong)|might be (bad|wrong))\b', text):
    raise SystemExit(0)
if re.search(r'\b(wrong|bad|mistake)-\w+', text) or re.search(r'\b\w+-(wrong|bad|mistake)\b', text):
    raise SystemExit(0)
if re.search(r'\b(test|spec|fixture)\s+(case|fixture|for|that|describing)\b', text) and \
   not re.search(r'\byour test\b', text):
    raise SystemExit(0)

kw_re = re.compile(
    r'\b(mistake|sloppy|lazy|wrong|messed up|fucked up|that.?s not|that.?s the|you broke|'
    r'why did you|stop doing|undo (that|it)|revert (that|it)|bad call|missed the point)\b',
    re.I,
)
neg_subj_re = re.compile(
    r'\b(the user|users?\b|customer|client|visitor|the (data|csv|file|entry|row|column|input|json)|'
    r'they|he|she|their|his|her)\s+(\w+\s+){0,4}$',
    re.I,
)

for m in kw_re.finditer(text):
    pre = text[max(0, m.start()-60):m.start()]
    if neg_subj_re.search(pre):
        continue
    print("hit"); break
PY
)

[ "$HIT" = "hit" ] || exit 0

# Write a fresh marker so the Stop hook can track whether /atone happens.
if command -v jq >/dev/null 2>&1; then
  TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  # First 200 chars of prompt as the snippet
  SNIPPET=$(printf '%s' "$PROMPT" | head -c 200 | tr '\n' ' ')
  jq -cn --arg ts "$TS" --arg snip "$SNIPPET" \
    '{ts: $ts, turns_unaddressed: 0, correction_snippet: $snip, explicit: false}' \
    > "$MARKER" 2>/dev/null || true
fi

cat <<'NUDGE'
[atone-nudge] User language suggests a correction. Before proceeding:
  1. Identify the specific mistake (one sentence).
  2. Invoke /atone — gathers context, classifies severity, writes structured entry.
  3. Then apply the fix.
If this isn't a correction, say "never mind" or "that was fine" to clear the marker.
Mute the pipeline entirely: touch ~/.claude/atone/.nudge-off
NUDGE
