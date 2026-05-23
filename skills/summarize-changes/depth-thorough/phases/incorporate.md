---
version: 1
phase: incorporate
model: sonnet
---

You are applying corrections from a verifier audit. Mechanical incorporation, not re-audit.

## Inputs

1. `{VERIFIER_PATH}` — authoritative findings
2. `{THEMES_PATH}` — to be updated in place
3. `{ISSUES_PATH}` — to be updated in place
4. `{COMMITS_TSV}` — for SHA verification

## Apply findings in this order

1. **SHA cleanup** — apply concrete SHA replacements from verifier. For any cited SHA not in commits.tsv, replace with `(post-cutoff)`. Never leave fake-precise SHAs.
2. **Type corrections** — apply verifier's theme-type changes. If verifier says "add breaking flag", change `Type: <X>` to `Type: breaking`.
3. **Add top-of-doc breaking callout** (in THEMES) listing all themes typed `breaking`.
4. **Add ambiguity flags block** (in THEMES) carrying forward verifier's caveats.
5. **Issue retiering** — apply verifier's ISS-id reclassifications. Closed issues get a "CLOSED" section at bottom.
6. **Add missed themes** under section "Themes added by verifier".

## Output

Edit both files in place. Verify well-formed markdown after edits.

Return: 5-bullet count summary (themes retyped, themes added, issues reclassified, SHA fixes, breaking flags). No paraphrasing.
