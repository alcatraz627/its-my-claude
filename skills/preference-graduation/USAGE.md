# /preference-graduation Usage Guide

## What it does

Harvests recurring preference and vocabulary signals from the post-insight streams
(atone, affirm, i-dream, runtime-notes, checkpoints), dedupes them against what GLOSSARY
and memory already hold, and routes each fresh signal to its durable home after per-signal
confirmation. It is the runnable form of the manual pass in
`conventions/preference-graduation.md`.

## Usage

```
/preference-graduation [--days N]
```

| Argument   | Type         | Description                                           |
| ---------- | ------------ | ----------------------------------------------------- |
| `--days N` | optional int | Look-back window passed to the harvester (default 30) |

## Examples

### Example 1: routine triage

```
/preference-graduation
```

→ Runs the harvester over the last 30 days, reads the candidate file, drops already-baked
terms, and presents 3 fresh signals with a recommended home for each. After you approve
two of them, writes one `feedback_*` memory and one GLOSSARY term, and updates `MEMORY.md`.

### Example 2: wider window after a busy stretch

```
/preference-graduation --days 90
```

→ Widens the look-back to 90 days for a deeper sweep, useful after a long gap between runs.

### Example 3: nothing to graduate

```
/preference-graduation
```

→ The harvester surfaces no new preference language; the skill reports the honest empty
result and stops rather than inventing a signal.

## Caveats

- Surfacing is automated; graduating is not. The skill never bakes a signal without your
  per-item confirmation.
- Write-bar: a weak or one-off signal becomes a memory at most. Promotion to a `rules/*.md`
  mandate requires repeat occurrence or an explicit "bake this in".
- It respects the always-loaded budget: a new rule is auto-loaded every session, so it does
  not promote to a rule lightly, and it enforces the sub-200-line CLAUDE.md ceiling.
- It never commits or pushes. You commit.

## Dependencies

| Dependency                                   | Type          | Notes                                                        |
| -------------------------------------------- | ------------- | ------------------------------------------------------------ |
| `GUIDELINES.md`                              | Shared rules  | Read at start of every run                                   |
| `conventions/preference-graduation.md`       | Convention    | Source of truth: streams, routing table, write-bar           |
| `scripts/preference-harvest.sh`              | Script        | Surfaces candidates in Phase 1                               |
| `GLOSSARY.md`, `memory/global/`, `MEMORY.md` | Homes + index | Where graduated signals land                                 |
| `PLACEMENT.md`                               | Index         | Where a graduated rule goes, plus the tier and loading rules |
| `scripts/validate-triggers.sh`               | Script        | Frontmatter validation when a rule sub-file is added         |

## Tips

- Run it every few weeks, or when the user says "remember how I work" / "bake this in".
- Pairs with `/tag`: use `/tag` to file one specific thing now; use this to sweep the
  streams for patterns that accreted over many sessions.
- The scheduled harvester already drops a dated candidate file under `~/.claude/topics/`;
  this skill can consume that file instead of re-scanning.
