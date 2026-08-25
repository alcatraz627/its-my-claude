# Design handoff: the kanban surfaces app

For the agent (or human) who will ideate on this app's UI. Read this page,
then the attached `design/SYSTEM.md`, then go wide.

## What you are designing for

One local app (kanban, :5106) that has become the owner's control plane for
agent work: boards mirroring projects, the owner's asks, drafts, decision
pages, plans, and soon sessions/transcripts. It grew surface by surface;
your job is to imagine what it looks like designed as ONE thing.

## The actual problem, in the owner's words

Added 2026-08-25, because every earlier version of this page described the
app and never named the problem. Verbatim: *"in the context of what all am I
doing in having a central place for managing the exponential explosion of the
communication needs between me and the agent"*.

Read that as the brief. One person now works with many agents, across many
projects, at once and around the clock, and the communication load between
them grows faster than the person's attention does. Every surface here is an
answer to some part of that: a board is a project's state without asking, an
ask is a thought captured before it is classified, a decision page is N
judgments batched into one pass, a note is a message that survives a session
dying, a plan is a ruling that stays ruled.

So the question a design must answer is not "how should a kanban board look".
It is **what does one person's attention need, when the other side of every
conversation is an agent that never sleeps, forgets on /clear, and multiplies.**
A design that makes the app prettier but does not move that number has missed.

The scope fence, also the owner's: this stays a personal control plane. It is
not becoming a team chat product or a document store. Anything you propose is
in service of one human staying on top of many agents.

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

**And go past the brief.** The owner asked explicitly for "ideas or domains or
callouts you didn't consider". The list of surfaces above is what the people
who built this happened to think of, which makes it the ceiling of their
imagination rather than the ceiling of the problem. So a section of your
output is reserved for what nobody asked about: the interaction that should
exist and does not, the state the taxonomy cannot express, the moment in the
owner's day this app is absent from and should not be, the thing two of these
surfaces are both badly approximating because the real primitive is missing.
Say when you are proposing a new entity, and say what it costs.

Disagreeing with a PRESCRIPTIVE ruling is allowed if you argue it. Those were
made from lived use and most should stand, but a ruling nobody can re-examine
is a rut. Name the ruling, say what changed, make the case.

## The shelf (source docs, when you want depth)

All in `~/.claude/scripts/kanban/docs/`: `UI-CHARTER.md` (the rulings ledger),
`DESIGN-SYSTEM.md` (current tokens/components), `FEEDBACK-CLASSES.md` (the
eleven recurring failure classes), `SEARCH-DESIGN.md`, `NAV-UNIFICATION.md`,
`EDITOR-LAYERS.md`, `CHAT-HISTORY.md` (the sessions plan, ruled),
`UNIFIED-SURFACES.md`, `DECISION-PAGES-ADOPTION.md`, `REMAINING-WORK.md`
(the want-list). SYSTEM.md summarizes them so you can start without reading
any; read them when a section's provenance matters.
