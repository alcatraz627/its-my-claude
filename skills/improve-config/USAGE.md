# /improve-config — Usage Guide

## What it does

Audits the entire `frontend/.claude/` directory — skills, guidelines, personal config, and
settings — identifies improvements across all files (consolidation, extraction, dead
instruction removal, guideline promotion), applies user-approved changes, and optionally
generates a summary HTML report.

## Usage

```
/improve-config [--scope=<focus-area>] [--skip=<skill,...>] [--dry-run] [notes...]
```

| Argument               | Type     | Description                                                                                                                      |
| ---------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `--scope=<focus-area>` | optional | Short description of which improvement aspects to prioritize (e.g. `--scope="consolidate shared instructions"`).                 |
| `--skip=<skill,...>`   | optional | Comma-separated skills or filenames to exclude from the audit (e.g. `--skip=create-report,arch-qa`).                             |
| `--dry-run`            | optional | Run the full analysis and print the improvement plan, but write no files. Exits after the user approval step.                    |
| `notes...`             | optional | Additional free-form guidance shaping the improvement run (e.g. "don't remove edge case handling", "prefer splits over merges"). |

## Examples

### Example 1: Cross-cutting change across all skills

```
/improve-config 'add a calculator tool to all my skills'
```

Identifies every skill that would benefit from the new tool, applies a tailored inclusion
to each (not a blanket copy-paste), and outputs a per-skill change log showing exactly
what was added and why.

### Example 2: Consolidation analysis

```
/improve-config 'list the skills that are hyper specific and can be folded into other skills'
```

Runs a deep comparative analysis across all skills, scores each on specificity vs.
generality, and produces a ranked consolidation plan with rationale — then applies approved
merges.

### Example 3: Global proofread

```
/improve-config proofread all the skills and improve whatever seems vague or obsolete
```

Global proofreading pass across all skill files; surfaces vague phrasing, stale
references, and outdated instructions with per-skill diffs, then applies approved rewrites.

### Example 4: Workflow composition + skill building

```
/improve-config 'using existing skills, here is a task: <description> — compose a workflow and list any missing skills, then build them'
```

Maps the task onto existing skills, designs a multi-skill execution workflow, identifies
capability gaps, and guides the user through building each missing skill interactively via
`/create-skill`.

## Caveats

- Changes are never applied without your approval — the skill prints a full categorized
  change list and asks which items to apply before writing anything.
- `--dry-run` exits cleanly after the approval step with no file writes — safe to use for
  previewing any large or uncertain improvement run.
- Dead instruction removals are conservative: instructions that handle edge cases not
  covered elsewhere are never removed, even if they appear redundant at first glance.
- When `skill-extraction` items invoke `/create-skill`, the wizard runs interactively — you
  will answer the standard Q&A questions for each new skill.
- Operates strictly within `frontend/.claude/` — the rest of the project is readable for
  context but never written to. `../backend/.claude/` is always read-only.

## Dependencies

| Dependency         | Type          | Notes                                                        |
| ------------------ | ------------- | ------------------------------------------------------------ |
| `GUIDELINES.md`    | Shared rules  | Read at start of every run; governs all file lock usage      |
| `runtime-notes.md` | Run log       | Read for context; updated with post-run entry after each run |
| `/project-index`   | Skill         | Invoked in Phase 1 for codebase context                      |
| `/user-config`     | Skill         | Invoked in Phase 1 for config + skill overview               |
| `/create-skill`    | Skill         | Invoked during Phase 3 for skill-extraction improvements     |
| `/create-report`   | Skill         | Optionally invoked in Phase 4 to generate HTML summary       |
| `lock-file.sh`     | Shared script | Used for every file write to prevent concurrent access       |
| `prettier`         | CLI tool      | Formats files after writing; available via `npx prettier`    |

## Tips

- Use `--dry-run` first on any large run — review the full improvement list before
  committing to changes.
- `--scope` is the fastest way to focus a run: `--scope="reduce verbosity"` or
  `--scope="extract reusable logic"` meaningfully weights the analysis.
- Combine `--skip` with a focused `--scope` for surgical runs:
  `/improve-config --scope="guideline promotion" --skip=create-report`
- After the run, use `/user-config` to review the updated configuration and verify changes
  look right in context.
- Run `/improve-config` after updating GUIDELINES.md to propagate new conventions to all
  existing skills automatically.
