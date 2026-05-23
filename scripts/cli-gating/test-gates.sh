#!/usr/bin/env bash
# Negative + positive test suite for cli-gating. Each case asserts ALLOW or BLOCK.
# The bypass-table rows from the /magi design are mandatory BLOCK cases.

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY="$HOME/.claude/conventions/cli-gating.json"
PY="$DIR/gate_cli_actions.py"

pass=0; fail=0

check() {
  local expect="$1" cmd="$2"
  local out verdict
  out=$(python3 "$PY" "$cmd" "$POLICY" 2>/dev/null)
  verdict="${out%%	*}"
  if [ "$verdict" = "$expect" ]; then
    pass=$((pass+1))
    # printf '  ok   [%s] %s\n' "$expect" "$cmd"
  else
    fail=$((fail+1))
    printf '  FAIL expected %s got %s: %s\n     (%s)\n' "$expect" "$verdict" "$cmd" "$out"
  fi
}

echo "=== READS (expect ALLOW) ==="
check ALLOW "render services"
check ALLOW "render logs --tail 100"
check ALLOW "vercel ls"
check ALLOW "vercel logs my-app"
check ALLOW "gh pr list"
check ALLOW "gh repo view anthropics/claude-code"
check ALLOW "gh api /user"
check ALLOW "ls -la"
check ALLOW "git status"
check ALLOW "npm run build"

echo "=== PROVEN-DEV WRITES (expect ALLOW) ==="
check ALLOW "render deploy --env staging"
check ALLOW "vercel deploy --target preview"
check ALLOW "vercel deploy"

echo "=== PROD WRITES (expect BLOCK) ==="
check BLOCK "render deploy --prod"
check BLOCK "render deploy --production"
check BLOCK "render restart --env production"
check BLOCK "vercel deploy --prod"

echo "=== UNKNOWN-ENV WRITES (expect BLOCK — treated as prod) ==="
check BLOCK "render deploy"
check BLOCK "render restart srv-123"
check BLOCK "render secret set FOO=bar"

echo "=== gh WRITES (expect BLOCK) ==="
check BLOCK "gh repo delete myorg/oldrepo"
check BLOCK "gh secret set TOKEN"
check BLOCK "gh pr merge 42"
check BLOCK "gh push origin main"
check BLOCK "gh release create v1.0.0"

echo "=== BYPASS TABLE (all expect BLOCK) ==="
check BLOCK 'bash -c "render deploy --prod"'
check BLOCK "ENV=prod render deploy --prod"
check BLOCK 'eval "render deploy --prod"'
check BLOCK 'echo $(render deploy --prod)'
check BLOCK "render status && render deploy --prod"
check BLOCK "vercel ls && vercel deploy --prod"

echo "=== COMPOUND with safe segments (expect ALLOW) ==="
check ALLOW "render services && vercel ls"
check ALLOW "git status && gh pr list"

echo "=== FALSE-POSITIVE GUARDS (gated CLI as string/comment, expect ALLOW) ==="
check ALLOW 'echo "gh pr list"'
check ALLOW 'echo "to deploy run render deploy --prod"'
check ALLOW "echo \"don't run vercel deploy --prod\""
check ALLOW '# we do not actually call gh here'
check ALLOW 'grep -r "render" ~/.claude/scripts'
printf -v multiline 'echo "step 1"\necho "now gh pr list would run"\nls -la'
check ALLOW "$multiline"

echo "=== unparseable BUT starts with gated CLI (expect BLOCK) ==="
check BLOCK "render deploy --prod 'unterminated"

echo "=== REVIEWER-DEMONSTRATED BYPASSES (all expect BLOCK) ==="
check BLOCK "/usr/bin/gh pr merge 42"
check BLOCK "command gh pr merge 42"
check BLOCK "/opt/homebrew/bin/render deploy --prod"
check BLOCK "cat <(render deploy --prod)"
check BLOCK "env gh pr merge 42"
check BLOCK "env render deploy --prod"
check BLOCK "nohup render deploy --prod"
check BLOCK "timeout 60 render deploy --prod"
check BLOCK "true & render deploy --prod"
check BLOCK 'render deploy --note "--env staging"'
check BLOCK "gh api --method POST /repos/o/r/merges"
check BLOCK "gh api -X DELETE /repos/o/r"
check BLOCK "vercel promote https://x"
check BLOCK "sudo gh secret set TOKEN"

echo "=== gh api READ still allowed ==="
check ALLOW "gh api /user"
check ALLOW "gh api /repos/o/r/pulls"

