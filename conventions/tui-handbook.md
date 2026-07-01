---
brief: How to build a terminal UI in this environment — the std::claude::tui library, the fzf-app blueprint, the bug-free patterns, and the traps that break TUIs here.
triggers:
  - topic:gum
  - phrase:"build a tui"
  - phrase:"terminal ui"
  - phrase:"fzf picker"
  - tool:tui/colors.sh
  - tool:tui/pick.sh
  - tool:tui/tty.sh
related:
  - conventions/tui-design.md
  - conventions/cli-help-design.md
  - conventions/visual-design.md
  - features/hooks-tui-limits.md
  - skills/shared/bash-gotchas.md
tier: 2
category: conventions
updated: 2026-07-01
stale_after_days: 180
---

# TUI handbook — building terminal UIs in this environment

The practical guide to building a TUI here: which engine to reach for, the
copy-paste blueprint, the reusable modules, the patterns worth stealing, and the
traps that break terminal UIs *on this machine specifically*. It **routes** to the
existing conventions rather than restating them — read those for depth, this for
the build.

## §0 · Orientation — fzf is the runtime

```
 std::claude::tui
   INPUT side  (scripts/tui/)          DISPLAY side (skills/shared/)
   colors.sh  tty.sh  require.sh        gum-tui.sh  (gum_* output wrappers)
   pick.sh    file-preview.sh
   ───────────────────────────────      ────────────────────────────────
   PATTERN side (this handbook): the --__ fzf-app blueprint · destructive
   guards · the testing seams.
```

The single most important fact: **fzf already is a TUI runtime.** Build on
fzf/gum and you inherit alternate-screen handling, termios save/restore, Ctrl-C
recovery, cursor management, and resize *for free*. So the library is deliberately
small — it extracts the duplicated *correctness* (color gating, tty probing,
degradation, dep preflight); the handbook owns the load-bearing *pattern* (the
`--__` self-re-exec blueprint). Don't hand-roll a screen unless you've proven you
must (you almost never must — see [`tui-design.md`](tui-design.md)).

## §1 · Which engine — pointer, not a restatement

The fzf-vs-gum-vs-framework decision tree and the "pick the lightest tool"
reasoning already live in [`conventions/tui-design.md`](tui-design.md) (§ decision +
§ fzf-as-runtime). One-line summary so you don't have to leave:

> **fzf** = the interactive loop (a list you browse/filter/preview/act on). **gum**
> = the moments around it (confirm, input, a small styled choose) and all
> non-interactive rendering. **read** (via `tui_read_tty`) = the last-resort prompt.
> Launch gum *from* an fzf `execute()` bind — never nest gum *inside* fzf (it
> blanks the screen; see §4 A3).

All three rungs are walked for you by `tui/pick.sh` — hand-roll fzf directly only
when you need preview/reload/binds the helper can't express.

## §2 · Golden-path skeleton — the `--__` fzf-app

The canonical pattern: the tool re-execs *itself* for fzf's feed/preview/action
callbacks, exposed as hidden `--__` subcommands. This keeps the callbacks pure,
out of `-h`/completions, and **headless-testable** (§5).

```bash
#!/usr/bin/env bash
set -euo pipefail
# SELF must be overridable for tests, and ALWAYS %q-quoted into fzf bind strings —
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
  local q; q="$(printf '%q' "$SELF")"              # the load-bearing quote
  "$SELF" --__feed | fzf --ansi --height=80% --reverse \
    --preview "$q --__preview {1}" \
    --bind "ctrl-r:reload($q --__feed)" \
    --bind "ctrl-x:execute-silent($q --__act {1})+reload($q --__feed)"
}
main "$@"
```

Three rules embedded (each links to its failure-mode row, not re-explained):
`printf '%q'` self-quoting (A4) · `execute-silent` = fire-and-forget, `execute` =
inline interactive, `become` = full-screen handoff (A3) · degrade *before*
invoking fzf, never inside it.

## §3 · Features catalog — what · when · how-bug-free

