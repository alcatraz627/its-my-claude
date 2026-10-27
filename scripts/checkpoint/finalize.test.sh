#!/usr/bin/env bash
# Tests for finalize.sh, the one call after /core-dump's Write.
#
# What it guards is a checkpoint that parses, indexes and renders while quietly
# misleading its reader: a broken file that gets indexed anyway, a caveat that
# vanished between dumps, an "authorization" the owner never gave. Every row runs
# against a fake HOME and a fake transcript, never the owner's real index; the
# last row proves it by comparing the real index before and after.
#
# FINALIZE=<path> runs the same rows against a mutated copy (mutation proofs).
# CK_TEST_QUIET=1 prints failures and the final line only.

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
FINALIZE="${FINALIZE:-$HERE/finalize.sh}"
FIX="$HERE/ckfixture.py"

pass=0; total=0
ok()  { pass=$((pass+1)); total=$((total+1)); [ -n "${CK_TEST_QUIET:-}" ] || echo "  PASS $1"; }
bad() { total=$((total+1)); echo "  FAIL $1"; }
check() {  # check <label> <haystack> <needle>
  case "$2" in *"$3"*) ok "$1";; *) bad "$1 (wanted: $3)"; printf '       got: %s\n' "$2" | head -c 700; echo;; esac
}
lacks() {  # lacks <label> <haystack> <needle>
  case "$2" in *"$3"*) bad "$1 (should not contain: $3)"; printf '       got: %s\n' "$2" | head -c 700; echo;; *) ok "$1";; esac
}

REAL_CKDIR="${CK_TEST_REAL_CKDIR:-$HOME/.claude/checkpoints}"

T=$(cd "$(mktemp -d)" && pwd -P)
export HOME="$T/home"
export NO_COLOR=1 TRACE_THEME=a CK_TMP="$T/tmp" CK_PRETTIER_CMD="/no/such/prettier"
unset CLAUDE_CODE_SESSION_ID
UUID="bbbbbbbb-1111-2222-3333-444444444444"
SID="fix-auth-3b"
PROJ="$T/proj"
ENC=$(printf '%s' "$PROJ" | sed 's#[/.]#-#g')
mkdir -p "$HOME/.claude/projects/$ENC" "$HOME/.claude/checkpoints" "$HOME/.claude/subconscious/scripts" "$PROJ/.claude" "$CK_TMP"
TX="$HOME/.claude/projects/$ENC/$UUID.jsonl"
CP="$PROJ/_20261013-$SID.claude.md"
PTR="$HOME/.claude/checkpoints/$SID.json"
IDX="$HOME/.claude/checkpoints/index.jsonl"

# The dream ingester is stubbed: the row only needs proof that write.sh still calls it.
cat > "$HOME/.claude/subconscious/scripts/ingest-checkpoint.sh" <<EOF
#!/bin/bash
echo "\$1" > "$T/ingested"
EOF
chmod +x "$HOME/.claude/subconscious/scripts/ingest-checkpoint.sh"

# The owner said two things this session; the assistant claimed a third.
cat > "$T/spec.json" <<EOF
[
 {"role":"owner","ts":"2026-10-13T09:00:00Z","text":"Yes,  Go ahead and push\nto the branch for PR 12, nothing else"},
 {"role":"assistant","ts":"2026-10-13T09:00:05Z","id":"msg_1","text":"Understood. I will also deploy to production when ready."},
 {"role":"owner","ts":"2026-10-13T09:10:00Z","text":"stop using the old importer"},
 {"role":"owner","ts":"2026-10-13T09:11:00Z","text":"please push the reviewed branch to origin then open the pull request for review and after that wait for my approval"},
 {"role":"owner","ts":"2026-10-13T09:12:00Z","text":"Go ahead and push the fix to the branch. Do not touch main."}
]
EOF
python3 "$FIX" "$T/spec.json" "$TX"

