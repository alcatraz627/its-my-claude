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

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
