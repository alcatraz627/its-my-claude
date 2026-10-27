#!/usr/bin/env bash
# Tests for guard-git-push.sh's GATING DECISION: which pushes reach the approval
# machinery and which pass silently. The approval machinery itself (sentinel,
# dialog) is NOT stubbed-and-trusted here: the 2026-07-13 incident showed a
# stubbed osascript can hide a fail-open: so these tests only assert gate-reached
# (the hook emits its block/ask output) versus not-gated (silent exit 0), with
# osascript stubbed to DENY so a gated case can never pop UI or approve itself.
set -uo pipefail
HOOK="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/guard-git-push.sh}"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

# A throwaway repo on branch main, plus a DENY osascript shadowing the real one.
git init -q -b main "$T/repo" && (cd "$T/repo" && git commit -q --allow-empty -m x)
git init -q -b feat "$T/featrepo" && (cd "$T/featrepo" && git commit -q --allow-empty -m x)
mkdir -p "$T/bin"; printf '#!/bin/sh\necho DENY; exit 1\n' > "$T/bin/osascript"; chmod +x "$T/bin/osascript"
# HOME is sandboxed: with no session_id the gate writes its nonce under
# $HOME/.claude/.push-nonce-nosession, and this suite left one in the real home.
mkdir -p "$T/.claude"
run() { # run <cwd> <command> → stdout of hook
  jq -nc --arg c "$2" --arg w "$1" '{tool_input:{command:$c}, cwd:$w}' \
    | HOME="$T" PATH="$T/bin:$PATH" bash "$HOOK" 2>/dev/null
}
gated()  { [ -n "$(run "$1" "$2")" ] && ok "GATED: $3" || bad "not gated: $3"; }
allowed(){ [ -z "$(run "$1" "$2")" ] && ok "allow: $3" || bad "gated (should pass): $3"; }

R="$T/repo"; F="$T/featrepo"

# The two automation-reported false blocks, now allowed:
allowed "$R" "git push origin --delete canary-x" "branch delete from main checkout"
allowed "$R" "git push origin :canary-x" "colon-refspec delete from main checkout"
allowed "$R" "git checkout -b feat-y && git commit -am x && git push -u origin feat-y" "compound: feature push while HEAD is main at inspection"
allowed "$R" "git push origin feat-y" "explicit feature refspec from main checkout"
allowed "$F" "git push" "bare push on a feature branch"

# Everything that must still gate:
gated "$R" "git push origin main" "explicit main refspec"
gated "$R" "git push origin HEAD:main" "HEAD:main refspec"
gated "$R" "git push origin --delete main" "deleting main itself"
gated "$R" "git push --mirror origin" "--mirror"
gated "$R" "git push --all origin" "--all"
gated "$R" "git push" "bare push on main checkout"
gated "$R" "git push origin" "remote-only push on main checkout"
gated "$F" "git push origin master" "explicit master from a feature checkout"

# Spellings that used to slip past the pattern (D33 audit, 2026-10-15):
gated "$R" 'bash -c "git push origin main"' "bash -c wrapper"
gated "$R" 'if true; then git push origin main; fi' "push inside if/then"
gated "$R" 'for r in origin; do git push $r main; done' "push inside a for loop"
gated "$R" "sh -c 'git push origin main'" "sh -c wrapper"
gated "$R" "/usr/bin/git push origin main" "absolute path to git"
gated "$R" "git push origin +main" "force-refspec +main"
gated "$R" "command git push origin main" "command prefix"
gated "$R" "env FOO=1 git push origin main" "env prefix"
gated "$R" 'git push origin "main"' "quoted refspec"
gated "$R" 'echo "$(git push origin main)"' "push inside command substitution"
gated "$R" "$(printf 'cat <<EOF | bash\ngit push origin main\nEOF')" "heredoc fed to bash"
gated "$R" "git push origin 2>&1" "remote-only push with a redirect"
allowed "$R" 'bash -c "git push origin feat-y"' "bash -c feature push"
allowed "$R" "/usr/bin/git push origin feat-y" "absolute-path feature push"

# Mentions stay silent: the words are data, not a push.
allowed "$R" 'echo "git push origin main"' "mention: echo"
allowed "$R" "rg 'git push origin main' docs/" "mention: rg pattern"
allowed "$R" 'git commit -m "docs: explain git push origin main"' "mention: commit message"
allowed "$R" "$(printf 'git commit -m "$(cat <<'"'"'EOF'"'"'\ngit push origin main\nEOF\n)"')" "mention: commit message heredoc"
allowed "$R" 'echo "bash -c \"git push origin main\""' "mention: quoted wrapper in echo"

# Protected repo gates regardless of branch or refspec:
mkdir -p "$F/.claude" && touch "$F/.claude/require-user-commit" && (cd "$F" && git add -A >/dev/null 2>&1 && git commit -qm marker)
gated "$F" "git push origin feat-z" "protected repo, feature refspec"

# The refusal says the whole call was refused and where the registration lives,
# for a lone push as well as a chained one; an unwritable nonce file says so.
msg=$(run "$R" "git push origin main" | jq -r '.reason // empty')
case "$msg" in *"refused the WHOLE Bash call"*"nonce file"*"is registered"*|*"refused the WHOLE Bash call"*"registered in the nonce file"*) ok "lone push: whole-call and registration sentences" ;; *) bad "lone push: whole-call and registration sentences" ;; esac
mkdir -p "$T/ro/.claude" && chmod a-w "$T/ro/.claude"
msg=$(jq -nc --arg c "git push origin main" --arg w "$R" '{tool_input:{command:$c}, cwd:$w}' | HOME="$T/ro" PATH="$T/bin:$PATH" bash "$HOOK" 2>/dev/null | jq -r '.reason // empty')
case "$msg" in *"NOT registered"*) ok "unwritable nonce file: says the push is NOT registered" ;; *) bad "unwritable nonce file: says the push is NOT registered" ;; esac
chmod u+w "$T/ro/.claude"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
