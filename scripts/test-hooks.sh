#!/usr/bin/env bash
# test-hooks.sh — smoke tests for the global hook scripts.
#
# Each test function (named `test_*`) fires a hook script with a crafted stdin
# and asserts exit code, stdout, stderr, or resulting filesystem side-effects.
#
# Isolation: side-effectful scripts (emit-event, rotate-events, rotate-wal,
# validate-memory) are run with HOME pointed at a temp dir so they touch an
# isolated `~/.claude/` rather than the real one.
#
# Usage:
#   test-hooks.sh                     # run all tests
#   test-hooks.sh --filter emit       # run only tests whose name contains "emit"
#   test-hooks.sh --verbose           # stream each script's output even on pass
#
# Exit 0 if all tests pass; exit 1 if any fail.

set -uo pipefail

FILTER=""
VERBOSE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --filter) FILTER="$2"; shift 2 ;;
    --verbose|-v) VERBOSE=1; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) shift ;;
  esac
done

SCRIPT_DIR="$HOME/.claude/scripts"

# Per-run temp dir that doubles as a fake $HOME for isolated tests.
FAKE_HOME=$(mktemp -d -t claude-test-hooks.XXXXXX)
mkdir -p "$FAKE_HOME/.claude"

pass=0
fail=0
failed_names=()

# --- helpers ------------------------------------------------------------------

# run_hook <script> <event-or-arg> <input-json>
# Prints exit code on line 1, stdout on line 2, stderr on line 3 (all base64'd).
run_hook() {
  local script="$1" arg="${2:-}" input="${3:-}"
  local out err exit_code
  local tmp_out tmp_err
  tmp_out=$(mktemp)
  tmp_err=$(mktemp)
  if [ -z "$input" ]; then
    HOME="$FAKE_HOME" bash "$script" ${arg:+"$arg"} >"$tmp_out" 2>"$tmp_err"
  else
    HOME="$FAKE_HOME" bash "$script" ${arg:+"$arg"} >"$tmp_out" 2>"$tmp_err" <<EOF
$input
EOF
  fi
  exit_code=$?
  out=$(cat "$tmp_out")
  err=$(cat "$tmp_err")
  rm -f "$tmp_out" "$tmp_err"
  printf 'EXIT:%s\n' "$exit_code"
  printf '<<STDOUT>>\n%s\n<<ENDOUT>>\n' "$out"
  printf '<<STDERR>>\n%s\n<<ENDERR>>\n' "$err"
}

extract_exit()   { echo "$1" | grep -E '^EXIT:' | head -1 | cut -d: -f2; }
extract_stdout() { echo "$1" | awk '/<<STDOUT>>/{flag=1; next} /<<ENDOUT>>/{flag=0} flag'; }
extract_stderr() { echo "$1" | awk '/<<STDERR>>/{flag=1; next} /<<ENDERR>>/{flag=0} flag'; }

assert_exit() {
  local expected="$1" actual="$2" label="$3"
  if [ "$actual" = "$expected" ]; then return 0; fi
  echo "    ✗ $label: expected exit=$expected, got $actual"
  return 1
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then return 0; fi
  echo "    ✗ $label: expected to contain '$needle'"
  [ "$VERBOSE" -eq 1 ] && echo "      haystack: $haystack"
  return 1
}

assert_not_contains() {
  local haystack="$1" needle="$2" label="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    echo "    ✗ $label: expected NOT to contain '$needle'"
    return 1
  fi
  return 0
}

# --- test: block-nested-claude -----------------------------------------------

test_block_nested_blocks_write() {
  local input='{"tool_name":"Write","tool_input":{"file_path":"/Users/alcatraz627/.claude/.claude/output/foo"}}'
  local r; r=$(run_hook "$SCRIPT_DIR/block-nested-claude.sh" "" "$input")
  local exit_code; exit_code=$(extract_exit "$r")
  local stderr; stderr=$(extract_stderr "$r")
  assert_exit 2 "$exit_code" "should block nested .claude/.claude/" || return 1
  assert_contains "$stderr" "BLOCKED:" "stderr should mention BLOCKED" || return 1
  return 0
}

