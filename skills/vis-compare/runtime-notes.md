# vis-compare — runtime notes

Newest first. Per-run insights: a divergence class the policy handles badly, a pack
signal that misled the judgment, a suppression worth graduating to policy.md.

---

## run 2026-07-11 — fixture pair diff-a/diff-b (first real invocation)

Purpose: full-skill run on the canonical fixture pair; verdict `diverges` on the
count-value info change, with sync-line judged improvement and button move neutral.
Insights:
- POLICY GAP: the ladder has no class for ADDED content. The new sync line had to be
  filed under `hierarchy-shift` as nearest-fit, which misdescribes it. Candidate: an
  `[info-add]`/`[content-add]` class, default judgment improvement-or-neutral.
- `[info-loss]` fires on any data-state change; on live-data surfaces (counts,
  timestamps) the looks-worse ruling is genuinely low-confidence without caller
  context. A per-project "live data values are exempt" override is the likely
  graduation once a user overrules one.
- `text_diff.moved` carrying measured from_xy/to_xy/delta_xy made the placement call
  fully groundable — cite those verbatim, no grid inference needed.
- SKILL-AUTHORING HAZARD: literal `$0` in SKILL.md body ("$0 ground truth") gets
  argument-substituted at invocation — the first arg path rendered in its place three
  times. Escape it or reword ("zero-cost") in SKILL.md.

---

## seed 2026-07-10 — skill authored (Phase B of visual-compare)

Purpose: the L2 judge for `see diff`'s L1 evidence pack. Mirrors `/ui-gripe`.
Insights:
- The pack's `color.palette_pairs[].weight` is the fabrication discriminator — a
  low-weight "different" pair is anti-aliasing, not a recolor. Judge accordingly.
- A theme flip reads LOW on E3 (palette) and HIGH on E5 (grid) by design — the same
  colors, redistributed. Don't call a theme change a "palette drift".
- Announce the native-vision seat before spending it; the $0 evidence is free.
---
