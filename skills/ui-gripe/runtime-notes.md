# ui-gripe — runtime notes

## ui-gripe: Speedway CG setup page (s2e-dark.png / s2e-light.png) — 2026-07-27

**Purpose:** General confusion audit (no args) of the Content Generation setup form,
dark + light; target resolved by mtime-sorting project-root PNGs — the s2e pair was
2 days newer than everything else.

**Insights:**

1. Zoom-cropping the SAME button region from both theme shots side by side caught a
   token-level bug a single-theme read would misdiagnose as taste: dark theme rendered
   secondary buttons as white-label-on-light-gray. The tell is MIXED foreground contrast
   within one control — the floppy icon had the correct dark foreground while the text
   label stayed white. Icon-vs-label contrast disagreement inside one button = an
   unadapted color token, not a design choice.
2. OCR lowercased button labels ("cancel", "save" for Cancel/Save) — Apple Vision case
   is not trustworthy; never build a capitalization finding on OCR, only on native read.
3. `--ui` invented "Bell icon + Bell with dot icon" for what is natively one stamp-like
   icon plus one bell. Icon-glyph identity claims from `--ui` need native confirmation
   before citing — it hallucinates plausible glyph pairs.
4. New recurring shape: a composite caption decoding multiple unlabeled inputs
   ("per line + line count" under three bare number boxes). Scan any form table for
   captions that name N concepts over M unlabeled inputs with N != M.
5. A placeholder ("Min") sitting beside a filled sibling value ("65") at identical
   visual weight reads as a value at a glance. Check number-input groups for
   placeholder/value weight collisions.

---

## ui-gripe: claude-ipc kanban v2 ledger (kanban-v2-ledger-dark.png) — 2026-07-24

**Purpose:** General confusion audit (no args) of the 1200x806 v2 ledger view, dark +
light; target resolved from newest screenshot pair + the active kanban-prosecutor agent.

**Insights:**

1. Mid-sentence truncation with no ellipsis was the top finding and the OCR pass is the
   cheap detector: scan row endings for a trailing comma, preposition, or article
   ("Talk to the", "spawn only at"). `--ui` re-flows text and hides where lines end;
   only `--ocr` + native show the actual cut points.
2. New scan worth keeping: count the DISTINCT numbering systems per row (ordinal, #id
   badge, source-line ref = 3 here). More than two numbers on a row with no visual
   role separation is a finding by itself.
3. Badge-slot semantic overload has a mechanical check: list every badge value from
   ELEMENTS and type them (id vs word). `#3…#9` + `USER` in the same visual slot = one
   slot, two meanings. Also check the same word rendered multiple ways ("USER" appeared
   as badge, `USER —` prefix, and `USER:` prefix on one screen).
4. Spec/annotation copy shipped in the UI ("one bar = the whole board, segments jump")
   reads exactly like a designer note. Any status-bar clause that describes the UI's
   own behavior instead of the data is suspect — OCR-verify then flag.
5. Light-theme pass earned its cost again: `DONE 4` bar label was fine in dark,
   near-invisible in light. One native Read of the sibling theme is cheap; keep doing it.

---

## ui-gripe: claude-ipc kanban board (kanban-board-real-dark.png) — 2026-07-22

**Purpose:** General confusion audit (no args passed) of a 1200x862 dark-theme kanban
board; target disambiguated from newest screenshots + the active kanban-prosecutor agent.

**Insights:**

1. A full-width `--crop` (1200x50+0+812 on a 1200px image) silently returned the FULL
   frame, same failure shape as `--region`. Inset the geometry (1100x50+50+800 worked).
   Verify every crop by reading the artifact's source.png before citing it.
2. The constant-column scan generalizes from table columns to card footers: every card
   carried the character-identical truncated chip ".claude/session-notes/0..." — zero
   information at a line of height per card. Compare card footers across cards on any
   board/list shot.
3. Unthemed native scrollbars were the single most visually dominant element on the dark
   board (near-white full-height bar) and are INVISIBLE to `--ui` — no mention in
   ELEMENTS or PALETTE. Always natively eyeball the chrome (scrollbars, viewport edges),
   not just content.
