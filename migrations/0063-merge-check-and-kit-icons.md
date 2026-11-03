---
migration: 0063
title: Add the ready-to-merge check, the screenshot nudge and the kit's icons
session: catch-ipc-7e@2026-11-03
status: complete
date: 2026-11-03
---

# Migration 0063: Ready-to-merge check, screenshot nudge, kit icons

## Why

The owner approved these on decision pages gcc-next-20261103 and hub-direction-20261103. Rulings are in `assets/reports/20261103-proposal-review/owner-answers.md`. Reports are in `assets/reports/20261103-gcc-build/`.

## What changes

| From | To | Why |
|---|---|---|
| Nothing checks every merge precondition | `scripts/pr/ready-to-merge.py` | Three recorded "told the owner it was ready" mistakes |
| No note on a ready claim | `scripts/hooks/ready-claim-note.sh` in `stop-gates.txt` | D2a: advisory, never blocks |
| No nudge on UI pull requests | `scripts/hooks/ui-pr-screenshot-nudge.sh` in `settings.json` | D3a: says to skip when not worth it or not easy |
| `pagekit.page()` had no favicon, meta tags or bar icon | `icon_name` and `description`, plus an icon sprite | The owner's list |
| A word for the theme switch, and a bar in a different colour | One icon, and the bar on the page background | "EVery new page made by claude has a different visual display" |
| No plain button or tooltip in the kit | `.kit-btn`, `.kit-icon-only`, `data-tip` | The owner's list |
| `directions.py` had no links reader | Optional `links` column and `links --json` | D4b: optional and advisory |

## What does NOT change

- Pages already built keep their look until rebuilt.
- Decision pages, decks and usage-flame keep their own toggles, for now.
- Neither new hook blocks.

## Verification

- [x] `python3 scripts/hooks/audit/run-hook-tests.py` after wiring: 91 suites, 1 failed. The failure is `authority-claim-note.test.sh`, from unfinished ipc work that is not part of this migration.
- [x] `bash scripts/pr/ready-to-merge.test.sh`: 32 pass. `bash scripts/hooks/ready-claim-note.test.sh`: 28 pass.
- [x] `check_page.py` on the kit demo and the hub: PASS, no notes.
- [ ] UNCONFIRMED: neither new hook has fired in a live session. A READY verdict was seen only on a recorded response.

## Indices updated

- [x] `MIGRATIONS.md` row added
- [x] `FOLDERS.md`: not affected, `scripts/pr/` is not top-level
- [x] `NAMESPACE.md`: not affected
- [x] `LOOKUP.md`: not affected, the brief's row already points here
- [x] `rules/00-index.md`: not affected

## Rollback

Mute: `touch ~/.claude/.no-ui-pr-screenshot-nudge`. Remove the `ready-claim-note.sh` line from `stop-gates.txt` and the nudge's block from `settings.json` to unwire them. The kit changes revert with the commit.
