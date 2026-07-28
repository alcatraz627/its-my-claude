---
brief: Functional (not aesthetic) TUI design patterns + the fzf-as-runtime launcher blueprint, approach-selection (fzf > gum > framework), a graceful-degradation ladder, and the earned ink-dashboard patterns for when the framework tier is justified. For building interactive terminal browsers/launchers/dashboards.
triggers:
  - topic:tui
  - topic:fzf
  - topic:launcher
  - topic:interactive-explorer
  - topic:ink
  - phrase:"interactive explorer"
  - phrase:"fzf"
  - phrase:"command palette"
  - phrase:"terminal UI"
  - phrase:"terminal dashboard"
related:
  - conventions/cli-help-design.md
  - conventions/dashboard-tools.md
  - features/hooks-tui-limits.md
tier: 2
category: conventions
updated: 2026-07-28
stale_after_days: 180
---

# TUI Design — functional patterns for terminal browsers & launchers

How to build an interactive terminal tool that lets a human **browse a list,
preview details, and act** (run / copy / edit / open). Distilled from a survey
of best-in-class TUIs (lazygit, k9s, yazi, atuin, television, navi, fzf). The
focus is **functional** value — what speeds a real task — not aesthetics.

Full research: [`assets/reports/20260619-tui-research/`](../assets/reports/20260619-tui-research/) (`index.md` links three agent reports: UX patterns · launcher/fzf-advanced · implementation approaches).

## Decision: pick the lightest tool that clears the bar

For a list-browse-act tool, **default to `fzf`**, not a framework. In 2026 fzf is
an application runtime driven by `--bind` (`reload`, `become`, `execute`,
`transform`, `change-preview`, multi-select, idle timers). It reaches every
load-bearing capability with **zero new deps and no language boundary**.

```
need multi-pane / mouse click-targets / persistent in-app model?
  NO  → fzf  (browse + preview + act; the 95% case)
  YES → a framework companion (Bubbletea/Go single-binary, or Textual/Python)
        — but that's a rewrite + a build step / per-arch binary. Justify it.
```

- **`gum`** is a *supporting actor*, not the browser: its `input`/`write`/
  `confirm` are best-in-class for the **arg-prompt** and confirmations, but
  `gum filter` has no preview-on-hover and no in-session reload. Use it for
  dialogs and as the first fallback rung — never as the main list.
