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

> **Steps 1 and 2 built 2026-08-24 (#13).** Layer 0 lives in **`editor.js`**,
> not `shared.js`, for the reason `match.js` exists: nothing in it touches the
> DOM until a function is CALLED, so bun can require it and `test-editor.sh` can
> exercise the history against a stub element. A core that can only be tested
> through a browser is a core nobody tests. The board `<script>`s it.
>
> The composer and the note popover have the surviving undo stack they never
> had, keyed per card (and per note for the popover), so switching cards and
> coming back resumes THAT card's history. Proven by genuinely replacing the
> node and undoing on the fresh one, which is where the native stack is empty.
>
> **The drafts page keeps its own two-field history.** The plan says Layer 0 is
> "the #12 mechanism, moved, not rewritten", but drafts' buffer is
> `{title, body}` behind a server save, not a textarea value. Making it use
> `attachBuffer` is a restructure of that page's state model, not a move, and
> its own suite is the thing that would pay for the mistake. Recorded rather
> than pretended.
>
> **The coalescing test could not fail when it was written**, which is the more
> useful half of this entry. It called `snap()` by hand after every edit, so the
> timer was irrelevant: removing the timer left every row green. It types a
> burst and waits now, and dropping the timer turns that row red. A row that
> cannot fail is not a test.
>
> **Step 3 built.** A preview toggle, not the drafts page's three-mode bar,
> because three modes on a five-line note is chrome without payload. The server
> renders it, since renderMd lives there and a second client-side parser is the
> drift this spec exists to stop. A failed render says so in the pane; an empty
> pane would read as "this renders to nothing".
>
> **Composer: exercised.** aria-pressed flips, headings, lists, code and bold
> render, the textarea hides, pressing again restores everything.
>
> **Popover: exercised too.** It shipped UNCONFIRMED first, because no note chip
> was reachable in the viewport and "same code therefore same behaviour" is the
> reasoning that ships broken twins. Closed the same session by standing up a
> throwaway board with a note on it and pressing the thing: aria flips, bold,
> code and list items render, the textarea hides, pressing again restores it.
> The board was unregistered afterwards; a test fixture living in the owner's
> registry is indistinguishable from their real work.
>
> **Step 5, and the plan was half stale.** It says tables first, then images.
> Tables ALREADY rendered — GFM pipes, thead and tbody, verified through
> /api/mdpreview before touching anything. Only images were missing, and they
> came out as literal text.
>
> Images render now, ahead of the link rule, because ![alt](src) contains
> [alt](src) and the link rule would eat the inside and leave a stray "!".
> Absolute and http sources become a lazy-loaded <img> capped at the container
> width. A RELATIVE source says so inline instead: a path is only relative to a
> document and a note has no document, so an empty frame would read as "the
> image is missing" when the true answer is "there is nowhere to resolve this
> from".
>
> **Step 4, the half that matters.** The popover had NO protection: close it and
> the words were gone, which is the complaint class the spec calls #1. The
> composer's stash is already keyed by card AND note, so this is the same store
> called with the popover's ids, exactly as the spec said it would be.
>
> A restore is OFFERED, never applied. Silently replacing what is on screen with
> something older is its own way to lose work. Exercised: type half a sentence,
> Escape out the way a mis-click does, reopen, the banner appears, the textarea
> is NOT silently overwritten, Restore puts it back, Discard forgets it.
>
> Remaining: the popover legend and the conflict notice.

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
