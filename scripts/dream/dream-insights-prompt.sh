#!/usr/bin/env bash
# dream-insights-prompt.sh — the first-prompt query lane for dream insights
# (i-dream docs/25 item 15 tail).
#
# SessionStart ranks dream lessons by cwd alone — the prompt doesn't exist yet.
# This UserPromptSubmit hook closes that gap ONCE per session: the first
# substantive prompt re-ranks the derived patterns view with the prompt's own
# words as query terms, and injects only the ranked-lessons section — and only
# when the re-ranked set actually differs from what SessionStart delivered
# (the ranking engine dedupes by ids and stays silent otherwise).
#
# Gates, in order: mute file · dream half enabled (.inject-on / INJECT_DREAM=1)
# · once-per-session marker · substantive prompt (≥3 content words — a terse
# "yes" does NOT consume the session's one shot). The marker is consumed on
# EVALUATION, not emission: a dedupe-to-silence result still counts as the
# session's shot, because later prompts were deliberately scoped out.
#
# Registered SYNCHRONOUS in settings.json UserPromptSubmit — async hook output
# is side-effect-only and never reaches the session (hook-output contracts).
# Output: {"hookSpecificOutput":{hookEventName, additionalContext}} or nothing.
# Always exits 0 — a UPS hook must never block the prompt.
# Mute: touch ~/.claude/.no-dream-prompt-lane

set -uo pipefail
# A sync UPS hook must be silent on stderr in every failure mode — leaked
# "Permission denied" noise reaches the harness (gate finding 6).
exec 2>/dev/null
[ -f "$HOME/.claude/.no-dream-prompt-lane" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

SUBCON="$HOME/.claude/subconscious/dreams"
if [ ! -f "$SUBCON/.inject-on" ] && [ "${INJECT_DREAM:-}" != "1" ]; then
  exit 0
fi

INPUT=$(cat 2>/dev/null || echo '{}')
PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
HOOK_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")
[ -n "$SID" ] || exit 0
# The sid becomes a filename — refuse anything with path structure. Today
# session_id is harness-controlled; this guards the day that stops being true
# (gate finding 2: "../../evil" was a zero-byte write primitive).
case "$SID" in */*|*..*) exit 0 ;; esac

MARKER_DIR="${TMPDIR:-/tmp}/dream-prompt-lane"
MARKER="$MARKER_DIR/$SID"
[ -f "$MARKER" ] && exit 0

# Substantive prompt = at least 3 words longer than 2 chars, each carrying at
# least one letter (a numbers-only prompt has no keyword-overlap value and
# must not spend the marker — gate finding 5). Terse continuations same.
WORDS=$(printf '%s' "$PROMPT" | tr -c '[:alnum:]' ' ' | tr -s ' ' '\n' | awk 'length>2 && /[[:alpha:]]/' | head -50 | wc -l | tr -d ' ')
[ "$WORDS" -ge 3 ] 2>/dev/null || exit 0

# Cap the query surface — a pasted wall of text ranks fine on its head. (A
# byte cap can tear a multibyte char; the engine normalizes on read.)
QUERY=$(printf '%.600s' "$PROMPT")

# Atomic once-per-session gate: exactly one concurrent invocation wins the
# noclobber create (gate finding 3, TOCTOU). Fail-CLOSED: an unwritable
# marker dir silences the lane for the session rather than letting it fire
# on every prompt — same posture as the mute file.
mkdir -p "$MARKER_DIR" || exit 0
( set -o noclobber; : > "$MARKER" ) || exit 0

# The engine lives next to this wrapper — resolve it from the script's own
# location, not $HOME (same split-resolution class as the item-12 blocker:
# a HOME override or HOME-less environment must not dangle the engine path).
ENGINE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dream-insights.sh"
OUT=$(INJECT_PART=ranked INJECT_QUERY="$QUERY" INJECT_CWD="$HOOK_CWD" INJECT_SID="$SID" \
      bash "$ENGINE" 2>/dev/null || true)
[ -n "$OUT" ] || exit 0
CTX=$(printf '%s' "$OUT" | jq -r '.additionalContext // ""' 2>/dev/null)
[ -n "$CTX" ] || exit 0
jq -cn --arg ctx "$CTX" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
exit 0
