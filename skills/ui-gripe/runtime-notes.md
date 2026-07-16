# ui-gripe — runtime notes

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
