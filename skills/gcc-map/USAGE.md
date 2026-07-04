# /gcc-map Usage Guide

## What it does

Maps how instruction content actually reaches an agent in `~/.claude/` and the CLAUDE.md
doc graph. It measures ground truth first (the filesystem and the real load behavior),
reads the indices' self-description second, and treats every divergence between them as a
finding. It then runs a deterministic health battery and an unconstrained blindspot pass,
and writes a durable map under `assets/reports/`.

## Usage

```
/gcc-map [--deep]
```

| Argument | Type  | Description                                                                  |
| -------- | ----- | ---------------------------------------------------------------------------- |
| (none)   | light | One-agent inline pass: measure, diff, battery, plus an inline blindspot pass |
| `--deep` | flag  | Adds a subagent fan-out on diverse lenses plus a completeness critic         |

## Examples

### Example 1: routine health map

```
/gcc-map
```

→ Measures the load channels and the on-disk tree, diffs them against what CLAUDE.md and
the indices claim, runs the battery (orphans, broken links, staleness, always-loaded
budget, tier/paths drift), and refreshes the map with a "what changed since last run"
section.

### Example 2: deep audit before a cleanup

```
/gcc-map --deep
```

→ Same, plus a fan-out where each subagent takes a different lens (by-directory,
by-load-channel, by-cross-reference, by-naming-convention, by-recent-churn) so no single
frame dominates, then a completeness critic asks what was missed.

## Caveats

- Read-only on config. It diagnoses and writes a report to `assets/`; it never edits rules,
  features, conventions, or CLAUDE.md. Fixes go through `/tag`, `/migrate`, or a direct edit
  you approve.
- Ground-truth-first is deliberate: it will not pre-read the indices before measuring,
  because anchoring on the self-description is the blindspot it exists to avoid.
- The blindspot pass can promote a newly-found failure mode into next run's battery. The
  check list is meant to evolve, not stay fixed.
- It logs what it did not cover rather than implying full coverage.

## Dependencies

| Dependency                                                 | Type         | Notes                                                        |
| ---------------------------------------------------------- | ------------ | ------------------------------------------------------------ |
| `GUIDELINES.md`                                            | Shared rules | Read at start of every run                                   |
| CLAUDE.md, LOOKUP, FOLDERS, PLACEMENT, NAMESPACE, GLOSSARY | Indices      | The claimed model read in Phase 2                            |
| `scripts/folders-index.sh`, `scripts/validate-triggers.sh` | Scripts      | Derived-view regen + frontmatter validation                  |
| `assets/reports/<date>-gcc-structure-map/MAP.md`           | Artifact     | The durable map it writes and refreshes                      |
| `rules/structural-claim-without-reading-code.md`           | Rule         | Every finding must be grounded in file:line or a measurement |

## Tips

- Run the light pass regularly; reserve `--deep` for before a real cleanup or after a big
  structural change.
- Pairs with `/tag` and `/migrate`: `gcc-map` finds the drift, those two fix it.
- The v1 map at `assets/reports/20260704-gcc-structure-map/MAP.md` is the reference output
  and the origin of the ground-truth-first method.
