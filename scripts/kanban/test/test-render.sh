#!/usr/bin/env bash
# What the markdown renderer must produce, for the constructs a check can pin.
#
# Written 2026-08-26 against the adversarial review's renderer findings. Every
# row here is a construct that shipped wrong: a quote holding a list flattened
# to literal hyphens, an ordered list restarting at 1 when a table interrupted
# it, and a setext heading rendering as body text. Each row asserts the fixed
# behaviour, so reverting a fix turns its row red rather than going quiet.
#
#   bash test-render.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
ok(){ echo "  PASS  $1"; pass=$((pass+1)); }
no(){ echo "  FAIL  $1"; echo "     got: $2"; fail=$((fail+1)); }

# renderMd is not exported, so the check drives it the way a reader does: feed a
# document in and read the HTML back out. bun runs server.ts's own module.
render(){
  bun --eval "
    const src = await Bun.stdin.text();
    const { renderMd } = await import('$HERE/render-md.ts');
    console.log(renderMd(src));
  "
}

# Every prohibition below ("no literal hyphens survive") is vacuously true on an
# empty string, so nothing is asserted about absence until presence is proved.
# This check exists because the first draft of this file passed that very row
# against empty output, which is the defect it was written to catch.
nonempty(){
  if [ -n "$(printf '%s' "$2" | tr -d '[:space:]')" ]; then return 0; fi
  no "$1" "renderer produced nothing; the prohibition rows below are meaningless"
  return 1
}

# --- a list inside a blockquote (adversarial F2) -------------------------------
got=$(printf '> intro:\n>\n> - first\n> - second\n>   - nested\n' | render)
case "$got" in
  *"<blockquote"*"<ul>"*"<li>first</li>"*) ok "a blockquote holding a list renders the list" ;;
  *) no "a blockquote holding a list renders the list" "$got" ;;
esac
if nonempty "no literal hyphens survive inside a quoted list" "$got"; then
  case "$got" in
    *"&gt; - first"*|*"<p>- first"*) no "no literal hyphens survive inside a quoted list" "$got" ;;
    *) ok "no literal hyphens survive inside a quoted list" ;;
  esac
fi
case "$got" in
  *"<li>second<ul><li>nested</li></ul></li>"*|*"<li>second"*"<ul>"*"nested"*) ok "nesting inside a quoted list survives" ;;
  *) no "nesting inside a quoted list survives" "$got" ;;
esac

# --- prose quotes keep working (the case the old grammar was written for) ------
got=$(printf '> one line.\n>\n> another paragraph.\n' | render)
case "$got" in
  *"<blockquote"*"<p>one line.</p>"*"<p>another paragraph.</p>"*) ok "a prose quote still splits on the empty marker" ;;
  *) no "a prose quote still splits on the empty marker" "$got" ;;
esac

# --- an ordered list interrupted by an indented block (adversarial F3) ---------
got=$(printf '1. one\n   | a | b |\n   |---|---|\n   | 1 | 2 |\n2. two\n' | render)
n=$(printf '%s' "$got" | grep -o '<ol' | wc -l | tr -d ' ')
if [ "$n" = "1" ]; then ok "an indented table does not split the ordered list"
else no "an indented table does not split the ordered list" "$n <ol> elements: $got"; fi
# The table must open INSIDE item one, not merely appear somewhere before some
# </li>. The looser glob passed with the fix reverted, because a later item
# supplied the closing tag: mutation-testing this row is what found that.
case "$got" in
  *"<li>one<table>"*) ok "the indented table lands inside its own list item" ;;
  *) no "the indented table lands inside its own list item" "$got" ;;
esac

# --- setext headings (adversarial F4) -----------------------------------------
got=$(printf 'Title\n=====\n\nbody.\n' | render)
case "$got" in
  *"<h1"*">Title</h1>"*) ok "an = underline makes an h1" ;;
  *) no "an = underline makes an h1" "$got" ;;
esac
got=$(printf 'Sub\n---\n\nbody.\n' | render)
case "$got" in
  *"<h2"*">Sub</h2>"*) ok "a - underline after text makes an h2" ;;
  *) no "a - underline after text makes an h2" "$got" ;;
