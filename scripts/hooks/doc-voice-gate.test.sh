#!/bin/bash
# Checks the doc gate against real offending docs (must speak), their plain
# rewrites (must stay quiet), the scope rules, and the end-of-turn gate.
H="${GATE_UNDER_TEST:-$HOME/.claude/scripts/hooks/doc-voice-gate.py}"
FIX="$HOME/.claude/assets/reports/20261019-reader-doc-fixture"
WALL="$HOME/.claude/assets/reports/20261022-doc-gate-fixture"
# Recovered from the sessions that wrote them: the 19 Oct capabilities doc as first
# written, the 20 Oct PR status doc before and after its rewrite, and PR 60's two bodies.
REC="$HOME/.claude/assets/reports/20261027-readability-gate-fixture"
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
{ cat "$FIX/cprd-parity-after.md"; printf '\n## Sources\n'; grep -v '^#' "$FIX/cprd-parity-before.md" | head -12; } > "$T/docs/plan/tail.md"
expect "ids inside a final Sources section do not count" silent "$(run "$T/docs/plan/tail.md")"
{ printf 'Plain intro.\n\n## Sources\n'; grep -v '^#' "$FIX/cprd-parity-before.md"; } > "$T/docs/plan/tail-dump.md"
expect "but a page moved wholesale into Sources is called out" "outweighs the page" "$(run "$T/docs/plan/tail-dump.md")"

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
expect "calling it better while it fails does too" "tells the owner the doc is better" "$(stop s1b 'Made legacy.md much clearer.')"
cp "$WALL/directions-plain.md" "$R/docs/good.md"
git -C "$R" add docs/good.md
git -C "$R" -c user.email=t@t -c user.name=t commit -q -m good
cp "$WALL/directions-wall.md" "$R/docs/good.md"
run "$R/docs/good.md" s0 >/dev/null
expect "a doc that passed before and fails now holds the turn" '"decision": "block"' "$(stop s0 'Updated good.')"

# The two docs of 19 and 20 Oct that reached the owner as internal ledgers.
# The first sat under docs/ and is judged on sight; it got through because the
# gate was committed hours after it was written. The second sat under
# .claude/output/ with no reader line, which the scope skipped entirely.
cp "$REC/cprd-parity-original.md" "$T/docs/plan/original.md"
expect "the 19 Oct capabilities doc is flagged as written" "internal ledger" "$(run "$T/docs/plan/original.md" r1)"
O="$T/proj/.claude/output/20261019-pr-replies"; mkdir -p "$O"
runa() { printf '{"session_id":"%s","agent_id":"ag1","tool_name":"Write","tool_input":{"file_path":"%s"}}' "${2:-s1}" "$1" | python3 "$H"; }
TILDE='~'
cp "$REC/review-before-rewrite.md" "$O/review.md"
expect "the 20 Oct status doc is quiet while it is only a file" silent "$(run "$O/review.md" r2)"
run "$O/review.md" r2a >/dev/null
expect "but the turn may not end once the reply hands it over" '"decision": "block"' \
  "$(stop r2a "Status is in $O/review.md, merge order at the top.")"
