---
name: file-gh-issue
description: Files a minor technical GitHub issue through the GitHub connector, or one disputing a wrong PR bot finding. Grounds it, shows a dry run, files only on a yes. Not for product work.
---

# File a GitHub issue

Files one small, technical-only issue on a GitHub repository through the
GitHub connector, with a dry run and the user's explicit go-ahead before
anything is created. Filing is outward-facing: other people read it, and it
carries the user's name.

## When to use

- A small technical cleanup worth tracking: dead code, a missing enum entry,
  config sprawl, a stale flag, a grounded correctness nit
- **A PR review bot's finding is wrong.** Arguing in the PR thread teaches the
  reviewer nothing, because nobody reads the thread back. An issue on the
  bot's repository, or the team's tracking repository, is the channel that
  reaches whoever maintains it. Link the PR comment in the body.

Not for anything with product or business value. That belongs in the team's
planning tool (Linear, via `linear-ops`) and is the team's call. Not for a
major bug or an incident.

If the GitHub connector is not connected in this chat, say so, and hand back
the drafted issue for the user to file by hand.

## Procedure

### 1. Ground the finding

Every claim in the issue is checked against the actual code before it goes
in. Read the file through the connector at the current default branch, and
quote the lines. An absence claim ("nothing calls X") needs a code search of
the whole repository, not one folder, and the issue says what was searched.
A finding from an earlier review or another tool gets re-checked, not copied.

If a claim cannot be checked, cut it or mark it `UNCONFIRMED: <reason>` in
the body.

### 2. Pick the repository

Confirm the owner and repository with the user. Never infer it from the
chat's topic alone. Then:

- Search open and closed issues for the same problem. If one exists, offer a
  comment on it instead of a new issue.
- Read the repository's labels and, for an organization, its issue types.
  Use only labels that exist. Suggest `tech-debt` or a close match only if
  the repository has one.
- Check for an issue template and follow its shape when there is one.

### 3. Draft

Title: specific and under about 70 characters ("Remove unused
`legacyExport` flag from config loader", not "Cleanup").

Body:

```markdown
## What
One or two sentences.

## Where (verified)
`path/to/file.ts:42` `functionName`, with the quoted lines.

## Options
The fix or fixes, smallest first.

## Scope
Minor technical. What it does not touch.
```

For a wrong review finding, add `## The finding` with a link to the PR
comment, and `## Why it is wrong` with the evidence.

End the body with one provenance line: drafted with Claude, minor technical
scope, checked against commit `<short sha>` on `<branch>`.

### 4. Dry run

Show exactly what will be sent, and send nothing:

```
Repository  owner/repo
Title       <title>
Labels      <labels that exist>   Type  <type, if the repo uses types>
Duplicates  none found  |  #123 looks related (link)
Body
<the full body, rendered>
```

### 5. File on an explicit yes

Only a clear go-ahead files it ("yes", "file it", "go"). Silence, a question
or an edit request is not a go. On edits, revise and show the dry run again.

On a yes, create the issue with exactly the dry-run content. Report the issue
link and number.

## Boundaries

- One issue per yes. A batch gets one dry run listing every issue, and one
  yes covers exactly that list.
- No commits, branches or pull requests as part of filing.
- No assignees or mentions unless the user names them. A mention notifies a
  real person.
- Minor technical scope only. If it needs a product decision, it goes to the
  team's planning tool, not here.