# mk [VAR=value ...]: write a full checkpoint to $CP; any field can be overridden.
mk() {
  local GOAL="Fix the login bug. The owner wants it done before Friday." SUMMARY="Fixed login, one thing left." \
        CONS='(1) "keep the existing UI, reuse it" (check: baseline screenshots)' \
        CAV='(1) Nothing is pushed. (2) The importer is unreviewed.' \
        NEXT="Run the importer dry run." BLOCKED="AGENT: none, go" \
        AUTH="none" VERIFY="pytest -q green after action 3" KEYFILES="none" RULINGS="none" \
        PENDING="- Run the importer dry run" ACTIONS="1. Fixed the bug" INSIGHTS="- the cache helped
- the first build failed on a stale lock" \
        EXTRA="" v
  for v in "$@"; do eval "${v%%=*}=\${v#*=}"; done
  cat > "$CP" <<EOF
# Quick Summary (for LLMs), 2026-10-13T10:00:00Z

> $SUMMARY

# Core Dump, 2026-10-13T10:00:00Z

## Resume Contract

- **Standing constraints:** $CONS
- **Standing caveats:** $CAV
- **Next action:** $NEXT
- **Next action's requirements:** none
- **Blocked on:** $BLOCKED
$AUTH_LINE
- **Pending approval codes:** none
- **Decaying prerequisites:** none
- **Verification state:** $VERIFY
- **Live commitments:** goal: none · wake: none · deadline: none · crons: none
- **Task list, glanced:** $(printf '\342\200\224')
- **Task store:** $(printf '\342\200\224')
- **Goal record:** $(printf '\342\200\224')
- **ipc alias:** gcc-test
- **Key anchor:** $(printf '\342\200\224')
- **Key files:** $KEYFILES
- **Atone this session:** none
- **Rulings this session:** $RULINGS
$EXTRA

## Initial Goal

$GOAL

## Agent Actions

$ACTIONS

## Current Expectation

x

## Pending Items

$PENDING

## Session Insights

$INSIGHTS
EOF
}
# the authorizations line is built separately because its value carries quotes
AUTH_LINE='- **Standing authorizations:** none'
setauth() { AUTH_LINE="- **Standing authorizations:** $1"; }

F() { bash "$FINALIZE" "$CP" --uuid "$UUID" --session-id "$SID" "$@" 2>&1; }
ptr() { tr -s " " < "$PTR" 2>/dev/null; }
reset() { trash "$IDX" "$PTR" "$PROJ/_checkpoint.claude.md" "$T/ingested" "$HOME/.claude/_last-checkpoint.json" 2>/dev/null; }

echo "== a sound checkpoint is formatted, indexed, linked and rendered last =="
reset; mk
OUT=$(F); rc=$?
[ "$rc" = 0 ] && ok "exits 0" || bad "exit $rc: $OUT"
check "the report says the contract holds" "$OUT" "OK: parse contract satisfied"
[ -f "$PTR" ] && ok "session pointer written under the fake HOME" || bad "no pointer at $PTR"
check "pointer name defaults to the session id" "$(ptr)" "\"name\": \"$SID\""
check "pointer summary is the goal's first sentence" "$(ptr)" "\"summary\": \"Fix the login bug.\""
check "pointer carries the session uuid" "$(ptr)" "\"session_uuid\": \"$UUID\""
check "index line appended" "$(cat "$IDX" 2>/dev/null)" "$CP"
[ "$(readlink "$PROJ/_checkpoint.claude.md")" = "_20261013-$SID.claude.md" ] && ok "_checkpoint.claude.md links to the dump" || bad "link is $(readlink "$PROJ/_checkpoint.claude.md")"
for i in 1 2 3 4 5 6; do [ -f "$T/ingested" ] && break; sleep 0.5; done
[ -f "$T/ingested" ] && ok "dream ingestion still runs behind write.sh" || bad "ingester stub never ran"
check "dream wiring is reported" "$OUT" "OK: dream ingestion is wired into write.sh"
REPORT_LAST=$(printf '%s\n' "$OUT" | rg -n '^(OK|WARN|DECIDE|UNVERIFIED|CONFIRM OR RETIRE|FIX):' | tail -1 | cut -d: -f1)
RENDER_AT=$(printf '%s\n' "$OUT" | rg -n 'DECREE' | head -1 | cut -d: -f1)
RESUME_AT=$(printf '%s\n' "$OUT" | rg -n '/catchup at' | tail -1 | cut -d: -f1)
{ [ -n "$REPORT_LAST" ] && [ -n "$RENDER_AT" ] && [ "$REPORT_LAST" -lt "$RENDER_AT" ] && [ -n "$RESUME_AT" ] && [ "$RESUME_AT" -gt "$REPORT_LAST" ]; } \
  && ok "the report comes first and the render, ending in the resume line, comes last" \
  || bad "order wrong: report ends $REPORT_LAST, render starts $RENDER_AT, resume at $RESUME_AT"
