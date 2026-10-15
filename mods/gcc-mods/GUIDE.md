# gcc-mods guide

Everything the mod draws reads files the shell tools already write. The one pane it can open, `/hub side`, only displays. Nothing needs a key.

## Where things appear

```
┌───────────────────────────────────────────────────────────────────────┐
│ transcript                                                            │
│   paths drawn absolute and clickable                                  │
│   seat landings and peer mail as one line                             │
│   dim line: a Stop hook sent the reply back                           │
├───────────────────────────────────────────────────────────────────────┤
│ band (above the prompt): images row if any, then one offer or nothing │
├───────────────────────────────────────────────────────────────────────┤
│ status line   ctx 42% used · wk 61% · 2 gates · 1 ready · ✉ 1 · idle  │
└───────────────────────────────────────────────────────────────────────┘
```

## Commands

- The mod starts off in every session and draws nothing. `/hub on` turns it on for this session; `/hub off` silences it again. `startOn` in `/config` makes it start on everywhere.
- `/hub on` carries over a `/clear`: the session that follows starts on, once, in the same terminal. A session you turned off, or one that ended any other way, is not carried.
- `/hub band` hides or shows the band. The `✕` at the end of every band row does the same.
- `/hub side` opens the side pane, `/hub side <tab>` switches it (overview, tasks, mcp, plugins, injections), and `/hub side off` closes it.
- `/hub preset S1|S2|S3` changes the band look (below).

## The band

One offer at a time, first match wins, and an empty band when nothing matches. Every offer is one line in the same shape:

```
[kind chip] title · detail · link        [primary] [secondary] ✕
```

The chip carries the kind (decide, resume, continue, context, owed, images) in its own color. The link is a real link that underlines when the pointer is on it, never a bare URL. One button is the main action; the others are plain. `✕` hides the band and turns red under the pointer.

| Row | When | Link | Buttons |
|---|---|---|---|
| decide | a page filed for this folder or this session waits | the page | none |
| resume | after clear, resume or compaction | the checkpoint, opened natively as a file | `load (/catchup)` · `copy path` · `skip` |
| continue | the agent stopped with agent-ready rows open | none | `continue` · `not now` |
| context | the window is past 70 percent used | none | `insert /core-dump` |
| owed | an acceptance row or a gated row waits on you | none | none; `/tasks now` lists them |
| images | the prompt draft holds `[Image #n]` | none | `open` per image · `view` · `copy path` |

The images row sits above whichever offer applies. `open` runs macOS `open` on that image file. `view` opens an unfocused pane with the images larger and their file paths as text; the pane has no buttons. `copy path` copies the image file path (all of them, one per line, when there are several) and toasts. If the image file cannot be found, the row says so and offers no button. The draft is read once a second.

The look is preset S1 by default. S2 puts an accent bar on the left with the link and buttons on a second line, and S3 draws a rounded box. They stay selectable with `/hub preset S2` and `/hub preset S3` for offers that need more room.

## The side pane

`/hub side` opens a pane that only shows things. It has no button and no input, so it does nothing even if you click into it, and it never takes the keyboard when it opens. It docks beside the transcript in fullscreen at 110 columns or more, and sits above the prompt otherwise. A dim strip at the top names the five tabs and marks the current one; switch with `/hub side <tab>`.

The tab strip is not a row of buttons because the mods API has no way to give the keyboard back to the prompt after a press, and a pane that kept the keyboard is how a long prompt gets eaten. The command always works.

- Overview (default): four sections, each at most six lines (heading, up to four items one per line, a pointer to its tab). Over four items, three show and one line folds the rest into a count; things needing attention come first.
- Tasks: id, status, blocked-by and subject for every task of this session, running first, finished last. It refreshes when the agent creates or updates a task and once a minute.
- MCP: name, state, tool-schema tokens (in the window now / all), transport, command or URL, and the config file that declares the server. From `claude mcp list` (on open, at most every ten minutes) plus the server names in the config files. Env values, headers and key-like arguments are never shown; a hidden word reads `<hidden>`.
- Plugins: name, enabled or off, version, an estimate of context tokens (skill listings plus MCP schemas the plugin ships; its agents, commands and hooks are not itemized), marketplace and install path.
- Injections: for this session, per hook: event, count, characters, `~tok` (characters / 4), when it last fired, and the script file (marked `(guess)` when matched from the name only).

Rows are one item each and are cut at the pane width, never shortened with an ellipsis; a wider pane shows more columns. A token column reads `n/a` when the engine gives no context breakdown.

The pane is not read while it is closed.

## Keys and the prompt box

No button has a hotkey. Press one with the mouse, or focus the band with `ctrl+x tab` and use Tab and Enter. This is deliberate: a letter typed while a pane or the band held the keyboard used to fire a button, and one of those wiped a long draft. For the same reason no pane the mod opens takes the keyboard on its own.

The only thing the mod ever puts in the prompt box is `/core-dump`, and it goes in at the cursor, never over what you typed. A slash command runs only from the start of an empty prompt, so with a draft in the box a toast reminds you of that.

## Wakes

While the session is idle, the mod checks once a minute and submits one short prompt when:

- a decision page of this session or folder gets its answer (it names the read command);
- a background seat's report landed more than two minutes ago and nothing has run since;
- ipc mail arrived, only with `mailWake` on, at most once per ten minutes, never quoting the body. Only mail the broker still lists as queued or delivered counts; mail it already put in front of the agent (surfaced) does not wake and does not add to the `✉` count. With an older broker that does not say, only mail that arrived after the mod switched on counts.

## Switches

`/config` rows, machine-wide: startOn (off by default), hygiene, continuity, tasks, fleet, wake, mailWake (off by default).

## If something looks wrong

- The status line shows context as used percent, the same way the statusline does. It says `gcc · nothing waiting` when every count is zero. Counts come from `python3 ~/.claude/scripts/goals/views/path.py --json` in the session's folder.
- After a CLI update: `claude plugin validate`, `tsc`, `claude plugin test` on `~/.claude/mods/gcc-mods` (call the binary by path).
