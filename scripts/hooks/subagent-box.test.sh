#!/usr/bin/env bash
# subagent-box.test.sh: the dispatch and landing boxes carry a two-line body at
# most, a landing reaches the model once, and stop-only strays are ledgered but
# never injected. BX=<path> points the suite at a mutated copy.
set -uo pipefail
REAL="$HOME"
BX="${BX:-$REAL/.claude/scripts/hooks/subagent-box.sh}"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

SID="boxtest$$x"; S8="${SID:0:8}"
T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude"
ln -s "$REAL/.claude/scripts" "$T/.claude/scripts"
ev(){ bash "$BX" | jq -r '(.hookSpecificOutput.additionalContext // empty)'; }
body_lines(){ printf '%s\n' "$1" | rg -c '^│'; }

d=$(printf '{"hook_event_name":"PreToolUse","session_id":"%s","tool_name":"Agent","tool_input":{"subagent_type":"general-purpose","model":"sonnet","description":"audit hooks","prompt":"Audit every hook."}}' "$SID" | ev)
n=$(body_lines "$d")
[ "$n" -le 2 ] && ok "dispatch box body is $n lines" || ko "dispatch box body is $n lines"
printf '%s' "$d" | rg -q "goal: audit hooks" && ok "dispatch box still names the goal" || ko "goal lost: $d"
printf '%s' "$d" | rg -q "landing box will follow" && ko "dispatch box still has the arrow line" || ok "dispatch arrow line dropped"

printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"ag1","agent_type":"general-purpose"}' "$SID" | bash "$BX" >/dev/null
l=$(printf '{"hook_event_name":"SubagentStop","session_id":"%s","agent_id":"ag1","agent_type":"general-purpose"}' "$SID" | ev)
n=$(body_lines "$l")
[ "$n" -le 2 ] && ok "landing box body is $n line(s)" || ko "landing box body is $n lines"
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

export HOME="$REAL"; trash "$T" "/tmp/claude-agentbox-$S8" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
