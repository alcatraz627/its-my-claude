<div align="center">

```
  ┌─┐┌─┐┌─┐  ┌───────────┐  ┌───────────────────────────────────────┐
  │▌│││ ││ │   K A N B A N   the owner's control plane for agent work
  └─┘└─┘└─┘  └───────────┘  └───────────────────────────────────────┘
   boards · asks · drafts · decisions · plans · (sessions, soon)
```

![runtime](https://img.shields.io/badge/runtime-bun-black) ![server](https://img.shields.io/badge/server-pm2%20%3A5106-blue) ![store](https://img.shields.io/badge/store-JSON%20files-green) ![tests](https://img.shields.io/badge/tests-136%20passing-brightgreen)

</div>

## What is this?

One local app where a human steers a fleet of Claude agents. Boards mirror
each project's docs; the owner writes **asks** that agents classify into
cards; **drafts** hold longer writing; **decision pages** collect batched
rulings in one paste; **plans** are registered docs with a state. Every kind
of thing is declared once in a registry and every surface (tabs, counts,
search, palette) derives from it.

> [!NOTE]
> The board is a **mirror**, never the source of truth: `sync` harvests
> cards from the project's own markdown, and staleness is always stated.
> The agent's equal-rights surface is the CLI, not the browser.

## Architecture

```
 kanban.sh ──▶ cli.ts ──┐            ┌──▶ board.html   /b/<slug>
                        ├──▶ lib.ts ─┤    hub.html     /  (+ ?view=…)
 server.ts (bun, pm2) ──┘   (state)  │    drafts.html  /drafts
      :5106  ▲                       └──▶ decision.html /dp/<slug>
             │ one writer per file · POSTs serialize · views re-read
 ~/.claude/kanban/*.json  +  assets/decision-pages/<slug>/config.json
```

Client pages share one look and behaviour layer (`shared.css`, `shared.js`,
`kinds.js`); `match.js` and `editor.js` are DOM-free so bun can test them.

## Quick start

```bash
pm2 start server.ts --name kanban          # usually already running
open http://localhost:5106                  # the hub
bash kanban.sh init                         # register a board for $PWD
bash kanban.sh sync                         # re-harvest it
for t in test/test-*.sh; do bash "$t"; done # 136 checks
```

> [!IMPORTANT]
> `board.json` has ONE writer (the CLI, under a lock); `notes.json` and
> `items.json` are written only by the server. Never hand-edit a store while
> either is running.

## By what you came to do

| You want to… | Go to |
|---|---|
| steer a board / answer asks | `http://localhost:5106/b/<slug>` |
| write something longer | `/drafts` |
| rule on a batch of decisions | `/dp/<slug>/` (hub: `/?view=decisions`) |
| act as an agent | `bash kanban.sh help` and `~/.claude/skills/kanban/` |
| ideate on the UI | **`design/HANDOFF.md`** and `design/SYSTEM.md` |
| know what is left | `docs/REMAINING-WORK.md` |

## Documentation

Everything lives in [`docs/`](docs/): the rulings ledger
([`UI-CHARTER.md`](docs/UI-CHARTER.md)), the token and component book
([`DESIGN-SYSTEM.md`](docs/DESIGN-SYSTEM.md)), the recurring failure classes
([`FEEDBACK-CLASSES.md`](docs/FEEDBACK-CLASSES.md)), per-area specs
(search, nav, editor, chat history, unified surfaces, decision-pages
adoption), and the live queue ([`REMAINING-WORK.md`](docs/REMAINING-WORK.md)).
Superseded material sits in [`docs/archive/`](docs/archive/).

> [!TIP]
> Reading order for a new agent: `docs/UI-CHARTER.md` §1 (the disposition),
> then `docs/FEEDBACK-CLASSES.md`, then whatever spec touches your task.

> [!WARNING]
> Three archived ledgers (compliance, surface catalog, caveats) are kept for
> history but were flagged stale on 2026-08-24. Treat `docs/archive/` as
> record, never as instruction.

## How work happens here

Owner rulings land in the charter with dates; recurring misses become
feedback classes; the queue lives in `docs/REMAINING-WORK.md` and on the
board itself (`/b/-claude-244ec6`). Changes ship with browser verification
and a test per guard, and the charter checks are mutation-tested: a check
that cannot fail is treated as a bug.

## Repo structure

```
board.html hub.html drafts.html decision.html   the four pages
shared.css shared.js kinds.js editor.js match.js shared layers
server.ts lib.ts cli.ts harvest.ts kanban.sh    server · state · CLI
design/          the design handoff package (start at HANDOFF.md)
docs/            specs, ledgers, reviews · docs/archive/ superseded
test/            five bun/bash suites, run from anywhere
```
