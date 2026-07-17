#!/usr/bin/env bash
# atone-session-key.test.sh — the atone fleet keys its state on the SESSION, not the day.
#
# What this protects, in human terms: every part of the atone system keeps a little
# state per session — "a correction is pending", "this slug already fired". If two
# sessions running on the same day share one state file, one session's business
# leaks into another's. That is not hypothetical: on 2026-05-24 an escalation
# quoted a memory-consolidation fragment from an unrelated session back at an agent
# as though it were its own prior turn, and demanded it atone for it
# (fb-20260524-025127-7810-5c3707b2).
#
# The mechanism was a variable name. CLAUDE_SESSION_ID is never set by the harness
# — the real one is CLAUDE_CODE_SESSION_ID — so `${CLAUDE_SESSION_ID:-$(date ...)}`
# always silently landed on the date. atone.sh, atone-stop-check.sh and
# atone-stop-gate.sh were corrected; the two hinters and this check were missed and
# kept writing/reading date-keyed state for weeks.
#
# Every assertion here is one the bug actually broke. Run it after touching any
# session-key derivation in the atone fleet:
#
#   bash ~/.claude/scripts/hooks/atone-session-key.test.sh

set -uo pipefail

GCC="${GCC_ROOT:-$HOME/.claude}"
NUDGE="$GCC/hinters/30-atone-nudge.sh"
BREAKER="$GCC/hinters/10-atone-circuit-breaker.sh"

PASS=0
FAIL=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }

SID="deadbeef-1111-2222-3333-444455556666"
TODAY="$(date +%Y-%m-%d)"

# Run a hinter against a throwaway HOME so a test never touches real atone state.
# Hinters are fed the prompt on stdin (not the hook JSON), which is exactly why
# they must read the session id from the environment.
run_nudge() {
  local prompt="$1" sid="$2" tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/.claude/atone"
  printf '%s' "$prompt" | env HOME="$tmp" CLAUDE_CODE_SESSION_ID="$sid" \
    CLAUDE_SESSION_ID= bash "$NUDGE" >/dev/null 2>&1
  printf '%s' "$tmp"
}

echo "== nudge marker is keyed by session, not by date =="
T=$(run_nudge "you did this wrong, revert that" "$SID")
SD="$T/.claude/atone/.session-state"
if [ -f "$SD/$SID.pending-atone" ]; then
  ok "marker written as <session-id>.pending-atone"
else
  bad "no session-keyed marker (found: $(ls "$SD" 2>/dev/null | tr '\n' ' '))"
fi
if [ -f "$SD/$TODAY.pending-atone" ]; then
  bad "date-keyed marker still written ($TODAY) — cross-session collision is live"
else
  ok "no date-keyed marker written"
fi
rm -rf "$T"

echo
echo "== two sessions on the same day do not share a marker =="
A=$(run_nudge "you broke the build, undo that" "aaaa1111-0000-0000-0000-000000000000")
B=$(run_nudge "why did you do that, revert it" "bbbb2222-0000-0000-0000-000000000000")
NA=$(ls "$A/.claude/atone/.session-state" 2>/dev/null | head -1)
NB=$(ls "$B/.claude/atone/.session-state" 2>/dev/null | head -1)
if [ -n "$NA" ] && [ -n "$NB" ] && [ "$NA" != "$NB" ]; then
  ok "distinct markers ($NA vs $NB)"
else
  bad "sessions collided on one marker ($NA vs $NB)"
fi
rm -rf "$A" "$B"

echo
echo "== the stored snippet is this session's own prompt =="
# The escalation quotes this text back at the agent. A foreign snippet here is the
# exact shape of the 2026-05-24 false positive.
T=$(run_nudge "you made a mistake here" "$SID")
SNIP=$(jq -r '.correction_snippet // ""' "$T/.claude/atone/.session-state/$SID.pending-atone" 2>/dev/null)
if [ "$SNIP" = "you made a mistake here" ]; then
  ok "correction_snippet is this session's prompt"
