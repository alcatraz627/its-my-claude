#!/usr/bin/env bash
# pre-tool-bash.sh — codex PreToolUse[Bash]: run the gcc guards that matter after
# the fact, unchanged, against codex's shell commands.
#
# Codex sends the same payload Claude Code does ({tool_name:"Bash",
# tool_input:{command}}), and codex accepts the same block shapes
# ({"decision":"block"}, permissionDecision:"deny", or exit 2 + stderr), so the
# guards below run as they are. Only the environment is re-keyed (lib.sh).
#
# The list is CURATED, not the 40 PreToolUse registrations of settings.json.
# Most of those tune a teammate (ripgrep preference, comment hygiene, WAL,
# tab title); a contractor's output is reviewed anyway. These guard the verbs
# where review comes after the damage. Add a guard by adding one line.
#
# Sequential, first block wins; additionalContext from passing guards is merged.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
gcc_read_input
gcc_export_env

H="$HOME/.claude/scripts"
GUARDS=(
  "$H/safe-delete.sh"                          # rm → trash
  "$H/hooks/guard-git-push.sh"                 # main/protected pushes need the owner
  "$H/hooks/guard-user-commit.sh"              # protected repos: commits are the owner's
  "$H/hooks/guard-commit-signature.sh"         # no harness trailers in commits
  "$H/hooks/guard-anthropic-credentials.sh"    # never touch the global-blast-radius key
  "$H/hooks/guard-secret-file-read.sh"         # .env and friends
  "$H/hooks/guard-system-dir-writes.sh"        # /usr, /etc, ~/Library ...
  "$H/hooks/block-curl-post-auth.sh"           # no credentialed POSTs from a seat
  "$H/hooks/guard-github-agent-marker.sh"      # gh comments carry the agent marker
)

contexts=()
for g in "${GUARDS[@]}"; do
  [ -x "$g" ] || [ -f "$g" ] || continue
  err=$(mktemp "${TMPDIR:-/tmp}/gcc-guard.XXXXXX")
  out=$(printf '%s' "$INPUT" | timeout 10 bash "$g" 2>"$err"); rc=$?
  stderr=$(cat "$err" 2>/dev/null); rm -f "$err"
  if [ "$rc" -eq 2 ]; then
    jq -cn --arg r "[$(basename "$g")] ${stderr:-blocked}" '{decision:"block", reason:$r}'
    exit 0
  fi
  [ -n "$out" ] || continue
  dec=$(printf '%s' "$out" | jq -r '(.decision // .hookSpecificOutput.permissionDecision // empty)' 2>/dev/null)
  case "$dec" in
    block|deny)
      reason=$(printf '%s' "$out" | jq -r '(.reason // .hookSpecificOutput.permissionDecisionReason // "blocked")' 2>/dev/null)
      jq -cn --arg r "[$(basename "$g")] $reason" '{decision:"block", reason:$r}'
      exit 0 ;;
  esac
  ctx=$(gcc_ctx_of "$out")
  [ -n "$ctx" ] && contexts+=("$ctx")
done

if [ "${#contexts[@]}" -gt 0 ]; then
  jq -cn --arg t "$(printf '%s\n' "${contexts[@]}")" '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$t}}'
fi
exit 0
