#!/usr/bin/env bash
# Concurrency test for ledger_append (scripts/ledger/ledger-common.sh).
#
# There is no `flock` on macOS, so the original `flock -x 9 || true` idiom fell
# through to an unlocked `>>` in every ledger — protected-looking, unprotected in
# fact. This test induces the state that matters: many concurrent writers emitting
# lines LONGER than PIPE_BUF, which is exactly where an unlocked append interleaves
# and produces a corrupt line an append-only store can never repair.
#
#   bash ~/.claude/scripts/tests/test-ledger-append.sh
set -uo pipefail

source "$HOME/.claude/scripts/ledger/ledger-common.sh" || { echo "cannot source ledger-common.sh"; exit 1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
STORE="$T/store.jsonl"; LOCK="$T/store.lock"
: > "$STORE"

WRITERS=24
# Well over PIPE_BUF (4096) so a bare >> is genuinely at risk of tearing.
PAYLOAD=$(head -c 9000 < /dev/zero | tr '\0' 'x')

echo "ledger_append concurrency:"
echo "  flock present: $(command -v flock >/dev/null 2>&1 && echo yes || echo 'NO (mkdir lock path)')"
echo "  writers: $WRITERS   line size: ~9KB (>PIPE_BUF)"

for i in $(seq 1 "$WRITERS"); do
  (
    line=$(printf '{"id":%d,"pad":"%s"}' "$i" "$PAYLOAD")
    ledger_append "$STORE" "$LOCK" "$line"
  ) &
done
wait

lines=$(wc -l < "$STORE" | tr -d ' ')
valid=$(jq -c . "$STORE" 2>/dev/null | wc -l | tr -d ' ')
ids=$(jq -r '.id' "$STORE" 2>/dev/null | sort -n | uniq | wc -l | tr -d ' ')

fail=0
if [ "$lines" = "$WRITERS" ]; then
  printf '  \033[32mPASS\033[0m  %s lines written, none lost\n' "$lines"
else
  printf '  \033[31mFAIL\033[0m  expected %s lines, got %s\n' "$WRITERS" "$lines"; fail=1
fi

if [ "$valid" = "$WRITERS" ]; then
  printf '  \033[32mPASS\033[0m  every line is valid JSON (no interleaving)\n'
else
  printf '  \033[31mFAIL\033[0m  only %s/%s lines parse as JSON — appends interleaved\n' "$valid" "$WRITERS"; fail=1
fi

if [ "$ids" = "$WRITERS" ]; then
  printf '  \033[32mPASS\033[0m  all %s distinct writers landed exactly once\n' "$WRITERS"
else
  printf '  \033[31mFAIL\033[0m  %s distinct ids, expected %s\n' "$ids" "$WRITERS"; fail=1
fi

# The lock must not be left behind, or the next writer stalls its full budget.
if [ ! -d "${LOCK}.d" ]; then
  printf '  \033[32mPASS\033[0m  no stale lock dir left behind\n'
else
  printf '  \033[31mFAIL\033[0m  stale lock dir %s.d survived\n' "$LOCK"; fail=1
fi

echo
[ "$fail" = "0" ] && echo "all passed" || echo "FAILURES"
exit "$fail"
