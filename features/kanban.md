---
brief: The kanban board is a project's communication surface between the human and its agents, spanning sessions, agents and days. Independent of the Task tool, never a mirror of it. Optional, and earned by project shape rather than by todo count.
triggers:
  - tool:kanban.sh
  - skill:kanban
  - topic:kanban
  - topic:project-board
  - phrase:"the board"
  - phrase:"sync the board"
  - phrase:"any notes for me"
related: [rules/todo-discipline.md, skills/kanban/SKILL.md]
tier: 2
category: features
updated: 2026-08-10
stale_after_days: 180
---

# The kanban board

## What it is for

The owner's words, 2026-08-10: **"The kanban is for user communication over the
entire project."** It is a communication surface between the human and the
agents working a project. It is not a task list, which is why it is not, and
must never become, a mirror of the Task tool.

The Task tool is the source of truth for a single session and is what the TUI
shows. A project is greater than one session, one agent, or one day. A sprint
board is a different artifact from a checklist in a PR description, which is
different again from an engineering spec. Three altitudes, not three copies.

## Which projects earn a board

Optional by design. The owner's three shapes:

- Some projects never need one and are fine without it.
- Some have two agents working as peers in two windows.
- Some have the same agent given different goals and todos every day for a week.

Only the last two earn a board. **Do not create one because a session crossed
some number of todos.** Session size is not the signal. Project continuity is:
a board already exists, another agent is live in the project, or a prior session
left a checkpoint here.

## How it works

Global data under `~/.claude/kanban/`, a bun server on pm2 (port from
`ports.sh`, currently 5106) serving two static pages, code at
`~/.claude/scripts/kanban/`, and the `/kanban` skill.

**The browser is read plus notes only.** Every card mutation (move, drop, link,
verify) goes through the CLI. Human requests travel as tags inside note text,
which agents parse and apply. Do not add mutation UI to the browser.

Cards are harvested from project docs, so the board is a derived mirror **of the
docs**, never a source of truth about the code. Notes are the human's lane and
the one thing the browser writes.

### Notes

A card holds many notes. Each has its own id, body, timestamp and pickup state.
The legacy `note` field is kept populated as a derived join so older readers
keep working, and that join excludes `@me` bodies because `@me` suppresses
rather than fires. Per-note pickup lives in `ack.json`, which stays CLI-owned so
the session-start reader still works with the server down.

Agents pull with `kanban.sh notes --unread --ack`, which returns one row per
note keyed `cardId#noteId`. A `!now` on any note fires. An `@me` note never
nags an agent.

### What a card can carry, and where it lives

Beyond lane and notes, a card carries the same vocabulary `/tasks` uses, so a
board and a task store can say the same thing about the same work. All of it
is in `plan.json` (server-owned, survives sync), read back by `show --json`:

- **tags**, by kind: `milestone` · `priority` (P1 P2 P3) · `class` (plan build
  review fix design, what KIND of work it is) · `tier` (lm gemini haiku sonnet
  opus fable, the model lane) · `effort` · `area` · `risk` · `plain`.
  `kanban.sh tag <id> <kind>:<name>`; a leading `-` removes.
- **goal**: the one line on why the card exists. `kanban.sh goal <id> "…"`.
- **after**: execution order, the cards this one comes after; the face shows
  `after N` with their titles on the tip. `kanban.sh after <id> <id…>`.

Use `priority` for P1..P3 and `tier` for the model: a board once filed P1 under
`tier` because `priority` did not exist, and the sidebar grouped it with opus.
When you find the board cannot hold an attribute the work needs, add the kind
or the field here rather than bending an existing one; every agent will hit
the same wall.

### Invariants that cost something to learn

- Wiping a card's notes requires an explicit `all: true`, which only `drop`
  sends. A blank save without a note id used to delete every note on the card
  and report success.
- Shape-check before iterating. A string has `.length`, so `notes: "not an
  array"` once passed a truthiness guard and crashed the CLI.
- Compare timestamps with `Date.parse`, never as strings.
- Read each board in isolation in the hub endpoints. One corrupt `board.json`
  used to take the whole fleet view down.
- `scripts/kanban/test-readers.sh` is the regression suite. Run it after any
  change to the board, and treat a green run as evidence only about the checks
  it actually makes.

## Related

- `rules/todo-discipline.md` carries the session-altitude rule this sits beside.
- `skills/kanban/SKILL.md` is the operational surface.
- `~/.claude/assets/magi/20260810-0157-kanban-notes-entity/` holds the panel
  verdict behind the notes design, including why templates were deferred.
