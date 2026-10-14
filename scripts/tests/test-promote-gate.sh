#!/usr/bin/env bash
# Regression test for the PROMOTE gate in backlog-consolidate.py.
#
# A lone proposal filed by a human (src:session-contrib, small or medium effort)
# used to promote on that alone. It must now wait in WATCH like any single signal.
# Corroboration of 2+ and an S3 atone slug still promote. The S3 case runs under a
# fixture HOME so it does not depend on the live atone ledger.
#
#   bash ~/.claude/scripts/tests/test-promote-gate.sh
#   BC=/path/to/copy.py bash ~/.claude/scripts/tests/test-promote-gate.sh   (mutation runs)
set -uo pipefail

BC="${BC:-$HOME/.claude/scripts/backlog-consolidate.py}"
FX=$(mktemp -d)
trap 'rm -rf "$FX"' EXIT
STORE="$FX/store.jsonl"
mkdir -p "$FX/.claude/atone/derived"
cat > "$FX/.claude/atone/derived/triggers.json" <<'JSON'
[{"from_slug":"fixture-s3-slug","severity_band":"S3","count":1}]
JSON
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
fail=0
ok()  { printf '  PASS  %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

cat > "$STORE" <<JSONL
{"id":"lone-human","ts":"$NOW","title":"quokka widget calibration drifts overnight","body":"zebra marmalade sundial telescope; entirely unrelated vocabulary one","category":"docs","effort":"small","status":"open","tags":["src:session-contrib"]}
{"id":"s3-linked","ts":"$NOW","title":"ostrich lantern avalanche protocol","body":"harpoon velvet cobalt thimble; entirely unrelated vocabulary two","category":"hooks","effort":"large","status":"open","tags":["link:atone:fixture-s3-slug"]}
{"id":"two-links","ts":"$NOW","title":"pelican glacier syndicate manifesto","body":"walnut trombone lichen carousel; entirely unrelated vocabulary three","category":"hooks","effort":"large","status":"open","tags":["link:atone:other-slug","link:dream:d-1"]}
JSONL

report=$(HOME="$FX" PROPOSE_STORE="$STORE" python3 "$BC" --read-only --force 2>/dev/null)
printf '%s\n' "$report" > "$FX/report.md"
promote=$(awk '/^## /{f = ($0 ~ /PROMOTE/)} f' "$FX/report.md")

echo "promote-gate regression:"
if printf '%s' "$promote" | rg -q 'lone-human'; then
  bad "lone human-filed small proposal still promotes"
else
  ok "lone human-filed small proposal no longer promotes"
fi
if rg -q 'lone-human' "$FX/report.md"; then
  ok "lone human proposal is still listed (WATCH), not dropped"
else
  bad "lone human proposal vanished from the report"
fi
if printf '%s' "$promote" | rg -q 's3-linked'; then
  ok "S3-linked proposal still promotes"
else
  bad "S3-linked proposal did not promote"
fi
if printf '%s' "$promote" | rg -q 'two-links'; then
  ok "proposal linking 2 systems (corroboration 2) still promotes"
else
  bad "corroboration-2 proposal did not promote"
fi
exit "$fail"
