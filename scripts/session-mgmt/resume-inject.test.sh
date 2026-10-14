#!/usr/bin/env bash
# Checks the resume injector against a sandbox home: fake checkpoints, a fake
# index, fake sessions/<pid>.json files and a fixed clock, fed the SessionStart
# payloads for clear, startup, resume and compact.
# Run: bash ~/.claude/scripts/session-mgmt/resume-inject.test.sh
set -uo pipefail

INJ="${RESUME_INJECT_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/resume-inject.sh}"
pass=0; fail=0
ok()  { echo "  ok    $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }

T=$(mktemp -d /tmp/resume-inject-test.XXXXXX)
trap 'trash "$T" 2>/dev/null || true' EXIT
NOW=1790000000
PID=4242
PROJ="$T/proj"
OTHER="$T/other"
OLD_SID="11111111-aaaa-4bbb-8ccc-000000000001"   # the session before the /clear
NEW_SID="22222222-aaaa-4bbb-8ccc-000000000002"   # the session after it
PEER_SID="33333333-aaaa-4bbb-8ccc-000000000003"  # another tab in the same folder

iso() { date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ; }

# A fresh sandbox per case: home, index, sessions dir and state dir.
reset() {
  [ -d "$T/home" ] && trash "$T/home"
  mkdir -p "$T/home/.claude/checkpoints" "$T/home/.claude/sessions" "$T/home/.claude/state" "$PROJ" "$OTHER"
  : > "$T/home/.claude/checkpoints/index.jsonl"
  # The Claude process started an hour before NOW.
  printf '{"pid":%s,"sessionId":"%s","startedAt":%s000}\n' "$PID" "$NEW_SID" "$((NOW - 3600))" > "$T/home/.claude/sessions/$PID.json"
}

# ckpt <file> <session uuid> <age seconds> [kind] [project]
ckpt() {
  local f="$1" uuid="$2" age="$3" kind="${4:-core-dump}" proj="${5:-$PROJ}"
  printf '# Quick Summary (for LLMs), x\n\n> SUMMARY-OF-%s\n\n# Core Dump, x\n\n## Resume Contract\n\n- **Next action:** CONTRACT-OF-%s\n\n## Initial Goal\n\nGOAL-BODY-SHOULD-NOT-APPEAR\n' "$uuid" "$uuid" > "$proj/$f"
  printf '{"ts":"%s","session_id":"friendly-%s","session_uuid":"%s","project_root":"%s","checkpoint_path":"%s","name":"%s","kind":"%s"}\n' \
    "$(iso $((NOW - age)))" "${uuid:0:4}" "$uuid" "$proj" "$proj/$f" "${f%.claude.md}" "$kind" >> "$T/home/.claude/checkpoints/index.jsonl"
}

# The ledger row the injector itself writes when the earlier session started.
started() { mkdir -p "$T/home/.claude/state/resume-inject"; printf '%s %s\n' "$1" "$2" >> "$T/home/.claude/state/resume-inject/pid-$PID.log"; }

# run <source> <session id> [cwd] [extra json] ; the env carries the sandbox.
run() {
  local extra="${4:-}"
  printf '{"session_id":"%s","cwd":"%s","source":"%s","hook_event_name":"SessionStart"%s}' "$2" "${3:-$PROJ}" "$1" "$extra" |
    HOME="$T/home" RESUME_INJECT_NOW="$NOW" RESUME_INJECT_CLAUDE_PID="$PID" bash "$INJ" 2>/dev/null
}
ctx() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null; }
has() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }

echo "clear"
reset; started "$OLD_SID" $((NOW - 1800)); ckpt _a.claude.md "$OLD_SID" 300
c=$(ctx "$(run clear "$NEW_SID")")
has "$c" "SUMMARY-OF-$OLD_SID" && ok "same window, fresh dump: injects the Quick Summary" || bad "no summary: '$c'"
has "$c" "CONTRACT-OF-$OLD_SID" && ok "and the Resume Contract" || bad "no contract: '$c'"
has "$c" "GOAL-BODY-SHOULD-NOT-APPEAR" && bad "leaked a section past the contract" || ok "stops at the next section"
has "$c" "do not run goal.sh set or gs link" && ok "offers the goal, never arms it" || bad "no goal guard: '$c'"
has "$c" "/catchup $PROJ/_a.claude.md" && ok "names /catchup for the full resume" || bad "no catchup line"

reset; started "$OLD_SID" $((NOW - 3000)); ckpt _a.claude.md "$OLD_SID" 2700
[ -z "$(run clear "$NEW_SID")" ] && ok "a dump older than the 30 minute window: nothing" || bad "injected a stale dump"

reset; started "$OLD_SID" $((NOW - 1800)); ckpt _p.claude.md "$PEER_SID" 120
[ -z "$(run clear "$NEW_SID")" ] && ok "a fresh dump by another tab in the same folder: nothing" || bad "injected a peer's dump"

