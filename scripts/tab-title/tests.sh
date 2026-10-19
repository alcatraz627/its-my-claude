#!/usr/bin/env bash
# tests.sh — Self-tests for the tab-title CLI + lib. Uses a sandbox
# TAB_STATE_DIR so it does not touch a live Claude session's state.
#
# Run:  bash ~/.claude/scripts/tab-title/tests.sh

set -uo pipefail
ROOT="${BASH_SOURCE%/*}"
CLI="$ROOT/tab-title.sh"
LIB="$ROOT/lib.sh"

SANDBOX=$(mktemp -d)
export TAB_STATE_DIR="$SANDBOX"
trap 'trash "$SANDBOX" 2>/dev/null || rm -rf "$SANDBOX"' EXIT

PASS=0; FAIL=0
ok()   { printf '\033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '\033[31m✗\033[0m %s\n  expected: %s\n  got:      %s\n' "$1" "$2" "$3"; FAIL=$((FAIL+1)); }
eq()   { [[ "$2" == "$3" ]] && ok "$1" || bad "$1" "$2" "$3"; }
match(){ [[ "$3" == *"$2"* ]] && ok "$1" || bad "$1" "*$2*" "$3"; }

# Seed initial state via the library (mimics what the Stop hook does).
seed() {
  ( source "$LIB"
    STAR="$TAB_STAR"; BASE="$1"; FOCUS="${2:-}"; TRANSIENT_FOCUS=""; TRANSIENT_DEPTH=0
    tab_save_state sess-test
  )
}

# ── 1. help on bare invocation ───────────────────────────────────────────────
out=$(bash "$CLI" 2>&1)
match "bare invocation prints USAGE" "USAGE" "$out"
match "bare invocation lists 'check'" "check" "$out"
match "bare invocation shows examples" "EXAMPLES" "$out"
# Regression: backticks/$() inside the unquoted heredoc were being expanded
# by bash, throwing "syntax error" before any help text rendered.
if echo "$out" | grep -q "syntax error"; then
  bad "help heredoc has no shell-expansion errors" "no 'syntax error'" "found syntax error in help output"
else
  ok "help heredoc has no shell-expansion errors"
fi

# ── 2. show / get on fresh state ─────────────────────────────────────────────
seed "Hello world" ""
out=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" show)
eq "show composes star+base" "✻ Hello world" "$out"
eq "get base" "Hello world" "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get base)"
eq "get focus empty" ""             "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)"
eq "get depth = 0" "0"              "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get depth)"
eq "get session" "sess-test"        "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get session)"

# ── 3. set focus via shorthand ───────────────────────────────────────────────
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" focus "writing tests" >/dev/null
eq "focus shorthand sets value" "writing tests" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)"
eq "show reflects focus" "✻ Hello world [:writing tests]" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" show)"

# ── 4. focus --clear ─────────────────────────────────────────────────────────
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" focus --clear >/dev/null
eq "focus --clear empties focus" "" "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)"

# ── 5. multi-field set in one call ───────────────────────────────────────────
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" set "base=New base" "focus=multi-field" >/dev/null
eq "multi-set updates base"  "New base"    "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get base)"
eq "multi-set updates focus" "multi-field" "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)"

# ── 6. set focus= (empty value clears) ───────────────────────────────────────
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" set "focus=" >/dev/null
eq "set focus= clears focus" "" "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)"

# ── 7. check on clean state ──────────────────────────────────────────────────
out=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" check)
eq "check on clean state = ok" "ok" "$out"

# ── 8. check + fix on dirty state ────────────────────────────────────────────
# Hand-craft a corrupted state file to trip every validator branch.
cat > "$SANDBOX/claude-tab-state-sess-test" <<'EOF'
STAR=★
DECORATORS=
BASE=✻\ already\ starred\ \[:embedded\]
FOCUS=has]bracket
TRANSIENT_FOCUS=
TRANSIENT_DEPTH=oops
EOF
echo sess-test > "$SANDBOX/claude-tab-current"
out=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" check; true)
match "check flags non-canonical star"     "non-canonical STAR"  "$out"
match "check flags star inside base"       "BASE contains a star" "$out"
match "check flags embedded focus in base" "embedded [:focus]"    "$out"
match "check flags bracket in focus"       "bracket char"         "$out"
match "check flags bad depth"              "TRANSIENT_DEPTH"      "$out"

# Apply fix; recheck must be clean.
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" fix >/dev/null
out=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" check)
eq "post-fix check is clean" "ok" "$out"
eq "post-fix base is normalised" "already starred" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get base)"
eq "post-fix focus strips brackets but keeps manual" "hasbracket" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)"
eq "post-fix depth reset" "0" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get depth)"

