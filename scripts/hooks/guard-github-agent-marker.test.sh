#!/usr/bin/env bash
# Suite for guard-github-agent-marker.sh: a real gh posting command without the
# owner's marker is refused, and a file, echo, commit message or heredoc that
# merely NAMES such a command is not. GUARD_UNDER_TEST points it at a mutated
# copy (the copy must sit in scripts/hooks/ so it finds shell-scan.py).
set -uo pipefail
HOOK="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/guard-github-agent-marker.sh}"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

MARKER='> Generated via a 🤖 on @someone machine (_he got lazy_)'

# rc 2 is the hook's block; anything else is a pass
rc_of() { jq -nc --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}, cwd:"/tmp"}' | bash "$HOOK" >/dev/null 2>&1; echo $?; }
blocked() { [ "$(rc_of "$1")" = 2 ] && ok "BLOCKED: ${1:0:70}" || bad "not blocked: ${1:0:70}"; }
allowed() { [ "$(rc_of "$1")" != 2 ] && ok "allow: ${1:0:70}" || bad "blocked (should pass): ${1:0:70}"; }

# Real posts without the marker
blocked 'gh pr comment 12 --body "looks good"'
blocked 'gh issue comment 4 --body "thanks"'
blocked 'gh pr create --title t --body "text"'
blocked 'gh api repos/o/r/issues/1/comments -X POST -f body=hello'
blocked 'bash -c "gh pr comment 12 --body hi"'
blocked 'cd repo && gh pr comment 12 --body hi'

# Real posts with the marker pass
allowed "gh pr comment 12 --body \"$MARKER
text\""

# Reads and non-comment gh commands pass
allowed 'gh pr view 12'
allowed 'gh api repos/o/r/pulls/1'

# Mentions: the words appear, no gh command runs
allowed "cat > /tmp/t.py <<'EOF'
gh pr create --title t --body x
gh pr comment 1 --body y
gh api repos/o/r/issues/1/comments -X POST -f body=z
EOF"
allowed 'echo "run gh pr create --title t --body x later"'
allowed 'git commit -m "docs: explain gh pr comment usage --body"'
allowed "rg 'gh pr create' scripts/"
allowed "cat <<'EOF' > notes.md
Use gh pr comment 3 --body to post.
EOF"

echo "---- pass=$pass fail=$fail"
[ $fail -eq 0 ]
