#!/usr/bin/env bash
# drain-outbox.sh — apply the ledger and IPC writes a codex session queued.
#
# Codex's sandbox blocks writes outside the workspace and blocks the claude-ipc
# socket, so `gcc` (adapters/codex/bin/gcc) queues those calls to
# /tmp/codex-gcc/outbox/<sid>.jsonl when they fail. Hooks run OUTSIDE the
# sandbox, so this script, called from PostToolUse (async), Stop, SessionEnd
# and UserPromptSubmit, replays each queued argv with the environment re-keyed
# to the codex session and writes a receipt line the next turn shows the model.
#
#   drain-outbox.sh <sid>      drain one session's queue
#   drain-outbox.sh --all      drain every queue (SessionEnd, 3s budget)
#
# Safe to run concurrently: the queue file is renamed to .inflight before it is
# read, so a `gcc` call landing mid-drain starts a fresh file. Always exits 0.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# The queue file sits in /tmp, which the seat's sandbox can write, so a seat could
# append any argv it likes and have this hook run it OUTSIDE the sandbox. The
# gcc CLI is therefore not the trust boundary; this allowlist is. Only the exact
# commands gcc maps (adapters/codex/bin/gcc) replay; anything else is refused
# and the refusal lands in the receipts where the seat, and the owner, see it.
# Found by the codex adversarial review of 2026-09-11 (finding D1).
argv_allowed() {
  local a0="${1:-}" a1="${2:-}" H="$HOME/.claude"
  case "$a0" in
    # Only the messaging verbs a seat needs; admin verbs (daemon, prune, cancel
    # of others' asks) never replay from a queue. Validator major 2, 2026-09-11.
    claude-ipc) case "$a1" in send|reply|register|accept|decline|snooze) return 0 ;; esac ;;
    i-dream) [ "$a1" = pin ] && return 0 ;;
    bash) case "$a1" in
            "$H/scripts/propose.sh"|"$H/scripts/atone.sh"|"$H/scripts/affirm.sh"|"$H/scripts/ledger/ledger.sh"|"$H/adapters/codex/checkpoint-register.sh") return 0 ;;
          esac ;;
  esac
  return 1
}

# A drain that died mid-file (hook timeout, session torn down) leaves an
# .inflight file nobody replays. Any inflight older than five minutes is folded
# back onto the queue before this drain starts, so a queued write is never lost
# to a crash. Review finding D6.
recover_inflight() {
  local q="$1" f
  for f in "${q%.jsonl}".inflight.*; do
    [ -f "$f" ] || continue
    if [ -n "$(find "$f" -mmin +5 2>/dev/null)" ]; then cat "$f" >> "$q" && rm -f "$f"; fi
  done
}

drain_one() {
  local q="$1" sid inflight receipts n ts verb argv_json rc out
  sid=$(basename "$q" .jsonl)
  inflight="${q%.jsonl}.inflight.$$"
  receipts="$GCC_OUTBOX_DIR/$sid.receipts.jsonl"
  recover_inflight "$q"
  [ -s "$q" ] || return 0
  mv -f "$q" "$inflight" 2>/dev/null || return 0
  SID="$sid"; CWD=$(jq -r 'select(.cwd) | .cwd' "$inflight" 2>/dev/null | head -1)
  [ -n "$CWD" ] || CWD="$PWD"
  gcc_export_env
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$(printf '%s' "$line" | jq -r '.n // 0')
    verb=$(printf '%s' "$line" | jq -r '.verb // "?"')
    argv_json=$(printf '%s' "$line" | jq -c '.argv // []')
    # argv → positional params, byte-exact, no shell re-parsing.
    set --
    while IFS= read -r a; do set -- "$@" "$a"; done < <(printf '%s' "$argv_json" | jq -r '.[]')
    if argv_allowed "$@"; then
      out=$(cd "$CWD" 2>/dev/null && "$@" 2>&1); rc=$?
    else
      out="refused: '${1:-} ${2:-}' is not a gcc verb this hook replays (only claude-ipc, propose.sh, atone.sh, affirm.sh, ledger.sh, i-dream pin, checkpoint-register.sh). Queue lines are only honoured when written by bin/gcc."; rc=126
    fi
    # An idle-pruned alias makes every ipc send fail with not_registered. The
    # drainer runs outside the sandbox with the session env re-keyed, so it can
    # re-register the cx- alias and retry once; the session never has to know.
    if [ "$rc" -ne 0 ] && [ "$verb" = ipc ] && printf '%s' "$out" | grep -q not_registered; then
      claude-ipc register "$CLAUDE_IPC_ALIAS" >/dev/null 2>&1 \
        && { out=$(cd "$CWD" 2>/dev/null && "$@" 2>&1); rc=$?; }
    fi
    ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    jq -cn --argjson n "$n" --arg ts "$ts" --arg verb "$verb" --argjson rc "$rc" \
      --arg out "$(printf '%s' "$out" | tail -c 400)" \
      '{n:$n, ts:$ts, verb:$verb, exit:$rc, out:$out}' >> "$receipts"
  done < "$inflight"
  rm -f "$inflight"
}

mkdir -p "$GCC_OUTBOX_DIR" 2>/dev/null || exit 0
case "${1:-}" in
  --all) for q in "$GCC_OUTBOX_DIR"/*.jsonl; do
           case "$q" in *.receipts.jsonl) continue;; esac
           [ -e "$q" ] && drain_one "$q"
         done ;;
  "")    exit 0 ;;
  *)     drain_one "$GCC_OUTBOX_DIR/$1.jsonl" ;;
esac
exit 0
