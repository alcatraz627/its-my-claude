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
updated: 2026-07-16
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
  --tier minor|moderate|project \
  --project <scope> --links "features/x.md rules/y.md" \
  --tags "tag1 tag2"
```

`tier` is the kind/ambition of the item — a passing note (`minor`), a
feedback-capture with little plan (`moderate`), or a full build (`project`) —
distinct from `effort` (work-size). `project` scopes the item so a successor
agent can focus on just that project's backlog; `links` point at the
folders/docs/rules it touches (queryable via `--link`).

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
bash ~/.claude/scripts/propose.sh list --status open               # the query table
bash ~/.claude/scripts/propose.sh list --project gcc --tier project  # filters compose
bash ~/.claude/scripts/propose.sh list --since 2026-07-01 --tag ipc
bash ~/.claude/scripts/propose.sh search "dashboard"               # full-text
bash ~/.claude/scripts/propose.sh show <id>                        # full detail + updates
```

`list` filters compose: `--status --tier --project --category --since --tag --link`
(`--since` is a zero-padded ISO date, e.g. `2026-07-01`).
`propose.sh` is the single query surface (the role atone.sh and gcc-schedule play
for their ledgers) — there is no separate query script.

## Lifecycle

`add` → accumulate context with `update <id> "note"` (append-only; keeps the
original body) → close with `retire <id> --as <status> "reason"` (`--as` defaults
to `done` if omitted). Terminal statuses: `done | rejected | superseded | deferred
| obsolete` (`--by <id>` links a superseding item). `done` and `reject` remain as
shortcuts. Re-weight any time with `tier <id> <minor|moderate|project>`. Never
delete — a closed item preserves the audit trail and feeds drain-rate metrics
(`decided_ts`). Quote multi-word reasons/notes.

## Self-feedback → canon promotion

High-confidence insights from runtime-notes/mistake-patterns/dream-mode (conf ≥ 0.85, 2+ occurrences) should graduate into rules or hooks, not remain in notes.

**Workflow:**
1. Auto-insight surfaced in runtime-notes.md or mistake-patterns.md
2. File a proposal tagged `source:dream` (or `source:mistake-pattern`) referencing the source path
3. User reviews via `propose.sh show <id>`
4. On approval: editor appends rule to `rules/<relevant>.md` (or adds hook), marks proposal `done`

This prevents the silent failure mode where high-signal insights sit in notes forever without becoming canonical.
