# Motion illustrator: a project's idea, moving, in one SVG

Turns what a project does into a small animated picture a visitor understands
in three seconds. The art comes from the project's own nouns (its commands,
folders, numbers, the thing that goes wrong), never from generic tech
decoration. The SVG is written by hand and checked by rendering it and
looking.

The sibling mode is the art director, for raster images. This one writes
vector markup directly, and the `svg` skill holds the craft details.

## Fits when

- "Animated SVG", "README banner", "make the README move"
- A README or docs page that needs a hero image, an animated diagram, or a
  badge-like graphic
- An illustration rather than an icon

## The medium's hard limits

- On GitHub, a README SVG is served through an `<img>` tag. No JavaScript, no
  hover, no click, no external fonts or images. "Interactive" there means
  animation that plays by itself, or the image linked to a live page.
- SMIL (`<animate>`, `<animateTransform>`, `<animateMotion>`) and CSS
  `@keyframes` inside a `<style>` block both play in `<img>`.
- `@media (prefers-color-scheme: dark)` inside the SVG's style works, so one
  file can carry both palettes.
- The first frame must read on its own, because previewers and
  reduced-motion readers see frame zero. Pause motion under
  `prefers-reduced-motion`.
- Keep it light: under about 60 KB, a loop of 4 to 12 seconds, no more than
  two things moving at once.

## Method

1. **Nouns first.** Read the README and write down five to eight real nouns.
   Every label in the art comes from that list.
2. **Find the scene.** The system as a place, a process, or one character.
   Draft genuinely different takes, not recolors.
3. **Direction cards.** Title, one-line scene, what moves, which nouns it
   shows, where it sits on the page.
4. **Build** on a 4 or 8 pixel grid with `shape-rendering="crispEdges"` for
   pixel work, clean paths for diagrams. One focal motion, one secondary.
5. **Render check.** Show it as an artifact, or render frames in the code
   sandbox if a headless browser is available. Check frame zero and mid-loop,
   and say what is on screen before judging it.
6. **Iterate** one variable at a time.

## Depth levels

**L1 Quick.** One SVG, one motion, checked at frame zero and mid-loop.

**L2 Standard.** Three to five direction cards, each a working SVG, shown
side by side, with a recommendation.

**L3 Deep.** L2, then the chosen direction refined in both color schemes, a
reduced-motion pass, size measured, and a linked interactive page if wanted.

## Anti-patterns

- Photographic, painterly or textured art. That is the art director.
- Promising hover or click inside a README image. State the limit and offer
  a linked page.
- Decoration with no project fact in it.
- Shipping an SVG that was parsed but never rendered and looked at.
