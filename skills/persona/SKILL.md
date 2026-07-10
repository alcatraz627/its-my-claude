---
name: persona
description: Adopt a working-mode persona (~/.claude/personas/) for the current task — pick by name or let the skill match one, load its role contract into context, and record the adoption to the efficacy log. The mechanical surface persona-suggest nudges point at; replaces "go read the persona file" (which telemetry shows never converts).
allowed-tools: Read, Bash, Grep, Glob
user-invokable: true
argument-hint: "[persona-name or task description]"
---

## Brief

Makes persona adoption a one-command, logged act. The activation substrate
(migration 0022) proved that only mechanically-logged personas get used:
dispatch personas (juror, skeptical-reviewer) accumulated 29 logged events in
three weeks while file-read adoption recorded zero, despite 81 suggest-hook
nudges. This skill is the fix: adopting through it both loads the persona and
writes the usage event, the same data-path pattern that makes /skeptical-review's
logging reliable.

## Procedure

### 1. Resolve the persona

- Argument names a persona (`/persona greybeard`) → use it directly.
- Argument is a task description (or empty) → list `~/.claude/personas/*.md`
  (skip `_proposed/`, `usage/`, `README.md`, `BUILD_LOG.md`), read each file's
  `role:` frontmatter line only, and pick the best match. If two are plausible,
  say which two and why you picked one — do not ask unless genuinely blocking.
- Dispatch-only personas (`juror`, `skeptical-reviewer`) are NOT adoptable —
  they belong to their owning flows (`atone-juror-dispatch.sh`,
  `/skeptical-review`). If matched, point at the owning flow instead.

### 2. Adopt it

Read the persona file IN FULL. State in one line to the user: which persona,
at which depth level (L1/L2/L3 per its Depth Levels section), and the one
behavior it changes for this task. Then work under it — its output
expectations and anti-patterns bind until the task ends or the user switches.

### 3. Record the adoption (mandatory — this is the step that makes the system honest)

```bash
bash ~/.claude/scripts/persona-log.sh record <name> --mode adopted \
  --session <sid8> --task "<one-line task>" --outcome unknown \
  --note "depth L<n>; adopted via /persona"
```

`<sid8>` is the first 8 characters of `$CLAUDE_CODE_SESSION_ID` (same
convention as /skeptical-review's step 5).

At task end (or session end), update the outcome honestly with a second
`record` call (`--outcome accepted|revised|discarded`) plus a one-line residue
note — what the persona actually changed. Never fabricate a success bit.

## Anti-patterns

- Adopting a persona for a task its own Anti-patterns section excludes.
- Stacking personas — one at a time; the strategic triad
  (closer/platform-builder/pragmatist) goes through /magi, not here.
- Recording `--outcome accepted` without naming what the persona changed.
