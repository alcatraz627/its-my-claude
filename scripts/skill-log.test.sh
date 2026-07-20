#!/usr/bin/env bash
# skill-log.test.sh — runnable checks for skill-log.sh.
# Isolation: SKILL_LOG_EVENTS redirects the stream so the live log is never touched.
# Run: bash ~/.claude/scripts/skill-log.test.sh   (exit 0 = all pass)

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SL="$HERE/skill-log.sh"

STORE="$(mktemp "${TMPDIR:-/tmp}/skl-XXXXXX")"; rm -f "$STORE"
export SKILL_LOG_EVENTS="$STORE"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }
last(){ tail -1 "$STORE" 2>/dev/null; }

echo "── record writes a well-formed event (positive read, not just 'a line appeared') ──"
id=$(bash "$SL" record bloop --outcome accepted --loop converged --iterations 1 --corrections 0 --gate pass --note "clean run")
ok "record prints an id"          "$(printf '%s' "$id" | grep -c '^skl-')"        1
ok "event is valid json"          "$(last | jq -e . >/dev/null 2>&1 && echo ok)"   ok
ok "skill field correct"          "$(last | jq -r .skill)"                         bloop
ok "outcome field correct"        "$(last | jq -r .outcome)"                       accepted
ok "gate field correct"           "$(last | jq -r .gate)"                          pass
ok "iterations is a NUMBER not string" "$(last | jq -r '.iterations|type')"        number
ok "corrections=0 is preserved"   "$(last | jq -r '.corrections')"                 0

echo "── --metrics accepts a json blob (deadline case) ──"
bash "$SL" record deadline --outcome accepted --metrics '{"turns_planned":4,"turns_used":3,"hit":true}' >/dev/null
ok "metrics parsed as object"     "$(last | jq -r '.metrics.turns_used')"          3
ok "metrics.hit bool preserved"   "$(last | jq -r '.metrics.hit')"                 true

echo "── malformed input never crashes the record (never-break) ──"
bash "$SL" record deadline --corrections "oops" --metrics 'not json' >/dev/null 2>&1
ok "bad corrections -> null, still valid" "$(last | jq -e 'has("corrections")|not' >/dev/null 2>&1 && echo dropped)"  dropped
ok "bad metrics -> null, still valid"     "$(last | jq -e 'has("metrics")|not' >/dev/null 2>&1 && echo dropped)"      dropped
ok "record still emits valid json"        "$(last | jq -e . >/dev/null 2>&1 && echo ok)"                              ok

echo "── empty fields are dropped, not written as empty strings ──"
bash "$SL" record svg >/dev/null
ok "no empty task key"            "$(last | jq -e 'has("task")|not' >/dev/null 2>&1 && echo clean)"  clean

echo "── summary aggregates the proxies (a READER can consume it) ──"
out=$(bash "$SL" summary --skill bloop 2>/dev/null)
ok "summary names the skill"      "$(printf '%s' "$out" | grep -c 'bloop')"         1
ok "summary shows outcome row"    "$(printf '%s' "$out" | grep -c 'outcome:')"      1
ok "summary shows gate row"       "$(printf '%s' "$out" | grep -c 'gate:')"         1

echo "── list shows recent events ──"
# two deadline records above: the --metrics json case and the malformed-input case.
ok "list has both deadline rows"  "$(bash "$SL" list --skill deadline 2>/dev/null | grep -c deadline)"  2

echo "── missing skill arg is rejected ──"
bash "$SL" record >/dev/null 2>&1; ok "record with no skill exits nonzero" "$?" 2

echo "── F3: a dangling flag fails clean (exit 2), never crashes on unbound \$2 ──"
bash "$SL" record edge --task >/dev/null 2>&1; ok "dangling --task -> exit 2"    "$?" 2
bash "$SL" record edge --metrics >/dev/null 2>&1; ok "dangling --metrics -> exit 2" "$?" 2
err=$(bash "$SL" record edge --task 2>&1 >/dev/null)
ok "dangling flag prints a clean message, not 'unbound variable'" \
   "$(printf '%s' "$err" | grep -c 'unbound variable')" 0

echo "── F1: a stale lock (crashed writer) is reclaimed, record still lands ──"
: > "$STORE"
mkdir -p "${STORE}.lock"                       # simulate a crashed holder
# backdate the lock dir past the 30s staleness window
touch -t "$(date -v-2M +%Y%m%d%H%M 2>/dev/null || date -d '2 min ago' +%Y%m%d%H%M)" "${STORE}.lock" 2>/dev/null || true
id=$(bash "$SL" record bloop --outcome accepted 2>/dev/null)
ok "record succeeds despite a stale lock"  "$(printf '%s' "$id" | grep -c '^skl-')"  1
ok "the stale lock was released after"     "$([ -d "${STORE}.lock" ] && echo held || echo freed)"  freed
rmdir "${STORE}.lock" 2>/dev/null || true

rm -f "$STORE"
echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
