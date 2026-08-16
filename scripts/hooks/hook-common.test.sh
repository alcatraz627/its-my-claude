#!/usr/bin/env bash
# hook-common.test.sh — runnable checks for hook-common.sh.
#
# Covers what the replay fixture corpus structurally cannot: the replay gate uses
# a FRESH synthetic session id per fixture and cleans up after each, so it only
# ever exercises a hook's FIRST fire — never the repeat/loop-safety path that
# hook_loop_check owns. This test drives that path end-to-end (block once, then
# step aside on the identical message) plus the unit behaviour of both helpers.
#
# Run: bash ~/.claude/scripts/hooks/hook-common.test.sh   (exit 0 = all pass)
# It redirects the warn-log ledger (WARN_LOG_STORE) so it never touches the live
# audit file.

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/hook-common.sh"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }

# ── hook_sid8 ────────────────────────────────────────────────────────────────
ok "sid8 normal (16-char uuid head)" "$(hook_sid8 '86f5f8bd-fc06-44d0')" "86f5f8bd"
ok "sid8 empty -> nosid"             "$(hook_sid8 '')"                    "nosid"
ok "sid8 short (<8) passes through"  "$(hook_sid8 'abc')"                 "abc"

# ── hook_loop_check state machine ────────────────────────────────────────────
M="$(mktemp -u "${TMPDIR:-/tmp}/hcm-XXXXXX")"; rm -f "$M"
hook_loop_check "$M" "claim ONE"; ok "first fire = new"          "$?" "0"
[ -f "$M" ]; ok "marker written on new"                          "$?" "0"
hook_loop_check "$M" "claim ONE"; ok "identical = repeat"        "$?" "1"
hook_loop_check "$M" "claim TWO"; ok "changed = new"             "$?" "0"
hook_loop_check "$M" "claim TWO"; ok "repeat after change"       "$?" "1"
ok "marker holds latest sig" "$(cat "$M")" "$(printf '%s' 'claim TWO' | shasum | awk '{print $1}')"
rm -f "$M"
# adversarial content must not be evaluated — only hashed
M2="$(mktemp -u "${TMPDIR:-/tmp}/hcm2-XXXXXX")"; rm -f "$M2"
CANARY="$(mktemp -u "${TMPDIR:-/tmp}/hccanary-XXXXXX")"
hook_loop_check "$M2" 'x`touch '"$CANARY"'`; $(touch '"$CANARY"') & end'
[ -e "$CANARY" ]; ok "content is hashed, never eval'd (no injection)" "$?" "1"
rm -f "$M2" "$CANARY"

# ── hook_clear_reset (post-/clear counter reset) ─────────────────────────────
CR="$(mktemp "${TMPDIR:-/tmp}/hccr-XXXXXX")"; SENT="/tmp/claude-clear-reset-hcrtest0"; rm -f "$SENT"
echo "n=1" > "$CR"; sleep 1; : > "$SENT"
hook_clear_reset "hcrtest0" "$CR"; [ -f "$CR" ] && r=kept || r=reset; ok "clear_reset: sentinel newer -> reset" "$r" "reset"
: > "$SENT"; sleep 1; echo "n=2" > "$CR"
hook_clear_reset "hcrtest0" "$CR"; [ -f "$CR" ] && r=kept || r=reset; ok "clear_reset: sentinel older -> kept" "$r" "kept"
rm -f "$SENT"
hook_clear_reset "hcrtest0" "$CR"; [ -f "$CR" ] && r=kept || r=reset; ok "clear_reset: no sentinel -> kept" "$r" "kept"
rm -f "$CR" "$SENT"

# ── injector integration: post-clear-counter-reset.sh source-gating ──────────
# Exercises the script that reads a real .source payload + derives sid8 — the gap
# the skeptical review flagged (only the primitive was covered). Note: this proves
# the injector's LOGIC given source=="clear"; that the harness actually SENDS
# "clear" on /clear is a separate, harness-level fact (see the script header).
INJ="$HERE/../session-mgmt/post-clear-counter-reset.sh"
if [ -f "$INJ" ] && command -v jq >/dev/null 2>&1; then
  ISENT="/tmp/claude-clear-reset-injtest1"; rm -f "$ISENT"
  printf '%s' '{"source":"clear","session_id":"injtest1-abcd-efgh"}' | bash "$INJ" 2>/dev/null
  [ -f "$ISENT" ] && ir=yes || ir=no; ok "injector: source==clear writes sentinel" "$ir" "yes"
  rm -f "$ISENT"
  printf '%s' '{"source":"startup","session_id":"injtest1-abcd-efgh"}' | bash "$INJ" 2>/dev/null
  [ -f "$ISENT" ] && ir=yes || ir=no; ok "injector: source==startup no sentinel" "$ir" "no"
  rm -f "$ISENT"
else
  echo "  SKIP injector integration: script / jq unavailable"
fi

