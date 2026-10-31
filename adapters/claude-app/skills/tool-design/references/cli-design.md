# CLI design: help, pipe mode, safety, robustness

Conventions for command-line tools. Help output comes first because it is the
most common need. Below it are pipe mode, man pages, source versus rendered
output, and the safety and robustness patterns that recurring tool work
surfaced. Interactive pickers and launchers are in `tui-design.md`.

## Help text

1. **Header.** Tool name and a one-line purpose, in bold or color when the
   terminal supports it.
2. **Order.** USAGE, EXAMPLES, OPTIONS, SUBCOMMANDS, CONFIGURATION. Readers scan
   top-down, so the most-used information goes first.
3. **Examples over descriptions.** Four to six real commands with a `# comment`
   on each. People copy examples more than they read option docs.
4. **Color coding.** Section titles in bold yellow, commands and subcommands in
   cyan, flags in green, descriptions and comments dim. Never rely on color
   alone. The text must read without it.
5. **Aligned columns.** Flags left-aligned in a 20-character column,
   descriptions at a fixed column: `printf '  %-20s %s\n'`.
6. **Show defaults inline.** `--max-tokens N   Max output tokens (default: 200)`.
7. **Group related options** under labeled sections, not one flat list.
8. **No pager.** Help fits in about 60 lines. Longer means the tool does too
   much or the help needs trimming.
9. **Fallback.** Help works with no color library installed. Test it with
   `TERM=dumb` and piped to `cat`.

## Pipe-friendly mode

When output is likely to be piped (logs, JSON, line-oriented data), support a
plain mode that drops color, borders and pagination on its own:

- **Detect a non-TTY.** `[ -t 1 ]` in bash, `sys.stdout.isatty()` in Python. If
  false, turn off color and box drawing.
- **Explicit flags.** `--json` emits structured output. `--plain` drops all
  styling but keeps human formatting.
- **Respect `NO_COLOR` and `TERM=dumb`.**
- **Flush on newlines** so pipes do not buffer forever. In Python,
  `sys.stdout.reconfigure(line_buffering=True)`, and `stdbuf -oL` for
  subprocesses.

Rule of thumb: if `tool | grep` or `tool | jq` is a reasonable thing to run,
the tool needs a pipe mode.

## Man pages for larger tools

For a tool with more than one subcommand, more than about 60 lines of help, or
a package-manager install, ship a man page:

- Write the source as `<tool>.1.md` and convert with
  `pandoc -s -t man <tool>.1.md -o <tool>.1`, or write roff directly.
- Render-check with `man -l <tool>.1` or `groff -Tascii -man <tool>.1`.
- End `--help` with `See 'man <tool>' for the full reference.`

Skip man pages for one-shot scripts, personal helpers and tools with one clear
flag set.

## Source by default for anything meant to be saved

When a tool emits content that may be saved (reports, scaffolds, generated
docs), the default output is **source**. Rendering needs an explicit
`--render` or `--pretty`.

Rendered output (panels, box-drawn tables, fixed-width alignment) is for the
terminal. Saved as source it breaks every consumer: markdown renderers read
lines indented two spaces as code blocks, JSON parsers reject wrapped values,
and YAML loaders choke on cells truncated with `…`.

```bash
mytool report                    # default: source markdown, safe to save
mytool report --render           # rendered for the terminal
mytool report --render | less    # fine: rendered into a pager
mytool report > file.md          # fine: source saved to a file
mytool report --render > file.md # wrong: rendered output saved as source
```

## Safety for destructive tools

A tool whose Enter key destroys something (kills a process, deletes files,
drops rows) needs guards a read-only tool does not.

- **Exact match by default in any picker that destroys.** Fuzzy matching
  scatters. On a real machine, typing `python` into a fuzzy process killer
  matched 136 rows, most of them unrelated system services. Exact matching
  gave the 10 real ones. A false positive costs a re-pick in a file opener and
  the wrong kill in a killer. Make exact the default and let the user opt into
  fuzzy.
- **Floor-guard any catch-all value.** `kill -<pgid>` with pgid 0 signals the
  caller's own group and kills the terminal. pgid 1 means every process you
  can signal. Refuse pgid 1 or lower before sending. Generalized: any API where
  zero, a low or a negative argument quietly means "all" needs a floor check
  before a computed value reaches it.
