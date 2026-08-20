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
jq -e '.set==true and .by=="catchup" and .text=="keep the lights on"' "$HOME/.claude/goals/$SID.json" >/dev/null && ok "file has text/by" || ko "file shape"
[ "$($G armline --sid $SID --cwd $CWD)" = "/goal keep the lights on" ] && ok "armline prefers the gcc goal" || ko "armline"
{ $G show --sid $SID --cwd $CWD || true; } | rg -q "harness /goal ARMED: second goal" && ok "show prints harness state" || ko "show harness"
$G clear --sid $SID >/dev/null; [ ! -f "$HOME/.claude/goals/$SID.json" ] && ok "clear removes the file" || ko "clear"
[ "$($G armline --sid $SID --cwd $CWD)" = "/goal second goal, with; punctuation" ] && ok "armline falls back to harness goal" || ko "armline fallback"
$G set "x" --sid $SID >/dev/null; { $G survey || true; } | rg -q "aaaaaaaa  by=agent" && ok "survey lists it" || ko "survey"
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
  $G set "$g" --sid $SID 2>&1 >/dev/null | rg -q "OWNER action" || { misses=$((misses+1)); echo "     miss: $g"; }
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
  $G set "$g" --sid $SID 2>&1 >/dev/null | rg -q "OWNER action" && { fires=$((fires+1)); echo "     false fire: $g"; }
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
armed=$($G armline --sid $SID 2>/dev/null)
echo "$armed" | rg -q "^/goal Take the owner" \
  && ok "armline still prints the paste line (warn, not block)" || ko "armline stopped printing"

export HOME="$HOME_REAL"; trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
