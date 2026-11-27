#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Suite for guard-pr-title-tags.sh: a `gh pr create` or `gh pr edit --title`
# whose title lacks the repo's required tags is rewritten to carry them (the
# whole rewritten command is checked, and the title is read back through a
# stand-in gh to prove the shell passes it intact); a command whose title cannot
# be rewritten safely is refused with the corrected title and the override; a
# leading PR_TITLE_TAGS_OFF=1 lets one gh command through untouched; a repo's own
# PR-TITLE-TAGS line beats the default. GUARD_UNDER_TEST points it at a mutated
# copy (the copy must sit in scripts/hooks/ so it finds shell-scan.py).
set -uo pipefail
HOOK="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/guard-pr-title-tags.sh}"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

ROOT=$(mktemp -d "${TMPDIR:-/tmp}/prtags.XXXXXX")
trap 'trash "$ROOT" 2>/dev/null || true' EXIT
export GUARD_PR_TAGS_CODE_ROOT="$ROOT/Code"
# The title step calls models; every case here uses a stand-in tool. The default one
# writes no title, so the tag cases below see the agent's title untouched.
printf '#!/usr/bin/env python3\nimport sys\nsys.exit(3)\n' > "$ROOT/no-title.py"
printf '#!/usr/bin/env python3\nimport json, sys\nopen(sys.argv[0] + ".called", "a").write(" ".join(sys.argv[1:]) + "\\n")\nprint(json.dumps({"title": "fix(llm): add model id to the cache key", "shape_ok": True}))\n' > "$ROOT/good-title.py"
export PR_TITLE_TOOL="$ROOT/no-title.py"

mkrepo() { # name origin-slug [claude-md-text]
  local d="$ROOT/Code/Versable/$1"
  mkdir -p "$d"
  git -C "$d" init -q 2>/dev/null
  git -C "$d" remote add origin "git@github.com:$2.git" 2>/dev/null
  [ -n "${3:-}" ] && printf '%s\n' "$3" > "$d/CLAUDE.md"
  return 0
}
mkrepo versable-foundry versable-git/versable-foundry
mkrepo walmart-mvp versable-git/walmart-mvp
mkrepo speedway versable-git/speedway "Some prose about PRs, no directive."
mkrepo strict-repo versable-git/strict-repo "PR-TITLE-TAGS: [noslack] [nobot]"
mkrepo quiet-repo versable-git/quiet-repo "PR-TITLE-TAGS: none"
mkrepo fill-repo versable-git/fill-repo "PR-TITLE-TAGS: [noslack] allow-fill"
FOUNDRY="$ROOT/Code/Versable/versable-foundry"