# ── repeat-path integration: real migrated hook, twice on one message ─────────
# filename-dot-stop.sh (Family A): first fire blocks, identical message steps
# aside. This is the exact path the replay corpus cannot reach.
HOOK="$HERE/filename-dot-stop.sh"
if [ -x "$HOOK" ] && command -v jq >/dev/null 2>&1 && command -v rg >/dev/null 2>&1; then
  export WARN_LOG_STORE="$(mktemp "${TMPDIR:-/tmp}/hc-warnlog-XXXXXX")"
  TS="$(mktemp "${TMPDIR:-/tmp}/hc-transcript-XXXXXX")"
  printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"The fix is in foo.md."}]}}' > "$TS"
  SID="hctest01x"; MK="/tmp/claude-filename-dot-hctest01"; rm -f "$MK"
  IN="$(jq -cn --arg s "$SID" --arg tp "$TS" '{session_id:$s, transcript_path:$tp}')"
  o1="$(printf '%s' "$IN" | bash "$HOOK" 2>/dev/null)"
  o2="$(printf '%s' "$IN" | bash "$HOOK" 2>/dev/null)"
  printf '%s' "$o1" | rg -q '"decision":"block"' && r1=block || r1=other
  if printf '%s' "$o2" | rg -q '"decision":"block"'; then r2=block
  elif printf '%s' "$o2" | rg -q 'systemMessage'; then r2=stepaside
  else r2=silent; fi
  ok "integration: first fire blocks"        "$r1" "block"
  ok "integration: repeat steps aside"       "$r2" "stepaside"
  rm -f "$MK" "$TS" "$WARN_LOG_STORE"; unset WARN_LOG_STORE
else
  echo "  SKIP integration: filename-dot-stop.sh / jq / rg unavailable"
fi

# ── hook_box ─────────────────────────────────────────────────────────────────
B="$(printf 'alpha\nbravo\n' | hook_box 'MY TITLE')"
printf '%s' "$B" | head -1 | grep -q 'MY TITLE'; ok "box: title in the top rule" "$?" "0"
printf '%s' "$B" | grep -q '^│ alpha$';           ok "box: body gets the rail"   "$?" "0"
printf '%s' "$B" | tail -1 | grep -q '^└─';       ok "box: bottom rule closes"   "$?" "0"

# Regression: printf-built bodies usually end WITHOUT a newline, and a bare
# `read` loop drops that final line. Caught by running the real hook, never by
# reading it — the reason arrived one line short with no error anywhere.
NL="$(printf 'first\nLASTLINE' | hook_box 'NO TRAILING NEWLINE')"
printf '%s' "$NL" | grep -q 'LASTLINE'; ok "box: final line without newline survives" "$?" "0"

# A blank body line is a bare rail, not a rail plus a stray space.
BL="$(printf 'a\n\nb\n' | hook_box 'BLANKS')"
printf '%s' "$BL" | grep -cq '^│ $'; ok "box: blank line leaves no trailing space" "$?" "1"

# Wrapping breaks on spaces, so a word never splits across two rails.
WR="$(printf 'antidisestablishmentarianism followed by many other words that push this line well past the wrap width limit\n' | hook_box 'WRAP' 40)"
printf '%s' "$WR" | grep -q 'antidisestablishmentarianism'; ok "box: long word stays whole" "$?" "0"
ok "box: wrapping actually happened" "$([ "$(printf '%s\n' "$WR" | wc -l | tr -d ' ')" -gt 3 ] && echo yes || echo no)" "yes"

# A title longer than the width must not compute a negative fill and blow up.
OT="$(printf 'body\n' | hook_box "$(printf 'X%.0s' 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0)" 40)"
printf '%s' "$OT" | grep -q '^│ body$'; ok "box: overlong title still renders body" "$?" "0"

# Geometry. The box is meant to be square, and nothing above checks that, which
# is how it shipped one character wider at the bottom in every box it ever drew.
# Count CHARACTERS, not bytes: each box-drawing glyph is 3 bytes in UTF-8, so
# `${#s}` in some shells and awk's length() both lie here. `wc -m` is honest.
boxw() { printf '%s' "$1" | wc -m | tr -d ' '; }
G="$(printf 'body\n' | hook_box 'T' 40)"
gtop="$(boxw "$(printf '%s\n' "$G" | head -1)")"
gbot="$(boxw "$(printf '%s\n' "$G" | tail -1)")"
ok "box: top rule is exactly the requested width"    "$gtop" "40"
ok "box: bottom rule is exactly the requested width" "$gbot" "40"
ok "box: the box is square"                          "$gtop" "$gbot"

# Same check at a second width, so a fix that hardcodes one number cannot pass.
G2="$(printf 'body\n' | hook_box 'LONGER TITLE' 66)"
ok "box: square at another width" \
   "$(boxw "$(printf '%s\n' "$G2" | head -1)")" \
   "$(boxw "$(printf '%s\n' "$G2" | tail -1)")"
