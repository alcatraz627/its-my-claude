# Architecture Decision Record

The Michael Nygard format. One decision per record.

## Gather

Ask in one message, for whatever the conversation does not already hold:

- **Decision.** What was decided?
- **Context.** What problem forced a choice, and what constraints apply?
- **Alternatives.** What else was considered?
- **Consequences.** What gets better, what gets worse, what changes without being better or worse?

If the user is vague, read the commits or PRs that carried the change and ask
focused follow-ups from what they show.

## Template

```markdown
# ADR-0014: Store job events in an append-only table

**Date:** 2026-10-30
**Status:** Accepted

## Context

Two to four sentences of facts: the forces at play and the constraints. No
opinions.

## Decision

What was decided and what changes because of it. Specific: names the table,
the service, the cutover.

## Alternatives considered

### Update rows in place
Why it was rejected, in one or two sentences.

### Event store service
Why it was rejected, in one or two sentences.

## Consequences

### Positive
- Replays rebuild any job's state from its events.

### Negative
- Storage grows linearly with job count. A retention job is now required.

### Neutral
- Reads move from the `jobs` table to a materialized view.
```

## Rules

- **Status** is one of Proposed, Accepted, Deprecated, or "Superseded by
  ADR-NNNN".
- **Numbering** follows the existing records in `docs/adr/` or
  `docs/decisions/`. Ask for the last number when the folder is not visible.
- **Alternatives** are real options someone weighed, not straw men. If only one
  option was ever considered, say so.
- **Consequences** include the negative ones. An ADR with no cost listed reads
  as advocacy.
- An accepted ADR is not edited to reflect a later change of mind. A new ADR
  supersedes it, and the old one's status line points forward.
