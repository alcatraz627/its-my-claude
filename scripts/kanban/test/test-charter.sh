#!/usr/bin/env bash
# The charter rules a static read can enforce. Each row is one standing count
# from UI-CHARTER.md, re-measured every run instead of copied forward, because a
# standing count is a measurement with a date (§16, 2026-08-22).
#
#   bash test-charter.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
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
# never writes a guess into the in-memory store and renders from that. The old
# check grepped for the one spelling `plan().foo =` and stayed green against
# `const p = plan(); p.foo = ...` and `data.plan.foo = ...`, including a live
# counterexample in the tree (the answers patch). This one resolves aliases.
priv=$(cd "$HERE" && bun -e '
const html = require("fs").readFileSync("board.html", "utf8");
const script = html.split(/<script[^>]*>/).slice(1).map((s) => s.split("</script>")[0]).join("\n");
const aliases = new Set();
for (const m of script.matchAll(/(?:const|let|var)\s+(\w+)\s*=\s*plan\(\)/g)) aliases.add(m[1]);
const bad = [];
script.split("\n").forEach((ln, i) => {
  const t = ln.trim();
  if (t.startsWith("//")) return;
  if (/plan\(\)(\.\w+|\[[^\]]+\])+\s*=[^=]/.test(ln)) bad.push(`${i + 1}: ${t}`);
  else if (/\bdata\.plan(\.\w+|\[[^\]]+\])+\s*=[^=]/.test(ln)) bad.push(`${i + 1}: ${t}`);
  else for (const a of aliases) {
    if (new RegExp(`\\b${a}\\.(answers|tags|goals|views|on)\\b[^=<>!]*=[^=]`).test(ln)
     || new RegExp(`\\b${a}\\.(answers|tags|goals|views|on)\\b.*\\.(push|splice|unshift|pop|shift)\\(`).test(ln))
      bad.push(`${i + 1}: ${t}`);
  }
});
process.stdout.write(bad.join("\n"));
' || true)
if [ -z "$priv" ]; then ok "no view patches the in-memory store instead of re-reading (C5)"
else no "no view patches the in-memory store instead of re-reading (C5)" "$priv"; fi

# C5: the one path out of a write DOES the re-read (a name-presence grep stayed
# green with the body gutted), and the bare cache invalidations outside it are
# a closed ledger: the declaration, two selection echoes (the server response
# rides the write, then the poll cache is dropped), poll recovery, the items
# signature, the 409 conflict recovery, and afterWrite itself. Seven. A new
# `lastPayload = ""` is an eighth path out of a write: route it or ledger it.
body=$(cd "$HERE" && awk '/^async function afterWrite/,/^}/' board.html)
inval=$(cd "$HERE" && rg -c 'lastPayload = ""' board.html || echo 0)
if echo "$body" | rg -q 'lastPayload = ""' && echo "$body" | rg -q 'load\(\)' \
   && (cd "$HERE" && rg -q 'refreshRail = \(\) => afterWrite' board.html); then
  ok "afterWrite re-reads for real, and the rail's refresh uses it (C5)"
else no "afterWrite re-reads for real, and the rail's refresh uses it (C5)" \
        "afterWrite body no longer drops the cache and re-loads, or refreshRail bypasses it"; fi
if [ "$inval" = "7" ]; then ok "cache invalidations outside afterWrite are the ledgered seven (C5)"
else no "cache invalidations outside afterWrite are the ledgered seven (C5)" \
        "found $inval; a new one is a second path out of a write — route it through afterWrite or update the ledger AND this count"; fi

# C6: the editing core is layer 0, "every surface, no opt-out" (EDITOR-LAYERS.md),
# and it was loaded by board.html alone. A page that builds a text surface loads
# the core; drafts is the recorded exception, with its own document-level history.
for pg in board.html hub.html; do
  if (cd "$HERE" && rg -q 'src="/editor.js"' "$pg"); then ok "$pg loads the editing core (C6)"
  else no "$pg loads the editing core (C6)" "no <script src=/editor.js> in $pg"; fi
done
# and the surfaces that get rebuilt actually attach it. Live code only: the
# comment filter is what lets this row fail when the call is deleted but its
# text survives in a comment, which is exactly how it was mutation-tested green.
live(){ (cd "$HERE" && rg -n "$1" "$2" | rg -v ':[[:space:]]*//' | rg -q .); }
missing=""
live "attachBuffer\(ta, \{ id: \`ask-\\\$\{slug\}\`" board.html || missing="$missing ask"
live "attachBuffer\(ta, \{ id: \`goal-\\\$\{cardId\}\`" board.html || missing="$missing goal"
live 'attachBuffer\(ta, \{ id: "hub-ask"' hub.html || missing="$missing hub-ask"
if [ -z "$missing" ]; then ok "every rebuilt text surface attaches the core, in live code (C6)"
else no "every rebuilt text surface attaches the core, in live code (C6)" "unattached:$missing"; fi

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
