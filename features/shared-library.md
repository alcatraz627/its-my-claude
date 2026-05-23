---
brief: std::claude::shared utility library: Python imports, shell scripts, gum-tui.sh styled output
triggers:
  - tool:gum-tui.sh
  - tool:lock-file.sh
  - topic:shared-utilities
  - topic:styled-terminal-output
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Shared Library
`std::claude::shared` — utility library at `~/.claude/skills/shared/`. (Renamed from plain `std::claude` in v0.2.0.)

## Python imports

```python
import sys, os
sys.path.insert(0, os.path.expanduser("~/.claude/skills"))
from shared import Banner, Section, Item, tree, kv_line, truncate_path, THEMES
```

## Shell scripts (always absolute paths)

```bash
bash ~/.claude/skills/shared/lock-file.sh acquire "<file>" "<skill>"
bash ~/.claude/skills/shared/prepend-runtime-note.sh "<skill>" /tmp/note.md
bash ~/.claude/skills/shared/check-path.sh "<filepath>"
```

## Styled terminal output — `gum-tui.sh`

Use for **all** non-interactive Bash output (tables, status lines, headers, panels). **Source it; never call raw `gum style` directly:**

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Title"          # styled header
gum_table "A,B" "1,2"       # bordered table
gum_success "Done"          # green ✓ line
gum_complete "name" "K=V"   # completion block
```

Run `bash ~/.claude/skills/shared/gum-tui.sh` for help, `list`, or `demo`.

## Full API reference

`~/.claude/skills/shared/README.md`.

## Visual rendering examples

Read `~/.claude/assets/docs/gum-rendering-examples.md` when composing multi-box layouts, rendering architecture diagrams, building dashboards, choosing border styles, or needing a concrete `gum style`/`gum join`/`gum table` snippet.