- **Framework (Bubbletea/Textual/Ratatui/ink)** buys true multi-pane + mouse
  targets + an in-process app model. None are load-bearing for a TSV browser, and
  each breaks "minimal deps / graceful degradation." Reach for it only when the
  tool becomes a persistent multi-pane dashboard — and then follow
  [§ ink-dashboard patterns](#when-the-framework-tier-is-justified-ink-dashboard-patterns)
  below.

**Graceful-degradation ladder** (honor it): `fzf` (full) → `gum filter` +
`gum pager` + `gum input` (degraded) → pure-bash numbered `select` (always
works). Gate color on `[ -t 1 ]`, honor `NO_COLOR`/`TERM=dumb` (see
[`cli-help-design.md`](cli-help-design.md)).

## The load-bearing patterns (ranked for a launcher)

A launcher's job is "find and run one thing, repeatedly" — so its priorities
differ from a file manager's (which ranks multi-select/tree-nav highest).

1. **Incremental fuzzy + structured filter.** Type to narrow; scope the match to
   useful columns (tags/desc), not noise. fzf `--with-nth` (display) + `--nth`
   (match scope) + `--delimiter`.
2. **Live preview of real data.** A side pane that re-renders for the *hovered*
   row (`--preview 'tool {1}'`). Show docs/examples, not decoration. Cycle what
   it shows with `change-preview`; toggle layout with `change-preview-window`.
3. **Run-and-stay-in-the-loop.** `execute(cmd)` runs and returns to the list (the
   exploration loop); `become(cmd)` hands off the terminal for a long/interactive
   command. Distinguish per command. Re-`reload` after a run so recents re-rank
   live.
4. **Contextual per-item actions.** One key per verb — run / copy / edit / docs /
   star — via multiple `--bind`s (or `--expect` dispatch in a wrapper). Mirror
   muscle memory: **enter = run, tab = edit/put-on-line** (atuin).
5. **Frecency + favorites.** Sort by `count × recency` from a side `usage.tsv`
   (`--tiebreak=index` makes the order stick); favorites toggle via
   `execute-silent(toggle)+reload`. State lives **outside** any synced repo.

Amplifiers (add when they pay off): multi-select + `{+}` for batch ops;
which-key/inline help header; `change-prompt` to show the current scope; mouse
scroll (free in fzf).

## fzf-as-runtime vocabulary (the binds that matter)

| Action | Use for |
|---|---|
| `reload(cmd)` | swap the candidate list live (all / favorites / recent / by-tag) |
| `execute(cmd)` | run, **return to the list** (mark, run-and-loop, open pager) |
| `become(cmd)` | replace fzf with a command (clean TTY handoff for interactive/long) |
| `execute-silent(cmd)` | side effect, no screen switch (copy, star, bump counter) |
| `transform(cmd)` | compute the next action string from state (mode toggles) |
| `change-preview` / `change-preview-window` | cycle docs↔source↔man; toggle layout (`ctrl-/`) |
| `change-prompt` / `change-query` | show scope/step; pre-seed or clear input |
| `--multi` + `{+}` | batch actions over selected rows |
| `--expect=k1,k2` | report the accept key → fan out run/copy/dry-run/edit in a wrapper |
| `{q}` `{n}` `{1}` `{2..}` | current query · row index · field-addressed columns |
| chain with `+` | `execute-silent(x)+reload(y)` — side effect then refresh |

Reference example (kubectl browser, from fzf `ADVANCED.md`): `enter:execute`
(stay) + multiple `--bind` action keys + `change-preview-window` cycle + `{1}
{2}` field addressing — every launcher primitive in one command.

## Argument fill (the one fzf rough edge)

fzf has no multi-field form. For "run with args," `become`/`execute` into a small
bash function that prompts **after** the list: `gum input` when present, else
`read -e`. For template commands, parse `<name>` placeholder tokens (navi-style)
and prompt each; pipe suggestion sources through a nested fzf. **Put-on-command-
line requires a shell widget** (zsh `print -z` / `BUFFER`; bash `READLINE_LINE`),
not a plain script — a script can only run, copy, or print.

## Reference implementation

`its-my-config/shell/zcmd/zcmd` → `cmd_explore` (+ `_feed`/`_run`/`_fav`/
`_log_use`): frecency-sorted feed, favorites, run-with-args via `execute`,
contextual action keys, layout toggle, `fzf`-absent → `kit` fallback. State in
`~/.local/state/zcmd/`.

## Anti-patterns

- Reaching for a framework (Go/Rust/Textual) for a list-browse-act tool — a
  rewrite that buys multi-pane features the tool doesn't need.
- A preview pane that shows decoration instead of the data you'd act on.
- `become` when you wanted to keep browsing (use `execute`); `execute` for a
  long-running interactive app (use `become`).
- Storing usage/favorites **inside** a synced config repo (churn + leaks habits).
- Building a category tree when inline fuzzy-matchable **tags** + frecency sort
  do the navigation for free.
- **`--nth=N` to scope search onto a field that carries ANSI color codes** — it
  silently matches *nothing* (the color escapes corrupt field tokenization even
  under `--ansi`). Keep one **clean, un-colored field** as the search target
  (`--nth` it, or just omit `--nth` and let whole-line search hit the hidden
  clean column), and put color only in the **display** field (`--with-nth`).
  Symptom: typing in the picker yields zero results though the list renders fine.

## When the framework tier is justified: ink-dashboard patterns

Earned on the claude-ipc `-i` dashboard build (2026-07: ink + React fullscreen
viewer over a local message broker; design history in that repo's
`docs/notes/`). Every rule below broke something before it became a rule.

**Input**
- **One central dispatcher, strict precedence.** ink `useInput` is *broadcast*,
  not bubbling — every active handler sees every key, so per-widget handlers
  double-fire Esc. Route everything through one dispatcher ordered
  filter-edit → modal → global → view.
- **Replay key-runs per char, functional updates only.** A fast key-run
  coalesces into ONE multi-char input event, and React batches a chunk's events
  into one commit — dispatchers must loop per character AND use functional
  `setState`, or keystrokes silently vanish.
- **Queue refetches via a latest-callback ref.** A refresh requested while a
  fetch is in flight silently misses unless queued; toggles then eat state.

**Process boundaries**
- **`$EDITOR` from a fullscreen app:** unmount the alternate screen (render a
  static fallback), pause every interval, guard in-flight state writes, spawn
  with stdio inherit, remount = full repaint. No suspend API needed.
- **Never build into the deployed artifact from tests** — a compile-gate builds
  to a temp dir; a stray rebuild of the served `dist/` stages unreviewed code
  into the next daemon restart.

**Honesty (generalizes beyond ipc)**
- **A dashboard is a viewer: display never mutates.** Peeks must be invisible —
  no consume, no notify, no heartbeat/register. A monitoring surface that
  repaints state (a tab badge, a read-marker) fights the owner of that state.
- **No fabricated liveness.** Render liveness as the inference it is
  ("live — seen 280s ago"), never as a process claim; unknown renders as
  labeled unknown, not a plausible zero.

**Verifying a TUI**
- **Check the framework's components DIR, not its docs page, before trusting a
  claim** — ink-terminal ships no text-input component; a one-line design
  decision ("in-app textarea") silently implied hand-rolling an editable widget.
- **pty capture is damage-diffed:** unchanged cells never rewrite, so captured
  words glue together and prefixes vanish. Assert on freshly-painted rows or
  force a full-frame oracle (open a modal); compare space-stripped; give every
  test message a distinct timestamp or list order is nondeterministic.
- **PNG renders lie about color:** `freeze` (ANSI→PNG) drops background colors
  and dim tints. Raw ANSI (`tmux capture-pane -e`) or a real terminal is color
  truth; judge color only there.
