# /core-dump — Examples & Schemas

Companion to `SKILL.md`. Holds the visual-summary JSON schema and the
validation-example scenarios pulled out of the main procedure to keep it lean.
The load-bearing procedure lives in `SKILL.md`; this file is reference detail.

## Visual-summary JSON schema (Phase 4)

The shared renderer (`~/.claude/scripts/render/trace.sh`) reads a per-session
JSON file at `/tmp/core-dump-data-<session-id>.json`. Schema:

```json
{
  "session_id": "<session-id>",
  "timestamp": "<HUMAN datetime, e.g. Thu Aug 14 2026, 1:30 PM IST; never raw ISO>",
  "ipc": "<ipc alias, e.g. gcc-work>",
  "model": "<model name, e.g. claude-fable-5>",
  "emitted": ["<absolute path of every file this run wrote; renders as copyable file rows above the seal>"],
  "goal": "<1-line original goal from Phase 2.1>",
  "status": "<in-progress | blocked | complete>",
  "project_root": "<absolute project root; file rows render relative to it>",
  "files": [{ "path": "src/auth/login.ts", "change": "+12 / -3" }],
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

- **Give `path` project-relative and set `project_root`.** The renderer prints
  the root once in the header and keeps rows short, which is what buys the width
  the change counts need. It truncates from the left with a leading `…` when a
  path still overruns its computed column.
- Keep action summaries to roughly 60 chars. Longer ones wrap with a hanging
  indent rather than breaking the list.
- Omit a key, or give it an empty array, and its whole section disappears. There
  are no placeholder rows.
- `interrupts` are classified by prefix: `WARN:` renders as a caution, `NOTE:`
  as a neutral line, anything else as a hard objection.

The renderer keeps three regalia and picks one at random per render. Pin one
with `--theme a|b|c` or `TRACE_THEME`; override width with `--width N` (clamped
to 60..100). Colour is forced by default, since a skill's output goes through a
pipe where most tools strip it; `NO_COLOR` still wins. OSC 8 hyperlinks on file
rows sit behind `TRACE_LINKS=1`. It is macOS bash 3.2 compatible (no `mapfile`,
no `local -a`).

`/catchup` calls the same script with `--kind catchup` and a different key set;
that schema lives in `~/.claude/skills/catchup/SKILL.md` Phase 3.1.

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

The scenarios are executable, not prose. Run them:

```bash
bash ~/.claude/scripts/render/smoke.sh            # every scenario, all themes
bash ~/.claude/scripts/render/smoke.sh --mutate   # prove the checks can fail
```

The suite builds four inputs and renders each across three themes and three
widths, for both kinds:

| scenario | what it pins |
|---|---|
| full | A goal that wraps twice, a docket row that overruns, a path long enough to need left-truncation, and one interrupt of each severity. |
| empty | Every array empty. Sections must vanish, leaving a header and a seal with no rules between them. |
| sparse | Keys absent rather than empty. A caller that omits fields must not crash. |
| catchup | The three-tier briefing, including a constraint long enough to wrap under its own label. |

Two further checks run once each: the empty input must emit zero section rules,
and `NO_COLOR=1` must strip every escape byte rather than most of them.

Every structural line is measured against the requested width. A frame one
column short is exactly the defect this catches, and it is invisible to review
by eye: three of the five candidate designs drafted for this renderer shipped a
ragged border that nobody noticed until the columns were counted.

`--mutate` asserts a width four columns wider than the render, so the checks are
expected to go red. If they stay green, the suite is the bug. The 2 checks that
correctly stay green under mutation are the two that do not measure width.
