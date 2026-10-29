---
name: svg
description: Writes an SVG (icon, logo, diagram, illustration) or cleans one up, then renders it and looks at it before handing it over, and optimizes icons. Not for photos or painterly raster art.
---

# SVG

You are the generator. This skill is the scaffolding a throwaway "here is some
markup" answer skips: a real file, sane viewBox and accessibility defaults, a
render you look at, optimization where it pays, and a real iteration loop.

The one rule: **an SVG that parses is not verified. It must be rendered and
seen.**

## Step 1: Classify the ask

| Kind | viewBox | Accessibility | Optimize? |
|---|---|---|---|
| Icon or favicon | Square `0 0 24 24` (or 16, 32, 64) | `role="img"` and `<title>` | Yes, bytes matter |
| Logo | Square or wordmark aspect | `role="img"` and `<title>` | Yes |
| Diagram | Fit to content, usually wide | `<title>` and `<desc>` | No, it can shift text |
| Illustration | Fit to content | Optional | No |
| Background pattern | Tile size | None (decorative) | Yes |

Also ask where it will live: favicon, README cover, standalone asset, or
inline in HTML. That decides whether to set a fixed `width` and `height` or
leave only `viewBox` for responsive scaling.

Given an existing SVG to edit or shrink, read it and go to step 6.

## Step 2: Illustrations start from the subject

For an illustration, banner or cover about a project (not an icon), the idea
matters more than the linework. A bespoke scene is memorable. A tidy template
is fine and forgettable.

1. **Learn the subject.** Read the README or docs the user gives you and write
   down five to eight real nouns: commands, components, numbers, the thing
   that goes wrong. Every label in the art comes from that list. Never invent
   a fact to fill space.
2. **Find the human situation it resembles.** If this system were people in a
   real place, where would they be and what would they be doing? Messages
   between agents become an office floor where one agent sleeps on the couch
   and two fight over the coffee machine. Single sign-on becomes a customs
   desk. Publishing becomes a giant straw pulling packages up to a registry.
3. **Draft three different takes** (a place, a process, a close-up character),
   not three recolors, and let the user pick.
4. **Make it legible.** Real labels on the props, characters facing different
   ways with distinct expressions, one clear focal point, humor that is true
   to the project.
5. **Build from sprites.** Small functions that return a person, desk or crate
   as `<rect>` pixels on a 4 to 8 px grid with `shape-rendering="crispEdges"`,
   composed into the scene. Generate them with a script in the sandbox. A
   light SMIL touch (a blink, a flicker) is fine, but the static frame must
   read on its own.

## Step 3: Author the markup

- Always an explicit `viewBox`. Set `width` and `height` only when the embed
  needs fixed sizing.
- Self-contained: no external `href`, no web fonts, no remote images. It must
  work offline and when copied anywhere.
- `role="img"` and `<title>` on standalone graphics, plus `<desc>` for
  diagrams.
- `currentColor` for single-color icons, so they inherit the CSS `color` where
  they are used.
- Group with `<g>` and comment the regions of a complex drawing. Prefer a
  `<style>` block or presentation attributes over long inline `style` strings.

## Step 4: Deliver a file, not only markup

Write the `.svg` to a file in the sandbox and hand it over as a download. Many
renderers (README viewers, package registries, some previews) strip inline SVG
and show the `<text>` nodes as loose words. A code block is a supplement, not
the deliverable. To embed it in HTML or Markdown, reference the file with
`<img src="...">`.

## Step 5: Render and look (mandatory)

Pick one and look at the result before calling it done:

- **Rasterize in the sandbox.** Install `cairosvg` or use `rsvg-convert` if
  present, render a PNG at 512 px (and at the real display size for an icon,
  such as 16 or 32 px), then view the image. Check proportions, colors, and
  whether paths and text land where intended.
- **Render it in an artifact.** Put the SVG on an HTML page with a dark and
  light background toggle, and for an icon show it at its real sizes. Ask the
  user for a screenshot when the result matters, since you cannot see the
  artifact yourself.

Cairo and librsvg are not full browsers. CSS `filter`, `foreignObject`,
animation and complex gradients can render wrong or not at all, which gives a
false pass. With those features, use the artifact path or a headless browser
if one installs in the sandbox. An animated SVG needs a capture after the
animation runs, or a fade-in reads as blank.

If it looks wrong, go back to step 3. Never hand over an SVG you have not
seen, or one that looked wrong.

## Step 6: Optimize and iterate

- **Icons, logos, favicons and patterns**: optimize by default. Run
  `npx svgo` if Node is in the sandbox, otherwise `scour` from pip, otherwise
  clean by hand (drop editor metadata, round coordinates to one or two
  decimals, merge identical styles). Report bytes before and after.
- **Illustrations and detailed diagrams**: skip it. Path simplification can
  alter linework or shift text.
- **Optimizing changes rendering sometimes**, so render and look again after
  every optimization.
- **On each change request**, edit the markup, then render and look again.
  The first pass passing does not cover the second.

For a set of SVGs, show them together on one artifact page with the dark and
light toggle, each at its real size.

## Hand-off

End with four lines: what was drawn or changed, the file name, how it was
render-checked (sandbox raster, artifact plus user screenshot, or not yet
seen), and the optimization result in bytes or "skipped". If it was not seen,
say so plainly instead of calling it done.
