---
migration: 0062
title: Deliver the UI brief by hook and make pages follow the OS theme
session: catch-ipc-7e@2026-11-03
status: complete
date: 2026-11-03
---

# Migration 0062: Deliver the UI brief by hook

## Why

UI guidance existed but nothing delivered it. The service hub's builder read only `conventions/pages.md`, and opened the design guide after the owner rejected the page. Executes prop-20261101-151317-eb. Audit: `assets/reports/20261103-ui-guidance-audit/audit.md`.

## What changes

| From | To | Why |
|---|---|---|
| No short UI brief | `conventions/ui-brief.md` | One page an agent will actually read, each rule with a check |
| No hook named any UI guide | `scripts/hooks/ui-brief-nudge.sh`, PreToolUse on Edit, Write and MultiEdit | Fires once per project per agent, sub-agents included |
| Internal-tools ruling in the `~/.claude` project memory | `memory/global/feedback_internal-tools-get-real-ui.md` | Sessions in other repos never saw it |
| Kit pages started dark whatever the OS | `kit.js` and `pagekit.py` follow the OS until the reader chooses | `pages.md` contradicted `visual-design.md`; the latter is the later ruling |
| `check_page.py` reported failures only | It also prints `notes`, which never fail the run | Reports a page ignoring the OS theme without failing older pages |
| Design kit named at `docs/design-kit.md` | `docs/dev/design-kit.md` | The path had gone stale |

## What does NOT change

- The stop-side check, `ui-verified-stop.py`, is unchanged.
- Existing built pages keep their theme until rebuilt, because the kit is inlined.
- `/build-ui` keeps its process; it gains one read at Step 0.
- The nudge never blocks.

## Verification

- [x] `bash scripts/hooks/ui-brief-nudge.test.sh`: 19 of 19.
- [x] `python3 scripts/hooks/audit/run-hook-tests.py`: 87 suites, 0 failed, 0 rows leaked.
- [x] A real headless `claude -p` session writing a `.css` file named `ui-brief.md` from the hook's context.
- [x] `jq empty settings.json` passes.
- [x] `check_page.py` on the hub: PASS, no notes.
- [x] `validate-triggers.sh`: the 12 remaining errors are in files this migration did not touch.

## Indices updated

- [x] `MIGRATIONS.md` row added
- [x] `FOLDERS.md`: not affected, no top-level directory added
- [x] `NAMESPACE.md`: not affected, no part added or retired
- [x] `LOOKUP.md`: row added for `conventions/ui-brief.md`
- [x] `rules/00-index.md`: not affected, no rule added or moved

## Rollback

Mute without reverting: `touch ~/.claude/.no-ui-brief-nudge`. To remove it, delete the hook's block from `settings.json`, then trash the hook and its test. To restore a dark default, revert `applyTheme(readTheme() || osTheme())` in `scripts/pages/kit.js` and the `THEME_BEFORE_PAINT` line in `scripts/pages/pagekit.py`.

Consider rollback if the nudge fires on files with no UI, or if the owner prefers kit pages to stay dark on a light OS.

## Notes / followups

- The hook has no ledger row (`audit/no-ledger.txt`), so judge it by on-sight rejections, not fire counts.
- `/bloop` does not name the brief. A plan written before any UI edit does not trigger the hook.
