---
name: linear-ops
description: Reads and changes the user's Linear through the Linear connector: issues, comments, labels, cycles, estimates, projects, docs. Previews every change and writes only after a yes.
---

# Linear ops

The user's Linear desk in chat. Reads anything the Linear connector can see,
and makes changes only after showing them with every name resolved. Asks
usually arrive against a clock, so the shape is one exchange: read what is
needed, preview the change, ask once, send, answer with links.

Read `references/field-guide.md` before the first change in a chat. It says
how Linear behaves, which fields replace rather than add, and the user's team
conventions for labels, estimates and cycles.

## When to use

- The user mentions Linear, a ticket key (like `ABC-123`), a sprint or cycle
- "What is on my plate", "how is the sprint going", "points left on X"
- "File a ticket for X", "move these to review", "tag it", "link the PR"
- Breaking an issue into sub-issues, posting a project update, putting a doc
  on an issue

Not for a GitHub issue. That is `file-gh-issue`.

If the Linear connector is not connected in this chat, say so and stop. Do
not draft changes as if they will be sent.

## Reading

Reads never need permission. Do them and answer.

- Resolve before answering. A vague ask ("the sync ticket") is a search. A
  name is matched case-insensitively, then by unique prefix, then by
  substring. A tie stops with the candidates listed, never a guess.
- Orient first when the ask names a state, label, cycle, project or person
  you have not seen in this chat: list the team's statuses, labels, cycles,
  projects or users through the connector.
- Answer with the data (a short table, the links), not an account of the
  calls made.
- Asked how a cycle is going, quote both Linear's own progress and points
  completed. They measure different things (see the field guide).
- An issue with no estimate is not zero. Report unestimated issues
  separately.

## Changing

Every write follows the same four steps.

### 1. Preview

Before any write, build the full change with every name resolved against what
Linear has:

```
ABC-123  "Fix the export timeout"
  state     In Progress  to  In Review
  cycle     42 (Oct 27 to Nov 3)
  labels    add: /backend   (existing labels kept)
  estimate  none  to  3
```

A name that does not resolve, or an estimate off the team's scale, stops
here with the valid options. For a description edit, show the before and
after text, or the exact lines added.

### 2. Ask once

Put every preview the task needs into one block and ask one question: "Send
these?" Do not ask field by field. Ask a second time, mid-task, only for one
of these:

- More than about ten issues at once
- Replacing text someone wrote: a description, a project body, a comment you
  did not write, a document edited in Linear
- Archiving, deleting, or moving something to another parent
- Posting something others will read as the user: a comment, a project
  update
- An ambiguous name

Never ask which tool to use or how to format the answer. Those are Claude's.

### 3. Send

On a yes, send exactly what the preview showed, nothing more. Use add and
remove fields for labels and relations, not the field that replaces the
whole set, unless the user asked to replace it. Use a patch edit for a
description change, not a full rewrite, when the connector offers one.

### 4. Report

Read back what changed and give the links. Say anything the preview could
not show: a template's own values, a notification the change triggers, a
field the connector refused.

## Documents on an issue

To put markdown on an issue as Linear documents:

1. List the documents already on the issue. Match by title and update those
   in place. Create only the missing ones. Titling differently from what is
   there is how duplicates get made.
2. Strip frontmatter and HTML comments, and turn `<br>` inside table cells
   into `•`. Linear shows raw HTML as visible text.
3. If a document changed in Linear since the user's version, or has open
   inline comments, stop and show the difference. Overwriting it loses
   someone's edit. Merge only with the user's say-so.
4. After writing, read each document back. Empty or truncated content is a
   failure, not a caveat.

## Boundaries

- Never write without the user's yes for that task. A yes covers the
  previewed changes only.
- No hard deletes unless the user names the item and says delete. Archive is
  the default.
- No admin surfaces: integrations, API keys, SSO, webhooks, billing.
- The team conventions in the field guide are a snapshot. When the live data
  disagrees, the live data wins, and say what changed.
