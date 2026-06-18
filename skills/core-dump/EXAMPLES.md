# /core-dump — Examples & Schemas

Companion to `SKILL.md`. Holds the visual-summary JSON schema and the
validation-example scenarios pulled out of the main procedure to keep it lean.
The load-bearing procedure lives in `SKILL.md`; this file is reference detail.

## Visual-summary JSON schema (Phase 4)

The renderer (`render-visual.sh`) reads a per-session JSON file at
`/tmp/core-dump-data-<session-id>.json`. Schema:

```json
{
  "session_id": "<session-id>",
  "timestamp": "<ISO timestamp>",
  "goal": "<1-line original goal from Phase 2.1>",
  "status": "<in-progress | blocked | complete>",
  "expects": "<what user expects next, from Phase 2.3>",
  "files": [{ "path": ".../path/to/file", "change": "+N / -N" }],
  "pipeline": ["next action 1", "next action 2"],
  "interrupts": ["BLOCKED: ...", "WARN: ...", "NOTE: ..."],
  "stack_trace": ["action 1 summary", "action 2 summary"],
  "coprocessor": {
    "worked": ["what worked well"],
    "failed": ["what didn't work"]
  },
  "checkpoint_path": "<resolved checkpoint filename>"
}
```

Authoring notes:

- Truncate long file paths with a `.../` prefix (e.g. `.../components/Nav.tsx`).
- Keep action summaries to ~60 chars.
- Use empty arrays `[]` for sections with no content — the renderer handles all
  empty states (`(none)` / `(no files modified)` placeholders).

The renderer compresses overflow automatically: >6 files show the first 6 then
`... and N more`; >8 stack actions show first 3, `... (N more)`, last 3;
interrupt borders turn red when interrupts are present. It is macOS bash 3.2
compatible (no `mapfile`, no `local -a`).

## Workspace-doc proposal schema (Phase 3.7)

```json
{
  "todos_done":    [<usually empty — completed tasks sync into the block automatically>],
  "todos_new":     [<only human-area todos NOT present in the live Task list>],
  "notes_append":  [<2-3 most load-bearing observations from Phase 2.5>],
  "doclinks_new":  [<URLs / file refs cited this session, deduped>],
  "decisions_new": [<load-bearing choices from Phase 2.5 "What worked / didn't">]
}
```

The `## Todos` machine block (between `<!-- sync:auto:start -->` and
`<!-- sync:auto:end -->`) is rewritten by the `stop-sync` hook every turn from
the live Task list. Don't propose todos into it — they'd be overwritten. Only
propose `todos_new` for genuine human-area items the Task list doesn't track.

## Validation scenarios

Run `render-visual.sh` against the test JSON files in
`/tmp/test-core-dump-*.json` and confirm each renders without errors.

### Full session (happy path)

Standard `/core-dump` after a complete bug-fix session. All 6 sections
populated with moderate content; 3 files modified, 5 stack-trace entries, no
blockers.

- JSON written to `/tmp/core-dump-data-<session-id>.json` with all fields populated
- `render-visual.sh` exits 0 and renders all 6 styled panels (REGISTERS, CACHE,
  PIPELINE, INTERRUPTS, STACK TRACE, COPROCESSOR)
- Header panel shows session ID and timestamp
- Footer panel shows checkpoint path and `Resume: /catchup`
- Checkpoint file written and formatted with Prettier (Phase 3.3)

### Empty / minimal session

`/core-dump` invoked immediately after `/clear` with no meaningful work done.
All sections present but with placeholder content.

- REGISTERS shows `(no work performed)` for Goal
- CACHE shows `(no files modified)` placeholder
- STACK TRACE shows `(no actions taken)` placeholder
- Renderer handles empty arrays without crashing (no unbound-variable errors)
- Visual is not skipped — a minimal visual is always produced

### Many files (>6 in CACHE)

Refactoring session that touched 10+ files. CACHE must show the top 6 with
overflow.

- First 6 file entries shown with `├─` tree prefix
- Last line is `└─ ... and N more` with the correct count
- Long paths truncated with `.../` prefix in the JSON
- Dot-leaders connect file names to change annotations

### Long stack trace (>8 actions)

Large feature session with 12+ agent actions. STACK TRACE compresses: first 3 +
`... (N more)` + last 3.

- First 3 actions shown with `├─` prefix
- Middle line is `├─ ... (N more)` with an accurate omitted count
- Last 3 actions shown, the final one with `└─` prefix
- Total visible lines = 7 (3 + ellipsis + 3), regardless of actual action count

### Active blockers (INTERRUPTS populated)

Debugging session blocked on an external dependency. INTERRUPTS has 3 items
(BLOCKED, WARN, NOTE); status is `blocked`.

- REGISTERS Status shows `blocked`
- INTERRUPTS panel border turns red (border-foreground 1)
- All 3 interrupt items shown with `├─` / `└─` tree prefixes
- BLOCKED/WARN/NOTE prefixes are visible and not truncated
