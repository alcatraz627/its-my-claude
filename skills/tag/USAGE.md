# /tag Usage Guide

## What it does

Files something worth keeping into the `~/.claude/` global config at its correct home:
resolves the target, places it via the PLACEMENT two-axis logic, confirms the plan,
writes it with proper frontmatter, and updates every index and cross-reference. Content
lives in one canonical home; everything else points at it. Promotes to a CLAUDE.md brief
only when the tier heuristics justify it.

## Usage

```
/tag [target | "concept"]
```

| Argument      | Type          | Description                                                                                |
| ------------- | ------------- | ------------------------------------------------------------------------------------------ |
| (none)        | inferred      | Files the thing just discussed or the file just edited; confirms the inferred target first |
| `<path>`      | file/dir      | Files a specific existing artifact (script, doc, snippet)                                  |
| `"<concept>"` | quoted string | Files an idea, rule, or note stated inline                                                 |

## Examples

### Example 1: tag a rule you just articulated

```
/tag "always grep the full tree before claiming a helper doesn't exist"
```

→ Classifies it as a behavioral rule, greps for an existing home (finds
`rules/grep-scope-before-claiming-absence.md`), proposes appending rather than creating
a duplicate, and after confirmation bumps its `updated:` and adds a cross-link.

### Example 2: tag a reusable shell tool for global keeping

```
/tag ~/Code/scratch/widgets/battery-glyph.sh
```

→ Recognizes a code snapshot, proposes a curated snippet under `assets/` (secrets and
machine-specific paths stripped) plus a `features/` pointer, and files it after you
approve the redaction.

### Example 3: tag a project-specific gotcha (routed locally, not global)

```
/tag "in this repo, the worker must boot before the API or migrations deadlock"
```

→ Detects the item is project-specific, routes it to the project's `.claude/` rather
than global config, and tells you it did so and why.

## Caveats

- Global-first: files into `~/.claude/` by default. Project-specific items are routed to
  the project's `.claude/`; the skill decides which and tells you.
- Pointer-propagation, not duplication: content is written once. "Replication" means a
  curated snapshot for code/reports, never a raw copy of the same text into two files.
- Conservative tiering: it will not promote an item into CLAUDE.md unless the tier
  heuristics justify it, and it enforces the sub-200-line ceiling.
- It never commits or pushes. Filing is a working-tree change; you commit.
- It will not hand-edit a derived view (the FOLDERS census, mistake-patterns). It fixes
  the source and re-derives.

## Dependencies

| Dependency                                               | Type         | Notes                                                                  |
| -------------------------------------------------------- | ------------ | ---------------------------------------------------------------------- |
| `GUIDELINES.md`                                          | Shared rules | Read at start of every run                                             |
| `PLACEMENT.md`                                           | Index        | The category x tier decision engine, plus the `paths:` loading reality |
| `FOLDERS.md`, `LOOKUP.md`, `GLOSSARY.md`, `NAMESPACE.md` | Indices      | Updated as part of the ripple set                                      |
| `conventions/gcc-hygiene.md`                             | Convention   | Derived-view rule + structural-change definition                       |
| `scripts/validate-triggers.sh`                           | Script       | Frontmatter validation in Phase 5                                      |
| `scripts/folders-index.sh`                               | Script       | Re-derives the FOLDERS census when it is in the ripple                 |
| `scripts/tui/pick.sh`                                    | Shared TUI   | Ambiguity picker (only when a one-line question will not do)           |
| `/migrate`                                               | Skill        | Chained when the tag action is structural                              |

## Tips

- Use it the moment you notice something worth keeping, not at session end: the summoning
  context (recent files, the live conversation) is what lets it infer the target.
- Pairs with `pin-for-dream` by contrast: `pin` defers a fuzzy observation to the async
  dream cycle; `/tag` enshrines a concrete thing now, with placement and index updates.
- Pairs with `/preference-graduation`: that skill batch-harvests preference signals from
  insight streams; `/tag` is the manual, point-at-one-thing path.