test_block_nested_allows_normal() {
  local input='{"tool_name":"Write","tool_input":{"file_path":"/Users/alcatraz627/project/src/foo.ts"}}'
  local r; r=$(run_hook "$SCRIPT_DIR/block-nested-claude.sh" "" "$input")
  local exit_code; exit_code=$(extract_exit "$r")
  assert_exit 0 "$exit_code" "should allow normal project path" || return 1
  return 0
}

test_block_nested_catches_bash_command() {
  local input='{"tool_name":"Bash","tool_input":{"command":"mkdir -p /Users/x/.claude/.claude/output/q"}}'
  local r; r=$(run_hook "$SCRIPT_DIR/block-nested-claude.sh" "" "$input")
  local exit_code; exit_code=$(extract_exit "$r")
  assert_exit 2 "$exit_code" "should block Bash commands with nested path" || return 1
  return 0
}

# --- test: safe-delete -------------------------------------------------------

test_safe_delete_blocks_rm() {
  local input='{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/foo"}}'
  local r; r=$(run_hook "$SCRIPT_DIR/safe-delete.sh" "" "$input")
  local stdout; stdout=$(extract_stdout "$r")
  assert_contains "$stdout" '"decision": "block"' "stdout should carry block decision" || return 1
  return 0
}

test_safe_delete_allows_git_rm() {
  local input='{"tool_name":"Bash","tool_input":{"command":"git rm foo.ts"}}'
  local r; r=$(run_hook "$SCRIPT_DIR/safe-delete.sh" "" "$input")
  local exit_code; exit_code=$(extract_exit "$r")
  local stdout; stdout=$(extract_stdout "$r")
  assert_exit 0 "$exit_code" "git rm should pass through" || return 1
  assert_not_contains "$stdout" '"decision": "block"' "git rm should not emit block" || return 1
  return 0
}

test_safe_delete_allows_trash() {
  local input='{"tool_name":"Bash","tool_input":{"command":"trash /tmp/foo"}}'
  local r; r=$(run_hook "$SCRIPT_DIR/safe-delete.sh" "" "$input")
  local stdout; stdout=$(extract_stdout "$r")
  assert_not_contains "$stdout" '"decision": "block"' "trash should not be blocked" || return 1
  return 0
}

# --- test: emit-event -------------------------------------------------------

test_emit_writes_session_start_line() {
  local input='{"session_id":"harness-ev-01","cwd":"/tmp/proj"}'
  run_hook "$SCRIPT_DIR/emit-event.sh" "SessionStart" "$input" >/dev/null
  local log="$FAKE_HOME/.claude/events.jsonl"
  if [ ! -f "$log" ]; then
    echo "    ✗ no events.jsonl written at $log"; return 1
  fi
  local last; last=$(tail -1 "$log")
  assert_contains "$last" '"event":"SessionStart"' "line should carry event" || return 1
  assert_contains "$last" '"session_id":"harness-ev-01"' "line should carry session_id" || return 1
  return 0
}

test_emit_duration_on_pre_post_pair() {
  local tid="toolu_HARNESS_$(printf '%04x' $RANDOM)"
  local pre_in="{\"session_id\":\"harness-ev-02\",\"tool_name\":\"Bash\",\"tool_use_id\":\"$tid\"}"
  local post_in="{\"session_id\":\"harness-ev-02\",\"tool_name\":\"Bash\",\"tool_use_id\":\"$tid\"}"
  run_hook "$SCRIPT_DIR/emit-event.sh" "PreToolUse" "$pre_in" >/dev/null
  sleep 0.1
  run_hook "$SCRIPT_DIR/emit-event.sh" "PostToolUse" "$post_in" >/dev/null
  local log="$FAKE_HOME/.claude/events.jsonl"
  local post_line; post_line=$(grep '"event":"PostToolUse"' "$log" | grep "$tid" | tail -1)
  [ -z "$post_line" ] && { echo "    ✗ no PostToolUse line"; return 1; }
  # duration_ms should be a positive integer (≥50ms from the sleep)
  local dur; dur=$(echo "$post_line" | jq -r '.duration_ms // empty')
  if [ -z "$dur" ] || [ "$dur" -lt 50 ] 2>/dev/null; then
    echo "    ✗ expected duration_ms ≥ 50, got: $dur"; return 1
  fi
  return 0
}

