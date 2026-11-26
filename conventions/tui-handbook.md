---
brief: How to build a terminal UI in this environment: the std::claude::tui library, the fzf-app blueprint, the bug-free patterns, and the traps that break TUIs here.
triggers:
  - topic:gum
  - phrase:"build a tui"
  - phrase:"terminal ui"
  - phrase:"fzf picker"
  - tool:tui/colors.sh
  - tool:tui/pick.sh
  - tool:tui/tty.sh
  - tool:tui/smoke.sh
  - tool:tui/tuikit.py
  - phrase:"settings screen"
  - phrase:"confirm dialog"
  - phrase:"blank pane"
  - phrase:"blank screen"
related:
  - conventions/tui-design.md
  - conventions/cli-help-design.md
  - conventions/visual-design.md
  - features/hooks-tui-limits.md
  - skills/shared/bash-gotchas.md
tier: 2
category: conventions
updated: 2026-11-10
stale_after_days: 180
---

# TUI handbook: building terminal UIs in this environment

The practical guide to building a TUI here: which engine to reach for, the
copy-paste blueprint, the reusable modules, the patterns worth stealing, and the
traps that break terminal UIs *on this machine specifically*. It **routes** to the
existing conventions rather than restating them. Read those for depth, and read this for
the build.

## §0 · Orientation: fzf is the runtime

```
 std::claude::tui
   INPUT side  (scripts/tui/)          DISPLAY side (skills/shared/)
   colors.sh  tty.sh  require.sh        gum-tui.sh  (gum_* output wrappers)
   pick.sh    file-preview.sh
   SCREEN side (scripts/tui/)           CHECK side (scripts/tui/)
   tuikit.py  (box, legend, pane rules) smoke.sh  (blank-screen check)
   ───────────────────────────────      ────────────────────────────────
   PATTERN side (this handbook): the --__ fzf-app blueprint · the
   list-and-preview screen (§11) · destructive guards · the testing seams.
```

The single most important fact: **fzf already is a TUI runtime.** Build on
fzf and gum and you inherit alternate-screen handling, termios save/restore, Ctrl-C
recovery, cursor management, and resize *for free*. So the library is deliberately
small. It extracts the duplicated *correctness* (color gating, tty probing,
degradation, dep preflight), and the handbook owns the load-bearing *pattern* (the
`--__` self-re-exec blueprint). Don't hand-roll a screen unless you've proven you
must (you almost never must, see [`tui-design.md`](tui-design.md)).

## §1 · Which engine: a pointer, not a restatement

The fzf-vs-gum-vs-framework decision tree and the "pick the lightest tool"
reasoning already live in [`conventions/tui-design.md`](tui-design.md) (§ decision and
§ fzf-as-runtime). One-line summary so you don't have to leave:

> **fzf** = the interactive loop (a list you browse, filter, preview and act on). **gum**
> = the moments around it (confirm, input, a small styled choose) and all
> non-interactive rendering. **read** (via `tui_read_tty`) = the last-resort prompt.
> Launch gum *from* an fzf `execute()` bind and never nest gum *inside* fzf (it
> blanks the screen; see §4 A3).

`tui/pick.sh` walks all three rungs for you. Hand-roll fzf directly only
when you need preview, reload or binds the helper can't express.

## §2 · Golden-path skeleton: the `--__` fzf-app

The canonical pattern: the tool re-execs *itself* for fzf's feed, preview and action
callbacks, exposed as hidden `--__` subcommands. This keeps the callbacks pure,
out of `-h` and completions, and **headless-testable** (§5).

