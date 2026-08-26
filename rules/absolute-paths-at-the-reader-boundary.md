---
brief: Any path in a reply the owner will read is absolute on its first mention, starting with / or ~; a repo-relative path pasted from a checkpoint, WAL, or plan forces them to come back and ask where it lives.
triggers:
  - topic:paths
  - phrase:"where is that file"
related:
  - rules/communication.md
  - rules/audience-aware-writing.md
tier: 1
category: rules
updated: 2026-08-27
stale_after_days: 180
---

# Absolute paths at the reader boundary

Internal surfaces (notes, checkpoints, WAL entries, sub-agent prompts) may carry repo-relative paths, because the agent holds the working directory that resolves them. The user does not. Any path in a reply they will read must be absolute on its first mention, starting with `/` or `~`. A bare basename, or a repo-relative path like `.claude/output/20260728-run-page-spec/experience-spec.md`, forces them to come back and ask where it lives. Expand it before sending.

**Precheck before pasting any path from a checkpoint, WAL, plan, or internal doc into a user-facing reply:** does it start with `/` or `~`? If not, expand it first.

**Diagnostic signal:** the path arrived by copy-paste out of an internal document. That is the most common miss shape, because the citation is correct in the doc it came from and only becomes unresolvable once it crosses into the reply. Owner correction 2026-07-28, then pinned in seven consecutive daily digests without landing.

Note this is a different failure from the trailing-period rule in `CLAUDE.md`, which the `filename-dot-stop.sh` Stop hook enforces mechanically. Relative-path expansion has no hook. Nothing catches it but you.

