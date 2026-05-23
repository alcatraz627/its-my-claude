# std::claude::shared v0.2.0

Shared utility library for Claude Code skills. Located at `~/.claude/skills/shared/`.

**Label history:** originally `std::claude` (v0.1.x) as a single-label library. Renamed to `std::claude::shared` in v0.2.0 when the namespace tree was introduced (see `~/.claude/NAMESPACE.md` + Migration 0001). The library and its path did not move; only the label changed.

## Quick Start

### Python

```python
import sys, os
sys.path.insert(0, os.path.expanduser("~/.claude/skills"))
from shared import Banner, Section, Item, tree, kv_line, truncate_path, THEMES
```

Or the direct import (when `sys.path` points to `shared/` itself):

```python
sys.path.insert(0, os.path.expanduser("~/.claude/skills/shared"))
from banner import Banner, tree, kv_line
```

### Bash

Always use absolute paths:

```bash
bash ~/.claude/skills/shared/lock-file.sh acquire "<filepath>" "<skill-name>"
bash ~/.claude/skills/shared/prepend-runtime-note.sh "<skill-name>" /tmp/note.md
bash ~/.claude/skills/shared/check-path.sh "<filepath>"
```

### Bash — gum TUI library

Source `gum-tui.sh` for styled terminal output that works without a TTY (safe in Claude
Code's Bash tool). Requires `gum` installed (`brew install gum`).

```bash
source ~/.claude/skills/shared/gum-tui.sh

gum_header "My Skill"
gum_table "Name,Status" "api,running" "db,stopped"
gum_success "All done!"
gum_dashboard "Panel1|line1|line2" "Panel2|line1|line2"
```

See `gum-guide.md` for the full TTY compatibility matrix and function reference.

---

## Python API — `banner.py`

### Classes

#### `Banner(title, subtitle?, timestamp?, width=72, theme="default")`

Terminal banner renderer with aligned Unicode borders.

| Param | Type | Default | Description |
|---|---|---|---|
| `title` | str | required | Banner title (uppercase recommended) |
| `subtitle` | str | `""` | Subtitle line below title |
| `timestamp` | str | `""` | Timestamp shown in header |
| `width` | int | `72` | Total character width |
| `theme` | str | `"default"` | Theme name: `default`, `minimal`, `rounded`, `heavy` |

**Methods:**
- `add_section(symbol, title, items)` — Add a section with heading and `Item` list
- `render() -> str` — Render to string with ANSI-safe borders
- `verify() -> list[str]` — Check all lines are exactly `width` chars (returns misaligned lines)
- `from_dict(d) -> Banner` — Class method: build from dict/JSON config

#### `Section(symbol, title, items)`

A named group of items inside a banner.

#### `Item(prefix, text)`

A single line inside a section. Common prefixes: `"├-"`, `"└-"`, `"  "`.

### Functions

#### `kv_line(key, value, dots=6) -> str`

Format a key-value pair with dot leaders: `"State ...... running"`

#### `tree(items: list[str]) -> list[Item]`

Convert a list of strings into `Item` objects with tree prefixes (`├-` / `└-`).

#### `truncate_path(path, max_len=35) -> str`

Shorten a path to fit `max_len`, replacing middle segments with `...`.

### Constants

#### `THEMES`

Dict of 4 theme presets: `default`, `minimal`, `rounded`, `heavy`. Each theme defines border characters, fill characters, and ornament symbols.

---

## Shell Scripts

### `lock-file.sh`

Write-priority file locking for concurrent skill writes.

```bash
lock-file.sh <action> <filepath> [skill-name]
```

| Action | Description | Exit |
|---|---|---|
| `acquire <path> [name]` | Acquire write lock (retries on contention) | 0=ok, 1=failed |
| `read <path> [name]` | Declare read intent (always succeeds) | 0 |
| `release <path> [name]` | Release write lock | 0=ok, 1=not found |
| `check <path>` | Print lock status | 0=free, 1=locked |
| `cleanup` | Remove all stale locks | 0 |

Lock files stored in `~/.claude/skills/shared/locks/`.

### `prepend-runtime-note.sh`

Atomic prepend to `runtime-notes.md`.

```bash
prepend-runtime-note.sh <skill-name> <temp-file>
```

Reads content from `<temp-file>`, prepends it to `.claude/skills/runtime-notes.md` (project-local). Creates the file with a header if it doesn't exist. Uses `lock-file.sh` internally.

### `check-path.sh`

Validates a path against the forbidden path deny list.

```bash
check-path.sh <filepath>
# Exit 0 = safe, Exit 1 = forbidden
```

### `log-run.sh`

Append a timestamped entry to a log file.

```bash
log-run.sh <log-file> <message>
```

---

## Reference Docs

| File | Topic |
|---|---|
| `asset-management.md` | Asset storage conventions (`~/.claude/assets/`) |
| `bash-gotchas.md` | Shell pitfalls + patterns: quoting, pipelines, `/dev/tty` interactive prompts |
| `doc-naming.md` | File naming: datestamp prefixes, session tags |
| `gum-guide.md` | Gum TUI library: spinners, confirm, choose, input |
| `mcp-config.md` | MCP server setup from catalog |
| `safe-delete.md` | `trash` vs `rm`: why and how |
| `wal-format.md` | Write-Ahead Log format spec |

---

## Adding New Utilities

Checklist for adding a new utility to `std::claude::shared`:

1. Place the file in `~/.claude/skills/shared/`
2. If Python: add exports to `__init__.py` and `__all__`
3. If Bash: add usage comment block with actions, arguments, exit codes
4. Add entry to this README under the appropriate section
5. Add entry to `CHANGELOG.md` under the next version
6. Bump `VERSION` (PATCH for fixes, MINOR for new utilities)
7. Test: `python3 test_std.py` and/or `bash test_scripts.sh`

---

## Versioning

Semver in `VERSION` file. Convention:
- **PATCH** (0.1.x): Bug fixes in existing utilities
- **MINOR** (0.x.0): New utilities added
- **MAJOR** (x.0.0): Breaking API changes (renamed functions, removed exports)

See `CHANGELOG.md` for history.