check "render carries the pending item" "$OUT" "Run the importer dry run"

echo "== a broken file is refused before anything is indexed =="
reset; mk
sed -i '' 's/^## Pending Items$/## Todo list/' "$CP"
OUT=$(F); rc=$?
[ "$rc" = 1 ] && ok "exit 1" || bad "exit $rc"
check "the validator's message is shown under FIX" "$OUT" "FIX:"
check "and names the missing heading" "$OUT" "## Pending Items"
[ ! -f "$PTR" ] && [ ! -f "$IDX" ] && ok "nothing indexed" || bad "a broken checkpoint was indexed"
[ ! -e "$PROJ/_checkpoint.claude.md" ] && ok "and not linked" || bad "a broken checkpoint was linked"
reset; mk
OUT=$(F); rc=$?
[ "$rc" = 0 ] && ok "after one repair finalize succeeds on the same call shape" || bad "exit $rc after repair"

echo "== the formatter runs first, and its absence is silent =="
cat > "$T/fakefmt.sh" <<EOF
#!/bin/bash
# stands in for prettier: --write <file>
sed -i '' 's/FMTME/formatted/' "\$2"
EOF
reset; mk GOAL="Fix FMTME the login bug. Second."
OUT=$(CK_PRETTIER_CMD="bash $T/fakefmt.sh" F)
check "the file on disk was formatted before the checks" "$(cat "$CP")" "Fix formatted the login bug"
check "the pointer summary reads the formatted text" "$(ptr)" "formatted"
reset; mk GOAL="Fix FMTME the login bug. Second."
OUT=$(F)
lacks "no formatter available prints nothing about it" "$OUT" "prettier"
check "and the file is left as written" "$(cat "$CP")" "FMTME"
reset; mk
cat > "$T/failfmt.sh" <<EOF
#!/bin/bash
exit 1
EOF
OUT=$(CK_PRETTIER_CMD="bash $T/failfmt.sh" F); rc=$?
[ "$rc" = 0 ] && ok "a formatter that fails does not block the dump" || bad "exit $rc"

