# vis-compare taste policy (v3 — calibrated 2026-07-12, Phase D runs 1–2)

> This file is the durable home of "which divergences matter to me." The judge reads
> it every run. It was drafted from the design's divergence-class ladder; **it is
> yours to edit** — reorder the ladder, change the floor, pin project-specific rules.
> The judge follows what is written here, not its own taste.

## The imitation doctrine (why this exists)

The question is never "is B pixel-identical to A?" — it is "does B faithfully imitate
A where it matters, and are its departures improvements or losses?" Pixel fidelity is
NOT the goal. A deliberate, tasteful departure (better spacing, a cleaner control) is a
**win**, not a divergence to flag. So every difference gets sorted into one of four
judgments, never a raw pass/fail on distance:

- **looks-worse** — B lost something A had (information, affordance, clarity, hierarchy).
- **neutral** — a real difference that neither helps nor hurts.
- **improvement** — B is better here; note it, do not "fix" it back.
- **not-worth-chasing** — below the floor; real but too small to spend effort on.

## Divergence classes, ranked by default severity (the ladder)

Higher = matters more. When two findings compete for attention, the higher class wins.
**Every divergence's `class` field MUST be the canonical slug in `[brackets]`** — the
fingerprint and suppression match key on it verbatim, so a prose synonym breaks them.

1. `[info-loss]` **information loss** — a value, label, count, or data point in A is
   missing or wrong in B. The most serious: it changes what the user *knows*. Never
   not-worth-chasing. **Live-data rule (calibrated, run 1):** on a live surface, a
   changed VALUE whose label and format are intact and whose value is plausible
   (`12 → 47`, a fresher timestamp) is the DATA changing, not the rebuild losing
   information — judge it `neutral` by default. `[info-loss]` is for a value that is
   missing, garbled, or misformatted.
2. `[info-add]` **information added** — a value, label, or line in B that A lacks.
   Changes what the user knows, so it ranks high — but the default judgment is
   context-dependent and often an `improvement` (more context, no hierarchy damage);
   never auto looks-worse. It is looks-worse only when the addition crowds, competes
   with, or contradicts something A said.
3. `[affordance-loss]` **affordance loss** — a control/action present in A is gone or no
   longer looks interactive in B. Changes what the user can *do*.
4. `[hierarchy-shift]` **hierarchy / emphasis shift** — the thing that dominated A no
   longer dominates B, or a new element competes for the top level. Changes where the
   eye goes first. (Dominance/emphasis, NOT mere position — a same-weight element that
   simply moved is `layout-placement`. New content that merely *exists* in B is
   `info-add`; it is a hierarchy shift only when it fights for the top level.)
5. `[layout-placement]` **layout / placement move** — an existing element sits in a
   different region of B than A, without a change in its dominance or styling (a button
   that moved corner-to-corner, a panel that reflowed). Low-to-mid by default: often
   `neutral` or an `improvement` toward convention; rises only if the new spot hurts
   findability or breaks a scan order.
6. `[render-fidelity]` **render / resample fidelity** — pixelation, blur, aliasing, or
   downscale blending that softens the mark (calibrated, run 2). Looks-worse when it
   costs legibility or crispness at the asset's actual display size. **Derived-size
   leniency:** judge a pipeline-derived rung against the best achievable AT that size,
   never the source verbatim — a good 30px render can't keep every edge. Hue gets NO
   such leniency: a competent resample keeps color identity, so accent drift still
   files as `brand-color` against the source.
7. `[brand-color]` **brand / accent color drift** — the accent or a brand-locked color
   moved (ΔE above the floor). Matters more when a project pins exact brand hexes.
8. `[spacing-rhythm]` **spacing / rhythm** — padding, gaps, alignment, inter-row rhythm.
   Matters when it breaks a grid the design otherwise keeps; small shifts are usually low.
9. `[micro-type]` **micro-typography** — weight, tracking, size within a step. Rarely
   worth chasing unless it changes legibility or hierarchy (then it graduates up).
10. `[texture]` **texture / decoration** — shadows, gradients, borders, ornament. Lowest
    by default; free-hand territory unless it carries meaning (a shadow that signals
    elevation/state).

## The floor (what is not-worth-chasing by default)

Unless it compounds with something higher on the ladder, treat as not-worth-chasing:

- A single spacing/rhythm shift under ~4% of the frame.
- A brand-color ΔE in the "subtle" band (2–8) on a non-pinned color.
- Micro-typography within one weight/size step.
- Any texture/decoration difference that carries no state or meaning.
- Anything the extractors flag as low-population / low-weight (a `color.palette_pairs`
  entry whose `weight` is tiny is a few pixels of anti-aliasing, not a real recolor).

**Compounding overrides the floor**: three "subtle" shifts in the same region read as
one real hierarchy problem. Say so, and rank it by the class it compounds into.

## Anti-fabrication (binding on the judge, not editable taste)

- The judge may NOT assert a color/size/position number that is absent from the
  evidence pack. It may only ADD gestalt observations (things it can see but the
  extractors don't measure — "the shadow reads as heavier"), each tagged `gestalt`.
- **`where.grid` is a MEASURED coordinate — it is valid ONLY when copied from a
  `grid_heat` or `edge_shape` `top_cells` entry.** A `text_diff` divergence
  (removed/added) has NO position in the pack: its `where` is `desc`-only (name the
  region in words if you like, but leave `grid` out). A `text_diff.moved` divergence
  carries `from`/`to` 3×3 LABELS plus measured `from_xy`/`to_xy` normalized centers
  (and `delta_xy` when the pairing is unambiguous 1-vs-1) — cite those verbatim as
  measured values; a null `delta_xy` means the pairing was ambiguous, not "small".
  Any other position — a grid cell you inferred, a coordinate you eyeballed — is a
  fabrication with `gestalt:false`, the exact thing this layer exists to prevent. If
  you can see a position but no extractor measured it, it is `gestalt:true`.
- If the pack's extractors report near-zero everywhere (an identical or
  perceptually-identical pair), the verdict is "no meaningful divergence." The judge
  does not go hunting for something to flag. A comparator that invents differences is
  worse than none.
- The judge never disputes an extractor's measurement; if a number looks wrong, that is
  a `--revisit` with feedback, not a silent override.

## Per-project overrides (add sections as needed)

A project can pin rules that outrank the defaults above. Example shape:

```
### project: versable
- brand hexes are STRICT: #<hex> and #<hex> — any ΔE > 2 is class-4 "looks-worse",
  never neutral, never floored.
- the primary CTA must keep its dominance — a hierarchy shift on it is class-2, not 3.
```

_No project overrides yet. Add them here as you calibrate on real pairs (Phase D)._
