# hub guide

`/hub help` or `h` in the hub opens this. Everything the mod draws reads the files the shell tools already write; nothing lives only in the mod.

## Where things appear

```
┌──────────────────────────────────────────────┬────────────────────────┐
│ transcript                                   │ hub pane  (/hub)       │
│   paths drawn absolute and clickable         │   1 Docs  2 Tasks      │
│   seat landings and peer mail as one line    │   3 Nudges 4 Fleet     │
│   dim lines: a Stop hook sent the reply back │   5 Inbox 6 Decide     │
│   dim lines: the receipt beside a done-claim │   h guide              │
├──────────────────────────────────────────────┤                        │
│ band (above the prompt)                      │ preview and goal tabs  │
│   one action card, the receipt, count chips  │   open from any tab    │
├──────────────────────────────────────────────┴────────────────────────┤
│ status line   ☀ ctx 42% · wk 61% · 2 gates · 1 seat · ✉ 1 · idle 12m  │
└───────────────────────────────────────────────────────────────────────┘
```

## Commands

- `/hub` opens the hub; `/hub tasks` (or docs, nudges, fleet, inbox, decide) opens a tab.
- `/hub help` opens this guide. `/hub band` hides or shows the band.
- The mod starts off in every session and draws nothing. Any `/hub` turns it on for this session; `/hub off` silences it again (hooks pass through, panes close, status clears). `startOn` in `/config` makes it start on everywhere.

## Keys

- A letter or digit presses a button only while that pane or the band holds the keyboard. The prompt holds it by default: then the letter is typed into the prompt box, which is what the engine does and the mod cannot change.
- The hub takes the keyboard when opened by a command or a chip, or when you click it; the band after `ctrl+x tab` or a click. Esc hands the keyboard back to the prompt. If a letter typed in the prompt vanished, the pane had the keyboard; press Esc first.
- `1` to `7` switch tabs, `h` guide. Tab and arrows walk, Enter presses, `ctrl+x x` closes a pane.
- Everything the mod puts in the prompt box is inserted at the cursor, never replacing what you typed. A slash command (`/goal`, `/core-dump`, `/atone` and the other skills) only runs from the start of an empty prompt, so with a draft in the box it goes to the clipboard instead and a toast says so.
- A `gcc-goal:`, `snip-note` or `dp-note` line is one line of its own. Enter saves that line and sends nothing; every other line you had in the box comes back. If it names a snippet or decision that does not exist, or cannot be saved, nothing is saved or sent and your whole text comes back.
- Preview and goal open in place of the hub; `b` goes back to it.
- In a text field every key types. Enter saves to gcc and sends nothing.

## The band

One action card at a time, first match wins:

| Card | When | Buttons |
|---|---|---|
| decision page | a page filed for this agent waits | `e` decide |
| resume from a checkpoint | after clear, resume or compaction | `l` runs /catchup · `v` view · `s` skip |
| continue | agent stopped with agent-ready rows open | `c` continue · `x` not now |
| context past 70% | the window is filling | `u` puts /core-dump in the prompt box, nothing sent |
| read owed | an acceptance row waits on you | `o` review |

Then the receipt (after a done-claim) and count chips; each chip opens its tab.

## Tabs

**Docs (1).** Files this session wrote, plus checkpoints, session notes and recent reports. `f` filter · `j` `k` move · `r` rescan · `p` preview · `e` expand here · `o` open · `c` copy path · `q` attach `@path` · `b` bookmark · `x` hide · `u` unhide.

**Tasks (2).** The goal record, the same views as `/tasks`.
- Goal: `e` or `v` opens the goal tab · `p` paste the /goal line · `w` retire the session goal · `g` next goal · `r` refresh.
- Waiting on you: `y` answers (`gs prove`) · `n` say why (your words become an acceptance row).
- Rows: `d` show or fold done rows.

**Goal tab.** The outcome on the record, the session goal, the acceptance rows. `e` edits the session goal in a field (Enter saves, `x` cancels) · `l` edits it in the prompt box, where Enter saves and sends nothing · `p` paste the /goal line.

**Nudges (3).** What fired this session. Select, then `t` text · `w` why · `s` snooze (your press is the owner approval) · `f` feedback · `p` preview.

**Fleet (4).** Seats running and landed, output file checked. `c` copy output path · `q` attach · `o` open · `p` preview.

**Inbox (5).** This project's ipc mail, read without consuming. `y` reply · `i` quote into prompt · `m` toggle read · `p` preview. Mail wake is off by default (`mailWake` in `/config`).

**Snips (7).** Selections you kept, with a title, notes and tags, plus bookmarked docs. Select text with the mouse (fullscreen terminal or desktop), then `s` here or `/hub snip` from the prompt. Scope is session, project or global, stored as jsonl under `~/.claude/snippets/`, so any session sees the same lists. Per snippet: `t` title · `n` notes · `e` tags · `l` notes in the prompt box (Enter saves, sends nothing) · `o` cycle scope · `p` preview · `q` quote · `c` copy · `x` delete · send to a skill with `d` pin-for-dream, `g` gcc-proposal, `a` atone, `f` affirm (the command lands in the prompt box for editing). From the prompt, `/hub pin`, `/hub propose`, `/hub atone`, `/hub affirm` do the same with the current selection. `b` on a doc in the Docs tab bookmarks it.

**Decide (6).** Pages filed for this folder or by this session, drafted picks preselected. Pick with the id button, flip the select, note on one line or `l` for a `dp-note` line in the prompt box. `s` submit · `c` copy the answer string · `x` dismiss · `o` show other agents' pages.

## Reads and writes

| Tab | Reads | Writes through |
|---|---|---|
| Tasks | path view, goal record | gs prove, gs accept, goal.sh |
| Docs | Write/Edit calls, checkpoints, notes, reports | nothing |
| Nudges | hook attachments, warn ledger | hook-snooze, hook-feedback |
| Fleet | Agent calls, seat turn ends | nothing |
| Inbox | claude-ipc inbox | claude-ipc reply |
| Decide | decision-pages pending and configs | dp-submit route or .answer.json |

## Switches

`/config` rows, machine-wide: startOn (off by default), hygiene, continuity, tasks, tasksWrite, fleet, wake, mailWake, router, nudges, decide, receipt, fun, sound. On by default except startOn, mailWake and sound.

## If something looks wrong

- A dim transcript line naming `gcc-mods` says which hook failed and why.
- `views:` in red on the Tasks tab: run `python3 ~/.claude/scripts/goals/views/path.py` in the folder.
- After a CLI update: `claude plugin validate`, `tsc`, `claude plugin test` on `~/.claude/mods/gcc-mods` (call the binary by path).
- Hook authors: `features/gcc-mods.md` explains the owner tag.
