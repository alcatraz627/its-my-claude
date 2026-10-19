#!/usr/bin/env bash
# Checks the i-dream verify SessionStart injector against a fake i-dream binary:
# silent when every row passes, one line naming each failing row with its detail,
# silent again when the same set fails twice, and spoken again when the set changes.
# Run: bash ~/.claude/scripts/dream/idream-verify-inject.test.sh
set -uo pipefail

INJ="$(cd "$(dirname "$0")" && pwd)/idream-verify-inject.sh"
pass=0; fail=0
ok()  { echo "  ok    $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }

T=$(mktemp -d /tmp/idream-verify-inject-test.XXXXXX)
trap 'trash "$T" 2>/dev/null || true' EXIT
FAKE="$T/i-dream"
printf '#!/usr/bin/env bash\ncat "%s/doc.json"\nexit 1\n' "$T" > "$FAKE"
chmod +x "$FAKE"
doc() { printf '%s' "$1" > "$T/doc.json"; }
run() { printf '{}' | INJECT_ONCE_DIR="$T/.once" IDREAM_BIN="$FAKE" bash "$INJ" 2>/dev/null; }

doc '{"checks":[{"row":"cycle-ran","verdict":"pass","detail":"ok"},{"row":"effect","verdict":"unknown","detail":"n/a"}]}'
out=$(run)
[ -z "$out" ] && ok "all rows passing: silent" || bad "all passing emitted '$out'"

doc '{"checks":[{"row":"cycle-ran","verdict":"pass","detail":"ok"},{"row":"cycle-budget","verdict":"fail","detail":"2.56x its budget"},{"row":"ingest-queue","verdict":"fail","detail":"689 queued"}]}'
ctx=$(run | jq -r '.additionalContext // empty' 2>/dev/null)
case "$ctx" in *"cycle-budget (2.56x its budget) · ingest-queue (689 queued)"*) ok "names each failing row with its detail" ;; *) bad "failing rows wrong: $ctx" ;; esac
case "$ctx" in *"cycle-ran"*) bad "lists a passing row" ;; *) ok "leaves passing rows out" ;; esac

out=$(run)
[ -z "$out" ] && ok "same failing set again: silent" || bad "repeated itself: '$out'"

doc '{"checks":[{"row":"cycle-budget","verdict":"fail","detail":"1.2x"}]}'
ctx=$(run | jq -r '.additionalContext // empty' 2>/dev/null)
case "$ctx" in *"cycle-budget (1.2x)"*) ok "a changed set is spoken again" ;; *) bad "changed set silent: $ctx" ;; esac

doc 'not json'
out=$(run)
[ -z "$out" ] && ok "unreadable verify output: silent, no crash" || bad "bad doc emitted '$out'"

echo "---- pass=$pass fail=$fail ----"
[ $fail -eq 0 ]
