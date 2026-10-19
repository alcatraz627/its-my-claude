# gcc-mods

The gcc surfaces drawn inside the Claude Code TUI: clickable absolute paths, one band row for whatever waits on you (a decision page, the resume offer after a clear, pasted images), the context gauge in the status line, a display-only side pane, and wakes for an idle session. `GUIDE.md` beside this file explains each one.

It loads in every session through `CLAUDE_CODE_PLUGIN_DIRS` in the `env` block of `~/.claude/settings.json`, and starts off: a session behaves as if the mod were absent until `/hub on` turns it on for that session. The `startOn` switch in `/config` makes it start on everywhere. The folder is watched, so edits hot-reload. Built against Claude Code 2.1.291 and trimmed on 2.1.299; the mods API is early access, so after a CLI update run the three checks below before trusting it.

## What it draws

| Surface | What you get |
|---|---|
| transcript | paths drawn absolute and clickable with the trailing period outside the link (every file, notes and text included, opens natively as a `file://` link through the OS default handler); seat landings and peer mail as one line (ctrl+o for the full row); a dim line when a Stop hook sends the reply back |
| band above the prompt | every offer is one line in the same shape, `[kind chip] title · detail · link   [primary] [secondary] ✕`, one offer at a time and nothing when nothing applies: a decision page filed for this folder (with its link), the checkpoint after a clear or resume (load runs `/catchup`), continue when the agent stopped with agent-ready rows open, an insert-`/core-dump` button past 70 percent context, then the reads owed by you. Above it, when the prompt draft holds `[Image #n]`, an images row with an `open` button per image, a `view` button and a `copy path` button |
| side pane | `/hub side` opens a display-only pane (text and boxes, no buttons) with six tabs: Overview (default, at most six lines per section, each pointing at its tab), Tasks, MCP, Plugins, Injections and Context, where the full annotated list sits one item per row in aligned columns (state, transport, command or URL, config file, install path, token cost, script, last fired). Context shows what fills the window: the real total, the engine's estimate, a row per category with a bar, and the five heaviest memory files |
| status line | `ctx 42% used · wk 61% · 2 gates · 1 ready · 1 seat · ✉ 1 · 1 decision · idle 12m` |
| wakes | an idle session is woken when a decision-page answer or an unread seat report lands, and, with `mailWake` on, for ipc mail that is still queued or delivered; the wake names the sender and the read command, never the body |

`/hub on` and `/hub off` switch the mod for the current session, and `/hub on` survives a `/clear` in the same terminal. `/hub band` hides or shows the band, `/hub side` opens the side pane, `/hub side <overview|tasks|mcp|plugins|injections|context>` opens or switches its tab, `/hub side off` closes it, and `/hub preset S1|S2|S3` picks the band look. The switches in `/config` are startOn, hygiene, continuity, tasks, fleet, wake and mailWake. The images row follows hygiene.

The tabs are not buttons on purpose: the mods API has no call that hands the keyboard back to the prompt (`$.ui.focus` only moves between the plugin's own elements), and a pressed pane button would keep it. So the tab strip is a dim line that names the command. Three rules hold everywhere: no button carries a hotkey, nothing opens with the keyboard focus, and anything the mod puts in the prompt box is inserted at the cursor, never over a draft. Each has a test that was watched failing.

## Checks

```
/Users/alcatraz627/.local/bin/claude plugin validate ~/.claude/mods/gcc-mods
tsc -p ~/.claude/mods/gcc-mods/tsconfig.json
/Users/alcatraz627/.local/bin/claude plugin test ~/.claude/mods/gcc-mods
```

The shell alias `claude` adds a flag the `plugin` subcommand refuses, so call the binary by path.

## Files stay the truth

The mod reads the goal record through `scripts/goals/views/path.py`, the checkpoint index and `resolve.sh`, `claude-ipc`, and the decision-page registry. For the side pane it also reads the Task tool's files (found with `scripts/task-table/task.sh store`), the enabled plugins from settings, the tail of `ledger/plug-events.jsonl`, and `claude mcp list` (a health check, at most every ten minutes while the pane is open), the server names in `~/.claude.json` and `.mcp.json` (names only, never env or headers), `plugins/installed_plugins.json`, the hook scripts in settings, and `$.session.usage({ breakdown: 'summary' })` for token estimates (MCP tool schemas by server, skill listings by plugin, the context tab's categories and memory files; local, no API call, never `full`). MCP commands and URLs are stripped of userinfo, query strings and key-like words before they are shown. It writes no gcc file. Its only actions are running `/catchup`, submitting a wake or continue prompt, inserting `/core-dump` at the cursor, running `open` on a pasted image you asked for, and one small marker in the plugin's own store so `/hub on` can follow a `/clear`.

Not confirmed on a real terminal yet: the band and pane trees pass the engine's tree validation on the terminal and desktop surfaces, but nobody has looked at them drawn. The MCP list is what a fresh `claude mcp list` sees, because the mods API has no call that lists the session's own servers. The image lookup was seen only with `.png` files under `/private/tmp/claude-<uid>/<project>/<session>/images/`.

The six-tab hub pane, the snippets store, the hook router and the proof receipt were removed on 2026-10-15. Why: `~/.claude/assets/reports/20261015-modular-gcc/report.md` section (b). What changed: `~/.claude/assets/reports/20261015-queue/q-design-mods-trim.md`. The original design record is `~/.claude/assets/reports/20261006-mods-scour/PROPOSAL.md`.