esac
# a rule with no paragraph above it is still a rule, not an empty heading
got=$(printf 'para.\n\n---\n\nmore.\n' | render)
case "$got" in
  *"<hr>"*) ok "a standalone - run is still a horizontal rule" ;;
  *) no "a standalone - run is still a horizontal rule" "$got" ;;
esac

# --- CRLF, which the renderer already normalises; pinned so it stays that way --
got=$(printf 'Title\r\n=====\r\n\r\nbody.\r\n' | render)
case "$got" in
  *"<h1"*">Title</h1>"*) ok "CRLF input reaches the same result as LF" ;;
  *) no "CRLF input reaches the same result as LF" "$got" ;;
esac

# --- attribute-context escaping (validation gate, CRITICAL-adjacent) ----------
# esc() covers text nodes and leaves quotes alone, correctly. Every value that
# lands inside an ATTRIBUTE needs the quote closed too, or it ends the attribute
# and opens a new one. /api/mdpreview feeds arbitrary card-note and draft text
# straight into this renderer, so these are reachable from anything a person or
# an agent can type into the app.
got=$(printf '![x" onerror="alert(1)](http://evil.example/a.png)\n' | render)
if nonempty "an image alt cannot break out of its attribute" "$got"; then
  case "$got" in
    *'onerror="alert'*) no "an image alt cannot break out of its attribute" "$got" ;;
    *"&quot;"*) ok "an image alt cannot break out of its attribute" ;;
    *) no "an image alt cannot break out of its attribute" "no escaping seen: $got" ;;
  esac
fi
got=$(printf '[l](http://evil.example/" onmouseover="alert(2))\n' | render)
if nonempty "a link href cannot break out of its attribute" "$got"; then
  case "$got" in
    *'onmouseover="alert'*) no "a link href cannot break out of its attribute" "$got" ;;
    *"&quot;"*) ok "a link href cannot break out of its attribute" ;;
    *) no "a link href cannot break out of its attribute" "no escaping seen: $got" ;;
  esac
fi
got=$(printf 'see http://evil.example/a" onclick="alert(3)\n' | render)
if nonempty "an autolinked URL cannot break out of its attribute" "$got"; then
  case "$got" in
    *'href="http://evil.example/a" onclick='*) no "an autolinked URL cannot break out of its attribute" "$got" ;;
    *) ok "an autolinked URL cannot break out of its attribute" ;;
  esac
fi
# A quote in ordinary prose is a quote, not an entity: over-escaping text would
# be its own defect, and this row is what stops the fix above growing into one.
got=$(printf 'she said "hello" and left.\n' | render)
case "$got" in
  *'said "hello"'*) ok "a quote in prose stays a quote" ;;
  *) no "a quote in prose stays a quote" "$got" ;;
esac

# --- an indented four-space block is CODE, not a paragraph (#17) ---------------
#
# Shipped broken and carried as a standing caveat since 2026-08-25. The renderer
# had no indented-code branch at all: the per-line fallthrough ends in
# para.push(l.trim()), so the indentation was discarded and the lines were joined
# with a space into one <p>. A pasted shell transcript rendered as a sentence.
got=$(printf 'para\n\n    code line one\n    code line two\n\nafter\n' | render)
case "$got" in
  *"<pre"*"<code>"*) ok "an indented four-space block renders as pre/code" ;;
  *) no "an indented four-space block renders as pre/code" "$got" ;;
esac
# Presence is not enough: the defect JOINED the lines, so pin the newline.
case "$got" in
  *"code line one"$'\n'"code line two"*) ok "its lines keep their newline, not joined by a space" ;;
  *) no "its lines keep their newline, not joined by a space" "$got" ;;
esac
# CommonMark: an indented chunk cannot interrupt a paragraph. Without this the
# second line of any hard-wrapped paragraph that happens to be indented would
# silently become code.
got=$(printf 'a sentence\n    still the same sentence\n' | render)
case "$got" in
  *"<pre"*) no "an indented line does not interrupt a paragraph" "$got" ;;
  *) ok "an indented line does not interrupt a paragraph" ;;
