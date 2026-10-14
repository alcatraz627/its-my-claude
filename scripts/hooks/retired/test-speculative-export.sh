#!/usr/bin/env bash
# test-speculative-export.sh — synthetic-tree acceptance suite for
# guard-speculative-export.sh. Constructs throwaway project trees, writes source
# to disk (PostToolUse fires post-write), synthesizes PostToolUse payloads, runs
# the REAL hook, and asserts fire/suppress behavior. Non-zero exit on any FAIL.
#
# This is the AUTHORITATIVE acceptance gate (the corpus replay is only a
# rate sanity-check against post-deletion trees).
#
# Usage:  bash test-speculative-export.sh
set -uo pipefail

HOOK="$HOME/.claude/scripts/hooks/guard-speculative-export.sh"
[ -f "$HOOK" ] || { echo "hook not found: $HOOK"; exit 2; }

PASS=0; FAIL=0
TMPROOT=$(mktemp -d "${TMPDIR:-/tmp}/specexport-test.XXXXXX")
SENTINELS=()   # /tmp sentinels to clean at exit

cleanup() {
  rm -rf "$TMPROOT" 2>/dev/null
  for s in "${SENTINELS[@]:-}"; do [ -n "$s" ] && rm -f "$s" 2>/dev/null; done
  rm -f /tmp/claude-specexport-spec[0-9]* 2>/dev/null
}
trap cleanup EXIT

# mkproj <name> → prints a fresh project root (with package.json marker).
mkproj() {
  local d="$TMPROOT/$1"
  mkdir -p "$d"
  printf '{"name":"%s"}\n' "$1" > "$d/package.json"
  printf '%s\n' "$d"
}

# writef <path> <content>  — write a file, creating parent dirs.
writef() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" > "$1"; }

# run_hook <mode> <file_path> <new_string> <session_id> → hook stdout.
# WARN_LOG_STORE is redirected into the throwaway tree so the hook's telemetry
# never touches the live warn-events ledger.
run_hook() {
  local mode="$1" fp="$2" ns="$3" sid="$4" payload
  SENTINELS+=("/tmp/claude-specexport-${sid:0:8}-"*)
  payload=$(jq -nc --arg sid "$sid" --arg fp "$fp" --arg ns "$ns" \
    '{session_id:$sid, tool_input:{file_path:$fp, new_string:$ns}}')
  printf '%s' "$payload" | SPECEXPORT_MODE="$mode" WARN_LOG_STORE="$TMPROOT/warn.jsonl" bash "$HOOK" 2>/dev/null
}

fired()  { case "$1" in *additionalContext*) return 0 ;; *) return 1 ;; esac; }
has_sym(){ case "$1" in *"\`$2\`"*) return 0 ;; *) return 1 ;; esac; }

ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ -n "${2:-}" ] && printf '        %s\n' "$2"; }

assert_fires()     { if fired "$2"; then ok "$1"; else bad "$1" "expected FIRE, got silence"; fi; }
assert_suppressed(){ if fired "$2"; then bad "$1" "expected SILENCE, got a fire: ${2:0:120}"; else ok "$1"; fi; }

echo "=== guard-speculative-export.sh — synthetic acceptance suite ==="

# 1. zero-caller new export → FIRES
p=$(mkproj p1)
writef "$p/src/util.ts" 'export function computeExpensiveThing() { return 42; }
'
out=$(run_hook lenient "$p/src/util.ts" "$(cat "$p/src/util.ts")" "spec0001xxxx")
assert_fires "1  zero-caller new export FIRES" "$out"

# 2. exported type used only within its own file (satisfies/union) → suppressed
p=$(mkproj p2)
writef "$p/src/types.ts" 'export type JobDisplayState = "queued" | "running" | "done";
const current = "running" satisfies JobDisplayState;
'
out=$(run_hook lenient "$p/src/types.ts" "$(cat "$p/src/types.ts")" "spec0002xxxx")
assert_suppressed "2  own-file satisfies use SUPPRESSED" "$out"

# 3. export whose ONLY refs are in a .test.ts → FIRES lenient, SUPPRESSED strict
p=$(mkproj p3)
writef "$p/src/calc.ts" 'export function deriveJobOutputStats() { return {}; }
'
writef "$p/src/calc.test.ts" "import { deriveJobOutputStats } from './calc';
test('x', () => deriveJobOutputStats());
"
out=$(run_hook lenient "$p/src/calc.ts" "$(cat "$p/src/calc.ts")" "spec0003xxxx")
assert_fires "3a test-only ref FIRES in lenient" "$out"
out=$(run_hook strict "$p/src/calc.ts" "$(cat "$p/src/calc.ts")" "spec0003yyyy")
assert_suppressed "3b test-only ref SUPPRESSED in strict" "$out"