- **Show the blast radius before a bulk destroy.** A confirm that says
  `[scope: group]` hides how many die. Expand to the real id list and print the
  count and ids before the confirm. The user can only approve what they see.
- **Refuse with a pointer.** When you block an action, name the conflict and
  the safe alternative in one message: `'rg' already exists (/usr/bin/rg). Use
  'mytool scan' instead.` A bare "refused" makes the user guess.

## Make an interactive tool testable headless

A test harness cannot drive a picker, but it can drive the logic if UI and
action are split. Expose the data and destructive paths as hidden subcommands
(`tool --__kill SIG SCOPE PID...`, `tool --__feed`, `tool --__advise PID`)
that take arguments and print or act with no UI. One seam then serves both:

- tests call `--__kill` and `--__advise` directly and read the result,
- the picker's key bindings call the same verbs:
  `--bind "ctrl-k:execute-silent(tool --__kill TERM one {1})+reload(tool --__feed)"`.

The interactive shell stays thin and is checked by hand. Everything under it
runs in tests.

## Robustness for tools that own files, symlinks or a registry

- **`while read` drops a last line with no trailing newline.** Hand-edited data
  files lose that newline eventually. `awk` keeps the row and the loop skips it,
  so two code paths disagree on one file. Guard it:
  `while IFS=$'\t' read -r a b || [ -n "$a" ]; do`.
- **Never `ln -sf` over a path you did not create.** If the target is a real
  file, it is gone. Check `[ -e X ] && [ ! -L X ]` and refuse.
- **Validate any string that becomes a filename, a symlink and a command
  word.** Spaces, slashes and a leading dash give broken links or flag
  injection. Reject `-*|*[!A-Za-z0-9._-]*` before creating anything.
- **Do not let a tool shadow the binaries it depends on.** A registry that
  links into `~/.local/bin` can register `ps` or `lsof` and silently break
  every tool that calls them. Two sides to the fix: `add` refuses names that
  already resolve on the full PATH minus its own bin dir, and a tool that
  depends on system binaries prepends `/bin:/usr/bin:/sbin:/usr/sbin` to its
  own PATH.

## Derive metadata before prompting

When a tool needs a label for something it registers, do not write a `TODO`
and do not prompt right away. Derive it, best signal first: a `tldr` one-liner,
the man page NAME section (macOS man uses an en dash there), the package
manager's description, the first prose line of `--help`, then `-h`, then an
honest "(describe me)". Registered commands then get real one-liners on their
own (`fd`: "Find entries in the filesystem"), and the human fixes only the
leftovers.

## Registry pattern: one source of truth, a derived projection, a doctor

For a tool that catalogs things and installs them, keep one **source of
truth** (a TSV or JSON manifest). Treat the live state (symlinks, generated
docs) as a **projection** rebuilt from it. Ship a **`doctor`** that reconciles
both ways: manifest rows with no install, and installs with no manifest row.
The manifest is editable and diffable, the projection is disposable, and that
is what makes `install` idempotent and `rm` complete.

## Isolate a heavy dependency, never install it globally

A shell tool that calls Python or Node for one heavy capability must not
depend on a global `pip install`. The global lives in one of the machine's
several interpreters, so the tool works for you and fails for the next
`python3` on PATH, and it does not travel to a new machine.

- **Keep cheap paths dependency-free.** Only the capability that needs the
  package goes through the isolated runner. A converter can run CSV and JSON on
  plain `python3` and send only XLSX through the isolated path.
- **Run the dependency in an isolated, cached environment:**
  `uv run --with <pkg> python3 - <<'PY' ...`. uv caches the package outside
  global site-packages and brings its own interpreter.
- **Offer an override variable** (`MYTOOL_PY`) so a machine without uv can
  point at any interpreter that has the package.
- **Resolver order:** the override, then `uv run --with`, then bare `python3`
  for stdlib paths, then a clear error that says "install uv or set
  `MYTOOL_PY`". Never "pip install globally".
- **Tests use the same isolation**, including for building fixtures, or the
  suite is not portable.