# ── 8c. fix also clears stuck-high depth (drift from missed PostToolUse) ─────
cat > "$SANDBOX/claude-tab-state-sess-test" <<'EOF'
STAR=✻
DECORATORS=
BASE=Working
FOCUS=manual
TRANSIENT_FOCUS=stale\ watchdog
TRANSIENT_DEPTH=8
TTY_PATH=
EOF
echo sess-test > "$SANDBOX/claude-tab-current"
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" fix >/dev/null
eq "fix clears stuck-high depth"     "0"      "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get depth)"
eq "fix clears stale transient"      ""       "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get transient)"
eq "fix preserves manual focus"      "manual" "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)"

# 8b. embedded focus absorbed when manual focus is empty
cat > "$SANDBOX/claude-tab-state-sess-test" <<'EOF'
STAR=✻
DECORATORS=
BASE=titled\ \[:adopt-me\]
FOCUS=
TRANSIENT_FOCUS=
TRANSIENT_DEPTH=0
EOF
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" fix >/dev/null
eq "embedded focus adopted when manual empty" "adopt-me" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)"
eq "base normalised after adoption" "titled" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get base)"

# ── 9. transient focus wins over manual focus ────────────────────────────────
seed "Working" "manual"
( source "$LIB"
  tab_load_state sess-test
  TRANSIENT_FOCUS="running tests"; TRANSIENT_DEPTH=1
  tab_save_state sess-test
)
eq "transient wins in compose" "✻ Working [:running tests]" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" show)"

# ── 10. unknown command exits non-zero ───────────────────────────────────────
bash "$CLI" wat 2>/dev/null
rc=$?
[[ $rc -ne 0 ]] && ok "unknown command exits non-zero" || bad "unknown command exits non-zero" "rc!=0" "rc=$rc"

# ── 10b. state mutates even when /dev/tty is unavailable ────────────────────
# Bash-tool calls (setsid'd, no controlling tty) can't emit OSC visibly —
# tab_emit silently no-ops. But state file MUST still be updated, so the
# next hook firing (which has /dev/tty) emits the latest composed title.
# This test verifies the state-mutation-without-OSC contract.
cat > "$SANDBOX/claude-tab-state-novtty" <<'EOF'
STAR=✻
DECORATORS=
BASE=baseline
FOCUS=
TRANSIENT_FOCUS=
TRANSIENT_DEPTH=0
TTY_PATH=
EOF
echo novtty > "$SANDBOX/claude-tab-current"
CLAUDE_TAB_SESSION_ID=novtty bash "$CLI" focus "still updates state" >/dev/null
got_focus=$(CLAUDE_TAB_SESSION_ID=novtty bash "$CLI" get focus)
eq "state mutates even when OSC emission silently fails" "still updates state" "$got_focus"

# ── 12. status / mode / intent slots ─────────────────────────────────────────
seed "Slot test" ""
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" status ok    >/dev/null
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" mode  debug  >/dev/null
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" intent feature >/dev/null
eq "status field set"  "ok"      "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get status)"
eq "mode field set"    "debug"   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get mode)"
eq "intent field set"  "feature" "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get intent)"
got=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" show)
match "compose v3 left has mode glyph"    "🐛" "$got"
match "compose v3 left has intent glyph"  "✨" "$got"
match "compose v3 right has status glyph" "✅" "$got"
match "compose v3 separator (double-space)" "  " "$got"

