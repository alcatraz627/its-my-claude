# Editing surfaces: what is shared, what each one opts into

Spec for #13, 2026-08-23. Owner ruling D3a with its note, verbatim: "As more
rich editor surfaces / controls get added, they can optionally dip into some of
the features, but we don't want to force the same thing everywhere, it's more
about different layers of what the common powerful editor / renderer has
(shared for things that help everywhere + specific instance needs)."

So this is not one editor component. It is a small core every text surface
gets, a set of opt-in features a surface declares, and each surface keeping
the part that is its own reason for existing.

## The three surfaces today, and what each already has

| | drafts editor (`drafts.html`) | board composer (`#dNote`) | note popover (`#popNote`) |
|---|---|---|---|
| what it is for | a document, edited over days | a message to the agent, sent once | the same message, edited in place |
| persistence | server auto-save, 1500 ms | local stash `kanban-draft-*`, TTL-swept, restored with a banner | none beyond the textarea |
| undo/redo | buffer-level, survives rebuild | native only, dies on rebuild | native only |
| rendering | Edit · Live · Preview, GFM via `/api/mdpreview` | none | none |
| vocabulary help | templates, insert at cursor | tag legend + insert chips | none |
| conflict | revision diff for the agent | "the agent rewrote this while you typed" notice | none |
| eats characters? | fixed (#11): no rebuild under a live caret | not rebuilt by polls | not rebuilt |

The asymmetry that matters: the composer and popover are not lesser drafts
editors. A note is sent, so server auto-save would spam the agent with
half-sentences; the local stash is the right persistence for it, and it
already exists. What they lack is the two things that have no reason to differ
anywhere: an undo stack that survives the element, and a way to see what the
markdown will look like.

## Layer 0, the core (every surface, no opt-out)

Extracted from `drafts.html` into `shared.js` as `attachBuffer(textarea, opts)`:

- **Buffer-level history.** `⌘Z` / `⌘⇧Z` / `⌘Y`, 600 ms coalescing, keyed on
  the surface's own id so a rebuilt element resumes the same stack. This is
  the #12 mechanism, moved, not rewritten.
- **Caret safety.** Never `replaceChildren` an element that has focus; the
  #11 rule as a guard in one place instead of a comment in two.
- **Insert at cursor** (`insertAtCursor`), because every surface with chips or
  templates needs it and two copies drift.

Check: `test-drafts.sh`'s undo rows keep passing against the moved code; a new
`test-editor.sh` exercises the same rows against a bare textarea with the
helper attached, so the core is proven outside drafts.

## Layer 1, the opt-ins (a surface declares them)

| feature | drafts | composer | popover | why it is optional |
|---|---|---|---|---|
| GFM preview toggle (`/api/mdpreview`) | has it (three modes) | **adds** a Preview toggle beside the legend | **adds** the same toggle | a one-line note rarely needs it, so it is a toggle, not a mode bar |
| Live (caret-line reveal) | has it | no | no | three modes on a five-line note is chrome without payload |
| server auto-save | has it | no: local stash is correct for a message | no | sending is the save |
| templates | has it | no | no | a note has a legend instead |
| tag legend + insert chips | no | has it | **adds** the legend | the popover is the same message; it should speak the same vocabulary |
| local stash + restore banner | no (server saves) | has it | **adds** it | losing a half-written note to a mis-click is the #1 complaint class |
| conflict notice | revision diff | has it | **adds** it | same data, same race |

"Adds" rows are the whole of #13's build. Everything else is already where
it should be.

## Layer 2, the surface's own (never shared)

Drafts: modes, templates, recipient, offer. Composer: the pickup hint, the
parsed-tags row, the Save-and-stay key. Popover: anchoring to its note,
select-for-send. These do not move.

## Rendering: one renderer, two places it runs

`renderMd` lives in `server.ts` and is served by `/api/mdpreview` and `/doc`.
The drafts page has its own `liveRender` for the caret-line mode, which is a
different job (per-line, not per-document). Rule: any surface that shows
rendered markdown asks the server; no client-side markdown grows beyond the
caret-line case. Images and tables (the owner's "other stuff") are a renderer
change and land once, in `renderMd`, after the doc viewer is re-checked (seed
§4 caveat): tables first (GFM pipes, no alignment), images as `<img>` with the
path resolved the way `/doc` resolves links, behind the same size guard.

## Build order, with checks

1. Extract Layer 0 to `shared.js`; drafts uses it. Check: drafts suite green
   and `test-editor.sh` green on a bare textarea; mutation: remove the
   coalescing timer, the coalescing row goes red.
2. Composer + popover attach Layer 0. Check: type, switch card, switch back,
   `⌘Z` restores; popover rebuilt by a note refresh keeps its stack.
3. Preview toggle on composer and popover. Check: a11y `button "preview"`
   pressed state; rendered HTML equals `/api/mdpreview` for the same text.
4. Popover gains legend, stash, restore banner, conflict notice (the composer's
   code, called with the popover's ids). Check: close popover mid-sentence,
   reopen, banner shows, discard works.
5. `renderMd` tables, then images. Check: the doc viewer re-read on three docs
   with tables; an image doc renders and a missing image says so inline.

Note that `board.html` still links neither `shared.css` nor `shared.js`
(catalog §0). Step 2 is the first change that needs `shared.js` on the board,
so step 2 starts by adding that one `<script>` tag and verifying nothing
double-defines (`NAV_ICON`, `applyTheme`, the tooltip layer); the known copy
becomes the shared one at that point and the catalog's "exempt by deferral"
line is retired.