```bash
#!/usr/bin/env bash
set -euo pipefail
# SELF must be overridable for tests, and ALWAYS %q-quoted into fzf bind strings:
# an unquoted path word-splits under sh -c and breaks on a space in the install dir.
SELF="${MYTOOL_SELF:-$(command -v mytool || printf '%s' "$0")}"
source "$HOME/.claude/scripts/tui/colors.sh"; tui_colors_init
source "$HOME/.claude/scripts/tui/tty.sh"
source "$HOME/.claude/scripts/tui/require.sh"

feed()    { ls -1; }                               # define the callbacks BEFORE the
preview() { "$HOME/.claude/scripts/tui/file-preview.sh" "$1"; }   # dispatch case, or the
act()     { : "do the thing with $1"; }            # re-exec dies "feed: command not found"

case "${1:-}" in                                   # hidden callbacks, dispatched FIRST
  --__feed)    shift; feed "$@";    exit 0 ;;
  --__preview) shift; preview "$@"; exit 0 ;;
  --__act)     shift; act "$@";     exit 0 ;;
esac

main() {
  tui_have fzf && [ -t 1 ] && [ -t 0 ] || { "$SELF" --__feed; exit 0; }  # degrade BEFORE fzf
  "$SELF" --__feed >/dev/null || { echo "mytool could not start" >&2; exit 1; }  # no blank frame (A11)
  local q; q="$(printf '%q' "$SELF")"              # the load-bearing quote
  "$SELF" --__feed | fzf --ansi --height=80% --reverse \
    --preview "$q --__preview {1}" \
    --bind "ctrl-r:reload($q --__feed)" \
    --bind "ctrl-x:execute-silent($q --__act {1})+reload($q --__feed)"
}
main "$@"
```

Three rules are embedded (each links to its failure-mode row and is not re-explained):
`printf '%q'` self-quoting (A4); `execute-silent` = fire-and-forget, `execute` =
inline interactive, `become` = full-screen handoff (A3); and degrade *before*
invoking fzf, never inside it.

## §3 · Features catalog: what, when, how-bug-free

