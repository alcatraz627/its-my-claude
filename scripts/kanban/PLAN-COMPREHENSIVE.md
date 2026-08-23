# The comprehensive plan

Written 2026-08-23 from `PLAN-SEED-COMPREHENSIVE.md`. Two artifacts under it
carry the evidence: `COMPLIANCE-LEDGER.md` (every ask, with its check) and
`SURFACE-CATALOG.md` (every surface, what it shows, does, and obeys). This file
is the decisions and the sequence only.

## 1 · Decided today

- **Branch.** `kanban/aug22-sweep`, cut from `main` at `e1783d3`, holds the
  whole 2026-08-22 session as `6de4e97` (11 files, +1521/-163, three suites
  green: drafts 68, items 23, readers 9). `main` is the working copy until the
  owner merges. Every change this plan schedules lands on this branch.
- **#41 closed.** Search chips were shipped and verified; the store lagged.
- **§16 count corrected.** `board.html`'s one `title=` is an iframe name.

## 2 · Ruled by the owner, 2026-08-23 (decision page kanban-comprehensive-plan)

All four recommendations accepted: D1a D2a D3a D4a. Two notes, verbatim, bind
the rows they sit under:

- D2: "projects do need decisions, sometimes (usually, preferably) related to a
  card, sometimes otherwise (do we even allow it or force there to be a card
  (new / existing), and surface the attention and callout for decisions as
  derived from that. Also, projects do need plenty of decisions through, and
  that could use some incorporation as a mechanism from functionality and
  visual needs perspective." So: the answer verb lands first (#48), and a
  decision MECHANISM (card-bound or not, with its own attention and callout)
  is a design item for the unified-surfaces plan below, not a dropped idea.
- D3: "As more rich editor surfaces / controls get added, they can optionally
  dip into some of the features, but we don't want to force the same thing
  everywhere, it's more about different layers of what the common powerful
  editor / renderer has (shared for things that help everywhere + specific
  instance needs)." So #13 is layered: a shared core every surface gets, and
  per-surface opt-ins, never one editor forced everywhere.

New ask from the same form, verbatim: "Next up I also want to standardize the
UI and functionality of decision pages into kanban, and also the one-off html
render preview pages that I keep asking agents to make for me. Logically, they
are all multiple ways of the similar kind of bidirectional visual display and
sync. ALSO, the ability to tag and display plans ... Do take up a /plan for all
the unified data boards and questionnaires and all the other things ... end of
the day I mainly care about colocation". Filed as the next P1 plan item; it
absorbs the D2 decision mechanism.

The table as it was put to the owner:

| Pick | Recommendation | Why |
|---|---|---|
| Fable seat: use it for one adversarial review of the ledger and catalog | Yes, one seat, after the fix-now batch lands, so it reviews shipped state | A second seat is the one caveat every record carries; fable at one seat stays inside the cap |
| #48 vb-fable's needs-human card | An answer verb beside `verify`: option + free text, three states (not seen / seen-deferred / answered), on the card object, after #49 | vb-fable's five constraints (msg-2cd095d8); they ruled out a decision kind themselves. The board knows what is blocked; a page does not |
| #13 "improve the editing surface everywhere" | Bound it to: the board composer and note popover adopt the drafts editor's auto-save, undo/redo and GFM preview; nothing else | That is the one editing surface the owner touches daily that still lacks what drafts got |
| §17 thorough review | Run it AFTER batch A, board first, using the catalog as its element list | Running it before means re-running it after |

## 3 · The sequence

Batches are small on purpose; each ends with the §14 capped round and a commit
on the branch.

**Batch A, fix now** (agent, no gate): #43 drop takes tags and goal · #45 eight
board dingbats drawn · #46 hub button contract, widened to the 18 unnamed
star/archive buttons and the `For:` combobox (catalog §1, §3) · #49 `show
--json` gets `goal` and `tags` · #47 status strip stops swallowing save state ·
sidebar collapse button gets a name.
Check: a11y tree has no bare `button`; `rg -c ' title="'` unchanged; `show
--json | jq .goal,.tags` non-null on a tagged card; suites green.

**Batch B, the review** (agent, then the fable seat if confirmed): charter §17
per element, board first, catalog as the list; the fable seat reads the ledger
and catalog and tries to refute each COMPLIES row. Findings become rows, not
fixes, until the owner has seen them.

**Batch C, plan items** (each needs a short written proposal before code): #38
column settings, #39 named filter views (owner and agent share the vocabulary;
the search chips are the seed), #13 as bounded above.

**Batch D, carried caveats**: composite control states, reduced motion,
concurrent note edits, doc viewer after renderMd, light theme sweep, nudge to a
live peer end to end. Each is one exercise with a positive assertion.

**Parked by ruling**: #14, #15, #27, #32.

## 4 · Model plan

```
catalog + ledger + batch A  → main agent (opus-5) · inline · no sub-agents
§17 review                  → main agent · one surface at a time
adversarial review (once)   → fable · one seat · reads only, writes a findings file
                              under ~/.claude/scripts/kanban/REVIEW-<date>.md
```

No fleet, no worktree agents, no nested spawns. The fable seat is the only
seat, and only if the owner confirms it.

## 5 · How compliance is kept honest from here

Every row that moves from RECORDED to COMPLIES must say "re-run <date>" with
the command or the a11y observation. A row nobody can re-run stays RECORDED.
Two records disagreeing is resolved by exercising the surface, never by picking
the record that sounds more careful (the #41 lesson, twice in one morning).
