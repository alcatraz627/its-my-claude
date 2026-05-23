---
brief: After user corrections: state mistake, identify pattern, update mistake-patterns.md, check for hook, fix
triggers:
  - topic:user-corrections
  - phrase:"revert this"
  - phrase:"why did you"
related: []
tier: 1
category: rules
updated: 2026-04-24
stale_after_days: 90
---

# Corrections
When the user corrects a mistake — any pushback, "why did you do X", "revert this", "stop doing that" — follow this exact ritual before continuing other work.

## The five steps

1. **State the mistake** — one sentence: what you did wrong.
2. **Identify the pattern** — the reusable category, not the specific instance (e.g., "batch verification skip", "number heuristic without rendering", "overrode user preference").
3. **Invoke `/atone`** — the skill gathers context, classifies severity (S1/S2/S3), reuses an existing slug if one matches, writes a structured event to `~/.claude/atone/events.jsonl`, and for S3 also drafts an RCA with a runnable `## Procedure` section.
4. **Check if a hook can prevent recurrence** — if yes, file via `bash ~/.claude/scripts/propose.sh add --category hooks ...`. The consolidate cron will surface it; you (the human) decide.
5. **Fix the mistake** — revert, then apply the correct change.

The goal is to externalize the learning so future agents (including yourself after compaction) benefit without needing the full story in context.

## How `/atone` writes the event

`~/.claude/atone/events.jsonl` is **append-only**, kernel-locked (`chflags uappnd`), and git-tracked. Each event is one JSON line:

```json
{"id": "mist-YYYYMMDD-HHMMSS-NN", "slug": "kebab-case-pattern",
 "severity": "S2", "cluster": "A|B|C|D|E|null",
 "issue": "...", "cause": "...", "fix": "...", "what_not_to_do": "...",
 "precheck": "yes/no question that resolves at draft time",
 "tags": [...], "rca_id": "..."}
```

Recurrences are **new lines with the same slug** — never edits to existing lines. The system measures severity-by-recurrence-count automatically.

The curated `~/.claude/mistake-patterns.md` is regenerated from `events.jsonl` by `bash ~/.claude/scripts/atone-consolidate.sh` (cron, every 2 days). Hand-editing `mistake-patterns.md` is overwritten on next consolidation.

**Rules for the file:**
- Max 20 patterns — if full, merge similar ones or drop the oldest with only 1 occurrence
- Check this file when starting work that touches areas with known patterns (CSS, file transforms, user preferences)
- Sub-agents don't read this file — only the main agent does at session start when relevant

## Promotion path

High-confidence patterns (repeat occurrences, user-cited as recurring) graduate from `mistake-patterns.md` → a proper `rules/*.md` entry or a hook. See `features/proposals.md` for the self-feedback → canon workflow.
