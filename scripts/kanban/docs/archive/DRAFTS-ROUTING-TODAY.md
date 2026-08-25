# How a draft reaches an agent today

Written 2026-08-22 before planning any change to it, because a plan for an
existing surface that never wrote down the surface is a plan for an imagined one.
Every claim below cites the line that proves it.

## The two writers

The owner owns the text, the agent owns what it did with the text. That split is
deliberate and predates this note: `drafts.json` is written by the server on the
owner's behalf, `pulls.json` by the CLI on the agent's, so a pull still records
with the server down (`lib.ts:534-538`).

## What a draft carries

`Draft` (`lib.ts:540-550`) has exactly six fields beyond its text: `id`,
`title?`, `isTemplate?`, `slug?`, `triggered?`, and the two timestamps.

- **`slug`** is a board affinity and is optional; a draft starts uncoupled.
- **`triggered`** is an ISO timestamp meaning "Offer to a session", set by the
  button at `drafts.html:338` through `PATCH /api/draft` (`server.ts:637`).

**There is no field naming an agent.** Not an alias, not a session, not a lane.
The routing vocabulary a draft can express today is one board, or nowhere.

## How an agent finds one

Pull-based, entirely. Nothing is pushed.

1. `pendingDrafts` (`lib.ts:582-589`) returns drafts that are not templates, not
   consumed, and whose `slug` is either absent or equal to the board being asked
   about. An absent slug matches every board.
2. `kanban.sh drafts` runs that against the board for the current project
   (`cli.ts:479-482`), so an agent sees this project's drafts plus every
   unassigned one.
3. `session-start-line.sh` reports the count at session start, and says how many
   carry `triggered`. That surfacing is one hour old, added 2026-08-22; before
   it, offering a draft signalled nothing anywhere.
4. `kanban.sh drafts <id>` prints it in full; `kanban.sh pull <id>` consumes it
   and records a `Pull` with an optional `cardId`, `slug` and `note`.

**Consequence: a draft is addressed to a place, and picked up by whoever happens
to be standing in it.** Two agents in one project both see it, either may pull
it, and the first to pull makes it invisible to the second.

## The sibling lane, which is further along

An `Item` (an "ask", `lib.ts:446-455`) already carries what a draft does not:
`boards?: string[]` overriding the origin slug, absent meaning everywhere
(`lib.ts:450`), resolved by `displayScope` (`lib.ts:461`). An ask can be shown on
several boards or on all of them. It still names no agent.

## The push channels, and what they can address

Two exist, and both answer the same question wrongly for this purpose.

- `POST /api/nudge` (`server.ts:831`) composes a message and sends it to
  `livePeers(reg.root)`.
- `POST /api/send` (`server.ts:894`) pushes the owner's selection the same way.

`livePeers(root)` (`server.ts:169-200`) reads the ipc registry and returns every
session whose `cwd` is at or under the board's project root, minus auto-generated
aliases and the board's own identity.

**So every push is addressed to a directory, never to an agent.** "Send this to
gcp-fable" is not expressible. The nearest available act is "send this to
everyone working in the gcp checkout", which today is one session and tomorrow
may be three.

Liveness is `last_seen` within a window, currently 1800s (`server.ts:181`, raised
from 900s today). The `status` column is not usable for this: measured
2026-08-22 it reads `live` for sessions last seen 21 hours ago, 172 rows of 266.

## What is therefore missing, stated plainly

1. A draft cannot name its recipient. Only a board, or nobody.
2. A draft cannot be pushed at all. `triggered` sets a flag that a session may
   notice at its next start; no message is sent.
3. There is no agent inbox. The nearest thing is a per-project pull.
4. A draft that is offered and then not picked up decays silently. Nothing
   escalates, nothing expires, nothing tells the owner it was never read.
5. The owner cannot see who read it. `Pull.by` records a session id
   (`lib.ts:553-559`), and no surface shows it back to them.