echo "== caveats that vanished since the previous dump of this session =="
reset
mk CAV='(1) Nothing is pushed. (2) The importer is unreviewed. (3) Four findings remain undispositioned.'
PREV="$PROJ/_20261012-$SID.claude.md"
cp "$CP" "$PREV"; touch -t 202610120000 "$PREV"
mk CAV='(1) Nothing is pushed.'
# a newer file of ANOTHER session whose caveats match, which a "newest of any stem" lookup would diff against
mk CAV='(1) Nothing is pushed.'; cp "$CP" "$PROJ/_20261013-someone-else.claude.md"
OUT=$(F); rc=$?
check "the dropped caveat is named under DECIDE" "$OUT" "DECIDE: caveat in _20261012-$SID.claude.md is absent now"
check "every dropped caveat is named, not just the first" "$OUT" "Four findings remain undispositioned"
[ "$rc" = 0 ] && ok "a vanished caveat is a decision, not a failure" || bad "exit $rc"
[ -f "$PTR" ] && ok "the dump is still indexed" || bad "not indexed"
OUT=$(F --prev "$PROJ/_20261013-someone-else.claude.md")
lacks "an explicit --prev overrides the stem lookup" "$OUT" "DECIDE: caveat"
reset; mk CAV='(1) Nothing is pushed. (2) The importer is unreviewed. (3) Four findings remain undispositioned.'
OUT=$(F)
check "nothing vanished is reported as OK" "$OUT" "OK: no caveats vanished since"
trash "$PREV" "$PROJ/_20261013-someone-else.claude.md"

echo "== a --prev that is not a file is said out loud and falls back to the stem lookup =="
reset
mk CAV='(1) Nothing is pushed. (2) The importer is unreviewed. (3) Four findings remain undispositioned.'
cp "$CP" "$PREV"; touch -t 202610120000 "$PREV"
mk CAV='(1) Nothing is pushed.'
OUT=$(F --prev "$PROJ/no-such-file.md"); rc=$?
check "a missing --prev prints a WARN" "$OUT" "WARN: --prev $PROJ/no-such-file.md is not a file; carry-forward from it skipped"
check "and the stem lookup still finds the real previous dump" "$OUT" "DECIDE: caveat in _20261012-$SID.claude.md is absent now"
trash "$PREV"

echo "== the copy gather leaves is keyed by uuid and name =="
reset
mkdir -p "$HOME/.claude/checkpoints/.prev"
mk CAV='(1) Nothing is pushed. (2) The importer is unreviewed. (3) Four findings remain undispositioned.'
cp "$CP" "$HOME/.claude/checkpoints/.prev/${UUID:0:8}-$SID.md"
cp "$CP" "$HOME/.claude/checkpoints/.prev/$SID.md"
mk CAV='(1) Nothing is pushed.'
OUT=$(F)
check "the copy under uuid8-name is the previous dump" "$OUT" "DECIDE: caveat in ${UUID:0:8}-$SID.md is absent now"
trash "$HOME/.claude/checkpoints/.prev/${UUID:0:8}-$SID.md"
reset; mk CAV='(1) Nothing is pushed.'
OUT=$(F)
lacks "a copy keyed by the name alone (another project's) is not read" "$OUT" "DECIDE: caveat"
trash "$HOME/.claude/checkpoints/.prev/$SID.md"

echo "== standing constraints: vanished, and unattributed =="
reset
mk CONS='(1) "keep the existing UI, reuse it" (check: baseline screenshots) (2) "no schema changes this week" (check: migration diff empty)'
cp "$CP" "$PREV"; touch -t 202610120000 "$PREV"
mk CONS='(1) "keep the existing UI, reuse it" (check: baseline screenshots)'
OUT=$(F)
check "a constraint present before and absent now is a DECIDE" "$OUT" "DECIDE: constraint in _20261012-$SID.claude.md is absent now"
check "naming the lost constraint" "$OUT" "no schema changes this week"
lacks "the carried constraint is not flagged" "$OUT" "keep the existing UI, reuse it"
trash "$PREV"
reset; mk CONS='(1) keep the existing UI (check: screenshots) (2) "no schema changes this week" (check: migration diff)'
OUT=$(F)
check "an entry with no quoted words is CONFIRM OR RETIRE" "$OUT" "CONFIRM OR RETIRE: constraint with no quoted owner words: keep the existing UI"
lacks "a quoted entry is not" "$OUT" "CONFIRM OR RETIRE: constraint with no quoted owner words: \"no schema"
check "the file is never edited for it" "$(cat "$CP")" "keep the existing UI (check: screenshots)"
reset; mk CONS='none'
OUT=$(F)
lacks "none is not an unattributed constraint" "$OUT" "CONFIRM OR RETIRE"

