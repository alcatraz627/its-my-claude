---
brief: Cross-session improvement backlog (propose.sh); self-feedback to canon promotion lifecycle
triggers:
  - tool:propose.sh
  - topic:improvements
  - phrase:"what else can be improved"
  - phrase:"list of improvements"
related: [rules/corrections.md]
tier: 1
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Proposals
Cross-session improvement backlog at `~/.claude/proposals.jsonl` (append-only JSONL). CLI: `~/.claude/scripts/propose.sh`.

## File an item mid-task (30 seconds tops)

```bash
bash ~/.claude/scripts/propose.sh add \
  --title "Short imperative statement" \
  --body "Rationale, context, pointers to files/lines" \
  --category hooks|scripts|skills|config|docs|other \
  --effort small|medium|large \
  --tags "tag1 tag2"
```

## What to file

- Config-level improvements noticed mid-task but out of scope
- Deferred items from completed upgrades
- Systemic pain points observed across multiple tasks
- Hook/skill/script gaps you worked around rather than fixed

## What NOT to file

One-off bug fixes (just fix them), user preferences (save to memory), project-specific items (project TODO). The backlog is for reusable `~/.claude/` infrastructure.

## Responding to meta-questions

When the user asks "what else can be improved?" / "give me a list of improvements" — **start by reading open proposals.** They were filed with full context the current session lacks:

```bash
bash ~/.claude/scripts/propose.sh list --status open
bash ~/.claude/scripts/propose.sh show <id>
```

## Lifecycle

`add` → `done` (implemented) or `reject --reason "..."` (obsolete). Never delete — rejection preserves audit trail.

## Self-feedback → canon promotion

High-confidence insights from runtime-notes/mistake-patterns/dream-mode (conf ≥ 0.85, 2+ occurrences) should graduate into rules or hooks, not remain in notes.

**Workflow:**
1. Auto-insight surfaced in runtime-notes.md or mistake-patterns.md
2. File a proposal tagged `source:dream` (or `source:mistake-pattern`) referencing the source path
3. User reviews via `propose.sh show <id>`
4. On approval: editor appends rule to `rules/<relevant>.md` (or adds hook), marks proposal `done`

This prevents the silent failure mode where high-signal insights sit in notes forever without becoming canonical.