esac
# Regression guard for the lazy-continuation feature next door: an indented line
# under a list item is that item's continuation and must NOT become code.
got=$(printf -- '- item one\n    wrapped onto a second line\n' | render)
case "$got" in
  *"<pre"*) no "an indented line under a list item stays a continuation" "$got" ;;
  *"wrapped onto a second line"*) ok "an indented line under a list item stays a continuation" ;;
  *) no "an indented line under a list item stays a continuation" "$got" ;;
esac
# A blank line inside an indented block does not end it; truncating at the first
# blank would be the same defect class wearing a different costume.
got=$(printf 'para\n\n    line one\n\n    line three\n\nafter\n' | render)
n=$(printf '%s' "$got" | grep -o '<pre' | wc -l | tr -d ' ')
if [ "$n" = "1" ] && printf '%s' "$got" | grep -q 'line three'; then
  ok "a blank line inside an indented block does not split it"
else
  no "a blank line inside an indented block does not split it" "$n <pre>: $got"
fi
# Markup inside code stays literal.
got=$(printf 'para\n\n    <b>not bold</b>\n' | render)
case "$got" in
  *"&lt;b&gt;not bold&lt;/b&gt;"*) ok "markup inside an indented block stays literal" ;;
  *) no "markup inside an indented block stays literal" "$got" ;;
esac

# --- an indented block keeps its place when another block follows it ----------
#
# The code buffer was only flushed on the paragraph fallthrough, so a table, a
# list or a blockquote starting right after an indented block left the block
# open; flushAll then emitted it at the END. A table rendered BEFORE the code
# that preceded it in the source. Found by testing the boundaries after the
# local reviewer pointed vaguely at block termination.
for after in 'table:| a | b |\n| - | - |\n:<table' 'list:- item\n:<ul' 'quote:> quoted\n:<blockquote'; do
  nm="${after%%:*}"; rest="${after#*:}"; body="${rest%:*}"; tag="${rest##*:}"
  got=$(printf "para\n\n    code\n\n$body" | render)
  pre_at=$(printf '%s' "$got" | grep -bo '<pre' | head -1 | cut -d: -f1)
  oth_at=$(printf '%s' "$got" | grep -bo -- "$tag" | head -1 | cut -d: -f1)
  if [ -n "$pre_at" ] && [ -n "$oth_at" ] && [ "$pre_at" -lt "$oth_at" ]; then
    ok "an indented block stays before a following $nm"
  else
    no "an indented block stays before a following $nm" "pre@${pre_at:-none} $nm@${oth_at:-none}: $got"
  fi
done

# --- KNOWN GAP: an ordered list interrupted by a FENCED block still splits -----
#
# Same defect class as the table case above, reached through a different
# interrupter, and NOT fixed. The cause is structural: renderMd splits on
# line-initial fences at the top level, before any list parsing, so a list
# spanning a fence is guaranteed to become two lists. Fixing it means hoisting
# list state across the fence split, which is a real change to the shared path.
#
# Deliberately not done, on the owner's benefit-versus-churn bar: the pattern
# occurs ZERO times across every .md in docs/ and design/ (measured, not
# assumed). A restructure for a case the corpus does not contain is cost.
#
# This row SELF-RETIRES rather than sitting here as a skip: while the gap is
# present it reports and does not fail, and the day someone closes it the row
# goes RED and says to delete itself. A skip would rot silently.
got=$(printf '1. one\n```\ncode\n```\n2. two\n' | render)
n=$(printf '%s' "$got" | grep -o '<ol' | wc -l | tr -d ' ')
if [ "$n" = "1" ]; then
  no "KNOWN GAP CLOSED: a fence no longer splits an ordered list — delete this row and its comment"
else
  echo "  GAP   a fenced block still splits an ordered list ($n <ol>) — known, unfixed, see comment"
fi

# --- GFM allows a single-hyphen separator row (validation gate, MEDIUM) --------
got=$(printf '| a | b |\n| - | - |\n| 1 | 2 |\n' | render)
case "$got" in
  *"<td>-</td>"*) no "a single-hyphen separator row is consumed, not rendered" "$got" ;;
  *"<th>a</th>"*) ok "a single-hyphen separator row is consumed, not rendered" ;;
  *) no "a single-hyphen separator row is consumed, not rendered" "$got" ;;
esac

echo
echo "---- pass=$pass fail=$fail"
[ "$fail" = 0 ]
