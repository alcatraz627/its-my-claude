# vis-compare — runtime notes

Newest first. Per-run insights: a divergence class the policy handles badly, a pack
signal that misled the judgment, a suppression worth graduating to policy.md.

---

## run 2026-07-11 — Phase D run #2: real icon pair (512 source vs 30px tray size)

Purpose: calibration on data-forge tray icons; verdict `pass-with-notes` — structure
fully survives (dhash/ahash 0), both accents drift hard (dE 22.7 / 33.6 at weight
0.111 each) and edges soften across 82.8% of cells; one fix (sharper 30px regen).
Insights:
- POLICY GAP (v3 candidate): no ladder class for resolution/render-fidelity loss —
  pixelation/softness had to file under `[texture]` with a manual "graduates because
  legibility" note. Candidate: `[render-fidelity]`, default mid-ladder for icons.
- POLICY GAP (v3 candidate): no derived-size leniency rule. A pipeline-derived 30px
  asset arguably should be judged against "best achievable at 30px", not the source
  verbatim — without it, every small icon rung reads as looks-worse x3.
- The pack's local-VLM prose is NOT an anchor: it claimed the mark "occupies a much
  smaller area" in B while dhash 0 + grid_delta 4.7% said otherwise. Trust extractors
  and native eyes; treat the VLM's LAYOUT SHIFTS section as a hint, never evidence.
- Equal-weight twin palette pairs (0.111 / 0.111) with big dE on BOTH accents +
  edge_shape hot_cell_pct >80% is the downscale-blend signature — one root cause,
  group the fix, don't report three independent recolors.
- `shared/prepend-runtime-note.sh` writes the GLOBAL runtime-notes.md, not this
  skill's file — prepend here manually (locked) instead.

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
