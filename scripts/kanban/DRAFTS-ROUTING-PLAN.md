# Plan: a draft can name who it is for, and reach them

2026-08-22 · SHA `e1783d3` · current behaviour: `DRAFTS-ROUTING-TODAY.md` beside
this file, read it first.

Owner's ask, verbatim:

> "The Drafts straight up need more features and ability to tag for what agent to
> send, either passively leaving it in the agent's "inbox" (or the kanban board
> asks list if applicable), or the ability to actively send it to an AGENT. This
> needs a more structural /plan for the features / flows / capabilities, and then
> we build it all, and then comes the final UI consistency and ergonomics polish"

## What kind of change this is

Not a feature bolted onto drafts. It is **one missing concept, an address**, plus
the two deliveries that an address makes possible. Everything else follows.

Today a draft is addressed to a *place* and collected by whoever stands in it.
The ask is for a draft addressed to a *recipient*, delivered either by leaving it
where they will look, or by handing it to them.

## The problems, each falsifiable

Each states what is wrong, what would prove it, and what would prove it fixed.

**P1 · A draft cannot name a recipient.**
Proof: `Draft` has no field for one (`lib.ts:540-550`); the only routing field is
`slug`, a board.
Fixed when: `kanban.sh drafts --to agent:gcp-fable <id>` succeeds and
`kanban.sh drafts --json` shows the draft carrying that recipient.

**P2 · A draft cannot be handed to anyone.**
Proof: `triggered` sets a timestamp and sends nothing; the two channels that do
send (`/api/nudge`, `/api/send`) address `livePeers(root)`, a directory.
Fixed when: offering a draft addressed to a live alias produces a message in that
session's ipc inbox, and the response names who received it.

**P3 · An offer that reaches nobody is silent.**
Proof: `drafts.html:338` flips the button to "Offered" on a successful PATCH,
which only records the flag. Nothing checks whether anyone can see it.
Fixed when: offering to a recipient who is not live returns and displays
"nobody live — it will wait in their inbox", and offering to nobody at all is
refused rather than accepted.

**P4 · There is no inbox, only a per-project sweep.**
Proof: `kanban.sh drafts` scopes by the board for the current project
(`cli.ts:479-482`); an agent's own identity is never consulted.
Fixed when: a session whose ipc alias is a draft's recipient sees that draft from
any directory, and a session that is not the recipient does not.

**P5 · The owner cannot see what became of it.**
Proof: `Pull.by` holds a session id (`lib.ts:553-559`) and no surface renders it.
Fixed when: a pulled draft shows who pulled it and when, on the drafts page.

## The approach is already in this codebase

Three shapes exist here and this change reuses all three rather than inventing.

1. **Scope resolution.** `Item.boards?: string[]` with absent meaning everywhere,
   resolved by `displayScope` (`lib.ts:450,461`). A draft's recipients get the
   same shape and the same "absent means anywhere" default, so one rule governs
   both lanes.
2. **Two-writer split.** The owner's file and the agent's file stay separate
   (`lib.ts:534-538`). Recipients are the owner's, so they live in `drafts.json`.
   Delivery receipts are the agent's, so they go beside pulls.
3. **Addressed send.** `/api/nudge` already composes a message, registers the
   board's identity, sends over ipc and reports `sent` plus a `reason` when it
   sends nothing (`server.ts:869-887`). The draft push is that function with a
   different recipient resolver and a different body.

## The contract

One new field on the owner's side, one new record on the agent's.

```
Draft.to?: string[]     // "board:<slug>" | "agent:<alias>"; absent = anywhere,
                        // exactly as Item.boards absent means everywhere
```

`slug` is NOT replaced. It stays what it is, the draft's home board, and a
`board:` recipient is a separate statement about who should act. A draft can sit
on the gcp board and be addressed to an agent working elsewhere.

Resolution, one function, mirroring `displayScope`:

```
recipientsOf(d): { boards: string[], agents: string[] } | null   // null = anyone
visibleTo(d, { slug, alias }): boolean
```

`visibleTo` is the single rule every surface asks: the CLI sweep, the
session-start line, and the push. Three surfaces asking one function is the fix
for the drift that `session-start-line.sh` already warns about in its own header.