# 12b. --clear empties the slot
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" status --clear >/dev/null
eq "status --clear" "" "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get status)"

# 12c. --list prints the enum table
out=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" mode --list)
match "mode --list has 'debug 🐛'"  "debug" "$out"
match "mode --list has 'test 🧪'"   "test"  "$out"
match "intent --list has 'feature'" "feature" "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" intent --list)"

# 12d. unknown name accepted (stored) but no glyph in compose
seed "Slot test" ""    # reset so prior intent/status doesn't leak in
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" mode flibbertigibbet 2>/dev/null >/dev/null
eq "unknown mode name still stored" "flibbertigibbet" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get mode)"
got=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" show)
eq "unknown mode produces no glyph in compose" "✻ Slot test" "$got"

# ── 13. glyph slot (perm/ssh) — named alias + raw emoji ──────────────────────
seed "Glyph test" ""
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" glyph perm robot >/dev/null
eq "glyph perm robot resolves to 🤖" "🤖" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get glyph_perm)"

# Raw emoji also accepted
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" glyph ssh 🐢 >/dev/null
eq "glyph ssh raw emoji" "🐢" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get glyph_ssh)"

# --options prints table
out=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" glyph perm --options)
match "glyph perm --options has 'robot'" "robot" "$out"
match "glyph perm --options has 'free'"  "free"  "$out"

# Unknown slot rejected
bash "$CLI" glyph unknownslot foo 2>/dev/null; rc=$?
[[ $rc -ne 0 ]] && ok "glyph unknown slot rejected" || bad "glyph unknown slot rejected" "rc!=0" "rc=$rc"

# --clear restores default
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" glyph perm --clear >/dev/null
eq "glyph perm --clear empties stored value" "" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get glyph_perm)"

# ── 14. v3 compose with no optional slots = just star + base ─────────────────
seed "Bare" ""
got=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" show)
eq "minimal compose is just star + base" "✻ Bare" "$got"

# ── 15. compose with status but no decorators ────────────────────────────────
seed "OnlyStatus" ""
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" status ok >/dev/null
got=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" show)
eq "status-only right strip has just status glyph" "✻ OnlyStatus  ✅" "$got"

# ── 16. all slots populated ─────────────────────────────────────────────────
seed "Full" "manual focus"
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" status warning >/dev/null
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" mode build    >/dev/null
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" intent refactor >/dev/null
got=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" show)
eq "full v3 compose" "✻ 🛠️ 🔄 Full [:manual focus]  ⚠️" "$got"

# ── 17a. auto-mode derivation in pre-tool hook ──────────────────────────────
# Simulate the hook's input contract and verify MODE gets set automatically.
seed "Auto-mode" ""
echo '{"session_id":"sess-test","tool_name":"Bash","tool_input":{"description":"smoke","command":"npm test"}}' \
  | TAB_STATE_DIR="$SANDBOX" CLAUDE_TAB_SESSION_ID=sess-test \
    bash ~/.claude/scripts/tab-title/hooks/pre-tool.sh >/dev/null 2>&1
eq "pre-tool derives mode=test from 'npm test'" "test" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get mode)"

echo '{"session_id":"sess-test","tool_name":"Bash","tool_input":{"description":"build","command":"npm run build"}}' \
  | TAB_STATE_DIR="$SANDBOX" CLAUDE_TAB_SESSION_ID=sess-test \
    bash ~/.claude/scripts/tab-title/hooks/pre-tool.sh >/dev/null 2>&1
eq "pre-tool re-derives mode=build" "build" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get mode)"

echo '{"session_id":"sess-test","tool_name":"Glob","tool_input":{}}' \
  | TAB_STATE_DIR="$SANDBOX" CLAUDE_TAB_SESSION_ID=sess-test \
    bash ~/.claude/scripts/tab-title/hooks/pre-tool.sh >/dev/null 2>&1
