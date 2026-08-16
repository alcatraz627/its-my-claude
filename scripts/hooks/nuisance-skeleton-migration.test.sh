#!/usr/bin/env bash
# Covers the nuisance-tier hooks migrated to hook_cmd_skeleton (task #36 / D12).
#
# Every mention row carries its OWN mutation control, because the first draft of
# this suite did not and shipped two dead fixtures. `echo "do not cat /etc/hosts"`
# never matched prefer-read-over-cat's raw pattern at all (it needs ^ or a ;
# before `cat`), so the row passed identically with the migration reverted. A
# fixture that cannot fire proves nothing about the filter that silenced it.
#
# The control: run the same command with HOME pointed at an empty directory. The
# migration blocks are all guarded by `[ -r "$HOME/.claude/.../hook-common.sh" ]`
# and fail open, so a HOME without hook-common gives the pre-migration behaviour
# with no edit to any hook. Each mention case must FIRE there and stay SILENT
# under the real HOME. If it is silent in both, the fixture is dead and says so.
#
# Hooks deliberately NOT covered, reclassified OUT of the migrate list 2026-08-16:
#   guard-commit-signature   its matcher reads the CONTENTS of commit -m "..."
#   guard-zsh-path-var       zsh-path-scan.py already blanks quotes, and better
#                            (state across lines, $'...' quoting, heredoc bodies)
# See the third-category note in hook-common.sh for the rule separating them.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

pass=0; fail=0
BARE=$(mktemp -d)                        # a HOME with no hook-common = pre-migration
trap 'rm -rf "$BARE"' EXIT

fire() {                                  # fire <hook> <cmd> [home] -> FIRE|SILENT
  local out
  out=$(printf '%s' "$2" \
        | jq -Rs '{tool_name:"Bash",tool_input:{command:.},cwd:"/tmp"}' \
        | HOME="${3:-$HOME}" bash "./${1}.sh" 2>/dev/null)
  [ -n "$out" ] && echo FIRE || echo SILENT
}

ok()   { pass=$((pass+1)); echo "  ok   $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL $1"; }

# invocation <hook> <label> <cmd> — a real call must still fire
invocation() {
  local got; got=$(fire "$1" "$3")
  [ "$got" = FIRE ] && ok "$1 · $2 still fires" || bad "$1 · $2 went silent (guard disarmed)"
}

# mention <hook> <label> <cmd> — quoted prose must be silent NOW and loud BEFORE
mention() {
  local now before; now=$(fire "$1" "$3"); before=$(fire "$1" "$3" "$BARE")
  if [ "$before" != FIRE ]; then
    bad "$1 · $2 — DEAD FIXTURE, does not fire pre-migration either"
  elif [ "$now" != SILENT ]; then
    bad "$1 · $2 — still fires on a quoted mention"
  else
    ok "$1 · $2 (fires pre-migration, silent after)"
  fi
}

echo "== real invocations still fire =="
invocation prefer-glob-over-find           "find -name"   'find /tmp -name "*.log"'
invocation warn-kill-9                     "kill -9"      'kill -9 12345'
invocation prefer-read-over-head-tail-file "head -N file" 'head -50 /etc/hosts'
invocation prefer-read-over-cat            "cat file"     'cat /etc/hosts'
invocation guard-dev-server-port           "npm run dev"  'npm run dev'

echo "== quoted mentions silent, each with its pre-migration control =="
mention prefer-glob-over-find     "find in prose"    'echo "use find . -name x instead"'
mention warn-kill-9               "kill in prose"    'echo "never kill -9 1234 here"'
mention prefer-read-over-cat      "cat in prose"     'echo "; cat /etc/hosts"'
mention prefer-read-over-head-tail-file "head in prose" 'echo "; head -50 notes.md"'
mention guard-dev-server-port     "launcher in a search pattern" "ps aux | rg 'next dev|vite'"
# This hook only nudges above its own threshold (inline -c with >5 newlines,
# line 86), so a one-line body can never fire and would be a dead fixture. The
# body below carries six.
mention prefer-tmp-py-over-inline "python -c in prose" 'echo "use python3 -c '"'"'import os
a
b
c
d
e
f'"'"' instead"'
mention warn-git-add-enumeration  "git add in prose" 'echo "avoid git add a.py b.py c.py d.py"'

# The weld case the replaced perl/sed blankers got wrong: deleting a quoted span
# joins its neighbours, so vi'x'te read as a `vite` launch. Blanking to spaces of
# equal length keeps the boundary. No pre-migration control here — the old perl
# also produced silence, by a different and wrong route.
echo "== token welding (regression on the replaced blankers) =="
got=$(fire guard-dev-server-port "rg 'vi''te' /tmp/x")
[ "$got" = SILENT ] && ok "guard-dev-server-port · quoted span must not weld" \
                    || bad "guard-dev-server-port · welded into a false launch"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
