---
name: scan-sessions
description: Deep-scan past Claude Code sessions for patterns, frustration signals, and improvement opportunities
invocation: /scan-sessions
arguments: "[--since DATE] [--until DATE] [--dir DIR] [--project PROJ] [--rescan] [--emit-proposals] [--report]"
---

# scan-sessions

Crawls Claude Code session JSONL files, extracts behavioral signals (user frustration,
self-corrections, tool errors, repeated reads, skill outcomes), aggregates across sessions,
and generates actionable reports.

## Usage

```
/scan-sessions                          # scan recent sessions (last 7 days)
/scan-sessions --since 2026-04-01       # scan from date
/scan-sessions --project frontend       # filter by project name
/scan-sessions --rescan                 # force full re-crawl (ignore cache)
/scan-sessions --report                 # generate HTML report
/scan-sessions --emit-proposals         # file top findings as proposals
```

## Step 0: Load Shared Guidelines

Read `~/.claude/skills/GUIDELINES.md`. Apply all rules for the duration of this skill run.

## Step 1: Run the scanner

```bash
python3 ~/.claude/skills/scan-sessions/main.py [ARGS]
```

Pass through all user-supplied arguments. The script handles:
- Incremental crawl of `~/.claude/projects/**/*.jsonl`
- Signal extraction (5 signal types)
- Aggregation and ranking
- JSON output to stdout

## Step 2: Present results

Format the JSON output as a readable summary:
- Top frustration signals with session context
- Recurring mistake patterns
- Tool error hotspots
- Skill reliability breakdown
- Novel patterns not yet in `~/.claude/mistake-patterns.md`

## Step 3: Optional actions

If `--report`: generate HTML report at `~/.claude/assets/reports/scan-sessions/`
If `--emit-proposals`: file top-N findings via `propose.sh add --source auto-scan`

## Architecture

```
~/.claude/skills/scan-sessions/
  SKILL.md          — this file
  main.py           — entry point + CLI
  crawl.py          — JSONL walker + SQLite indexer (incremental, prunes stale entries)
  signals/
    user_frustration.py  — keyword + short-reply detection (filters boilerplate/instructions)
    self_correction.py   — re_edit, fix_attempt, actually patterns
    tool_errors.py       — 30+ regex patterns across 15 error categories
    repeated_reads.py    — tracks files read 3+ times in a session
    skill_outcomes.py    — 40-turn lookahead for confirmed/implicit success/error/rejection
  aggregate.py      — cross-session analysis + novel pattern detection
  report.py         — HTML report generator (dark/light toggle, CSS bar charts)

~/.claude/assets/scan-sessions/
  index.db          — SQLite index (WAL mode, 3 tables: sessions, turns, signals)
```

## Signal Details

### Tool Error Categories (15)
`not_found`, `exit_code`, `permission`, `cancelled`, `token_limit`, `precondition`,
`http_error`, `hook_denied`, `syntax`, `parse`, `browser_error`, `stale_read`,
`config_error`, `validation`, `mcp_error`, `edit_mismatch`, `rate_limit`,
`connection`, `wrong_type`, `import`, `runtime`, `killed`, `disk`, `exists`,
`missing_cmd`, `timeout`

### Skill Outcome States
`confirmed_success` (explicit praise), `implicit_success` (topic change / session end),
`error_recovered` (error occurred but user didn't complain), `error` (error + no user response),
`rejected` (user frustration keywords), `unknown` (insufficient signal)

### Performance
127 sessions, ~24K turns: crawl 0.96s, signals 0.31s, total 1.27s
