#!/usr/bin/env bash
# Exercises quiz.py end to end on a small fixture doc: lint, render, grade,
# remap on change, retry and the held/shaky/missed map.
set -uo pipefail

Q="python3 $HOME/.claude/scripts/quiz/quiz.py"
T=$(mktemp -d)
export QUIZ_HOME="$T/quizzes"

pass=0 fail=0
check() {  # $1 name, $2 haystack, $3 needle
  if [[ "$2" == *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1"; echo "     want: $3"; echo "     got:  ${2:0:400}"; fi
}
absent() {  # $1 name, $2 haystack, $3 must-not-contain
  if [[ "$2" != *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1"; echo "     must not contain: $3"; fi
}

DOC="$T/spec.md"
cat > "$DOC" <<'EOF'
# Retry spec

## Backoff
Failed jobs retry three times with exponential backoff.
The first retry waits two seconds.

## Dead letter
After the last retry the job moves to the dead-letter queue.
EOF

D=$($Q init --artifact "$DOC" --kind spec --path "$DOC" --ask "jobs must not be lost" --slug fixture)
check "init makes the record folder" "$D" "$QUIZ_HOME/"

write_quiz() {  # $1 key for q2, $2 round-1 requirement flag
  python3 - "$D" "$DOC" "$1" "$2" <<'EOF'
import json, sys
d, doc, key2, req = sys.argv[1:5]
p = f"{d}/quiz.json"; q = json.load(open(p))
q["chunks"] = [
  {"id": "c1", "title": "Backoff", "depends_on": [], "claims": [
     {"id": "c1.1", "text": "Jobs retry three times.", "key_phrase": "retry three times", "slice": {"path": doc, "lines": [4, 5]}},
     {"id": "c1.2", "text": "First wait is two seconds.", "key_phrase": "two seconds", "slice": {"path": doc, "lines": [5, 5]}}]},
  {"id": "c2", "title": "Dead letter", "depends_on": ["c1"], "claims": [
     {"id": "c2.1", "text": "Exhausted jobs go to the dead-letter queue.", "key_phrase": "dead-letter queue", "slice": {"path": doc, "anchor": "Dead letter"}}]}]
q["questions"] = [
  {"id": "q1", "round": 1, "chunk": "c1", "claim": "c1.1", "type": "which-is-true", "requirement": req == "1",
   "stem": "How many times does a failed job retry?", "options": [{"code": "a", "label": "once"}, {"code": "b", "label": "three times"}],
   "key": "b", "why": "The spec says three retries.", "wrong": {"a": "One retry is the old behaviour."}},
  {"id": "q2", "round": 1, "chunk": "c2", "claim": "c2.1", "type": "what-happens-when",
   "stem": "What happens after the last retry?", "options": [{"code": "a", "label": "dropped"}, {"code": "b", "label": "dead-letter queue"}],
   "key": key2, "why": "Nothing is lost; it is parked.", "wrong": {"a": "Dropping would lose jobs."}},
  {"id": "q3", "round": 2, "chunk": "c2", "claim": "c2.1", "type": "which-is-true",
   "stem": "Where does an exhausted job end up?", "options": [{"code": "a", "label": "nowhere"}, {"code": "b", "label": "the dead-letter queue"}],
   "key": "b", "why": "It is parked, not lost.", "wrong": {"a": "It is parked."}},
  {"id": "q4", "round": 2, "chunk": "c1", "claim": "c1.2", "type": "which-is-true",
   "stem": "How long is the first wait?", "options": [{"code": "a", "label": "two seconds"}, {"code": "b", "label": "a minute"}],
   "key": "a", "why": "The spec says two seconds.", "wrong": {"b": "A minute is not in the spec."}}]
json.dump(q, open(p, "w"))
EOF
}

write_quiz b 1
check "a sound quiz passes check" "$($Q check "$D")" "READY"

write_quiz b 0
check "round 1 without a requirement question fails" "$($Q check "$D")" "no requirement question"

write_quiz z 1
out=$($Q check "$D")
check "a key that is not an option fails" "$out" "key 'z' is not an option"
check "a missing wrong line fails" "$out" "no wrong line for b"

mutate() {  # $1 python statement over q; rewrites quiz.json from the sound version first
  write_quiz b 1
  python3 - "$D/quiz.json" "$1" <<'EOF'
import json, sys
p, stmt = sys.argv[1:3]; q = json.load(open(p)); exec(stmt); json.dump(q, open(p, "w"))
EOF
}
mutate 'for i in q["questions"]: i["round"] = 2'
check "a quiz with no round 1 fails" "$($Q check "$D")" "there is no round 1"
mutate 'q["questions"][0]["requirement"] = "false"'
check "a string requirement flag does not count" "$($Q check "$D")" "no requirement question"
mutate 'q["questions"][1]["chunk"] = "c1"'
check "a question filed under the wrong chunk fails" "$($Q check "$D")" "is not the chunk its claim belongs to"
mutate 'q["chunks"][0]["claims"][0]["slice"] = "spec.md"'
out=$($Q check "$D" 2>&1)
check "a malformed slice is one problem line, not a traceback" "$out" "quiz.json is malformed"
absent "no traceback leaks" "$out" "Traceback"
mutate 'q["chunks"][0]["claims"][0]["slice"] = {"path": q["chunks"][0]["claims"][0]["slice"]["path"]}'
check "a whole-file slice is refused" "$($Q check "$D")" "a slice needs lines, an anchor or an image"
mutate 'q["questions"].append(dict(q["questions"][0]))'
check "duplicate question ids fail" "$($Q check "$D")" "q1: duplicate question id"

write_quiz b 1
w=$($Q render "$D" --round 1)
check "wizard has one step per question" "$(printf '%s' "$w" | jq '.steps | length')" "2"
check "wizard labels carry the option text" "$w" "b) three times"
check "wizard always offers not sure" "$(printf '%s' "$w" | jq -c '.steps[0].fields[0].enum')" '["a","b","?"]'
check "wizard carries only the inputs-MCP fields, so nothing can leak the key" \
  "$(printf '%s' "$w" | jq -c '[.steps[] | keys, (.fields[] | keys)] | unique')" \
  '[["enum","enum_labels","label","name","type"],["fields","message","name"]]'

pg=$($Q render "$D" --round 1 --surface page)
check "page puts the recommendation on a neutral option" "$(printf '%s' "$pg" | jq -c '[.decisions[].options[] | select(.rec) | .code] | unique')" '["x"]'

g=$($Q grade "$D" q1=b q2=a)
check "a right pick prints its why" "$g" "✓ q1  The spec says three retries."
check "a wrong pick prints the wrong line" "$g" "you picked a: Dropping would lose jobs."
check "a wrong pick reveals the anchor slice read live" "$g" "│ After the last retry the job moves to the dead-letter queue."
check "the score line is printed" "$g" "1/2 right"

check "a chunk missed once is due a retry" "$($Q retry "$D")" "c2  Dead letter  unused claims: none"
check "the map shows one miss as retry due, not missed" "$($Q report "$D")" "| Dead letter | retry due |"

out=$($Q grade "$D" q1=a 2>&1)
check "re-grading an answered question is refused" "$out" "q1 is already answered"
out=$($Q grade "$D" q4=zz 2>&1)
check "an unknown option code is refused, not graded wrong" "$out" "'zz' is not an option"
check "the page's untouched default is a skip, not a miss" "$($Q grade "$D" Q4x)" "left unanswered (q4)"

# A miss on a chunk's second claim must point at that claim, and must stop the chunk reading as held.
$Q grade "$D" Q4b >/dev/null
r=$($Q report "$D")
check "a chunk with any miss is not held" "$r" "| Backoff | retry due | First wait is two seconds. |"
check "the slice to read is the missed claim's own" "$r" "Backoff: \`$DOC:5-5\`"

printf 'Retries now stop after five attempts.\n' >> "$DOC"
$Q grade "$D" q1=b >/dev/null 2>&1
check "grading refuses after the artifact changed" "$?" "3"
$Q hash "$D" >/dev/null
check "hash reports a change with exit 3" "$?" "3"
$Q hash "$D" --accept >/dev/null
check "hash --accept clears it" "$($Q hash "$D")" "same"

$Q grade "$D" q3=b >/dev/null
r=$($Q report "$D")
check "right after a miss is shaky" "$r" "| Dead letter | shaky | Exhausted jobs go to the dead-letter queue. |"
check "map.md is written" "$(cat "$D/map.md")" "# Quiz map:"
check "weak chunks get a slice to read" "$r" "Dead letter: \`$DOC § Dead letter\`"

sed -i '' 's/dead-letter queue/parking lot/' "$DOC"
check "a slice that lost its key phrase is flagged" "$($Q check "$D")" "slice no longer contains 'dead-letter queue'"

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