| # | Feature | When | How (and the trap it avoids) |
|---|---------|------|------------------------------|
| F1 | In-list act + reload (`execute+reload`) | mutate then reflect (kill, toggle, star) | `execute-silent` for non-interactive mutation; `execute` only if it writes inline; `become` if full-screen. Wrong choice → **blank pane (A3)**. Re-quote the row via a `--__act {1}` callback, never an inline `{}` (A4). |
| F2 | `reload` / `change:reload` | refresh stale data; front a huge/DB corpus | Debounce `change:reload` (`sleep 0.1`) or you fork per keystroke. Never put a network/stdin-reading command in the source (**wedges the picker, B4**). |
| F3 | Type-dispatched preview | a list of mixed item kinds | Delegate to `file-preview.sh` — it is bounded and **always exits 0**; a preview that errors/stalls breaks the host. Size-gate big files. |
| F4 | `?`-help overlay + persistent header | every interactive tool | Render the header via a `--__iheader` callback so it's **assertable headless** (§5). Don't end a header line on a bare `path.ext.` — Ghostty eats the trailing dot into the link (A5). |
| F5 | One palette via env | always | `FZF_DEFAULT_OPTS` + `GUM_*` env, set once. Don't double-color (gum styling + embedded ANSI). Gate all color via `colors.sh` so it never leaks into a pipe (A8). |
| F6 | Command-palette / verb router | a tool with many verbs | `fzf --prompt ':' --bind 'enter:become(dispatch {})'`. `become` (not `execute`) so the verb owns a clean terminal (A3). Never auto-run on hover — require Enter. |
| F7 | Two-axis filter (scope × match) | big lists | Cycle *scope* via `reload` with a source flag; advertise fzf's `'exact` `^prefix` `suffix$` `!negate` in the header. `--nth` must point at a **clean uncolored field** — `--nth` onto ANSI matches zero (A7). |
| F8 | In-list option toggles (live header) | adjustable options mid-browse | `execute-silent(mutate statefile)+reload(feed)+transform-header(header)` — no modal, no flicker. State in a `mktemp` arg (not a global) so callbacks are pure → headless-testable. Clean the temp in an EXIT trap. (zconvert `-i` ^O/^T.) |

## §4 · Failure-mode catalog — the traps that break TUIs here

The canonical home for "what breaks a TUI on this machine." Tier A is
account/macOS-specific (the ones that actually bit); Tier B is general.

| # | Trap | Symptom | Fix |
|---|------|---------|-----|
| A1 | `cat` is aliased to `glow`; other aliases leak | corrupted captured output, garbled test scaffolding | In any script use `command cat` / `head` / `printf` / `$(<file)`; resolve tools with `command -v`, never an alias. (→ [`bash-gotchas.md`](../skills/shared/bash-gotchas.md)) |
| A2 | bash 3.2 is what `#!/usr/bin/env bash` resolves to | `read -i`, `${v,,}`, `declare -A`, `mapfile` silently absent or error | No bash-4 features. `read -i` prefill → show a `[default]` and accept Enter. (→ bash-gotchas.md) |
| A3 | alt-screen program (`gum`, nested `fzf`) inside `fzf execute(...)` | host screen blanks / garbles | `execute-silent` for non-interactive actions; for an interactive moment use `/dev/tty` `read` prompts or `become`, not a nested full-screen TUI. |
| A4 | unquoted `$SELF`/path in an fzf bind string | bind silently fails (`sh -c` word-splits on a space in the path) | `printf '%q'` the self-path; single-quote vars embedded in `--bind`/`--preview`. |
| A5 | a file path ending a line, then `.` | Ghostty swallows the dot into the link; path stops being clickable | Never end a line on `path.ext.` — follow with a space/word. (Stop-hook enforced.) |
| A6 | a prompt written to stdout instead of `/dev/tty` | the prompt text pollutes captured/piped output | Write prompts to `/dev/tty` (`tui_read_tty` does); keep stdout = the chosen value only. |
| A7 | `--nth` pointed at an ANSI-colored field | fuzzy match returns zero results | Color only the `--with-nth` display field; keep the `--nth` match field uncolored. |
| A8 | color gated on `-t 1` only | raw escapes leak into a redirected stderr (`2>log`) or a pager | Gate on **both** fds (`-t 1 && -t 2`) — `colors.sh` does this. |
| A9 | `[ -r /dev/tty ]` as the interactivity test | `read </dev/tty` hangs/errors with no controlling terminal | Probe by *opening* it — `tui_have_tty` (subshell `exec 3</dev/tty`). |
| B1 | TTY left raw after a crash mid-prompt | terminal unusable after the tool dies | fzf/gum restore on their own; for a hand-rolled `read` after gum, `stty sane` on the way out. |
| B2 | no `SIGWINCH` redraw in a hand-rolled screen | layout corrupts on resize | Don't hand-roll — fzf/gum handle resize. If you must, trap `WINCH` and redraw. |
| B3 | color leaking into a pipe | escapes in captured output | Always gate via `colors.sh`; honor `NO_COLOR`. |
| B4 | unbounded / slow / stdin-reading preview command | picker stalls or wedges per row | Bound the preview (`head`/`--line-range`), size-gate, never read stdin or the network in a preview. |

(→ macOS `find /tmp` symlink no-descent trap and the `perl` process-group timeout
gotcha live in [`bash-gotchas.md`](../skills/shared/bash-gotchas.md); the hook
output-channel ceiling lives in [`hooks-tui-limits.md`](../features/hooks-tui-limits.md).)

## §5 · Testing a TUI without a live terminal

You cannot drive fzf/gum's rendering headless, but you can verify almost
everything *underneath* it — decompose so the picker only *gathers + delegates*,
then test the parts:

1. **Hidden `--__` subcommands** are plain functions of explicit args — call them
   directly and assert output (`mytool --__feed`, `mytool --__iheader statefile`).
2. **`fzf --filter=QUERY`** runs the matcher non-interactively — assert "this query
   finds that row" and that a typed path passes through (`--print-query`).
3. **A `$SELF` re-exec stub** (`MYTOOL_SELF=/path/to/stub`) asserts the tool invokes
   the core with the right args, and that cancel invokes *nothing*.
