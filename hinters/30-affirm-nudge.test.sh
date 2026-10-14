#!/usr/bin/env bash
# 30-affirm-nudge.test.sh: the affirm nudge fires once per session, only after a
# turn that changed a file, and again after /clear.
# H=<path> points the suite at a mutated copy of the hinter.
set -uo pipefail
REAL="$HOME"
H="${H:-$REAL/.claude/hinters/30-affirm-nudge.sh}"
RESET="$REAL/.claude/scripts/session-mgmt/post-clear-counter-reset.sh"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude/atone"
ln -s "$REAL/.claude/scripts" "$T/.claude/scripts"

u(){ jq -nc --arg t "$1" '{type:"user",message:{role:"user",content:$t}}'; }
a_tool(){ jq -nc --arg n "$1" '{type:"assistant",message:{role:"assistant",content:[{type:"tool_use",name:$n,input:{}}]}}'; }
a_text(){ jq -nc --arg t "$1" '{type:"assistant",message:{role:"assistant",content:[{type:"text",text:$t}]}}'; }
res(){ jq -nc '{type:"user",message:{role:"user",content:[{type:"tool_result",content:"ok"}]}}'; }

EDIT="$T/edit.jsonl"; NOEDIT="$T/noedit.jsonl"; INLOG="$T/inlog.jsonl"
{ u "fix the bug"; a_tool Edit; res; a_text "fixed"; } > "$EDIT"
{ u "what is the bug"; a_tool Read; res; a_text "it is a typo"; } > "$NOEDIT"
{ u "fix the bug"; a_tool Write; res; a_text "fixed"; u "good call on that"; } > "$INLOG"

fire(){ printf '%s' "$3" | env CLAUDE_HINT_SID="$1" AFFIRM_TRANSCRIPT="$2" bash "$H"; }
has(){ printf '%s' "$1" | rg -q "affirm-nudge"; }

has "$(fire sessAAAA1 "$NOEDIT" "good call on that")" && ko "fired after a turn that changed nothing" || ok "silent after a turn that changed nothing"
has "$(fire sessAAAA1 "$EDIT" "good call on that")" && ok "fires after an edit turn (a no-edit miss did not use up the once)" || ko "silent after an edit turn"
has "$(fire sessAAAA1 "$EDIT" "perfect, exactly")" && ko "second nudge in the same session" || ok "silent on the second affirmation of the session"
has "$(fire sessBBBB2 "$EDIT" "nice catch there")" && ok "a new session fires again" || ko "new session silent"
has "$(fire sessCCCC3 "$INLOG" "good call on that")" && ok "works when the current prompt is already in the transcript" || ko "silent with prompt in transcript"
has "$(fire sessDDDD4 "$EDIT" "please run the tests")" && ko "fired on a non-affirming prompt" || ok "silent when the prompt does not affirm"
printf '{"source":"clear","session_id":"sessBBBB2"}' | bash "$RESET"
has "$(fire sessBBBB2 "$EDIT" "good call on that")" && ok "after /clear the nudge may fire again" || ko "silent after clear"
has "$(fire sessEEEE5 "$T/missing.jsonl" "good call on that")" && ko "fired with no transcript" || ok "no transcript: quiet"

export HOME="$REAL"; trash "$T" "/tmp/claude-clear-reset-sessBBBB" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
