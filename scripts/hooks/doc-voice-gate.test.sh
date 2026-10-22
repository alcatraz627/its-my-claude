#!/bin/bash
# Checks the doc gate against real offending docs (must speak), their plain
# rewrites (must stay quiet), the scope rules, and the end-of-turn gate.
H="$HOME/.claude/scripts/hooks/doc-voice-gate.py"
FIX="$HOME/.claude/assets/reports/20261019-reader-doc-fixture"
WALL="$HOME/.claude/assets/reports/20261022-doc-gate-fixture"
T=$(mktemp -d)
export DOC_VOICE_STATE="$T/state" DOC_VOICE_EXEMPT="$T/exempt.txt" DOC_VOICE_OFF=0
mkdir -p "$DOC_VOICE_STATE"
fail=0
run() { printf '{"session_id":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "${2:-s1}" "$1" | python3 "$H"; }
stop() { jq -cn --arg s "$1" --arg m "$2" '{session_id:$s, last_assistant_message:$m}' | python3 "$H" stop; }
expect() {
  local name="$1" want="$2" got="$3"
  if [ "$want" = silent ]; then
    [ -z "$got" ] && echo "ok   $name" || { echo "FAIL $name: ${got:0:200}"; fail=1; }
  else
    printf '%s' "$got" | grep -q -- "$want" && echo "ok   $name" || { echo "FAIL $name: '${got:0:200}'"; fail=1; }
  fi
}
mkdir -p "$T/docs/plan" "$T/notes" "$T/proj/.claude/docs"
cp "$FIX/cprd-parity-before.md" "$T/docs/plan/before.md"
cp "$FIX/cprd-parity-after.md" "$T/docs/plan/after.md"
expect "the ledger-style doc is flagged" "internal ledger" "$(run "$T/docs/plan/before.md")"
expect "and asks for a reader line" "reader:" "$(run "$T/docs/plan/before.md")"
expect "the plain rewrite is quiet" silent "$(run "$T/docs/plan/after.md")"
cp "$FIX/cprd-parity-before.md" "$T/notes/before.md"
expect "outside docs/ with no reader is out of scope" silent "$(run "$T/notes/before.md")"
{ printf -- '---\nreader: CEO\n---\n'; cat "$FIX/cprd-parity-before.md"; } > "$T/notes/declared.md"
expect "a declared human reader brings it into scope" "internal ledger" "$(run "$T/notes/declared.md")"
{ printf -- '---\nreader: agent\n---\n'; cat "$FIX/cprd-parity-before.md"; } > "$T/notes/agent.md"
expect "reader: agent outside docs/ is skipped" silent "$(run "$T/notes/agent.md")"
{ printf -- '---\nreader: agent\n---\n'; cat "$FIX/cprd-parity-before.md"; } > "$T/docs/plan/agent.md"
expect "reader: agent does not exempt a doc under docs/" "internal ledger" "$(run "$T/docs/plan/agent.md")"
echo "$T/docs/plan/agent.md" > "$DOC_VOICE_EXEMPT"
expect "the owner's exempt list does" silent "$(run "$T/docs/plan/agent.md")"
: > "$DOC_VOICE_EXEMPT"
cp "$FIX/cprd-parity-before.md" "$T/proj/.claude/docs/x.md"
expect "agent folders are skipped" silent "$(run "$T/proj/.claude/docs/x.md")"
{ printf 'Plain intro.\n\n## Sources\n'; cat "$FIX/cprd-parity-before.md" | grep -v '^#'; } > "$T/docs/plan/tail.md"
expect "ids inside a final Sources section do not count" silent "$(run "$T/docs/plan/tail.md")"

# The wall of text: DIRECTIONS.md as the owner called it a wall, and as rewritten.
cp "$WALL/directions-wall.md" "$T/docs/plan/DIRECTIONS.md"
expect "the wall version is called a wall of text" "wall of text" "$(run "$T/docs/plan/DIRECTIONS.md" s9)"
cp "$WALL/directions-plain.md" "$T/docs/plan/plain-directions.md"
expect "its rewrite is quiet" silent "$(run "$T/docs/plan/plain-directions.md" s8)"

# The end of the turn: the doc as it stands decides, not the note.
expect "the turn may not end while the doc fails" '"decision": "block"' "$(stop s9 'Updated the directions file.')"
expect "nor a second time" '"decision": "block"' "$(stop s9 'Still working on it.')"
got=$(stop s9 'Leaving it.')
expect "the third stop goes through and tells the owner" '"systemMessage"' "$got"
expect "naming the doc" "DIRECTIONS.md still fails" "$got"
expect "after that the session starts clean" silent "$(stop s9 'next turn')"

cp "$WALL/directions-wall.md" "$T/docs/plan/DIRECTIONS.md"
run "$T/docs/plan/DIRECTIONS.md" s7 >/dev/null
stop s7 'first try' >/dev/null
stop s7 'second try' >/dev/null
expect "calling the failing doc better is blocked once more" "tells the owner the doc is better" \
  "$(stop s7 'I rewrote DIRECTIONS so it reads better.')"
cp "$WALL/directions-wall.md" "$T/docs/plan/DIRECTIONS.md"
run "$T/docs/plan/DIRECTIONS.md" s6 >/dev/null
stop s6 'first' >/dev/null
stop s6 'second' >/dev/null
expect "an honest admission ends the turn, and the owner is told" '"systemMessage"' \
  "$(stop s6 'DIRECTIONS still fails the doc check: the tables are meant to be dense for agents.')"

run "$T/docs/plan/DIRECTIONS.md" s5 >/dev/null
cp "$WALL/directions-plain.md" "$T/docs/plan/DIRECTIONS.md"
expect "a doc fixed before the turn ends lets it end quietly" silent "$(stop s5 'Rewrote DIRECTIONS, now plain.')"
expect "a session that wrote no doc is never stopped" silent "$(stop s4 'done')"

# A doc that already failed before the turn: a small edit is not held, making it worse is.
R="$T/repo"; mkdir -p "$R/docs"
git -C "$R" init -q
cp "$WALL/directions-wall.md" "$R/docs/legacy.md"
git -C "$R" add docs/legacy.md
git -C "$R" -c user.email=t@t -c user.name=t commit -q -m legacy
printf '\nOne more short line.\n' >> "$R/docs/legacy.md"
expect "a legacy failing doc still gets the note" "already failed before this turn" "$(run "$R/docs/legacy.md" s3)"
expect "a small edit to it does not hold the turn" silent "$(stop s3 'Added a line to legacy.')"
printf '\n| a | %s |\n' "$(printf 'x%.0s' $(seq 1 200))" >> "$R/docs/legacy.md"
run "$R/docs/legacy.md" s2 >/dev/null
expect "making it worse does" '"decision": "block"' "$(stop s2 'Added a row.')"
git -C "$R" checkout -q -- docs/legacy.md
printf '\nOne more short line.\n' >> "$R/docs/legacy.md"
run "$R/docs/legacy.md" s1b >/dev/null
expect "calling it better while it fails does too" "tells the owner the doc is better" "$(stop s1b 'Made legacy much clearer.')"
cp "$WALL/directions-plain.md" "$R/docs/good.md"
git -C "$R" add docs/good.md
git -C "$R" -c user.email=t@t -c user.name=t commit -q -m good
cp "$WALL/directions-wall.md" "$R/docs/good.md"
run "$R/docs/good.md" s0 >/dev/null
expect "a doc that passed before and fails now holds the turn" '"decision": "block"' "$(stop s0 'Updated good.')"
trash "$T" 2>/dev/null
exit $fail
