#!/usr/bin/env bash
# test_scripts.sh — Integration tests for std::claude shell scripts.
#
# Run: bash ~/.claude/skills/shared/test_scripts.sh
# Exit 0 = all pass, exit 1 = failures
set -uo pipefail

SHARED="$HOME/.claude/skills/shared"
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

passed=0
failed=0

check() {
  local name="$1" result="$2"
  if [[ "$result" == "0" ]]; then
    (( passed++ ))
    printf "  PASS  %s\n" "$name"
  else
    (( failed++ ))
    printf "  FAIL  %s\n" "$name"
  fi
}

echo "std::claude test_scripts.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── check-path.sh ────────────────────────────────────────────────
echo ""
echo "▸ check-path.sh"

# Valid path should exit 0
bash "$SHARED/check-path.sh" "/Users/test/project/src/index.ts" >/dev/null 2>&1
check "valid path exits 0" "$?"

# Forbidden paths should exit 1
bash "$SHARED/check-path.sh" "/Users/test/node_modules/pkg/index.js" >/dev/null 2>&1
r=$?; [[ $r -ne 0 ]]; check "node_modules blocked" "$?"

bash "$SHARED/check-path.sh" "/Users/test/.git/config" >/dev/null 2>&1
r=$?; [[ $r -ne 0 ]]; check ".git blocked" "$?"

bash "$SHARED/check-path.sh" "/Users/test/project/.env" >/dev/null 2>&1
r=$?; [[ $r -ne 0 ]]; check ".env blocked" "$?"

# ── lock-file.sh ─────────────────────────────────────────────────
echo ""
echo "▸ lock-file.sh"

TEST_LOCK_PATH="$TMPDIR_TEST/test-file.md"
touch "$TEST_LOCK_PATH"

# Acquire should succeed
bash "$SHARED/lock-file.sh" acquire "$TEST_LOCK_PATH" "test-skill" >/dev/null 2>&1
check "acquire succeeds" "$?"

# Check should show locked (exit 1)
bash "$SHARED/lock-file.sh" check "$TEST_LOCK_PATH" >/dev/null 2>&1
r=$?; [[ $r -ne 0 ]]; check "check shows locked" "$?"

# Release should succeed
bash "$SHARED/lock-file.sh" release "$TEST_LOCK_PATH" "test-skill" >/dev/null 2>&1
check "release succeeds" "$?"

# Check after release should show free (exit 0)
bash "$SHARED/lock-file.sh" check "$TEST_LOCK_PATH" >/dev/null 2>&1
check "check shows free after release" "$?"

# Cleanup should succeed
bash "$SHARED/lock-file.sh" cleanup >/dev/null 2>&1
check "cleanup succeeds" "$?"

# ── log-run.sh ───────────────────────────────────────────────────
echo ""
echo "▸ log-run.sh"

# log-run.sh takes <skill-name> <message> and writes to shared/run.log
RUN_LOG="$SHARED/run.log"
before_lines=0
[[ -f "$RUN_LOG" ]] && before_lines=$(wc -l < "$RUN_LOG" | tr -d ' ')

bash "$SHARED/log-run.sh" "test-skill" "test message 1" >/dev/null 2>&1
check "log-run writes to run.log" "$([[ -f "$RUN_LOG" ]] && echo 0 || echo 1)"

bash "$SHARED/log-run.sh" "test-skill" "test message 2" >/dev/null 2>&1
after_lines=$(wc -l < "$RUN_LOG" | tr -d ' ')
added=$(( after_lines - before_lines ))
check "log-run appended 2 entries" "$([[ $added -ge 2 ]] && echo 0 || echo 1)"

# Check timestamp format in last entry
tail -1 "$RUN_LOG" | grep -q "$(date +%Y)" 2>/dev/null
check "log entry has timestamp" "$?"

# ── prepend-runtime-note.sh ──────────────────────────────────────
echo ""
echo "▸ prepend-runtime-note.sh"

# Create a temp note
NOTE_TMP="$TMPDIR_TEST/note.md"
cat > "$NOTE_TMP" << 'ENTRY'
## test-skill: Test note — 2026-04-06

**Purpose:** Testing prepend
**Insights:**
1. This is a test

---
ENTRY

# Create a fake runtime-notes in temp dir to avoid modifying real one
export RUNTIME_NOTES_PATH="$TMPDIR_TEST/runtime-notes.md"
# prepend-runtime-note.sh may not support custom paths — test existence check only
if [[ -f "$SHARED/prepend-runtime-note.sh" ]]; then
  check "prepend-runtime-note.sh exists" "0"
else
  check "prepend-runtime-note.sh exists" "1"
fi

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  std::claude test_scripts.sh — %d passed, %d failed\n" "$passed" "$failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $failed -gt 0 ]] && exit 1
exit 0
