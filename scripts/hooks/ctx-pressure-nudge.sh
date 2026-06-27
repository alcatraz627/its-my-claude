#!/usr/bin/env bash
# ctx-pressure-nudge.sh — warn the agent before the context window gets dangerous.
#
# The statusline already knows how full the context is and writes the real,
# tier-aware "% remaining" to /tmp/claude-ctx-<claude-pid> every render, but no
# hook reads it — so every context-boundary nudge until now used proxies (idle,
# cwd). This hook reads the real number and speaks up once the window enters the
# rate-limit danger zone (>80% full), where the large majority of this account's
# transient 429 errors occur. It matters most on the 1M-token tier, which has
# NO early autocompact at all (verified: sessions sit at 92-99% full for many
# turns there) — so this nudge is the only early-checkpoint signal on that tier.
#
# Two halves, so it is not advisory-only:
#   1. a graded {additionalContext} nudge (the agent can act on it), and
#   2. at a higher bar, a MECHANICAL enqueue of a retro core-dump via the
#      existing opt-in auto-coredump queue — so a reasoning checkpoint survives
#      even if the agent ignores the nudge. The enqueue is a no-op unless the
#      user has opted in (~/.claude/.auto-coredump-enabled), so it never spends
#      tokens behind their back.
#
# Runtime contract: UserPromptSubmit hook, registered DIRECTLY in settings.json
# (not via the orchestrator — the orchestrator discards stdout, which would drop
# the injection, and $PPID must resolve to the claude process to find the ctx
# file). Reads the hook payload on stdin; prints one {additionalContext} object
# when it fires, nothing otherwise. Always exits 0 — a UserPromptSubmit hook
# must never block the prompt. Rate-limited per session so it never nags.

set -uo pipefail

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[[ -z "$sid" ]] && exit 0

# Remaining context %, tier-aware. Prefer the stdin field; fall back to the file
# the statusline persists (hook $PPID == claude pid, verified).
rem=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)
if [[ -z "$rem" || "$rem" == "null" ]]; then
  ctx_file="/tmp/claude-ctx-${PPID}"
  [[ -f "$ctx_file" ]] && rem=$(tr -dc '0-9.' < "$ctx_file" 2>/dev/null)
fi
[[ -z "$rem" ]] && exit 0

# used % = 100 - remaining %
used=$(awk -v r="$rem" 'BEGIN { printf "%d", 100 - r }' 2>/dev/null)
[[ -z "$used" ]] && exit 0

# Below the danger zone → silent.
(( used < 80 )) && exit 0

# Rate-limit: fire at most once per 10 min per session, but always re-fire when
# the pressure escalates into a higher band (80 → 90).
state="/tmp/claude-ctxpress-${sid:0:8}"
now=$(date +%s)
last_ts=0
last_band=0
if [[ -f "$state" ]]; then
  last_ts=$(grep '^ts=' "$state" 2>/dev/null | cut -d= -f2); last_ts=${last_ts:-0}
  last_band=$(grep '^band=' "$state" 2>/dev/null | cut -d= -f2); last_band=${last_band:-0}
fi

band=80
(( used >= 90 )) && band=90
if (( band <= last_band )) && (( now - last_ts < 600 )); then
  exit 0
fi
{ echo "ts=$now"; echo "band=$band"; } > "$state"

# Mechanical half (opt-in): at >=85% full, enqueue a retro core-dump so a
# reasoning checkpoint survives regardless of agent compliance. The enqueue
# script is a no-op unless the user opted in; touch is idempotent.
enq=""
if (( used >= 85 )); then
  printf '%s' "$input" | bash "$HOME/.claude/scripts/session-mgmt/enqueue-auto-coredump.sh" >/dev/null 2>&1 || true
  [[ -f "$HOME/.claude/.auto-coredump-enabled" ]] && enq=" A retro core-dump has been queued for this session."
fi

if (( used >= 90 )); then
  msg="[ctx-pressure] Context is ~${used}% full. On the 1M-token tier there is no early autocompact, and this is deep in the rate-limit zone (most transient 429s strike above 80% fill). Checkpoint now: /core-dump then /clear, or land and wrap up the current thread.${enq}"
else
  msg="[ctx-pressure] Context is ~${used}% full — entering the rate-limit danger zone (the large majority of past 429s occurred above 80% fill). Good moment to /core-dump + /clear if you're switching focus, or to finish the current step before it grows.${enq}"
fi

jq -nc --arg m "$msg" '{additionalContext: $m}'
exit 0
