# Changelog and release notes

A changelog tells a reader what changed for them between two versions. It is
written from the changes, never pasted from commit subjects.

## Gather

1. **The range.** Two tags or refs from the user, or the last tag to the head
   of the main branch.
2. **The changes.** The commit list or merged PRs in range, through a GitHub
   connector or pasted `git log --oneline --no-merges <range>` output.
3. **Classify.** With conventional commits, use the prefixes (`feat:`, `fix:`,
   `docs:`, `chore:`). Without them, classify by what the change touches (UI,
   API, dependencies, tests) and by reading the diff.
4. **Read the diff where the subject is unclear.** A subject like "update
   handler" can hide a user-facing change, and a revert can read as a new bug.

## Template

```markdown
# Changelog: v2.8.0 (2026-10-30)

Scope: 41 merged PRs since v2.7.2. Two changes need action on upgrade.

## Breaking changes
- `POST /exports` now requires a `format` field. **Migration:** send
  `"format": "csv"` to keep the old behavior. ([#812])

## New features
- Invoices can be paid in two installments from the billing page. ([#798])

## Bug fixes
- Exports no longer drop the last row when the file ends without a newline.
  ([#805])

## Other
- Node 18 support ends. CI now runs on Node 20 and 22.
```

## Rules

- **Context before the list.** One line on scope (how many changes, since
  which version) and anything that needs action, before any section.
- **Breaking changes first,** each with its migration step.
- **Write each entry as an effect on the reader,** not as what the code did.
  "Exports no longer drop the last row" beats "Fix off-by-one in serializer".
- **Collapse trivia.** Typo fixes, lint, internal refactors with no visible
  effect go in one "Other" line or are left out.
- **Expand what users feel** with enough context to judge the impact.
- **Caveats carry.** A fix that only covers new accounts says so. A summary
  keeps every qualifier of the entry it shortens.
- **Link each entry** to its PR or commit. Long lists use reference links at
  the foot (see `github-markdown.md`).
- Empty sections are dropped, not left with "None".