echo "== standing authorizations must be the owner's words, said this session =="
reset
setauth '"go ahead and push to the branch for PR 12" (2026-10-13 09:00) · target: acme/app PR 12 @abc1234 · one-shot · "deploy everything to production now" (2026-10-13 09:05) · target: acme/app @abc1234 · standing · "never said this anywhere" (2026-10-13 09:06) · target: x · one-shot · "go ahead and push ... for PR 12, nothing else" (2026-10-13 09:01) · target: acme/app · one-shot'
mk
OUT=$(F); rc=$?
[ "$rc" = 0 ] && ok "exit 0, an unverified line is reported not fatal" || bad "exit $rc"
BODY=$(cat "$CP")
check "words the owner said (case and whitespace differ) stay as written" "$BODY" '- **Standing authorizations:** "go ahead and push to the branch for PR 12"'
lacks "and are not prefixed" "$BODY" 'UNVERIFIED: "go ahead and push'
check "words only the assistant said are rewritten UNVERIFIED in the file" "$BODY" 'UNVERIFIED: "deploy everything to production now"'
check "words nobody said are rewritten UNVERIFIED" "$BODY" 'UNVERIFIED: "never said this anywhere"'
lacks "a quote with ... between two owner phrases in one message verifies" "$BODY" 'UNVERIFIED: "go ahead and push ... for PR 12'
check "the report lists the UNVERIFIED lines" "$OUT" 'UNVERIFIED: no owner message of this session says "deploy everything to production now"'
OUT=$(F)
lacks "a second run does not double the prefix" "$(cat "$CP")" "UNVERIFIED: UNVERIFIED:"
check "a second run reports it as already marked" "$OUT" "UNVERIFIED: already marked"
check "the pointer is still written" "$(ptr)" "$CP"

echo "== authorizations carried from the previous dump stay verified =="
reset
setauth '"approve the vercel deploy for the website" (2026-10-12 11:00) · target: web @def5678 · standing'
mk
cp "$CP" "$PREV"; touch -t 202610120000 "$PREV"
setauth '"approve the vercel deploy for the website" (2026-10-12 11:00) · target: web @def5678 · standing · "something new nobody said" (2026-10-13 09:00) · target: web · one-shot'
mk
OUT=$(F)
lacks "a grant verified in the previous dump needs no words in this transcript" "$(cat "$CP")" 'UNVERIFIED: "approve the vercel'
check "a new unsaid grant is still caught" "$(cat "$CP")" 'UNVERIFIED: "something new nobody said"'
trash "$PREV"

echo "== every entry is checked on its own, not only the whole field =="
reset
setauth '"go ahead and push to the branch for PR 12" (2026-10-13 09:00) · target: acme/app PR 12 @abc1234 · one-shot · "go ahead and push to the branch" · target: acme/app · one-shot'
mk
OUT=$(F)
BODY=$(cat "$CP")
lacks "the full dated grant the owner said is left alone" "$BODY" 'UNVERIFIED: "go ahead and push to the branch for PR 12"'
check "a dateless entry beside a dated one gets its own prefix" "$BODY" 'UNVERIFIED: "go ahead and push to the branch" · target'
check "and the report says it is not shaped as a grant" "$OUT" 'UNVERIFIED: not shaped as'
reset
setauth '"go ahead and push to the branch for PR 12" (2026-10-13 09:00) · one-shot'
mk
OUT=$(F)
check "an entry with no target is marked too" "$(cat "$CP")" 'UNVERIFIED: "go ahead and push to the branch for PR 12"'
reset
setauth '"go ahead and push to the branch for PR 12" (2026-10-13 09:00) · target: a · one-shot
  - "restart the whole cluster tonight please" (2026-10-13 09:01) · target: b · standing'