| # | Feature | When | How (and the trap it avoids) |
|---|---------|------|------------------------------|
| F1 | In-list act + reload (`execute+reload`) | mutate then reflect (kill, toggle, star) | `execute-silent` for non-interactive mutation; `execute` only if it writes inline; `become` if full-screen. Wrong choice → **blank pane (A3)**. Re-quote the row via a `--__act {1}` callback, never an inline `{}` (A4). |
| F2 | `reload` / `change:reload` | refresh stale data; front a huge/DB corpus | Debounce `change:reload` (`sleep 0.1`) or you fork per keystroke. Never put a network/stdin-reading command in the source (**wedges the picker, B4**). |
| F3 | Type-dispatched preview | a list of mixed item kinds | Delegate to `file-preview.sh`, which is bounded and **always exits 0**; a preview that errors or stalls breaks the host. Size-gate big files. |
| F4 | `?`-help overlay + persistent header | every interactive tool | Render the header via a `--__iheader` callback so it's **assertable headless** (§5). Don't end a header line on a bare `path.ext.` because Ghostty eats the trailing dot into the link (A5). |
| F5 | One palette via env | always | `FZF_DEFAULT_OPTS` + `GUM_*` env, set once. Don't double-color (gum styling + embedded ANSI). Gate all color via `colors.sh` so it never leaks into a pipe (A8). |
| F6 | Command-palette / verb router | a tool with many verbs | `fzf --prompt ':' --bind 'enter:become(dispatch {})'`. Use `become` (not `execute`) so the verb owns a clean terminal (A3). Never auto-run on hover; require Enter. |
| F7 | Two-axis filter (scope × match) | big lists | Cycle *scope* via `reload` with a source flag, and advertise fzf's `'exact` `^prefix` `suffix$` `!negate` in the header. `--nth` must point at a **clean uncolored field**, because `--nth` onto ANSI matches zero (A7). |
| F9 | Question in a floating box | confirm a save, a drop, a quit with unsaved work | `key:transform(self --__flow step)`. The callback draws `tuikit.dialog` over the live screen, acts on the key, and prints the next fzf actions (`clear-screen+reload(...)`, or `abort`). No screen switch. Single keys need `tuikit.read_key` (A13). |
| F10 | Headings in the list | more than about eight rows | Emit heading rows with a key that is no item (`group:name`) and make every action ignore that prefix. Start the cursor on row 2. |
| F11 | Fixed-shape preview pane | any pane a person compares across rows | `tuikit.title`, then the SAME three labelled lines for every row, then `tuikit.section` dividers. A line that appears only sometimes makes rows impossible to compare, so show it always and dim it when it says nothing. |
| F12 | Key legend footer | every screen | `--footer "$(tuikit.py legend ...)"`: aligned cells, green keeps, amber drops or undoes, cyan the rest. Three cells per row fits the list column. |
| F13 | Try on move, undo on escape | choosing a value with a visible effect | In the value picker: `focus:execute-silent(self --__try KEY {1})+refresh-preview`, `start:pos(current)` so opening changes nothing, and on abort re-apply the value that was showing. Trying is never saving. |
| F14 | Keep the place across `become` | a row opens another full screen and returns | Return with `exec self --at KEY` and `start:pos(index of KEY)`. A list that reopens at the top after every edit reads as broken. |
| F15 | Drawn preview of what text cannot show | a setting whose effect is outside the terminal's text (an icon, a title bar, a screen edge) | A small "what it changes" section: half-block pixels for an image (`sips` to BMP, two pixels per cell), box-drawing for a window. Best effort: draw nothing when it cannot be drawn. |
| F8 | In-list option toggles (live header) | adjustable options mid-browse | `execute-silent(mutate statefile)+reload(feed)+transform-header(header)` gives no modal and no flicker. Keep state in a `mktemp` arg (not a global) so callbacks are pure and headless-testable. Clean the temp in an EXIT trap. (zconvert `-i` ^O/^T.) |

## §4 · Failure-mode catalog: the traps that break TUIs here

The canonical home for "what breaks a TUI on this machine." Tier A is
account and macOS specific (the ones that actually bit), and Tier B is general.

| # | Trap | Symptom | Fix |
|---|------|---------|-----|
| A1 | `cat` is aliased to `glow`; other aliases leak | corrupted captured output, garbled test scaffolding | In any script use `command cat` / `head` / `printf` / `$(<file)`; resolve tools with `command -v`, never an alias. (→ [`bash-gotchas.md`](../skills/shared/bash-gotchas.md)) |
| A2 | bash 3.2 is what `#!/usr/bin/env bash` resolves to | `read -i`, `${v,,}`, `declare -A`, `mapfile` silently absent or error | No bash-4 features. For `read -i` prefill, show a `[default]` and accept Enter. (→ bash-gotchas.md) |
| A3 | alt-screen program (`gum`, nested `fzf`) inside `fzf execute(...)` | host screen blanks / garbles | `execute-silent` for non-interactive actions; for an interactive moment use `/dev/tty` `read` prompts or `become`, not a nested full-screen TUI. |
| A4 | unquoted `$SELF`/path in an fzf bind string | bind silently fails (`sh -c` word-splits on a space in the path) | `printf '%q'` the self-path; single-quote vars embedded in `--bind`/`--preview`. |
| A5 | a file path ending a line, then `.` | Ghostty swallows the dot into the link; path stops being clickable | Never end a line on `path.ext.`; follow with a space or word. (Stop-hook enforced.) |
| A6 | a prompt written to stdout instead of `/dev/tty` | the prompt text pollutes captured/piped output | Write prompts to `/dev/tty` (`tui_read_tty` does); keep stdout = the chosen value only. |
| A7 | `--nth` pointed at an ANSI-colored field | fuzzy match returns zero results | Color only the `--with-nth` display field; keep the `--nth` match field uncolored. |
| A8 | color gated on `-t 1` only | raw escapes leak into a redirected stderr (`2>log`) or a pager | Gate on **both** fds (`-t 1 && -t 2`); `colors.sh` does this. |
| A9 | `[ -r /dev/tty ]` as the interactivity test | `read </dev/tty` hangs/errors with no controlling terminal | Probe by *opening* it with `tui_have_tty` (subshell `exec 3</dev/tty`). |
| A10 | a helper file located with `dirname "$0"` | works from the source folder; once installed as a link on PATH, every callback fails and the screen opens blank | Follow the link before taking the folder (a `readlink` loop, or `cd -P`). Test by starting the tool through a link in another folder. |
| A11 | a feed, header or preview callback that fails | fzf draws an empty frame and says nothing: the list is empty because the command behind it died | Run the feed once BEFORE opening fzf, and print its error and exit 1 when it fails or prints nothing. Callbacks exit with their real status, never a blanket `exit 0`, and the script sets `pipefail`. |
| A12 | header or row text wider than the list column | fzf cuts it with `··`, and the cut part is usually the instruction | With a side preview the list is the narrow column. Keep header lines and rows under about 55 characters, or split the header over two lines. |
| A13 | reading one key inside `transform` or `execute-silent` | the box draws, the key is echoed and nothing happens until enter | fzf puts the terminal back in line mode a moment after starting the command. Poll and re-set one-key mode while waiting: `tuikit.read_key` does this. |
| A14 | a screen offers an action its current state cannot deliver | "changes as you go" while nothing is connected; the owner tries values and sees no effect | Check the precondition before opening the screen that depends on it, ask in a box, and refuse plainly when declined. Never rely on a status line to carry it. |
| A15 | `load:` used for a once-only action | the action repeats after every `reload`, and can loop | Use `start:` for anything that must run once. |
| A16 | `$(tput cols)` for the window size | answers 80 whatever the window is, because its output is captured | `stty size </dev/tty`, with `tput` only as the fallback when there is no terminal. |
| A17 | a message printed just before the screen redraws | the owner never sees it; an error looks like nothing happened | Put outcomes in a box (`tuikit.notice`) or the header. For plain prompts, wait for a key before returning. |
| A18 | the same helper written into each tool | two tools, two legends, two dividers, drifting apart | If it draws part of a screen, it belongs in `tuikit.py`. Import it; do not copy it. |
| B1 | TTY left raw after a crash mid-prompt | terminal unusable after the tool dies | fzf/gum restore on their own; for a hand-rolled `read` after gum, `stty sane` on the way out. |
| B2 | no `SIGWINCH` redraw in a hand-rolled screen | layout corrupts on resize | Don't hand-roll, since fzf/gum handle resize. If you must, trap `WINCH` and redraw. |
| B3 | color leaking into a pipe | escapes in captured output | Always gate via `colors.sh`; honor `NO_COLOR`. |
| B4 | unbounded / slow / stdin-reading preview command | picker stalls or wedges per row | Bound the preview (`head`/`--line-range`), size-gate, and never read stdin or the network in a preview. |

