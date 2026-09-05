---
name: gcc-map
description: Maps how instruction content actually loads into an agent and the CLAUDE.md doc graph, measuring ground truth first and diffing it against what the indices claim, then runs a deterministic health battery (orphans, broken links, staleness, always-loaded budget, tier/paths drift) plus an unconstrained blindspot pass, and writes a durable map under assets/reports/.
argument-hint: "[--deep]"
user-invocable: true
disable-model-invocation: true
context: fork
allowed-tools: Read, Grep, Glob, Bash, Write, Task
---

## Brief

Produces a durable, evidence-grounded map of the `~/.claude/` global config: what actually
reaches an agent at session start, the shape of the doc graph that unfolds from CLAUDE.md,
and where that structure is durable versus where it leaks. It is the repeatable form of the
one-off map at `assets/reports/20260704-gcc-structure-map/MAP.md`.

The defining constraint of this skill is that a fixed checklist becomes a blindspot. So it
measures ground truth (the filesystem and the real load behavior) BEFORE it reads what the
indices claim, treats every divergence between the two as a finding, and always runs an
open-ended pass whose whole job is to catch what the deterministic checks were not designed
to see. The battery is a floor, never a ceiling.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules (forbidden paths, retry logic, tool
preferences, verbosity, timeouts, post-run insights, and the file lock protocol) for the
entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

Do NOT pre-read the indices (CLAUDE.md, LOOKUP, FOLDERS, PLACEMENT, NAMESPACE, GLOSSARY)
before Phase 2. Reading them first anchors you on the config's self-description, which is
the exact failure this skill exists to avoid.

## Usage

```
/gcc-map            light pass: measure, diff, run the battery + blindspot pass inline
/gcc-map --deep     add a fan-out: diverse-lens subagents + a completeness critic
```

| Argument | Type  | Meaning                                                                          |
| -------- | ----- | -------------------------------------------------------------------------------- |
| (none)   | light | One-agent pass; fast; the deterministic checks plus an inline blindspot pass     |
| `--deep` | flag  | Fan out subagents on different lenses, then a completeness critic; more thorough |

## Phase 1: Ground truth, measured first

Establish what is real before reading any claim about it.

1. **What actually loads.** Enumerate the load channels empirically: native CLAUDE.md,
   the native `rules/` autoload, `MEMORY.md`, SessionStart injectors, UserPromptSubmit
   injectors. Quantify each (files, lines, rough tokens). Do not assume; check the actual
   mechanism (grep for `@`-imports, read the SessionStart hook wiring in settings.json,
   confirm the framing of what appears in context). If you cannot prove a mechanism, say so.
2. **What actually exists.** Census the full tree: every `rules/`, `features/`,
   `conventions/` file, the indices, `memory/`, `scripts/`, `skills/`. Sizes and counts
   from disk, not from a doc.
3. Record this empirical structure as the source of truth for the rest of the run.

## Phase 2: The claimed model, read second

Now read the indices and extract what they CLAIM: CLAUDE.md (the router + tiers), LOOKUP
(the address book), FOLDERS (per-dir owner + census), PLACEMENT (category x tier + the
loading reality), NAMESPACE (clusters), GLOSSARY (terms). Extract the claimed graph:
what points to what, what tier each thing claims, what each index says exists.

## Phase 3: Diverge (the primary finding source)

Diff empirical (Phase 1) against claimed (Phase 2). Every divergence is a finding:

- **Orphans:** files that exist but no index references.
- **Phantoms:** index rows or CLAUDE.md pointers to files that do not exist.
- **Miscategorized:** a file whose location contradicts its claimed category.
- **Stale derived views:** a census or derived list that disagrees with disk.
- **Load-vs-claim mismatches:** the tier a file claims versus how it actually loads (for
  example a Tier-2 rule that the platform autoloads every session anyway).

Divergences outrank the battery: they are where the config lies to itself.

## Phase 4: The deterministic battery (the floor)

Run these repeatable checks. They are necessary, not sufficient.

1. **Link graph + integrity:** every doc's outbound refs; flag orphans and broken links.
2. **Staleness:** frontmatter where `updated + stale_after_days < today`.
3. **Always-loaded budget:** measured token footprint of everything that loads every
   session; trend it against the last run if a prior map exists.
4. **Tier / paths drift:** rules with a `tier:` implying on-demand but no `paths:` lever,
   so they load unconditionally; and rules whose `paths:` do not match their real scope.