echo "=== REAL INCIDENT REGRESSIONS (last-2-day transcripts — all expect ALLOW) ==="
# FP-1: gh reads with --jq/--json (shlex-breaking) — were wrongly blocked
check ALLOW "gh run view 26197629560 --json status,conclusion,jobs --jq '{s: .status}'"
check ALLOW "gh run list --branch gh-pages-cleanup/aakarsh --limit 7 --json status"
check ALLOW "gh pr view 180 --json labels --jq '[.labels[].name] | join(\",\")'"
# FP-2: 'render' as a substring of a script name — was wrongly blocked
check ALLOW "/bin/bash ~/.claude/skills/core-dump/render-visual.sh /tmp/x.json"
check ALLOW "bash render-visual.sh"
# FP-3: heredoc / big script with NO gated CLI — was wrongly blocked by >50-cap
check ALLOW "cat > /tmp/out.md"
check ALLOW "SID=x; F=/tmp/f.json; test -f \"\$F\" && trash \"\$F\"; cat > \"\$F\""
# FP-4: gh read inside command substitution — was wrongly blocked
check ALLOW "RID=\$(gh run list --branch x --json databaseId --jq '.[0]')"
check ALLOW "cd \"\$(git rev-parse --show-toplevel)\" && gh pr view 180 --json labels"
# bash -c wrapping a READ should now pass (recursion), not block
check ALLOW 'bash -c "gh pr list"'

echo "=== SKEPTICAL-REVIEW FALSE-NEGATIVES (2026-05-22 — all expect BLOCK) ==="
# read-namespace prefix laundering a write subcommand
check BLOCK "render env-vars set FOO=bar"
check BLOCK "render services delete srv-1"
check BLOCK "render services scale srv-1 --num 5"
check BLOCK "render deploys cancel dep-1"
# combined shell flag dodging the -c recursion
check BLOCK "bash -lc 'render deploy --prod'"
check BLOCK "sh -xc 'render deploy --prod'"
# vercel prod-signal gaps (short flag, =-glued, --target)
check BLOCK "vercel deploy -p"
check BLOCK "vercel deploy --prod=true"
check BLOCK "vercel deploy --target production"
check BLOCK "vercel deploy --target=production"

echo "=== NAMESPACE READS must STILL pass (no over-correction back — expect ALLOW) ==="
check ALLOW "render services"
check ALLOW "render env-vars"
check ALLOW "render deploys"
check ALLOW "render logs --tail"
check ALLOW "vercel deploy"
check ALLOW "vercel deploy --target preview"

echo ""
echo "── Core results: $pass passed, $fail failed ──"

echo ""
echo "=== END-TO-END THROUGH THE SHIM (production entry point) ==="
# The atone lesson: test the shim, not just the core. Pipe hook JSON to the
# registered command and assert exit codes. Disable marker must be absent.
shim_pass=0; shim_fail=0
mkjson() { jq -nc --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}, cwd:"/tmp/noproject"}'; }
shim_check() {
  local expect_exit="$1" cmd="$2"
  mkjson "$cmd" | bash "$DIR/gate-cli-actions.sh" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" = "$expect_exit" ]; then
    shim_pass=$((shim_pass+1))
  else
    shim_fail=$((shim_fail+1))
    printf '  SHIM FAIL expected exit %s got %s: %s\n' "$expect_exit" "$rc" "$cmd"
  fi
}
# Skip if user has the hook disabled (marker present)
if [ -f "$HOME/.claude/cli-gating.off" ]; then
  echo "  (skipped — cli-gating.off present; remove it to run shim tests)"
else
  shim_check 0 "gh pr list"
  shim_check 0 "render services"
  shim_check 0 "ls -la && git status"
  shim_check 2 "render deploy --prod"
  shim_check 2 "/usr/bin/gh pr merge 42"
  shim_check 2 "env render deploy --prod"
  shim_check 2 "true & render deploy --prod"
  shim_check 2 "gh api -X DELETE /repos/o/r"
  shim_check 2 "vercel promote https://x"
  shim_check 0 'echo "gh pr list is just text"'
  echo "  Shim results: $shim_pass passed, $shim_fail failed"
fi

echo ""
total_fail=$((fail + ${shim_fail:-0}))
echo "── TOTAL: core $pass/$((pass+fail)), shim ${shim_pass:-0}/$((${shim_pass:-0}+${shim_fail:-0})) ──"
[ "$total_fail" -eq 0 ] || exit 1