ok "box: honours that width too" "$(boxw "$(printf '%s\n' "$G2" | head -1)")" "66"

# ── integration: prose-smell-stop.sh emits a BOXED block reason ───────────────
PS="$HERE/prose-smell-stop.sh"
if [ -f "$PS" ] && command -v jq >/dev/null 2>&1 && command -v rg >/dev/null 2>&1; then
  export WARN_LOG_STORE="$(mktemp "${TMPDIR:-/tmp}/hc-warnlog2-XXXXXX")"
  PT="$(mktemp "${TMPDIR:-/tmp}/hc-prose-XXXXXX")"
  # Trips em-dash + bold-spam + Label:fragment = 3 block-tier categories.
  jq -cn '{type:"assistant",message:{content:[{type:"text",text:"Here is the summary — it covers everything.\n\n**One**: the loader resolves correctly and returns the parsed value now.\n**Two**: the cache was invalidated on every write which caused the stall.\n**Three**: the retry path is bounded so a failure cannot spin forever.\n**Four**: logging moved behind a flag to keep the hot path quiet here.\n**Five**: the tests cover the empty and the overflow case end to end.\n**Six**: documentation was regenerated to match the reference exactly.\n"}]}}' > "$PT"
  # 9 chars, so sid8 truncates to a known 8 — a sid of exactly 8 makes the
  # marker path the whole string and a hand-written cleanup path silently misses.
  PSID="hcbox001x"; rm -f "/tmp/claude-prose-smell-hcbox001"
  PIN="$(jq -cn --arg s "$PSID" --arg tp "$PT" '{session_id:$s, transcript_path:$tp}')"
  po="$(printf '%s' "$PIN" | PROSE_SMELL_ENFORCE=1 bash "$PS" 2>/dev/null)"
  pr="$(printf '%s' "$po" | jq -r '.reason // empty' 2>/dev/null)"
  # A block `reason` is NOT boxed. The harness renders it as one clipped
  # "Stop hook error:" line, so a box arrives truncated mid-word with the
  # actionable half past the clip (owner-reported live fire, 2026-08-15;
  # conventions/callout-boxes.md "Match the shape to the channel"). These
  # assertions are positive on purpose: proving the box is gone says nothing
  # about whether the content survived, and the previous compaction silently
  # dropped the process-scoped mute until this test caught it.
  [ "$(printf '%s' "$pr" | wc -l | tr -d ' ')" -eq 0 ]; ok "integration: block reason is single-line" "$?" "0"
  printf '%s' "$pr" | grep -q '[┏┃┗━]'; ok "integration: block reason carries no box glyphs" "$?" "1"
  printf '%s' "$pr" | grep -q 'prose-smell'; ok "integration: reason names the emitter" "$?" "0"
  printf '%s' "$pr" | grep -q 'em-dash'; ok "integration: reason names the tell that fired" "$?" "0"
  printf '%s' "$pr" | grep -q 'no-prose-smell-gate'; ok "integration: reason keeps the machine-wide mute" "$?" "0"
  printf '%s' "$pr" | grep -q 'PROSE_SMELL_OFF=1'; ok "integration: reason keeps the process mute" "$?" "0"
  rm -f "/tmp/claude-prose-smell-hcbox001" "$PT" "$WARN_LOG_STORE"; unset WARN_LOG_STORE
else
  echo "  SKIP prose-smell integration: script / jq / rg unavailable"
fi

# ── hook_box_kind (vocab bridge to box.sh) ───────────────────────────────────
K="$(printf 'body\n→ act\n' | hook_box_kind gate prose-smell)"
printf '%s' "$K" | head -1 | grep -q '⛔ gate · prose-smell'; ok "kind: vocab title composed"   "$?" "0"
printf '%s' "$K" | head -1 | grep -q '^┏━';                   ok "kind: gate gets heavy rails"  "$?" "0"
printf '%s' "$K" | grep -q '^┃ body$';                        ok "kind: body behind heavy rail" "$?" "0"
K2="$(printf 'body\n→ act\n' | hook_box_kind landing probe 'ran 2m')"
printf '%s' "$K2" | head -1 | grep -q '🛬 subagent · probe';  ok "kind: landing vocab title"    "$?" "0"
printf '%s' "$K2" | head -1 | grep -q 'ran 2m ──$';           ok "kind: attr right-anchored"    "$?" "0"
# The fallback is the load-bearing half: a hook on a half-installed tree must
# still box its reason. BOX_SH points at nothing, so the delegate cannot run.
KF="$(printf 'body\n' | BOX_SH=/nonexistent hook_box_kind gate prose-smell)"
printf '%s' "$KF" | head -1 | grep -q '^┌─ gate · prose-smell'; ok "kind: falls back without box.sh" "$?" "0"
printf '%s' "$KF" | grep -q '^│ body$';                         ok "kind: fallback keeps the body"   "$?" "0"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