(→ The macOS `find /tmp` symlink no-descent trap and the `perl` process-group timeout
gotcha live in [`bash-gotchas.md`](../skills/shared/bash-gotchas.md), and the hook
output-channel ceiling lives in [`hooks-tui-limits.md`](../features/hooks-tui-limits.md).)

## §5 · Testing a TUI without a live terminal

You cannot drive fzf/gum's rendering headless, but you can verify almost
everything *underneath* it. Decompose so the picker only *gathers and delegates*,
then test the parts:

1. **Hidden `--__` subcommands** are plain functions of explicit args. Call them
   directly and assert output (`mytool --__feed`, `mytool --__iheader statefile`).
2. **`fzf --filter=QUERY`** runs the matcher non-interactively. Assert "this query
   finds that row" and that a typed path passes through (`--print-query`).
3. **A `$SELF` re-exec stub** (`MYTOOL_SELF=/path/to/stub`) asserts the tool invokes
   the core with the right args, and that cancel invokes *nothing*.
4. **`read` prompts** become testable by reading from an env-overridable source
   (`${MYTOOL_IN:-/dev/tty}`) so a test pipes via `/dev/stdin`.
5. For the genuinely live-only surface (the rendered pane, a gum widget), drive a
   real pty with `python3 -c 'import pty; ...'` (reliable), because `script` stdin-forwarding
   is flaky. What you still can't prove, mark `UNCONFIRMED` and smoke-test by hand.

This is the [`exercise-based-verification`](../rules/exercise-based-verification.md)
rule applied to TUIs: "looks right" is not "ran it."

### The blank-screen check: run it before calling any TUI done

A TUI that opens as an empty frame is the most repeated defect in tools built here. It has
one shape: a callback fails, fzf has nothing to draw, and no error reaches the screen. It
passes every headless test above, because those call the callbacks from the source folder
with the builder's own paths. The owner starts the tool by the name on PATH.

```bash
bash ~/.claude/scripts/tui/smoke.sh --expect "a word on the main screen" -- mytool
bash ~/.claude/scripts/tui/smoke.sh --keys "j Enter" --expect "a word on the next screen" -- mytool
bash ~/.claude/scripts/tui/smoke.sh --keys "s" --keys "y" --expect "saved" -- mytool   # one --keys per step
```

`smoke.sh` starts the command in a real terminal, reads the screen back, prints it, and
exits 1 when the screen is blank, shows a startup error, or closed by itself. It refuses a
path, since the name on PATH is the thing under test.

A TUI is not done until all five hold:

1. `smoke.sh` passes for the main screen, started by its installed name.
2. `smoke.sh --keys` passes for every screen a key opens (a picker, a history, a prompt).
3. Breaking the tool on purpose (point its helper at a missing file) gives a plain error
   and a failed check, never an empty frame. This proves trap A11 is closed.
4. The printed screen was read: nothing cut with `··`, and every key in the legend is there.

