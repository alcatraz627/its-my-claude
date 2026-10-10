#!/usr/bin/env bash
# The three first views over goal records built through gs in a sandbox HOME:
# the ruled shape is present, the height law holds on a big goal, and the
# mutation control (drop the gate) moves CLEAR NOW.
set -uo pipefail
SRC="$HOME/.claude/scripts/goals"; REAL="$HOME"
SB=$(mktemp -d "${TMPDIR:-/tmp}/views-home-XXXXXX")
mkdir -p "$SB/.claude/scripts/goals/views" "$SB/repo"
cp -f "$SRC/gs" "$SRC/goalstore.py" "$SRC/render.py" "$SB/.claude/scripts/goals/"
cp -f "$SRC"/views/*.py "$SB/.claude/scripts/goals/views/"
export HOME="$SB"; export CLAUDE_CODE_SESSION_ID="aaaaaaaa-1111-2222-3333-444444444444"
GS="$HOME/.claude/scripts/goals/gs"; V="$HOME/.claude/scripts/goals/views"
trap 'cp -f "$SB"/*.txt "${KEEP_DIR:-/dev/null}/" 2>/dev/null; export HOME="$REAL"; trash "$SB" 2>/dev/null || true' EXIT
pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }
git -C "$SB/repo" init -q 2>/dev/null; cd "$SB/repo" || exit 1

"$GS" new "The owner sees every decision they owe on one page" --accept "visual: the page shows all open decisions" --accept "reviewed: owner rules on it" >/dev/null 2>&1
G1=$(python3 -c "import sys;sys.path.insert(0,'$SRC');import goalstore as G;print(G.goal_id('The owner sees every decision they owe on one page'))")
"$GS" milestone "$G1" "DEC: the decisions group opens when any is pending" >/dev/null 2>&1
"$GS" task "$G1" m1 "Rule on the notes-and-asks redesign" --gate "rule on it" --do "open the decision page and rule" --lane owner --tier opus --kind decide --domain kanban >/dev/null 2>&1
"$GS" task "$G1" m1 "Force the Decisions group open when any decision is pending" --lane hands --tier sonnet --kind build --domain kanban >/dev/null 2>&1
"$GS" task "$G1" m1 "Board tab title carries the pending count" --lane hands --tier sonnet --kind build --domain kanban --blocked-by 2 >/dev/null 2>&1
"$GS" start "$G1" 2 >/dev/null 2>&1
export CLAUDE_CODE_SESSION_ID="bbbbbbbb-1111-2222-3333-444444444444"
"$GS" new "A person drives the job page end to end without stumbling" --accept "functional: a stranger completes a job unaided" >/dev/null 2>&1
G2=$(python3 -c "import sys;sys.path.insert(0,'$SRC');import goalstore as G;print(G.goal_id('A person drives the job page end to end without stumbling'))")
"$GS" milestone "$G2" "PARTS: the parts table loads with a skeleton" >/dev/null 2>&1
"$GS" task "$G2" m1 "Skeleton for the parts table while it loads" --lane hands --tier opus --kind ui --domain forge >/dev/null 2>&1
"$GS" review "$G2" 1 >/dev/null 2>&1
"$GS" note "$G2" 1 "PR open, awaiting a peer read" >/dev/null 2>&1
export CLAUDE_CODE_SESSION_ID="aaaaaaaa-1111-2222-3333-444444444444"

echo "── path ──"
python3 "$V/path.py" --boxed > "$SB/path.txt" 2>&1 || bad "path exited non-zero: $(head -3 "$SB/path.txt")"
rg -q "^TASKS  path" "$SB/path.txt" && ok "header" || bad "no header"
rg -q "armed, on the /goal line below|linked, no /goal armed" "$SB/path.txt" && ok "header says whether the goal is armed or only linked" || bad "armed marker missing"
rg -q "^/goal The owner sees every decision" "$SB/path.txt" && ok "the /goal paste line is whole at column 0" || bad "armline missing"
rg -q "2 goals, 0 met" "$SB/path.txt" && ok "goal count" || bad "goal count wrong: $(rg TASKS "$SB/path.txt")"
rg -q "✅ 0 of 3 accepted" "$SB/path.txt" && ok "acceptance meter in the header" || bad "acceptance meter missing"
rg -q "1 need you" "$SB/path.txt" && ok "gate count" || bad "gate count missing"
rg -q "⚡ CLEAR NOW   1 of 1 waiting on you, across 1 goal" "$SB/path.txt" && ok "CLEAR NOW band" || bad "CLEAR NOW missing"
rg -q "▸ do    open the decision page and rule" "$SB/path.txt" && ok "do-line under the gate" || bad "do-line missing"
rg -q "^╭▏─" "$SB/path.txt" && ok "goal box opens with the rule corner" || bad "no box corner"
rg -q "^╰▏" "$SB/path.txt" && ok "goal box closes" || bad "no closing corner"
rg -q "│  ▸ DEC: the decisions group" "$SB/path.txt" && ok "milestone band on the rail" || bad "milestone band missing"
rg -q "🔴 ! #1" "$SB/path.txt" && ok "gate row: red ball and ! twin" || bad "gate row glyphs wrong"
rg -q "🔵 ▶ #2" "$SB/path.txt" && ok "running row: blue ball and ▶ twin" || bad "running row glyphs wrong"
rg -q "🟠 ~ #3" "$SB/path.txt" && ok "blocked row: orange ball and ~ twin" || bad "blocked row glyphs wrong"
rg -q "◆ owner .*◇ opus .*▪ decide .*▫ kanban" "$SB/path.txt" && ok "one trait per column" || bad "trait line wrong: $(rg -m1 '◆' "$SB/path.txt")"
rg -q "after #2" "$SB/path.txt" && ok "blocked row names what it waits on" || bad "wait note missing"
rg -q "🟣 = #1" "$SB/path.txt" && ok "review row in the second goal" || bad "review row missing"
# The gate box renders first (ruling): the first box corner comes before the second goal's title
first=$(rg -n "The owner sees every decision they owe" "$SB/path.txt" | sed -n '2p' | cut -d: -f1)
second=$(rg -n "A person drives the job page" "$SB/path.txt" | head -1 | cut -d: -f1)
[ -n "$first" ] && [ -n "$second" ] && [ "$first" -lt "$second" ] && ok "the box holding a gate renders first" || bad "box order: gate box at $first, other at $second"
rg -q "A person drives the job page end to end without stumbling  ·  " "$SB/path.txt" && ok "a one-row goal draws no box (D3a): title carries the age" || bad "one-row goal boxed"
rg -q "🔴 needs you \(!\)" "$SB/path.txt" && ok "legend lists present states" || bad "legend missing"
rg -q "✅ done" "$SB/path.txt" && bad "legend lists a state not present" || ok "legend omits absent states"
rg -q "📝 1 handoff note\(s\) unread" "$SB/path.txt" && ok "unread notes announced, not rendered as rows" || bad "note announcement missing"
h=$(rg -o 'height ([0-9]+)/44' -r '$1' "$SB/path.txt" | head -1); n=$(wc -l < "$SB/path.txt" | tr -d ' ')
[ "$h" = "$n" ] && ok "footer height equals the actual line count ($n)" || bad "footer says $h, file has $n lines"


echo "── quiet (the default) ──"
python3 "$V/path.py" --quiet > "$SB/quiet.txt" 2>&1 || bad "quiet path exited: $(head -2 "$SB/quiet.txt")"
rg -q "^TASKS  2 goals · milestones 0/2 · accepted 0/3 · running 1 · needs you 1" "$SB/quiet.txt" && ok "quiet header: counts in words, no emoji" || bad "quiet header: $(head -1 "$SB/quiet.txt")"
rg -q "^NEEDS YOU  1" "$SB/quiet.txt" && ok "quiet: NEEDS YOU band" || bad "quiet: no NEEDS YOU"
rg -q "^    ! #1  Rule on the notes-and-asks redesign .*owner  opus  decide  kanban" "$SB/quiet.txt" && ok "quiet: one glyph per row, traits as plain words on the same line" || bad "quiet row: $(rg -m1 '#1' "$SB/quiet.txt")"
rg -q "🔴|🔵|🟠|🟣|◆|◇|▪|▫|╭|╰" "$SB/quiet.txt" && bad "quiet: a ball, marker or rail leaked" || ok "quiet: no balls, no trait markers, no rails"
n=$(wc -l < "$SB/quiet.txt" | tr -d ' '); b=$(wc -l < "$SB/path.txt" | tr -d ' ')
[ "$n" -lt "$b" ] && ok "quiet is shorter than boxed ($n vs $b lines)" || bad "quiet is not shorter ($n vs $b)"
echo "── now ──"
python3 "$V/now.py" > "$SB/now.txt" 2>&1
rg -q "⚡ CLEAR NOW   1 waiting on you" "$SB/now.txt" && ok "now: one gate" || bad "now wrong: $(cat "$SB/now.txt")"
rg -q "▸ do    open the decision page and rule" "$SB/now.txt" && ok "now: do-line" || bad "now: do-line missing"
python3 "$V/now.py" --goal "$G2" > "$SB/now2.txt" 2>&1
rg -q "nothing waits on you" "$SB/now2.txt" && ok "now: a goal with no gate says so in one line" || bad "now: $(cat "$SB/now2.txt")"

echo "── left ──"
python3 "$V/left.py" --goal "$G2" > "$SB/left.txt" 2>&1 || bad "left exited: $(head -3 "$SB/left.txt")"
rg -q "^LEFT  " "$SB/left.txt" && ok "left header" || bad "left header missing"
rg -q "◻︎ a1 functional +a stranger completes a job unaided.*unproven" "$SB/left.txt" && ok "left: acceptance row with evidence state first" || bad "left: acceptance missing: $(rg a1 "$SB/left.txt")"
rg -q "to met: 1 open row" "$SB/left.txt" && ok "left: containment names the open row" || bad "left: containment missing"
rg -q "📝 1: PR open, awaiting a peer read" "$SB/left.txt" && ok "left: unread note printed once" || bad "left: note missing"
python3 "$V/left.py" --goal "$G2" > "$SB/left2.txt" 2>&1
rg -q "📝" "$SB/left2.txt" && bad "left: note printed twice (not consumed)" || ok "left: note consumed on first read"
python3 "$V/left.py" > "$SB/left3.txt" 2>&1
rg -q "The owner sees every decision" "$SB/left3.txt" && ok "left with no --goal takes this session's goal" || bad "left: session goal not taken"
export CLAUDE_CODE_SESSION_ID="cccccccc-0000-0000-0000-000000000000"
if python3 "$V/left.py" > "$SB/left4.txt" 2>&1; then bad "left: a stranger session with no goal got an answer"; else rg -q "Name one" "$SB/left4.txt" && ok "left: stranger session refuses and lists goals" || bad "left: wrong refusal"; fi
export CLAUDE_CODE_SESSION_ID="aaaaaaaa-1111-2222-3333-444444444444"

echo "── the height law on a big goal ──"
"$GS" new "Sixty rows of forge work land" --accept "functional: x" --project "$SB/repo" >/dev/null 2>&1
G3=$(python3 -c "import sys;sys.path.insert(0,'$SRC');import goalstore as G;print(G.goal_id('Sixty rows of forge work land'))")
for m in 1 2 3; do "$GS" milestone "$G3" "STATE $m holds true" >/dev/null 2>&1; done
for i in $(seq 1 60); do "$GS" task "$G3" "m$(( (i % 3) + 1 ))" "Row number $i of the forge work with a longish subject" --lane hands --tier sonnet --kind build --domain forge >/dev/null 2>&1; done
python3 "$V/path.py" --boxed > "$SB/big.txt" 2>&1
n=$(wc -l < "$SB/big.txt" | tr -d ' '); [ "$n" -le 44 ] && ok "path on 63 open rows renders $n lines, within 44" || bad "height law broken: $n lines"
rg -q "row\(s\) not on screen" "$SB/big.txt" && ok "truncation is loud and names hidden ids" || bad "silent truncation"
rg -q "#1·" "$SB/big.txt" && ok "multi-goal view qualifies ids with the goal prefix" || bad "ids unqualified across goals"
python3 "$V/path.py" --boxed --detail > "$SB/bigd.txt" 2>&1
nd=$(wc -l < "$SB/bigd.txt" | tr -d ' '); [ "$nd" -gt 100 ] && ok "--detail prints every line ($nd)" || bad "--detail still capped at $nd"
python3 "$V/path.py" --json > "$SB/big.json" 2>&1
python3 -c "import json;j=json.load(open('$SB/big.json'));assert len(j['goals'])==3;assert 'containment' in j['goals'][0]" && ok "--json carries every goal with containment" || bad "--json malformed"


echo "── cards (the default since the 09-24 rulings) ──"
"$GS" task "$G2" m1 "Deploy the skeleton to preview and smoke it" --lane hands --tier sonnet >/dev/null 2>&1
"$GS" closure "$G2" 2 "preview deploy plus a smoke check" >/dev/null 2>&1
"$GS" task "$G1" m1 "Audit the decisions group for leaks" --lane hands --tier opus >/dev/null 2>&1
"$GS" delegate "$G1" 4 --to auditor-seat >/dev/null 2>&1
"$GS" task "$G1" m1 "Board tab title after the ruling lands" --lane hands --tier sonnet --blocked-by 1 >/dev/null 2>&1
python3 "$V/path.py" --cards > "$SB/cards.txt" 2>&1 || bad "cards exited: $(head -2 "$SB/cards.txt")"
rg -q "^TASKS  3 goals · rows 0/67 done · accepted 0/4 · stops 4" "$SB/cards.txt" && ok "cards header: rows done, accepted, stops" || bad "cards header: $(head -1 "$SB/cards.txt")"
rg -q "^┌ repo ── The owner sees every decision they owe on one page" "$SB/cards.txt" && ok "a frame per goal with the project word" || bad "no frame"
rg -q "to finish: 5 rows, 1 milestone, 2 acceptance rows · first stop: you at #1" "$SB/cards.txt" && ok "'to finish' sentence with the first stop" || bad "to-finish line: $(rg 'to finish' "$SB/cards.txt")"
python3 "$V/path.py" --cards --goal "$G1" > "$SB/cards-g1.txt" 2>&1
rg -q "^│ burst " "$SB/cards-g1.txt" && rg -q "^│ stop " "$SB/cards-g1.txt" && rg -q "^│ after " "$SB/cards-g1.txt" && ok "rows split burst / stop / after" || bad "segments missing"
rg -qF "… +1 row not on screen · /tasks left" "$SB/cards.txt" && ok "a card that cannot fit every row says so inside the frame" || bad "held-rows line missing"
rg -q "🏓 #1 Rule on the notes-and-asks redesign" "$SB/cards.txt" && ok "a gate is a 🏓 stop" || bad "gate glyph missing"
rg -q "🐱 #4 Audit the decisions group for leaks" "$SB/cards.txt" && ok "a delegated row is a 🐱 seat stop" || bad "seat glyph missing"
rg -q "🧷 #2 Deploy the skeleton to preview and smoke it" "$SB/cards.txt" && ok "closure pain is its own stop" || bad "closure glyph missing"
rg -q "↳ closure pain: preview deploy plus a smoke check" "$SB/cards.txt" && ok "the stop reason rides a second line" || bad "closure reason missing"
rg -q "^│ stop  you " "$SB/cards.txt" && ok "holder column appears on a multi-holder goal" || bad "holder column missing"
rg -q "🔵|🟠|🟣|🟢|🔴|◆|◇|▪|▫|╭|╰|▱" "$SB/cards.txt" && bad "cards: a ball, marker, rail or meter leaked" || ok "cards: colour only on stops"
rg -q "^│ ◻ visual     the page shows all open decisions" "$SB/cards.txt" && ok "acceptance checklist at the bottom of the card" || bad "acceptance missing"
python3 "$SRC/tests/framewidth.py" "$SB/cards.txt" > "$SB/widths.txt"
[ "$(wc -l < "$SB/widths.txt" | tr -d " ")" = 1 ] && ok "every framed line has the same width" || bad "ragged frame: $(sort -u "$SB/widths.txt" | tr '\n' ' ')"
python3 "$V/path.py" --cards --goal "$G3" > "$SB/cards-big.txt" 2>&1
rg -q "^│   st  id" "$SB/cards-big.txt" && ok "a goal with many rows draws the ledger table" || bad "ledger table missing on 60 rows"
n=$(wc -l < "$SB/cards-big.txt" | tr -d ' '); [ "$n" -le 44 ] && ok "cards on 60 rows render $n lines, within 44" || bad "height law broken: $n"

echo "── state-first (the default since the 09-24 evening read) ──"
python3 "$V/path.py" --state > "$SB/state.txt" 2>&1 || bad "state render exited: $(head -2 "$SB/state.txt")"
rg -q "^TASKS  3 goals · [0-9] waiting on you" "$SB/state.txt" && ok "state header counts goals by state" || bad "state header: $(head -1 "$SB/state.txt")"
rg -q "your move on [0-9]" "$SB/state.txt" && ok "header names whose move it is" || bad "no move line"
rg -q "^┌ repo · The owner sees every decision they owe on one page ─" "$SB/state.txt" && ok "frame carries the project and the short name, full width" || bad "frame top wrong"
rg -q "^│ waiting on you for [0-9]+m: 1 row; [0-9]+ more in flight for others" "$SB/state.txt" && ok "lead sentence: waiting on you, with the work in flight counted" || bad "lead wrong: $(rg -m1 'waiting on you' "$SB/state.txt")"
rg -q "then accept: 2 rows once the work is built" "$SB/state.txt" && ok "acceptance is not asked while rows are still open" || bad "acceptance asked too early"
n=$(wc -l < "$SB/state.txt" | tr -d ' '); [ "$n" -le 44 ] && ok "state render on 3 goals and 67 rows is $n lines, within 44" || bad "height law broken: $n"
python3 "$SRC/tests/framewidth.py" "$SB/state.txt" > "$SB/widths.txt"
[ "$(wc -l < "$SB/widths.txt" | tr -d ' ')" = 1 ] && ok "state frames are square" || bad "ragged: $(tr '\n' ' ' < "$SB/widths.txt")"
"$GS" close "$G2" 1 --by true >/dev/null 2>&1; "$GS" close "$G2" 2 --by true >/dev/null 2>&1
python3 "$V/path.py" --state --goal "$G2" > "$SB/state-built.txt" 2>&1
rg -q "^│ waiting on you for [0-9]+m: 1 acceptance row to accept" "$SB/state-built.txt" && ok "a built goal asks for acceptance in the lead" || bad "built lead: $(rg -m1 'waiting' "$SB/state-built.txt")"
rg -q "🏓 a1 try it and say it works: a stranger completes a job unaided" "$SB/state-built.txt" && ok "an unproven acceptance row is the ask, in the reader's verb" || bad "acceptance ask missing"
rg -q "built: 2 of 2 rows done" "$SB/state-built.txt" && ok "what happened is folded to one line" || bad "built line missing"

echo "── editorial (the default since the 09-24 night pick) ──"
python3 "$V/path.py" > "$SB/ed.txt" 2>&1 || bad "editorial exited: $(head -2 "$SB/ed.txt")"
rg -q "^Three goals\. [A-Z][a-z]+ (is|are) waiting on you\." "$SB/ed.txt" && ok "editorial header is a sentence" || bad "header: $(head -1 "$SB/ed.txt")"
rg -q "^│ 🏓 Rule on the notes-and-asks redesign: open the decision page and rule\." "$SB/ed.txt" && ok "a gate is a second-person ask" || bad "gate ask missing"
rg -q "rows the agent can take without stopping" "$SB/ed.txt" && ok "the burst is one sentence" || bad "burst sentence missing"
rg -q "#[0-9]" "$SB/ed.txt" && bad "editorial: a row id leaked" || ok "editorial: no row ids in the body"
python3 "$SRC/tests/framewidth.py" "$SB/ed.txt" > "$SB/widths.txt"
[ "$(wc -l < "$SB/widths.txt" | tr -d ' ')" = 1 ] && ok "editorial frames are square" || bad "ragged: $(tr '\n' ' ' < "$SB/widths.txt")"
n=$(wc -l < "$SB/ed.txt" | tr -d ' '); [ "$n" -le 44 ] && ok "editorial on 3 goals is $n lines, within 44" || bad "height law broken: $n"
echo "── mutation control ──"
"$GS" ungate "$G1" 1 >/dev/null 2>&1
python3 "$V/path.py" --boxed --goal "$G1" > "$SB/mut.txt" 2>&1
rg -q "CLEAR NOW" "$SB/mut.txt" && bad "MUTATION: gate removed, CLEAR NOW still renders" || ok "MUTATION: removing the gate removes CLEAR NOW"
rg -q "need you" "$SB/mut.txt" && bad "MUTATION: header still counts a gate" || ok "MUTATION: header gate count gone"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
