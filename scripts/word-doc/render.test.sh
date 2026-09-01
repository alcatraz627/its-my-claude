#!/usr/bin/env bash
# Exercise /word-doc's scripts end to end: the good fixture renders to a docx that
# carries every style the theme promises; each preflight gate fires on the case it
# guards; the lint names each defect it claims to catch. Run after any change here.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d)
pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok    $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL  $1"; }
has()  { if printf '%s' "$2" | rg -q -- "$1"; then ok "$3"; else bad "$3 (wanted /$1/)"; fi; }
lacks(){ if printf '%s' "$2" | rg -q -- "$1"; then bad "$3 (found /$1/)"; else ok "$3"; fi; }

echo "# good fixture renders"
out=$(python3 "$HERE/render.py" "$HERE/fixtures/full.md" -o "$T/full.docx" 2>&1); rc=$?
[ $rc -eq 0 ] && ok "exit 0" || bad "exit $rc: $out"
has "^  clean" "$out" "preflight clean"
[ -s "$T/full.docx" ] && ok "docx written" || bad "no docx"
unzip -tq "$T/full.docx" >/dev/null 2>&1 && ok "docx is a valid zip" || bad "docx zip broken"
doc=$(unzip -p "$T/full.docx" word/document.xml)
sty=$(unzip -p "$T/full.docx" word/styles.xml)
for s in CalloutNote CalloutTip CalloutWarning CalloutImportant Diagram SourceCode KeywordTok TOC1 TOC2 TableCaption ImageCaption TableSpacer; do
  has "w:val=\"$s\"" "$doc" "document uses style $s"
done
has 'w:br w:type="page"' "$doc" "page break emitted for \\newpage"
has 'w:anchor="summary"' "$doc" "TOC entry links to a heading anchor"
has 'w:tblStyle w:val="Table"' "$doc" "tables use the Table style"
grids=$(printf '%s' "$doc" | tr -d '\n' | rg -o '<w:tblGrid>.*?</w:tblGrid>' | head -1)
lacks '(<w:gridCol w:w="([0-9]+)" />)(<w:gridCol w:w="\2" />){2}' "$grids" "pipe-table columns are sized from content, not equal"
has 'Figure 1\. Today' "$doc" "diagram caption present"
has 'Listing 1\.' "$doc" "code caption present"
ACC=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('$HERE/theme.json')))['palette']['accent'])")
has "<w:bottom[^/]*w:color=\"$ACC\"[^/]*w:val=\"dashed\"|<w:bottom[^/]*w:val=\"dashed\"[^/]*w:color=\"$ACC\"" "$sty" "ruled table: dashed accent rule under the header (theme.json accent)"
has '<w:insideH[^/]*w:val="dashed"' "$sty" "ruled table: dashed row separators"
has 'CalloutNoteHead' "$sty" "ruled callouts: head style present"
has '<w:rPrDefault><w:rPr><w:rFonts[^/]*/><w:color w:val="222B36"' "$(unzip -p "$T/full.docx" word/styles.xml | tr -d '\n')" "ink colour lives in docDefaults (theme.json ink)"
has 'footer1.xml' "$(unzip -l "$T/full.docx")" "footer part present"
has 'NUMPAGES' "$(unzip -p "$T/full.docx" word/footer1.xml)" "footer has page N of M"
has 'w:pgSz w:h="16838" w:w="11906"' "$doc" "A4 by default"
out=$(python3 "$HERE/render.py" "$HERE/fixtures/full.md" -o "$T/letter.docx" --paper letter 2>&1)
has 'w:pgSz w:h="15840" w:w="12240"' "$(unzip -p "$T/letter.docx" word/document.xml)" "--paper letter"
out=$(python3 "$HERE/render.py" "$HERE/fixtures/full.md" -o "$T/font.docx" --font-body Georgia --font-mono "JetBrains Mono" --accent 6B2D5C 2>&1)
has 'w:ascii="Georgia"' "$(unzip -p "$T/font.docx" word/styles.xml)" "--font-body lands in styles"
has 'w:ascii="JetBrains Mono"' "$(unzip -p "$T/font.docx" word/styles.xml)" "--font-mono lands in styles"
has 'w:color w:val="6B2D5C"' "$(unzip -p "$T/font.docx" word/styles.xml)" "--accent lands in headings"
has 'w:name="JetBrains Mono"' "$(unzip -p "$T/font.docx" word/fontTable.xml)" "mono font declared in fontTable"

echo "# preflight gates fire"
mk() { printf -- "---\ntitle: t\n---\n\n# A\n\n%b\n" "$1" > "$T/g.md"; python3 "$HERE/render.py" "$T/g.md" -o "$T/g.docx" 2>&1; }
has "error.*diagram is 90 columns" "$(mk "\`\`\`\n$(printf '%90s' x)\n\`\`\`")" "wide diagram is an error"
has "warn.*code line of 100" "$(mk "\`\`\`python\n$(printf '%100s' x)\n\`\`\`")" "wide code is a warning"
has "error.*jumps from level 1 to 3" "$(mk "text\n\n### C")" "skipped heading level is an error"
has "error.*unknown callout" "$(mk "> [!DANGER] x")" "unknown callout is an error"
has "error.*fence options need braces" "$(mk "\`\`\`python caption=\"x\"\nx\n\`\`\`")" "bare fence options are an error"
has "error.*image not found" "$(mk "![a](nope.png)")" "missing image is an error"
has "error.*table row has 3 cells, header has 2" "$(mk "| a | b |\n|---|---|\n| 1 | 2 | 3 |")" "ragged table is an error"
has "warn.*table has 7 columns" "$(mk "| a | b | c | d | e | f | g |\n|---|---|---|---|---|---|---|\n| 1 | 2 | 3 | 4 | 5 | 6 | 7 |")" "wide table is a warning"
has "error.*needs a title" "$(printf -- "---\nauthor: x\n---\n\n# A\n\ntext\n" > "$T/n.md"; python3 "$HERE/render.py" "$T/n.md" -o "$T/n.docx" 2>&1)" "missing title is an error"
out=$(mk "\`\`\`python\n$(printf '%100s' x)\n\`\`\`"); python3 "$HERE/render.py" "$T/g.md" -o "$T/g.docx" --strict >/dev/null 2>&1; [ $? -eq 1 ] && ok "--strict fails on a warning" || bad "--strict did not fail"

echo "# lint fires"
cat > "$T/l.md" <<'MD'
---
title: l
---

# Intro

This has an em-dash — and a massive claim. It is fast, simple, and reliable. This sentence is deliberately stretched well past thirty words so that the long sentence check has something concrete to find when it runs over this paragraph here and keeps on going.

- **Owner:** platform
- **Status:** draft
- **Risk:** low
- this bullet is far too long to be a bullet because a bullet is one thought and this one keeps going and going past the one hundred and sixty character mark that the gate sets

## Only child

# Empty

## Sub

text
MD
l=$(python3 "$HERE/lint.py" "$T/l.md" 2>&1); rc=$?
[ $rc -eq 1 ] && ok "lint exits 1 on findings" || bad "lint exit $rc"
for c in em-dash weasel triad sentence bullet labels empty orphan; do has " $c " "$l" "lint: $c"; done
l=$(python3 "$HERE/lint.py" "$HERE/fixtures/full.md" 2>&1); rc=$?
[ $rc -eq 0 ] && ok "lint clean on the good fixture" || bad "lint on good fixture: $l"
has '"check": "em-dash"' "$(python3 "$HERE/lint.py" --json "$T/l.md")" "lint --json"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
