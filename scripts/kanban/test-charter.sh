#!/usr/bin/env bash
# The charter rules a static read can enforce. Each row is one standing count
# from UI-CHARTER.md, re-measured every run instead of copied forward, because a
# standing count is a measurement with a date (§16, 2026-08-22).
#
#   bash test-charter.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
pass=0; fail=0
ok(){ echo "  PASS  $1"; pass=$((pass+1)); }
no(){ echo "  FAIL  $1"; echo "     $2"; fail=$((fail+1)); }

# §13/§16: no native tooltips. Both spellings count, the attribute and the
# property, because the hub carried four of the second kind that an attribute
# grep never saw (2026-08-23). Allowed: document.title (the tab), the draft
# buffer's own title field, and the doc-modal iframe, whose title= is its
# accessible name rather than a tooltip.
hits=$(cd "$HERE" && rg -n ' title="|\.title *= ' board.html hub.html drafts.html \
  | rg -v 'document\.title|buf\.title|<iframe ' || true)
if [ -z "$hits" ]; then ok "no native tooltips on board, hub or drafts (§16)"
else no "no native tooltips on board, hub or drafts (§16)" "$hits"; fi

echo "  ---- $pass passed, $fail failed"
[ "$fail" -eq 0 ]
