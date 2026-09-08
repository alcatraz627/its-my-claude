---
migration: 0059
title: Task stores gain a .goals sidecar for goal-level fields (direction, when)
session: guard-bad-e3@2026-09-08
status: complete
date: 2026-09-08
---

# Migration 0059: the `.goals` sidecar in a task store

## Why

The store could not say which direction a goal serves or what check closes it;
only `directions.md` could, on paper. The owner's decision page `unblock-0908`
def-01 (submitted unflipped) ruled P3 built now, additive. Row `#24` in store
`session-cd22422c`.

## What changes

| From | To | Why |
|---|---|---|
| a goal is only a `metadata.goal` string on rows | the same, plus `<store>/.goals`: JSON keyed by goal text, `{direction, when, set_at}` | a goal-level fact on a row invites rows to disagree (the `batch_at` problem one level up) |
| no write path for goal-level fields | `task.sh goal <id\|"text"> [--direction D] [--when W]` | an id resolves to its row's goal; the goal must be one some row carries |
| the render shows title, meter, milestones, rows | plus `🧭 <direction>` above the title (once per run of boxes sharing it) and `│  ✅ when: <check>` under the meter, both only when set | additive: a store with no sidecar renders exactly as before, so the frozen goldens did not move |
| `--json` has no goal-level data | `--json` carries `goals: {<text>: {direction, when, set_at}}` | |
| the renderer's row loader read every `*.json` in the store, dotfiles included (pathlib) | it skips names starting with `.` | the first sidecar was `.goals.json` and was read as a row (KeyError: status); the name lost its suffix AND the loader skips dotfiles |

## What does NOT change

- Row files, their shape, and every verb except the new `goal`.
- The `.project` stamp (migration 0057's sibling sidecar).
- `glob.glob` readers (`stop-sync`, `writeback`, `checks.py`, `stamp-stores`,
  `freeze.py`) never matched dotfiles; `find -name '*.json'` counters in
  `store-backup.sh` do not match `.goals`.

## Verification

- [x] `bash scripts/task-table/task.test.sh` green (the P3 section: write, resolve by id, clear, show, three refusals, lock released, suffix check, render, json)
- [x] `bash scripts/task-table/goal-box.test.sh` green (case 26: both lines, sharing, one-row collapse, broken sidecar, four mutations incl. the dotfile-as-row one and the unpriced-box sweep)
- [x] `bash scripts/task-table/real-store.test.sh` green: goldens unchanged
- [x] the real store `session-cd22422c` renders the direction and when at height 43/44

## Indices updated

- [x] `MIGRATIONS.md` row added
- [ ] `FOLDERS.md`: not affected (no new directory)
- [ ] `NAMESPACE.md`: not affected (same cluster, `std::claude::tasks`)
- [x] `LOOKUP.md`: not affected; the verb is documented in `skills/tasks/SKILL.md`
- [ ] `rules/00-index.md` / `skills/00-index.md`: not affected

## Rollback

```bash
trash ~/.claude/tasks/session-*/.goals
git -C ~/.claude checkout HEAD -- scripts/task-table/task.sh scripts/task-table/task-table.sh
```

Rollback if a store reader that globs dotfiles starts choking on `.goals`.

## Notes / followups

- The `✅` glyph is the owner's own legend for "accepted when" (`directions.md`)
  and is also the done-row ball. The test detectors that took "a ball at the row
  position" as a row were tightened to ball, twin, id (goal-box.test.sh case 18).
