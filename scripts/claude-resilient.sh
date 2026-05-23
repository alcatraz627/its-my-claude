#!/usr/bin/env bash
# claude-resilient.sh — wraps `claude` with exponential-backoff retry for API
# errors, rate limits, and transient network issues. On retry, uses
# `claude --continue` so the same session is resumed rather than started fresh.
#
# Usage:
#   claude-resilient.sh [claude-args...]
#
# Examples:
#   claude-resilient.sh                       # interactive, auto-retry on API error
#   claude-resilient.sh -p "summarize repo"   # one-shot, auto-retry
#
# Env:
#   CLAUDE_BIN                     — binary to wrap (default: claude)
#   CLAUDE_RESILIENT_MAX_RETRIES   — max retries (default: 3)
#   CLAUDE_RESILIENT_BASE_SLEEP    — first backoff seconds (default: 5)
#   CLAUDE_RESILIENT_BACKOFF       — multiplier between retries (default: 3)
#   CLAUDE_RESILIENT_DISABLED=1    — disable retries; first failure is final
#
# Exit-code policy:
#   0                    — success; exit immediately
#   130 (SIGINT)         — user Ctrl+C; never retry, propagate exit
#   143 (SIGTERM)        — shell/OS kill; never retry, propagate exit
#   anything else        — treated as retryable (API/network/5xx/rate limit)
#
# All retry attempts use `claude --continue` regardless of the original args,
# so the conversation state is preserved and we don't re-prompt from scratch.
#
# This script is intended to be invoked manually (or via alias/symlink) in
# place of `claude`. It is NOT a hook; it does not consume stdin JSON.

set -uo pipefail

CLAUDE_BIN="${CLAUDE_BIN:-claude}"
MAX_RETRIES="${CLAUDE_RESILIENT_MAX_RETRIES:-3}"
BASE_SLEEP="${CLAUDE_RESILIENT_BASE_SLEEP:-5}"
BACKOFF="${CLAUDE_RESILIENT_BACKOFF:-3}"
DISABLED="${CLAUDE_RESILIENT_DISABLED:-0}"

log() {
  printf '[claude-resilient] %s\n' "$*" >&2
}

# First attempt: pass all args through verbatim
"$CLAUDE_BIN" "$@"
EXIT=$?

# Success or explicitly disabled — exit now
if [ "$EXIT" -eq 0 ] || [ "$DISABLED" = "1" ]; then
  exit "$EXIT"
fi

# User-initiated exits never retried
case "$EXIT" in
  130|143)
    exit "$EXIT"
    ;;
esac

# Retry loop with exponential backoff
RETRY=0
SLEEP="$BASE_SLEEP"
while [ "$RETRY" -lt "$MAX_RETRIES" ]; do
  RETRY=$((RETRY + 1))
  log "exit=$EXIT — retry $RETRY/$MAX_RETRIES in ${SLEEP}s (via --continue)"
  sleep "$SLEEP"
  "$CLAUDE_BIN" --continue
  EXIT=$?
  if [ "$EXIT" -eq 0 ]; then
    log "recovered on retry $RETRY"
    exit 0
  fi
  case "$EXIT" in
    130|143)
      exit "$EXIT"
      ;;
  esac
  SLEEP=$((SLEEP * BACKOFF))
done

log "exhausted $MAX_RETRIES retries — final exit=$EXIT"
exit "$EXIT"
