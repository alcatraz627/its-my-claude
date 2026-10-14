---
brief: Building CLI tools: help layout/color/pipe-mode/man-pages/source-vs-render, plus (from zap and zcmd) destructive-tool safety, headless-testable internal verbs, file/symlink/registry robustness, PATH-shadow hardening, and metadata auto-derivation
triggers:
  - topic:cli-help
  - topic:terminal-ux
  - topic:cli-tools
  - phrase:"-h"
  - phrase:"--help"
  - phrase:"build a cli"
related: [tui-design.md]
tier: 2
category: conventions
updated: 2026-06-25
stale_after_days: 90
---

# Cli Help Design
Conventions for CLI tools Claude writes. Help output comes first (it's the most
common need). Below that are pipe mode, man pages, source-vs-render, and the
robustness and safety patterns that recurring tool work (zap, zcmd) surfaced. For
interactive TUI patterns (fzf-as-launcher, color-vs-search fields) see
`tui-design.md`.

## Principles

1. **Header**: Tool name and one-line purpose. Use gum border or ANSI bold/color if available.
2. **Structure**: USAGE → EXAMPLES → OPTIONS → SUBCOMMANDS → CONFIGURATION. Users scan top-down, so put the most-used info first.
3. **Examples over descriptions**: Show 4-6 real commands with `# comments` explaining each. Users copy-paste examples more than they read option docs.
4. **Color coding** (ANSI or gum): section titles in **bold yellow**, commands and subcommands in **cyan**, option flags in **green**, descriptions and comments in **dim**. Never rely on color alone, because text must be readable without it.
5. **Consistent column alignment**: Options left-aligned at 20 chars, descriptions start at a fixed column. Use the `printf '  %-20s %s\n'` pattern.
6. **Show defaults**: Display current default values inline (for example `--max-tokens N  Max output tokens (default: 200)`).
7. **Group related options**: Separate option groups with labeled sections, and avoid a flat list.
8. **No pager**: Help text should be short enough to fit about 60 lines. If it is longer, the tool is doing too much or the help needs trimming.
9. **Fallback**: Help always works without gum or color. Test with `TERM=dumb` or pipe to `cat`.

## Reference implementation

`~/.claude/scripts/llm-mini/llm-mini-core.sh` `show_help()`.

## Pipe-friendly mode (stdio)

When a tool's output is likely to be piped (logs, JSON, line-oriented data), support a plain mode that strips colors, borders and pagination automatically:

- **Detect non-TTY:** `[ -t 1 ]` in bash, `os.isatty(sys.stdout.fileno())` in Python. If false, disable color and box-drawing.
- **`--json` / `--plain` flags:** explicit overrides. `--json` emits structured output, and `--plain` disables all styling but keeps human formatting.
- **Respect `NO_COLOR`** and `TERM=dumb` env vars and strip ANSI.
- **Flush on newlines:** so pipes don't buffer indefinitely. Use `sys.stdout.reconfigure(line_buffering=True)` in Python and `stdbuf -oL` when calling subprocesses.

Rule of thumb: if `tool | grep` or `tool | jq` would be a reasonable thing to run, the tool must support a pipe mode.

## Man pages for larger tools

For tools with substantial surface area (more than one subcommand, more than about 60 lines of `--help`, or installed via a package manager), generate a man page alongside the tool:

- Write source in `<tool>.1.md` (markdown-to-roff) or raw roff `<tool>.1`
- Install to `~/man/man1/` (or `/usr/local/share/man/man1/` if system-wide), and the user's `MANPATH` should include it
- Render check: `man -l <tool>.1` (macOS) or `groff -Tascii -man <tool>.1 | less`
- Tools: `pandoc -s -t man <tool>.1.md -o <tool>.1` converts markdown to man
- Cross-reference: `--help` output should include a final line like `See 'man <tool>' for full reference.`

Skip man pages for one-shot scripts, personal helpers, and tools with a single clear flag set.

## Source vs rendered output, for tools that emit content meant to be saved

When a tool emits content that may be saved to a file (RCA generators, report makers, scaffold writers, doc generators), the **default output should be SOURCE** and not rendered. Rendering should require an explicit `--render` or `--pretty` flag.

