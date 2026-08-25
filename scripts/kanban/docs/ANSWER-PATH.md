# The answer path for a needs-human card

Design for #48, 2026-08-23. Owner ruling D2a on the decision page; constraints
from vb-fable (msg-2cd095d8), ranked, the first two load-bearing.

## What it is, in one paragraph

An agent that grades a card `needs-human` can now also put the choice on the
card: the options, its own pick, and the question. The owner answers on the
card, in the drawer, with a pick and/or free text, or marks it "later". The
card then carries three distinguishable states (not yet seen, seen and
deferred, answered), all readable from `show --json` without parsing prose.
No new card kind, no lane, no workflow: one field on `verify` and one verb.

## The data (one field, on the object that already survives sync)

```ts
verify?: {
  grade: "executed" | "cited" | "reasoned";
  needsHuman?: boolean; note?: string; at: string;
  ask?: {                                   // NEW, only with needsHuman
    question?: string;                      // one line; note stays the context
    options: string[];                      // 2 to 6, the agent's words
    rec?: number;                           // index of the agent's pick
    askedAt: string;
    seenAt?: string;                        // set when the owner opens the drawer on it
    deferredAt?: string;                    // set by "later"
    answer?: { pick: number | null; text?: string; at: string };  // pick OR text OR both
  };
};
```

State is derived, never stored as an enum (pattern: a record and a verdict are
different questions):

| state | rule |
|---|---|
| not seen | `ask` and no `seenAt` and no `answer` |
| seen, deferred | `seenAt` or `deferredAt`, no `answer` |
| answered | `answer` present |

`answer.pick` may be `null` with `text` set: "neither, do X" is a first-class
answer, never a note somewhere else (constraint 4).

## The verbs

Agent side (`cli.ts`):

```
kanban.sh verify <id> executed --needs-human --ask "A|B|C" [--rec 1] [--question "…"] [--note "…"]
kanban.sh answer <id>            # read: state, options, the answer if any; --json for the object
```

`verify --ask` without `--needs-human` is refused: an ask is what needs-human
means. `show --json` already carries `card.verify`, so the ask and the answer
arrive with no new route for readers.

Owner side (server + board):

```
POST /api/answer { slug, cardId, pick?: number|null, text?: string }   → answer
POST /api/answer { slug, cardId, seen: true }                          → seenAt, once
POST /api/answer { slug, cardId, defer: true }                         → deferredAt
```

Server-owned because `board.json` is written by the CLI under a lock today and
by the server for notes; the answer is the owner's, so it goes the owner's way
(the single-writer rule the note path already follows).

## The surface (drawer only; the face changes one pill)

- Face pill: `Needs you` stays amber for not-seen; `seen · later` for
  deferred (same amber, a dot); `answered` goes green and carries the pick's
  first words. Hub pill `N needs you` counts not-seen and deferred only.
- Drawer, under "What the agent claims": the question, the options as a radio
  list with the recommended one marked `agent's pick` (constraint 5, visually
  distinct by a label rather than colour alone, §4), a one-line text box, and
  two buttons: `Answer` (primary) and `Later`. Answered state shows the answer
  and an `Change` link; it never re-asks.
- Opening the drawer on a not-seen ask posts `seen` once. That is the whole
  mechanism for constraint 2: the owner cannot have decided without seeing,
  and "seen" is the cheapest honest signal the board can give the agent.
- Keyboard: `1`-`6` pick when the answer block is focused, `⌘↵` answers, `l`
  defers. Esc steps out (§10).

> **Built 2026-08-24 (#48), steps 1 to 3 and 5.** One correction to the design
> above, and it matters. The type sketch puts `seenAt`, `deferredAt` and
> `answer` inside `verify.ask` on the card, but `board.json` has exactly one
> writer and it is the CLI (charter §11); the server has never written it. So
> the halves are split along the line the plan's own prose draws: the AGENT's
> half (`question`, `options`, `rec`, `askedAt`) is on the card, and the
> OWNER's half lives in `plan.json` under `answers[cardId]`, which is where the
> note path already puts the owner's words. `askOf(card, plan)` merges them, so
> every reader still sees one object and no caller touches `plan.answers`
> directly. `seenAt` is written once and a later defer does not move it.
>
> **Step 4 built the same day.** The drawer block, the face pill and the count.
> Two collisions the plan's keyboard line would have caused, resolved the way
> the plan itself scopes them: the board already spends `1`-`9` on "jump to that
> tab" and `l` on "next lane", so the ask's keys live on the block and fire only
> when focus is inside it. Verified both ways: `2` inside the block picks option
> two, `2` outside still means what it always meant.
>
> One wording fix caught by looking at it rather than by a test. The face read
> `seen · later` as soon as the drawer opened, which claims the owner deferred
> when all they did was look. "Later" is something they SAY; opening is not
> saying it. Three labels now, for three states: `needs you · a choice`,
> `needs you · seen`, `seen · later`, then `answered · <the pick>`.

## Sequence (build order, each with its check)

1. `lib.ts` type + `show --json` already serves it. Check: `test-items.sh` row
   seeds an ask on the fixture card and reads it back through `show --json`.
2. `cli.ts` `verify --ask/--rec/--question` and `answer`. Check: refusal
   without `--needs-human`; `answer --json` prints the derived state.
3. `server.ts` `/api/answer` with seen/defer/answer. Check: three POSTs, three
   states, `answer` rejects a pick outside range.
4. `board.html` drawer block + face pill + hub count. Check: a11y tree shows a
   radiogroup with a named recommended option; screenshot both themes; the
   §14 round.
5. Charter §12 gains one line: a decision the owner has not opened is shown as
   unseen, never as undecided.

Out of scope, on purpose, per the owner's D2 note: decisions without a card,
and a project-level decision mechanism with its own attention and callout.
That belongs to #56 (unified surfaces) and can reuse this field shape.