eq "pre-tool derives mode=search from Glob" "search" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get mode)"

# ── 17b. Stop hook smoke test (synthetic payload) ────────────────────────────
seed "Stop-hook test" "before"
echo '{"session_id":"sess-test","transcript_path":"","cwd":"/tmp","permission_mode":"acceptEdits"}' \
  | TAB_STATE_DIR="$SANDBOX" \
    bash ~/.claude/scripts/update-tab-title.sh >/dev/null 2>&1
# Stop hook should auto-heal transient + depth
eq "stop hook clears transient" "" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get transient)"
eq "stop hook resets depth"     "0" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get depth)"
# Preserves the manual focus
eq "stop hook preserves manual focus" "before" \
   "$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)"

# ── 17. focus rejects bracket chars via fix ─────────────────────────────────
# Programmatic abuse: someone sets focus with []s → fix strips them
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" set "focus=oh [no] brackets" >/dev/null
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" fix >/dev/null
got=$(CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get focus)
eq "fix strips brackets from focus" "oh no brackets" "$got"

# ── 11. no-session path is non-blocking ──────────────────────────────────────
trash "$SANDBOX/claude-tab-current" 2>/dev/null || rm -f "$SANDBOX/claude-tab-current"
unset CLAUDE_TAB_SESSION_ID
bash "$CLI" focus "should-noop" >/dev/null 2>&1
rc=$?
[[ $rc -eq 0 ]] && ok "no-session focus exits 0 (non-blocking)" \
                 || bad "no-session focus exits 0" "rc=0" "rc=$rc"