4. **`read` prompts** become testable by reading from an env-overridable source
   (`${MYTOOL_IN:-/dev/tty}`) so a test pipes via `/dev/stdin`.
5. For the genuinely live-only surface (the rendered pane, a gum widget), drive a
   real pty with `python3 -c 'import pty; ...'` (reliable) — `script` stdin-forwarding
   is flaky. What you still can't prove, mark `UNCONFIRMED` and smoke-test by hand.

This is the [`exercise-based-verification`](../rules/exercise-based-verification.md)
rule applied to TUIs: "looks right" is not "ran it."

## §6 · Degradation ladder — pointer + module map

The ladder itself is documented in [`tui-design.md`](tui-design.md) (§ graceful
degradation). Mapping to the library:

```
fzf (full: search+preview+binds)  → tui_pick_one  (tty + fzf)
gum filter / choose (degraded)    → tui_pick_one  (tty + gum)
numbered read menu (always works) → tui_pick_one  (tty, no fzf/gum)
non-tty plain-text                → tui_pick_one --non-tty fail|first|passthrough
```

Two hard boundaries (do not fake them in fzf): **live-updating meters/gauges** and
**true multi-panel layouts** are out of scope — use tmux panes or climb to
[`dashboard-tools.md`](dashboard-tools.md).

## §7 · Destructive-tool rules (kill / delete / overwrite)

Non-negotiable for any tool that ends a process or removes/overwrites data:

- **Mass-kill guard:** never `kill -<pgid>` with pgid ≤ 1 (0 = your own group +
  the terminal, 1 = every process you own). `zap` is the reference (`group_pgid`
  refuses ≤ 1).
- **PATH front-load:** a tool that shells out to `ps`/`lsof`/`pgrep` must
  `export PATH=/bin:/usr/bin:/sbin:/usr/sbin:$PATH` first, or a shadowing stub
  returns nothing and the tool silently does the wrong thing.
- **Refuse same source==dest** (overwrite-in-place that destroys input).
- **Confirm before the act** via `tui_confirm` — which returns NO on a non-tty
  (never auto-yes headless).
- **Expose the destructive core as a `--__` subcommand** so it's exercisable
  without the TUI.

## §8 · Theme + keymap — pointer

Color tiers (OKLCH), truncation, the ≤78-col rule live in
[`visual-design.md`](visual-design.md); the help-text dialect lives in
[`cli-help-design.md`](cli-help-design.md). The only convention to set here: one
shared look via `FZF_DEFAULT_OPTS` + `GUM_*_FOREGROUND` in your shell profile, and
the keymap convention — vim `hjkl`, `/` filter, `q`/esc quit, **lowercase = safe,
UPPER/ctrl = destructive**, `?` = help.

## §9 · Library reference — `scripts/tui/`

| Module | Use | Contract |
|--------|-----|----------|
| `colors.sh` | `source` + `tui_colors_init` | TTY-gated palette; exports both `B/R` and `BLD/RST` dialects; empty strings when not a terminal (both-fd gate). |
| `tty.sh` | `source` | `tui_have_tty` (honest open-probe); `tui_read_tty [-t N] [-p P] VAR` (bounded, never hangs headless). |
| `require.sh` | `source` | `tui_have DEP` (boolean); `tui_require DEP...` (install hint to stderr, returns 1, does not exit). |
| `pick.sh` | `source` | `tui_pick_one` (one from stdin, fzf→gum→read); `tui_pick_many` (multi); `tui_choose OPT...` (one from a static arg list); `tui_confirm PROMPT` (yes=0, no/headless=1). |
| `file-preview.sh` | `exec` (`bash .../file-preview.sh F`) | rich bounded preview (jq/bat/xlsx-sheets→head), always exits 0. **Deliberate exception to the §4-A8 color gate: color is forced ON** — a preview pane always wants ANSI. |

**Discover live:** `bash ~/.claude/scripts/tui/list.sh` prints this catalog scanned straight from the modules' doc-headers — it can't drift from the code the way a hand-kept list does. Run it before building a TUI to see what's already available.

> **`set -e` note:** all five are sourced libraries. Under `set -euo pipefail`,
> guard any call that can return non-zero — `tui_require x || handle`,
> `if tui_have_tty; then act; fi`, `tui_read_tty v || v=default`. A bare non-zero return
> aborts a `set -e` caller (standard bash); the functions return status precisely
> so you branch on it.

## Cross-link index

| Need | Read |
|------|------|
| the functional decision tree + fzf-as-runtime + degradation ladder | [`tui-design.md`](tui-design.md) |
| help-text layout / colors / columns | [`cli-help-design.md`](cli-help-design.md) |
| color tiers, truncation, ≤78 cols | [`visual-design.md`](visual-design.md) |
| `/dev/tty`, bash-3.2, `find /tmp`, timeout traps | [`bash-gotchas.md`](../skills/shared/bash-gotchas.md) |
| what a hook can/can't put on screen | [`hooks-tui-limits.md`](../features/hooks-tui-limits.md) |
| run-before-done discipline | [`exercise-based-verification.md`](../rules/exercise-based-verification.md) |
