---
migration: 0057
title: The live-session task pin moves out of ~/.claude/tasks
session: gcc-work f32c64bc@2026-09-04
status: complete
date: 2026-09-04
---

# Migration 0057: The live-session task pin moves out of ~/.claude/tasks

## Why

The pin that maps a live session to its task store kept disappearing, and the
owner paid for it on every fleet wake: `/tasks` refused, and the hinter asked
him to identify his own store from a candidate list. Measured across four wakes
on 2026-09-04. Each time the pin was written, confirmed on disk by reading it
back, and read correctly by the next wake's header, which printed
`resolved by pin`. By the wake after that it was gone.

Nothing in this repo removes it. All four scripts naming the directory were
read, every hook registered in settings.json was checked, and a full-tree grep
finds only those scripts. Pinning fresh and then running each task-table command
in turn removed none of them.

What the evidence does support is a difference by LOCATION, not by code:

- Sixty pins for dead sessions have sat in that directory since August.
- `tasks-view.json`, which lives outside `tasks/`, is untouched since 19 August.
- Only the entry named for the LIVE session vanishes, within one wake interval.

`~/.claude/tasks` is the harness's own Task-tool storage, and a file inside it
named exactly the live session id reads as harness session state to anything
cleaning up after a session. So the fix does not depend on naming the culprit,
which was not findable with the instruments available here. It moves the pin
somewhere nothing else claims.

## What changes

| From | To | Why |
|---|---|---|
| pin at `~/.claude/tasks/.live-session-map/<live8>` | pin at `~/.claude/tasks-pins/<live8>` | outside the harness-managed directory, beside `tasks-view.json`, which demonstrably survives |
| one cache location, read and written | new location written; BOTH read, old one labelled `pin (legacy location)` | an existing pin must not stop working the day this lands |
| `resolve-store.sh` cached-hit reads one dir | loops new then legacy | same reason, and it is the rung `task.sh` and `task-table.sh` both fall through to |

## Files

| File | What changed |
|---|---|
| `scripts/task-table/task-table.sh` | `PIN_DIR`, `PIN_DIR_LEGACY`, one extra resolution rung |
| `scripts/task-table/task.sh` | `PINS`, `PINS_LEGACY`, one extra rung in `resolve_store` |
| `scripts/task-table/resolve-store.sh` | `CACHE`, `CACHE_LEGACY`, the cached-hit loop |
| `scripts/task-table/pin-location.test.sh` | NEW, 12 cases |
| `scripts/task-table/resolve-store.test.sh` | cache path corrected, see below |

## Verification

`pin-location.test.sh`, 12 cases: the pin lands outside `tasks/` and not inside
it, all three readers resolve from it, a pin left in the old place still
resolves and says it is legacy, and a pin naming a deleted store is refused
rather than rendered. Mutation-proved: disabling the legacy rung turns 2 red.

Full task-table sweep green afterwards, except the two reds that predate this
work (`task-table.test.sh` 53/3 on goal-batch grouping, unrelated).

## A self-inflicted false green, caught and recorded

`resolve-store.test.sh` defined its own `CACHE` as the old path. After the move,
its case that clears the cache before a bare run was clearing the wrong
directory: the live pin survived, the run resolved silently, and a case that had
been failing for days went green with nothing fixed. That is the shape this
whole session keeps meeting, an instrument measuring something adjacent to its
claim, and it arrived here by my own edit.

Fixing the path turned the case red again and exposed a second, older defect in
it. The case asserts "a bare run says nothing on stderr" but deletes the cache
first, so the run cannot resolve and correctly prints its refusal. The script's
own comment says failing closed without a word is the defect. The test
contradicted the code it was testing. It now seeds a resolvable state and
asserts silence there, plus the missing other half: a run that cannot resolve
must speak. `resolve-store.test.sh` is 7/0.

## Rollback

Revert the four scripts. Any pin written under the new path is then unread, so
re-pin once with `task-table.sh --pin <sid8>`. No data is stored in these files
beyond an 8-character store id, so nothing is lost either direction.
