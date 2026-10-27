#!/usr/bin/env bash
# wake-breaker.sh: skips a scheduled wake when nothing has changed since the last one.
#
# An agent's own recurring wake kept firing every 30 minutes for six hours while
# it was blocked on the owner, each time re-reading its whole context to say the
# same thing (clanky-opus, 2026-10-14). This lets the first wake through, then
# skips each later one, before the model runs, until something moves: a new
# commit, a changed file in the repo, or any other message reaching the session
# (the owner, a peer, a finished background task). Keep-warm's own wakes are left
# to keep-warm. Repos only: outside git there is no cheap progress signal, so
# every wake passes.
#
# Wakes are recognised by the prompt hashes guard-cron-prompt.sh records, not by
# guessing who sent a prompt. Runs as UserPromptSubmit.
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
dir="/tmp/claude-wakes-${sid:0:8}"
[ -f "$dir/crons" ] || exit 0
now=$(date +%s)

h=$(printf '%s' "$prompt" | shasum | cut -c1-16)
if ! rg -qxF "$h" "$dir/crons" 2>/dev/null; then
  printf '%s' "$now" > "$dir/other"   # any other message is news
  exit 0
fi
# Keep-warm, usage hibernation pings and the fleet check repeat by design: what they
# watch lives outside this repo, so an unchanged tree says nothing about them.
case "$prompt" in "[keepwarm]"*|"[usage-carry]"*|"[usage-resume]"*|"[fleet-watch]"*) exit 0 ;; esac

head=$(git -C "$cwd" rev-parse HEAD 2>/dev/null) || exit 0
tree=$(git -C "$cwd" status --porcelain 2>/dev/null | shasum | cut -c1-16)
fp="$head:$tree"
other=$(cat "$dir/other" 2>/dev/null || echo 0)
prev_fp=$(jq -r '.fp // empty' "$dir/last" 2>/dev/null)
prev_at=$(jq -r '.at // 0' "$dir/last" 2>/dev/null)

if [ "$fp" = "$prev_fp" ] && [ "$other" -le "$prev_at" ]; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook wake-breaker --action skip --heeded n/a >/dev/null 2>&1 || true
  jq -cn '{decision:"block", reason:"wake skipped: nothing changed since the last one", suppressOutput:true}'
  exit 0
fi
jq -cn --arg fp "$fp" --argjson at "$now" '{fp:$fp, at:$at}' > "$dir/last"
exit 0
