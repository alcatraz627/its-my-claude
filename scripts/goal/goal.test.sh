#!/usr/bin/env bash
# goal.test.sh — goal.sh reads the harness /goal from a transcript and keeps a gcc goal.
set -uo pipefail
G="$HOME/.claude/scripts/goal/goal.sh"; pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
T=$(mktemp -d); export HOME_REAL="$HOME"
# sandbox HOME so goals/ and projects/ are private to the test
export HOME="$T"; mkdir -p "$HOME/.claude/scripts/goal" "$HOME/.claude/goals"; cp "$G" "$HOME/.claude/scripts/goal/goal.sh"; G="$HOME/.claude/scripts/goal/goal.sh"
SID=aaaaaaaa-0000-0000-0000-000000000001; CWD=/Users/x/proj; PD="$HOME/.claude/projects/-Users-x-proj"; mkdir -p "$PD"; TR="$PD/$SID.jsonl"
line(){ printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":"%s"}}\n' "$1" "$2"; }
CMD='<command-name>/goal</command-name>\\n<command-message>goal</command-message>\\n<command-args>%s</command-args>'

echo "== harness read =="
: > "$TR"; { $G harness --sid $SID --cwd $CWD || true; } | jq -e '.armed==false' >/dev/null && ok "empty transcript: not armed" || ko "empty transcript"
line t1 "$(printf "$CMD" 'ship the deck')" >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.armed==true and .text=="ship the deck"' >/dev/null && ok "set is read back verbatim" || ko "set read"
line t2 'please note that /goal foo is not a command here' >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.text=="ship the deck"' >/dev/null && ok "quoted /goal in prose does not count" || ko "prose quote counted"
# The core-dump shape (adv-goal F1, 2026-09-05): a user turn that QUOTES the
# name tag in prose, with no args tag adjacent. The skill body does exactly this
# while documenting the parser, and a substring match on the tag recorded
# "clear" on every dump, erasing the fabad34c goal twice. The quote below has no
# adjacent <command-args>, so it must not count as an invocation.
line t2b 'goal.sh harness recovers it from the <command-name>/goal</command-name> blocks, so record what was SET' >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.armed==true and .text=="ship the deck"' >/dev/null && ok "a quoted name tag with no adjacent args does not disarm (the /core-dump shape)" || ko "core-dump shape disarmed the goal"
line t3 "$(printf "$CMD" 'clear')" >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.armed==false and (.reason|test("clear"))' >/dev/null && ok "clear disarms" || ko "clear"
line t4 "$(printf "$CMD" 'second goal, with; punctuation')" >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.text=="second goal, with; punctuation"' >/dev/null && ok "last set wins after a clear" || ko "last set"
# The cwd no longer decides whether the transcript is found. goal.sh resolves by
# SESSION ID across every project dir (a cwd-derived path first, as a fast path),
# because a session whose working surface differs from its start directory used
# to resolve a path that does not exist, and the silent miss read as "not armed"
# rather than "unknown" (automation-d8ff1149, 2026-08-19). These two rows used to
# assert rc 1 here, which pinned that bug: they asserted that a WRONG cwd hides a
# transcript that exists.
{ $G harness --sid $SID --cwd /Users/x/other || true; } | jq -e '.armed==true' >/dev/null \
  && ok "a wrong cwd still finds the transcript by session id" || ko "cross-project resolve"
{ $G harness --sid nosuchsession-0000 --cwd $CWD || true; } | jq -e '.reason|test("UNKNOWN")' >/dev/null \
  && ok "a genuinely missing transcript reports UNKNOWN, not 'not armed'" || ko "missing transcript wording"
# the three other shapes a set arrives in (gcp-fable, 2026-08-18: a mid-turn /goal was missed)
printf '{"type":"queue-operation","operation":"enqueue","timestamp":"t5","content":"Goal set: mid-turn goal"}\n' >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.armed==true and .text=="mid-turn goal" and .via=="queue"' >/dev/null && ok "mid-turn queue-operation 'Goal set:' counts" || ko "queue shape"
line t6 'A session-scoped Stop hook is now active with condition: \"active goal\". Briefly acknowledge the goal' >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.text=="active goal" and .via=="active"' >/dev/null && ok "'Stop hook is now active' injection counts" || ko "active shape"
line t7 '<local-command-stdout>Goal set: stdout goal</local-command-stdout>' >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.text=="stdout goal" and .via=="stdout"' >/dev/null && ok "local-command-stdout counts" || ko "stdout shape"
line t8 '<local-command-stdout>Goal cleared</local-command-stdout>' >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.armed==false' >/dev/null && ok "stdout 'Goal cleared' disarms" || ko "stdout clear"
printf '{"type":"user","timestamp":"t9","message":{"role":"user","content":[{"type":"tool_result","content":"<command-name>/goal</command-name> <command-args>quoted in a tool result</command-args>"}]}}\n' >> "$TR"
{ $G harness --sid $SID --cwd $CWD || true; } | jq -e '.armed==false' >/dev/null && ok "a /goal block inside a tool_result does not count" || ko "tool_result counted"
line t10 "$(printf "$CMD" 'second goal, with; punctuation')" >> "$TR"

echo "== gcc goal =="
# Same correction: this sid HAS a transcript with a goal in it, so "no goal
# anywhere" is no longer true from a different cwd. Use a sid that has neither.
$G show --sid nosuchsession-0000 --cwd /Users/x/other >/dev/null 2>&1; [ $? -eq 1 ] \
  && ok "no goal anywhere: rc 1" || ko "rc no goal"
$G set "keep the lights on" --by catchup --sid $SID --cwd $CWD >/dev/null && ok "set writes" || ko "set"
jq -e '.set==true and .via=="catchup" and .text=="keep the lights on"' "$HOME/.claude/goals/$SID.json" >/dev/null && ok "file has text/via" || ko "file shape"
[ "$($G armline --sid $SID --cwd $CWD)" = "/goal keep the lights on" ] && ok "armline prefers the gcc goal" || ko "armline"
{ $G show --sid $SID --cwd $CWD || true; } | rg -q "harness /goal ARMED: second goal" && ok "show prints harness state" || ko "show harness"
$G clear --sid $SID >/dev/null; [ ! -f "$HOME/.claude/goals/$SID.json" ] && ok "clear removes the file" || ko "clear"
[ "$($G armline --sid $SID --cwd $CWD)" = "/goal second goal, with; punctuation" ] && ok "armline falls back to harness goal" || ko "armline fallback"
$G set "x" --sid $SID >/dev/null; { $G survey || true; } | rg -q "by agent via [a-z-]+  :: x$" && ok "survey lists it with by and via" || ko "survey"
unset CLAUDE_CODE_SESSION_ID; $G show >/dev/null 2>&1; [ $? -eq 3 ] && ok "no sid: rc 3" || ko "no sid rc"

echo "== owner-actor clause warning (the six-stop jam, catch-r7-a3 2026-08-19) =="
JAM="Take the owner's board review of rounds 6 and 7, then apply the fixes"
err=$($G set "$JAM" --sid $SID 2>&1 >/dev/null)
echo "$err" | rg -q "names an OWNER action" && ok "the exact goal that jammed vb-fable is flagged" || ko "jamming goal not flagged"
echo "$err" | rg -q "Reword so the agent" && ok "the warning says what to do, not just what is wrong" || ko "warning gives no fix"
# Capture first, then match. Piping a script straight into `rg -q` under
# `set -o pipefail` fails even on a match: rg exits at the first hit and closes
# the pipe, the producer dies of SIGPIPE, and pipefail reports the pipeline as
# failed. The rows above escape it only because `echo` is a builtin.
shown=$($G show --sid $SID 2>/dev/null)
echo "$shown" | rg -q "board review" && ok "warn tier: the goal is still set (D2a)" || ko "warning blocked the set"

# Measured corpora, not a claim. The first glob-list cut of this matcher scored
# 7/20 recall and 5/7 precision under adversarial review; both corpora below are
# the evidence that the regex cut is better, and they fail loudly if it regresses.
misses=0
while IFS= read -r g; do
  err=$($G set "$g" --sid $SID 2>&1 >/dev/null); echo "$err" | rg -q "OWNER action" || { misses=$((misses+1)); echo "     miss: $g"; }
done <<'FIRE'
Take the owner's board review of rounds 6 and 7, then apply the fixes
Have the owner review the diff, then merge
Get approval from the owner and ship
Await the owner's ruling on the direction
Ship after you sign off
Take your review of the board and act on it
Wait for the owner to decide, then implement
Once the owner approves, roll it out
Finish the spec, pending the owner's verdict
Collect the owner's go-ahead before deploying
FIRE
[ "$misses" = 0 ] && ok "all 10 owner-actor phrasings fire" || ko "$misses of 10 owner-actor phrasings missed"

fires=0
while IFS= read -r g; do
  err=$($G set "$g" --sid $SID 2>&1 >/dev/null); echo "$err" | rg -q "OWNER action" && { fires=$((fires+1)); echo "     false fire: $g"; }
done <<'CLEAN'
draft the run-mode proposal and put it to the owner
land the rename after the owner-actor warning ships
fix batch H, then summarise for the owner
proceed with all, go with recommended, finish all, show me a summary
review the diff myself and fix what I find
build the owner dashboard page
pick the three highest-value tasks and do them
write the deck re-plan and file it for the owner to read later
CLEAN
[ "$fires" = 0 ] && ok "none of 8 agent-doable goals false-fires" || ko "$fires of 8 agent-doable goals false-fired"

# armline is the OTHER surface that hands the owner a goal to paste, so it warns too.
$G set "$JAM" --sid $SID >/dev/null 2>&1
$G armline --sid $SID 2>&1 >/dev/null | rg -q "names an OWNER action" \
  && ok "armline warns before the owner pastes it" || ko "armline hands over a jamming goal silently"

echo "== the register sees the shapes the owner rejected (adv-goal F2, 2026-09-05) =="
# Capture then match (SIGPIPE under pipefail, see above). Each FIRE case is a goal
# the owner or the rule file has named as wrong; each CLEAN case must stay silent.
lintq(){ $G lint "$1" 2>&1 >/dev/null; }
f2miss=0
while IFS= read -r g; do
  o=$(lintq "$g"); echo "$o" | rg -q "register finding" || { f2miss=$((f2miss+1)); echo "     silent: $g"; }
done <<'FIRE2'
Land migration 0057, fix resolve-store.sh, update REDESIGN.md, then rerun task.test.sh.
Close all three findings, ship the two fixes, and land the four renames.
Every row in every store renders without a lie.
No agent anywhere sees a broken render.
Level 4 is closed in the runner's own suite. Every one of the nine checks is proven by a planted defect that turns its test red and is then restored, not by inspection.
The task-table renderer draws the goal boxes, the rail, the continuability ball, and the CLEAR NOW band that REDESIGN.md rules. No column carries two traits.
FIRE2
[ "$f2miss" = 0 ] && ok "all 6 rejected shapes fire" || ko "$f2miss of 6 rejected shapes stayed silent"

f2false=0
while IFS= read -r g; do
  o=$(lintq "$g"); echo "$o" | rg -q "register finding" && { f2false=$((f2false+1)); echo "     false fire: $g"; }
done <<'CLEAN2'
A nontechnical teammate gets one real JEGS workbook through the console alone: upload, preview, run, read the results, export. No step needs me.
The runner suite is green at head. A caller key with no capability list shows up instead of failing silently. Keystore list and revoke both run from the CLI.
Every row in this store renders with its own ball.
One screen of /tasks tells the owner what he has to do today without a follow-up question.
CLEAN2
[ "$f2false" = 0 ] && ok "the owner's good goals stay clean (JEGS, the rule's After, a bounded set)" || ko "$f2false good goal(s) false-fired"

# Mutation: blind the filename detector in a COPY and the filename case must go
# silent. A guard that stays green with its detector removed tests the fixture.
MUTG="$HOME/.claude/scripts/goal/goal.mut.sh"; cp "$G" "$MUTG"
python3 - "$MUTG" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read()
s2=s.replace('names a file: a goal says what changes for the reader', 'MUTANT-DISABLED')
s2=s2.replace('if [[ "$t" =~ [a-z0-9_-]+\\.(md|sh|py|json|jsonl|ya?ml|tsx?|jsx?|toml|txt|html|css|svelte) ]]; then', 'if false; then')
assert s2!=s, "mutation anchor not found"; open(p,"w").write(s2)
PY
mo=$(bash "$MUTG" lint "Land migration 0057, fix resolve-store.sh, update REDESIGN.md, then rerun task.test.sh." 2>&1 >/dev/null)
echo "$mo" | rg -q "names a file" \
  && ko "FAILED GUARD: filename case passed with the detector removed" || ok "filename guard goes red under mutation"
trash "$MUTG" 2>/dev/null || true
armed=$($G armline --sid $SID 2>/dev/null)
echo "$armed" | rg -q "^/goal Take the owner" \
  && ok "armline still prints the paste line (warn, not block)" || ko "armline stopped printing"

echo "== A13: an unknown --via warns and WRITES (owner default, accepted 2026-09-05) =="
# Observed red before the fix: `goal.sh set … --via weirdvia` exited 2 and wrote
# nothing, while a bad goal text always wrote. Losing the goal is the one
# outcome the owner called unacceptable, so the severities invert here.
out=$($G set "via probe" --sid $SID --via weirdvia 2>&1); rc=$?
[ "$rc" = 0 ] && ok "unknown --via exits 0" || ko "unknown --via exit $rc"
echo "$out" | rg -q "not a known mechanism" && ok "and warns" || ko "no warning on unknown --via"
jq -e '.text=="via probe" and .via=="unknown"' "$HOME/.claude/goals/$SID.json" >/dev/null \
  && ok "the goal is written with via=unknown" || ko "goal not written, or via not recorded as unknown"

export HOME="$HOME_REAL"; trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