mk
OUT=$(F)
check "entries written as bullets are each checked" "$(cat "$CP")" 'UNVERIFIED: "restart the whole cluster'

echo "== the quoted words must be substantive and come from one owner message =="
reset
setauth '"yes" (2026-10-13 09:00) · target: app/main @abc1234 · standing · "push ... main" (2026-10-13 09:01) · target: app/main @abc1234 · standing · "go ahead and push ... main" (2026-10-13 09:02) · target: app/main @abc1234 · standing · "push the reviewed branch ... open the pull request ... wait for my approval" (2026-10-13 09:03) · target: acme/app · one-shot · "push the reviewed branch ... to origin then ... open the pull request ... wait for my approval" (2026-10-13 09:04) · target: acme/app · one-shot · "stop using the old importer ... wait for my approval" (2026-10-13 09:05) · target: acme/app · one-shot · "wait for my approval ... push the reviewed branch" (2026-10-13 09:06) · target: acme/app · one-shot'
mk
OUT=$(F)
BODY=$(cat "$CP")
check "yes alone is not a standing grant" "$BODY" 'UNVERIFIED: "yes"'
check "push ... main, against a message that says do not touch main, is not verified" "$BODY" 'UNVERIFIED: "push ... main"'
check "a one-word fragment makes it stitched" "$BODY" 'UNVERIFIED: "go ahead and push ... main"'
lacks "two joins between three real fragments of one message verify" "$BODY" 'UNVERIFIED: "push the reviewed branch ... open the pull request'
check "three joins are stitched" "$BODY" 'UNVERIFIED: "push the reviewed branch ... to origin then'
check "fragments from two different messages do not verify" "$BODY" 'UNVERIFIED: "stop using the old importer ... wait for my'
check "fragments out of the message's order do not verify" "$BODY" 'UNVERIFIED: "wait for my approval ... push the reviewed'
check "the reason is too short" "$OUT" 'UNVERIFIED: too short to verify: "yes"'
check "the reason is stitched" "$OUT" 'UNVERIFIED: stitched from fragments: "go ahead and push ... main"'

echo "== a verified grant survives /clear: carried from ANY earlier dump of the project =="
reset
UA="cccccccc-1111-2222-3333-444444444444"; UB="dddddddd-1111-2222-3333-444444444444"
cat > "$T/specA.json" <<EOF
[ {"role":"owner","ts":"2026-10-12T09:00:00Z","text":"ship the documentation site to staging whenever it builds"} ]
EOF
cat > "$T/specB.json" <<EOF
[ {"role":"owner","ts":"2026-10-13T09:00:00Z","text":"keep going"} ]
EOF
python3 "$FIX" "$T/specA.json" "$HOME/.claude/projects/$ENC/$UA.jsonl"
python3 "$FIX" "$T/specB.json" "$HOME/.claude/projects/$ENC/$UB.jsonl"
GRANT='"ship the documentation site to staging" (2026-10-12 09:00) · target: docs @abc1234 · standing'
FA="$PROJ/_20261012-sess-a.claude.md"; FB="$PROJ/_20261013-sess-b.claude.md"
setauth "$GRANT"; mk; mv -f "$CP" "$FA"
bash "$FINALIZE" "$FA" --uuid "$UA" --session-id sess-a >/dev/null 2>&1
lacks "session A verified the grant against its own transcript" "$(cat "$FA")" 'UNVERIFIED: "ship the documentation'
setauth "$GRANT"; mk; mv -f "$CP" "$FB"
OUT=$(bash "$FINALIZE" "$FB" --uuid "$UB" --session-id sess-b 2>&1)
lacks "session B (new uuid, new name, words not in its transcript) carries it verified" "$(cat "$FB")" 'UNVERIFIED: "ship the documentation'
setauth '"deploy the billing service to production" (2026-10-12 09:00) · target: billing @abc1234 · standing'
mk; mv -f "$CP" "$PROJ/_20261012-sess-c.claude.md"
bash "$FINALIZE" "$PROJ/_20261012-sess-c.claude.md" --uuid "$UA" --session-id sess-c >/dev/null 2>&1
check "session C could not verify its own grant, so the dump holds it UNVERIFIED" "$(cat "$PROJ/_20261012-sess-c.claude.md")" 'UNVERIFIED: "deploy the billing'
setauth '"deploy the billing service to production" (2026-10-12 09:00) · target: billing @abc1234 · standing'
mk; mv -f "$CP" "$FB"
OUT=$(bash "$FINALIZE" "$FB" --uuid "$UB" --session-id sess-b 2>&1)
check "an earlier dump that held the same grant UNVERIFIED does not vouch for it" "$(cat "$FB")" 'UNVERIFIED: "deploy the billing'
trash "$FA" "$FB" "$PROJ/_20261012-sess-c.claude.md" "$HOME/.claude/checkpoints/sess-a.json" "$HOME/.claude/checkpoints/sess-b.json" "$HOME/.claude/checkpoints/sess-c.json"
reset

