#!/usr/bin/env bash
# Suite for guard-pr-title-tags.sh: a `gh pr create` or `gh pr edit --title`
# whose title lacks the repo's required tags is refused with the corrected
# title; the same command with the tags passes; a repo's own PR-TITLE-TAGS line
# beats the default. GUARD_UNDER_TEST points it at a mutated copy (the copy
# must sit in scripts/hooks/ so it finds shell-scan.py).
set -uo pipefail
HOOK="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/guard-pr-title-tags.sh}"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

ROOT=$(mktemp -d "${TMPDIR:-/tmp}/prtags.XXXXXX")
trap 'trash "$ROOT" 2>/dev/null || true' EXIT
export GUARD_PR_TAGS_CODE_ROOT="$ROOT/Code"

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
  if [ "$(printf '%s' "$o" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" = deny ] && [ -n "$(printf '%s' "$o" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -F -- "$3")" ]; then ok "BLOCKED: ${1:0:60} -> has: $3"
  else bad "not blocked or reason lacks '$3': ${1:0:70} :: ${o:0:120}"; fi
}
allowed() {
  local o; o=$(out_of "$1" "$2")
  [ -z "$o" ] && ok "allow: ${1:0:70}" || bad "blocked (should pass): ${1:0:70} :: ${o:0:120}"
}

echo "== 23 Oct 2026 versable-foundry commands (real, from session e815d840)"
BODY=/private/tmp/x/scratchpad/pr-wm-preview-body.md
blocked "gh pr create -R versable-git/walmart-mvp --base feat/ingest-service --head feat/preview-envs --title \"Preview environments that follow their branch\" --body-file $BODY" "$FOUNDRY" '--title "[noslack] Preview environments that follow their branch"'
blocked "gh pr create -R versable-git/speedway --base development --head feat/preview-workflow --title \"Previews that follow their branch, and kit installs without a personal token\" --body-file $BODY" "$FOUNDRY" '[noslack] Previews that follow'
allowed "gh pr create -R versable-git/walmart-mvp --base feat/ingest-service --head feat/preview-envs --title \"[noslack] Preview environments that follow their branch\" --body-file $BODY" "$FOUNDRY"
allowed "gh pr create -R versable-git/speedway --base development --head feat/preview-workflow --title \"[noslack] Previews that follow their branch\" --body-file $BODY" "$FOUNDRY"

echo "== spellings, flags, cwd"
allowed 'gh pr create -t "[no-slack] a thing" --body-file b' "$FOUNDRY"
allowed 'gh pr create --title="[NoSlack] a thing" --body-file b' "$FOUNDRY"
blocked 'gh pr create -t "a thing" --body-file b' "$FOUNDRY" 'missing [noslack]'
blocked 'gh pr create --title="a thing"' "$FOUNDRY" '[noslack] a thing'
blocked "cd $FOUNDRY && gh pr create --title t" "$ROOT" 'missing [noslack]'
blocked 'gh -R versable-git/walmart-mvp pr create --title t' "$ROOT" 'missing [noslack]'

echo "== gh pr edit: only a title change is judged"
blocked 'gh pr edit 12 --title "Renamed"' "$FOUNDRY" '[noslack] Renamed'
allowed 'gh pr edit 12 --title "[noslack] Renamed"' "$FOUNDRY"
allowed 'gh pr edit 12 --add-label x' "$FOUNDRY"
allowed 'gh pr edit 12 --body-file b' "$FOUNDRY"

echo "== --fill"
blocked 'gh pr create --fill' "$FOUNDRY" 'takes the title from the commit message'
allowed 'gh pr create --fill --title "[noslack] x"' "$FOUNDRY"
allowed 'gh pr create --fill' "$ROOT/Code/Versable/fill-repo"
allowed 'gh pr create --fill' "$ROOT/Code/Versable/quiet-repo"

echo "== a repo's own rule wins over the default"
blocked 'gh pr create --title "[noslack] only" --body-file b' "$ROOT/Code/Versable/strict-repo" 'missing [nobot]'
blocked 'gh pr create -R versable-git/strict-repo --title "[noslack] only"' "$FOUNDRY" '[nobot] [noslack] only'
allowed 'gh pr create --title "[noslack] [nobot] both" --body-file b' "$ROOT/Code/Versable/strict-repo"
allowed 'gh pr create --title "No tag at all"' "$ROOT/Code/Versable/quiet-repo"
allowed 'gh pr create -R versable-git/quiet-repo --title "No tag at all"' "$FOUNDRY"
blocked 'gh pr create --title "No tag at all"' "$ROOT/Code/Versable/speedway" 'default rule'

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

echo "---- pass=$pass fail=$fail"
[ $fail -eq 0 ]
