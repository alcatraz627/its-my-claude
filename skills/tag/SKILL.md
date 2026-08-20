---
name: tag
description: Captures something worth keeping (a rule, convention, feature doc, glossary term, code snapshot, or note) and files it into the ~/.claude global config at its correct home per PLACEMENT.md, updates every index and cross-reference, and promotes it into CLAUDE.md's always-loaded core only when the tier heuristics justify it.
argument-hint: '[target | "concept"]'
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

## Brief

Point at something worth enshrining and `/tag` files it into `~/.claude/` correctly. It resolves the target, works out the right home via the PLACEMENT two-axis logic, confirms the plan with you, writes the item with proper frontmatter, and updates every index and pointer that must reference it. Content lives in exactly one canonical home; every other location gets a pointer, not a copy. It promotes an item into CLAUDE.md's always-loaded core only when the tier heuristics justify it, and it chains `/migrate` when the action is structural.

This is the manual, in-the-moment front-end to the placement discipline that `PLACEMENT.md`, `gcc-hygiene.md`, and `conventions/preference-graduation.md` document but otherwise rely on an agent remembering to apply. The whole value is that it performs the full filing-and-cross-referencing ritual so a good idea does not die inline in a session.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules (forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the file lock protocol)
for the entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock hygiene: run `bash ~/.claude/skills/shared/lock-file.sh cleanup` once at skill start
> to clear any stale locks from crashed sessions. Then acquire a lock via
> `lock-file.sh acquire` before every Edit/Write, and release it immediately after.
> Never write to `runtime-notes.md`, an index file, or CLAUDE.md without holding its lock.

Then read the placement machinery you will drive, in this order:
`~/.claude/PLACEMENT.md` (the two-axis rule + the "Loading reality" section on `paths:`),
`~/.claude/FOLDERS.md` (per-folder owner map), `~/.claude/LOOKUP.md` (the address book),
`~/.claude/conventions/gcc-hygiene.md` (derived views + what counts as a structural change).

## Usage

```
/tag                      file the thing just discussed or the file just edited (inferred)
/tag <path>               file a specific file or directory
/tag "<concept or rule>"  file an inline concept or rule described in the argument
```

| Argument      | Type          | Meaning                                                                                                |
| ------------- | ------------- | ------------------------------------------------------------------------------------------------------ |
| (none)        | inferred      | Resolve the target from the summoning context: cwd, files edited this session, the recent conversation |
| `<path>`      | file/dir      | Tag an existing artifact (a script, a doc, a snippet)                                                  |
| `"<concept>"` | quoted string | Tag an idea, rule, or note stated inline                                                               |

## Scope: gcc-only, with project-detection

`/tag` files into the global config (`~/.claude/`). Most tagged items are global: an
insight, a behavioral rule, an output convention, a term, a reusable snippet all apply
across projects. Global is the default because insights are global.

But some items are genuinely project-specific (they only make sense inside one repo:
a project's error-code enum, a repo-local build gotcha, a service's route convention).
Do NOT shove those into top-level global config. Detect project-specificity in Phase 2
and route the item to that project's `.claude/` (its `rules/`, `memory/`, or a local
doc) instead, and tell the user you did so and why. The test: "would a session in an
unrelated project ever benefit from this?" If no, it is project-scoped.

## Phase 1: Capture (resolve the target)

Establish exactly what is being tagged before doing anything else.

1. If an argument is a path, `Read` it. If it is a quoted concept, take it verbatim.
2. If there is no argument, infer the target from the summoning context: the file(s)
   edited this session, the artifact just produced, or the idea just discussed. State
   your inferred target in one line and confirm it before proceeding. A wrong
   inference caught here is free; caught after writing it is not.
3. Read enough surrounding context to characterize the item: is it a behavioral
   mandate, a how-something-works doc, an output standard, a term, a reusable code or
   doc snapshot, or a standing preference? You need this to classify in Phase 2.

Do not continue until you can state, in one sentence, what the item IS and why it is
worth keeping.

## Phase 2: Classify and place

Apply the PLACEMENT two-axis rule (category x tier). This is the "find a relevant home
in the gcc" step.

1. **Category (what is it?)** per PLACEMENT.md:
   - behavioral mandate -> `rules/`
   - how a tool/subsystem works -> `features/`
   - output/authoring standard -> `conventions/`
   - a word/shorthand the user adopts -> `GLOSSARY.md`
   - a standing preference or who-the-user-is fact -> `memory/global/feedback_*.md` / `user_*.md`
   - a reusable code/doc snapshot -> see "Replication mode" in Notes
   - an external pointer (URL, dashboard, ticket) -> a `reference_*` memory
2. **Dedupe before you create anything.** Grep the FULL relevant tree, not just the
   one directory where it "should" live, for an existing home. This is mandatory and
   non-negotiable (see `rules/grep-scope-before-claiming-absence.md`):
   ```bash
   rg -n --no-ignore --hidden "<2-3 keywords of the item>" ~/.claude/rules ~/.claude/features ~/.claude/conventions ~/.claude/GLOSSARY.md ~/.claude/memory
   ```
   If a home already exists, plan to APPEND to it and bump its `updated:`, not create a
   duplicate. If the item duplicates values already inlined somewhere, follow that
   inline pattern rather than exporting a competing copy.
3. **Tier (how often does it apply?)** per PLACEMENT's Axis 2 and the 80%-skip test.
   Default to the most conservative tier. Promotion to a CLAUDE.md brief is the gated
   exception, not the reflex (see Phase 3).
