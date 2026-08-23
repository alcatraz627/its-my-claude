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

# §5: drawn, not typed. A button whose only content is a unicode dingbat, in
# markup or assigned as textContent, reads at a different weight from the SVG
# set beside it. Eleven of them were found on the board on 2026-08-23 (#45).
typed=$(cd "$HERE" && rg -n '<button[^>]*>[[:space:]]*[◐?↑↓»«✕✓○●⋯›‹×✎]+[[:space:]]*</button>|textContent = "[◐?↑↓»«✕✓○●⋯›‹×✎]"' board.html hub.html drafts.html || true)
if [ -z "$typed" ]; then ok "no typed dingbats in buttons on board, hub or drafts (§5)"
else no "no typed dingbats in buttons on board, hub or drafts (§5)" "$typed"; fi

# §5 widened to links (G17, 2026-08-24). "open in tab ↗" and a bare ↗ before
# </a> were the two that hid from the check above, because it only reads a
# button whose ENTIRE content is a dingbat and these carry a label too. The
# leaving-the-page glyph is EXT_ICON now, so the character itself should not
# appear in any of the three pages at all, which is a rule with nowhere to hide.
arrow=$(cd "$HERE" && rg -n '↗|↖|↘|↙' board.html hub.html drafts.html || true)
if [ -z "$arrow" ]; then ok "no typed corner arrows anywhere on board, hub or drafts (§5, G17)"
else no "no typed corner arrows anywhere on board, hub or drafts (§5, G17)" "$arrow"; fi

echo "  ---- $pass passed, $fail failed"
[ "$fail" -eq 0 ]
