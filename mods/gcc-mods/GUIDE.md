# gcc-mods guide

Everything the mod draws reads files the shell tools already write. It opens no pane and needs no key.

## Where things appear

```
┌───────────────────────────────────────────────────────────────────────┐
│ transcript                                                            │
│   paths drawn absolute and clickable                                  │
│   seat landings and peer mail as one line                             │
│   dim line: a Stop hook sent the reply back                           │
├───────────────────────────────────────────────────────────────────────┤
│ band (above the prompt): one row, or nothing                          │
├───────────────────────────────────────────────────────────────────────┤
│ status line   ctx 42% · wk 61% · 2 gates · 1 ready · ✉ 1 · idle 12m   │
└───────────────────────────────────────────────────────────────────────┘
```

## Commands

- The mod starts off in every session and draws nothing. `/hub on` turns it on for this session; `/hub off` silences it again. `startOn` in `/config` makes it start on everywhere.
- `/hub band` hides or shows the band. The band's own `hide band` button does the same.

## The band

One row at a time, first match wins. When nothing matches, the band is empty.

| Row | When | Buttons |
|---|---|---|
| decision page | a page filed for this folder or this session waits | none; the row carries the page's link |
| resume from a checkpoint | after clear, resume or compaction | `load (/catchup)` · `copy path` · `skip` |
| continue | the agent stopped with agent-ready rows open | `continue` · `not now` |
| context past 70% | the window is filling | `insert /core-dump at the cursor` |
| reads owed | an acceptance row or a gated row waits on you | none; `/tasks now` lists them |

## Keys and the prompt box

No button has a single-letter hotkey. Press one with the mouse, or focus the band with `ctrl+x tab` and use Tab and Enter. This is deliberate: a letter typed while a pane or the band held the keyboard used to fire a button, and one of those wiped a long draft.

The only thing the mod ever puts in the prompt box is `/core-dump`, and it goes in at the cursor, never over what you typed. A slash command runs only from the start of an empty prompt, so with a draft in the box a toast reminds you of that.

## Wakes

While the session is idle, the mod checks once a minute and submits one short prompt when:

- a decision page of this session or folder gets its answer (it names the read command);
- a background seat's report landed more than two minutes ago and nothing has run since;
- ipc mail arrived, only with `mailWake` on, at most once per ten minutes, never quoting the body.

## Switches

`/config` rows, machine-wide: startOn (off by default), hygiene, continuity, tasks, fleet, wake, mailWake (off by default).

## If something looks wrong

- The status line says `gcc · nothing waiting` when every count is zero. Counts come from `python3 ~/.claude/scripts/goals/views/path.py --json` in the session's folder.
- After a CLI update: `claude plugin validate`, `tsc`, `claude plugin test` on `~/.claude/mods/gcc-mods` (call the binary by path).