Delivery receipt, agent-side, beside `pulls.json`:

```
Delivery { draftId, to, at, ok, sent: string[], reason?: string }
```

## Directives, each with the check that proves it

| # | Directive | Check |
|---|---|---|
| D1 | `to` accepts only `board:<slug>` and `agent:<alias>`; an unknown board is refused the way `/api/pin` refuses one | POST a bad slug, expect 404 with the slug named |
| D2 | Absent `to` behaves exactly as today | `pendingDrafts` output for an unaddressed draft is byte-identical before and after |
| D3 | `visibleTo` is the ONLY place the rule lives | grep: no surface re-implements a recipient test |
| D4 | A push reports who received it, and says so when nobody did | offer to a dead alias; response carries `sent: []` and a reason; UI renders it |
| D5 | A push never silently replaces the wait | after a failed push the draft is still pending for its recipient |
| D6 | An agent sees a draft addressed to it from any directory | run the CLI from `/tmp` with the alias set; the draft appears |
| D7 | An agent does NOT see a draft addressed to another agent | same run, different alias; it does not appear |

D7 is the one to write first. It is the only directive whose failure is silent
and whose blast radius is the owner's private text going to the wrong reader.

## Parity ledger — what must not change

| Behaviour | Why it is load-bearing | Check |
|---|---|---|
| An unaddressed draft reaches whoever is in the project | Every draft today is unaddressed; changing this breaks the whole existing corpus | D2 |
| A pull still records with the server down | Stated design reason for the two-writer split | run `kanban.sh pull` with the server stopped |
| The staleness rule from this morning: a revised draft returns | Shipped today, and it is what surfaced this whole ask | `test-drafts.sh` section 8 stays green |
| The session line runs with no bun and no server | Its stated contract | run it with pm2 stopped |
| `--json` shapes stay additive | Agents parse them | existing keys unchanged |

## The smallest slice that runs

Slice 1 is the whole concept, end to end, for one recipient kind, and it is
worth shipping alone:

1. `Draft.to`, `recipientsOf`, `visibleTo` in `lib.ts`, with D2 and D7 as tests.
2. `kanban.sh to <draft-id> agent:<alias>` and `--clear`, refusing an unknown
   board the way `/api/pin` does.
3. `pendingDrafts` asks `visibleTo`, and the CLI passes its own ipc alias.
4. `session-start-line.sh` mirrors it, and `test-drafts.sh` section 11 pins the
   two definitions against one fixture, exactly as it does for staleness now.

Nothing in slice 1 sends anything. It is the address, and the address is the part
everything else needs.

Slice 2 is the push: `POST /api/draft-send`, `/api/nudge`'s resolver swapped for
`recipientsOf`, receipts, and D4/D5.

Slice 3 is the owner's view: recipients on the draft row, who pulled it and when
(P5), and the "nobody was live" state rendered rather than swallowed.

Slice 4 is the asks-list route the owner names as an alternative: a draft can
land as an `Item` on a board, reusing `classify`.

## What this plan deliberately does not do

- It does not touch the editing surface. That is the direction memo's territory
  and a separate lane.
- It does not add an expiry or an escalation for an unread draft. P3 makes the
  silence visible, which is the smaller half; whether an unread draft should
  chase anyone is a question for the owner, not a default.
- It does not move `slug`. Renaming a field every doc references buys nothing
  here.

## What needs the owner

1. **Is `agent:<alias>` the right unit**, or should a draft address a *role*
   (whoever is working on gcp) rather than a named session? An alias is precise
   and dies with the session; a role survives but is vaguer. Recommendation:
   alias now, because it is what you asked for and it is checkable; roles are a
   later widening of the same field.
2. **Should an addressed draft be invisible to non-recipients, or merely
   deprioritised?** Recommendation: invisible, per D7. Deprioritised means your
   private text is still readable by any agent in the project.
3. **Slice 4** (a draft landing as an ask) is the smallest and the least certain
   I have understood you. Recommendation: build slices 1 to 3, then look at it
   with the surfaces in front of us.
