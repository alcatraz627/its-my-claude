---
name: codex-setup
description: Diagnose this machine's Codex and gcc adapter installation, generated rule menu, skill links, hooks, and refresh steps.
---

# Codex adapter setup

Run `python3 /Users/alcatraz627/.claude/adapters/codex/bin/codex-setup-map.py --check` before asserting the adapter is current. Read its reported source and installed paths; inspect a failing check before changing configuration. For the owner's intended architecture and known limits, read `/Users/alcatraz627/.claude/features/codex-adapter.md`.

`/Users/alcatraz627/.claude/adapters/codex/install.sh` refreshes the generated rule menu and skill links. An edit to `hooks.json` also changes the interactive hook trust hash; the owner must trust the new entry in Codex's `/hooks` menu. Do not duplicate hooks in a project config. Keep full gcc rules and conventions in their existing files and read them on demand.

When examining `~/.claude` structure, use the measure-first method in `/Users/alcatraz627/.claude/skills/gcc-map/SKILL.md`: inspect what is installed before trusting an index or an old map. The adapter map is read-only and on demand.
