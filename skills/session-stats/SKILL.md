---
name: session-stats
description: Full session analytics report — cost, tokens, tools, rate limits, context usage, and activity timeline
allowed-tools: [Read, Bash, Glob, Grep]
---

# /session-stats

Generate a comprehensive analytics report for the current Claude Code session.

## Data Sources

Gather data from these temp files (all keyed by `$PPID` — the Claude process PID):

| File | Content |
|---|---|
| `/tmp/claude-tools-$PPID` | Tool usage counters (`_total=N`, one `toolname=count` per line) |
| `/tmp/claude-sparkline-$PPID` | Context % ring buffer (one number per line, newest last) |
| `/tmp/claude-timeline-$PPID` | Activity delta ring buffer (tool calls per daemon interval) |
| `/tmp/claude-statusline-$PPID` | Daemon-collected stats (key=value pairs) |
| `/tmp/claude-ctx-$PPID` | Latest context remaining % |
| `/tmp/claude-turns-*` | Turn counter file |
| `/tmp/claude-cost-ring-*` | Cost velocity ring buffer |

Also query the **statusline JSON** by running the statusline command to capture live data (model, cost, rate limits, context window).

## Report Format

Source gum-tui.sh and render using a dashboard layout. Omit panels that have no data:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Session Analytics"

# Top-level session summary as key-value lines:
gum_kv "Model"    "Opus 4.6"
gum_kv "Duration" "42m 15s"
gum_kv "Turns"    "28"
gum_kv "Cost"     "\$3.47 (\$0.12/turn avg)"

gum_divider

# Dashboard row 1: Context + Rate Limits + Tool Usage
gum_dashboard \
  "Context|Remaining: 38%|Trend: ▁▂▂▃▃▄▅▅▆▇|Est. left: ~12 turns" \
  "Rate Limits|5h window: 62% used|7d window: 31% used|Resets in: 2h 14m" \
  "Tool Usage|Total: 142 calls|Top: Read(38) Edit(25) Bash(22)|Ratio: R/W = 1.52x"

# Activity timeline panel (if data exists):
gum_panel "Activity Timeline" \
  "░░▒▓█▒░░▓▓█▒░░░▒▓▒░░▒▓█▓░░░░▒▒" \
  "^start                       ^now" \
  "Peak burst: 8 calls/interval at ~12m mark"

# Environment panel (omit if no relevant data):
gum_panel "Environment" \
  "Git:     main (+3 ahead, 2 uncommitted)" \
  "PM2:     3 online, 0 errored" \
  "Network: 48ms to Anthropic API" \
  "Disk:    42GB free"
```

Adapt to show only panels with data. Omit sections with no data (e.g., skip PM2 if not running, skip rate limits if not available).

## Execution Steps

1. **Resolve PID**: Use `$PPID` to find the Claude process PID. All temp files are keyed by this.

2. **Read temp files**: Use Bash to read each temp file. Handle missing files gracefully — they may not exist if the session is young or the daemon hasn't collected data yet.

3. **Read statusline data**: Run `cat /tmp/claude-statusline-$PPID 2>/dev/null` to get daemon-collected stats.

4. **Read tool counters**: Parse `/tmp/claude-tools-$PPID` — format is `toolname=count` per line, with `_total=N` for the grand total.

5. **Compute derived metrics**:
   - Cost per turn: `cost / turns`
   - Read/Write ratio: `(Read + Grep + Glob) / (Edit + Write)`
   - Context trend: direction from sparkline data (rising/stable/falling)
   - Peak activity: max value in timeline ring buffer

6. **Render**: Print the report using the format above with Unicode box-drawing characters.

## Rules

- This is a **read-only** skill. Never modify any files.
- If temp files are missing, state "Session data not yet available — run a few more turns to populate."
- Round costs to 2 decimal places, percentages to integers.
- Use color in output: green for healthy metrics, yellow for warnings, red for critical.
- The report should be generated in a single output — do not ask the user questions.