out_of() { jq -nc --arg c "$1" --arg d "$2" '{tool_name:"Bash", tool_input:{command:$c}, cwd:$d}' | bash "$HOOK" 2>/dev/null; }
blocked() { # cmd cwd expected-substring-in-reason
  local o; o=$(out_of "$1" "$2")
  if [ "$(printf '%s' "$o" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" = deny ] && [ -n "$(printf '%s' "$o" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -F -- "$3")" ]; then ok "REFUSED: ${1:0:60} -> has: $3"
  else bad "not refused or reason lacks '$3': ${1:0:70} :: ${o:0:120}"; fi
}
allowed() {
  local o; o=$(out_of "$1" "$2")
  [ -z "$o" ] && ok "allow: ${1:0:70}" || bad "changed or blocked (should pass untouched): ${1:0:70} :: ${o:0:120}"
}
rewrote() { # cmd cwd expected-whole-new-command
  local o dec new ctx
  o=$(out_of "$1" "$2")
  dec=$(printf '%s' "$o" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)
  new=$(printf '%s' "$o" | jq -r '.hookSpecificOutput.updatedInput.command' 2>/dev/null)
  ctx=$(printf '%s' "$o" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)
  if [ "$dec" = allow ] && [ "$new" = "$3" ] && [[ "$ctx" == *"PR_TITLE_TAGS_OFF=1"* ]]; then ok "REWRITTEN: ${1:0:60} -> ${3:0:60}"
  else bad "want rewrite to '$3' naming the override, got decision='$dec' command='$new' :: ${o:0:160}"; fi
}
# The title argument gh would receive after the shell reads the rewritten command (a stand-in gh prints its arguments).
title_seen() { # cmd cwd expected-title
  local o new got
  o=$(out_of "$1" "$2")
  new=$(printf '%s' "$o" | jq -r '.hookSpecificOutput.updatedInput.command' 2>/dev/null)
  got=$(bash -c 'gh() { while [ $# -gt 0 ]; do case "$1" in --title|-t) printf "%s" "$2"; return;; --title=*) printf "%s" "${1#--title=}"; return;; esac; shift; done; }
eval "$1"' _ "$new" 2>/dev/null)
  if [ "$got" = "$3" ]; then ok "title passes intact: $3"
  else bad "title after the shell reads the rewrite: '$got', want '$3' (command: $new)"; fi
}

echo "== 23 Oct 2026 versable-foundry commands (real, from session e815d840)"
BODY=/private/tmp/x/scratchpad/pr-wm-preview-body.md
rewrote "gh pr create -R versable-git/walmart-mvp --base feat/ingest-service --head feat/preview-envs --title \"Preview environments that follow their branch\" --body-file $BODY" "$FOUNDRY" "gh pr create -R versable-git/walmart-mvp --base feat/ingest-service --head feat/preview-envs --title '[noslack] Preview environments that follow their branch' --body-file $BODY"
rewrote "gh pr create -R versable-git/speedway --base development --head feat/preview-workflow --title \"Previews that follow their branch, and kit installs without a personal token\" --body-file $BODY" "$FOUNDRY" "gh pr create -R versable-git/speedway --base development --head feat/preview-workflow --title '[noslack] Previews that follow their branch, and kit installs without a personal token' --body-file $BODY"
allowed "gh pr create -R versable-git/walmart-mvp --base feat/ingest-service --head feat/preview-envs --title \"[noslack] Preview environments that follow their branch\" --body-file $BODY" "$FOUNDRY"
allowed "gh pr create -R versable-git/speedway --base development --head feat/preview-workflow --title \"[noslack] Previews that follow their branch\" --body-file $BODY" "$FOUNDRY"

echo "== spellings, flags, cwd"
allowed 'gh pr create -t "[no-slack] a thing" --body-file b' "$FOUNDRY"
allowed 'gh pr create --title="[NoSlack] a thing" --body-file b' "$FOUNDRY"
rewrote 'gh pr create -t "a thing" --body-file b' "$FOUNDRY" "gh pr create -t '[noslack] a thing' --body-file b"
rewrote 'gh pr create --title="a thing"' "$FOUNDRY" "gh pr create --title='[noslack] a thing'"
rewrote "cd $FOUNDRY && gh pr create --title t" "$ROOT" "cd $FOUNDRY && gh pr create --title '[noslack] t'"
rewrote 'gh -R versable-git/walmart-mvp pr create --title t' "$ROOT" "gh -R versable-git/walmart-mvp pr create --title '[noslack] t'"
rewrote "gh pr create --title 't' # trailing note" "$FOUNDRY" "gh pr create --title '[noslack] t' # trailing note"

echo "== the rewritten title reaches gh exactly as written"
title_seen 'gh pr create --title "It'"'"'s a thing"' "$FOUNDRY" "[noslack] It's a thing"
title_seen "gh pr create --title 'costs \$5 and \`ls\`'" "$FOUNDRY" '[noslack] costs $5 and `ls`'
title_seen 'gh pr create --title "say \"hi\" now"' "$FOUNDRY" '[noslack] say "hi" now'
title_seen 'gh pr create --title="spaced   out"' "$FOUNDRY" '[noslack] spaced   out'
title_seen 'gh pr create --title "Caf'$'\303\251'' au lait"' "$FOUNDRY" "[noslack] Caf$(printf '\303\251') au lait"

echo "== gh pr edit: only a title change is judged"
rewrote 'gh pr edit 12 --title "Renamed"' "$FOUNDRY" "gh pr edit 12 --title '[noslack] Renamed'"
allowed 'gh pr edit 12 --title "[noslack] Renamed"' "$FOUNDRY"
allowed 'gh pr edit 12 --add-label x' "$FOUNDRY"
allowed 'gh pr edit 12 --body-file b' "$FOUNDRY"

echo "== two gh commands in one call are both fixed"
rewrote 'gh pr create --title a --body-file b && gh pr edit 3 --title "b c"' "$FOUNDRY" "gh pr create --title '[noslack] a' --body-file b && gh pr edit 3 --title '[noslack] b c'"

echo "== the rest of the tool input is kept"
o=$(jq -nc --arg d "$FOUNDRY" '{tool_name:"Bash", tool_input:{command:"gh pr create --title t", description:"open it", timeout:90000, run_in_background:false}, cwd:$d}' | bash "$HOOK" 2>/dev/null)
kept=$(printf '%s' "$o" | jq -c '.hookSpecificOutput.updatedInput | [.description, .timeout, .run_in_background]' 2>/dev/null)
[ "$kept" = '["open it",90000,false]' ] && ok "description, timeout and run_in_background survive the rewrite" || bad "other fields lost: $kept"

echo "== --fill"
blocked 'gh pr create --fill' "$FOUNDRY" 'takes the title from the commit message'
blocked 'gh pr create --fill' "$FOUNDRY" 'PR_TITLE_TAGS_OFF=1 gh pr create'
allowed 'gh pr create --fill --title "[noslack] x"' "$FOUNDRY"
allowed 'gh pr create --fill' "$ROOT/Code/Versable/fill-repo"
allowed 'gh pr create --fill' "$ROOT/Code/Versable/quiet-repo"

echo "== a title the hook cannot read exactly is refused with the fix, never guessed"
blocked 'gh pr create --title "$T" --body-file b' "$FOUNDRY" '--title "[noslack] $T"'
blocked 'gh pr create --title "$(git log -1 --format=%s)"' "$FOUNDRY" 'cannot be rewritten safely'
blocked "bash -c 'gh pr create --title t'" "$FOUNDRY" '--title "[noslack] t"'
blocked 'gh pr create --title "$T"' "$FOUNDRY" 'PR_TITLE_TAGS_OFF=1'

echo "== one-call override"
allowed 'PR_TITLE_TAGS_OFF=1 gh pr create --title "No tag wanted" --body-file b' "$FOUNDRY"
allowed 'env PR_TITLE_TAGS_OFF=1 gh pr create --title "No tag wanted"' "$FOUNDRY"
allowed 'PR_TITLE_TAGS_OFF=1 gh pr create --fill' "$FOUNDRY"
allowed 'PR_TITLE_TAGS_OFF=1 gh pr create --title "$T"' "$FOUNDRY"
rewrote 'PR_TITLE_TAGS_OFF=0 gh pr create --title t' "$FOUNDRY" "PR_TITLE_TAGS_OFF=0 gh pr create --title '[noslack] t'"
rewrote 'PR_TITLE_TAGS_OFF=1 gh pr view 1 && gh pr create --title t' "$FOUNDRY" "PR_TITLE_TAGS_OFF=1 gh pr view 1 && gh pr create --title '[noslack] t'"
rewrote 'echo PR_TITLE_TAGS_OFF=1 && gh pr create --title t' "$FOUNDRY" "echo PR_TITLE_TAGS_OFF=1 && gh pr create --title '[noslack] t'"

echo "== a repo's own rule wins over the default"
rewrote 'gh pr create --title "[noslack] only" --body-file b' "$ROOT/Code/Versable/strict-repo" "gh pr create --title '[nobot] [noslack] only' --body-file b"
rewrote 'gh pr create -R versable-git/strict-repo --title "[noslack] only"' "$FOUNDRY" "gh pr create -R versable-git/strict-repo --title '[nobot] [noslack] only'"
allowed 'gh pr create --title "[noslack] [nobot] both" --body-file b' "$ROOT/Code/Versable/strict-repo"
allowed 'gh pr create --title "No tag at all"' "$ROOT/Code/Versable/quiet-repo"
allowed 'gh pr create -R versable-git/quiet-repo --title "No tag at all"' "$FOUNDRY"
rewrote 'gh pr create --title "No tag at all"' "$ROOT/Code/Versable/speedway" "gh pr create --title '[noslack] No tag at all'"
o=$(out_of 'gh pr create --title "No tag at all"' "$ROOT/Code/Versable/speedway")
[[ "$(printf '%s' "$o" | jq -r '.hookSpecificOutput.additionalContext')" == *"the default rule"* ]] \
  && ok "the note says why the tag was added" || bad "rewrite note lacks the rule source: ${o:0:160}"

echo "== unrelated commands and mentions pass"
allowed 'gh pr view 12' "$FOUNDRY"
allowed 'gh pr list' "$FOUNDRY"
allowed 'gh pr create' "$FOUNDRY"
allowed 'echo "run gh pr create --title t later"' "$FOUNDRY"
allowed 'git commit -m "docs: gh pr create --title usage"' "$FOUNDRY"
allowed 'gh issue create --title "no tag needed"' "$FOUNDRY"
allowed "cat > /tmp/t.sh <<'EOF'
gh pr create --title t
EOF" "$FOUNDRY"

echo "== the machine-wide mute still works"
mkdir -p "$ROOT/home/.claude"
touch "$ROOT/home/.claude/.no-pr-title-tags-gate"
o=$(jq -nc --arg d "$FOUNDRY" '{tool_name:"Bash", tool_input:{command:"gh pr create --title t"}, cwd:$d}' | HOME="$ROOT/home" bash "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "mute file: untouched" || bad "mute file ignored: ${o:0:100}"
o=$(jq -nc --arg d "$FOUNDRY" '{tool_name:"Bash", tool_input:{command:"gh pr create --title t"}, cwd:$d}' | PR_TITLE_TAGS_OFF=1 bash "$HOOK" 2>/dev/null)
[ -z "$o" ] && ok "process-wide PR_TITLE_TAGS_OFF=1: untouched" || bad "process override ignored: ${o:0:100}"

echo "== the title step names a new PR from its git data (owner ruling D21a)"
step_out() { ( export PR_TITLE_TOOL="$ROOT/good-title.py"; out_of "$1" "$2" ); }
calls() { [ -f "$ROOT/good-title.py.called" ] && wc -l < "$ROOT/good-title.py.called" | tr -d ' ' || echo 0; }
: > "$ROOT/good-title.py.called"
o=$(step_out 'gh pr create --title "update the cache" --body-file b' "$FOUNDRY")
new=$(printf '%s' "$o" | jq -r '.hookSpecificOutput.updatedInput.command' 2>/dev/null)
ctx=$(printf '%s' "$o" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)
[ "$new" = "gh pr create --title '[noslack] fix(llm): add model id to the cache key' --body-file b" ] && ok "the step's title replaces the agent's, with the repo's tag" || bad "step title not applied: $new :: ${o:0:160}"
[[ "$ctx" == *"title step"* && "$ctx" == *"PR_TITLE_KEEP=1"* && "$ctx" == *"update the cache"* ]] && ok "the agent is told, with its old title and the keep override" || bad "step note incomplete: ${ctx:0:200}"
[ "$(calls)" = 1 ] && ok "the read-back of the rewrite does not run the models again" || bad "tool ran $(calls) times"
o=$(step_out 'gh pr create --title "[nobot] update the cache"' "$FOUNDRY")
new=$(printf '%s' "$o" | jq -r '.hookSpecificOutput.updatedInput.command' 2>/dev/null)
[ "$new" = "gh pr create --title '[noslack] [nobot] fix(llm): add model id to the cache key'" ] && ok "tags the agent chose are kept in front of the step's title" || bad "agent tag lost: $new"
o=$(step_out 'PR_TITLE_KEEP=1 gh pr create --title "[noslack] my own title"' "$FOUNDRY")
[ -z "$o" ] && ok "PR_TITLE_KEEP=1 keeps the agent's title" || bad "keep override ignored: ${o:0:120}"
o=$(step_out 'gh pr edit 3 --title "[noslack] renamed"' "$FOUNDRY")
[ -z "$o" ] && ok "a title edit is the agent's own call, the step does not run" || bad "edit was re-titled: ${o:0:120}"
o=$(step_out 'gh pr create --head other-branch --title "[noslack] mine"' "$FOUNDRY")
[ -z "$o" ] && ok "a PR for another branch than the checkout's keeps the agent's title" || bad "other-branch PR re-titled: ${o:0:120}"
o=$(step_out 'gh pr create -R versable-git/walmart-mvp --title "[noslack] mine"' "$FOUNDRY")
[ -z "$o" ] && ok "a PR for a repo other than the working checkout keeps the agent's title" || bad "other-repo PR re-titled: ${o:0:120}"
o=$( ( export PR_TITLE_STEP_OFF=1; step_out 'gh pr create --title "[noslack] mine"' "$FOUNDRY" ) )
[ -z "$o" ] && ok "PR_TITLE_STEP_OFF=1 turns the step off" || bad "step-off ignored: ${o:0:120}"
o=$(out_of 'gh pr create --title "[noslack] mine"' "$FOUNDRY")
[ -z "$o" ] && ok "a tool that writes no title keeps the agent's" || bad "failed tool changed the title: ${o:0:120}"

echo "---- pass=$pass fail=$fail"
[ $fail -eq 0 ]
