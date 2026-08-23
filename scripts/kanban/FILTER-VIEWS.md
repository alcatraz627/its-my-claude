# Filter views the agent and the owner can both name

Design for #39, 2026-08-23. Owner V4: "pair it with filter views that both the
agent and I can also create / update / delete, and also be able to talk in
terms of that."

## What a view is

A **name** over a **query**, where the query is one to four of the filter
clauses the board already understands (`matchFilter`, `board.html:4719`),
ANDed. Nothing new to match; the composition SEARCH-DESIGN.md §6 deferred
arrives as the smallest form that makes a name worth having.

```ts
interface View { id: string; name: string; clauses: string[]; by: "owner" | "agent"; createdAt: string; updatedAt: string }
// clauses use today's grammar verbatim:
//   is:open · is:blocked · is:settled · needs-you · review-me
//   since:new · since:moved · since:done · since:blocked
//   tag:<kind>:<name> · a free-text word
```

Examples that are already useful on the `.claude` board:

- `this week` = `since:new`, `since:moved`: what moved since I last looked
- `M2 blocked` = `tag:milestone:M2`, `is:blocked`
- `for me` = `needs-you` (or `review-me`): the owner's queue on one board

Rules: 2 to 40 chars for a name, unique per board case-insensitively (the tag
rule), at most four clauses, at most one free-text word (more is a search,
not a view). A view never stores card ids; it is a query, so it is right
tomorrow without anyone maintaining it.

## Where it lives

`plan.json`, beside tags and goals: `views: View[]`. Shared, server-owned,
survives sync. Not `localStorage`, because "both of us can talk in terms of
it" means the agent has to be able to read the same list the owner sees.

## The verbs (agent side, `cli.ts`)

```
kanban.sh view                       # list: name · clauses · N cards now
kanban.sh view add "M2 blocked" tag:milestone:M2 is:blocked
kanban.sh view rm "M2 blocked"
kanban.sh view "M2 blocked" [--json] # the cards it matches, right now
kanban.sh status --view "M2 blocked" # the status block scoped to the view
```

`view add` with an unknown clause is refused with the grammar printed;
`view add` with a name that exists updates it (the owner's update, via CLI).
Matching runs through the SAME function the board uses, moved to `lib.ts` as
`matchClause(card, clause, ctx)` so the CLI and the board cannot disagree
(the "two surfaces disagreeing" tell, pre-empted).

## The surface (owner side)

- **Sidebar, VIEWS group** above TAGS: each view a row with its live count;
  press to apply; `rename` / `delete` like a tag. Agent-made views carry a
  small `by agent` mark so the owner knows who to ask.
- **Save as view**: when any filter is active, the filter input grows a
  `save as view` button; one prompt for the name. That is how an owner makes
  one without learning the grammar.
- **Search picker** (`/`): views appear as a section, first, since a named
  thing the owner made ranks above a seeded hint.
- **Switcher** (`b`): no. Views are per board; the switcher is across boards.
- Applying a view sets `filterText` to its clauses joined by a space; the
  status band's visible/total counts behave as they do for any filter.

## Talking in terms of it

- `status --view` gives the agent a way to say "the M2 blocked view has three
  cards and here they are" and the owner a way to say "clear the for-me view
  before tonight", and both mean the same list.
- The `c` status digest names the active view in its first line when one is
  applied, so a pasted digest says what was looked at.
- A view name is a legal word in an ask: the harvester leaves it alone; the
  agent reading the ask runs `view <name>` to resolve it.

## Sequence, with checks

1. `lib.ts`: `View` type, `matchClause`, `views` on `Plan`. Check: the board's
   `matchFilter` delegates to it and `test-items.sh` runs `matchClause` on a
   fixture card for every clause in the grammar (positive and negative).
2. `cli.ts` `view` verbs. Check: add / list / match / rm round-trip; unknown
   clause refused; `status --view` scopes counts.
3. `server.ts` `/api/view` create/rename/delete (owner path). Check: three
   POSTs; duplicate name refused case-insensitively.
4. `board.html` sidebar group, save-as-view, search section. Check: a11y tree
   shows `VIEWS` with named buttons; applying one changes the visible/total
   count; the §14 round, both themes.
5. Charter §11 gains one line: a view is a query, never a list of cards.

## Deferred, named

OR and NOT (the grammar stays AND-only until a view needs otherwise), views
across boards (the hub is the wrong altitude for a per-board query), and
sharing views between boards by copy (a later CLI flag if asked).

## Ruled, 2026-08-23 (decision page kanban-plans-round-2)

D3a shared, with this note, verbatim: "Wanna share as much with the agent as
possible, allow me to add notes for agent (optional) as well so when the agent
reeads the board it can know what I am using it for, it may or may not bother
using it, do also update agent's prompt so it is aware". So `View` gains
`note?: string`, the owner's one line on what the view is for; `view` (list)
prints it; the session-start line names the board's views and their notes
under the drafts block; `features/kanban.md` and the `/kanban` skill say views
exist and how to read them.

D4b, the fuller grammar now: AND, OR and NOT over the same clauses. Syntax
keeps the clause words as they are; `or` and `not` are lowercase words between
them, AND is the space as today: `tag:milestone:M2 is:blocked or review-me`,
`is:open not tag:area:docs`. Precedence: NOT binds a clause, AND binds tighter
than OR, no parentheses. `matchClause` becomes `matchQuery`, parsed once, and
the deferred list loses its first row.

## Owner decisions (answered above)

- D-view-1: views live in `plan.json` shared (recommended) or owner-local.
- D-view-2: AND-only, four clauses max (recommended) or a fuller grammar now.
