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

## 2 · Still the owner's (four picks, wizard-presented)

| Pick | Recommendation | Why |
|---|---|---|
| Fable seat: use it for one adversarial review of the ledger and catalog | Yes, one seat, after the fix-now batch lands, so it reviews shipped state | A second seat is the one caveat every record carries; fable at one seat stays inside the cap |
| #48 vb-fable's needs-human card | Tell them the board is not a decision surface; a decision kind is a new entity and belongs after #39 | Decision pages already exist on :5197; building a second one on the board duplicates a surface |
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
