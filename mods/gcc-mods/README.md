# gcc-mods

gcc's owner surfaces drawn inside the Claude Code TUI, so what waits on you, what is running, and what the agent actually exercised no longer travel through the model's reply.

The owner's guide, every surface and key explained, is `GUIDE.md` beside this file; `/hub help` or `h` in the hub opens it in the preview pane.

Loads in every session through `CLAUDE_CODE_PLUGIN_DIRS` in the `env` block of `~/.claude/settings.json`, and starts off: a session behaves as if the mod were absent until `/hub` turns it on for that session. The `startOn` switch in `/config` makes it start on everywhere. The folder is watched, so edits hot-reload. Built against Claude Code 2.1.291; the mods API is early access, so after a CLI update run the three checks below before trusting it.

## What it draws

| Surface | What you get |
|---|---|
| `/hub` pane, six tabs | Docs (files this session wrote, preview, copy path, attach, open), Tasks (the goal record at real width, gates first, answers or say why through `gs`), Nudges (what fired, why, snooze, feedback), Fleet (seats, landing, output file check), Inbox (ipc mail, reply, quote), Decide (pending decision pages with drafted picks, submit) |
| `/hub tasks`, `/hub help`, `/hub band`, `/hub off` and `/hub on` | the Tasks tab, this guide, the band toggle, and the per-session switch |
| band above the prompt | one action row at a time: a decision page for this project, the checkpoint after a clear or resume (load fills `/catchup`), continue when the agent stopped with agent-ready rows open, a core-dump button past 70 percent context, then the owed read; the proof receipt beside a done-claim; count chips |
| status line | `ctx 42% · wk 61% · 2 gates · 1 seat · ✉ 1` |
| transcript | paths drawn absolute and clickable with the trailing period outside the link; seat landings and peer mail as one line (ctrl+o for the full row); a dim line when a Stop hook sends the reply back |
| wakes | an idle session is woken when ipc mail, a decision-page answer, or an unread seat report lands; the wake names the sender and the read command, never the body |
| fun | a spinner word that fits the moment, a turn footer with the tool count, a greeting with what waits, landing phrases, a toast when every acceptance row is proven |

Any `/hub` turns the mod on for the current session; `/hub off` silences it again (every hook passes through, panes close, status clears). Every cluster is also a machine-wide switch in `/config` (startOn, hygiene, continuity, tasks, tasksWrite, fleet, wake, mailWake, router, nudges, decide, receipt, fun, sound). Turn one off rather than argue with it.

## The router

A settings hook marks owner-facing text with `hook_owner_wrap` (in `scripts/hooks/hook-common.sh`):

```
<owner surface="toast|log|band|pane:nudges|pane:tasks|ask" hook="<script>" model="…">…</owner>
```

This mod draws the block on that surface and removes it from what the model reads, handing the model the `model` text instead when one is given. Without the mod (Codex, `claude -p`) the tag is plain text and the old paste-verbatim behaviour stands; the Codex adapter unwraps it in `gcc_ctx_of`. Adopters today: `subagent-box.sh` and `task-table-inject.sh`.

## Checks

```
/Users/alcatraz627/.local/bin/claude plugin validate ~/.claude/mods/gcc-mods
tsc -p <a tsconfig that includes the engine's types, see the header of .claude-plugin/types/claude-code/index.d.ts once laid>
/Users/alcatraz627/.local/bin/claude plugin test ~/.claude/mods/gcc-mods
```

The shell alias `claude` adds a flag the `plugin` subcommand refuses, so call the binary by path.

## Files stay the truth

The mod reads `gs` and the `/tasks` views, the checkpoint index, `claude-ipc`, the warn ledger and the decision pages. It writes only through their own CLIs (`gs prove`, `gs accept`, `hook-snooze.sh`, `hook-feedback.sh`, `claude-ipc reply`, the decision-page submit route). Nothing lives only in `$.state`.

Design record: `~/.claude/assets/reports/20261006-mods-scour/PROPOSAL.md` and the four evidence files beside it.
