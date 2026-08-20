#!/usr/bin/env bash
# render.test.sh — the deck renderer's contract: every slide type renders, an
# over-budget slide is refused, a colour literal is refused, notes never reach the
# slides' HTML, and lint.py fires on the shapes it names. No browser here; check.sh
# owns the pixel measurement (proven by hand: a 30-bullet slide reads OVER 1933/684).
set -uo pipefail
D=/Users/alcatraz627/.claude/scripts/deck; pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
T=$(mktemp -d)
python3 "$D/render.py" "$D/fixtures/DECK.md" -o "$T/deck.html" > "$T/out.txt"; rc=$?
[ $rc -eq 0 ] && ok "fixture renders clean (rc 0)" || { cat "$T/out.txt"; ko "fixture rc $rc"; }
rg -q "10 slides" "$T/out.txt" && ok "10 slides counted" || ko "slide count"
H="$T/deck.html"
for needle in 'class="stat"' 'class="show-row"' 'class="callout warn"' 'class="callout quote"' 'class="callout term"' 'class="callout stat-callout"' 'class="cards"' 'class="diagram"' 'td class="tone-ok"' 'td class="tone-bad"' 'td class="tone-warn"' 'class="kicker"' 'class="lede"' 'class="leave"'; do
  rg -q -F "$needle" "$H" && ok "renders $needle" || ko "missing $needle"; done
python3 - "$H" <<'PY' && ok "notes are absent from the slides' HTML (only in the NOTES array)" || ko "notes leaked into slides"
import sys; d=open(sys.argv[1]).read(); body=d.split('<main class="deck">')[1].split('</main>')[0]
assert "Say the three facts slowly" not in body and "Say the three facts slowly" in d
PY
rg -q "BroadcastChannel" "$H" && ok "presenter sync channel present" || ko "no BroadcastChannel"
rg -q 'presenter-view' "$H" && ok "presenter view present" || ko "no presenter view"
rg -q "@media print" "$H" && ok "print stylesheet present" || ko "no print css"
# refusals
{ cat "$D/fixtures/DECK.md"; printf '\n## Too much\n'; for i in $(seq 1 30); do echo "- bullet $i is long enough to wrap onto a second line when the slide is narrow"; done; } > "$T/over.md"
python3 "$D/render.py" "$T/over.md" -o "$T/over.html" > "$T/o.txt"; [ $? -eq 1 ] && rg -q "ERROR: slide 11" "$T/o.txt" && ok "over-budget slide is refused (rc 1, named)" || ko "overflow not refused"
[ -f "$T/over.html" ] && ok "file still written on refusal (for inspection)" || ko "no file on refusal"
python3 "$D/render.py" "$T/over.md" -o "$T/over2.html" --allow-overflow >/dev/null; [ $? -eq 0 ] && ok "--allow-overflow downgrades to a note" || ko "allow-overflow"
printf '# T\n## C\n```html\n<div style="color:#ff0000">red</div>\n```\n' > "$T/col.md"; python3 "$D/render.py" "$T/col.md" -o "$T/col.html" > "$T/c.txt"; [ $? -eq 1 ] && rg -q "colour literal" "$T/c.txt" && ok "colour literal in slide content is refused" || ko "colour not refused"
printf '# T\n## N\n:::cols\n:::callout tip\nleft tip\n:::\n---\n:::callout tip\nright tip\n:::\n:::\n- after the cols\n' > "$T/n.md"; python3 "$D/render.py" "$T/n.md" -o "$T/n.html" >/dev/null; [ "$(rg -o 'class="callout tip"' "$T/n.html" | wc -l | tr -d ' ')" = 2 ] && rg -q 'after the cols' "$T/n.html" && ok "nested callouts inside cols render, and the cols close at their own :::" || ko "nested callout in cols"
printf '# T\n## O\n:::open https://example.com/x | the label | how to open\n' > "$T/o.md"; python3 "$D/render.py" "$T/o.md" -o "$T/o.html" >/dev/null; rg -q '<span>the label</span>' "$T/o.html" && rg -q 'show-note">how to open' "$T/o.html" && ok ":::open three-part form: label replaces the raw url, hint wraps" || ko "open label form"
printf '# T\n## L\nWe never write `robust` or `seamless` on a slide; per the WRITING doc.\n' > "$T/l.md"; python3 "$D/lint.py" "$T/l.md" >/dev/null; [ $? -eq 0 ] && ok "lint: a banned word in backticks is a mention, not a use" || ko "lint code-span mention"
printf '# T\n## C\n:::callout purple nope\n' > "$T/k.md"; python3 "$D/render.py" "$T/k.md" -o "$T/k.html" | rg -q "unknown callout kind" && ok "unknown callout kind is reported and falls back" || ko "unknown kind silent"
# lint
python3 "$D/lint.py" "$D/fixtures/DECK.md" >/dev/null; [ $? -eq 0 ] && ok "lint: fixture is clean" || ko "lint fixture"
printf '# T\n## A\nWe made it faster, simpler, and more robust — dramatically so, with many wins across the board for everyone involved in the whole programme end to end.\n- 1\n- 2\n- 3\n- 4\n- 5\n- 6\n- 7\n> notes: fast\n## N\n:::stat 42%% | of rows\n' > "$T/bad.md"
out=$(python3 "$D/lint.py" "$T/bad.md"); for k in em-dash bullets adjectives hedge-triad ste notes-voice unsourced; do echo "$out" | rg -q "\[$k\]" && ok "lint fires: $k" || ko "lint silent: $k"; done
trash "$T" 2>/dev/null || true
echo "== the review prompt's placeholder count describes itself =="
# review-prompt.md's header states how many placeholders a dispatcher must fill.
# That number was hand-maintained and drifted: it said "two" while there were
# three ({{OUT}} was missed), which is the same defect as a help text that no
# longer matches its parser. Now the count is checked rather than trusted.
RP="$HOME/.claude/scripts/deck/review-prompt.md"
n_actual=$(rg -o '\{\{[A-Z_]+\}\}' "$RP" | sort -u | wc -l | tr -d ' ')
n_stated=$(rg -o '[Ff]ill the ([a-z]+) placeholder' --replace '$1' "$RP" | head -1)
case "$n_stated" in
  two) want=2;; three) want=3;; four) want=4;; five) want=5;; *) want="";;
esac
if [ -z "$want" ]; then
  ko "review-prompt.md does not state its placeholder count in a form this can check"
elif [ "$want" = "$n_actual" ]; then
  ok "stated placeholder count ($n_stated) matches the $n_actual actually present"
else
  ko "review-prompt.md says $n_stated placeholders, found $n_actual: $(rg -o '\{\{[A-Z_]+\}\}' "$RP" | sort -u | tr '\n' ' ')"
fi

echo "== the reviewer seat is opus, and the deck says so in both places =="
rg -q 'default seat is opus' -i "$RP" && ok "review-prompt names opus as the default seat" || ko "review-prompt still defaults to a cheaper seat"
rg -q 'one opus seat' "$HOME/.claude/skills/deck/SKILL.md" && ok "SKILL.md's phase table names the opus seat" || ko "SKILL.md still names a sonnet seat"
rg -q 'in-band or it does not exist' "$HOME/.claude/skills/deck/SKILL.md" && ok "the in-band read-back rule is stated" || ko "no in-band read-back rule"
rg -q 'DECK_MTIME' "$RP" && ok "the prompt pins the deck mtime so a stale read is detectable" || ko "no mtime pin"

echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
