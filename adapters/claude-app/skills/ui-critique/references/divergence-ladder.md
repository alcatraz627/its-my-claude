# Divergence ladder for comparing a rebuild to its reference

Rank each divergence between reference A and rebuild B by class. Higher on the
list matters more. When two findings compete for attention, the higher class
wins. The user can reorder this for a project, and their order then wins.

| # | Class | B differs from A when | Default judgment |
|---|---|---|---|
| 1 | Information loss | A value, label or count in A is missing, garbled or misformatted in B | Never "not worth chasing" |
| 2 | Information added | B shows something A lacks | Often an improvement. Worse only when it crowds or contradicts A |
| 3 | Affordance loss | A control in A is gone, or no longer looks interactive | Looks worse |
| 4 | Hierarchy shift | The element that dominated A no longer dominates, or a new one competes for the top | Looks worse unless deliberate |
| 5 | Layout move | An element sits in another region with the same weight | Often neutral. Worse if it hurts findability |
| 6 | Render fidelity | Blur, pixelation or aliasing softens a mark at its display size | Worse when it costs legibility |
| 7 | Brand color drift | The accent or a brand color moved | Matters more when the project pins exact hexes |
| 8 | Spacing and rhythm | Padding, gaps or alignment changed | Low unless it breaks a grid the design keeps |
| 9 | Micro-typography | Weight, tracking or size within one step | Rarely worth chasing unless legibility changes |
| 10 | Texture | Shadows, gradients, borders, ornament | Lowest, unless it signals state or elevation |

## Live data

On a live surface, a changed value whose label and format are intact and whose
value is plausible (12 became 47, a newer timestamp) is the data changing, not
the rebuild losing information. Judge it neutral.

## The floor

Treat these as not worth chasing unless they compound with something higher:

- A single spacing shift under about 4% of the frame
- A subtle color shift on a color the project does not pin
- Micro-typography within one weight or size step
- Texture with no meaning
- A color difference covering a few pixels (anti-aliasing, not a recolor)

Three subtle shifts in the same region read as one real hierarchy problem. Say
so, and rank it by the class it compounds into.

## Judging progress across rounds

When B is rebuilt over several rounds, measure progress by which divergences
moved to fixed, not by a similarity score. Pixel scores saturate as soon as
the two layouts differ, so they can stall or worsen while the rebuild is
improving. Within one A-to-B comparison, the scores remain fair evidence of
where B departs.
