---
brief: CLI --help output: header, USAGE/EXAMPLES/OPTIONS order, color coding, column alignment, no-pager rule
triggers:
  - topic:cli-help
  - topic:terminal-ux
  - phrase:"-h"
  - phrase:"--help"
related: []
tier: 2
category: conventions
updated: 2026-04-24
stale_after_days: 90
---

# Cli Help Design
Rules for `-h` / `--help` output on any CLI tool Claude writes.

## Principles

1. **Header**: Tool name + one-line purpose. Use gum border or ANSI bold/color if available.
2. **Structure**: USAGE → EXAMPLES → OPTIONS → SUBCOMMANDS → CONFIGURATION. Users scan top-down — put the most-used info first.
3. **Examples over descriptions**: Show 4-6 real commands with `# comments` explaining each. Users copy-paste examples more than they read option docs.
4. **Color coding** (ANSI or gum): section titles in **bold yellow**, commands/subcommands in **cyan**, option flags in **green**, descriptions/comments in **dim**. Never rely on color alone — text must be readable without it.
5. **Consistent column alignment**: Options left-aligned at 20 chars, descriptions start at a fixed column. Use `printf '  %-20s %s\n'` pattern.
6. **Show defaults**: Display current default values inline (e.g., `--max-tokens N  Max output tokens (default: 200)`).
7. **Group related options**: Separate option groups with labeled sections, not a flat list.
8. **No pager**: Help text should be short enough to fit ~60 lines. If longer, the tool is doing too much or the help needs trimming.
9. **Fallback**: Always works without gum/color — test with `TERM=dumb` or pipe to `cat`.

## Reference implementation

`~/.claude/scripts/llm-mini/llm-mini-core.sh` `show_help()`.

## Pipe-friendly mode (stdio)

When a tool's output is likely to be piped (logs, JSON, line-oriented data), support a plain mode that strips colors, borders, and pagination automatically:

- **Detect non-TTY:** `[ -t 1 ]` in bash, `os.isatty(sys.stdout.fileno())` in Python. If false → disable color and box-drawing.
- **`--json` / `--plain` flags:** explicit overrides. `--json` emits structured output; `--plain` disables all styling but keeps human formatting.
- **Respect `NO_COLOR`** and `TERM=dumb` env vars — strip ANSI.
- **Flush on newlines:** so pipes don't buffer indefinitely. `sys.stdout.reconfigure(line_buffering=True)` in Python; `stdbuf -oL` when calling subprocesses.

Rule of thumb: if `tool | grep` or `tool | jq` would be a reasonable thing to run, the tool must support a pipe mode.

## Man pages — for larger tools

For tools with substantial surface area (more than one subcommand, more than ~60 lines of `--help`, or installed via a package manager), generate a man page alongside the tool:

- Write source in `<tool>.1.md` (markdown-to-roff) or raw roff `<tool>.1`
- Install to `~/man/man1/` (or `/usr/local/share/man/man1/` if system-wide) — user's `MANPATH` should include it
- Render check: `man -l <tool>.1` (macOS) or `groff -Tascii -man <tool>.1 | less`
- Tools: `pandoc -s -t man <tool>.1.md -o <tool>.1` converts markdown → man
- Cross-reference: `--help` output should include a final line like `See 'man <tool>' for full reference.`

Skip man pages for: one-shot scripts, personal helpers, tools with a single clear flag set.

## Source vs rendered output — for tools that emit content meant to be saved

When a tool emits content that may be saved to a file (RCA generators, report makers, scaffold writers, doc generators), the **default output should be SOURCE**, not rendered. Rendering should require an explicit `--render` / `--pretty` flag.

Rationale: rendered output (gum panels, ASCII tables, box-drawing, fixed-width column alignment) is for terminal viewing. Saving rendered output as source breaks downstream consumers — markdown renderers see "every line indented 2 spaces" as code blocks; JSON parsers reject prettified-then-line-wrapped values; YAML loaders fail on truncated cell labels with `…`.

For tools that have BOTH a "show on screen" mode and a "save to file" mode, separate the paths:

```bash
mytool report                    # default: emit SOURCE markdown (saveable)
mytool report --render           # explicit: render to TTY for viewing
mytool report --render | less    # acceptable: rendered into a pager
mytool report > file.md          # acceptable: source saved to file
mytool report --render > file.md # WRONG: rendered output saved as source
```

This is the source-vs-render discipline graduated from the 2026-05-16 RCA-quality incident (`ascii-art-tables-instead-of-gum-tools` recurring at 4× because RCA-writing tools rendered then saved). New tools that touch saveable output should follow this default.
