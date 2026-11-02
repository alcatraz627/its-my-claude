#!/usr/bin/env bash
# The hook ledger must name the session that really fired, keep test runs out of the
# owner's live file, and never break the hook calling it.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi; }
live_home=$(eval echo "~$(id -un)")
LIVE="$live_home/.claude/hooks/warn-events.jsonl"

STORE="$T/w.jsonl"
env -u CLAUDE_SESSION_ID CLAUDE_CODE_SESSION_ID=harness-sid WARN_LOG_STORE="$STORE" HOOK_TEST=1 bash "$D/warn-log.sh" --hook a --action block
check "the harness's session id is used" "$(jq -r .sid "$STORE")" "harness-sid"
: > "$STORE"
CLAUDE_SESSION_ID=explicit CLAUDE_CODE_SESSION_ID=harness-sid WARN_LOG_STORE="$STORE" bash "$D/warn-log.sh" --hook a
check "an explicit id still wins" "$(jq -r .sid "$STORE")" "explicit"

# The shared id file holds whichever session started last, so it must never be read.
: > "$STORE"
mkdir -p "$T/home/.claude"
printf 'other-session' > "$T/home/.claude/.current-session-id"
env -u CLAUDE_SESSION_ID -u CLAUDE_CODE_SESSION_ID HOME="$T/home" WARN_LOG_STORE="$STORE" bash "$D/warn-log.sh" --hook a
check "with no id the row says so" "$(jq -r .sid "$STORE")" "nosid"

: > "$STORE"
CLAUDE_CODE_ENTRYPOINT=sdk-cli WARN_LOG_STORE="$STORE" bash "$D/warn-log.sh" --hook a
check "a headless fire is marked" "$(jq -r .entry "$STORE")" "sdk-cli"
: > "$STORE"
env -u CLAUDE_CODE_ENTRYPOINT WARN_LOG_STORE="$STORE" bash "$D/warn-log.sh" --hook a
check "an unknown entry stays absent" "$(jq -c 'has("entry")' "$STORE")" "false"

# A test pointed at a temporary store or home keeps its rows.
: > "$STORE"
HOOK_TEST=1 WARN_LOG_STORE="$STORE" bash "$D/warn-log.sh" --hook a
check "a test's own store still gets rows" "$(wc -l < "$STORE" | tr -d ' ')" "1"
HOOK_TEST=1 HOME="$T/home" bash "$D/warn-log.sh" --hook a
check "a test's temporary home still gets rows" "$(wc -l < "$T/home/.claude/hooks/warn-events.jsonl" | tr -d ' ')" "1"

# The live file. Another session may append meanwhile, so look for this run's own marker.
marker="warn-log-test-$$"
HOOK_TEST=1 CLAUDE_SESSION_ID="$marker" bash "$D/warn-log.sh" --hook a
check "a test cannot write to the live ledger" "$(rg -c "$marker" "$LIVE" || echo 0)" "0"
HOOK_TEST=1 CLAUDE_SESSION_ID="$marker" WARN_LOG_STORE="$LIVE" bash "$D/warn-log.sh" --hook a
check "nor by naming it as the store" "$(rg -c "$marker" "$LIVE" || echo 0)" "0"

HOOK_TEST=1 CLAUDE_SESSION_ID="$marker" WARN_LOG_STORE="$(dirname "$LIVE")/./warn-events.jsonl" bash "$D/warn-log.sh" --hook a
check "nor by spelling the path differently" "$(rg -c "$marker" "$LIVE" || echo 0)" "0"
: > "$STORE"
env -u CLAUDE_SESSION_ID HOOK_TEST_RUN=run-1 WARN_LOG_STORE="$STORE" bash "$D/warn-log.sh" --hook a
check "a row names the test run that wrote it" "$(jq -r .test_run "$STORE")" "run-1"
HOOK_TEST=1 WARN_LOG_STORE="$STORE" bash "$D/warn-log.sh" --hook a --bogus x >/dev/null 2>&1
check "a bad flag still exits clean" "$?" "0"
: > "$STORE"
HOOK_TEST=1 WARN_LOG_STORE="$STORE" bash "$D/warn-log.sh"
check "no hook id writes nothing" "$(wc -l < "$STORE" | tr -d ' ')" "0"

trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
