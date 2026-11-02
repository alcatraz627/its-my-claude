#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Advice runs for a person's turn and stays out of headless runs and keep-warm pings,
# while safety guards hold everywhere. The shell and Python halves must agree.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d)
export KEEPWARM_WAKE_DIR="$T" HOOK_POPULATION_TEST=1 WARN_LOG_STORE="$T/w.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi; }
. "$D/hook-common.sh"

sh_run()  { ( export CLAUDE_CODE_ENTRYPOINT="$1" CLAUDE_CODE_SESSION_ID="$2"; hook_should_run "$3" && echo run || echo skip ); }
py_run()  { CLAUDE_CODE_ENTRYPOINT="$1" CLAUDE_CODE_SESSION_ID="$2" python3 -c "import sys; sys.path.insert(0, '$D'); import hookpop; print('run' if hookpop.should_run('$3') else 'skip')"; }
both() {  # both <label> <entry> <sid> <population> <want>
  check "shell: $1" "$(sh_run "$2" "$3" "$4")" "$5"
  check "python: $1" "$(py_run "$2" "$3" "$4")" "$5"
}

both "an interactive turn runs advice" cli sess1111 owner-turn run
both "a headless run skips advice" sdk-cli sess1111 owner-turn skip
both "the Python SDK counts as headless" sdk-py sess1111 owner-turn skip
both "a headless run still meets a no-wake gate" sdk-cli sess1111 no-wake run
touch "$T/claude-keepwarm-wake-wake2222"
both "a keep-warm ping skips advice" cli wake2222-rest-of-id owner-turn skip
both "a keep-warm ping skips a no-wake gate" cli wake2222-rest-of-id no-wake skip
both "another session's ping changes nothing" cli sess1111 owner-turn run
both "no session id still runs" cli "" owner-turn run

# A prompt nobody typed.
auto() { hook_is_automated_prompt "$1" && echo auto || echo human; }
pyauto() { python3 -c "import sys; sys.path.insert(0, '$D'); import hookpop; print('auto' if hookpop.is_automated_prompt(sys.argv[1]) else 'human')" "$1"; }
for p in "<task-notification>x" "[keepwarm] idle check" "[usage-resume] go" "  <system-reminder>y" "Stop hook feedback: z"; do
  check "shell: machine prompt '$p'" "$(auto "$p")" auto
  check "python: machine prompt '$p'" "$(pyauto "$p")" auto
done
for p in "fix the keepwarm hook" "why did [keepwarm] fail" "/core-dump" ""; do
  check "shell: typed prompt '$p'" "$(auto "$p")" human
  check "python: typed prompt '$p'" "$(pyauto "$p")" human
done

# The plan's proof, on the real gate: the same em-dash reply blocks only for a person.
# The gate blocks a given reply once per session, so each run needs its own id.
RUNSID="popt$$-$RANDOM"
REPLY=$(jq -cn --arg s "$RUNSID" --arg m "This is wrong — fix it." '{session_id:$s, stop_hook_active:false, last_assistant_message:$m, transcript_path:""}')
out=$(printf '%s' "$REPLY" | CLAUDE_CODE_ENTRYPOINT=cli CLAUDE_CODE_SESSION_ID="$RUNSID" bash "$D/format-gate-stop.sh")
check "format-gate blocks an em-dash in an interactive reply" "$(printf '%s' "$out" | jq -r '.decision // empty')" block
out=$(printf '%s' "$REPLY" | CLAUDE_CODE_ENTRYPOINT=sdk-cli CLAUDE_CODE_SESSION_ID=sess1111 bash "$D/format-gate-stop.sh")
check "format-gate is silent in a headless reply" "$out" ""
out=$(printf '%s' "$REPLY" | CLAUDE_CODE_ENTRYPOINT=cli CLAUDE_CODE_SESSION_ID=wake2222-rest bash "$D/format-gate-stop.sh")
check "format-gate is silent on a keep-warm ping" "$out" ""

# A prompt injector sees the same bytes after its guard reads stdin.
PROMPT=$(jq -cn '{session_id:"sess1111", prompt:"<task-notification>done", hook_event_name:"UserPromptSubmit"}')
out=$(printf '%s' "$PROMPT" | CLAUDE_CODE_ENTRYPOINT=cli CLAUDE_CODE_SESSION_ID=sess1111 bash "$D/persona-suggest.sh")
check "persona-suggest stays out of a task notification" "$out" ""
PROMPT=$(jq -cn '{session_id:"sess1111", prompt:"please plan the architecture of a large new system, weighing the design options", hook_event_name:"UserPromptSubmit"}')
out=$(printf '%s' "$PROMPT" | CLAUDE_CODE_ENTRYPOINT=cli CLAUDE_CODE_SESSION_ID=sess1111 bash "$HOME/.claude/scripts/hint-injector.sh")
printf '%s' "$PROMPT" | CLAUDE_CODE_ENTRYPOINT=sdk-cli CLAUDE_CODE_SESSION_ID=sess1111 bash "$HOME/.claude/scripts/hint-injector.sh" > "$T/headless.out"
check "hint-injector injects nothing headless" "$(wc -c < "$T/headless.out" | tr -d ' ')" 0

# Safety guards do not take part: each still denies with the headless entrypoint.
deny() {  # deny <label> <script> <command>
  local in code
  in=$(jq -cn --arg c "$3" '{tool_name:"Bash", tool_input:{command:$c}, session_id:"sess1111", cwd:"/tmp"}')
  out=$(printf '%s' "$in" | CLAUDE_CODE_ENTRYPOINT=sdk-cli CLAUDE_CODE_SESSION_ID=sess1111 bash "$2" 2>&1); code=$?
  if [ "$code" = 2 ] || printf '%s' "$out" | jq -e '(.decision == "block") or (.hookSpecificOutput.permissionDecision == "deny")' >/dev/null 2>&1; then
    ok "$1"
  else
    bad "$1 (exit $code: ${out:0:120})"
  fi
}
deny "safe-delete still denies under sdk-cli" "$HOME/.claude/scripts/safe-delete.sh" "rm -rf /tmp/nothing-here"
deny "guard-env-dump still denies under sdk-cli" "$D/guard-env-dump.sh" "printenv"
# The push gate reads the repo, and a policy may allow pushes here, so use a throwaway main.
git init -q -b main "$T/repo"
(cd "$T/repo" && git commit -q --allow-empty -m x)
mkdir -p "$T/home/.claude" "$T/bin"
printf '#!/bin/sh\necho DENY; exit 1\n' > "$T/bin/osascript"; chmod +x "$T/bin/osascript"
out=$(jq -nc --arg w "$T/repo" '{tool_input:{command:"git push origin main"}, cwd:$w}' \
  | HOME="$T/home" PATH="$T/bin:$PATH" CLAUDE_CODE_ENTRYPOINT=sdk-cli bash "$D/guard-git-push.sh" 2>/dev/null)
if [ -n "$out" ]; then ok "guard-git-push still gates under sdk-cli"; else bad "guard-git-push still gates under sdk-cli"; fi
deny "guard-anthropic-credentials still denies under sdk-cli" "$D/guard-anthropic-credentials.sh" "export ANTHROPIC_API_KEY=abc"
for s in safe-delete guard-env-dump guard-git-push guard-anthropic-credentials guard-secret-file-read guard-commit-signature; do
  f=$(ls "$HOME/.claude/scripts/$s.sh" "$D/$s.sh" 2>/dev/null | head -1)
  [ -n "$f" ] || continue
  if rg -q "hook_should_run|hookpop" "$f"; then bad "$s must not call the population check"; else ok "$s has no population check"; fi
done

trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