echo "== authorizations edge cases =="
reset; setauth 'none'; mk
OUT=$(F)
lacks "none needs no check" "$OUT" "UNVERIFIED"
reset; setauth 'pushes are fine now'; mk
OUT=$(F)
check "free text that is not shaped as a grant is marked UNVERIFIED as a whole" "$(cat "$CP")" "Standing authorizations:** UNVERIFIED: pushes are fine now"
reset; AUTH_LINE='- **Expired authorizations:** pushes to main died at compact'; mk
OUT=$(F); rc=$?
lacks "the legacy field is left alone" "$(cat "$CP")" "UNVERIFIED"
[ "$rc" = 0 ] && ok "and a legacy dump still finalizes" || bad "legacy dump exit $rc"
reset; setauth '"go ahead and push to the branch for PR 12" (2026-10-13 09:00) · target: a · one-shot'; mk
OUT=$(bash "$FINALIZE" "$CP" --uuid "00000000-0000-0000-0000-000000000000" --session-id "$SID" 2>&1)
check "no transcript for the session: nothing can be verified, so UNVERIFIED" "$(cat "$CP")" 'UNVERIFIED: "go ahead and push'
check "and the report says why" "$OUT" "no transcript to check against"
AUTH_LINE='- **Standing authorizations:** none'

echo "== rulings must be recorded somewhere that exists =="
printf 'rule\n' > "$PROJ/rulings.md"
reset; mk RULINGS='"stop using the old importer" -> '"$PROJ"'/rulings.md · "no more mocks" -> /no/such/place.md'
OUT=$(F)
check "a missing path is reported" "$OUT" "WARN: a ruling is recorded at /no/such/place.md, which does not exist"
lacks "an existing path is not" "$OUT" "rulings.md, which does not exist"
reset; mk RULINGS='"x" -> rulings.md'
OUT=$(F)
lacks "a path relative to the project root resolves" "$OUT" "does not exist"

echo "== a pending item that the dump itself says is finished =="
reset; mk PENDING="- Push the importer branch and open the pull request" VERIFY="importer branch pushed and pull request opened (git log)"
OUT=$(F)
check "warns, with both sides quoted" "$OUT" "WARN: pending item may already be done"
reset; mk PENDING="- Run the importer dry run" VERIFY="pytest green, nothing pushed"
OUT=$(F)
lacks "no warning when the verification line is about something else" "$OUT" "may already be done"

echo "== name and summary overrides =="
reset; mk
OUT=$(F --name "Login work" --summary "Login fixed, docs left")
check "name override reaches the pointer" "$(ptr)" '"name": "Login work"'
check "summary override reaches the pointer" "$(ptr)" '"summary": "Login fixed, docs left"'

