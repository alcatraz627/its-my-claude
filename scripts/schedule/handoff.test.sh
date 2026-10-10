#!/bin/bash
# Exercises handoff.sh end to end in a throwaway folder: raise, carry over,
# done, tag, list. Exits non-zero on the first failed check.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d)"
export HANDOFF_DIR="$T/handoffs" HANDOFF_QUIET=1
H="$HERE/handoff.sh"
fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

printf 'Do the weekly thing.\n' > "$T/p.md"
bash "$H" raise wk "Weekly session" /tmp opus "$T/p.md" >/dev/null
check "raise writes an open card with the prompt" \
  '[[ "$(jq -r .prompt "$HANDOFF_DIR/wk.json")" == "Do the weekly thing." && "$(jq -r ".done_at // \"open\"" "$HANDOFF_DIR/wk.json")" == open ]]'
bash "$H" raise wk "Weekly session" /tmp opus "$T/p.md" >/dev/null
check "re-raising an open card counts a carry-over" '[[ "$(jq -r .carried "$HANDOFF_DIR/wk.json")" == 1 ]]'
bash "$H" done wk >/dev/null
check "done stamps done_at" 'jq -e .done_at "$HANDOFF_DIR/wk.json" >/dev/null'
bash "$H" raise wk "Weekly session" /tmp opus "$T/p.md" >/dev/null
check "raising after done starts a fresh card" '[[ "$(jq -r .carried "$HANDOFF_DIR/wk.json")" == 0 ]] && ! jq -e .done_at "$HANDOFF_DIR/wk.json" >/dev/null'
bash "$H" tag "check the svc merge" >/dev/null
check "tag queues one note" '[[ "$(ls "$HANDOFF_DIR/tags" | wc -l | tr -d " ")" == 1 ]]'
out="$(bash "$H" list)"
check "list shows the open card and the tag count" '[[ "$out" == *"OPEN  wk"* && "$out" == *"queued for the next weekly session: 1"* ]]'
check "history records every raise and done" '[[ "$(wc -l < "$HANDOFF_DIR/history.jsonl" | tr -d " ")" == 4 ]]'
check "a missing prompt file fails" '! bash "$H" raise x t /tmp opus "$T/nope.md" 2>/dev/null'

trash "$T" 2>/dev/null || true
exit $fail
