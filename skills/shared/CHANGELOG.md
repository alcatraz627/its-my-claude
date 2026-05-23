# Changelog

## 0.2.0 — 2026-04-17

- **Label rename:** `std::claude` → `std::claude::shared` (Phase 1 of Migration 0001, `~/.claude/migrations/0001-namespace-introduction.md`)
- Library and path unchanged (`~/.claude/skills/shared/`); no code changes, no API changes
- Updates callsites in `CLAUDE.md`, `skills/GUIDELINES.md`, `skills/banner/SKILL.md`, and the project memory reference
- Rationale: make room for sibling clusters under `std::claude::` (`::code`, `::scripts`, `::skills`, etc.)

## 0.1.1 — 2026-04-06

- Fix `banner.py` `_sep()` overflow for narrow widths (<56 chars) — proportional fill distribution
- Add `test_std.py` (41 tests) and `test_scripts.sh` (13 tests) — automated test suites
- Update `/banner` skill to use canonical package import path
- Add `## std::claude` section to CLAUDE.md and GUIDELINES.md for discoverability

## 0.1.0 — 2026-04-06

Initial formalization of std::claude.

- `banner.py`: Terminal banner renderer (4 themes, JSON config, CLI, verify mode)
- `lock-file.sh`: Write-priority file locking with stale detection and cleanup
- `prepend-runtime-note.sh`: Atomic prepend to runtime-notes.md
- `check-path.sh`: Forbidden path validation against deny list
- `log-run.sh`: Timestamped run logging
- `__init__.py`: Python package init with re-exports
- `VERSION`: Semver tracking
- `README.md`: Full API reference (replaces NOTES.md)
- 7 reference docs: asset-management, bash-gotchas, doc-naming, gum-guide, mcp-config, safe-delete, wal-format