# ── 18. hands-off derivation: matchers, base, status, intent, focus ─────────
HOOKS="$ROOT/hooks"
run_hook() { # run_hook <script> <json>
  echo "$2" | TAB_STATE_DIR="$SANDBOX" TAB_TASK_STORE="${TAB_TASK_STORE:-}" bash "$HOOKS/$1" >/dev/null 2>&1
}
getf() { CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" get "$1"; }
SETTINGS="${SETTINGS_JSON:-$HOME/.claude/settings.json}"

# 18a. both tab-title hooks listen to the file and task tools, still async
for ev_script in "PreToolUse pre-tool.sh" "PostToolUse post-tool.sh"; do
  set -- $ev_script
  m=$(jq -r --arg e "$1" --arg s "$2" '.hooks[$e][] | select(any(.hooks[]; .command | endswith("tab-title/hooks/" + $s))) | .matcher' "$SETTINGS")
  a=$(jq -r --arg e "$1" --arg s "$2" '.hooks[$e][] | select(any(.hooks[]; .command | endswith("tab-title/hooks/" + $s))) | .hooks[0].async' "$SETTINGS")
  all=1; for t in Read Write Edit MultiEdit Glob Grep TaskCreate TaskUpdate; do [[ "$m" == *"$t"* ]] || all=0; done
  [[ $all == 1 ]] && ok "$2 matcher covers file and task tools" || bad "$2 matcher covers file and task tools" "all of Read..TaskUpdate" "$m"
  eq "$2 stays async" "true" "$a"
done

# 18b. the Stop hook keeps a stored base but recomputes its own
trash "$SANDBOX"/claude-tab-auto-* 2>/dev/null
seed "My stored title" ""
echo '{"session_id":"sess-test","transcript_path":"","cwd":"/tmp"}' | TAB_STATE_DIR="$SANDBOX" bash ~/.claude/scripts/update-tab-title.sh >/dev/null 2>&1
eq "stop keeps a stored base" "My stored title" "$(getf base)"
seed "Am❓ stale" ""
echo '{"session_id":"sess-test","transcript_path":"","cwd":"/tmp"}' | TAB_STATE_DIR="$SANDBOX" bash ~/.claude/scripts/update-tab-title.sh >/dev/null 2>&1
eq "stop recomputes an auto base" "Am❓ tmp" "$(getf base)"
echo '{"session_id":"sess-test","transcript_path":"","cwd":"/var"}' | TAB_STATE_DIR="$SANDBOX" bash ~/.claude/scripts/update-tab-title.sh >/dev/null 2>&1
eq "stop keeps refreshing its own auto base" "Am❓ var" "$(getf base)"

# 18c. status from a test/build exit code (PostToolUse), hand-set status untouched
trash "$SANDBOX"/claude-tab-auto-* 2>/dev/null
seed "Status test" ""
run_hook post-tool.sh '{"session_id":"sess-test","tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"exit_code":1}}'
eq "failing test command sets status=error" "error" "$(getf status)"
run_hook post-tool.sh '{"session_id":"sess-test","tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"exit_code":0}}'
eq "later passing test command sets status=ok" "ok" "$(getf status)"
run_hook post-tool.sh '{"session_id":"sess-test","tool_name":"Bash","tool_input":{"command":"ls nope"},"tool_response":{"exit_code":2}}'
eq "a non-test failure leaves status alone" "ok" "$(getf status)"
run_hook post-tool.sh '{"session_id":"sess-test","tool_name":"Bash","tool_input":{"command":"pytest -q"},"error":"Exit code 1\nFAILED"}'
eq "an 'Exit code N' error string counts" "error" "$(getf status)"
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" status blocked >/dev/null
run_hook post-tool.sh '{"session_id":"sess-test","tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"exit_code":0}}'
eq "a status the agent set by hand is not overwritten" "blocked" "$(getf status)"

# 18d. status at Stop, from the transcript of the turn
mk_tx() { # mk_tx <file> <cmd> <is_error true|false> [extra tool name]
  local f="$1" cmd="$2" err="$3" extra="${4:-}"
  {
    echo '{"type":"user","message":{"role":"user","content":"please do it"}}'
    jq -nc --arg c "$cmd" '{type:"assistant",message:{role:"assistant",content:[{type:"tool_use",id:"t1",name:"Bash",input:{command:$c}}]}}'
    jq -nc --argjson e "$err" '{type:"user",message:{role:"user",content:[{type:"tool_result",tool_use_id:"t1",is_error:$e,content:"out"}]}}'
    [[ -n "$extra" ]] && jq -nc --arg n "$extra" '{type:"assistant",message:{role:"assistant",content:[{type:"tool_use",id:"t2",name:$n,input:{}}]}}'
  } > "$f"
}
stop_status() { # stop_status <transcript> -> status after a Stop with an empty status
  seed "Stop status" ""
  trash "$SANDBOX"/claude-tab-auto-* 2>/dev/null
  echo "{\"session_id\":\"sess-test\",\"transcript_path\":\"$1\",\"cwd\":\"/tmp\"}" | TAB_STATE_DIR="$SANDBOX" bash ~/.claude/scripts/update-tab-title.sh >/dev/null 2>&1
  getf status
}
mk_tx "$SANDBOX/tx-ok.jsonl" "npm test" false;               eq "stop: passing test turn -> ok" "ok" "$(stop_status "$SANDBOX/tx-ok.jsonl")"
mk_tx "$SANDBOX/tx-err.jsonl" "npm test" true;               eq "stop: failing test turn -> error" "error" "$(stop_status "$SANDBOX/tx-err.jsonl")"
mk_tx "$SANDBOX/tx-warn.jsonl" "ls nope" true;               eq "stop: other failure -> warning" "warning" "$(stop_status "$SANDBOX/tx-warn.jsonl")"
mk_tx "$SANDBOX/tx-blk.jsonl" "ls" false AskUserQuestion;    eq "stop: ended on a question -> blocked" "blocked" "$(stop_status "$SANDBOX/tx-blk.jsonl")"
mk_tx "$SANDBOX/tx-quiet.jsonl" "ls" false;                  eq "stop: quiet turn -> no status" "" "$(stop_status "$SANDBOX/tx-quiet.jsonl")"

# 18e. intent once per session from the first real prompt (BASE seeded so the q path stays off)
intent_run() { # intent_run <prompt> [cwd]
  echo "{\"session_id\":\"sess-test\",\"prompt\":$(jq -Rn --arg p "$1" '$p'),\"cwd\":\"${2:-/tmp}\"}" \
    | TAB_STATE_DIR="$SANDBOX" bash "$HOOKS/auto-base.sh" >/dev/null 2>&1
}
reset_intent() { seed "Intent test" ""; trash "$SANDBOX/claude-tab-intent-done-sess-test" 2>/dev/null; }
reset_intent; intent_run "please fix the login bug on the settings page"
eq "intent: 'fix ... bug' -> bugfix" "bugfix" "$(getf intent)"
intent_run "now refactor the whole thing into modules"
eq "intent: set once, a later prompt does not change it" "bugfix" "$(getf intent)"
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" intent --clear >/dev/null
intent_run "now refactor the whole thing into modules"
eq "intent: derived only once per session, not re-derived when cleared" "" "$(getf intent)"
reset_intent; intent_run "/catchup"
eq "intent: a slash command is not a real prompt" "" "$(getf intent)"
intent_run "write up the design notes for the new page"
eq "intent: the next real prompt still counts (docs before design)" "docs" "$(getf intent)"
reset_intent; intent_run "study how the scheduler decides things"
eq "intent: study -> research" "research" "$(getf intent)"
reset_intent
GITD="$SANDBOX/repo"; mkdir -p "$GITD"; git -C "$GITD" init -q -b feat/new-thing 2>/dev/null
intent_run "carry on with the next piece of work please" "$GITD"
eq "intent: no keyword -> branch prefix feat/ -> feature" "feature" "$(getf intent)"
reset_intent; CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" intent security >/dev/null; trash "$SANDBOX/claude-tab-intent-done-sess-test" 2>/dev/null
intent_run "please fix the login bug on the settings page"
eq "intent: an agent-set intent is never replaced" "security" "$(getf intent)"

# 18f. focus from the Task list's in_progress row, cut to three words
TS="$SANDBOX/taskstore"; mkdir -p "$TS"
printf '{"id":"1","subject":"Wire the plan gate into settings now","status":"in_progress"}' > "$TS/1.json"
printf '{"id":"2","subject":"Other pending work","status":"pending"}' > "$TS/2.json"
seed "Focus test" ""; trash "$SANDBOX"/claude-tab-auto-* 2>/dev/null
TAB_TASK_STORE="$TS" run_hook post-tool.sh '{"session_id":"sess-test","tool_name":"TaskUpdate","tool_input":{}}'
eq "focus: in_progress subject cut to three words" "Wire the plan" "$(getf focus)"
printf '{"id":"1","subject":"Wire the plan gate into settings now","status":"completed"}' > "$TS/1.json"
TAB_TASK_STORE="$TS" run_hook post-tool.sh '{"session_id":"sess-test","tool_name":"TaskUpdate","tool_input":{}}'
eq "focus: cleared when nothing is in progress" "" "$(getf focus)"
CLAUDE_TAB_SESSION_ID=sess-test bash "$CLI" focus "my own focus" >/dev/null
printf '{"id":"1","subject":"Wire the plan gate into settings now","status":"in_progress"}' > "$TS/1.json"
TAB_TASK_STORE="$TS" run_hook post-tool.sh '{"session_id":"sess-test","tool_name":"TaskUpdate","tool_input":{}}'
eq "focus: a hand-set focus is not overwritten" "my own focus" "$(getf focus)"
# the file and task tools now reach pre-tool.sh's mode derivation
seed "Mode test" ""
run_hook pre-tool.sh '{"session_id":"sess-test","tool_name":"MultiEdit","tool_input":{}}'
eq "pre-tool derives mode=edit from MultiEdit" "edit" "$(getf mode)"

# ── Summary ──────────────────────────────────────────────────────────────────
echo
echo "── $((PASS+FAIL)) tests: $PASS passed, $FAIL failed ──"
exit $FAIL