reset; ckpt _a.claude.md "$OLD_SID" 300
[ -z "$(run clear "$NEW_SID")" ] && ok "no earlier session recorded for this process: nothing" || bad "injected without a same-process link"

reset; started "$OLD_SID" $((NOW - 7200 * 24)); ckpt _a.claude.md "$OLD_SID" 300
[ -z "$(run clear "$NEW_SID")" ] && ok "a ledger row older than the process (recycled pid): nothing" || bad "trusted a recycled pid"

reset; started "$OLD_SID" $((NOW - 1800)); ckpt _pc.claude.md "$OLD_SID" 60 precompact
[ -z "$(run clear "$NEW_SID")" ] && ok "a shell-only precompact snapshot is never injected" || bad "injected a precompact snapshot"

# Without the override the injector walks its own parents for sessions/<pid>.json:
# this test shell is one of them.
reset; started "$OLD_SID" $((NOW - 1800)); ckpt _a.claude.md "$OLD_SID" 300
mv -f "$T/home/.claude/state/resume-inject/pid-$PID.log" "$T/home/.claude/state/resume-inject/pid-$$.log"
printf '{"pid":%s,"startedAt":%s000}\n' "$$" "$((NOW - 3600))" > "$T/home/.claude/sessions/$$.json"
c=$(printf '{"session_id":"%s","cwd":"%s","source":"clear"}' "$NEW_SID" "$PROJ" | HOME="$T/home" RESUME_INJECT_NOW="$NOW" bash "$INJ" 2>/dev/null)
has "$(ctx "$c")" "SUMMARY-OF-$OLD_SID" && ok "finds the Claude process by walking up the parents" || bad "parent walk failed: '$c'"

echo "startup"
reset; ckpt _s.claude.md "$OLD_SID" 7200
c=$(ctx "$(run startup "$NEW_SID")")
has "$c" "/catchup $PROJ/_s.claude.md" && ok "offers the newest unresumed checkpoint for this folder" || bad "no offer: '$c'"
[ "$(printf '%s\n' "$c" | wc -l | tr -d ' ')" = 1 ] && ok "in one line" || bad "offer is not one line"
has "$c" "SUMMARY-OF" && bad "startup injected the checkpoint body" || ok "and never the body"
[ -z "$(run startup "$PEER_SID")" ] && ok "a second startup does not offer it again" || bad "re-offered"

reset; ckpt _s.claude.md "$OLD_SID" $((30 * 3600))
[ -z "$(run startup "$NEW_SID")" ] && ok "older than STARTUP_MAX_AGE_HOURS (24): nothing" || bad "offered a day-old dump"

reset; ckpt _s.claude.md "$OLD_SID" 7200
printf 'STARTUP_MAX_AGE_HOURS=1\n' > "$T/home/.claude/state/resume-inject.conf"
[ -z "$(run startup "$NEW_SID")" ] && ok "the owner's max age in resume-inject.conf is honoured" || bad "conf max age ignored"

reset; ckpt _s.claude.md "$OLD_SID" 600
printf 'STARTUP_OFFER=off\n' > "$T/home/.claude/state/resume-inject.conf"
[ -z "$(run startup "$NEW_SID")" ] && ok "STARTUP_OFFER=off silences the offer" || bad "offer not switchable"

reset; ckpt _o.claude.md "$OLD_SID" 600 core-dump "$OTHER"
[ -z "$(run startup "$NEW_SID")" ] && ok "a checkpoint from another folder: nothing" || bad "offered another folder's dump"

reset; started "$OLD_SID" $((NOW - 1800)); ckpt _a.claude.md "$OLD_SID" 300
run clear "$NEW_SID" >/dev/null
[ -z "$(run startup "$PEER_SID")" ] && ok "a checkpoint already injected after a clear is not offered at startup" || bad "offered an injected dump"

echo "resume, compact, subagent, mute"
reset; started "$OLD_SID" $((NOW - 1800)); ckpt _a.claude.md "$OLD_SID" 300
[ -z "$(run resume "$NEW_SID")" ] && ok "resume: nothing" || bad "resume injected"
[ -z "$(run compact "$NEW_SID")" ] && ok "compact: nothing" || bad "compact injected"
[ -z "$(run fork "$NEW_SID")" ] && ok "fork: nothing" || bad "fork injected"
[ -z "$(run clear "$NEW_SID" "$PROJ" ',"agent_id":"ag-1"')" ] && ok "a subagent's SessionStart: nothing" || bad "subagent injected"
touch "$T/home/.claude/.no-resume-inject"
[ -z "$(run clear "$NEW_SID")" ] && ok "the mute file silences it" || bad "mute ignored"

echo "---- pass=$pass fail=$fail ----"
[ $fail -eq 0 ]
