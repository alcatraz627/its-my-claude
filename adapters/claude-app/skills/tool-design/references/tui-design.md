# TUI design: terminal browsers, launchers and dashboards

How to build an interactive terminal tool that lets a person **browse a list,
preview details and act** (run, copy, edit, open). Drawn from a survey of
strong TUIs (lazygit, k9s, yazi, atuin, television, navi, fzf). The focus is
functional value, what speeds a real task. Looks come second.

## Pick the lightest tool that clears the bar

For a list-browse-act tool, **default to `fzf`** and skip the framework. fzf is
now an application runtime driven by `--bind` (`reload`, `become`, `execute`,
`transform`, `change-preview`, multi-select, idle timers). It reaches every
capability that matters with no new dependency and no language boundary.

```
need multi-pane, mouse click targets, or a persistent in-app model?
  no  -> fzf  (browse, preview, act: the 95% case)
  yes -> a framework (Bubble Tea in Go, Textual in Python, Ratatui, ink)
         that is a rewrite plus a build step. Justify it.
```

- **`gum`** is a supporting actor, not a browser. Its `input`, `write` and
  `confirm` are excellent for argument prompts and confirmations. `gum filter`
  has no live preview and no in-session reload, so it is never the main list.
- **A framework** buys true multi-pane layouts, mouse targets and an in-process
  model. None of that matters for a list browser, and each breaks minimal
  dependencies and graceful degradation. Reach for one only when the tool
  becomes a persistent multi-pane dashboard, and then follow the framework
  patterns at the end of this file.

**Degradation ladder:** `fzf` (full), then `gum filter` with `gum pager` and
`gum input` (reduced), then a numbered bash `select` (always works). Gate color
on `[ -t 1 ]` and honor `NO_COLOR` and `TERM=dumb`.

## The patterns that matter, ranked for a launcher

A launcher's job is "find and run one thing, again and again", so it ranks
differently from a file manager, which puts multi-select and tree navigation
first.

1. **Incremental fuzzy plus structured filter.** Type to narrow, and scope the
   match to useful columns (tags, description) and away from noise. Use fzf
   `--with-nth` (what shows), `--nth` (what matches) and `--delimiter`.
2. **Live preview of real data.** A side pane re-renders for the hovered row
   (`--preview 'tool show {1}'`). Show docs and examples, not decoration. Cycle
   what it shows with `change-preview`, toggle layout with
   `change-preview-window`.
3. **Run and stay in the loop.** `execute(cmd)` runs and returns to the list.
   `become(cmd)` hands the terminal over for a long or interactive command.
   Choose per command. `reload` after a run so recents re-rank live.
4. **One key per verb.** Run, copy, edit, docs, star, through several `--bind`s
   or `--expect` dispatch in a wrapper. Follow muscle memory: Enter runs, Tab
   edits or puts the command on the line (as atuin does).
5. **Frecency and favorites.** Sort by count times recency from a side
   `usage.tsv` (`--tiebreak=index` keeps the order). Toggle favorites with
   `execute-silent(toggle)+reload`. Keep this state **outside** any synced
   config repo.

Add when they pay off: multi-select with `{+}` for batch actions, an inline
help header, `change-prompt` to show the current scope, mouse scroll (free in
fzf).

## fzf as a runtime: the binds that matter

| Action | Use for |
|---|---|
| `reload(cmd)` | Swap the list live (all, favorites, recent, by tag) |
| `execute(cmd)` | Run, then return to the list |
| `become(cmd)` | Replace fzf with a command, a clean terminal handoff |
| `execute-silent(cmd)` | Side effect with no screen switch (copy, star, count) |
| `transform(cmd)` | Compute the next action from state (mode toggles) |
| `change-preview`, `change-preview-window` | Cycle docs, source and man, toggle layout |
| `change-prompt`, `change-query` | Show the scope or step, pre-fill or clear input |
| `--multi` with `{+}` | Batch actions over selected rows |
| `--expect=k1,k2` | Report the accept key, then dispatch in a wrapper |
| `{q}` `{n}` `{1}` `{2..}` | Current query, row index, field columns |
| chain with `+` | `execute-silent(x)+reload(y)`: act, then refresh |

The kubectl browser in fzf's `ADVANCED.md` holds every launcher primitive in
one command and is worth reading.

## Argument fill, fzf's one rough edge

fzf has no multi-field form. For "run with arguments", `become` or `execute`
into a small function that prompts **after** the list: `gum input` when
present, else `read -e`. For template commands, parse `<name>` placeholders
(as navi does) and prompt for each, feeding suggestions through a nested fzf.
**Putting a command on the shell's line needs a shell widget** (zsh `print -z`
or `BUFFER`, bash `READLINE_LINE`). A plain script can only run, copy or print.

## Anti-patterns

- A framework rewrite for a list-browse-act tool. It buys multi-pane features
  the tool does not need.
- A preview pane showing decoration instead of the data you would act on.
- `become` when you wanted to keep browsing (use `execute`), and `execute` for
  a long interactive app (use `become`).
- Usage counts and favorites stored inside a synced config repo, which churns
  and leaks habits.
- A category tree when fuzzy-matchable tags plus frecency already navigate.
- **`--nth=N` on a field that carries ANSI color codes.** It silently matches
  nothing, because the escapes corrupt field splitting even under `--ansi`.
  Keep one clean, uncolored field as the match target, and put color only in
  the displayed field (`--with-nth`). Symptom: typing gives zero results while
  the list renders fine.

## When the framework tier is justified

These rules came from building a fullscreen ink (React for the terminal)
viewer over a local message broker. Each broke something before it became a
rule.

**Input**
- **One central dispatcher with strict precedence.** ink's `useInput` is
  broadcast and does not bubble, so every active handler sees every key and
  per-widget handlers double-fire Esc. Route all keys through one dispatcher,
  ordered filter edit, modal, global, view.
- **Replay key runs per character, with functional updates.** A fast key run
  arrives as one multi-character event, and React batches a chunk into one
  commit. Loop per character and use functional `setState`, or keystrokes
  vanish.
- **Queue refetches through a latest-callback ref.** A refresh asked for while
  a fetch is in flight is lost unless queued, and toggles then eat state.

**Process boundaries**
- **Opening `$EDITOR` from a fullscreen app:** unmount the alternate screen,
  pause every interval, guard in-flight writes, spawn with inherited stdio,
  then remount for a full repaint.
- **Never build into the deployed output from tests.** Compile checks build to
  a temp dir. A stray rebuild of the served build ships unreviewed code on the
  next restart.

**Honesty**
- **A dashboard is a viewer. Display never mutates.** Peeks are invisible: no
  consume, no notify, no heartbeat. A monitor that repaints someone else's
  state (a badge, a read marker) fights the owner of that state.
- **No fabricated liveness.** Show liveness as the inference it is ("live, seen
  280s ago"), never as a process claim. Unknown shows as labelled unknown,
  never as a plausible zero.

**Verifying a TUI**
- **Check the framework's component directory, not its docs page.** One
  framework shipped no text-input component, so a one-line plan for an in-app
  text area quietly meant hand-building an editable widget.
- **pty capture is damage-diffed.** Unchanged cells never repaint, so captured
  words glue together and prefixes vanish. Assert on freshly painted rows or
  force a full repaint (open a modal), compare with spaces stripped, and give
  every test message a distinct timestamp.
- **PNG renders lie about color.** ANSI-to-PNG tools drop background colors and
  dim tints. Raw ANSI capture (`tmux capture-pane -e`) or a real terminal is
  the color truth.