else
  bad "unexpected snippet: '$SNIP'"
fi
rm -rf "$T"

echo
echo "== circuit breaker reads the key atone.sh writes =="
# atone.sh records each atone to .session-atone-slugs/<session_id>.json. The
# breaker exits quietly when it finds no counter, so reading the wrong key does not
# fail loudly — it just never fires. Seed a counter and assert the breaker looks
# for it under the same name.
T=$(mktemp -d)
mkdir -p "$T/.claude/.session-atone-slugs" "$T/.claude/atone/derived"
printf '{"slug":"x","ts":"2026-07-16T00:00:00Z","severity":"S3","stakes":"a","event_id":"e1"}\n' \
  > "$T/.claude/.session-atone-slugs/$SID.json"
KEY_READ=$(printf 'hello' | env HOME="$T" CLAUDE_CODE_SESSION_ID="$SID" CLAUDE_SESSION_ID= \
  bash -x "$BREAKER" 2>&1 | rg -o "\.session-atone-slugs/[^']*\.json" | head -1)
if printf '%s' "$KEY_READ" | rg -q "$SID"; then
  ok "breaker resolves the counter to <session-id>.json"
elif printf '%s' "$KEY_READ" | rg -q "$TODAY"; then
  bad "breaker reads <date>.json — no counter is ever written there, so it never fires"
else
  bad "could not observe the breaker's counter path (got: '$KEY_READ')"
fi
rm -rf "$T"

echo
echo "== with no session id at all, every reader does nothing =="
# The old chain ended in `date +%Y-%m-%d`. That is not a fallback, it is the bug:
# a key every session running that day shares. All three readers now exit instead.
# Nothing here asserts the date key "works" — the point is that it is gone.
T=$(mktemp -d); mkdir -p "$T/.claude/atone" "$T/.claude/.session-atone-slugs"
noenv() { env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_SESSION_ID HOME="$T" "$@"; }

printf 'you did this wrong, revert that' | noenv bash "$GCC/hinters/30-atone-nudge.sh" >/dev/null 2>&1
if [ -z "$(ls -A "$T/.claude/atone/.session-state" 2>/dev/null)" ]; then
  ok "30-atone-nudge writes no marker without an id"
else
  bad "30-atone-nudge still wrote: $(ls "$T/.claude/atone/.session-state" | tr '\n' ' ')"
fi

printf 'hello' | noenv bash "$GCC/hinters/10-atone-circuit-breaker.sh" >/dev/null 2>&1
[ $? -eq 0 ] && ok "10-atone-circuit-breaker exits clean without an id" || bad "breaker errored without an id"

# #8: named in 3432587 as one of the three fixed readers, never exercised until now.
FI="$GCC/scripts/hooks/atone-fired-and-ignored-check.sh"
printf '{}' | noenv bash "$FI" >/dev/null 2>&1
[ $? -eq 0 ] && ok "atone-fired-and-ignored-check exits clean with no id in stdin or env" || bad "fired-and-ignored errored with no id"

# and that it reads the key atone.sh WRITES, not a date
printf '{"slug":"x","ts":"2026-07-17T00:00:00Z","severity":"S3","stakes":"a","event_id":"e1"}\n' \
  > "$T/.claude/.session-atone-slugs/$SID.json"
KEY=$(printf '{"session_id":"%s"}' "$SID" | env HOME="$T" bash -x "$FI" 2>&1 \
      | rg -o "\.session-atone-slugs/[^\"']*\.json" | head -1)
if printf '%s' "$KEY" | rg -q "$SID"; then
  ok "atone-fired-and-ignored-check resolves the counter to <session-id>.json"
elif printf '%s' "$KEY" | rg -q "$TODAY"; then
  bad "atone-fired-and-ignored-check reads <date>.json — the counter is never written there"
else
  bad "could not observe its counter path (got '$KEY')"
fi
rm -rf "$T"

echo
printf 'passed %d, failed %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
