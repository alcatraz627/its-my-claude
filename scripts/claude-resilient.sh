#!/usr/bin/env bash
# claude-resilient.sh — DEPRECATED. Does not reliably do what its name claims.
#
# This was meant to auto-retry `claude` through API errors. It does not work for
# either real use case, verified 2026-06-18 against 48h of transcripts
# (assets/reports/20260618-api-error-48h-analysis/findings.md):
#
#   - INTERACTIVE: a transient 429 surfaces inline and the REPL keeps running —
#     the process never exits non-zero, so the exit-code-gated retry below can
#     never fire. Clean quit=0 and Ctrl+C=130 are both non-retryable.
#   - HEADLESS (`-p`): even here the retry is bare `claude --continue` with no
#     args, which DROPS the original `-p` prompt — so the one case it could
#     theoretically serve, it corrupts.
#
# Kept only as a record of the approach. Do NOT alias `claude` to this and do
# NOT rely on it. For the real lessons see the report above; for interactive
# recovery there is no process-wrapper fix (Claude Code emits no Stop/Notification
# on an API-error abort) — that path is handled by hooks/api-recovery-nudge.sh.
#
# Env (legacy, only if you knowingly run the deprecated path):
#   CLAUDE_BIN, CLAUDE_RESILIENT_MAX_RETRIES, CLAUDE_RESILIENT_BASE_SLEEP,
#   CLAUDE_RESILIENT_BACKOFF, CLAUDE_RESILIENT_DISABLED=1.

set -uo pipefail

# Loud, non-fatal: anyone who runs this should know it's deprecated and broken
# for its stated purpose. Goes to stderr so it never pollutes captured stdout.
printf '%s\n' \
  '[claude-resilient] DEPRECATED & non-functional for its stated purpose — see' \
  '[claude-resilient] assets/reports/20260618-api-error-48h-analysis/findings.md' >&2

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