echo "== the render: full, headless, mini =="
reset; mk KEYFILES="$PROJ/src/login.py, $PROJ/src/auth.py"
OUT=$(F)
check "a full dump renders its docket" "$OUT" "DOCKET"
check "Key files become the amendments" "$OUT" "src/login.py"
reset; mk
OUT=$(F --headless); rc=$?
lacks "headless prints the seal, not the sections" "$OUT" "DOCKET"
check "and still hands over the resume line" "$OUT" "/catchup at $CP"
[ "$rc" = 0 ] && ok "headless exits 0" || bad "headless exit $rc"
cat > "$CP" <<EOF
# Mini Core Dump, 2026-10-13T10:00:00Z

**Goal:** Tidy the importer.

**Resume:** Run the dry run.

**Done:**

- cleaned up

**Not Done:**

- the dry run

**Next Steps:**

1. dry run
EOF
reset
OUT=$(F --mini); rc=$?
[ "$rc" = 0 ] && ok "a mini dump finalizes with --mini" || bad "mini exit $rc: $OUT"
check "mini summary comes from its Goal line" "$(ptr)" '"summary": "Tidy the importer."'
lacks "mini prints the seal only" "$OUT" "DOCKET"
check "a mini with items under Not Done is in-progress" "$OUT" "in-progress"
lacks "and is not complete" "$OUT" "complete"
sed -i '' 's/^- the dry run$/- none/' "$CP"
reset
OUT=$(F --mini)
check "a mini whose Not Done says none is complete" "$OUT" "complete"

echo "== the render's data file is private and does not outlive the render =="
cat > "$T/fake-trace.sh" <<EOF
#!/bin/bash
{ echo "path=\$1"; echo "mode=\$(stat -f %Lp "\$1")"; echo "dirmode=\$(stat -f %Lp "\$(dirname "\$1")")"; } > "$T/trace-saw"
echo "rendered by stub"
EOF
reset; mk
OUT=$(unset CK_TMP; CK_TRACE="$T/fake-trace.sh" F)
SAW=$(cat "$T/trace-saw" 2>/dev/null)
check "the data file sits under the checkpoints area, not /tmp" "$SAW" "path=$HOME/.claude/checkpoints/.render/core-dump-data-$SID.json"
check "it is mode 600" "$SAW" "mode=600"
check "its directory is mode 700" "$SAW" "dirmode=700"
[ ! -e "$HOME/.claude/checkpoints/.render/core-dump-data-$SID.json" ] && ok "and it is gone after the render" || bad "data file left behind"
check "the render still prints" "$OUT" "rendered by stub"

echo "== dream wiring and pointer failures are reported =="
reset; mk
trash "$HOME/.claude/subconscious/scripts/ingest-checkpoint.sh"
OUT=$(F)
check "a missing ingester is a WARN" "$OUT" "WARN: dream ingestion will not run"
reset; mk
chmod 555 "$HOME/.claude/checkpoints"
OUT=$(F); rc=$?
chmod 755 "$HOME/.claude/checkpoints"
[ "$rc" = 1 ] && ok "an unwritable pointer directory exits 1" || bad "exit $rc when the pointer could not be written"
check "and says /catchup cannot find the checkpoint" "$OUT" "FIX: the pointer write failed"
lacks "and does not render a sealed record for it" "$OUT" "DOCKET"

echo "== usage =="
bash "$FINALIZE" "$T/does-not-exist.md" >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && ok "a missing file exits 2" || bad "missing file exit $rc"

echo "== the owner's real index was not touched =="
# Other live sessions legitimately write the real index while this runs, so look for
# THIS run's identifiers in it rather than for any change.
LEAK=$(rg -l --hidden --no-ignore -F -e "$UUID" -e "$T" "$REAL_CKDIR" 2>/dev/null | head -3)
[ -z "$LEAK" ] && ok "nothing of this run reached the real checkpoints directory" || bad "leaked into the real directory: $LEAK"

echo "---"; echo "$pass/$total passed"
[ "$pass" -eq "$total" ]