4. **Set the `paths:` lever for scoped `rules/` items.** Critical, and the reason this
   skill exists in its current form: `~/.claude/rules/*.md` is auto-loaded in full
   every session regardless of `tier:` (see PLACEMENT "Loading reality"). If the rule
   is project- or language-specific, give its frontmatter a `paths:` glob so it loads
   only when Claude touches a matching file, instead of paying always-on budget. If it
   is a truly universal behavioral rule, leave `paths:` off so it stays always-on.
5. **Respect derived views.** If the natural home is a derived view (the `FOLDERS.md`
   census, `mistake-patterns.md`, any file marked auto-generated), do NOT hand-edit it.
   Fix the authoritative source and re-run its regeneration script. Never write into a
   section marked "do not hand-edit".
6. **Compute the full ripple set:** the canonical home plus every index/pointer that
   must reference it: a `LOOKUP.md` row, a `GLOSSARY.md` term, a `MEMORY.md` pointer,
   `related:` cross-links, a `NAMESPACE.md` cluster entry, and a CLAUDE.md brief if the
   tier earns one.

If placement is ambiguous (two plausible homes, or unclear category), do not guess and
do not silently pick. Present ranked candidate homes in ONE round trip with your
recommendation first. Only escalate to a `std::claude::tui` picker (source
`~/.claude/scripts/tui/pick.sh`, use `tui_choose`; never hand-roll) when the choice
genuinely needs the user and a one-line question will not do.

## Phase 3: Propose and confirm

Present ONE consolidated plan and wait for approval. Do not write anything yet.

The plan states:

- the canonical home (new file or append-to-existing), with the exact path
- the frontmatter you will write (brief, triggers, tier, `paths:` if scoped, related)
- the full ripple set of index and cross-link edits, each as a concrete line
- the tier verdict, and explicitly whether it earns a CLAUDE.md brief and why
- any structural-change trigger that will chain `/migrate` (see Notes)
- for a project-specific item, the project `.claude/` destination and the reason

You may halt at any point to ask a focused question or offer a suggestion (a better
home, a related item worth tagging too, a cross-link the user may not have considered).
This is encouraged; the user wants the skill's judgment, not silent compliance.

## Phase 4: Write and propagate

Only after approval. For every write, hold the file lock (acquire, write, release).

1. Create or append the canonical file with correct, validated frontmatter.
2. Apply each index/pointer edit from the ripple set: the `LOOKUP.md` row, the
   `GLOSSARY.md` term, the `MEMORY.md` pointer line, the `related:` links on both ends.
3. For any derived view in the ripple, run its regeneration script rather than editing
   it (for example `bash ~/.claude/scripts/folders-index.sh` for `FOLDERS.md`, with no
   `>` redirect).
4. If the tier earned it, add the CLAUDE.md brief. Before doing so, check the line
   count: `wc -l ~/.claude/CLAUDE.md`. CLAUDE.md must stay under 200 lines; if the
   brief would push it over, surface that and ask what moves out first. Do not silently
   exceed the ceiling.
5. If the action is structural (see Notes), invoke `/migrate` to record it.

## Phase 5: Verify

Exercise the change; do not declare done off inspection alone.

1. If a `rules/`, `features/`, or `conventions/` sub-file was added or renamed, run
   `bash ~/.claude/scripts/validate-triggers.sh` and read the pass/fail line.
2. Confirm every new index row resolves to a real file (`test -f` each target).
3. Confirm CLAUDE.md is still under 200 lines if you touched it.
4. Render-check the written markdown (frontmatter closes, headings intact, no
   gum-rendered-as-source artifacts).
5. Print the GUIDELINES completion block with the files created/modified, then the
   post-run insight entry via `prepend-runtime-note.sh`.

## Notes

### Replication mode (curated snapshot, not raw copy)

The default is pointer-propagation: content lives in one home, everything else points
at it. But some items are worth capturing as a distilled snapshot rather than a link:
a subagent run report, a code snippet or bundle from a vibe-coded shell tool or a
macOS widget, or a project architecture doc. For those, replicate a _refined_ snapshot,
not a raw copy: strip project-specific and secret details, keep the reusable essence,
and file it under `assets/` (reports/snippets) or the relevant `features/` doc with a
pointer back to the source of truth. A snapshot must say what it deliberately omits so
a future reader does not mistake it for the live artifact.

### Structural-change trigger (chain /migrate)

Per `gcc-hygiene.md`, chain `/migrate` when the tag action does any of: creates,
renames, or deletes a top-level `~/.claude/` directory; moves or renames a canonical
file other things reference by path; changes a data-store schema; adds or renames a
NAMESPACE cluster. Adding a new sub-file under `rules/`, `features/`, or `conventions/`
is NOT structural and needs no migration.

### Guardrails

- Never write to `~/.claude/.claude/` paths (a hook blocks it). When cwd is `~/.claude`,
  keep paths anchored at `~/.claude/...`.
- Never duplicate content across files. If two homes need the same rule, it lives once
  and both link via `related:` (PLACEMENT anti-patterns 1 and 6).
- Do not over-promote. A conservative tier that keeps CLAUDE.md lean is the goal; the
  always-loaded budget is finite and every promoted brief competes for it.
- Confirm before overwriting any file this run did not create.
- Never commit or push. Filing is a working-tree change; the user commits.
