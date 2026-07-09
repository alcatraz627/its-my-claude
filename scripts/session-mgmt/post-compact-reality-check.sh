#!/usr/bin/env bash
# post-compact-reality-check.sh — SessionStart injector, fires ONLY on source=="compact".
#
# Compaction reliably preserves task momentum while stripping negative constraints
# (the 18+-incident push-without-approval cluster traces to exactly this), and an
# agent cannot self-detect what it forgot. This injector is the mechanical reset:
# right after any compaction it re-arms the state-is-ephemeral + approvals-expired
# doctrine and points at the fresh precompact checkpoint for cross-checking.
# SessionStart(source:"compact") is used instead of PreCompact because it fires
# after BOTH auto and manual compaction, and PreCompact has a reported miss bug
# on manual /compact (gh anthropics/claude-code#13572).
#
# Runtime contract: runs inside sessionstart-inject.sh's injector array — reads
# the SessionStart payload on stdin, prints {additionalContext} or nothing.
# Always exits 0. Mute: touch ~/.claude/.no-postcompact-check (machine-wide).

set -uo pipefail
[ -f "$HOME/.claude/.no-postcompact-check" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || echo '{}')
src=$(printf '%s' "$INPUT" | jq -r '.source // empty' 2>/dev/null)
[ "$src" = "compact" ] || exit 0

cwd=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
ckpt_hint=""
if [ -n "$cwd" ] && [ -f "$cwd/_precompact-checkpoint.claude.md" ]; then
  ckpt_hint=" A fresh _precompact-checkpoint.claude.md exists in the project root — cross-check your understanding against it."
fi

msg="[post-compact] This session was just compacted. Three resets apply NOW:
1. AUTHORIZATIONS EXPIRED — any pre-compact approval for a push, deploy, or destructive op is void. Re-confirm with the user before any shared-state mutation, even mid-task; a terse \"keep going\" resumes local work only.
2. STATE IS EPHEMERAL — the summary is lossy and you cannot know what it dropped. Files on disk are the source of truth, not what you remember. Before the next side-effecting action, re-verify: git status + git log --oneline -3 + git diff --stat, plus liveness of any process you plan to rely on.${ckpt_hint}
3. NOTES CATCH-UP — update the session workspace notes with anything important that may have been dropped, before resuming the task."

jq -nc --arg m "$msg" '{additionalContext: $m}'
exit 0
