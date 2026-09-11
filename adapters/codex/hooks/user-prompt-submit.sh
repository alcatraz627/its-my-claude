#!/usr/bin/env bash
# user-prompt-submit.sh — codex UserPromptSubmit: mail in, receipts in.
#
# Drains this session's gcc outbox (so anything queued last turn has landed),
# injects pending claude-ipc messages via claude-ipc's own hook binary, then
# the unread receipts. One UserPromptSubmit JSON object, or nothing. Exit 0.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
gcc_read_input
gcc_export_env

bash "$CODEX_GCC_ROOT/hooks/drain-outbox.sh" "$SID" >/dev/null 2>&1 || true

parts=()
ipc_bin=$(gcc_ipc_bin ipc-ups)
if [ -n "$ipc_bin" ]; then
  out=$(printf '%s' "$INPUT" | timeout 8 "$ipc_bin" 2>/dev/null)
  ctx=$(gcc_ctx_of "$out")
  [ -n "$ctx" ] && parts+=("$ctx")
fi

r=$(bash "$CODEX_GCC_ROOT/hooks/receipts.sh" "$SID" 2>/dev/null)
[ -n "$r" ] && parts+=("[gcc·codex] receipts for calls you queued through gcc:
$r")

[ "${#parts[@]}" -gt 0 ] || exit 0
gcc_emit_ctx UserPromptSubmit "$(printf '%s\n\n' "${parts[@]}")"
exit 0