4. Column-header counts are a cheap taxonomy-truth check: INBOX 0 / BACKLOG 0 /
   BLOCKED 0 vs ACTIVE 43 / DONE 97 exposed a dead five-stage workflow in one glance.
   On any kanban/pipeline UI, read the counts row as a claim and test it.

---

## ui-gripe: Versable Speedway Review page (review-gripe.png) — 2026-07-14

**Purpose:** General confusion audit (no gripe text passed) of a 1500x900 light-theme
screenshot: review queue table with per-row inline fix inputs.

**Insights:**

1. `--region bottom` silently returned a FULL-FRAME read (it described the left sidebar) — the named-region crop did NOT crop. `--crop WxH+X+Y` does crop for real, and its artifact folder's `source.png` IS the cropped image. Reliable zoom path: `see <img> --crop WxH+X+Y --ocr` (fast, no model) → `see open -1` → `Read` the source.png. Do not trust `--region`.
2. Highest-damage finding was a **contract mismatch between a column label and its input**: col 2 declared "SMI vocabulary" (a controlled vocab) while the Fix control was free text with no chevron — while the page's OWN filter bar used chevrons for pick-from-list. Checking a form control against the page's other controls for convention consistency is cheap and high-yield; the internal pattern break IS the evidence.
3. A constant-column scan generalizes the redundancy check from the two prior runs: compare each column's values ACROSS rows. Here 4 of 6 columns were character-identical on every row, so a wide 6-col table carried one varying field. Worth doing on any list/table shot.
4. Pixel-level clipping (card border slicing a Save button in half, empty page bg below) is INVISIBLE to `--ui` — it happily enumerated all 4 rows with their Save buttons. The enumeration layer reports presence, not visual truncation. Always crop and eyeball the bottom edge of a height-capped container; a count badge that disagrees with the visible row count is the tell.
5. `prepend-runtime-note.sh <skill>` writes to the GLOBAL `~/.claude/skills/runtime-notes.md`, not `skills/ui-gripe/runtime-notes.md` — which is the file this SKILL.md tells you to read at Step 0. Entries written via the script are invisible to the next ui-gripe run. Prepend to this file directly (lock → Edit → unlock).
6. No PIL, no ImageMagick on this machine. `see --crop` is the crop tool; don't waste calls discovering that again.

---

## ui-gripe: Versable Speedway products list + peek panel (ucc-peek-open.png) — 2026-07-14

**Purpose:** General confusion audit (no gripe given) of a 1500x900 full-app screenshot: products table with a slide-out peek panel open.

**Insights:**

1. When `--ui` binds a stray token to the wrong element (it read "...Bushing Kits 95%" as one string), that misparse is itself evidence of visual ambiguity — the enumeration layer failing to associate a value mirrors the first-time user failing the same way. Worth citing in the finding, not just correcting.
2. Detail/peek panels with sections named by pipeline stage (PART DETAILS / ATTRIBUTES / DERIVED BY MODULE) reliably duplicate values across sections; the cheap check from the pricing-card run (compare ELEMENTS against itself for repeated values) generalizes and found the top finding here.
3. `--ui` produced three near-miss strings on this shot (`parts_.master.csv`, "Untyped/Unclassified", "DERIVED FROM MODULE"); `--ocr` corrected all three. On dense app UIs, run OCR before quoting ANY panel label, not just the suspicious ones.
4. Full-frame reads sufficed at 1500x900; no `--region` crop needed even for the 25%-width panel.

---

## ui-gripe: pricing-card confusion audit (Langfuse-style "Core" plan) — 2026-07-10

**Purpose:** General confusion audit (no gripe given) of a 275x593 crop of a single pricing card.

**Insights:**

1. On pricing cards the highest-damage rubric item is label opacity in the usage-price line, not hierarchy — `see --ui` HIERARCHY was clean while the cost string was unparseable.
2. `see --ui` reproduced the odd string "$8-6/100k" verbatim; `--ocr` confirmed it is real UI copy, not an OCR near-miss. Always run `--ocr` before calling a weird string a bug in the UI vs a bug in the read.
3. Narrow single-card crops don't need `--region` passes; the full-frame `--ui` + `--ocr` pair was sufficient evidence.
4. Redundancy detection (paragraph repeating bullet content) falls out of comparing the ELEMENTS list against itself — cheap check worth doing on marketing/pricing surfaces.

---
