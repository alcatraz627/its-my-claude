#!/usr/bin/env bash
# Checks guard-system-dir-writes: a write into a system directory is blocked
# however it is wrapped, and a path that is only named is not.
# GUARD_UNDER_TEST=<path> points the suite at a mutated copy.
set -uo pipefail
H="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/guard-system-dir-writes.sh}"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.allow-system-writes" ]; then echo "override file present"; exit 2; fi

T=$(mktemp -d)
printf '#!/bin/bash\n[ "$1" = get ] && echo ask\nexit 0\n' > "$T/pol.sh"
export POL_SH="$T/pol.sh" WARN_LOG_STORE="$T/warn.jsonl"

blocked() {
  jq -nc --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$H" 2>/dev/null \
    | tr -d ' ' | rg -q '"decision":"block"'
}
must_block() { blocked "$1" && ok "BLOCKED: $2" || bad "let through: $2"; }
must_pass()  { blocked "$1" && bad "blocked: $2" || ok "allow: $2"; }

must_block "echo x > /etc/hosts" "redirect into /etc"
must_block "echo x>>/etc/hosts" "attached append redirect"
must_block "sudo tee -a /etc/hosts < f" "tee into /etc"
must_block "dd if=x of=/System/foo" "dd into /System"
must_block "rm -rf /Library/Foo" "rm of a system path"
must_block "chmod -R 777 /bin" "recursive chmod on /bin"
must_block "cat <<EOF > /etc/hosts
x
EOF" "heredoc redirected into /etc"
must_block 'bash -c "echo x > /etc/hosts"' "a bash -c wrapper"
must_block "eval 'tee /etc/motd < f'" "an eval wrapper"
must_pass "cat /etc/hosts" "a read"
must_pass 'git commit -m "docs: never tee /etc/hosts"' "a mention in a commit message"
must_pass "cat > notes.md <<'EOF'
echo x > /etc/hosts
EOF" "a heredoc body naming a write"
must_pass "ls -la /etcetera" "a lookalike root"
must_pass "echo x > ./etc/hosts" "a relative etc"
must_pass "chmod 644 /etc/hosts" "a non-recursive chmod"

trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
