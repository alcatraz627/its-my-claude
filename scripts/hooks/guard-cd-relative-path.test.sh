#!/usr/bin/env bash
# guard-cd-relative-path.test.sh — the guard catches the reported shape and stays
# quiet on everything else.
#
# The quiet cases carry equal weight here, on purpose. A false block stalls the
# lane in exactly the way the permission dialog does, so a guard that over-fires
# has not fixed the problem, it has moved it. Every "stays quiet" case below is a
# command a working agent legitimately issues.
#
# Run: bash ~/.claude/scripts/hooks/guard-cd-relative-path.test.sh
set -uo pipefail

G="$HOME/.claude/scripts/hooks/guard-cd-relative-path.sh"
pass=0; fail=0

# fires <label> <command>   — expects a block
fires(){
  local out
  out=$(jq -cn --arg c "$2" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$G" 2>/dev/null)
  if printf '%s' "$out" | rg -q '"decision":"block"'; then pass=$((pass+1));
  else fail=$((fail+1)); echo "  FAIL (should block): $1"; echo "        cmd: $2"; fi
}
# quiet <label> <command>   — expects no block
quiet(){
  local out
  out=$(jq -cn --arg c "$2" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$G" 2>/dev/null)
  if printf '%s' "$out" | rg -q '"decision":"block"'; then
    fail=$((fail+1)); echo "  FAIL (should stay quiet): $1"; echo "        cmd: $2";
  else pass=$((pass+1)); fi
}
says(){   # says <label> <command> <substring the reason must contain>
  local out
  out=$(jq -cn --arg c "$2" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$G" 2>/dev/null)
  if printf '%s' "$out" | rg -q -- "$3"; then pass=$((pass+1));
  else fail=$((fail+1)); echo "  FAIL: $1 — reason lacks [$3]"; fi
}

echo "── the reported shape, verbatim from forge-brains msg-33af190e195248fd ──"
fires "cd then rg on a relative dir" \
  "cd /Users/alcatraz627/Code/Versable/speedway && rg -n 'pattern' app/"
fires "cd then rg on a relative file" \
  "cd /Users/alcatraz627/Code/Versable/speedway && rg -n 'x' app/lib/modules/content.server.ts"
fires "semicolon instead of &&" \
  "cd /Users/alcatraz627/Code/Versable/gcp; cat docs/plan.md"
fires "a pipe still counts as a separator" \
  "cd /tmp && cat logs/out.txt | head"
fires "./ prefixed path is just as unresolvable" \
  "cd /tmp && rg -n 'x' ./src/app.ts"

echo "── the block hands back a command the agent can retry with ──"
says "it names the offending argument" \
  "cd /Users/alcatraz627/Code/Versable/speedway && rg -n 'x' app/" \
  'app/'
says "it offers the joined absolute path" \
  "cd /Users/alcatraz627/Code/Versable/speedway && rg -n 'x' app/" \
  '/Users/alcatraz627/Code/Versable/speedway/app/'
says "it says the cd was never needed" \
  "cd /tmp && cat logs/out.txt" \
  'working directory persists'

echo "── no cd, so the harness can resolve it: stay quiet ──"
quiet "a relative path on its own is fine" \
  "rg -n 'pattern' app/lib/thing.ts"
quiet "a relative path with a pipe but no cd" \
  "cat logs/out.txt | head -5"
quiet "a bare cd with nothing after it" \
  "cd /Users/alcatraz627/Code/Versable/gcp"

echo "── absolute paths after a cd are exactly what we asked for: stay quiet ──"
quiet "absolute path after a cd" \
  "cd /tmp && rg -n 'x' /Users/alcatraz627/.claude/rules/shell.md"
quiet "tilde path after a cd" \
  "cd /tmp && cat ~/.claude/CLAUDE.md"

echo "── things that look like paths but are not ──"
quiet "an rg pattern containing a slash, quoted" \
  "cd /tmp && rg -n 'foo/bar' /abs/path.txt"
quiet "a flag value is not a path" \
  "cd /tmp && rg --glob=*.ts -n 'x' /abs/dir"
quiet "a variable we cannot judge is left alone" \
  "cd /tmp && cat \$HOME/notes.txt"
# Both of these must exercise the SANITISER, not merely fail to match. An
# earlier pair used `git commit -m '…'` and a heredoc whose body began with
# prose; git is not a path-taking command and the prose line is not at a command
# position, so both stayed quiet with the sanitiser bypassed and proved nothing.
# Mutation-testing the guard is what surfaced that: bypassing strip-payloads.py
# turned only one of the three quiet cases red.
quiet "a heredoc body holding a real command is not executed" \
  "cd /tmp && cat <<'EOF'
rg -n 'x' app/lib/thing.ts
EOF"
quiet "a relative path inside a quoted message argument" \
  "cd /tmp && python3 /abs/script.py --note 'writes to app/out.json'"

echo "── the guard only judges Bash ──"
out=$(jq -cn '{tool_name:"Read", tool_input:{command:"cd /tmp && cat a/b.txt"}}' | bash "$G" 2>/dev/null)
if printf '%s' "$out" | rg -q '"decision":"block"'; then
  fail=$((fail+1)); echo "  FAIL: fired on a non-Bash tool"
else pass=$((pass+1)); fi

echo "── the mute file opens the gate ──"
MUTE="$HOME/.claude/.no-cd-relpath-guard"
had_mute=0; [ -f "$MUTE" ] && had_mute=1
touch "$MUTE"
out=$(jq -cn --arg c "cd /tmp && rg -n 'x' app/" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$G" 2>/dev/null)
if printf '%s' "$out" | rg -q '"decision":"block"'; then
  fail=$((fail+1)); echo "  FAIL: mute file did not open the gate"
else pass=$((pass+1)); fi
[ "$had_mute" = 0 ] && rm -f "$MUTE"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
