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

# C5: no view keeps a private copy. A write sends a patch and then RE-READS; it
# never writes the server's answer into the in-memory store and renders from
# that. Three sites did (board defaults, saving a view, deleting one), so the
# page could show something the store did not have, and the surfaces that read
# the same data disagreed until an unrelated render.
priv=$(cd "$HERE" && rg -n 'plan\(\)\.[a-z]+ *=[^=]' board.html || true)
if [ -z "$priv" ]; then ok "no view patches the in-memory store instead of re-reading (C5)"
else no "no view patches the in-memory store instead of re-reading (C5)" "$priv"; fi

# C5: the one path out of a write exists and the rail's refresh goes through it,
# rather than rebuilding one surface by hand and stopping there.
if (cd "$HERE" && rg -q '^async function afterWrite' board.html) \
   && (cd "$HERE" && rg -q 'refreshRail = \(\) => afterWrite' board.html); then
  ok "writes leave through one path, and the rail's refresh uses it (C5)"
else no "writes leave through one path, and the rail's refresh uses it (C5)" \
        "afterWrite missing, or refreshRail no longer routes through it"; fi

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

# The skill is how an agent MEETS this CLI. It sat six weeks behind it, missing
# seven verbs including tag and verify, which is exactly what a peer reported on
# 2026-08-24: those verbs "are all documented and all were invisible to me".
# This reads the CLI's own help for the verb list and greps the skill for each,
# so it compares two independent sources rather than agreeing with itself.
SKILL="$HOME/.claude/skills/kanban/SKILL.md"
if [ -f "$SKILL" ]; then
  missing=""
  # The verb list comes from cli.ts's own switch, not from the help prose: a
  # wrapped continuation line in the footer parsed as a verb called
  # "positional". Two independent sources is still the point, code against doc.
  for v in $(rg -o '^  case "[a-z][a-z-]*"' "$HERE/cli.ts" | rg -o '"[a-z-]*"' | tr -d '"' | sort -u); do
    case "$v" in help|"") continue ;; esac
    # Command position: after kanban.sh or the $K shorthand, allowing the
    # open|status|check alternation the skill uses. A bare word match is not
    # enough; it passed while `tag` was undocumented, matching the word inside
    # the clause grammar "tag:<kind>:<name>", so the guard agreed with itself.
    rg -q "(kanban\.sh|\\\$K) [a-z|]*\\b$v\\b" "$SKILL" || missing="$missing $v"
  done
  if [ -z "$missing" ]; then ok "every cli.ts verb appears in the /kanban skill"
  else no "every cli.ts verb appears in the /kanban skill" "undocumented:$missing"; fi
fi

echo "  ---- $pass passed, $fail failed"
[ "$fail" -eq 0 ]
