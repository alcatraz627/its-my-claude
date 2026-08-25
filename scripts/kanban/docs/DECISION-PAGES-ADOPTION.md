# Decision pages, adopted into kanban

Owner, 2026-08-25: "I do want you to fold in decision pages into kanban,
visually, server wise, and beyond. Examine all it has, surfaces, inputs,
guiderails, etc. Identify UI / category / display defects. Adopt decision
pages in here, can make a copy of the decision pages; once all fine we'll
retire the main thing."

This ruling settles what items 11, 13 and 15 were gated on. The direction is
absorption, not asset-linking: kanban serves the pages itself.

## What the system has today (examined 2026-08-25)

**Surfaces.** A hub at :5197/ (hub.html + pages.json manifest, progress chips
read from each page's localStorage) · one page per slug (a COPY of
template.html + config.json + images) · an answer-preview drawer · a keyboard
help overlay · a toast. Plus a terminal surface: wizard.sh answers the same
config in the TTY and submits through the same endpoint.

**Inputs.** Radio decisions with exactly one `rec` option · per-item agree
checkboxes · per-item notes (hidden until asked for; `notes:false` disables
the whole surface) · end-of-form notes · a flagged-only filter · full keyboard
(j k g G 1-9 a n N m f p c s t ?).

**Guardrails.** `decision-page.sh check` (schema-lite with fix-proposing
failures, image existence, HTTP render check) · `.pending.txt` ledger (one
slug per line; the statusline reads its count directly) · submit writes
`.answer.json` `{answer, submitted_at}`, clears pending, ipc-notifies the
origin session (`dp-server` identity, registered `--service`) · localStorage
persistence keyed `decision-page:<storageKey>` · path-traversal guard on the
submit route · clipboard fallback when submit fails.

**Contract consumers, which the adoption must not break.**
1. Agents watch `<slug>/.answer.json` (Monitor or poll); that file is the
   load-bearing wake.
2. The answer STRING format is what every skill parses from the paste.
3. `.pending.txt` line count feeds the statusline chip.
4. `decision-page.sh` (new/check/list/pending/answer) and wizard.sh keep working.
5. features/decision-pages.md is the schema doc.

## Defect catalog

UI defects (charter violations in the old template):
- **U1** Native `title=` tooltips on every header control (charter §16 bans;
  kanban has a delegated data-tip layer).
- **U2** Typed dingbats: `＋ note`, `☀ / ☾`, CSS-content `▾/▸` (charter §5:
  drawn, not typed). The theme button also never reflects current state.
- **U3** A third theme system: its own palette + `data-theme` handling,
  drifted from the kanban tokens (different hues, different steps).
- **U4** No page chrome: no way back to anything; the page is a dead end
  (the owner leaves by closing the tab).
- **U5** Image zoom toggles a class that reflows the page (no scrim);
  thumbnails fixed at 236px.
- **U6** Reset uses native `confirm()` with no way to see what would be lost.

Category defects (structure, not paint):
- **C1** The answer-string algorithm exists in THREE copies: template.html,
  hub.html (`answerStringOf`), wizard.sh. Classic drift risk; the hub's copy
  already reads state slightly differently (`st?.d?.[id] ?? rec`).
- **C2** Answered-ness is split across three stores that can disagree:
  browser localStorage (progress), `.pending.txt` (agent-maintained by hand),
  `.answer.json` (the truth). The page itself never reads `.answer.json`, so
  a submitted page re-opens as if unanswered (**D1** below).
- **C3** Per-page `index.html` is a full COPY of template.html (52 copies
  today): a template fix reaches only pages scaffolded after it.
- **C4** The hub is a second "list pages with state" implementation; kanban's
  Decisions view is now a third. One of them (the hub) is the retirement
  target.

Display defects:
- **D1** A submitted page shows no answered state on revisit (only the
  transient toast at submit time knew).
- **D2** Hub progress chips read localStorage cross-page, so they are blind
  in any other browser/profile and never see submits made via wizard.sh.
- **D3** The linkified evidence URL strips scheme+host from the display text,
  which misreads for cross-host links.

## The adoption (built 2026-08-25)

Kanban serves the same registry, read-only for GETs, with ONE dynamic
template instead of 52 copies (fixes C3):

- `GET /dp/<slug>/` serves kanban's `decision.html` (charter chrome; config
  fetched per page).
- `GET /dp/<slug>/config.json` and image assets are served from the registry
  dir with traversal guards.
- `POST /api/dp-submit/<slug>` is byte-compatible with the old server:
  writes the same `.answer.json` shape, clears `.pending.txt`, ipc-notifies
  the origin session. Agents watching `.answer.json` cannot tell which
  server took the submit.

`decision.html` keeps the old page's answer contract VERBATIM: the
state/flips/answerString functions are ported unchanged, the keyboard map is
identical, and the localStorage key string is unchanged. Adopted into the
charter: shared tokens and theme, the kanban navbar (kinds tabs, crumb
`All decisions / <title>`), data-tip tooltips (U1), SVG glyphs (U2), an
answered banner when `.answer.json` exists (D1), scrimmed image zoom (U5).

kinds.js's decisions href now points at `/dp/<slug>/`, so the hub view, the
palette, the switcher and search all land in-app.

## Invariants, each with its check

1. **Answer string byte-equal** to the old page on the same config and the
   same interactions. Check: computed on both origins with clean storage and
   after identical flips; diffed.
2. **`.answer.json` shape identical** `{answer, submitted_at}`. Check: submit
   from the new page, read the file.
3. **Pending semantics**: submit drops the slug from `.pending.txt`. Check:
   seeded ledger line disappears.
4. **Old system untouched**: :5197 keeps serving every existing page; nothing
   in the registry is rewritten. Both run side by side until the owner
   retires :5197.

## First production round: dp-system-feedback (2026-08-25)

The first real page on the adopted system collected the gated decisions and
feedback on the surface itself; the watcher wake and the ipc backup both
fired on Submit. Rulings: sessions get a hub surface woven with boards
(D1b); #20 runs after the WiZ dropdown (D2b); terminal DEFERRED pending
real design (D3a+note), task runner and skip-permissions spawner never
as-was (D4a, D5a). Follow-ups recorded in docs/REMAINING-WORK.md: answered
banner v2, decision origin weaving, the navbar-crowding guidance. The 52
stale per-page index.html copies were trashed on the owner's nod; every
page renders from the one template (verified post-trash).

## Transition / retirement — EXECUTED 2026-08-25

The owner ruled the retirement the same day. decision-page.sh and wizard.sh
now target the kanban server (URLs, ensure-server, submit endpoint); the
/kanban and /decision-wizard skills, features/decision-pages.md, CLAUDE.md,
the wizard rule and the callout convention were repointed in the same change,
so a naive invocation lands on the new system with no knowledge of the
switch. `new` no longer copies template.html (every page renders from the one
dynamic template). pm2 `decision-pages` is deleted and :5197 is dark. The
statusline's pending chip reads .pending.txt directly and needed nothing.
The section below is the original plan, kept for the record.

## Transition / retirement (the original plan, as written)

Once the kanban surface has carried a few real decision rounds: repoint
`decision-page.sh`'s printed URLs and `open` at :5106/dp/, teach `new` to
stop copying template.html (config.json alone is enough), move the submit
watcher docs, then decommission pm2 `decision-pages` and :5197. localStorage
progress does not carry across origins; pages are temporary, accepted cost.
Known not-yet-adopted: in-progress hub chips (D2 stays until answered-ness
moves server-side), wizard.sh (already server-agnostic except the hardcoded
:5197 BASE), the help-modal hosts (item 11; now same-origin and cheap).
