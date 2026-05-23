# /summarize-changes — Usage Guide

## What it does

Generates a categorized changelog of recent work, scoped by three orthogonal axes: **time**, **topic**, and **source**. Reads git AND the surrounding signal layer (WAL, checkpoints, runtime-notes, memory entries, recently-modified files, past-session transcripts), reads the actual code (not just diffs and not just commit subjects), reconciles signals across sources, and asks the user when sources disagree.

## Core idea

A "change" is not a commit. A change is a unit of work the user cares about — and that unit can be:

- spread across many commits with no clean delimiter,
- bundled inside one big commit alongside unrelated work,
- still uncommitted (in working tree / WAL / a checkpoint),
- discussed in runtime-notes from a previous session,
- or some combination of all of the above.

This skill treats git as **one signal source among many**.

## Usage

```
/summarize-changes [time-flag] [--topic <q>] [--path <p>] [--include-sources <csv>] [--format <k>]
```

### Time axis (pick one if non-interactive)

| Flag                | Meaning                                                                                  |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `--last <dur>`      | `30m` / `2h` / `1d` / `1w` / `session` (= since last WAL `session_start`)                |
| `--since <when>`    | Anything `git log --since` accepts — `"yesterday 9am"`, `"2026-05-01"`                   |
| `--between <a> <b>` | Two timestamps OR two refs (e.g. `--between v1.2 HEAD`)                                  |
| `--unstaged`        | Working-tree diff only                                                                   |
| `--staged`          | Index diff only                                                                          |
| `--vs <ref>`        | HEAD vs ref                                                                              |
| `--pr [#]`          | Current branch's PR or explicit `#NNN`                                                   |
| `--last-commits N`  | Explicit commit count — only when you really mean "exactly N commits", not "recent work" |

### Topic axis (optional, composes with time)

| Flag          | Meaning                                                                             |
| ------------- | ----------------------------------------------------------------------------------- |
| `--topic <q>` | Keyword / feature name / ticket id — used for filtering and ambient-source matching |
| `--path <p>`  | Path / glob — composes with `--topic`                                               |

### Source axis (where to read evidence from)

| Flag                      | Meaning                                                                                         |
| ------------------------- | ----------------------------------------------------------------------------------------------- |
| `--include-sources <csv>` | Subset of: `git,worktree,wal,runtime-notes,checkpoints,memory,recent-files,sessions`            |
| no flag                   | **Auto-detect** — include every source with data in the window (each pre-checked in the picker) |

### Format axis

| Flag           | Meaning                                                            |
| -------------- | ------------------------------------------------------------------ |
| `--format <k>` | `bullets` / `report` / `pr` / `markdown` / `html` / `conventional` |
| no flag        | Interactive `pick_one`                                             |

## Examples

### Example 1 — "What did I do today?" (multi-source)

```
/summarize-changes --last 1d --format report
```

→ Auto-detects every source with data in the last 24h: git commits + uncommitted working-tree + WAL events + any checkpoints written today + runtime-notes added today + recently-modified files. Cross-references them, classifies into Big/Medium/Small, reads the actual code for non-trivial entries, asks if any sources disagree, and prints a grouped report. **The uncommitted work shows up as its own entry, marked WIP — it would be invisible to plain `git log`.**

### Example 2 — Continuing from where I left off

```
/summarize-changes --last session --format bullets
```

→ Lower bound is the last `session_start` event in `.claude/wal.jsonl`. Useful right after `/clear` or after stepping away and coming back. The output naturally highlights both committed work and pending items captured in the most recent checkpoint.

### Example 3 — Topic-scoped across sources

```
/summarize-changes --last 1w --topic "auth" --format report
```

→ Last 7 days of work that touches authentication — pulls commits, runtime-notes mentions of "auth", checkpoint Goals containing "auth", and recently-modified files in `*/auth*` paths. Even if there are zero git commits matching, you'll still see the planning/discussion captured ambient sources.

### Example 4 — PR description that includes context git can't see

```
/summarize-changes --vs main --format pr
```

→ Diff `HEAD ↔ main`, plus any WAL/checkpoint/runtime-notes evidence about _why_ the work happened. Output includes a "Context not in this branch" subsection if ambient sources captured related work or constraints not visible in the diff.

### Example 5 — Release notes since last tag

```
/summarize-changes
# pick: "Since the last git tag"
# pick sources: git only
# pick format: markdown
```

→ Conventional release-notes use case where you _want_ git as the only source of truth.