run "$O/review.md" r2b >/dev/null
expect "and says it reads like an internal ledger" "internal ledger" "$(stop r2b "Status is in $O/review.md.")"
run "$O/review.md" r2c >/dev/null
expect "and offers the reader line as the way out" "reader: agent" "$(stop r2c "Status is in $O/review.md.")"
run "$O/review.md" r3 >/dev/null
expect "a reply that does not name the file never stops on it" silent "$(stop r3 'Status doc updated, check the PR board.')"
run "$O/review.md" r4 >/dev/null
expect "naming it with ~ works too" '"decision": "block"' "$(stop r4 "See ${O/#$HOME/$TILDE}/review.md")"
{ printf -- '---\nreader: agent\n---\n'; cat "$REC/review-before-rewrite.md"; } > "$O/agent.md"
run "$O/agent.md" r5 >/dev/null
expect "reader: agent clears a handed-over file" silent "$(stop r5 "Notes in $O/agent.md")"
cp "$REC/review-before-rewrite.md" "$O/seat.md"
runa "$O/seat.md" r6 >/dev/null
expect "a sub-agent's file is never held on the parent's reply" silent "$(stop r6 "Seat output at $O/seat.md")"
cp "$REC/review-after-rewrite.md" "$O/plain.md"
run "$O/plain.md" r7 >/dev/null
expect "the plain rewrite of the status doc passes when handed over" silent "$(stop r7 "Status is in $O/plain.md")"
{ printf -- '---\nreader: owner\n---\n'; cat "$REC/review-before-rewrite.md"; } > "$O/declared.md"
expect "a declared human reader brings a .claude file into scope" "internal ledger" "$(run "$O/declared.md" r8)"

# Update stamps are ledger marks of their own kind.
printf 'See the table.\n\nUpdated 2026-10-20 ~20:15 IST, mergeable.\n\nStatus at ~22:10: steps 1 to 8 merged (ab5722e).\n\nUpdated 20:15 by me, see `a/b.py:12` and `c/d.py:40`, 943e257 and 148f833, CAP-1, CAP-2, V1, V2.\n' > "$T/docs/plan/stamps.md"
expect "dated update lines count toward the ledger check" "internal ledger" "$(run "$T/docs/plan/stamps.md" r9)"

# Hard to skim: dense paragraphs, semicolon-spliced lines, internals-only runs.
P1='The cache keeps recent reads in memory for the length of one request. A second call with the same key gets the stored reply instead of going back to disk. Entries expire after sixty seconds so a stale value cannot linger for long. The size is capped at five hundred entries and the oldest one is dropped first.'
P2='The `fetch` in `src/lib/beehiiv.ts` memoizes the GET for 3s. Each retry adds an `X-Retry-Attempt` header, which changes the cache key. The `revalidate = 3600` setting then applies per key.'
S1='Phases run in order; within a phase the items are independent of each other, so any order inside one works.'
printf 'Intro.\n\n%s\n\n%s\n\n%s\n\nEnd.\n' "$P1" "$P1 More." "$P1 Again." > "$T/docs/plan/dense.md"
expect "dense paragraphs in a doc are called hard to skim" "hard to skim" "$(run "$T/docs/plan/dense.md" r10)"
printf '%s\n\n%s\n\n%s\n' "$S1" "$S1 Yes." "$S1 Always." > "$T/docs/plan/semis.md"
expect "semicolon-spliced long lines are called out" "glued with a semicolon or dash" "$(run "$T/docs/plan/semis.md" r11)"
printf '%s\n\n%s\n\n%s\n' "$P2" "$P2 One." "$P2 Two." > "$T/docs/plan/mech.md"
expect "runs of internals-only sentences are called out" "only name code" "$(run "$T/docs/plan/mech.md" r13)"
printf 'Intro.\n\n%s\n\n%s\n\n%s\n' "$P1" "$S1" "$P2" > "$T/docs/plan/few.md"
expect "one such block of each kind in a doc is allowed" silent "$(run "$T/docs/plan/few.md" r12)"

# Fixes from the 2026-10-29 gate diagnosis.
# A sub-agent's write gets the note in its own context but never holds the parent's turn.
cp "$WALL/directions-wall.md" "$T/docs/plan/seat.md"
got=$(printf '{"session_id":"q1","agent_id":"a-seat","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$T/docs/plan/seat.md" | python3 "$H")
expect "a sub-agent's write still gets the note" "does not read as a doc" "$got"
expect "but the parent's turn is not held for it" silent "$(stop q1 'The seat is still working.')"
# A plain decline that names the doc ends the turn on the first stop, and the owner is told.
cp "$WALL/directions-wall.md" "$T/docs/plan/DIRECTIONS.md"
run "$T/docs/plan/DIRECTIONS.md" q2 >/dev/null
got=$(stop q2 'DIRECTIONS.md still fails the doc check, because a seat is rewriting it now.')
expect "an honest decline ends the turn at once" '"systemMessage"' "$got"
expect "and tells the owner it was left on purpose" "on purpose" "$got"
# Two docs admitted in one sentence both count.
cp "$WALL/directions-wall.md" "$T/docs/plan/one.md"; cp "$WALL/directions-wall.md" "$T/docs/plan/two.md"
run "$T/docs/plan/one.md" q3 >/dev/null; run "$T/docs/plan/two.md" q3 >/dev/null
expect "a plural admission covers both docs" '"systemMessage"' "$(stop q3 'one.md and two.md still fail the doc check.')"
# A claim word elsewhere in the reply, or a plain-word stem, does not count as calling the doc better.
cp "$WALL/directions-wall.md" "$T/docs/plan/testing.md"
run "$T/docs/plan/testing.md" q4 >/dev/null
expect "fixing a testing job is not a claim about testing.md" '"decision": "block"' \
  "$(stop q4 'Merged it. I also fixed the flaky testing job in CI.')"
stop q4 'Merged it.' >/dev/null
expect "and it is not treated as a claim, so the third stop lets go" '"systemMessage"' \
  "$(stop q4 'Merged it. I also fixed the flaky testing job in CI.')"
# Real names are not agent codes; separator rows are not long cells; indented fences are code.
printf 'Logs land in Amazon S3 as UTF-8 text. The P95 latency is 40 ms and P99 is 90 ms. EC2 hosts read them.\n\nCache is on redis.svc:6379 and the key used to sign is rotated. It is no longer cached.\n\nS3 and EC2 again, P95 and UTF-8, SHA-256 hashes, as of 2026-10-26.\n' > "$T/docs/plan/aws.md"
expect "common tech names and host:port are not ledger marks" silent "$(run "$T/docs/plan/aws.md" q5)"
SEP=$(printf -- '-%.0s' $(seq 1 170))
printf '| a | b |\n|%s|%s|\n| x | y |\n| x | y |\n|%s|%s|\n|%s|%s|\n' "$SEP" "$SEP" "$SEP" "$SEP" "$SEP" "$SEP" > "$T/docs/plan/sep.md"
expect "table separator rows are not long cells" silent "$(run "$T/docs/plan/sep.md" q6)"
printf '1. Run it:\n\n   ```bash\n   git show 943e257 a/b.py:12 c/d.py:40 943e258 943e259 e/f.py:9 g/h.py:3 1a2b3c4d\n   ```\n\nDone.\n' > "$T/docs/plan/fence.md"
expect "an indented fence is code, not prose" silent "$(run "$T/docs/plan/fence.md" q7)"
# Swapping dashes for semicolons is not an improvement: both count as glued lines.
D1='Phases run in order — within a phase the items are independent of each other, so any order inside one works.'
printf '%s\n\n%s\n\n%s\n' "$D1" "$D1 Yes." "$D1 Always." > "$T/docs/plan/dashes.md"
expect "dash-glued lines count like semicolon ones" "glued with a semicolon or dash" "$(run "$T/docs/plan/dashes.md" q8)"
# The note names the move, not just the count.
expect "the note points at the restructuring moves" "section 6b" "$(run "$T/docs/plan/dense.md" q9)"
# Shape: agent codes alone, long sentences, a long page with no sections.
{ printf 'Status for the owner.\n\n'; for i in 1 2 3 4; do printf 'S%d closed A%d and D%d holds per R%d, so the next step waits.\n\n' $i $i $i $i; done; } > "$T/docs/plan/codes.md"
expect "agent codes in running text are called out on their own" "agent codes" "$(run "$T/docs/plan/codes.md" q10)"
expect "and a new doc failing only on shape holds the turn" '"decision": "block"' "$(stop q10 'Wrote the status page.')"
printf '| id | what |\n|---|---|\n| A1 | x |\n| A2 | y |\n| A3 | z |\n| A4 | w |\n| A5 | v |\n| A6 | u |\n| A7 | t |\n| A8 | s |\n| A9 | r |\n| A10 | q |\n| A11 | p |\n' > "$T/docs/plan/idcol.md"
expect "codes in a table's id column are fine" silent "$(run "$T/docs/plan/idcol.md" q11)"
L='When a seller uploads a file the importer reads every column and maps it to a field and then checks the values against the catalog and then writes the rows it trusts and holds back the rest for review by a person.'
printf 'Intro.\n\n%s\n\n%s\n\n%s\n\n%s\n' "$L" "$L" "$L" "$L" > "$T/docs/plan/longs.md"
expect "a run of very long sentences is called out" "run past 40 words" "$(run "$T/docs/plan/longs.md" q12)"
{ printf 'Intro.\n\n'; for i in $(seq 1 90); do printf 'The sync job copies each row once a night. It skips rows that did not change. A failed row is retried the next night.\n\n'; done; } > "$T/docs/plan/flat.md"
expect "a long page with no sections is called out" "section headings" "$(run "$T/docs/plan/flat.md" q13)"
trash "$T" 2>/dev/null
exit $fail