5. **Derived-view freshness:** each auto-generated view versus its source (regenerate to
   compare; never hand-edit). Compare AGE too, not only rows: a view whose stamp is older
   than the newest mtime in the tree it describes is stale even when its row count
   happens to match (FOLDERS.md went 51 days this way, v4 D4).
6. **Glob-loader hygiene:** for every loader that picks up files by glob rather than by
   name (`hint-injector.sh` over `hinters/*.sh`, any `for f in dir/*` in a hook), list the
   files it will actually execute and flag non-conforming names: `*.test.sh`, backups,
   editor swaps, anything with the execute bit that was never registered. Four executable
   test suites ran on every prompt for 16 days before v4 caught it (D1).
7. **Present-sentinel inventory:** list every `.no-*` / `*-off` mute file present at
   `~/.claude/`, then for each find the rule or feature doc that promises the gate it
   mutes. A rule that says "enforced by hook X" while X's mute file is present is a
   divergence; report the pair and the sentinel's age (v4 D2: five present, two muting
   always-loaded rules).
8. **Declared thresholds:** grep the docs for every self-declared numeric cap (line
   caps, entry caps, day limits, "keep last N", byte thresholds) and measure each
   against disk. v3 proposed this; v4 ran it and found 8 of 12 in breach (D3, D7,
   `runtime-notes.md` caps). Report as declared / measured / breach.
9. **Context-vs-disk, by content:** the set check (files in context equal files without
   `paths:` on disk) passes even when a file was edited after the session started.
   Hash or diff one or two always-on files against the copy in context; report which
   snapshot (HEAD vs working tree) every count in the map was taken from (critic A1,
   A2, C4).

## Phase 5: The blindspot pass (the ceiling, anti-pre-fab)

This phase exists because Phases 3 and 4 can only find what they were built to find. Here
you deliberately look for what they cannot.

Ask, unconstrained by the battery:

- What exists in the tree that no phase above touched or explained?
- What is surprising, inconsistent, or undocumented that is not on any checklist?
- What pattern or convention is present that the check battery was not designed to see?
- Is the battery itself still the right set? What new failure mode has emerged since the
  checks were written that nothing here checks for? Name it; it becomes next run's check.

For `--deep`, fan out subagents, each with a DISTINCT lens so no single frame dominates
(by-directory, by-load-channel, by-cross-reference, by-naming-convention, by-recent-churn).
Each is blind to the others. Then run one completeness critic over all findings asking
"what modality was not run, what claim is unverified, what did we cap silently?" Every
finding here must be grounded in a real file:line or a real measurement, not a hunch (see
`rules/structural-claim-without-reading-code.md`).

If you bound coverage anywhere (sampled a subset, capped a fan-out), LOG what you dropped.
Silent truncation reads as "covered everything" when it did not.

## Phase 6: Synthesize and write the durable map

1. Rank findings by severity, divergences first.
2. Refresh the assessment (good and durable / messy / inefficient) from THIS run's
   evidence, not from the prior map's text.
3. Write the map to `~/.claude/assets/reports/<YYYYMMDD>-gcc-structure-map/MAP.md` (update
   the living one, or a dated sibling if you want to preserve history), with a short "what
   changed since last run" section when a prior map exists.
4. Render-check the output (frontmatter closes, headings intact, no em-dashes, ASCII
   diagrams inside code fences and under 78 columns).
5. Print the GUIDELINES completion block and the post-run insight entry, and state plainly
   what this run did NOT cover.

## When the other skill is the right one

`/gcc-explore` is this skill's sibling, and neither should pretend the other is not
sitting right there. Route out loud whenever the user's real question fits it better:

- **Send to `/gcc-explore`** when the question is orientation rather than diagnosis:
  what is this config, which way is it drifting, what loops keep it alive, walk me
  through it. It consumes this map's output plus the vitals EKG, renders three
  panels, and holds a dig-deeper conversation. It never re-scans, and it never
  adjudicates a finding.
- **A mix is often right.** "Map it, then explore what changed" is a normal two-step,
  and so is "explore first to find the area, then map that area deeply". Offer the
  pairing instead of leaving the user to discover it.

## Notes

- **Why measure before reading.** Anchoring on the docs' self-description is how the v1 map
  would have missed the native rules-autoload. Ground truth first is the load-bearing
  design choice, not a stylistic one.
- **The battery evolves.** Phase 5 can promote a newly-found failure mode into a Phase 4
  check on the next run. A static battery is itself a blindspot.
- **Read-only on config; writes only to `assets/`.** This skill diagnoses; it does not fix.
  Fixes go through `/tag`, `/migrate`, or a direct edit the user approves.
- Never commit or push. The map is a working-tree artifact; the user commits.