test_emit_error_flag_on_failure() {
  local input='{"session_id":"harness-ev-03","tool_name":"Read","tool_use_id":"toolu_ERRX","tool_response":{"is_error":true}}'
  run_hook "$SCRIPT_DIR/emit-event.sh" "PostToolUse" "$input" >/dev/null
  local log="$FAKE_HOME/.claude/events.jsonl"
  local line; line=$(grep "toolu_ERRX" "$log" | tail -1)
  assert_contains "$line" '"error":true' "should set error:true when tool_response.is_error" || return 1
  return 0
}

test_emit_omits_empty_session_id() {
  local input='{"cwd":"/tmp"}'
  run_hook "$SCRIPT_DIR/emit-event.sh" "UserPromptSubmit" "$input" >/dev/null
  local log="$FAKE_HOME/.claude/events.jsonl"
  local last; last=$(tail -1 "$log")
  assert_not_contains "$last" '"session_id":""' "empty session_id should be omitted" || return 1
  return 0
}

# --- test: rotate-events ----------------------------------------------------

test_rotate_events_noop_under_threshold() {
  local log="$FAKE_HOME/.claude/events.jsonl"
  local before_size
  before_size=$(wc -c < "$log" 2>/dev/null | tr -d ' ')
  run_hook "$SCRIPT_DIR/rotate-events.sh" "" "" >/dev/null
  local after_size
  after_size=$(wc -c < "$log" 2>/dev/null | tr -d ' ')
  if [ "$before_size" != "$after_size" ]; then
    echo "    ✗ expected no rotation under threshold (before=$before_size after=$after_size)"
    return 1
  fi
  return 0
}

test_rotate_events_archives_when_over_threshold() {
  local log="$FAKE_HOME/.claude/events.jsonl"
  # Build a ≥1KB log with threshold set to 512 bytes to force rotation
  {
    for i in $(seq 1 30); do
      echo "{\"ts\":\"2026-04-17T00:00:0${i}Z\",\"event\":\"SessionStart\",\"session_id\":\"rot-$i\",\"padding\":\"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\"}"
    done
  } > "$log"
  EVENTS_ROTATE_THRESHOLD=512 HOME="$FAKE_HOME" bash "$SCRIPT_DIR/rotate-events.sh" >/dev/null 2>&1
  # After rotation, log should be empty (or very small) and archive should exist
  local post_size; post_size=$(wc -c < "$log" | tr -d ' ')
  if [ "$post_size" -gt 10 ]; then
    echo "    ✗ log should be empty after rotation, still $post_size bytes"; return 1
  fi
  local archives
  archives=$(ls "$FAKE_HOME/.claude/assets/backups/events-archive/"*.jsonl.gz 2>/dev/null | wc -l | tr -d ' ')
  if [ "$archives" = "0" ]; then
    echo "    ✗ expected at least one archive file in events-archive/"; return 1
  fi
  return 0
}

# --- test: rotate-wal -------------------------------------------------------

test_rotate_wal_noop_when_absent() {
  # No wal.jsonl exists — should exit 0, do nothing
  local r; r=$(run_hook "$SCRIPT_DIR/rotate-wal.sh" "" '{"cwd":"/tmp/nonexistent"}')
  local exit_code; exit_code=$(extract_exit "$r")
  assert_exit 0 "$exit_code" "rotate-wal should exit 0 when no wal.jsonl present" || return 1
  return 0
}