5. `python3 ~/.claude/scripts/tui/lint.py <the tool's files>` prints no findings, or each
   one left is explained.

The check reads text, so colour stays unverified. Say so, or look at a screenshot.

Enforced: `scripts/hooks/tui-smoke-stop.py` (a Stop gate in `stop-gates.txt`) holds a reply
that calls a changed screen done when no `tui/smoke.sh` run followed the last edit. It blocks
once, then only notes. Saying the smoke check was not run passes. Mute:
`touch ~/.claude/.no-tui-smoke-gate` . Open work on the kit: `~/.claude/scripts/tui/TODO.md` .

Lived case, 2026-11-10: `zterminal look` passed 14 tests and a full tmux walkthrough, all run
by its source path. Installed, it was a link in `~/.local/bin`, the helper was looked for
beside the link, and the owner got an empty frame on first use.

## §6 · Degradation ladder: pointer and module map

The ladder itself is documented in [`tui-design.md`](tui-design.md) (§ graceful
degradation). Mapping to the library:

```
fzf (full: search+preview+binds)  → tui_pick_one  (tty + fzf)
gum filter / choose (degraded)    → tui_pick_one  (tty + gum)
numbered read menu (always works) → tui_pick_one  (tty, no fzf/gum)
non-tty plain-text                → tui_pick_one --non-tty fail|first|passthrough
```

Two hard boundaries (do not fake them in fzf): **live-updating meters/gauges** and
**true multi-panel layouts** are out of scope. Use tmux panes or climb to
[`dashboard-tools.md`](dashboard-tools.md).

## §7 · Destructive-tool rules (kill / delete / overwrite)

Non-negotiable for any tool that ends a process or removes or overwrites data:

- **Mass-kill guard:** never `kill -<pgid>` with pgid ≤ 1 (0 = your own group and
  the terminal, 1 = every process you own). `zap` is the reference (`group_pgid`
  refuses ≤ 1).
- **PATH front-load:** a tool that shells out to `ps`/`lsof`/`pgrep` must
  `export PATH=/bin:/usr/bin:/sbin:/usr/sbin:$PATH` first, or a shadowing stub
  returns nothing and the tool silently does the wrong thing.
- **Refuse same source==dest** (overwrite-in-place that destroys input).
- **Confirm before the act** via `tui_confirm`, which returns NO on a non-tty
  (never auto-yes headless).
- **Expose the destructive core as a `--__` subcommand** so it's exercisable
  without the TUI.

## §8 · Theme and keymap: pointer

Color tiers (OKLCH), truncation, and the ≤78-col rule live in
[`visual-design.md`](visual-design.md), and the help-text dialect lives in
[`cli-help-design.md`](cli-help-design.md). The only convention to set here is one
shared look via `FZF_DEFAULT_OPTS` + `GUM_*_FOREGROUND` in your shell profile, plus
the keymap convention: vim `hjkl`, `/` filter, `q`/esc quit, **lowercase = safe,
UPPER/ctrl = destructive**, `?` = help.

## §9 · Library reference: `scripts/tui/`

| Module | Use | Contract |
|--------|-----|----------|
| `colors.sh` | `source` + `tui_colors_init` | TTY-gated palette; exports both `B/R` and `BLD/RST` dialects; empty strings when not a terminal (both-fd gate). |
| `tty.sh` | `source` | `tui_have_tty` (honest open-probe); `tui_read_tty [-t N] [-p P] VAR` (bounded, never hangs headless). |
| `require.sh` | `source` | `tui_have DEP` (boolean); `tui_require DEP...` (install hint to stderr, returns 1, does not exit). |
| `pick.sh` | `source` | `tui_pick_one` (one from stdin, fzf→gum→read); `tui_pick_many` (multi); `tui_choose OPT...` (static arg list); `tui_confirm PROMPT` (yes=0, no/headless=1). **Enriched (§10):** `tui_pick_key` (colored `key⇥display` in, clean key out); `tui_pick_or_add` (seeded suggestions + accept a typed-new value); `tui_strip_ansi` (filter). |
| `file-preview.sh` | `exec` (`bash .../file-preview.sh F`) | rich bounded preview (jq/bat/xlsx-sheets→head), always exits 0. **Deliberate exception to the §4-A8 color gate: color is forced ON**, because a preview pane always wants ANSI. |

