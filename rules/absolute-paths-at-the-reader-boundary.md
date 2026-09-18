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
updated: 2026-09-18
stale_after_days: 180
---
# Absolute paths at the reader boundary

Any path in a reply the owner will read is absolute on its first mention, starting with `/` or `~`. Internal surfaces (notes, WAL, sub-agent prompts) may stay repo-relative. Precheck before pasting a path out of a checkpoint, plan or internal doc: does it start with `/` or `~`? Expand it first. Second reader: `relpath-stop.sh` (advisory; it skips fenced blocks). Separate from the trailing-period rule in CLAUDE.md.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/absolute-paths-at-the-reader-boundary.md`
