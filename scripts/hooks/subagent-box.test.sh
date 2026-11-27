#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# subagent-box.test.sh: a dispatch or landing is a header line led by its emoji
# plus labelled lines that each carry their own emoji, nothing is clipped, a
# landing reaches the model once, stop-only strays are ledgered but never
# injected, and three or more seats sent together share one fleet notice at
# dispatch and one at landing. BX=<path> points the suite at a mutated copy.
set -uo pipefail
REAL="$HOME"
BX="${BX:-$REAL/.claude/scripts/hooks/subagent-box.sh}"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

SID="boxtest$$x"; S8="${SID:0:8}"
T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude"
ln -s "$REAL/.claude/scripts" "$T/.claude/scripts"
# Lone-seat cases first: no two dispatches may join a batch.
export SUBAGENT_BURST_GAP=-1
ev(){ bash "$BX" | jq -r '[.systemMessage // empty, .hookSpecificOutput.additionalContext // empty] | join("\n")'; }
rows(){ printf '%s\n' "$1" | rg -v '^─{10}$' | rg -c '\S'; }
# Every notice closes with a ten-character rule.
ruled(){ [ "$(printf '%s\n' "$1" | rg -v '^Subagent landing' | rg -v '^ *$' | tail -n 1)" = "──────────" ]; }
# Every line of a notice opens with an emoji, the header's or its label's.
emoji_led(){ printf '%s\n' "$1" | rg -v '^ *$|^─{10}$' | rg -v '^(🛫|🛬|   (🎯|📄|🔹|✅|❌|⏳) )|^ {12}\S|^Subagent landing' | rg -c . || echo 0; }
# A SubagentStop hook's output reaches nobody, so a landing box waits for the next prompt.
land(){ printf "$1" "$SID" | bash "$BX" >/dev/null; cat "/tmp/claude-agentbox-$S8/pending-boxes"; }

d=$(printf '{"hook_event_name":"PreToolUse","session_id":"%s","tool_name":"Agent","tool_input":{"subagent_type":"general-purpose","model":"sonnet","description":"audit hooks","prompt":"Audit every hook."}}' "$SID" | ev)
n=$(rows "$d")
[ "$n" = 2 ] && ok "a short dispatch is two lines" || ko "dispatch is $n lines: $d"
printf '%s\n' "$d" | rg -q "^   🎯 goal  audit hooks: Audit every hook\.$" && ok "the goal line carries its own emoji" || ko "goal lost: $d"
printf '%s\n' "$d" | rg -q "^🛫 general-purpose  sonnet$" && ok "the header leads with the emoji and spaced fields" || ko "header: $d"
printf '%s' "$d" | rg -q "[│┌└]" && ko "the dispatch still draws rails: $d" || ok "no rails"
ruled "$d" && ok "a dispatch closes with a ten-dash rule" || ko "no closing rule: $d"
raw=$(printf '{"hook_event_name":"PreToolUse","session_id":"%s","tool_name":"Agent","tool_input":{"subagent_type":"general-purpose","model":"sonnet","description":"channel check","prompt":"x"}}' "$SID" | bash "$BX")
printf '%s' "$raw" | jq -e '.systemMessage | test("^🛫")' >/dev/null && ok "the line goes straight to the owner's screen" || ko "line not in systemMessage: $raw"
printf '%s' "$raw" | jq -e 'has("hookSpecificOutput") | not' >/dev/null && ok "and the model does not read it" || ko "box reached the model: $raw"
sed -i '' '$d' "/tmp/claude-agentbox-$S8/dispatch-queue"

printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"ag1","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
l=$(land '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"ag1","agent_type":"general-purpose"}')
n=$(rows "$l")
[ "$n" = 1 ] && ok "a landing with no output file is one line" || ko "landing is $n lines: $l"
printf '%s\n' "$l" | rg -q "^🛬 general-purpose  audit hooks  ran [0-9]+s$" && ok "the landing header names the seat and its run" || ko "landing header: $l"
printf '%s' "$l" | rg -q "report is data" && ko "landing box still has the long reminder" || ok "landing reminder line dropped"

printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"stray1","agent_type":"x"}' "$SID" | bash "$BX" >/dev/null
printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"stray2","agent_type":"x"}' "$SID" | bash "$BX" >/dev/null
u=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | ev)
printf '%s' "$u" | rg -q "unmatched" && ko "unmatched line reached the model: $u" || ok "no unmatched line in the drain"
printf '%s' "$u" | rg -q "verify each agent" && ok "the verify duty stays outside the box" || ko "verify duty lost"
c=$(wc -l < "/tmp/claude-agentbox-$S8/unmatched.log" | tr -d ' ')
[ "$c" = "2" ] && ok "strays are still ledgered ($c rows)" || ko "stray ledger rows=$c"
u=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | ev)
[ -z "$u" ] && ok "second drain with nothing new is silent" || ko "second drain spoke: $u"

# A seated prompt: the header line is metadata, the goal is the prose after it,
# shown whole, and the landing names the goal and whether the file was written.
OUTF="$T/seat-out.md"
long="Review the decision page composer against the golden fixture and report every string that differs, with the config, the state, the expected string and the composed string, plus a guess at the cause for each one you find"
jq -cn --arg sid "$SID" --arg p "[seat s-20261026-101010-abcd] role=reviewer model=sonnet output=$OUTF
$long" '{hook_event_name:"PreToolUse",session_id:$sid,tool_name:"Agent",tool_input:{subagent_type:"general-purpose",model:"sonnet",description:"golden review",prompt:$p}}' > "$T/pre.json"
d=$(ev < "$T/pre.json")
printf '%s' "$d" | rg -q "s-20261026-101010-abcd" && ok "dispatch names the seat id" || ko "seat id missing: $d"
printf '%s' "$d" | rg -q "🎯 goal  golden review: Review the decision" && ok "the goal skips the header line" || ko "header leaked into goal: $d"
printf '%s' "$d" | rg -q "for each one you find$" && ok "a long goal is shown whole" || ko "a long goal was cut: $d"
printf '%s' "$d" | rg -q "…" && ko "the goal still carries a cut mark: $d" || ok "no cut mark"
wide=$(printf '%s\n' "$d" | python3 -c 'import sys,unicodedata as u
print(max(sum(2 if u.east_asian_width(c) in "WF" else 0 if c=="️" else 1 for c in l) for l in sys.stdin.read().splitlines()))')
[ "$wide" -le 84 ] && ok "a long goal wraps inside 84 columns ($wide)" || ko "a line runs to $wide columns"
printf '%s\n' "$d" | rg -q "^ {12}fixture" && ok "the wrapped goal hangs under its own text" || ko "wrap indent: $d"
[ "$(emoji_led "$d")" = "0" ] && ok "every dispatch line is emoji-led or a hanging wrap" || ko "unled line: $d"
# A composed seat's brief has a goal section; that section is the goal, not the persona.
jq -cn --arg sid "$SID" --arg p "[seat s-compose-1] role=reviewer output=$T/c.md

# Who you are
You are a reviewer seat, called because: check it.

# The goal
Check the parser against the fixtures.

# What we already know
Nothing." '{hook_event_name:"PreToolUse",session_id:$sid,tool_name:"Agent",tool_input:{subagent_type:"general-purpose",model:"sonnet",description:"parse check",prompt:$p}}' > "$T/composed.json"
c=$(ev < "$T/composed.json")
printf '%s\n' "$c" | rg -q "^   🎯 goal  parse check: Check the parser against the fixtures\.$" && ok "a composed brief's goal section is the goal" || ko "composed goal: $c"
sed -i '' '$d' "/tmp/claude-agentbox-$S8/dispatch-queue"
printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"ag2","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
l=$(land '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"ag2","agent_type":"general-purpose"}')
printf '%s' "$l" | rg -q "^🛬 general-purpose  golden review  ran [0-9]+s  ❌ output NOT written" && ok "landing names the goal and the missing file" || ko "missing file not flagged: $l"
printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | bash "$BX" >/dev/null
d=$(ev < "$T/pre.json"); echo "done" > "$OUTF"
printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"ag3","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
l=$(land '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"ag3","agent_type":"general-purpose"}')
printf '%s' "$l" | rg -q "✅ output written" && ok "landing says the file was written" || ko "written file not shown: $l"
printf '%s\n' "$l" | rg -qxF "   📄 out   $OUTF" && ok "the path gets its own emoji line, whole" || ko "out line: $l"
n=$(rows "$l"); [ "$n" = 2 ] && ok "the landing is two lines" || ko "landing grew to $n lines"
[ "$(emoji_led "$l")" = "0" ] && ok "every landing line is emoji-led" || ko "unled line: $l"
ruled "$l" && ok "a landing closes with a ten-dash rule" || ko "no closing rule: $l"
printf '%s' "$l" | rg -q "ran [0-9]+s" && ok "a short run shows seconds, not 0m" || ko "duration: $l"
printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | bash "$BX" >/dev/null

# A batch: three dispatches together share one fleet box, and their landings
# fill in one fleet landing box.
jq -cn --arg sid "$SID" --arg p "[seat s-fleettest-9] role=reader output=$T/x.md
Read one file." '{hook_event_name:"PreToolUse",session_id:$sid,tool_name:"Agent",tool_input:{subagent_type:"general-purpose",model:"haiku",description:"named seat",prompt:$p}}' > "$T/named.json"
d=$(ev < "$T/named.json")
printf '%s' "$d" | rg -q "role=reader" && ko "a lettered seat id leaked its header into the goal: $d" || ok "a lettered seat id is read as a seat"

# A batch: three dispatches together share one fleet box, and their landings
# fill in one fleet landing box. No seat has an estimate here (empty cache).
echo '{}' > "$T/est.json"; export SEAT_COST_CACHE="$T/est.json"
export SUBAGENT_BURST_GAP=20
: > "/tmp/claude-agentbox-$S8/burst"
: > "/tmp/claude-agentbox-$S8/dispatch-queue"
mkdir -p "$T/out"
for k in 1 2 3; do
  jq -cn --arg sid "$SID" --arg p "[seat s-1-$k] output=$T/out/seat$k.md
Do part $k." --arg d "part $k" \
    '{hook_event_name:"PreToolUse",session_id:$sid,tool_name:"Agent",tool_input:{subagent_type:"general-purpose",model:"sonnet",description:$d,prompt:$p}}' > "$T/f$k.json"
  f=$(ev < "$T/f$k.json")
done
printf '%s' "$f" | rg -q "^🛫 fleet  3 seats" && ok "the third dispatch shows one fleet notice" || ko "no fleet notice: $f"
[ "$(printf '%s\n' "$f" | rg -c '^   🔹 [123]  sonnet  part [123]$')" = "3" ] && ok "one aligned line per seat, empty columns dropped" || ko "fleet rows: $f"
printf "%s" "$f" | rg -q "Surface this box|surface only" && ko "the box still asks the model to retype it: $f" || ok "nothing asks the model to retype a box"
printf '%s' "$f" | rg -q 'est ~' && ko "a fleet with no estimates claims one: $f" || ok "a fleet with no estimates shows no total"
echo x > "$T/out/seat1.md"; echo x > "$T/out/seat2.md"
for k in 1 2 3; do printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"fa%s","agent_type":"general-purpose"}' "$SID" "$k" | bash "$BX" >/dev/null; done
printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"fa1","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
u=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | ev)
printf '%s' "$u" | rg -q "^🛬 fleet  1 of 3 back" && ok "a partial landing shows how many are back" || ko "partial landing: $u"
[ "$(printf '%s\n' "$u" | rg -c '⏳ [23]')" = "2" ] && ok "seats still out show as waiting" || ko "waiting rows: $u"
printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"fa2","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"fa3","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
u=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | ev)
[ "$(printf '%s\n' "$u" | rg -c '🛬 fleet')" = "1" ] && ok "two landings drain as one updated fleet box" || ko "fleet boxes drained: $u"
printf '%s' "$u" | rg -q "^🛬 fleet  all 3 back" && ok "the last landing says all are back" || ko "all back: $u"
printf '%s' "$u" | rg -q "❌ 3 .*part 3 \(no output written\)" && ok "a seat that wrote nothing is marked" || ko "missing output: $u"
printf '%s\n' "$u" | rg -qxF "   📄 out   $T/out/" && ok "a shared output folder prints once, on its own line" || ko "output folder: $u"
cols=$(printf '%s\n' "$u" | rg '^   [✅❌] ' | python3 -c 'import sys; print(len({l.index("part") for l in sys.stdin}))')
[ "$cols" = "1" ] && ok "the fleet's description column lines up" || ko "fleet columns drift: $u"
[ "$(emoji_led "$u")" = "0" ] && ok "every fleet line is emoji-led" || ko "unled line: $u"
ruled "$u" && ok "a fleet landing closes with a ten-dash rule" || ko "no closing rule: $u"
ruled "$f" && ok "a fleet dispatch closes with a ten-dash rule" || ko "no closing rule: $f"

export HOME="$REAL"; trash "$T" "/tmp/claude-agentbox-$S8" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