### Example 6 — One commit, multiple distinct themes

```
/summarize-changes --last-commits 1 --format report
```

→ Reads the single most-recent commit, but if it touches multiple unrelated modules the report breaks it into separate entries by directory/theme. A 4000-line "misc fixes" commit emits 4–5 entries, not one. Conversely, a refactor + 5 caller-update commits collapse to one entry.

### Example 7 — Conflicting sources trigger a question

```
/summarize-changes --last 4h --format bullets
```

→ During Phase 6.5: the WAL has a `goal: "fixed task-claimer race"` event but no commit in the window touches the claimer file. The skill stops and asks:

```
Conflict:
  WAL @ 15:39 says: "fixed task-claimer race"
  But no commit touches lib/tasks/claimer.py.

  1. Treat WAL as authoritative — include as uncommitted fix
  2. Treat git as authoritative — drop the WAL signal
  3. Mark as ambiguous in output
  4. Investigate further
  5. Skip the entry
```

→ Whatever you pick is reflected in the output. The footer shows "Conflicts resolved: 1".

## Caveats

- **Cross-source reads cost more than `git log`.** Phase 3 prints a sizing summary and offers a coarse mode (diffstat-only) when the range is large.
- **`--last session` requires WAL.** Falls back to "last 4 hours" with a warning if WAL is missing or stale.
- **`/past-sessions` source is opt-in only** — it's slow and runs as a subagent. Don't include it for routine runs.
- **Bot filtering is on by default** across all sources, not just git.
- **Read-only by default.** The single exception is `gh pr edit --body-file` in the PR format, which requires explicit Phase 4a opt-in.
- **Auto-formatter / lockfile mass-changes are demoted** to a single line.
- **Binary files are listed but never read.**
- **Forbidden paths** (per GUIDELINES.md) are excluded from every source query — even if a recently-modified probe finds them.

## Dependencies

| Dependency                                     | Type        | Notes                                                             |
| ---------------------------------------------- | ----------- | ----------------------------------------------------------------- |
| `GUIDELINES.md`                                | Shared rule | Read at start of every run                                        |
| `git`                                          | CLI         | All git/worktree sources                                          |
| `gh`                                           | CLI         | Required for `--pr` and PR-source                                 |
| `jq`                                           | CLI         | Parses `.claude/wal.jsonl`                                        |
| Interactive Inputs MCP                         | MCP         | `pick_one`, `pick_many`, `text_input`, `pick_path`                |
| `~/.claude/skills/shared/wal-format.md`        | Spec        | WAL JSONL schema reference                                        |
| `_checkpoint.claude.md` (per project)          | File        | Read for "Goal / Pending Items" if checkpoints source is selected |
| `~/.claude/projects/<encoded-cwd>/memory/*.md` | Files       | Read if memory source selected                                    |
| `.claude/skills/runtime-notes.md`              | File        | Read if runtime-notes source selected                             |
| `/create-report`                               | Skill       | Chained when `--format html`                                      |
| `/past-sessions`                               | Skill       | Chained when `sessions` source is selected (slow, opt-in)         |
| `~/.claude/assets/reports/`                    | Dir         | Default output for markdown / html artifacts                      |

## Tips

- **Daily standup** — `/summarize-changes --last 1d --format bullets` (filter "My commits/events only" in Phase 2). The ambient sources mean WIP work shows up too.
- **Resuming after `/clear`** — `--last session` + `bullets`. WAL grounds the lower bound.
- **PR description for a sprawling refactor** — `--vs main --format pr`. The "Context not in this branch" subsection will surface why-this-shape decisions captured in checkpoints.
- **Release notes** — interactive, pick "Since the last git tag" + source = `git` only + format = `markdown`. Uncommitted/WAL noise is appropriately filtered.
- **Investigating a regression window** — `--between <good-sha> <bad-sha> --topic <suspected-area>`. The cross-source view often reveals an in-flight pivot (checkpoint Goal, runtime-notes insight) that wasn't a clean commit.
- **Composing axes** — every flag composes. `--last 1w --topic "cache" --path backend/ --format markdown` is valid and useful.
- **Skipping sources** — when you trust git as authoritative for the use case (release notes, PR description against main), pass `--include-sources git` to short-circuit ambient probes.
- **Skipping prompts** — combining `--last <dur>` + `--include-sources <csv>` + `--format <k>` makes the skill fully non-interactive (apart from Phase 6.5 ambiguity prompts, which only fire on actual conflicts).
