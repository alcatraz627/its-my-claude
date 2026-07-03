#!/usr/bin/env bash
# test-banned-vocab.sh — synthetic-tree acceptance suite for guard-banned-vocab.sh.
# Builds throwaway project trees (some with a .claude/banned-vocab.txt, some
# without), synthesizes PreToolUse payloads, runs the REAL hook, and asserts
# block/silence behavior. Non-zero exit on any FAIL.
#
# Usage:  bash test-banned-vocab.sh
set -uo pipefail

HOOK="$HOME/.claude/scripts/hooks/guard-banned-vocab.sh"
[ -f "$HOOK" ] || { echo "hook not found: $HOOK"; exit 2; }

PASS=0; FAIL=0
TMPROOT=$(mktemp -d "${TMPDIR:-/tmp}/bannedvocab-test.XXXXXX")
cleanup() { rm -rf "$TMPROOT" 2>/dev/null; }
trap cleanup EXIT

# mkproj <name> [vocab-contents] → prints a fresh project root. If vocab-contents
# is given, writes it to <root>/.claude/banned-vocab.txt (the opt-in file).
mkproj() {
  local d="$TMPROOT/$1"
  mkdir -p "$d"
  printf '{"name":"%s"}\n' "$1" > "$d/package.json"
  if [ $# -ge 2 ]; then
    mkdir -p "$d/.claude"
    printf '%s' "$2" > "$d/.claude/banned-vocab.txt"
  fi
  printf '%s\n' "$d"
}

# run_write <file_path> <content> → hook stdout (Write payload).
run_write() {
  local fp="$1" c="$2" payload
  payload=$(jq -nc --arg fp "$fp" --arg c "$c" \
    '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}')
  printf '%s' "$payload" | WARN_LOG_STORE="$TMPROOT/warn.jsonl" bash "$HOOK" 2>/dev/null
}

# run_edit <file_path> <new_string> → hook stdout (Edit payload).
run_edit() {
  local fp="$1" ns="$2" payload
  payload=$(jq -nc --arg fp "$fp" --arg ns "$ns" \
    '{tool_name:"Edit", tool_input:{file_path:$fp, new_string:$ns, old_string:""}}')
  printf '%s' "$payload" | WARN_LOG_STORE="$TMPROOT/warn.jsonl" bash "$HOOK" 2>/dev/null
}

blocked() { case "$1" in *'"decision"'*'"block"'*|*'"block"'*) return 0 ;; *) return 1 ;; esac; }
mentions(){ case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ -n "${2:-}" ] && printf '        %s\n' "$2"; }

assert_block()  { if blocked "$2"; then ok "$1"; else bad "$1" "expected BLOCK, got: ${2:0:160}"; fi; }
assert_silent() { if blocked "$2"; then bad "$1" "expected SILENCE, got a block: ${2:0:160}"; else ok "$1"; fi; }

VOCAB='# customer-facing docs vocabulary
Impersonation => Access delegation
blacklist => denylist
whitelist
click here => the settings page
'

echo "=== guard-banned-vocab.sh — synthetic acceptance suite ==="

# 1. banned term added to a .md, project opted in → BLOCK
p=$(mkproj p1 "$VOCAB")
out=$(run_write "$p/docs/guide.md" $'# Guide\n\nUse Impersonation to act as a user.\n')
assert_block "1  banned term in .md (opted in) BLOCKS" "$out"
mentions "$out" "Access delegation" && ok "1b block names the replacement" || bad "1b block names the replacement" "no replacement in reason"

# 2. NO banned-vocab.txt anywhere → silent (gate inert)
p=$(mkproj p2)
out=$(run_write "$p/docs/guide.md" $'Use Impersonation freely, no opt-in here.\n')
assert_silent "2  no vocab file → silent (inert)" "$out"

# 3. term NOT in the list → silent
p=$(mkproj p3 "$VOCAB")
out=$(run_write "$p/docs/ok.md" $'This document is perfectly clean and allowed.\n')
assert_silent "3  clean text (no banned term) → silent" "$out"

# 4. case-insensitive: lowercase 'impersonation' → BLOCK
p=$(mkproj p4 "$VOCAB")
out=$(run_write "$p/docs/x.md" $'the impersonation flow runs here\n')
assert_block "4  case-insensitive lowercase match BLOCKS" "$out"

# 5. whole-word: camelCase identifier ImpersonationService → silent (not a word)
p=$(mkproj p5 "$VOCAB")
out=$(run_write "$p/src/svc.ts" $'export class ImpersonationServiceImpl {}\n')
assert_silent "5  camelCase identifier → silent (whole-word)" "$out"

# 6. whole-word: snake_case impersonation_flow → silent
p=$(mkproj p6 "$VOCAB")
out=$(run_write "$p/src/f.py" $'def impersonation_flow():\n    return 1\n')
assert_silent "6  snake_case identifier → silent (whole-word)" "$out"

# 7. banned term in a CODE COMMENT (opt-in project) → BLOCK
p=$(mkproj p7 "$VOCAB")
out=$(run_write "$p/src/f.py" $'# TODO: wire up Impersonation later\ndef f():\n    return 1\n')
assert_block "7  banned term in code comment BLOCKS" "$out"

# 8. multi-word phrase 'click here' → BLOCK
p=$(mkproj p8 "$VOCAB")
out=$(run_write "$p/docs/cta.md" $'Please click here to finish.\n')
assert_block "8  multi-word phrase BLOCKS" "$out"

# 9. Edit (not Write) adding a banned term → BLOCK
p=$(mkproj p9 "$VOCAB")
out=$(run_edit "$p/docs/edit.md" $'We added a blacklist of users.\n')
assert_block "9  Edit new_string with banned term BLOCKS" "$out"

# 10. term with no replacement ('whitelist') → BLOCK, no 'use' clause
p=$(mkproj p10 "$VOCAB")
out=$(run_write "$p/docs/w.md" $'Add them to the whitelist.\n')
assert_block "10  no-replacement term BLOCKS" "$out"

# 11. non-text file (.png) → silent even with banned bytes
p=$(mkproj p11 "$VOCAB")
out=$(run_write "$p/assets/img.png" $'Impersonation\n')
assert_silent "11  non-text extension → silent" "$out"

# 12. editing the vocab file itself → silent (never scan the ban list)
p=$(mkproj p12 "$VOCAB")
out=$(run_write "$p/.claude/banned-vocab.txt" $'Impersonation => Access delegation\n')
assert_silent "12  editing banned-vocab.txt itself → silent" "$out"

# 13. mute file honored → silent even on a clear violation
p=$(mkproj p13 "$VOCAB")
MUTE="$HOME/.claude/.no-banned-vocab-gate"
had_mute=0; [ -f "$MUTE" ] && had_mute=1
touch "$MUTE"
out=$(run_write "$p/docs/m.md" $'Use Impersonation here.\n')
assert_silent "13  mute file → silent" "$out"
[ "$had_mute" -eq 0 ] && rm -f "$MUTE"

# 14. comment line in vocab starting with '#' is ignored (no phantom ban on '#...')
p=$(mkproj p14 "$VOCAB")
out=$(run_write "$p/docs/c.md" $'This mentions customer-facing docs vocabulary in prose.\n')
assert_silent "14  vocab '#' comment line does not become a ban" "$out"

echo "---------------------------------------------------------------"
echo "PASS=$PASS  FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && { echo "ALL PASS"; exit 0; } || { echo "SUITE FAILED"; exit 1; }
