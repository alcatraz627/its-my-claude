#!/usr/bin/env bash
# no-task-nudge.test.sh — the todo-discipline nudge must only speak when it can see.
#
# What this protects, in human terms: the nudge tells an agent "you have done real
# work and kept no todo list". That is useful when true and corrosive when false —
# a hook that lies teaches you to ignore hooks. It has been false twice, both times
# because it asked a question it could not actually answer:
#
#   1. It counted tasks under tasks/<full-uuid>/ after the store had moved to
#      tasks/session-<sid8>/, so the count was 0 for every session (d424d4d).
#   2. The store reaps a task's json on completion, so a session that finished its
#      list looks identical to one that never made it (2fae480).
#
# And it cannot see at all after a /clear: the store stays keyed to the pre-clear
# session id, while this hook is handed the new one. So the third rule is silence.
#
# Every case below is a shape that actually occurred. Run after touching the hook:
#   bash ~/.claude/scripts/hooks/no-task-nudge.test.sh

set -uo pipefail
HOOK="${HOOK_UNDER_TEST:-$(dirname "$0")/no-task-nudge.sh}"
SID="aaaabbbb-1111-2222-3333-444455556666"
SID8="${SID:0:8}"

PASS=0; FAIL=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

# Fire the hook against a throwaway HOME.
#   $1 label · $2 task dir name ("" = none) · $3 n task json · $4 highwatermark ("" = none)
#   $5 "clear" to simulate a post-/clear session
# The tool-counter tally is PPID-keyed, so the same shell that writes it must be the
# hook's parent. Getting that wrong makes the hook exit early and EVERY case read as
# quiet — a probe that cannot fail is worse than no probe.
fire() {
  local dirname="$2" ntasks="$3" hw="$4" clear="${5:-}"
  local T; T=$(mktemp -d)
  if [ -n "$dirname" ]; then
    mkdir -p "$T/.claude/tasks/$dirname"
    # Guard on >0 before seq: BSD seq counts DOWN when the end is below the start,
    # so `seq 1 0` yields "1 0" rather than nothing, and the zero-task fixture
    # silently gained two task files. That made the reaped case pass through the
    # "it has tasks" branch and left the highwatermark guard never exercised —
    # a fixture that cannot express the state it claims to test.
    if [ "${ntasks:-0}" -gt 0 ]; then
      for n in $(seq 1 "$ntasks"); do
        printf '{"id":"%s"}' "$n" > "$T/.claude/tasks/$dirname/$n.json"
      done
    fi
    [ -n "$hw" ] && printf '%s' "$hw" > "$T/.claude/tasks/$dirname/.highwatermark"
  fi
  rm -f "/tmp/claude-notask-nudged-${SID8}" "/tmp/claude-clear-reset-${SID8}"
  [ "$clear" = "clear" ] && touch "/tmp/claude-clear-reset-${SID8}"

  local out
  out=$(env HOME="$T" bash -c '
      printf "E=8\nW=5\n" > "/tmp/claude-tools-$$"
      printf "{\"session_id\":\"'"$SID"'\"}" | bash "'"$HOOK"'" 2>/dev/null
      rm -f "/tmp/claude-tools-$$"')
  [ -n "${NTN_DEBUG:-}" ] && printf '    [dbg] %s: fixture=[%s] outlen=%s\n' \
    "$1" "$(ls -A "$T/.claude/tasks/$dirname" 2>/dev/null | tr '\n' ',')" "${#out}" >&2
  rm -rf "$T" "/tmp/claude-notask-nudged-${SID8}" "/tmp/claude-clear-reset-${SID8}"
  printf '%s' "$out"
}

nudged() { printf '%s' "$1" | rg -q 'todo-discipline'; }

echo "== it SHOULD nudge: real work, no list ever kept =="
o=$(fire "no dir" "" 0 "")
nudged "$o" && ok "no task dir at all -> nudges" || bad "stayed silent when it should nudge"

echo
echo "== it should stay quiet: a list exists =="
o=$(fire "current shape" "session-$SID8" 3 "3")
nudged "$o" && bad "nudged a session holding 3 live tasks" || ok "live tasks (session-<sid8>) -> quiet"
o=$(fire "legacy shape" "$SID" 3 "3")
nudged "$o" && bad "nudged a session holding 3 tasks in the legacy dir" || ok "live tasks (legacy <uuid>) -> quiet"

echo
echo "== it should stay quiet: the list was kept AND finished (json reaped) =="
o=$(fire "reaped" "session-$SID8" 0 "20")
nudged "$o" && bad "nagged the session that completed all 20 of its tasks" || ok "reaped list (hw=20, 0 json) -> quiet"

echo
echo "== it must stay quiet after a /clear: it cannot see the store at all =="
# The store keeps the pre-clear id; this hook gets the new one and can never map
# between them. Its count is meaningless here, so it must not speak.
o=$(fire "post-clear, no dir" "" 0 "" clear)
nudged "$o" && bad "asserted an empty list while blind (post-/clear)" || ok "post-/clear -> silent, not guessing"

echo
printf 'passed %d, failed %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
