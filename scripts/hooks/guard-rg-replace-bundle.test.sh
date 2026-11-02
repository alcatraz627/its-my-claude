#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# guard-rg-replace-bundle.test.sh: runnable checks for the rg -r guard.
#
# The guard must tell rg's OWN -r flag from a -r that merely appears in the
# command text. It already scopes to rg segments and strips runner wrappers; what
# it could not do was tell rg's flags from rg's quoted PATTERN, so searching for
# the string "jq -r" was refused as if it were a replacement.
#
# The controls matter more than the cases. This guard blocks via
# {"decision":"block"} on stdout with exit 0, NOT exit 2: a probe that only
# checks the exit code reads every block as "allowed" and reports a clean bill of
# health for a broken hook. Both mechanisms are checked below.
#
# Run: bash ~/.claude/scripts/hooks/guard-rg-replace-bundle.test.sh  (exit 0 = pass)

set -uo pipefail

# Redirect the warn-log ledger so this suite never writes into the live audit
# file. Without it, test fires are indistinguishable from live ones, which is
# how 102 test events were read as live adherence data (audit 2026-08-18).
export WARN_LOG_STORE="$(mktemp "${TMPDIR:-/tmp}/warnlog-test-XXXXXX")"
HERE="$(cd "$(dirname "$0")" && pwd)"
# GUARD_UNDER_TEST points the suite at a deliberately broken copy for mutation runs.
HOOK="${GUARD_UNDER_TEST:-$HERE/guard-rg-replace-bundle.sh}"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1: got [$2] want [$3]"; fi; }

verdict(){ # verdict <command> -> BLOCK|allow
  local out rc
  out=$(printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)" \
        | bash "$HOOK" 2>/dev/null); rc=$?
  if [ "$rc" -eq 2 ]; then echo BLOCK; return; fi
  if printf '%s' "$out" | grep -q '"decision":"block"'; then echo BLOCK; return; fi
  echo allow
}

echo "── the footgun itself: must BLOCK ──"
ok "bare -r"                "$(verdict 'rg -r foo src/')"            BLOCK
ok "bundled -rn"            "$(verdict 'rg -rn foo src/')"           BLOCK
ok "bundled -nr"            "$(verdict 'rg -nr foo src/')"           BLOCK
ok "-r after a quoted arg"  "$(verdict 'rg "pat" -r x src/')"        BLOCK
ok "behind an xargs wrapper" "$(verdict 'xargs -I{} rg -r foo')"     BLOCK

echo "── the same bundles where rg is not at the start of a segment: must BLOCK ──"
ok "-rn inside \$( )"        "$(verdict 'echo $(rg -rn foo src/)')"   BLOCK
ok "-nr in an assignment"   "$(verdict 'x=$(rg -nr foo src/)')"      BLOCK
ok "-nr inside backticks"   "$(verdict 'echo `rg -nr foo`')"         BLOCK
ok "-rn in a subshell"      "$(verdict '(rg -rn foo src/)')"         BLOCK
ok "-nr after env prefix"   "$(verdict 'LC_ALL=C rg -nr foo src/')"  BLOCK

echo "── deliberate or unrelated: must ALLOW ──"
ok "jq -r inside \$( )"      "$(verdict 'echo $(jq -r .cwd f.json)')"  allow
ok "heredoc prose naming rg -rn" "$(verdict "$(printf 'cat <<EOF > n.md\nrg -rn foo is wrong\nEOF')")" allow
ok "explicit --replace"     "$(verdict 'rg foo --replace bar src/')" allow
ok "-r in another segment"  "$(verdict 'rg foo src/ | sort -r')"     allow
ok "not an rg command"      "$(verdict 'jq -r .cwd f.json')"         allow
ok "plain search"           "$(verdict 'rg foo src/')"               allow

echo "── -r inside rg's OWN quoted pattern: data, not a flag. Must ALLOW ──"
ok "double-quoted pattern"  "$(verdict 'rg "jq -r .cwd" scripts/')"       allow
ok "single-quoted pattern"  "$(verdict "rg 'use -r for recursive' docs/")" allow
ok "quoted, with real flag" "$(verdict 'rg -n "sort -r output" notes.md')" allow