test_rotate_wal_archives_when_over_threshold() {
  local wal="$FAKE_HOME/.claude/wal.jsonl"
  {
    for i in $(seq 1 40); do
      echo "{\"ts\":\"2026-04-17T00:00:0${i}Z\",\"kind\":\"action\",\"session_id\":\"test-wal-rot\",\"body\":\"padding-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\"}"
    done
  } > "$wal"
  WAL_ROTATE_THRESHOLD=512 HOME="$FAKE_HOME" bash "$SCRIPT_DIR/rotate-wal.sh" >/dev/null 2>&1 <<< '{}'
  local post_size; post_size=$(wc -c < "$wal" | tr -d ' ')
  if [ "$post_size" -gt 10 ]; then
    echo "    ✗ global wal.jsonl should be empty after rotation, still $post_size bytes"; return 1
  fi
  local archives
  archives=$(ls "$FAKE_HOME/.claude/assets/backups/wal-archive/"wal-global-*.jsonl.gz 2>/dev/null | wc -l | tr -d ' ')
  if [ "$archives" = "0" ]; then
    echo "    ✗ expected at least one wal-global archive"; return 1
  fi
  return 0
}

# --- test: validate-memory --------------------------------------------------

test_validate_memory_passes_clean() {
  local mem_root="$FAKE_HOME/.claude/projects/clean-proj/memory"
  mkdir -p "$mem_root"
  cat > "$mem_root/ref_real.md" <<EOF
---
name: ref_real
type: reference
---
Script path: $SCRIPT_DIR/emit-event.sh
EOF
  local r; r=$(run_hook "$SCRIPT_DIR/validate-memory.sh" "--quiet" "")
  local exit_code; exit_code=$(extract_exit "$r")
  assert_exit 0 "$exit_code" "clean memory should pass" || return 1
  return 0
}

test_validate_memory_flags_stale() {
  local mem_root="$FAKE_HOME/.claude/projects/stale-proj/memory"
  mkdir -p "$mem_root"
  cat > "$mem_root/ref_bad.md" <<EOF
---
name: ref_bad
type: reference
---
Script: /this/path/definitely/does/not/exist.sh
EOF
  # validate-memory --path <FAKE_HOME>/.claude/projects → scans our isolated tree
  local out exit_code
  out=$(HOME="$FAKE_HOME" bash "$SCRIPT_DIR/validate-memory.sh" --path "$FAKE_HOME/.claude/projects" --quiet 2>&1)
  exit_code=$?
  if [ "$exit_code" = "0" ]; then
    echo "    ✗ expected non-zero exit on stale ref"
    echo "      output: $out"
    return 1
  fi
  assert_contains "$out" "/this/path/definitely/does/not/exist.sh" "output should name the stale path" || return 1
  return 0
}

# --- runner ------------------------------------------------------------------

all_tests=(
  test_block_nested_blocks_write
  test_block_nested_allows_normal
  test_block_nested_catches_bash_command
  test_safe_delete_blocks_rm
  test_safe_delete_allows_git_rm
  test_safe_delete_allows_trash
  test_emit_writes_session_start_line
  test_emit_duration_on_pre_post_pair
  test_emit_error_flag_on_failure
  test_emit_omits_empty_session_id
  test_rotate_events_noop_under_threshold
  test_rotate_events_archives_when_over_threshold
  test_rotate_wal_noop_when_absent
  test_rotate_wal_archives_when_over_threshold
  test_validate_memory_passes_clean
  test_validate_memory_flags_stale
)

echo "[test-hooks] fake HOME: $FAKE_HOME"
echo

for name in "${all_tests[@]}"; do
  [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]] && continue
  printf "  • %-48s" "$name"
  if "$name" >/dev/null 2>&1; then
    echo "PASS"
    pass=$((pass + 1))
  else
    echo "FAIL"
    fail=$((fail + 1))
    failed_names+=("$name")
    # Re-run the failed test with output captured for diagnostics
    echo "    --- diagnostic re-run of $name ---"
    "$name" 2>&1 | sed 's/^/      /'
  fi
done

echo
echo "[test-hooks] results: $pass passed, $fail failed"

# Clean up fake home (best-effort)
rm -rf "$FAKE_HOME" 2>/dev/null || true

[ "$fail" -gt 0 ] && exit 1
exit 0