# 4. `export const fetchUserList = () => fetchUser()` → fetchUser SUPPRESSED
#    (the FP-1 declaration-line-anchoring proof). fetchUserList itself may fire;
#    only fetchUser must be absent.
p=$(mkproj p4)
writef "$p/src/api.ts" 'export const fetchUser = () => ({});
export const fetchUserList = () => fetchUser();
'
out=$(run_hook lenient "$p/src/api.ts" "$(cat "$p/src/api.ts")" "spec0004xxxx")
if has_sym "$out" "fetchUser"; then
  bad "4  same-line sibling use → fetchUser SUPPRESSED" "fetchUser wrongly fired: ${out:0:140}"
else
  ok "4  same-line sibling use → fetchUser SUPPRESSED (regex fix)"
fi

# 5. barrel index.ts export → suppressed
p=$(mkproj p5)
writef "$p/src/index.ts" 'export const somethingReserved = 12345;
'
out=$(run_hook lenient "$p/src/index.ts" "$(cat "$p/src/index.ts")" "spec0005xxxx")
assert_suppressed "5  barrel index.ts SUPPRESSED" "$out"

# 6. framework route page.tsx → suppressed
p=$(mkproj p6)
writef "$p/app/page.tsx" 'export function DashboardHome() { return null; }
'
out=$(run_hook lenient "$p/app/page.tsx" "$(cat "$p/app/page.tsx")" "spec0006xxxx")
assert_suppressed "6  route page.tsx SUPPRESSED" "$out"

# 7. // speculative-ok marker (line above decl) → suppressed
p=$(mkproj p7)
writef "$p/src/reserve.ts" '// speculative-ok
export function reservedApiThing() { return 1; }
'
out=$(run_hook lenient "$p/src/reserve.ts" "$(cat "$p/src/reserve.ts")" "spec0007xxxx")
assert_suppressed "7  // speculative-ok marker SUPPRESSED" "$out"

# 8. second write of same symbol, same session → suppressed (sentinel)
p=$(mkproj p8)
writef "$p/src/twice.ts" 'export function computeTwiceThing() { return 1; }
'
out1=$(run_hook lenient "$p/src/twice.ts" "$(cat "$p/src/twice.ts")" "spec0008xxxx")
out2=$(run_hook lenient "$p/src/twice.ts" "$(cat "$p/src/twice.ts")" "spec0008xxxx")
assert_fires      "8a first write FIRES" "$out1"
assert_suppressed "8b second write same session SUPPRESSED (sentinel)" "$out2"

# 9. comment-mention-only (// TODO: wire computeMetrics) → still FIRES lenient
p=$(mkproj p9)
writef "$p/src/metrics.ts" 'export function computeMetrics() { return 1; }
// TODO: wire computeMetrics later
'
out=$(run_hook lenient "$p/src/metrics.ts" "$(cat "$p/src/metrics.ts")" "spec0009xxxx")
assert_fires "9  comment-mention-only still FIRES in lenient" "$out"

# 10a. non-TS file → silent
p=$(mkproj p10)
writef "$p/notes.md" 'export function fakeThing() {}
'
out=$(run_hook lenient "$p/notes.md" "$(cat "$p/notes.md")" "spec0010xxxx")
assert_suppressed "10a non-TS file → silent" "$out"

# 10b. no project root → silent (isolated dir with no package.json/.git ancestor)
iso=$(mktemp -d "${TMPDIR:-/tmp}/specexport-noroot.XXXXXX")
mkdir -p "$iso/deep"
writef "$iso/deep/orphan.ts" 'export function orphanThing() { return 1; }
'
out=$(run_hook lenient "$iso/deep/orphan.ts" "$(cat "$iso/deep/orphan.ts")" "spec0011xxxx")
assert_suppressed "10b no project root → silent" "$out"
rm -rf "$iso" 2>/dev/null

echo "---------------------------------------------------------------"
echo "PASS=$PASS  FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && { echo "ALL PASS"; exit 0; } || { echo "SUITE FAILED"; exit 1; }
