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

# Claude's first substantive prompt gets one query-ranked dream pass when
# ambient dream guidance is enabled. The shared engine owns deduplication.
if [ -f "$HOME/.claude/subconscious/dreams/.inject-on" ] || [ "${INJECT_DREAM:-}" = 1 ]; then
  dout=$(printf '%s' "$INPUT" | bash "$HOME/.claude/scripts/dream/dream-insights-prompt.sh" 2>/dev/null || true)
  dctx=$(gcc_ctx_of "$dout")
  [ -n "$dctx" ] && parts+=("$dctx")
fi

# The push gate's typed-approval channel, the same hook Claude sessions run:
# "approve push <nonce>" / "cancel push" writes or clears this session's
# single-use sentinel, keyed by the same session_id guard-git-push.sh uses.
pa=$(printf '%s' "$INPUT" | bash "$HOME/.claude/scripts/hooks/push-approve-prompt.sh" 2>/dev/null)
pctx=$(gcc_ctx_of "$pa")
[ -n "$pctx" ] && parts+=("$pctx")

# Record which fields Codex's prompt payload carries (names only, never
# values), so the field the push hook reads can be confirmed against reality.
mkdir -p "$CODEX_GCC_ROOT/state" 2>/dev/null
printf '%s' "$INPUT" | jq -c '{seen: (now | todate), keys: keys}' > "$CODEX_GCC_ROOT/state/ups-payload-keys.json" 2>/dev/null || true
ipc_bin=$(gcc_ipc_bin ipc-ups)
if ! gcc_is_managed_host_hook && [ -n "$ipc_bin" ]; then
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
