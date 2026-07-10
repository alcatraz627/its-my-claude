---
name: svg
description: Authors, edits, optimizes, and render-checks SVG graphics — icons, logos, diagrams, illustrations, patterns. Claude writes the SVG markup directly (no image-gen backend); the skill adds the scaffolding that makes it production-grade: a file-first output path, a mandatory rasterized render-check you actually look at, svgo optimization, accessibility/viewBox defaults, and an iteration loop. Use when the user wants a vector graphic, an icon set, a logo, an inline diagram, a favicon, or wants an existing SVG cleaned up or resized.
allowed-tools: Read, Write, Edit, Bash, Glob, mcp__plugin_chrome-devtools-mcp_chrome-devtools__navigate_page, mcp__plugin_chrome-devtools-mcp_chrome-devtools__new_page, mcp__plugin_chrome-devtools-mcp_chrome-devtools__take_screenshot
argument-hint: "[what to draw, or a path to an existing .svg to edit/optimize]"
user-invokable: true
---

## Brief

Turns a description into a real, verified SVG file. Claude's native SVG-authoring
is the generator — this skill is the scaffolding around it that a throwaway "here's
some markup" answer skips: a file on disk (not inline markup that renderers strip),
a rasterized render-check that gets *looked at* before handoff, optional `svgo`
optimization, sane viewBox/accessibility defaults, and a real iteration loop.

The one rule that makes this skill worth invoking over just writing markup: **an SVG
that parses is not verified — it must be rendered and seen.** (`rules/exercise-based-verification.md`.)

## Step 0 — Guidelines + output location

Read `~/.claude/skills/GUIDELINES.md` and apply it for the whole run (forbidden
paths, confirm-before-overwrite, completion block).

Resolve the output directory:
- In a project (a `.claude/` exists up-tree): `<project>/assets/` (create if absent).
- Global / no project, OR CWD is `~/.claude`: `~/.claude/assets/images/`. **Never**
  let a relative `.claude/output/...` resolve under `~/.claude` — that becomes the
  hook-blocked `~/.claude/.claude/...` double-nest. Use the absolute assets path.

## Phase 1 — Intent

Classify the ask and let it set the defaults:

| Kind | viewBox default | Accessibility | Optimize by default? |
|---|---|---|---|
| icon / favicon | square `0 0 24 24` (or 16/32/64) | `role="img"` + `<title>` | yes (byte size matters) |
| logo | square or wordmark aspect | `role="img"` + `<title>` | yes |
| diagram / flowchart | content-fit, wider | `<title>` + `<desc>` | no (svgo can shift text/paths) |
| illustration | content-fit | optional | no |
| background pattern | tile size | none (decorative) | yes |

Also determine the **embed context** (favicon, README cover, standalone asset,
inline-in-HTML) — it decides whether to set fixed `width`/`height` or leave only
`viewBox` for responsive scaling.

If the arg is a path to an existing `.svg`, skip to Phase 6 (edit/optimize an
existing file) after reading it.

## Phase 2 — Author the markup

Claude writes the SVG directly. Apply these defaults (they are what separate a
production SVG from a sketch):

- **Always an explicit `viewBox`**; set `width`/`height` only when the embed needs
  fixed sizing.
- **Self-contained** — no external `href`, no web-font references, no remote
  images. Everything inline so the file works offline and when copied anywhere.
- **`role="img"` + `<title>`** (and `<desc>` for diagrams) on standalone graphics —
  screen readers and it's cheap.
- Prefer a `<style>` block or presentation attributes over inline `style="..."`
  blobs where it reads cleaner; group with `<g>` and comment the regions of a
  complex drawing.
- `currentColor` for single-color icons so they inherit CSS `color` at the callsite.

## Phase 3 — Write to disk (file-first, never inline-only)

Write the `.svg` to the resolved path. **Never present raw `<svg>` markup as the
deliverable** — most renderers (IDE previews, glow/mdcat, npm/crates pages, chat)
strip SVG and dump the `<text>` nodes as garbage (`readme/SKILL.md` §3.3). Hand back
the file path; reference via `<img src=...>` when embedding in HTML/markdown.

## Phase 4 — Render-check (MANDATORY — the load-bearing phase)

Rasterize with the zero-install path and **read the PNG back and actually look at
it** (the Read tool renders images) — proportions, colors, whether paths/text land
as intended:

```bash
TMP=$(mktemp -d); qlmanage -t -s 512 -o "$TMP" "<file>.svg" >/dev/null 2>&1
# → $TMP/<file>.svg.png  — Read this file and judge it visually
```

Escalate to a browser-fidelity render **when the SVG uses features QuickLook
mishandles** (CSS `filter`, `foreignObject`, animation, complex gradient meshes) OR
the qlmanage output looks wrong: open `file://<abs-path>.svg` via the chrome-devtools
MCP (`new_page` / `navigate_page` + `take_screenshot`) and judge that instead.
QuickLook is a plugin, not a full SVG engine — a false pass is a real risk, so pick
the browser path whenever advanced features are present.

If it looks wrong, go back to Phase 2 — do not hand off an unverified or
wrong-looking SVG.

## Phase 5 — Optimize (icons/logos/favicons: default on; illustrations: ask/skip)

```bash
# macOS has no `timeout`; svgo via npx can take a few seconds on first (uncached) run.
npx --yes svgo "<file>.svg" -o "<file>.svg"
```

Apply by default for icons/logos/favicons/patterns (byte size matters, geometry is
simple). **Skip for illustrations/detailed diagrams** — svgo's path-simplification
can visibly alter linework or shift text. Report bytes before/after. After optimizing,
**re-run Phase 4's render-check** — svgo occasionally changes rendering, so an
optimized file is not verified until re-seen.

## Phase 6 — Iterate / edit-existing

On a change request (or when handed an existing file): `Read` the SVG, edit the
markup directly (same native authoring as Phase 2), then **re-run Phase 4** — never
skip verification on the second pass because the first passed. For a pure optimize
request on an existing file, run Phase 5 then Phase 4.

## Phase 7 — Completion block

Per GUIDELINES.md:

```
What was done:   <one line — what was drawn/edited>
Files created:   <absolute path to the .svg>
Render-check:    <passed (qlmanage / browser) | needs-look>
Optimized:       <svgo: N → M bytes | skipped (illustration)>
Errors:          <none | ...>
```

## Notes

- **No backend.** Unlike `/generate-image`, `/svg` has no external generator —
  Claude is the generator. The only command that matters is the render-check
  (`qlmanage -t`). This is deliberate: `readme`'s pixel-art cover already proves
  Claude authors SVG natively; the value here is the verification + optimization
  scaffolding.
- **Companion:** `/generate-image` for raster art (photos, textures, painterly
  images) via the local `imagine` model. Rule of thumb: vector/geometric/logo/icon →
  `/svg`; photographic/painterly/textured → `/generate-image`.
- **Preview gallery:** for a set of SVGs, write a small `index.html` with the
  mandatory dark/light toggle (`conventions/html-output.md`) referencing each via
  `<img>`, served or opened locally — don't inline the markup.
- **Post-run:** prepend a runtime-notes entry via
  `~/.claude/skills/shared/prepend-runtime-note.sh` if the run surfaced anything
  reusable (a QuickLook fidelity gotcha, an svgo setting that broke a drawing).

## See Also

- `~/.claude/conventions/html-output.md` — dark/light toggle for any preview page
- `~/.claude/conventions/asset-management.md` — where assets go
- `~/.claude/rules/exercise-based-verification.md` — render-and-look, not parse-and-ship
- `~/.claude/skills/generate-image/SKILL.md` — the raster companion
