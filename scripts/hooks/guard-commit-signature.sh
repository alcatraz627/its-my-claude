#!/bin/bash
# Hard gate: no AI-signature trailers reach any commit, and no bypassing the
# git-level check. Blocks a `git commit` whose command text carries a Claude
# trailer (Co-Authored-By Claude / Claude-Session / Generated with Claude Code /
# a claude.ai/code URL), and blocks `--no-verify`/`-n` on commits, which would
# skip the commit-msg hook that enforces the same ban inside git (migration
# 0040; owner ruling 2026-07-28: hard block, not silent strip).
#
# Layer 2 of 2: the git-level commit-msg hook rejects trailers in every local
# commit; this guard catches what that hook cannot see — --no-verify runs and
# repos whose local core.hooksPath bypasses the global hook dir. Out of scope
# by construction: commits created server-side (GitHub API, squash-merge).
# Mute (owner only): touch ~/.claude/.no-commit-signature-gate

set -uo pipefail
[ -f "$HOME/.claude/.no-commit-signature-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# in scope: local message writes, and gh pr bodies (the other stamped surface)
is_commit=0; is_pr=0
printf '%s' "$cmd" | rg -q 'git[^|;&]*\bcom''mit\b' && is_commit=1
printf '%s' "$cmd" | rg -q 'gh[^|;&]*\bpr\b[^|;&]*\b(create|edit|comment|review|merge)\b' && is_pr=1
[ "$is_commit" = "1" ] || [ "$is_pr" = "1" ] || exit 0

block() {
  jq -n --arg r "$1" '{decision: "block", reason: $r}'
  exit 0
}

if printf '%s' "$cmd" | rg -q -e 'Co-.uthored-.y:.{0,20}Claude' -e 'Claude-Session:' -e 'Generated with .?Claude Code' -e 'claude\.ai/code/session'; then
  block "Commit message or PR body carries an AI signature trailer (Co-Authored-By Claude / Claude-Session / Generated with Claude Code). The owner bans these in every repo, any model (rules/git.md § Commit message style). Remove the trailer lines from the message and rerun the commit."
fi

if [ "$is_pr" = "1" ] && printf '%s' "$cmd" | rg -q ' — '; then
  block "PR body carries a connective em-dash. PR descriptions are docs register (rules/audience-aware-writing.md): owner budget is zero. Reword and rerun."
fi

if [ "$is_commit" = "1" ] && printf '%s' "$cmd" | rg -q -e 'commit[^|;&]*--no-verify' -e 'commit[^|;&]*\s-n\b' -e 'commit[^|;&]*\s-[a-zA-Z]*n[a-zA-Z]*\s'; then
  # -n bundled into short flags (e.g. -an) is rare but real; better a rare
  # false block with a clear next step than a silent bypass of the msg gate
  block "git commit with --no-verify/-n skips the commit-msg hook that enforces the no-AI-signature ban (migration 0040). Rerun without --no-verify. If a repo's own hooks are the obstacle, fix the message or ask the owner — bypassing the gate is not available."
fi

exit 0
