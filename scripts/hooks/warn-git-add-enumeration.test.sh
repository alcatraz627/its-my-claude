#!/usr/bin/env bash
# warn-git-add-enumeration.test.sh: runnable checks for the git-add enumeration nudge.
#
# The nudge must fire on a real `git add` with four or more path arguments and stay
# silent when those words only appear as text: a commit message, an echo, a heredoc
# body. It is advisory (exit 0 either way), so the signal is the additionalContext
# JSON on stdout.
#
# The hook runs under a throwaway HOME so its side effects (an atone feedback event,
# a warn-log line) land in stubs instead of the live ledgers.
#
# Run: bash ~/.claude/scripts/hooks/warn-git-add-enumeration.test.sh   (exit 0 = pass)

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="${GUARD_UNDER_TEST:-$HERE/warn-git-add-enumeration.sh}"

FAKE=$(mktemp -d "${TMPDIR:-/tmp}/addenum-home-XXXXXX")
mkdir -p "$FAKE/.claude/scripts/hooks" "$FAKE/.claude/atone" "$FAKE/work"
ln -s "$HERE/strip-payloads.py" "$FAKE/.claude/scripts/hooks/strip-payloads.py"
ln -s "$HERE/hook-common.sh" "$FAKE/.claude/scripts/hooks/hook-common.sh"
printf '#!/bin/sh\nexit 0\n' > "$FAKE/.claude/scripts/atone.sh"
printf '#!/bin/sh\nexit 0\n' > "$FAKE/.claude/scripts/hooks/warn-log.sh"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }

verdict(){ # verdict <command> -> NUDGE|quiet
  local out
  out=$(jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' \
        | (cd "$FAKE/work" && HOME="$FAKE" bash "$HOOK" 2>/dev/null))
  if printf '%s' "$out" | rg -q 'additionalContext'; then echo NUDGE; else echo quiet; fi
}

echo "── a real enumerated add: must NUDGE ──"
ok "four paths"              "$(verdict 'git add a.ts b.ts c.ts d.ts')"                     NUDGE
ok "after cd &&"             "$(verdict 'cd src && git add a.ts b.ts c.ts d.ts')"           NUDGE
ok "env-var prefix"          "$(verdict 'GIT_X=1 git add a.ts b.ts c.ts d.ts')"             NUDGE
ok "quoted paths"            "$(verdict 'git add "a.ts" "b.ts" "c.ts" "d.ts"')"             NUDGE
ok "add on a later line"     "$(verdict "$(printf 'git status\ngit add a b c d e')")"       NUDGE
ok "add before a commit"     "$(verdict 'git add a b c d && git commit -m wip')"            NUDGE

echo "── the words appearing only as text: must stay quiet ──"
ok "commit message"          "$(verdict 'git commit -m "run git add a b c d e first"')"     quiet
ok "echo string"             "$(verdict "echo 'git add a b c d e'")"                        quiet
ok "heredoc body"            "$(verdict "$(printf 'cat <<EOF > n.md\ngit add a b c d e\nEOF')")" quiet
ok "multi-line commit msg"   "$(verdict "$(printf 'git commit -m "subject\n\ngit add a b c d e\n"')")" quiet
ok "unquoted prose in echo"  "$(verdict 'echo next run git add a b c d e')"                 quiet
ok "gh body mention"        "$(verdict 'gh issue comment 1 --body "use git add a b c d"')" quiet
ok "grep for the phrase"     "$(verdict "rg 'git add a b c d' docs/")"                      quiet

echo "── below the threshold or not an add: must stay quiet ──"
ok "three paths"             "$(verdict 'git add a b c')"                                   quiet
ok "a directory"             "$(verdict 'git add src/')"                                    quiet
ok "flags do not count"      "$(verdict 'git add -A -f -N -v a b c')"                       quiet
ok "git status"              "$(verdict 'git status a b c d e')"                            quiet

echo "── control: the suite can tell a nudge from silence ──"
ok "control: can nudge"      "$(verdict 'git add 1 2 3 4 5')"                               NUDGE
ok "control: can stay quiet" "$(verdict 'ls -la')"                                          quiet

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
