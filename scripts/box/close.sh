#!/usr/bin/env bash
# close.sh — the lede block: the renderer that owns position 1 of an
# owner-facing reply (regfric build D1, owner-approved 2026-08-20).
#
# The sweep behind it: a question buried in prose gets answered 1 time in 19;
# owners read verdict -> needs-you -> next, while agents write in production
# order. This script emits the consumption-order block so the shape lives in
# a renderer, not in session memory. Ledger: the emitted nonce is written to
# /tmp/claude-lede-<sid8>/nonce; reply-lede-stop.sh checks the reply carries it.
#
# Usage:
#   close.sh --sid <sid8> --verdict "<what is true now>" --next "<one action>" \
#            [--ask "authority|text|drafted answer"]... [--tasks]
#   --tasks pulls needs-you rows from the pinned task store (task-table --json).
# Authority tags (c4 table): push-main | spend | publish | delete | taste |
#   owner-fact | scope-fork. An ask without one of these does not belong here.
set -uo pipefail
SID=""; VERDICT=""; NEXT=""; TASKS=0; ASKS=()
while [ $# -gt 0 ]; do case "$1" in
  --sid) SID="$2"; shift 2;; --verdict) VERDICT="$2"; shift 2;;
  --next) NEXT="$2"; shift 2;; --ask) ASKS+=("$2"); shift 2;;
  --tasks) TASKS=1; shift;; *) echo "close.sh: unknown arg $1" >&2; exit 2;; esac; done
[ -n "$VERDICT" ] && [ -n "$NEXT" ] || { echo "close.sh: --verdict and --next are required (empty fields are the defect this exists to stop)" >&2; exit 2; }
NONCE=$(hexdump -n3 -e '3/1 "%02x"' /dev/urandom 2>/dev/null || date +%s | tail -c 7)
if [ "$TASKS" = 1 ]; then
  rows=$(bash ~/.claude/scripts/task-table/task-table.sh --json 2>/dev/null | \
    jq -r '.tasks[]? | select((.status=="pending" or .status=="in_progress") and ((.blockedOn // .blocked_on // "") | test("USER|owner";"i"))) | "\(.subject) (#\(.id)) · \(.blockedOn // .blocked_on)"' 2>/dev/null)
  while IFS= read -r r; do [ -n "$r" ] && ASKS+=("owner-fact|$r|"); done <<< "$rows"
fi
n=${#ASKS[@]}
printf '── lede·%s ──────────────────────────────────\n' "$NONCE"
printf 'verdict   %s\n' "$VERDICT"
if [ "$n" -eq 0 ]; then printf 'needs-you nothing needs you\n'; else
  printf 'needs-you %d decision(s)\n' "$n"
  for a in "${ASKS[@]}"; do
    IFS='|' read -r tag text draft <<< "$a"
    printf '  · [%s] %s' "$tag" "$text"
    [ -n "$draft" ] && printf ' — my answer: %s' "$draft"; printf '\n'
  done
fi
printf 'next      %s\n' "$NEXT"
printf '────────────────────────────────────────────────\n'
[ -n "$SID" ] && { mkdir -p "/tmp/claude-lede-$SID"; printf '%s' "$NONCE" > "/tmp/claude-lede-$SID/nonce"; }