Rationale: rendered output (gum panels, ASCII tables, box-drawing, fixed-width column alignment) is for terminal viewing. Saving rendered output as source breaks downstream consumers. Markdown renderers see "every line indented 2 spaces" as code blocks, JSON parsers reject prettified-then-line-wrapped values, and YAML loaders fail on truncated cell labels with `…`.

For tools that have BOTH a "show on screen" mode and a "save to file" mode, separate the paths:

```bash
mytool report                    # default: emit SOURCE markdown (saveable)
mytool report --render           # explicit: render to TTY for viewing
mytool report --render | less    # acceptable: rendered into a pager
mytool report > file.md          # acceptable: source saved to file
mytool report --render > file.md # WRONG: rendered output saved as source
```

This is the source-vs-render discipline graduated from the 2026-05-16 RCA-quality incident (`ascii-art-tables-instead-of-gum-tools` recurring at 4× because RCA-writing tools rendered then saved). New tools that touch saveable output should follow this default.

## Safety for destructive tools (kill / delete / bulk ops)

A tool whose Enter key destroys something (kills a process, removes files, drops rows) needs guardrails a read-only tool doesn't. Graduated from `zap`:

- **Default to EXACT match, not fuzzy, in any picker that destroys.** fzf's default fuzzy match scatters: typing `python` matched **136** rows (124 junk like `WardaSynthesizer`, `SpeechSynthesisServerXPC`) on a real machine, and `fzf --exact` gave 10 real ones. A false positive costs a re-pick in a file-opener but the wrong kill in a killer. Make exact the default and let the user opt into fuzzy.
- **Floor-guard any catch-all sentinel.** `kill -<pgid>` with pgid 0 signals the caller's own group (kills the terminal), and pgid 1 means "every process you can signal" on macOS. Refuse pgid ≤ 1 before sending. This generalizes: any API where a zero, low or negative argument silently means "all" needs an explicit floor check before you pass a computed value into it.
- **Show the blast radius before a bulk destroy.** A `[scope: group]` confirm hides how many die. Expand the group or tree to the actual id list and print it (count plus ids) before the confirm, because the user can only approve what they can see.
- **Refuse with a pointer, not a flat error.** When you block an action, name the conflict AND the safe alternative in the same message: `zcmd add rg` prints "'rg' already exists (/opt/homebrew/bin/rg); use `zcmd scan` instead." A bare "refused" makes the user guess the next move.

## Make an interactive TUI headless-testable with internal verbs

