#!/usr/bin/env bash
# Tests for plan-gate-pre.sh (third-code-file dry-run check), plan-gate-ups.sh
# (build-prompt hint) and plan-signals.py (what counts as a plan or an exemption).
# Every exemption has a control: the same setup without it fires.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PRE="${PLAN_GATE_PRE:-$HERE/plan-gate-pre.sh}"
UPS="${PLAN_GATE_UPS:-$HERE/plan-gate-ups.sh}"
T=$(mktemp -d)
H="$T/home"; mkdir -p "$H/.claude" "$T/tasks" "$T/pins"
export WARN_LOG_STORE="$T/warn.jsonl"
export PLAN_GATE_TASKS_DIR="$T/tasks" PLAN_GATE_PINS_DIR="$T/pins"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-plan-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

SID="plangt01-aaaa-bbbb-cccc-dddddddddddd"; S8="plangt01"
fresh() { rm -rf "/tmp/claude-plan-gate-$S8" "/tmp/claude-plan-hint-$S8" "/tmp/claude-edited-files-$S8" "$T/tasks"/* "$T/pins"/*; : > "$WARN_LOG_STORE"; rm -f "$H/.claude/.no-plan-gate"; }
edited() { : > "/tmp/claude-edited-files-$S8"; for f in "$@"; do printf '%s\n' "$f" >> "/tmp/claude-edited-files-$S8"; done; }

# Transcript builders: tx <file> <prompt> [entrypoint] [sidechain]
tx() { jq -nc --arg p "$2" --arg e "${3:-cli}" --argjson s "${4:-false}" '{type:"user",entrypoint:$e,isSidechain:$s,message:{role:"user",content:$p}}' > "$1"; }
add_tool() { local inp="${3:-}"; [ -n "$inp" ] || inp='{}'; jq -nc --arg n "$2" --argjson i "$inp" '{type:"assistant",entrypoint:"cli",message:{role:"assistant",content:[{type:"tool_use",id:"x",name:$n,input:$i}]}}' >> "$1"; }
add_text() { jq -nc --arg t "$2" '{type:"assistant",entrypoint:"cli",message:{role:"assistant",content:[{type:"text",text:$t}]}}' >> "$1"; }
add_user() { jq -nc --arg p "$2" '{type:"user",entrypoint:"cli",isSidechain:false,message:{role:"user",content:$p}}' >> "$1"; }

A=/work/proj/src/a.py; B=/work/proj/src/b.py; C=/work/proj/src/c.py
pre() { # pre <transcript> <file> [tool] [extra jq filter]
  jq -nc --arg s "$SID" --arg tp "$1" --arg f "$2" --arg t "${3:-Edit}" '{session_id:$s,transcript_path:$tp,cwd:"/work/proj",tool_name:$t,tool_input:{file_path:$f}}' \
    | HOME="$H" bash "$PRE" 2>/dev/null
}
fires() { printf '%s' "$1" | jq -e '.systemMessage | test("plan-gate")' >/dev/null 2>&1; }
rows() { jq -r --arg a "$1" 'select(.hook_id=="plan-gate" and .action==$a) | .id' "$WARN_LOG_STORE" | wc -l | tr -d ' '; }

PLAIN="$T/plain.jsonl"; tx "$PLAIN" "please wire the new thing up across the code"

echo "== pre: the positive case =="
fresh; edited $A $B
out=$(pre "$PLAIN" $C)
fires "$out" && ok "third distinct code file with no plan: visible advisory" || bad "third file should advise: $out"
[ "$(rows block-dry)" = 1 ] && ok "a block-dry row is recorded" || bad "block-dry rows: $(rows block-dry)"
printf '%s' "$out" | jq -e '(has("decision") or (.hookSpecificOutput | has("permissionDecision"))) | not' >/dev/null && ok "never a deny" || bad "must not deny"
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse" and (.hookSpecificOutput.additionalContext | length > 0)' >/dev/null && ok "agent-visible additionalContext too" || bad "additionalContext missing"
out=$(pre "$PLAIN" $C); [ -z "$out" ] && ok "speaks once per session" || bad "second call must be silent"
[ "$(rows block-dry)" = 1 ] && ok "and records once" || bad "second row recorded"
fresh; edited $A; out=$(pre "$PLAIN" $B); [ -z "$out" ] && ok "second file: silent" || bad "second file must be silent"
fresh; edited $A $B; out=$(pre "$PLAIN" $A); [ -z "$out" ] && ok "re-editing a known file is not a third file" || bad "re-edit must be silent"
fresh; edited $A $B $C; out=$(pre "$PLAIN" /work/proj/src/d.py); [ -z "$out" ] && ok "a fourth file does not re-fire (only the third crossing does)" || bad "fourth file must be silent"
fresh; edited $A $B; out=$(pre "$PLAIN" $C Read); [ -z "$out" ] && ok "a Read is not an edit" || bad "Read must be silent"
fresh; edited $A $B; out=$(pre "$PLAIN" $C MultiEdit); fires "$out" && ok "MultiEdit counts" || bad "MultiEdit should fire"

echo "== pre: path exemptions (each with the control above) =="
for p in /work/proj/docs/guide.sh /work/proj/assets/reports/x.py /work/proj/notes/n.py /work/proj/src/a.test.py /work/proj/tests/helper.py /work/proj/tests.sh /private/tmp/claude-501/x/scratchpad/s.py /tmp/q.py /var/folders/zz/abc/T/q.py /work/proj/README.md /work/proj/src/data.json; do
  fresh; edited $A $B; out=$(pre "$PLAIN" "$p")
  [ -z "$out" ] && ok "not code, silent: $p" || bad "should be exempt: $p"
done
for nc in /work/proj/tests/t.py /private/tmp/s.py /var/folders/zz/abc/T/s.py /work/proj/README.md /work/proj/docs/d.py; do
  fresh; edited $A "$nc"; out=$(pre "$PLAIN" $B)
  [ -z "$out" ] && ok "a non-code file in the edit list does not count toward the three: $nc" || bad "non-code file counted toward the three: $nc"
done

echo "== pre: plan signals (each exempts; control fires) =="
sig() { # sig <label> <builder> ; builder gets the transcript path
  fresh; edited $A $B; local f="$T/sig.jsonl"; tx "$f" "please wire the new thing up across the code"; "$2" "$f"
  out=$(pre "$f" $C); [ -z "$out" ] && ok "plan signal: $1" || bad "plan signal ignored: $1 ($out)"
}
b_taskcreate() { add_tool "$1" TaskCreate '{"subject":"step one"}'; }
b_tasklist()   { add_tool "$1" TaskList; }
b_exitplan()   { add_tool "$1" ExitPlanMode; }
b_skill()      { add_tool "$1" Skill '{"skill":"bloop"}'; }
b_cmdname()    { add_user "$1" "<command-name>/build-change</command-name> add the thing"; }
b_planfile()   { add_tool "$1" Write '{"file_path":"/work/proj/docs/design-plan.md"}'; }
b_plantext()   { add_text "$1" $'Plan:\nread the module, change it'; }
b_steps()      { add_text "$1" $'I will do this:\n1. read\n2. change\n3. test'; }
sig "TaskCreate" b_taskcreate; sig "TaskList" b_tasklist; sig "ExitPlanMode" b_exitplan
sig "planning skill via Skill tool" b_skill; sig "planning skill via slash command" b_cmdname
sig "plan file written" b_planfile; sig "plan heading in assistant text" b_plantext; sig "three-step numbered list" b_steps
fresh; edited $A $B; mkdir -p "$T/tasks/session-$S8"; echo '{"id":"1","subject":"x","status":"pending"}' > "$T/tasks/session-$S8/1.json"
out=$(pre "$PLAIN" $C); [ -z "$out" ] && ok "plan signal: a task store on disk for this session" || bad "task store ignored"
fresh; edited $A $B; mkdir -p "$T/tasks/session-inherit1"; echo '{"id":"1","subject":"x","status":"pending"}' > "$T/tasks/session-inherit1/1.json"; echo inherit1 > "$T/pins/$S8"
out=$(pre "$PLAIN" $C); [ -z "$out" ] && ok "plan signal: a pinned (inherited) task store" || bad "pinned store ignored"

echo "== pre: session exemptions =="
ex() { # ex <label> <builder>
  fresh; edited $A $B; local f="$T/ex.jsonl"; tx "$f" "please wire the new thing up across the code"; "$2" "$f"
  out=$(pre "$f" $C); [ -z "$out" ] && ok "exempt: $1" || bad "not exempted: $1 ($out)"
}
e_resumed()  { add_user "$1" "<command-name>/catchup</command-name>"; }
e_revive()   { add_tool "$1" Skill '{"skill":"revive"}'; }
e_enum()     { add_user "$1" $'do these:\n1. rename x\n2. rename y\n3. rename z'; }
e_enum_bul() { add_user "$1" $'do these:\n- rename x\n- rename y\n- rename z'; }
e_enum_inl() { add_user "$1" "do these: 1) rename x 2) rename y 3) rename z"; }
ex "resumed via /catchup" e_resumed; ex "resumed via /revive" e_revive
ex "enumerated owner prompt (lines)" e_enum; ex "enumerated owner prompt (bullets)" e_enum_bul; ex "enumerated owner prompt (inline)" e_enum_inl
fresh; edited $A $B; f="$T/meta.jsonl"; tx "$f" "please wire the new thing up across the code"
jq -nc '{type:"user",entrypoint:"cli",isMeta:true,isSidechain:false,message:{role:"user",content:"Base directory for this skill: /x\n- one\n- two\n- three\n- four"}}' >> "$f"
out=$(pre "$f" $C); fires "$out" && ok "a skill body injected as a meta row is not the owner's list (still fires)" || bad "meta bullets wrongly exempted: $out"
fresh; edited $A $B; f="$T/hl.jsonl"; tx "$f" "please wire the new thing up across the code" sdk-cli; out=$(pre "$f" $C)
[ -z "$out" ] && ok "exempt: headless entrypoint" || bad "headless not exempted"
fresh; edited $A $B; f="$T/sc.jsonl"; tx "$f" "please wire the new thing up across the code" cli true; out=$(pre "$f" $C)
[ -z "$out" ] && ok "exempt: sidechain" || bad "sidechain not exempted"
fresh; edited $A $B; out=$(jq -nc --arg s "$SID" --arg tp "$PLAIN" --arg f "$C" '{session_id:$s,transcript_path:$tp,tool_name:"Edit",agent_id:"agent-7",tool_input:{file_path:$f}}' | HOME="$H" bash "$PRE" 2>/dev/null)
[ -z "$out" ] && ok "exempt: a sub-agent call (agent_id)" || bad "agent_id not exempted"
fresh; edited $A $B; out=$(pre "" $C); [ -z "$out" ] && ok "exempt: no transcript to judge by" || bad "missing transcript not exempted"
fresh; edited $A $B; touch "$H/.claude/.no-plan-gate"; out=$(pre "$PLAIN" $C); [ -z "$out" ] && ok "mute file silences it" || bad "mute ignored"
rm -f "$H/.claude/.no-plan-gate"
fresh; edited $A $B; out=$(jq -nc --arg s "$SID" --arg tp "$PLAIN" --arg f "$C" '{session_id:$s,transcript_path:$tp,tool_name:"Edit",tool_input:{file_path:$f}}' | PLAN_GATE_OFF=1 HOME="$H" bash "$PRE" 2>/dev/null)
[ -z "$out" ] && ok "PLAN_GATE_OFF=1 silences it" || bad "PLAN_GATE_OFF ignored"
out=$(printf '{}' | HOME="$H" bash "$PRE" 2>/dev/null); [ -z "$out" ] && ok "empty payload: silent" || bad "empty payload"

echo "== ups: the build-prompt hint =="
ups() { jq -nc --arg s "$SID" --arg p "$1" --arg tp "${2:-}" '{session_id:$s,hook_event_name:"UserPromptSubmit",prompt:$p,transcript_path:$tp}' | HOME="$H" bash "$UPS" 2>/dev/null; }
hint() { printf '%s' "$1" | jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit" and (.hookSpecificOutput.additionalContext | test("plan"))' >/dev/null 2>&1; }
BUILD="please add a new export endpoint to the api and wire it into the page"
fresh; out=$(ups "$BUILD" "$PLAIN")
hint "$out" && ok "build-shaped prompt, no plan: one hint line" || bad "should hint: $out"
printf '%s' "$out" | jq -e '(.hookSpecificOutput.additionalContext | contains("\n") | not) and (has("decision") | not)' >/dev/null && ok "single line, never blocks" || bad "hint shape"
out=$(ups "$BUILD" "$PLAIN"); [ -z "$out" ] && ok "speaks once per session" || bad "second hint"
fresh; out=$(ups "what does this module do and why is it shaped like that, explain it" "$PLAIN"); [ -z "$out" ] && ok "not a build: silent" || bad "non-build hinted"
fresh; out=$(ups "add a new api page" "$PLAIN"); [ -z "$out" ] && ok "too short: silent" || bad "short hinted"
fresh; out=$(ups "/bloop add a new export endpoint to the api and page" "$PLAIN"); [ -z "$out" ] && ok "slash command: silent" || bad "slash hinted"
fresh; out=$(ups "please fix the typo in the sentence that says teh quick brown" "$PLAIN"); [ -z "$out" ] && ok "verb without a multi-file noun: silent" || bad "verb-only hinted"
uh() { # uh <label> <builder>: transcript with an exemption or plan signal
  fresh; local f="$T/uh.jsonl"; tx "$f" "$BUILD"; "$2" "$f"; out=$(ups "$BUILD" "$f"); [ -z "$out" ] && ok "silent: $1" || bad "hinted despite $1"
}
uh "Task list already exists" b_taskcreate; uh "planning skill active" b_skill; uh "plan text posted" b_plantext
uh "resumed session" e_resumed; uh "enumerated owner prompt" e_enum
fresh; f="$T/uh2.jsonl"; tx "$f" "$BUILD" sdk-cli; out=$(ups "$BUILD" "$f"); [ -z "$out" ] && ok "silent: headless" || bad "headless hinted"
fresh; mkdir -p "$T/tasks/session-$S8"; echo '{"id":"1","subject":"x","status":"pending"}' > "$T/tasks/session-$S8/1.json"
out=$(ups "$BUILD" "$PLAIN"); [ -z "$out" ] && ok "silent: task store on disk" || bad "store ignored by ups"
fresh; out=$(ups $'add a new thing across the files:\n1. alpha\n2. beta\n3. gamma' "$PLAIN"); [ -z "$out" ] && ok "silent: this prompt is itself an enumerated list" || bad "enumerated current prompt hinted"
fresh; touch "$H/.claude/.no-plan-gate"; out=$(ups "$BUILD" "$PLAIN"); [ -z "$out" ] && ok "mute file silences the hint" || bad "ups mute ignored"
rm -f "$H/.claude/.no-plan-gate"
fresh; out=$(jq -nc --arg s "$SID" --arg p "$BUILD" --arg tp "$PLAIN" '{session_id:$s,prompt:$p,transcript_path:$tp}' | PLAN_GATE_OFF=1 HOME="$H" bash "$UPS" 2>/dev/null); [ -z "$out" ] && ok "PLAN_GATE_OFF=1 silences the hint" || bad "ups OFF ignored"
fresh; ups "$BUILD" "$PLAIN" >/dev/null
[ "$(jq -r 'select(.hook_id=="plan-gate-ups" and .action=="nudge") | .id' "$WARN_LOG_STORE" | wc -l | tr -d ' ')" = 1 ] && ok "the hint is logged as a nudge" || bad "nudge row missing"

fresh
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
