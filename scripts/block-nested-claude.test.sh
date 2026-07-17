#!/usr/bin/env bash
# block-nested-claude.test.sh — runnable checks for block-nested-claude.sh.
#
# The guard exists to stop a WRITE landing in ~/.claude/.claude/. Two things it
# must get right, and historically got backwards:
#
#   1. Catch the real root cause: a RELATIVE ".claude/…" write while cwd is the
#      gcc. That is how the nesting actually happens (skill templates assume cwd
#      is a project root). A substring match for the spelled-out nested path
#      cannot see this case at all.
#   2. Never block a READ, a search, a mention, or a test of that path. Auditing
#      the nested directory must be at least as easy as creating it was.
#
# The same relative path is CORRECT in a normal project (a project's .claude/ is
# a real subdir) and wrong ONLY in the gcc, so cwd decides — never the text.
#
# Run: bash ~/.claude/scripts/block-nested-claude.test.sh   (exit 0 = all pass)

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/block-nested-claude.sh"

# Compose the nested literal from parts: a test that spells it out cannot be
# grepped for, edited, or run without tripping the very guard under test.
C=".claude"
GCC="$HOME/$C"
NEST="$GCC/$C"
PROJ="/tmp/some-project"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }

verdict(){ # verdict <json> -> block|allow
  local rc
  printf '%s' "$1" | bash "$HOOK" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 2 ]; then echo block; else echo allow; fi
}
bash_j(){ printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"%s"}}' "$1" "$2"; }
write_j(){ printf '{"tool_name":"Write","cwd":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2"; }

echo "── real writes to the nest: must BLOCK ──"
ok "Write file_path is nested"            "$(verdict "$(write_j "$GCC" "$NEST/foo.md")")"          block
ok "NotebookEdit notebook_path is nested" "$(verdict "$(printf '{"tool_name":"NotebookEdit","cwd":"%s","tool_input":{"notebook_path":"%s"}}' "$GCC" "$NEST/n.ipynb")")" block
ok "Bash mkdir absolute nested"           "$(verdict "$(bash_j "$GCC" "mkdir -p $NEST/output")")"  block

echo "── THE ROOT CAUSE: relative write while cwd IS the gcc: must BLOCK ──"
ok "Bash mkdir relative in gcc"           "$(verdict "$(bash_j "$GCC" "mkdir -p $C/output")")"     block
ok "Bash tee relative in gcc"             "$(verdict "$(bash_j "$GCC" "tee $C/output/x.md")")"     block
ok "Bash redirect relative in gcc"        "$(verdict "$(bash_j "$GCC" "echo hi > $C/foo.txt")")"   block
ok "Bash cp relative in gcc"              "$(verdict "$(bash_j "$GCC" "cp a.md $C/skills/b.md")")" block

echo "── reads / mentions / checks: must ALLOW (auditing is not creating) ──"
ok "Bash cat the nested file (read)"      "$(verdict "$(bash_j "$GCC" "cat $NEST/settings.local.json")")" allow
ok "Bash rg for the pattern (search)"     "$(verdict "$(bash_j "$GCC" "rg -n '$NEST/' rules/")")"         allow
ok "Bash echo mentioning the nest"        "$(verdict "$(bash_j "$GCC" "echo the $NEST/ anti-pattern")")"  allow
ok "Bash test -f the marker (perm check)" "$(verdict "$(bash_j "$GCC" "[ -f $NEST/require-user-commit ]")")" allow
ok "Bash ls the nested dir"               "$(verdict "$(bash_j "$GCC" "ls -la $NEST/")")"                 allow

echo "── each fix pinned individually (these fail if ONLY that fix is reverted) ──"
# Pins quote-blanking: a legit write whose CONTENT mentions the nest. This is what
# rules/shell.md does — documents the anti-pattern. Without blanking the quoted
# span is read as a target and the write is refused.
ok "write to a normal path, content mentions nest" \
   "$(verdict "$(bash_j "$GCC" "echo 'see $NEST/ for detail' > $GCC/assets/notes.md")")" allow
# Pins the /dev/null redirect strip: without it, "2>/dev/null" reads as a write
# redirect, making every silenced read of the nested dir a block.
ok "read of nested dir silenced with 2>/dev/null" \
   "$(verdict "$(bash_j "$GCC" "ls -la $NEST/ 2>/dev/null")")" allow

echo "── a project's own .claude/ is legitimate: must ALLOW ──"
ok "relative write, cwd is a PROJECT"     "$(verdict "$(bash_j "$PROJ" "mkdir -p $C/output")")"    allow
ok "Write into a project's .claude/"      "$(verdict "$(write_j "$PROJ" "$PROJ/$C/notes.md")")"    allow
ok "Write to a normal gcc path"           "$(verdict "$(write_j "$GCC" "$GCC/assets/reports/r.md")")" allow

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