A headless test harness can't drive an fzf or gum tool, but its *logic* can be driven if you split UI from action. Expose the data and destructive paths as hidden subcommands (`tool --__kill SIG SCOPE PID...`, `tool --__feed`, `tool --__advise PID`) that take args and print or act with no TUI. Then one seam serves two masters:
- the test harness calls `--__kill` and `--__advise` directly and reads the result (zap's kill, escalation, tree-expansion, truthful report, and recommendation engine were all verified this way without ever opening fzf);
- the fzf binds reuse the same verbs: `--bind "ctrl-k:execute-silent(kill -TERM {1})+reload(tool --__feed)"`.

The interactive shell (the menus, the fzf loop) stays the thin part you verify by hand, and everything underneath is exercised by tests.

For the enriched interactive form, follow the standard in [`tui-handbook.md`](tui-handbook.md) §10. That covers colored lists whose selection parses cleanly (`tui_pick_key`), suggest-don't-restrict selectors (`tui_pick_or_add`), arrow-nav-by-default, and the both-fd color gate that keeps the same tool's agent calls plain. Reference build: `gcc-schedule -i`.

## Robustness for tools that own files, symlinks, or a registry

Graduated from `zcmd` (a TSV manifest and PATH-symlink registry):

- **A `while read` loop drops a final line with no trailing newline.** A hand-editable data file eventually loses its trailing `\n`. Then `while IFS=$'\t' read -r a b; do ...; done < file` silently skips the last row while `awk` keeps it, so two code paths disagree on the same file. Guard the loop with a final-line check: `while IFS=$'\t' read -r a b || [ -n "$a" ]; do`.
- **Never `ln -sf` over a path you didn't create.** If `~/.local/bin/<name>` is a real file, `ln -sf` replaces it and the content is gone. Check `[ -e X ] && [ ! -L X ]` and refuse.
- **Validate any string that becomes a filename AND a symlink AND a command word.** Spaces, slashes and a leading dash give broken symlinks or flag injection. Reject `-*|*[!A-Za-z0-9._-]*` up front, before you create anything.
- **Don't let a tool shadow the binaries it depends on.** A registry that symlinks into `~/.local/bin` can register `ps` or `lsof`, shadowing the real ones on PATH and silently breaking every tool (itself included) that calls them. The fix has two sides: (a) the registry's `add` refuses names that resolve to an existing command on the *full* PATH minus its own bin dir, and (b) a tool that depends on system binaries prepends `/bin:/usr/bin:/sbin:/usr/sbin` to its own PATH so a stub can't shadow them.

## Derive metadata from the ecosystem before prompting the human

When a tool needs a description or label for something it registers, don't write a `TODO` placeholder and don't immediately prompt. *Derive* it, best-signal-first, and only then fall back. For a command on macOS the chain that works is: `tldr` one-liner, then the `man` NAME section (UTF-8 en-dash aware, since macOS man uses `–` and not `-`), then `brew desc <name>` (clean package tagline), then the first prose line of `--help`, then `-h`, then an honest "(describe me)" placeholder. A registered tool then gets a real one-liner automatically (`fd → "Find entries in the filesystem"`), and the human edits only the leftovers.

## Registry pattern: source-of-truth, derived projection, and a reconciling doctor

For a tool that catalogs things and installs them, keep one **source of truth** (a TSV or JSON manifest), treat the live state (PATH symlinks, generated tldr and man pages) as a **derived projection** rebuilt from it, and ship a **`doctor`** that reconciles both directions: manifest rows with no symlink, and symlinks or commands with no manifest row. The manifest is editable and diffable, and the projection is disposable. This is what lets `install` be idempotent and `rm` clean up completely.

## Isolate a tool's non-stdlib dependency with `uv`, and never use a global install

A shell tool that shells out to python (or node) for one heavy capability should NOT depend on a globally `pip install`ed package. The global is invisible breakage: it lives in *one* of the machine's several pythons (a user-site dir), so the tool works for you and fails for the next python on PATH (pyenv or homebrew), and it doesn't travel to a new machine. Graduated from `zconvert` (openpyxl) and `desktop.sh`/`annotate-screenshot.py` (Pillow), both 2026-06-25.

The pattern (`uv` is the cleanest on a machine that already has it):
- **Keep the cheap paths dependency-free.** Only the capability that *needs* the package routes through the isolated runner, and the stdlib paths run bare `python3`. (`zconvert` runs csv, tsv and json on plain `python3`, and only xlsx goes through uv.)
- **Run the dep in an isolated, cached env:** `uv run --with <pkg> python3 - <<'PY' …`. uv fetches the package into its own cache (`~/.cache/uv/…`, never global site-packages), caches it after first use, and provides its own python, so it works regardless of which `python3` the user has. Verify once: `uv run --with <pkg> python3 -c 'import <pkg>'` should resolve from the uv cache and not a global path.
- **Expose an override env var** (`ZCONVERT_PY`, `DESKTOP_PY`) so a machine without uv, or with a deliberately chosen interpreter, can point the tool at any python or command that has the package. Set it in your shell config and it travels with you.
- **Resolver precedence:** `$OVERRIDE`, then `uv run --with <pkg> python3` (if uv is present), then bare `python3` (stdlib-only paths), then a clear error that says "install uv (recommended) or set `$OVERRIDE`" and **never** "pip install globally".
- **Tests must use the same isolation** and skip the machine's happens-to-exist global, or the suite isn't portable. Build xlsx and PNG fixtures via `uv run --with <pkg>` too.

This keeps a tool portable (clone the repo and have uv, and it works) without vendoring a venv into the repo or polluting global site-packages.
