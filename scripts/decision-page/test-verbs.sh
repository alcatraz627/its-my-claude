#!/usr/bin/env bash
# Smoke test for the decision-page verbs (compose, parse, reach, submit, seen)
# and the server routes that use the same composer. Builds a scratch page with
# no origin, so a submit's wake fails without sending any ipc mail, and removes
# the page at the end. Needs the kanban server on :5106.
#   bash ~/.claude/scripts/decision-page/test-verbs.sh
set -uo pipefail

DP="$HOME/.claude/scripts/decision-page/decision-page.sh"
WZ="$HOME/.claude/scripts/decision-page/wizard.sh"
REG="$HOME/.claude/assets/decision-pages"
S="http://127.0.0.1:5106"
SLUG="zz-verbs-smoke"
PAGE="$REG/$SLUG"
pass=0; fail=0
ok() { pass=$((pass+1)); printf 'ok   %s\n' "$1"; }
no() { fail=$((fail+1)); printf 'FAIL %s\n     %s\n' "$1" "$2"; }
eq() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1" "want: $(printf '%q' "$3")  got: $(printf '%q' "$2")"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1" "missing '$3' in: $2" ;; esac; }

cleanup() {
  [ -d "$PAGE" ] && trash "$PAGE" >/dev/null 2>&1
  bash "$DP" pending clear "$SLUG" >/dev/null 2>&1
}
trap cleanup EXIT
[ -e "$PAGE" ] && { echo "refusing: $PAGE exists and this run did not make it" >&2; exit 2; }
mkdir -p "$PAGE"
cat > "$PAGE/config.json" <<'JSON'
{ "title": "Verbs smoke", "decisions": [
    { "id": "D1", "note": "seed", "options": [ { "code": "a", "rec": true }, { "code": "b" } ] },
    { "id": "D2", "none": true, "options": [ { "code": "a", "rec": true } ] } ],
  "sections": [ { "id": "S1" } ] }
JSON
FRESH=$'Verbs smoke:\nD1a D2a\nD1 note — seed'
FLIPPED=$'Verbs smoke:\nD1b D2z\nS1: DISAGREE — no\nnotes:\nend'
STATE='{"d":{"D1":"b","D2":"z"},"dnotes":{"D1":""},"screens":{"S1":{"agree":false,"note":"no"}},"endnotes":"end"}'

eq "compose: the page as drawn" "$(bash "$DP" compose "$SLUG" </dev/null)" "$FRESH"
eq "compose: picks, a cleared seed, a section note and end notes" "$(printf '%s' "$STATE" | bash "$DP" compose "$SLUG")" "$FLIPPED"
eq "compose: from an empty environment" "$(env -i /bin/bash "$DP" compose "$SLUG" </dev/null)" "$FRESH"
eq "parse then compose returns the same answer" \
  "$(printf '%s' "$FLIPPED" | bash "$DP" parse "$SLUG" | bash "$DP" compose "$SLUG")" "$FLIPPED"

eq "route: dp-compose matches the command" \
  "$(curl -s -X POST "$S/api/dp-compose/$SLUG" -H 'content-type: application/json' -d "{\"state\":$STATE}" | python3 -c 'import json,sys;print(json.load(sys.stdin)["answer"])')" "$FLIPPED"
has "route: dp-parse returns the picks" \
  "$(curl -s -X POST "$S/api/dp-parse/$SLUG" -H 'content-type: application/json' -d "$(python3 -c 'import json,sys;print(json.dumps({"answer":sys.argv[1]}))' "$FLIPPED")")" '"D2":"z"'
eq "route: dp-compose on an unknown page is 404" \
  "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$S/api/dp-compose/zz-no-such-page" -d '{}')" "404"

bash "$DP" pending add "$SLUG" >/dev/null
has "reach: one call covers every pending page" "$(bash "$DP" reach)" "\"$SLUG\":\"unknown\""

eq "wizard --dry-run without a tty composes the recommended answer" "$(bash "$WZ" "$SLUG" --dry-run </dev/null 2>/dev/null)" "$FRESH"

out=$(printf '%s' "$FLIPPED" | bash "$DP" submit "$SLUG"); rc=$?
eq "submit: exit 0" "$rc" "0"
has "submit: reports the failed wake" "$out" '"state":"no-origin"'
eq "submit: wrote the answer" "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["answer"])' "$PAGE/.answer.json")" "$FLIPPED"
has "submit: a failed wake leaves the page pending" "$(bash "$DP" pending list)" "$SLUG"
printf '%s' "$FRESH" | bash "$DP" submit "$SLUG" >/dev/null; rc=$?
eq "submit again without --replace: exit 3, nothing replaced" "$rc" "3"
printf '%s' "$FRESH" | bash "$DP" submit "$SLUG" --replace >/dev/null; rc=$?
eq "submit --replace: exit 0" "$rc" "0"

before=$(wc -l < "$REG/answers.jsonl" 2>/dev/null || echo 0)
bash "$DP" answer "$SLUG" >/dev/null
case "$(bash "$DP" pending list)" in *"$SLUG"*) no "answer: clears the pending page" "still pending" ;; *) ok "answer: clears the pending page" ;; esac
eq "answer: appends one line to answers.jsonl" "$(( $(wc -l < "$REG/answers.jsonl") - before ))" "1"

has "seen: first open is recorded" "$(bash "$DP" seen "$SLUG")" '"already":false'
has "seen: a second open keeps the first time" "$(bash "$DP" seen "$SLUG")" '"already":true'

printf '%s' "x" | bash "$DP" submit zz-no-such-page >/dev/null 2>&1; rc=$?
eq "submit to an unknown page: exit 1" "$rc" "1"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
