# The drafts editing surface, as it behaves today

Written 2026-08-22, before any change, because both `/ui` and `/plan` refuse to
work on an existing surface until its current behaviour is written down, and
because a rebuild with no record of what it replaced is how accumulated UX gets
lost. This is a parity baseline, not a design. Everything here is read from
`drafts.html` at the cited line.

## What it is

One page at `/drafts`, three regions: a list of drafts on the left, an editor in
the middle, a status strip along the bottom. The editor is a plain `<textarea>`
(`drafts.html:369`) with an optional markdown preview beside it.

## What it can do

| Capability | Where | Note |
|---|---|---|
| Edit a title and a body | `:285`, `:369` | Title is an input that shows its border only on hover and focus |
| Markdown preview, side by side | `:377`, `:442` | Toggled by a button, remembered in `localStorage`, rendered server-side by `POST /api/mdpreview` |
| Preview debounce | `:437` | 250ms after the last keystroke |
| Save | `:204` | Explicit, by button or ⌘S (`:477`). Nothing is written until you press it |
| Crash recovery | `:391`, `:180` | Every keystroke stashes the buffer to `localStorage`; a recovered buffer beats the saved text on reopen |
| Guard against losing work | `:482` | `beforeunload` stashes and warns while dirty |
| Guard against clobbering | `:175`, `:192` | Switching or starting a draft while dirty asks before discarding |
| Poll without stealing the text | `:tail` | The 15s refresh runs only while the buffer is clean |
| Word count, save state | `:412` | Status strip: word count, pull provenance, `unsaved · ⌘S`, save button disabled when clean |
| Selection to template | `:323` | Selected text can be saved as a reusable template |
| Start from a template | `:tail` | A dropdown seeds a new draft from one |
| Offer to a session | `:338` | The button whose channel was dead until this session; see the charter |
| Native spellcheck | `:370` | `ta.spellcheck = true`, so this is the browser's, not ours |
| Delete | `:351` | Confirms first |

## What it cannot do

- **No auto-save.** Saving is explicit. The crash stash is recovery, not saving:
  it survives a reload but never reaches the server.
- **No undo/redo of our own.** Whatever the browser gives a `<textarea>` is all
  there is, and it dies whenever the element is rebuilt (below).
- **No editor affordances.** No formatting controls, no list continuation, no
  tab handling, no bracket or fence completion. `insertAtCursor` (`:398`) exists
  but only the template action calls it.
- **No hover or highlight relationship** between the editor and its preview.
  They are two panes that do not know about each other.
- **No GFM.** Whatever `/api/mdpreview` renders is the whole vocabulary.
- **No visible save state beyond a word.** `unsaved · ⌘S` is text in a strip.

## The known structural weakness

`render()` (`:455`) rebuilds the editor by
`document.getElementById("edit").replaceChildren(...editorEl())`. That destroys
the live `<textarea>` and builds a new one from `buf.body`. The text survives,
because `buf` is updated on every keystroke, but two things do not: **focus and
the native undo stack**. Only `newDraft()` (`:199`) restores focus afterwards.

Every path that ends in `render()` therefore drops the caret: `save()`,
`open()`, and `load()`. `load()` is called by the 15s poll, which is guarded by
`if (!dirty())` — a guard that holds while you are typing into an existing
draft, and does not hold on a **new** draft, whose empty buffer reads as clean.

This is the leading candidate for the owner's report that the editor eats
characters ("`###` becomes `#`", inconsistently). It is a hypothesis with a
mechanism, not a diagnosis: it has not been reproduced yet. Task #11 owns
proving it with a probe before anything is changed.

## Constraint inherited from the owner, 2026-08-22

The brief for improving this surface names its non-goals first: not more
features, not a heavy dependency, not a polished showpiece. The target is
*textural* feedback rather than thematic, an approachable feel, durable
undo/redo, auto-save, trivial spelling highlight, and visual consistency of the
surrounding chrome. Any direction that adds capability without changing how the
surface feels under the hand has missed the ask.
