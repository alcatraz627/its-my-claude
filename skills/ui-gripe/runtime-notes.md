# ui-gripe — runtime notes

## ui-gripe: pricing-card confusion audit (Langfuse-style "Core" plan) — 2026-07-10

**Purpose:** General confusion audit (no gripe given) of a 275x593 crop of a single pricing card.

**Insights:**

1. On pricing cards the highest-damage rubric item is label opacity in the usage-price line, not hierarchy — `see --ui` HIERARCHY was clean while the cost string was unparseable.
2. `see --ui` reproduced the odd string "$8-6/100k" verbatim; `--ocr` confirmed it is real UI copy, not an OCR near-miss. Always run `--ocr` before calling a weird string a bug in the UI vs a bug in the read.
3. Narrow single-card crops don't need `--region` passes; the full-frame `--ui` + `--ocr` pair was sufficient evidence.
4. Redundancy detection (paragraph repeating bullet content) falls out of comparing the ELEMENTS list against itself — cheap check worth doing on marketing/pricing surfaces.

---