| `tuikit.py` | `import tuikit` in Python, or `python3 .../tuikit.py dialog\|legend\|title\|section` from a shell | the drawn parts of a list-and-preview screen: `dialog`/`notice` (box over the live screen), `read_key`, `legend`, `choice`, `title`, `section` (§11). Always writes ANSI. |
| `new-screen.sh` | `exec` (`bash .../new-screen.sh NAME [FOLDER]`) | writes a working list-and-preview tool (§11): the tool, its helper and its tests. Start here; do not hand-build a screen. |
| `lint.py` | `exec` (`python3 .../lint.py FILE...` or `--scan DIR`) | reads a tool's source for the traps in §4 and exits 1 on any finding. A finding is a place to look, not proof of a fault. |
| `smoke.sh` | `exec` (`bash .../smoke.sh [--keys K] [--expect T] -- tool`) | opens the tool by its installed name in a real terminal and exits 1 on a blank or errored screen (§5). Needs tmux. |

**Discover live:** `bash ~/.claude/scripts/tui/list.sh` prints this catalog scanned straight from the modules' doc-headers, so it can't drift from the code the way a hand-kept list does. Run it before building a TUI to see what's already available.

> **`set -e` note:** all five are sourced libraries. Under `set -euo pipefail`,
> guard any call that can return non-zero: `tui_require x || handle`,
> `if tui_have_tty; then act; fi`, `tui_read_tty v || v=default`. A bare non-zero return
> aborts a `set -e` caller (standard bash). The functions return status precisely
> so you branch on it.

## §10 · Enriched pickers: the interactive-CLI standard

The default for any interactive selector a HUMAN drives (a `-i` mode, a wizard, a
chooser). Three shared `pick.sh` primitives give a colored, arrow-navigable,
suggest-don't-restrict picker whose selection still parses cleanly, while the
both-fd color gate keeps the same tool's piped and agent calls plain automatically.

**The three moves:**

1. **Colored list, clean value: `tui_pick_key`.** Emit candidates as
   `key<TAB>display`, where `display` may carry ANSI color. fzf renders the color
   (`--ansi`), searches only the display, hides the key column, and you get the
   **clean key** back, with no ANSI to strip and no `awk`-slicing a colored token. This is THE
   idiom for a colored menu or list.
   ```bash
   key=$(printf '%s\t%sshow%s - run it\n' show "$CYN" "$RST" | tui_pick_key --prompt 'action > ')  # -> "show"
   ```
   The preview `{}` is the whole line, so slice the key with `cut -f1`:
   `--preview 'echo {} | cut -f1 | xargs mytool show'`.

2. **Suggest without restricting: `tui_pick_or_add`.** Seed the existing options
   (paths, names) but let the user type a brand-new value. The typed query is
   returned when nothing matches (fzf `--print-query`). Use it for any "pick one of
   these OR enter your own" selector, and never a blind `read` when candidates exist.

3. **Arrow-nav + enter is the default.** fzf already gives ↑↓ to move, type to
   filter, enter to open, and esc/ctrl-c to leave, identically on every screen. Don't
   hand-roll navigation. Use the pickers and it's uniform for free.

**Keep it agent-safe and testable** (the other half of the standard):
- Colors come from `colors.sh` (both-fd gate), so the tool's piped or headless call is
  plain, and a colored picker never leaks ANSI into an agent's capture.
- Build the mode as a **thin tty layer over pure functions**: candidate
  generators (`key<TAB>display`), an action router keyed on the clean key, and an
  arg-composer. Then the logic is unit-tested headless (§5) while only the fzf
  keystroke drive needs a terminal. Gate the whole mode on `tui_have_tty` with a
  clean refusal that points at the text subcommands.

**Reference implementation:** `gcc-schedule -i` (`scripts/schedule/schedule.sh`,
the `_i_*` functions) and its criteria harness `scripts/schedule/test-interactive.sh`
(A: agent-plain · C: feature coverage · E: enriched-picker contracts).

## §11 · The list-and-preview screen: one shape for every tool

A screen that lists things on the left and shows the highlighted one on the right is the
default shape for a tool with more than a few settings or items. Build every one the same
way, so the owner learns it once. Reference implementations: `zterminal look` and
`zterminal banner` (`~/Code/Claude/its-my-config/shell/zcmd/tools/zterminal`,
`zterminal-look.py`; `~/Code/Claude/banner-fun/home_variants.py` `feed` and `pane`).

