#!/usr/bin/env bash
# stop.sh — codex Stop: land the queue, heartbeat the fabric, nudge on owed asks.
#
# Drains the gcc outbox synchronously (a queued send must not wait for the
# next turn when there may be none), then hands the payload to claude-ipc's
# own Stop hook, which heartbeats and blocks the turn once if a peer's ask is
# unanswered. Stop expects JSON on stdout or nothing; the ipc binary honours
# that, and we pass its stdout through untouched. Exit 0.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
gcc_read_input
gcc_export_env

bash "$CODEX_GCC_ROOT/hooks/drain-outbox.sh" "$SID" >/dev/null 2>&1 || true

ipc_bin=$(gcc_ipc_bin ipc-stop)
if [ -n "$ipc_bin" ]; then
  out=$(printf '%s' "$INPUT" | timeout 8 "$ipc_bin" 2>/dev/null)
  if [ -n "$out" ] && printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    printf '%s\n' "$out"
  fi
fi
exit 0
