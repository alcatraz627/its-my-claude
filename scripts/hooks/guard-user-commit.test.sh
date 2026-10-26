#!/usr/bin/env bash
# Checks guard-user-commit: a commit that would run in a protected repo is
# blocked however it is spelled, and a mention of one is not.
# GUARD_UNDER_TEST=<path> points the suite at a mutated copy.
set -uo pipefail
H="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/guard-user-commit.sh}"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

T=$(mktemp -d)
P="$T/protected"; U="$T/plain"
mkdir -p "$P/.claude" "$U"
git init -q -b main "$P"; git init -q -b main "$U"
touch "$P/.claude/require-user-commit"
export WARN_LOG_STORE="$T/warn.jsonl"

blocked() { # <command> <cwd>
  local out rc
  out=$(jq -nc --arg c "$1" --arg d "$2" '{tool_name:"Bash", tool_input:{command:$c}, cwd:$d}' | bash "$H" 2>/dev/null); rc=$?
  [ "$rc" -eq 2 ] || printf '%s' "$out" | tr -d ' ' | rg -q '"decision":"block"|"permissionDecision":"deny"'
}
must_block() { blocked "$1" "$2" && ok "BLOCKED: $3" || bad "let through: $3"; }
must_pass()  { blocked "$1" "$2" && bad "blocked: $3" || ok "allow: $3"; }

must_block "git commit -m x" "$P" "commit in a protected repo"
must_block "git -C $P commit -m x" "$U" "git -C into a protected repo"
must_block "cd $P && git commit -m x" "$U" "cd into a protected repo, then commit"
must_block "bash -c \"git commit -m x\"" "$P" "a bash -c wrapper"
must_block "if true; then git commit -m x; fi" "$P" "a commit inside if/then"
must_pass "git commit -m x" "$U" "commit in an unprotected repo"
must_pass "git status" "$P" "status in a protected repo"
must_pass 'echo "next step: git commit"' "$P" "a mention in echo"
must_pass "git log --grep 'a; git commit'" "$P" "a quoted chain in a log search"
must_pass "cat > notes.md <<'EOF'
git commit -m later
EOF" "$P" "a heredoc written to a file"
must_pass "cd $U && git commit -m x" "$P" "cd out to an unprotected repo, then commit"

trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
