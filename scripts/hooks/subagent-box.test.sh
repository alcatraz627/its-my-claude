#!/usr/bin/env bash
# subagent-box.test.sh: a lone dispatch or landing carries at most two rows, a
# landing reaches the model once, stop-only strays are ledgered but never
# injected, and three or more seats sent together share one fleet box at
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
ev(){ bash "$BX" | jq -r '(.hookSpecificOutput.additionalContext // empty)'; }
rows(){ printf '%s\n' "$1" | rg -c '^│  \S'; }

d=$(printf '{"hook_event_name":"PreToolUse","session_id":"%s","tool_name":"Agent","tool_input":{"subagent_type":"general-purpose","model":"sonnet","description":"audit hooks","prompt":"Audit every hook."}}' "$SID" | ev)
n=$(rows "$d")
[ "$n" -le 2 ] && ok "dispatch box is $n rows" || ko "dispatch box is $n rows"
printf '%s' "$d" | rg -q "🔵 goal +audit hooks" && ok "dispatch box names the goal" || ko "goal lost: $d"
printf '%s' "$d" | rg -q "subagent · general-purpose .* sonnet" && ok "the header carries the model" || ko "model missing: $d"

printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"ag1","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
l=$(printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"ag1","agent_type":"general-purpose"}' "$SID" | ev)
n=$(rows "$l")
[ "$n" -le 2 ] && ok "landing box is $n row(s)" || ko "landing box is $n rows"
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
# cut at a word, and the landing names the goal and whether the file was written.
OUTF="$T/seat-out.md"
long="Review the decision page composer against the golden fixture and report every string that differs, with the config, the state, the expected string and the composed string, plus a guess at the cause for each one you find"
jq -cn --arg sid "$SID" --arg p "[seat s-20261026-101010-abcd] role=reviewer model=sonnet output=$OUTF
$long" '{hook_event_name:"PreToolUse",session_id:$sid,tool_name:"Agent",tool_input:{subagent_type:"general-purpose",model:"sonnet",description:"golden review",prompt:$p}}' > "$T/pre.json"
d=$(ev < "$T/pre.json")
printf '%s' "$d" | rg -q "s-20261026-101010-abcd" && ok "dispatch names the seat id" || ko "seat id missing: $d"
printf '%s' "$d" | rg -q "goal +golden review: Review the decision" && ok "the goal skips the header line" || ko "header leaked into goal: $d"
printf '%s' "$d" | rg -q "for each one you find" && ko "a long goal was not cut" || ok "a long goal is cut"
printf '%s' "$d" | rg -q " …" && ok "the cut is marked" || ko "no cut mark: $d"
printf '%s' "$d" | rg -q "[a-z]{2,} …" && ok "the cut lands after a whole word" || ko "cut mid-word: $d"
printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"ag2","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
l=$(printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"ag2","agent_type":"general-purpose"}' "$SID" | ev)
printf '%s' "$l" | rg -q "🔴 goal +golden review · output NOT written" && ok "landing names the goal and the missing file" || ko "missing file not flagged: $l"
printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | bash "$BX" >/dev/null
d=$(ev < "$T/pre.json"); echo "done" > "$OUTF"
printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"ag3","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
l=$(printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"ag3","agent_type":"general-purpose"}' "$SID" | ev)
printf '%s' "$l" | rg -q "🟢 goal +golden review · output written" && ok "landing says the file was written" || ko "written file not shown: $l"
printf '%s\n' "$l" | rg -qxF "$OUTF" && ok "the path sits bare on its own line" || ko "path not bare: $l"
n=$(rows "$l"); [ "$n" -le 2 ] && ok "the landing is at most 2 rows" || ko "landing grew to $n rows"
printf '%s' "$l" | rg -q "ran [0-9]+s" && ok "a short run shows seconds, not 0m" || ko "duration: $l"
printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | bash "$BX" >/dev/null

# A batch: three dispatches together share one fleet box, and their landings
# fill in one fleet landing box.
export SUBAGENT_BURST_GAP=20
: > "/tmp/claude-agentbox-$S8/burst"
mkdir -p "$T/out"
for k in 1 2 3; do
  jq -cn --arg sid "$SID" --arg p "[seat s-1-$k] output=$T/out/seat$k.md
Do part $k." --arg d "part $k" \
    '{hook_event_name:"PreToolUse",session_id:$sid,tool_name:"Agent",tool_input:{subagent_type:"general-purpose",model:"sonnet",description:$d,prompt:$p}}' > "$T/f$k.json"
  f=$(ev < "$T/f$k.json")
done
printf '%s' "$f" | rg -q "🛫 fleet · 3 seats" && ok "the third dispatch shows one fleet box" || ko "no fleet box: $f"
[ "$(printf '%s\n' "$f" | rg -c '^│  🔵 [123] +sonnet ')" = "3" ] && ok "the fleet box lists all three seats" || ko "fleet rows: $f"
printf '%s' "$f" | rg -q "replaces the separate dispatch boxes" && ok "it tells the agent to show only the fleet box" || ko "no replace note: $f"
echo x > "$T/out/seat1.md"; echo x > "$T/out/seat2.md"
for k in 1 2 3; do printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"fa%s","agent_type":"general-purpose"}' "$SID" "$k" | bash "$BX" >/dev/null; done
printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"fa1","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
u=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | ev)
printf '%s' "$u" | rg -q "🛬 fleet · 1 of 3 back" && ok "a partial landing shows how many are back" || ko "partial landing: $u"
[ "$(printf '%s\n' "$u" | rg -c '⏳ [23]')" = "2" ] && ok "seats still out show as waiting" || ko "waiting rows: $u"
printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"fa2","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"fa3","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
u=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"go"}' "$SID" | ev)
[ "$(printf '%s\n' "$u" | rg -c '🛬 fleet')" = "1" ] && ok "two landings drain as one updated fleet box" || ko "fleet boxes drained: $u"
printf '%s' "$u" | rg -q "🛬 fleet · all 3 back" && ok "the last landing says all are back" || ko "all back: $u"
printf '%s' "$u" | rg -q "🔴 3 .*part 3 \(no output written\)" && ok "a seat that wrote nothing is red" || ko "missing output: $u"
printf '%s\n' "$u" | rg -qxF "$T/out/" && ok "a shared output folder prints once, bare" || ko "output folder: $u"

export HOME="$REAL"; trash "$T" "/tmp/claude-agentbox-$S8" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
