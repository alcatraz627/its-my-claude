---
name: forgotten-todos
description: Browse the cross-session backlog of unfinished todos surfaced from /core-dump checkpoints. Reads ~/.claude/subconscious/dreams/pending-todos.jsonl (regenerated from all ingested checkpoint Pending Items), deduped by content, sorted by recurrence count then recency. Use when the user asks "what was I about to do", "anything I forgot", or wants to clean up the long-tail todo backlog from past sessions.
allowed-tools: Read, Bash
argument-hint: "[--all] [--project PATH] [--seen-min N]"
user-invokable: true
---

## Brief

The subconscious dream system ingests `/core-dump` Pending Items into a deduped, recurrence-counted backlog. This skill browses it. The backlog is the answer to "what did I leave hanging across all the sessions I forgot to finish?"

## When to use

- User asks: "what was I going to do", "anything pending from before", "list forgotten todos"
- SessionStart hint mentions "N unfinished todos from past sessions" — user clicks through
- Sweeping the backlog after a quiet week, marking items abandoned vs still-pending

## Usage

```
/forgotten-todos                  # top 30 by recurrence × recency
/forgotten-todos --all            # everything, no cap
/forgotten-todos --project PATH   # filter to one project
/forgotten-todos --seen-min N     # only items seen N+ times across sessions
```

## Phase 1 — Refresh the backlog

```bash
~/.claude/subconscious/scripts/aggregate-todos.sh
```

This walks `~/.claude/subconscious/dreams/ingest-queue/*.json` and rebuilds `pending-todos.jsonl`. Cheap (sub-second on a normal corpus). Always re-aggregate before browsing so new `/core-dump` ingests are picked up.

## Phase 2 — Render the picker

```bash
~/.claude/subconscious/scripts/aggregate-todos.sh --pretty
```

Output (sample):
```
  #   TODO                                                         SEEN  AGE        PROJECT
  1   Disable claude.ai Sentry + Gmail connectors via web UI       ×3    2h ago     ~/.claude
  2   Migrate improvement-ideas.md to proposals.jsonl              ×2    1d ago     ~/.claude
  3   Verify tab-title emit log                                    ×1    2h ago     ~/.claude
```

`SEEN ×N` = item recurred in N different `/core-dump` Pending Items. High-recurrence items are likely either (a) actually important and being forgotten OR (b) genuinely abandoned but never marked so. Both worth attention.

## Phase 3 — Triage (optional, interactive)

If user wants to triage, present `mcp__inputs__pick_many` with all rows. Three actions:
- **Mark done** — append to `~/.claude/subconscious/dreams/done-todos.jsonl` (audit trail); aggregator filters these out next pass
- **Mark abandoned** — append to `done-todos.jsonl` with `"status":"abandoned"`; same filter effect
- **Keep open** — no-op (default)

Triage protocol — write a JSON line per disposition:
```json
{"ts": "<now>", "norm_text": "<lowercased-collapsed>", "status": "done|abandoned", "via": "/forgotten-todos"}
```

The aggregator's dedup keys against `done-todos.jsonl` to filter completed items on next pass (TODO — wire this into aggregate-todos.sh in a follow-up).

## Phase 4 — Output

If no triage requested: just print the table and exit. The data is useful as-is for the user's awareness.

If triage requested: print a summary after picker submission:
```
─────────────────────────────────────────────────────
  Triage complete
─────────────────────────────────────────────────────
  Done:       3
  Abandoned:  2
  Kept open:  10

  Next /forgotten-todos call will hide done/abandoned items.
─────────────────────────────────────────────────────
```

## Filtering args

- `--project PATH` — filter by project_root prefix
- `--seen-min N` — only show items with `seen_count >= N` (recurrence threshold)
- `--all` — disable the default 30-item cap

Pass these through to `aggregate-todos.sh` once it supports them (current impl caps to 30 by default; --all flag is a TODO on the aggregator).

## Notes

- This skill is a **read-mostly browser** — heavy logic lives in `aggregate-todos.sh`. Keep them separate so the data view (script) can serve other UIs (dashboard, widget) without skill overhead.
- The pending-todos.jsonl is regenerated on each invocation; it's a derived view, not a primary source. The primary source is the ingest queue.
- Dedup by lowercased-whitespace-collapsed text. Slight wording variations across sessions ("Disable Sentry" vs "Disable claude.ai Sentry") may produce near-duplicates. Acceptable for an MVP.