```
 one line of state, under 55 characters      │ name of the highlighted row
 GROUP HEADING                               │ ──────────────────────────────
   row           value          not saved    │ label     value      (always
   row           value                       │ label     value       these
 GROUP HEADING                               │ label     value       three)
   row           value                       │
 ─────────────────────────────────────────── │ ── SECTION ───────────────────
  enter change   u  put back   h  history    │ what the row changes, drawn
  s     save     x  drop all   q  quit       │ ── SECTION ───────────────────
```

The rules, each of which was a defect before it was a rule:

1. **Logic in a helper, the shell only draws and asks.** The helper answers one word per
   step (`rows`, `header`, `detail KEY`, `try KEY VALUE`, `flow save`). Every step is then
   testable with no terminal, and the screen is a thin `fzf` call over them.
2. **The top line is the state**, in one short sentence (A12). It changes after every action
   (`transform-header`).
3. **The list is grouped** (F10) and each row is `label  value  marker`. The marker is a
   short word, never a sentence: the detail belongs in the pane.
4. **The pane has a fixed top**: `tuikit.title`, then the same three labelled lines for
   every row (F11). Below it, `tuikit.section` dividers in the same order everywhere.
5. **The footer is a legend** from `tuikit.legend` (F12), and every key in it is bound.
   A test asserts both directions.
6. **Questions are boxes over the screen** (F9), never a new screen. Anything lasting needs
   a yes from a key press; with no terminal to ask on, the answer is no.
7. **Trying is not saving.** Keep `saved` and `draft` as separate files, show the draft live,
   and write `saved` only on a yes. Keep every save in a history, starting with the state
   before the tool first ran, so there is always a way back.
8. **Never rewrite a config the owner maintains.** Add one include line once, on a yes,
   after a backup, and keep the tool's values in the tool's own file.
9. **A precondition is checked before the screen that needs it** (A14).
10. **The place is kept** when a row opens another screen and returns (F14).

Skeleton of the flow callback and its binds:

```bash
# in the tool: one word from the helper becomes what the screen does next
--__flow) word=$(helper flow "$2" "$3")
  case "$word" in
    refresh) printf 'clear-screen+reload(%s --__rows)+transform-header(%s --__header)+refresh-preview' "$q" "$q" ;;
    redraw)  printf 'clear-screen' ;;
    abort)   printf 'abort' ;;
    edit\ *) printf 'become(%s --__screen edit %s)' "$q" "${word#edit }" ;;
  esac ;;

fzf --ansi --no-input --reverse --height=100% --delimiter=$'\t' --with-nth=2 --sync \
  --header "$(helper header)" --footer "$(helper keys)" \
  --preview "$q --__detail {1}" --preview-window "right,58%,border-left" \
  --bind "start:pos(${start:-2})" \
  --bind "enter:transform($q --__flow enter {1})" \
  --bind "s:transform($q --__flow save)" \
  --bind "q:transform($q --__flow quit),esc:transform($q --__flow quit)"
```

```python
# in the helper: the box, the key, and the one word back
import sys; sys.path.insert(0, str(Path.home() / ".claude/scripts/tui"))
from tuikit import GREEN, CYAN, choice, dialog, legend, section, title

def flow(step):
    if step == "save":
        key = dialog("Save this?", changes(), choice(("y", "save", GREEN), ("n", "keep trying", CYAN)))
        if key in ("y", "Y"):
            save()
        return "refresh"
```

Testing a screen built this way: the helper's steps run under plain `subprocess` with state
redirected to a temp folder by env vars; the tool is started through a link in another
folder (A10); and `smoke.sh` opens each screen by its installed name, one `--keys` per step.

## Cross-link index

| Need | Read |
|------|------|
| the functional decision tree + fzf-as-runtime + degradation ladder | [`tui-design.md`](tui-design.md) |
| help-text layout / colors / columns | [`cli-help-design.md`](cli-help-design.md) |
| color tiers, truncation, ≤78 cols | [`visual-design.md`](visual-design.md) |
| `/dev/tty`, bash-3.2, `find /tmp`, timeout traps | [`bash-gotchas.md`](../skills/shared/bash-gotchas.md) |
| what a hook can/can't put on screen | [`hooks-tui-limits.md`](../features/hooks-tui-limits.md) |
| run-before-done discipline | [`exercise-based-verification.md`](../rules/exercise-based-verification.md) |
