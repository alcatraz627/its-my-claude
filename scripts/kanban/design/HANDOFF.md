# Design handoff: the kanban surfaces app

For the agent (or human) who will ideate on this app's UI. Read this page,
then the attached `design/SYSTEM.md`, then go wide.

## What you are designing for

One local app (kanban, :5106) that has become the owner's control plane for
agent work: boards mirroring projects, the owner's asks, drafts, decision
pages, plans, and soon sessions/transcripts. It grew surface by surface;
your job is to imagine what it looks like designed as ONE thing.

## The one rule of this handoff

`SYSTEM.md` contains three kinds of statement, labeled by section:

- **NORMATIVE (binds you):** what the entities ARE and MEAN: the taxonomy,
  the honesty rules, the capability contracts. These are semantics, not
  paint. A design that shows an unknown count as zero is wrong, not fresh.
- **PRESCRIPTIVE (binds you):** interaction laws the owner has ruled on
  through lived use (a count filters; siblings get the same capability; a
  floating surface is a first-class object). Violating one re-litigates a
  settled ruling.
- **EXISTING (does NOT bind you):** the current visual language: tokens,
  type ladder, hues, component inventory. It is described so you know what
  is on screen today. Treat it as the incumbent to beat, not the system to
  build for. Diverge freely; keep only what you would keep on merit.

## What to produce

Ideation, not implementation: directions, mocks, pattern proposals, a point
of view on the surface examples named in SYSTEM.md §5 (the rich-row family,
the toolbars, search, the combined board toolbar, the navbar and its views,
the transcript/ask hub). Ground each idea in the taxonomy; never invent an
entity the taxonomy lacks without saying you are proposing one.

## The shelf (source docs, when you want depth)

All in `~/.claude/scripts/kanban/docs/`: `UI-CHARTER.md` (the rulings ledger),
`DESIGN-SYSTEM.md` (current tokens/components), `FEEDBACK-CLASSES.md` (the
eleven recurring failure classes), `SEARCH-DESIGN.md`, `NAV-UNIFICATION.md`,
`EDITOR-LAYERS.md`, `CHAT-HISTORY.md` (the sessions plan, ruled),
`UNIFIED-SURFACES.md`, `DECISION-PAGES-ADOPTION.md`, `REMAINING-WORK.md`
(the want-list). SYSTEM.md summarizes them so you can start without reading
any; read them when a section's provenance matters.
