#!/usr/bin/env bash
# guard-rg-replace-bundle.test.sh — runnable checks for the rg -r guard.
#
# The guard must tell rg's OWN -r flag from a -r that merely appears in the
# command text. It already scopes to rg segments and strips runner wrappers; what
# it could not do was tell rg's flags from rg's quoted PATTERN, so searching for
# the string "jq -r" was refused as if it were a replacement.
#
# The controls matter more than the cases. This guard blocks via
# {"decision":"block"} on stdout with exit 0, NOT exit 2 — a probe that only
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
HOOK="$HERE/guard-rg-replace-bundle.sh"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }

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

echo "── deliberate or unrelated: must ALLOW ──"
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

echo "── the mute still works ──"
ok "muted -> allow" "$(RGGUARD_TEST=1; touch "$HOME/.claude/.no-rg-replace-guard"; v=$(verdict 'rg -r foo src/'); rm -f "$HOME/.claude/.no-rg-replace-guard"; echo "$v")" allow

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
