#!/usr/bin/env bash
# Suite for guard-secret-file-read.sh.
#
# The acceptance condition is the peer's, from prop-20260817-112815-df: replay
# the exact command that leaked and watch it blocked, then replay every safe
# command from the rotation and watch each one pass. Shipping an untested guard
# as the fix for an untested guard would be the same mistake in a fix's clothing.
#
# The allowlist half carries more test weight than the block half on purpose. A
# block that also stops legitimate inspection gets muted, and a muted guard
# protects nothing.

set -uo pipefail
H="$HOME/.claude/scripts/hooks/guard-secret-file-read.sh"
pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail+1)); printf '  FAIL  %s\n     %s\n' "$1" "${2:-}"; }

# verdict <tool-json> -> "deny" | "allow"
verdict() {
  local out
  out=$(printf '%s' "$1" | bash "$H" 2>/dev/null)
  if [ -z "$out" ]; then echo allow; return; fi
  printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "allow"' 2>/dev/null
}
bash_cmd() { jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }
read_tool() { jq -nc --arg p "$1" '{tool_name:"Read",tool_input:{file_path:$p}}'; }

blocks() { [ "$(verdict "$(bash_cmd "$1")")" = deny ] && ok "blocks: $1" || bad "did NOT block: $1"; }
allows() { [ "$(verdict "$(bash_cmd "$1")")" = allow ] && ok "allows: $1" || bad "wrongly blocked: $1"; }

echo "== the exact command that leaked =="
blocks "sed -E 's/=.*/=<redacted>/' pr-board/.env"

echo "== other ways to emit the same file =="
blocks "cat .env"
blocks "cat ~/project/.env.production"
blocks "head -20 config/secrets.pem"
blocks "tail -5 ~/.ssh/id_rsa"
blocks "xxd deploy.key | head"
blocks "base64 cert.p12"
blocks "strings ~/.netrc"
blocks "awk '{print}' .env.local"
blocks "cat .env | rg GITHUB"
blocks "< .env"

echo "== C1 (review 2026-08-18): bare rg/grep print matching LINES, values included =="
blocks "rg GITHUB_APP_KEY .env"
blocks "grep KEY .env"
blocks "rg -n KEY .env"
blocks "rg KEY deploy.pem"

echo "== I4 (review 2026-08-18): an allowlisted verb in one segment must not clear the others =="
blocks "ls -la .env && cat .env"
blocks "stat .env; sed -E 's/=.*/=x/' deploy.pem"
blocks "basename .env && xxd deploy.key"
allows "ls -la .env && wc -l .env"
allows "test -f .env && rg -c '=' .env"

echo "== the safe rotation commands must all survive =="
allows "rg -c '^[A-Z_]+=' .env"
allows "rg -o '^[A-Z_]+' .env"
allows "rg -q '^GITHUB_APP_KEY=' .env"
allows "rg -l 'GITHUB' .env"
allows "wc -l .env"
allows "shasum -a 256 deploy.key"
allows "stat .env"
allows "ls -la ~/.ssh/id_rsa"
allows "git check-ignore -v .env"
allows "openssl rsa -in deploy.key -pubout"
allows "ssh-keygen -y -f ~/.ssh/id_rsa"
allows "test -f .env && echo present"
allows "grep -c '=' .env"

echo "== the -o bypass, reported by automation with a live repro 2026-08-17 =="
# -o prints what the PATTERN matched and the pattern is the caller's, so an
# allowlist keyed on the flag admits everything the pattern can reach.
blocks "rg -o '.*' pr-board/.env"
blocks "rg -o 'GH_PRIVATE_KEY=.*' pr-board/.env"
blocks "rg --only-matching '.+' pr-board/pr-review-automation.private-key.pem"
blocks "grep -o '.*' .env"
# the reason -o is allowed at all: anchored, no wildcard, names only
allows "rg -o '^[A-Z_]+' .env"
allows "rg -o '^[A-Z_]+=' .env"

echo "== a .pem target isolates the verb; a .env target cannot =="
# `env` used to match inside the FILENAME, so for .env paths the verb list did
# no work at all. These pin the verb against a target with no such collision.
blocks "sed -E 's/x/y/' deploy.pem"
blocks "cat deploy.pem"
allows "wc -l deploy.pem"

echo "== files that are not secret-shaped are none of this guard's business =="
allows "cat README.md"
allows "cat src/env.ts"
allows "sed -E 's/=.*/=x/' package.json"
allows "cat environment.md"
allows "head docs/.env-example.md"

echo "== the Read tool on the same paths =="
[ "$(verdict "$(read_tool "$HOME/p/.env")")" = deny ] && ok "blocks Read of .env" || bad "Read of .env was not blocked"
[ "$(verdict "$(read_tool "$HOME/p/deploy.pem")")" = deny ] && ok "blocks Read of a .pem" || bad "Read of .pem was not blocked"
[ "$(verdict "$(read_tool "$HOME/p/README.md")")" = allow ] && ok "allows Read of an ordinary file" || bad "Read of README was blocked"

echo "== the refusal has to teach, or it just gets muted =="
msg=$(printf '%s' "$(bash_cmd "sed -E 's/=.*/=<redacted>/' pr-board/.env")" | bash "$H" 2>/dev/null | jq -r '.hookSpecificOutput.permissionDecisionReason')
case "$msg" in *"rg -o"*) ok "names a safe alternative" ;; *) bad "refusal offers no safe path" "$msg" ;; esac
case "$msg" in *"line-oriented"*) ok "explains why the hand-written redactor failed" ;;
  *) bad "does not explain the redactor trap" "$msg" ;; esac

echo "== the mute is honoured =="
M="$HOME/.claude/.no-secret-read-guard"
had_mute=0; [ -f "$M" ] && had_mute=1
touch "$M"
[ "$(verdict "$(bash_cmd "cat .env")")" = allow ] && ok "silent while the mute file exists" || bad "mute file did not silence the guard"
[ "$had_mute" -eq 1 ] || rm -f "$M"

printf '  ---- %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
