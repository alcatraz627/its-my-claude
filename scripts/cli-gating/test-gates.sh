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

echo "=== command -v|-V <cli> is a LOOKUP, not an invocation (expect ALLOW) ==="
# Regression: a `>/dev/null` redirect after the looked-up CLI used to be read as
# the gh write verb, blocking the existence check. See atone command-v fix.
check ALLOW "command -v gh"
check ALLOW "command -v gh >/dev/null 2>&1 && echo ok"
check ALLOW "command -V render"
check ALLOW "gh auth status"
check ALLOW "gh auth status 2>&1"
# but `command <cli>` WITHOUT -v actually RUNS it — a write must still gate:
check BLOCK "command gh pr merge 123"

echo "=== EVERY WRITE GATED (gate_all_writes — even dev/preview writes BLOCK) ==="
check BLOCK "render deploy --env staging"
check BLOCK "vercel deploy --target preview"
check BLOCK "vercel deploy"

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

echo "=== AWS READS (operation-prefix; expect ALLOW) ==="
check ALLOW "aws s3 ls"
check ALLOW "aws s3 ls s3://bucket"
check ALLOW "aws sts get-caller-identity"
check ALLOW "aws ec2 describe-instances"
check ALLOW "aws iam list-users"
check ALLOW "aws dynamodb scan --table-name t"
check ALLOW "aws dynamodb query --table-name t"
check ALLOW "aws logs tail /aws/lambda/x"
check ALLOW "aws logs filter-log-events --log-group-name x"
check ALLOW "aws ec2 help"
check ALLOW "aws --version"
check ALLOW "aws s3api list-buckets"

echo "=== AWS WRITES (every mutation gated; expect BLOCK) ==="
check BLOCK "aws s3 rm s3://b/k"
check BLOCK "aws s3 cp ./f s3://b/k"
check BLOCK "aws s3 sync . s3://b"
check BLOCK "aws s3 mb s3://newbucket"
check BLOCK "aws ec2 terminate-instances --instance-ids i-1"
check BLOCK "aws ec2 run-instances --image-id ami-1"
check BLOCK "aws rds delete-db-instance --db-instance-identifier x"
check BLOCK "aws iam create-user --user-name x"
check BLOCK "aws iam attach-user-policy --user-name x"
check BLOCK "aws lambda update-function-code --function-name x"
check BLOCK "aws dynamodb put-item --table-name t"
check BLOCK "aws configure set foo bar"
check BLOCK "aws s3api put-bucket-policy --bucket b"

echo "=== AWS WRITE BYPASS (launcher/shell/env; expect BLOCK) ==="
check BLOCK "sudo aws s3 rm s3://b/k"
check BLOCK "env aws ec2 terminate-instances"
check BLOCK "AWS_PROFILE=prod aws s3 rm s3://b/k"
check BLOCK 'bash -c "aws s3 sync . s3://b"'
check BLOCK "/usr/local/bin/aws rds delete-db-instance"
check BLOCK "aws ec2 describe-instances && aws s3 rm s3://b/k"
# Global flag BEFORE the service must NOT launder a write into a read
# (skeptical-review finding A — a leading --region/--profile/--output bypassed).
check BLOCK "aws --region us-east-1 s3 rm s3://b/k"
check BLOCK "aws --profile prod s3 rm s3://b/k"
check BLOCK "aws --output json ec2 terminate-instances --instance-ids i-1"
check BLOCK "sudo aws --region x s3 rm s3://b/k"
check ALLOW "aws --region us-east-1 s3 ls"
check ALLOW "aws --profile dev ec2 describe-instances"

echo "=== AWS SENSITIVE READS (secret/credential exfil -> BLOCK) ==="
check BLOCK "aws secretsmanager get-secret-value --secret-id x"
check BLOCK "aws ecr get-login-password"
check BLOCK "aws sts get-session-token"
check BLOCK "aws ssm get-parameter --name x --with-decryption"
check ALLOW "aws ssm get-parameter --name x"
check ALLOW "aws ssm get-parameters --names a b"
check ALLOW "aws sts get-caller-identity"

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
check BLOCK "vercel deploy"
check BLOCK "vercel deploy --target preview"

