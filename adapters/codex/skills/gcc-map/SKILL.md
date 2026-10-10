---
name: gcc-map
description: Map what gcc guidance actually reaches Claude and Codex, compare live files with the indexes, and report broken links, stale views, load cost, and blind spots. Use for instruction-system audits.
---

# GCC map in Codex

Read `/Users/alcatraz627/.claude/skills/gcc-map/SKILL.md`. Measure disk and each runtime's actual load path before reading the indexes. For Codex, inspect `/Users/alcatraz627/.codex/AGENTS.md`, `/Users/alcatraz627/.agents/skills`, `/Users/alcatraz627/.codex/skills`, and `/Users/alcatraz627/.claude/adapters/codex/`; do not treat Claude autoload as Codex autoload. Run `bash /Users/alcatraz627/.claude/adapters/codex/bin/codex-gcc map --check` for adapter drift.

Compare empirical files and load paths with `CLAUDE.md`, `LOOKUP.md`, `PLACEMENT.md`, and the adapter map. Check broken links, stale generated views, always-loaded bytes, mute sentinels, glob loaders, and declared caps. Then do an open-ended blindspot pass. Save a dated report under the current project's `.claude/output/`, with every finding tied to a file and line or a measurement. This is a read-only audit of gcc; do not fix findings as part of the map.
