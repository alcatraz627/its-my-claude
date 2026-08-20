#!/usr/bin/env bash
# Tests for guard-git-push.sh's GATING DECISION: which pushes reach the approval
# machinery and which pass silently. The approval machinery itself (sentinel,
# dialog) is NOT stubbed-and-trusted here — the 2026-07-13 incident showed a
# stubbed osascript can hide a fail-open — so these tests only assert gate-reached
# (the hook emits its block/ask output) versus not-gated (silent exit 0), with
# osascript stubbed to DENY so a gated case can never pop UI or approve itself.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/guard-git-push.sh"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

# A throwaway repo on branch main, plus a DENY osascript shadowing the real one.
git init -q -b main "$T/repo" && (cd "$T/repo" && git commit -q --allow-empty -m x)
git init -q -b feat "$T/featrepo" && (cd "$T/featrepo" && git commit -q --allow-empty -m x)
mkdir -p "$T/bin"; printf '#!/bin/sh\necho DENY; exit 1\n' > "$T/bin/osascript"; chmod +x "$T/bin/osascript"
run() { # run <cwd> <command> → stdout of hook
  jq -nc --arg c "$2" --arg w "$1" '{tool_input:{command:$c}, cwd:$w}' \
    | PATH="$T/bin:$PATH" bash "$HOOK" 2>/dev/null
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

# Protected repo gates regardless of branch or refspec:
mkdir -p "$F/.claude" && touch "$F/.claude/require-user-commit" && (cd "$F" && git add -A >/dev/null 2>&1 && git commit -qm marker)
gated "$F" "git push origin feat-z" "protected repo, feature refspec"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
