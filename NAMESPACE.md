# The gcc vocabulary

<!-- sessions: polish-cdump-4e@2026-10-28 -->

Fourteen words for the parts of `~/.claude` (the gcc). They are the words you already use when you talk about the system, so you can name any part in a prompt and an agent knows what you mean. `gcc::<word>` is the same word with a prefix and is optional. The words are labels only: no code imports them, and a word does not map to one folder.

To remember them, follow one session from start to finish. It **knows** things, does **work**, is **guarded** while it works, **shows** you what is happening, and **keeps** what is left when it ends.

## Cheat sheet

```
KNOW    rules · skills · memory          what Claude reads before it acts
WORK    goals · seats · ipc · schedule   how work is planned, split and run
GUARD   gates · usage                    what stops, warns and meters it
SHOW    hub · pages                      where you see it
KEEP    checkpoints · ledger · dream     what survives the session
```

To find a file, use `FOLDERS.md` for folders and `LOOKUP.md` for single files. This page only names the parts.

## The words

### KNOW: what Claude reads before it acts

**rules.** Everything that tells Claude how to behave or how a thing works: `CLAUDE.md`, `rules/`, `features/`, `conventions/`, and the indices (`LOOKUP.md`, `FOLDERS.md`, `PLACEMENT.md`, `GLOSSARY.md`). `migrations/` records each structural change to them. You say "the rule", "gcc rules".

**skills.** What Claude can pick up and use: `skills/` (the slash commands, plus the `skills/shared/` helper library), `personas/`, the plugins in `settings.json`, the MCP servers (`mcp-catalog.json`), and the tools for seeing the screen (`lm see`, `scripts/desktop.sh`). `skills-parked/` holds skills taken off the roster.

**memory.** What Claude remembers about you and your projects between sessions: `memory/` (global and per-project), `guidance/notes.md` (your standing directives), and `scratchpad/` for half-proven notes.

### WORK: how work is planned, split and run

**goals.** What the work is for and what is left: the goal record (`goals/`, `scripts/goals/gs`), the session task lists (`tasks/`, `tasks-pins/`, `/tasks`), and the weekly todos. You say "goal", "tasks", "what is left".

**seats.** Every agent or model the main session hands work to: sub-agent seats (`seats/`, `scripts/seats/`), `/magi` voters, Codex (`adapters/codex/`) and the local models (`lm`, `lm gemini`). Model routing (fable, opus, sonnet, haiku) lives here too.

**ipc.** Sessions talking to each other: `claude-ipc` (source in `~/Code/Claude/claude-ipc`), `handoffs/` and `groups/`.

**schedule.** Work that runs on a clock or in the background: `scheduled/` and `gcc-schedule`, the login-time `scripts/startup/`, `warden/`, `keepwarm/`, `cron-duties/`, `deployq/`, and the dev servers under pm2 (`dev-servers/`).

### GUARD: what stops, warns and meters it

**gates.** Everything that checks Claude's work as it happens: the hooks (`scripts/hooks/`, `hinters/`, `git-hooks/`), the policy that Switchboard sets from the menu bar (`policy/`, `scripts/pol/`), and the prose engine (`style/`, `scripts/style/`). You say "gate", "hook", "policy", "switchboard".

**usage.** How much Claude has spent and has left: `scripts/usage/`, `usage5h/`, `telemetry/`, and the cost lines in the status line.

### SHOW: where you see it

**hub.** Everything drawn in the terminal: the gcc-mods band and side pane (`mods/gcc-mods/`, `/hub`), the status line (`scripts/statusline/`), tab titles, the callout boxes (`scripts/box/`), the TUI library (`scripts/tui/`), and the macOS widgets (`widgets/`).

**pages.** Everything shown in a browser or as a file: decision pages (`scripts/decision-page/`), local pages on the shared kit (`scripts/pages/`), reports and other kept outputs (`assets/`), and the mothballed kanban board.

### KEEP: what survives the session

**checkpoints.** How a session is resumed: `/core-dump` and `/catchup`, the `_*.claude.md` files and `checkpoints/`, `session-notes/`, the write-ahead log (`wal.jsonl`), and the compact gate. You say "core-dump", "catchup".

**ledger.** The records of judgment: `atone/` (mistakes), `affirm/` (good calls), `proposals.jsonl` (the improvement backlog), `pinned/`, and the alerts in `ledger/`. You say "atone", "proposal", "backlog".

**dream.** The i-dream engine that reads past sessions and writes digests and briefs: `i-dream/`, `subconscious/`, and the `*-domain/` event streams. Its source is `~/Code/Claude/i-dream`. You say "i-dream", "digest", "audit".

## Adding a word

Add a word only when you have started using one in prompts for a part that none of the fourteen covers. A new folder usually belongs to an existing word, so give it a `FOLDERS.md` row instead.

## Old labels

Before 2026-10-28 this page was a `std::claude::<cluster>` tree with one label per folder. Older files still use those labels. Each one means the word on the right:

| Old label | Word now |
|---|---|
| `rules`, `features`, `conventions`, `placement`, `migrations` | rules |
| `skills`, `shared`, `personas`, `plugins`, `mcp`, `vision` | skills |
| `memory`, `scratchpad` | memory |
| `tasks`, `todos` | goals |
| `magi` | seats |
| `schedule`, `startup` | schedule |
| `style` | gates |
| `tui`, `widgets` | hub |
| `assets` | pages |
| `checkpoints`, `logging` | checkpoints |
| `ledger`, `improvement` (ideas, mistakes, proposals, insights) | ledger |
| `improvement::dreams` | dream |
| `code`, `scripts`, `network`, `backups` | retired: each is a folder, not a part (see `FOLDERS.md`) |

The full old tree is in git history: `git -C ~/.claude show 0a8d985:NAMESPACE.md`.