echo "── a | inside the pattern must not split the segment ──"
# The pre-fix comment claimed a mid-quote split could only UNDER-fire ("the safe
# direction"). It over-fired: the split stranded the pattern's -r in what looked
# like rg's own args. Both must allow.
ok "pipe in pattern"        "$(verdict 'rg "a|b" src/')"             allow
ok "pipe AND -r in pattern" "$(verdict 'rg "jq -r x|y" src/')"       allow

echo "── a real replacement is the flag's job: -r with a capture group or empty text must ALLOW ──"
# 22 of the 28 real denials were this. -r takes the next word as the replacement,
# so a word with a $ reference, or an empty one, is the flag used correctly.
ok "-r '\$1'"                "$(verdict "rg 'a(b)' -r '\$1' f.txt")"            allow
ok "-r after the path"       "$(verdict "rg -n -o 'v\\(--[a-z]+' app.css --no-filename -r '\$0' -m 4")" allow
ok "-r \"\$1\" double quoted"  "$(verdict 'rg -o "\](([^)]+))" -r "$1" docs/')"    allow
ok "-r '' empty"             "$(verdict "rg -n 'X = ' -r '' --hex f.py")"       allow
ok "-r \"\" empty"            "$(verdict 'rg "a|b" -r "" -c f.txt')"             allow
ok "-r '\$1\$2' two groups"   "$(verdict "rg -o 'x(a)|y(b)' -r '\$1\$2' README.md")" allow
ok "-r with text and a ref"  "$(verdict "rg 'k=(\\w+)' -r 'key:\$1' f")"        allow
ok "-or bundle ending in r"  "$(verdict "rg -nor '\$0' 'a+' f")"                allow
ok "-r bare \$1"             "$(verdict 'rg -o "(a)" -r $1 f')"                 allow
ok "-r=VALUE"                "$(verdict "rg foo -r='x' f")"                     allow
ok "replacement, then sort -r" "$(verdict "rg -o 'a(b)' -r '\$1' f | sort -r")" allow

echo "── a bundle where r swallows the letters after it, or an r with a pattern after it: must BLOCK ──"
ok "-ri bundle"              "$(verdict 'rg -ri foo src/')"                     BLOCK
ok "-rl bundle"              "$(verdict 'rg -rl foo src/')"                     BLOCK
ok "-rn with quoted pattern" "$(verdict 'rg -rn "def ipc_peers" -A20 native/')"  BLOCK
ok "-rn with glob after"     "$(verdict "rg -rn 'a|b' dir --glob '!x.json' -m 3")" BLOCK
ok "-nrn middle r"           "$(verdict 'rg -nrn foo src/')"                    BLOCK
ok "-r then a quoted pattern" "$(verdict "rg -r 'pattern' src/")"               BLOCK
ok "-r then a plain word"    "$(verdict 'rg -r pattern src/')"                  BLOCK
ok "-r last, nothing after"  "$(verdict 'rg foo src/ -r')"                      BLOCK
ok "-n -r then a path"       "$(verdict 'rg -n -r foo /abs/path')"              BLOCK
ok "the \$ is in the pattern, not after -r" "$(verdict 'rg "a$" -r src/')"      BLOCK
ok "second -r is the typo"   "$(verdict "rg -r '\$1' 'a(b)' f | rg -r foo g")"  BLOCK

echo "── the block message keeps the phrase measure.test.py reads ──"
msg=$(printf '{"tool_name":"Bash","tool_input":{"command":"rg -rn foo ."}}' | bash "$HOOK" 2>/dev/null)
ok "message names the footgun" "$(printf '%s' "$msg" | grep -c 'rg -r IS --replace')" 1

echo "── the mute still works ──"
ok "muted -> allow" "$(RGGUARD_TEST=1; touch "$HOME/.claude/.no-rg-replace-guard"; v=$(verdict 'rg -r foo src/'); rm -f "$HOME/.claude/.no-rg-replace-guard"; echo "$v")" allow

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
