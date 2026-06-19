---
brief: Procedure for scanning a vast external list (GH issues, Linear tickets, Slack archive, mailing-list threads) for goal-relevant items without flooding the main agent's context. Sub-agent fan-out + structured cache.
triggers:
  - phrase:"scan the issues"
  - phrase:"check existing reports"
  - phrase:"look through the list"
  - phrase:"vast list"
  - phrase:"large issue tracker"
  - topic:github-issues
  - topic:duplicate-check
  - topic:external-list-scan
related:
  - rules/sub-agent-outputs.md
  - features/proposals.md
tier: 2
category: conventions
updated: 2026-06-19
stale_after_days: 365
---

# Scanning a vast external list for goal-relevant items

Procedure for "look through hundreds of GH issues / tickets / threads and tell me what's relevant to my goal" tasks. The naive approach (read everything into the main agent's context) burns budget and drowns the synthesizer. This procedure uses sub-agent fan-out so each scanner absorbs its own dump and only a structured summary returns to the orchestrator.

## When this applies

- Any task with the shape: "given goal `G`, scan list `L` of `N` items where `N` >> 30, surface the items relevant to `G`."
- Concrete instances seen so far: GitHub issue duplicate-checks, language/style calibration against a venue's existing writing, prior-art surveys before filing a new ticket, audit of an open-issue backlog for cluster patterns.

Don't use for: lists where you can answer the question with one targeted search (use that search directly), or where you need to read every item in full anyway (no fan-out benefit).

## The shape

```
┌─ Orchestrator (main agent) ────────────────────────────────────────────┐
│                                                                        │
│  1. Define goal in one sentence.                                       │
│  2. Decide what each sub-agent should return (the structured shape).   │
│  3. Set up cache dir + reserve absolute output paths per sub-agent.    │
│  4. Fan out 2–4 sub-agents in parallel, one Agent call per role.       │
│  5. Verify their output files exist before reading them.               │
│  6. Read only the synthesis files, not the raw .jsonl candidates.      │
│  7. Apply findings; archive cache for future reuse.                    │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

The orchestrator never reads more than ~10 KB per sub-agent return. Each sub-agent's raw dump (the 30 issue bodies, the API pagination, the snippets) lives in its own context and dies when it returns.

## Cache layout

Standard path under the global Claude config:

```
~/.claude/cache/<source>-<list-kind>-scans/<repo-or-namespace>/<YYYYMMDD>-<scan-slug>/
  <role>_analysis.md       # synthesis (human-readable, what you actually read)
  <role>_candidates.jsonl  # raw structured findings, one object per item (machine-readable)
  index.json               # scan metadata: goal, queries run, item counts, agent IDs
```

Concrete example from 2026-06-19:

```
~/.claude/cache/github-issue-scans/anthropics-claude-code/20260619-tui-corruption-search/
  dup_analysis.md          # 71 lines, top-3-candidates + recommendation + query log
  dup_candidates.jsonl     # 20 objects, each rated similarity high/medium/low/none
  voice_patterns.md        # 334 lines of concrete quoted phrasings from real issues
  voice_samples.jsonl      # 14 objects with body excerpts + lifted phrases
```

The `.md` files are the synthesis (read them later). The `.jsonl` files are the raw evidence (search them later for specific items, don't re-read in full).

## Roles per scan

Pick the smallest set of role-distinct sub-agents that covers the goal. Typical sets:

| Goal shape | Roles |
|---|---|
| "Is there already a report for X?" | dup-hunt only |
| "Match the venue's writing style" | voice-extract only |
| "File a new report properly" | dup-hunt + voice-extract (parallel) |
| "Find clusters in the backlog" | cluster-survey + outlier-finder (parallel) |
| "Validate a hypothesis across the corpus" | evidence-for + evidence-against (parallel adversarial) |

Run roles in parallel via multiple `Agent` calls in one orchestrator message. Each sub-agent has independent context, so cost scales linearly with role count, not with item count.

## Sub-agent prompt template

Each Agent dispatch must contain these blocks (per `rules/sub-agent-outputs.md` since material content is being produced):

```
CONTEXT
  - The orchestrator's overall goal in one sentence.
  - The artifact the result will feed into (so the sub-agent calibrates depth).
  - Anything the sub-agent should read FIRST before searching.

SCOPE
  - The exact query templates / search terms to run.
  - The per-item inspection cap (e.g. "≤30 get_issue calls").
  - The selection criteria for which items to inspect in depth.

OUTPUT (mandatory)
  - Absolute path 1: <role>_candidates.jsonl, with the per-line JSON shape spelled out.
  - Absolute path 2: <role>_analysis.md, with the section list spelled out.
  - Instruction: "write before returning."

RETURN
  - "5-bullet abstract + the two file paths. Don't paste raw findings into the return string."
```

The "write before returning" + per-line JSON shape are the load-bearing parts. Without them the sub-agent's findings die when its context goes; with them, the cache survives and can be re-queried by name later.

Working example from the 2026-06-19 GH scan, lightly trimmed:

```
GOAL: Scan github.com/anthropics/claude-code for any issue overlapping with
our draft report on TUI character-zipper + scrollback-wipe corruption.

CONTEXT: Read /Users/alcatraz627/.claude/assets/reports/20260618-.../REPORT.md
first so you understand what we're filing.

SCOPE: Use mcp__github__search_issues with these queries [list of 10 keyword
queries]. For each promising hit, mcp__github__get_issue to check the body.
Cap get_issue calls at 30. Rank each as high/medium/low/none overlap.

OUTPUT (write to disk BEFORE returning):
  /Users/alcatraz627/.claude/cache/github-issue-scans/anthropics-claude-code/
    20260619-tui-corruption-search/dup_candidates.jsonl
    20260619-tui-corruption-search/dup_analysis.md

dup_candidates.jsonl shape: one JSON per inspected issue, fields {number, url,
title, state, created_at, updated_at, comments_count, labels, similarity,
overlap_summary}.

dup_analysis.md sections: ## Summary, ## Top 3 candidates, ## Recommendation,
## Query log.

RETURN: 5-bullet abstract + the two absolute file paths.
```

Real result: 20 issues inspected, 5 ranked `high`, no exact duplicate, recommendation to file new with cross-refs to 6 existing issues. Cost: ~165K subagent tokens, ~3.5 min wall time, ~10 KB returned to the orchestrator.

## Common pitfalls

**Pitfall: sub-agent skips the write step and reports findings only in the return string.** Findings die when the sub-agent returns. The cache is your reusable artifact; the return string is throwaway. Always require the write before the return, and verify the file with `Read` or `Bash ls` before reading its content.

**Pitfall: orchestrator reads the `.jsonl` candidates file as its primary digest.** The `.md` synthesis is what the sub-agent ranked and reasoned over. The `.jsonl` is for spot-checking specific items by `grep`/`jq` later, not for synthesis. Read the `.md`.

**Pitfall: too many keyword queries, not enough get-the-body calls.** The query list cap is for breadth; the inspection cap is for depth. A scan with 20 queries and 5 deep inspections finds less than one with 8 queries and 25 deep inspections. Spend the budget on bodies.

**Pitfall: prefix-stem search bites you.** Verified 2026-06-19 on GH: searching `"interleav"` returns zero hits even though `#68755` title contains "interleaved". GitHub's search is doing prefix-stem matching, not substring. Run multiple inflections (`interleav` / `interleave` / `interleaving`) or use a broader keyword and filter in the body check.

**Pitfall: pagination cap masks scope.** GitHub's `search_issues` returns 30 per page by default. If 9 of 10 queries hit the per-call token cap at 30 results, the scan covered only 30 of N total — fine for sampling, not for completeness. Document this in the analysis (`## Query log` with hit counts) so future scans know what was missed.

**Pitfall: voice agents re-impose generic anti-AI rules over the venue's actual style.** The internal `conventions/doc-writing.md` is calibrated for our internal docs. When the goal is "write a doc the external venue will accept," the venue's house style wins over the generic anti-AI list. A voice-extract sub-agent's findings about local conventions take precedence on conflict.

## Synthesis pattern

The orchestrator after the sub-agents return:

1. Run `ls -la` on the cache dir; confirm every promised file exists with non-trivial size.
2. `Read` the `.md` synthesis files in full. Do not `Read` the `.jsonl` candidates files in full; spot-check specific items by line number if needed.
3. Apply findings to the destination artifact (revise the draft, file the ticket, write the next sub-prompt).
4. Leave the cache files in place for re-use. They're cheap and a future scan with the same goal can reuse them or compare against them.
5. If the cache directory should be referenced from another doc (a checkpoint, a plan, a runbook), link the path in. Unlinked caches go orphaned per the sub-agent-outputs rule.

## Budgeting

Per scan, on the order of 100–200K sub-agent tokens for a 2-role fan-out scanning 30–50 items. Wall time: 3–6 minutes per role, parallel. Orchestrator context cost: ~10 KB per sub-agent return + whatever synthesis files the orchestrator reads.

If a scan needs 4+ roles to cover the goal, batch them in two waves rather than one — the parallel cap and API rate limits start hurting above ~4 simultaneous sub-agents on a single MCP server.

## Reuse and reference

A previous scan's cache directory is itself a corpus. Before running a new scan against the same source, check the cache index:

```bash
ls ~/.claude/cache/github-issue-scans/<repo>/
```

If a recent scan covers the same goal, read its `_analysis.md` first and only re-scan if the data is stale (>7 days) or the goal has shifted. Don't repeat 165K-token work that's still good.

## When this convention doesn't fit

- Single-issue targeted lookups: just call the API directly.
- "Read every item in detail" tasks: there's no fan-out benefit; the sub-agent would have to return everything.
- Lists where the items are already locally indexed (atone events, your own checkpoints): direct shell tools (`jq`, `rg`, `awk`) beat sub-agent dispatch.
- Tasks where the venue won't tolerate machine-readable output: this convention assumes the cache is reusable; if every scan is bespoke, the cache overhead doesn't pay back.

## See also

- `rules/sub-agent-outputs.md` — the mandate that material sub-agent content must be persisted to disk (this convention is one application).
- `features/proposals.md` — if a scan surfaces a system-improvement candidate, route it to `proposals.jsonl` rather than another markdown doc.
- The 2026-06-19 anthropic/claude-code scan at `~/.claude/cache/github-issue-scans/anthropics-claude-code/20260619-tui-corruption-search/` is the canonical worked example.
