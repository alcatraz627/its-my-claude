# gcc-mods

The gcc surfaces that help without being opened, drawn inside the Claude Code TUI: clickable absolute paths, a resume offer after a clear, the context gauge in the status line, and wakes for an idle session. `GUIDE.md` beside this file explains each one.

It loads in every session through `CLAUDE_CODE_PLUGIN_DIRS` in the `env` block of `~/.claude/settings.json`, and starts off: a session behaves as if the mod were absent until `/hub on` turns it on for that session. The `startOn` switch in `/config` makes it start on everywhere. The folder is watched, so edits hot-reload. Built against Claude Code 2.1.291 and trimmed on 2.1.299; the mods API is early access, so after a CLI update run the three checks below before trusting it.

## What it draws

| Surface | What you get |
|---|---|
| transcript | paths drawn absolute and clickable with the trailing period outside the link; seat landings and peer mail as one line (ctrl+o for the full row); a dim line when a Stop hook sends the reply back |
| band above the prompt | one row at a time, and nothing when nothing applies: a decision page filed for this folder (with its link), the checkpoint after a clear or resume (load runs `/catchup`), continue when the agent stopped with agent-ready rows open, an insert-`/core-dump` button past 70 percent context, then the reads owed by you |
| status line | `ctx 42% · wk 61% · 2 gates · 1 ready · 1 seat · ✉ 1 · 1 decision · idle 12m` |
| wakes | an idle session is woken when a decision-page answer or an unread seat report lands, and, with `mailWake` on, for ipc mail; the wake names the sender and the read command, never the body |

`/hub on` and `/hub off` switch the mod for the current session; `/hub band` hides or shows the band. The switches in `/config` are startOn, hygiene, continuity, tasks, fleet, wake and mailWake.

Two rules hold everywhere: no button carries a single-letter hotkey, and anything the mod puts in the prompt box is inserted at the cursor, never over a draft. Both have a test that was watched failing.

## Checks

```
/Users/alcatraz627/.local/bin/claude plugin validate ~/.claude/mods/gcc-mods
tsc -p ~/.claude/mods/gcc-mods/tsconfig.json
/Users/alcatraz627/.local/bin/claude plugin test ~/.claude/mods/gcc-mods
```

The shell alias `claude` adds a flag the `plugin` subcommand refuses, so call the binary by path.

## Files stay the truth

The mod reads the goal record through `scripts/goals/views/path.py`, the checkpoint index and `resolve.sh`, `claude-ipc`, and the decision-page registry. It writes nothing; its only actions are running `/catchup`, submitting a wake or continue prompt, and inserting `/core-dump` at the cursor.

The six-tab hub pane, the snippets store, the hook router and the proof receipt were removed on 2026-10-15. Why: `~/.claude/assets/reports/20261015-modular-gcc/report.md` section (b). What changed: `~/.claude/assets/reports/20261015-queue/q-design-mods-trim.md`. The original design record is `~/.claude/assets/reports/20261006-mods-scour/PROPOSAL.md`.
