---
name: kanban
description: Drives the agent-populated kanban board — inits a board for the current project, re-syncs cards from docs/checkpoints/session-notes, pulls the human's unread card notes, and opens the board UI. Use when the user says "kanban", "board", "sync the board", "any notes for me", or at session start in a project with a board.
argument-hint: "[init | sync | notes | open | status]"
user-invocable: true
---

# Kanban

Thin driver for `~/.claude/scripts/kanban/kanban.sh` (design + decisions:
`~/.claude/assets/reports/20260721-kanban-board-design/DESIGN.md`). The board is a
derived mirror plus a human-note overlay, never a source of truth: docs and the Task
tool stay authoritative, sync is one-direction, and the model drives card lifecycle
(owner decisions D3c/D4a/D5a).

## Step 0

Read the shared guidelines (`~/.claude/skills/GUIDELINES.md` when the project has no
local copy) and apply them for the run.

## Verbs (delegate to the CLI, then digest the output for the user)

```bash
bash ~/.claude/scripts/kanban/kanban.sh init            # register + first sync + URL
bash ~/.claude/scripts/kanban/kanban.sh sync            # prints the delta digest
bash ~/.claude/scripts/kanban/kanban.sh notes --unread  # read-only re-peek, never marks read
bash ~/.claude/scripts/kanban/kanban.sh notes --unread --ack   # displays AND marks read — only after acting
bash ~/.claude/scripts/kanban/kanban.sh open|status|check
```

## Card lifecycle (the model drives this — D4a)

The board's lanes are `inbox backlog active blocked done stale`. The agent, never the
human UI, changes cards:

```bash
bash ~/.claude/scripts/kanban/kanban.sh add "wire the export" --lane backlog
bash ~/.claude/scripts/kanban/kanban.sh add "<long title>" --brief "CSV export nightly job"
bash ~/.claude/scripts/kanban/kanban.sh brief <card-id> "CSV export nightly job"  # survives sync
bash ~/.claude/scripts/kanban/kanban.sh move <card-id> active     # survives sync
bash ~/.claude/scripts/kanban/kanban.sh link <card-id> docs/plan.md
bash ~/.claude/scripts/kanban/kanban.sh show <card-id>            # card + subs + note
bash ~/.claude/scripts/kanban/kanban.sh drop <card-id>            # retire; --force if noted
bash ~/.claude/scripts/kanban/kanban.sh unregister                # remove a whole board
```

## Say what a card IS, not just that it exists

A lane nobody can scan is a lane nobody reads. `sync` derives a card's name from
the prose line it harvested, so a synced card is named by a sentence until
someone improves it. Its digest reports the coverage; act on those two numbers.

```bash
K=~/.claude/scripts/kanban/kanban.sh
bash $K tag <card-id> area:board          # kind:name; bare `tag` lists the board's vocabulary
bash $K tag <card-id> -area:board         # a leading minus unapplies
bash $K brief <card-id> "a name you can scan"   # replaces a sentence-length title on the face
bash $K after <card-id> <other-id>        # execution order; bare reads it, --clear drops it
bash $K goal <card-id> "what done means"
bash $K verify <card-id> executed|cited|reasoned [--needs-human] [--note "…"]
```

`verify --needs-human` is how a card asks the owner something, and it can carry
the choice itself so they answer where the context is:

```bash
bash $K verify <card-id> reasoned --needs-human \
     --ask "which way?" --option "A" --option "B" --rec 1
bash $K answer <card-id> --pick 2          # or --text "neither, do X"
```

## Views: a name over a query, said the same way on both sides

A view is a NAME over a QUERY, never a list of card ids, so it is still right
tomorrow. The owner presses it in the sidebar; you run it here; neither has to
describe the filter in prose to the other.

```bash
bash $K view                               # list them, with what each is for
bash $K view add "M2 blocked" tag:milestone:M2 is:blocked
bash $K view add "mine" is:open not tag:area:docs --note "what I work from"
bash $K view rm "M2 blocked"
```