echo "=== VERCEL NOUN-LS READS (2026-06-01 domains-ls false-block — expect ALLOW) ==="
check ALLOW "vercel domains ls"
check ALLOW "vercel certs ls"
check ALLOW "vercel dns ls"
check ALLOW "vercel secrets ls"
check ALLOW "vercel domains inspect x.com"
check BLOCK "vercel domains add x.com"
check BLOCK "vercel domains rm x.com"
check BLOCK "vercel secrets add API x"

echo "=== QUOTED-PIPE FALSE-POSITIVE (2026-05-31 bug — expect ALLOW) ==="
check ALLOW 'rg -i "declare|render|workspace|automat" /tmp/x'
check ALLOW 'grep -E "render|vercel|gh" file.txt'
check ALLOW 'rg "a|b|render" .'
check ALLOW 'bash ~/.claude/scripts/atone.sh slugs | rg "verif|render|scope"'

echo "=== quoted pipe + REAL operator must STILL split + BLOCK (no security regression) ==="
check BLOCK 'rg "x|y" && render deploy --prod'
check BLOCK 'echo "render|x" | render deploy --prod'

echo "=== AWS FALLBACK POLICY (unreadable JSON must NOT un-gate writes) ==="
# gate_for() returns None for an unknown CLI -> allow. If aws is missing from
# _fallback_policy, a broken policy file silently un-gates every AWS write.
# This locks the fallback in. Pass a non-existent policy path to force fallback.
_fbpol="/tmp/cli-gating-nonexistent-$$.json"
_fbw=$(python3 "$PY" "aws s3 rm s3://b/k" "$_fbpol" 2>/dev/null)
if [ "${_fbw%%	*}" = "BLOCK" ]; then pass=$((pass+1)); else fail=$((fail+1)); printf '  FAIL fallback aws write not blocked: %s\n' "$_fbw"; fi
_fbr=$(python3 "$PY" "aws s3 ls" "$_fbpol" 2>/dev/null)
if [ "${_fbr%%	*}" = "ALLOW" ]; then pass=$((pass+1)); else fail=$((fail+1)); printf '  FAIL fallback aws read not allowed: %s\n' "$_fbr"; fi
# render/vercel fallback must keep gate_all_writes (skeptical-review finding D —
# a broken JSON silently downgraded them to dev-allowed).
_fbv=$(python3 "$PY" "vercel deploy" "$_fbpol" 2>/dev/null)
if [ "${_fbv%%	*}" = "BLOCK" ]; then pass=$((pass+1)); else fail=$((fail+1)); printf '  FAIL fallback vercel write not blocked: %s\n' "$_fbv"; fi
_fbrn=$(python3 "$PY" "render deploy --env staging" "$_fbpol" 2>/dev/null)
if [ "${_fbrn%%	*}" = "BLOCK" ]; then pass=$((pass+1)); else fail=$((fail+1)); printf '  FAIL fallback render write not blocked: %s\n' "$_fbrn"; fi

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
  shim_check 0 "aws s3 ls"
  shim_check 2 "aws s3 rm s3://b/k"
  shim_check 2 "aws ec2 terminate-instances --instance-ids i-1"
  shim_check 2 "$(printf 'aws\ts3 rm s3://b/k')"   # tab between aws+service must not dodge the screen (finding C)
  # Per-command nonce approval: block -> approve(nonce) -> allow once -> consume -> block
  _NCMD="vercel deploy --prod"
  _NHASH=$(printf '%s' "$_NCMD" | shasum -a 256 | cut -c1-16); _N="$HOME/.claude/.cli-approve-$_NHASH"
  rm -f "$_N"
  shim_check 2 "$_NCMD"          # no nonce -> block
  touch "$_N"; shim_check 0 "$_NCMD"   # nonce present -> allow once
  shim_check 2 "$_NCMD"          # consumed -> block again
  rm -f "$_N"
  echo "  Shim results: $shim_pass passed, $shim_fail failed"
fi

echo ""
total_fail=$((fail + ${shim_fail:-0}))
echo "── TOTAL: core $pass/$((pass+fail)), shim ${shim_pass:-0}/$((${shim_pass:-0}+${shim_fail:-0})) ──"
[ "$total_fail" -eq 0 ] || exit 1