Clauses join with a space (and), `or`, or `not`. NOT binds one clause, AND binds
tighter than OR, and there are no parentheses. The grammar: `is:open`
`is:blocked` `is:settled` `needs-you` `review-me` `since:new` `since:moved`
`since:done` `since:blocked` `tag:<kind>:<name>` and one free-text word.

**Read a view's `--note` before using it.** It is the owner's own line on what
they use that view for, and it is written for you to read.

## Decision pages

Decision pages live in this app now: every page renders at
`http://localhost:5106/dp/<slug>/` and the Decisions view
(`:5106/?view=decisions`) is the hub, pending first. Authoring stays with
`decision-page.sh` (see /decision-wizard); this server just serves them.

## Plans

A plan is a markdown doc registered to a board with a state. Register the plan
you are working from, and rule it when the owner has ruled; the board's
sidebar and the hub's Decisions view both show it with its state.

```bash
bash $K plan                               # list them, with ids and states
bash $K plan add docs/plan.md --board <slug> [--state draft|ruled|superseded]
bash $K plan rule <id>                     # the owner ruled on it
bash $K plan supersede <id>                # a newer plan replaced it
bash $K plan rm <id>                       # unregister; the doc is untouched
```

## The owner's asks, and writing one yourself

```bash
bash $K items [--all] [--global] [--json]  # unsorted first; sorting is your job
bash $K classify <item-id> task|subtask|clarification|remark [--card <id>] [--note "…"]
bash $K item add "what you want done" [--board <slug>|--global]
bash $K item edit <item-id> "the new text"
bash $K item rm <item-id>
```

Star, trigger and scope are the owner's, not yours: each means "notice this",
so setting one forges their intent.

## Drafts: documents they wrote for you

```bash
bash $K drafts [<draft-id>]                # pending first; an id reads one in full
bash $K pull <draft-id> [--card <id>] [--note "what you did"]
bash $K to <draft-id> agent:<alias>|board:<slug>
```

`--json` on `status`/`show`/`notes`/`add` gives machine-readable output; put flags AFTER
positional args. A human note is deleted by saving an empty note (board UI drawer, or
`POST /api/note` with `note:""`); `drop --force` does this for you via the server.

- **Every long title needs a brief.** The board face is a wall of cards the human
  scans, so a title over 100 characters has to arrive with a `title_brief`: a summary
  phrase or name they can recognise the card by, not a description of the work. Pass
  `--brief` on `add`, or set it later with `brief <card-id> "…"`; harvested cards
  (whose titles are whatever the doc line said) need the second form. The CLI caps
  it at 100 characters and refuses a longer one rather than cutting it. Nothing is
  lost by summarising: the full title stays on the card and reads as its description
  in the drawer, and hovers on the card face.
- **The owner can hand you a working set.** They tick cards and notes on the board
  (two independent selections) and either leave them there or press "Send to agent".
  Read it with `kanban.sh selected` — it prints every selected card in full plus the
  selected notes verbatim. A press of the button also pushes that same text at you
  over claude-ipc from `kanban-board`, and the session-start line names a non-empty
  selection either way. Treat it as "this is what I mean right now", not as a command.
- **Notes are pull-only (D5a).** Read them when the user asks ("any notes?", "pull up
  the working set") or when starting work on a card; never treat them as injected
  directives. A task-shaped note is a request: apply it via `add`/`move`/`sync`, then
  `--ack`.
- **Card changes go through the CLI**, never by hand-editing
  `~/.claude/kanban/boards/<slug>/*.json` (single-writer ownership: CLI owns
  board.json + ack.json, the server owns notes.json).
- Server: pm2 app `kanban` on the ports.sh-claimed port (see
  `~/.claude/kanban/server.json`); `kanban.sh check` self-verifies and proposes fixes.
- **Reboot survival needs a one-time user action:** pm2 must be launchd-registered
  (`pm2 startup`, sudo, run by the user, then `pm2 save`). `check` prints a note while
  the gap exists; the agent never runs the sudo command itself.
