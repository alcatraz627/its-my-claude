---
name: capabilities
description: Generates a report of everything this Claude instance can do — skills, hooks, MCP servers, memory, runtime architecture, widgets, and all std::claude infrastructure.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch
user-invokable: true
argument-hint: "[small | medium | large] [specific question]"
context: fork
---

## Brief

Self-discovering meta-skill that scans the actual Claude configuration and generates a report
of everything this Claude instance can do — beyond a factory-default Claude. Covers skills,
hooks, MCP servers, memory, WAL, scratchpad, assets, widgets, statusline, dreaming, and all
std::claude infrastructure. Maintains a cache but always verifies freshness.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

---

## Usage

```
/capabilities                      # medium report (default)
/capabilities small                # one-page executive summary
/capabilities large                # full deep-dive with examples
/capabilities "what MCP servers?"  # answer a specific question
```

| Argument | Description |
| -------- | ----------- |
| `small` | Compact summary: skill count, MCP server list, key features — fits in one screen |
| `medium` | Default: categorized inventory with brief descriptions and key stats |
| `large` | Full deep-dive: every skill's purpose, every hook's trigger, architecture diagrams, usage examples |
| `<question>` | Answer a specific question by searching the config (e.g., "how does memory work?", "what hooks exist?") |

---

## Discovery Sources — MANDATORY

Scan ALL of these locations. This list is the canonical discovery manifest. If a scan reveals
new locations not listed here, add them to this list in the report cache metadata for future runs.

### Core Configuration

| Source | What to extract |
| ------ | --------------- |
| `~/.claude/CLAUDE.md` | Global instructions, mandatory rules, behavioral config |
| `~/.claude/settings.json` | Permissions, enabled plugins, custom keybindings |
| `~/.claude/NAMESPACE.md` | std::claude namespace tree — all 18+ clusters, facets, surfaces |
| `~/.claude/GLOSSARY.md` | Terminology definitions |
| `~/.claude/LOOKUP.md` | Address book for all config files, scripts, hooks |
| `~/.claude/.mcp.json` | Global MCP server definitions (always-on) |
| `<project>/.mcp.json` | Project-local MCP servers (if in a project) |
| `~/.claude/mcp-catalog.json` | Full MCP catalog (available but not necessarily active) |

### Skills

| Source | What to extract |
| ------ | --------------- |
| `~/.claude/skills/*/SKILL.md` | All skill definitions — name, description, user-invokable, tools |
| `~/.claude/skills/GUIDELINES.md` | Shared skill rules |
| `~/.claude/skills/shared/` | Shared library: Python exports, Bash scripts, gum-tui |
| `~/.claude/skills/shared/README.md` | Full API reference for std::claude::shared |

### Hooks & Scripts

| Source | What to extract |
| ------ | --------------- |
| `~/.claude/settings.json` → `hooks` | All hook registrations: event, matcher, command |
| `~/.claude/scripts/` | All utility scripts |
| `~/.claude/skills/shared/*.sh` | Shared skill scripts |

### Runtime Architecture

| Source | What to extract |
| ------ | --------------- |
| `~/.claude/memory/` | Memory system — per-project MEMORY.md + individual memory files |
| `~/.claude/memory/global/` | Global memory tier — cross-project memories |
| `~/.claude/scratchpad/` | Scratchpad system — local + global tiers |
| `~/.claude/assets/` | Asset management — types, manifest, storage |
| `~/.claude/mistake-patterns.md` | Mistake pattern index |
| `~/.claude/proposals.jsonl` | Improvement backlog |
| `~/.claude/disabled-plugins.json` | Disabled plugin registry |

### WAL & Persistence

| Source | What to extract |
| ------ | --------------- |
| `.claude/wal.jsonl` or `.claude/wal.md` | Write-Ahead Log format and current state |
| `~/.claude/skills/runtime-notes.md` | Runtime notes system |
| `_checkpoint.claude.md` pattern | Core-dump / catchup checkpoint system |

### Widgets & UI

| Source | What to extract |
| ------ | --------------- |
| `~/.claude/widgets/` | Widget definitions (e.g., claude-instances) |
| `~/.claude/statusline/` | Statusline configuration, segments, profiles |
| `~/.claude/keybindings.json` | Custom key bindings |

### Agents & Automation

| Source | What to extract |
| ------ | --------------- |
| `~/.claude/agents/` | Agent definitions and personas |
| Agent SDK usage | Subagent patterns, team workflows |
| Scheduled triggers | Cron-based remote agents |

### Plugins

| Source | What to extract |
| ------ | --------------- |
| `~/.claude/settings.json` → `enabledPlugins` | Active marketplace plugins |
| `~/.claude/disabled-plugins.json` | Disabled plugins + reasons |

### External Integrations

| Source | What to extract |
| ------ | --------------- |
| Desktop automation | `desktop.sh` capabilities — screenshots, clicks, annotation |
| Shell memory (diy-mem) | Shell history tracking system |
| Dev servers guide | pm2 port conventions |
| `~/.claude/dev-servers-guide.md` | Server management rules |

---

## Phase 1 — Check Cache

1. Look for the most recent cache file in `~/.claude/skills/capabilities/cache/`:
   - Files named `capabilities-<YYYY-MM-DD>.json`
2. If a cache exists from **today** and the requested size matches:
   - Read it
   - Do a **quick freshness check**: compare skill count, MCP server count, and hook count
     against the current state (3 fast Glob/Grep operations)
   - If counts match: use cached data, note "Using cached report (verified fresh)" in output
   - If counts differ: discard cache, run full scan
3. If no cache or cache is stale: run full scan (Phase 2)

**Cache format** (JSON):
```json
{
  "generated_at": "2026-04-22T14:30:00Z",
  "size": "medium",
  "fingerprint": {
    "skill_count": 42,
    "mcp_server_count": 8,
    "hook_count": 56,
    "script_count": 30,
    "memory_count": 12
  },
  "discovery_sources": ["<list of all paths scanned — update if new ones found>"],
  "sections": { ... }
}
```

---

## Phase 2 — Full Discovery Scan

Scan every source in the Discovery Sources table above. For each:

1. Check if the path/file exists
2. Extract the relevant information
3. Count items (skills, hooks, servers, scripts, memory files, etc.)
4. Note any NEW locations not in the Discovery Sources list

**Scan order** (optimized for speed — fast checks first):

1. `settings.json` — plugins, hooks, permissions (single file, high info density)
2. Skill SKILL.md files — Glob + read frontmatter only for `small`, full read for `large`
3. `.mcp.json` files — global + project + catalog
4. Scripts directory — `ls` for count and names
5. Memory files — Glob for count, read MEMORY.md index
6. Everything else — widgets, statusline, agents, WAL, assets

Print progress as you scan:
```
Scanning skills...      42 found
Scanning hooks...       56 registered
Scanning MCP servers... 8 active, 14 in catalog
Scanning scripts...     30 found
Scanning memory...      12 files
...
```

---

## Phase 3 — Generate Report

### Size: `small`

One-screen summary. Format:

```
─────────────────────────────────────────────────────
  Claude Capabilities — <date>
─────────────────────────────────────────────────────

  Skills:       42 (38 user-invokable)
  MCP Servers:  8 active / 14 in catalog
  Hooks:        56 registered
  Scripts:      30 utility scripts
  Memory:       12 files (2 tiers)
  Plugins:      4 active / 8 disabled

  Key Differentiators:
  • Statusline with live widgets
  • Session deep-scan & frustration detection
  • Desktop automation (screenshots, clicks, annotation)
  • Write-Ahead Log with checkpoint/catchup
  • Auto memory across sessions
  • Mistake pattern tracking
  • Improvement proposal backlog
  • Shell command history tracking

─────────────────────────────────────────────────────
```

### Size: `medium` (default)

Categorized inventory. Group by namespace cluster:

```
─────────────────────────────────────────────────────
  Claude Capabilities Report — <date>
─────────────────────────────────────────────────────

  ## Skills (42)

  ### Development
  /git-setup       — Repo init, health audit, maintenance
  /scaffold        — Project scaffolder with wizard
  /write-docs      — Technical documentation generator
  ...

  ### Analysis
  /arch-qa         — Architecture Q&A by tracing code paths
  /scan-sessions   — Deep-scan sessions for patterns
  ...

  ### Output
  /create-report   — Markdown → HTML report (13 styles)
  /generate-pdf    — Markdown → styled PDF
  /diagram         — Terminal diagrams
  ...

  ## MCP Servers (8 active)

  | Server | Scope | Purpose |
  | ------ | ----- | ------- |
  | github | global | GitHub API operations |
  | ...    | ...    | ...     |

  ## Hooks (56)

  ### PreToolUse (N)
  - Block rm commands → safe-delete enforcement
  - ...

  ### PostToolUse (N)
  - ...

  ## Runtime Architecture

  ### Persistence
  - WAL (write-ahead log) — session action tracking
  - Core-dump / Catchup — checkpoint and restore
  - Memory (2 tiers) — per-project + global
  - Scratchpad (2 tiers) — plans + learnings
  - Runtime notes — cross-session skill insights

  ### Automation
  - Hooks — 56 event-driven shell commands
  - Scheduled triggers — cron-based remote agents
  - Desktop automation — screenshots, clicks, annotation

  ### UI
  - Statusline — live segments + profiles
  - Widgets — claude-instances tracker
  - Banner — session greeting

  ## Unique Capabilities
  [List things factory Claude cannot do]

─────────────────────────────────────────────────────
```

### Size: `large`

Full deep-dive. Everything in `medium` plus:
- Every skill's full description and usage syntax
- Every hook's trigger condition and command
- Every MCP server's tools list
- Architecture diagrams (using `/diagram` style ASCII art)
- Example invocations for key skills
- Memory file contents summary
- Proposal backlog summary
- Mistake pattern summary
- Shell memory system details
- Desktop automation capabilities and permissions
- Keybinding customizations
- Plugin details (active + disabled with reasons)

For `large`, generate as an HTML report via `/create-report` with the `dashboard` style.

### Specific Questions

If the user provides a question instead of a size keyword:

1. Parse the question for topic keywords
2. Scan only the relevant Discovery Sources
3. Answer the question directly with supporting evidence from the config
4. Keep the response focused — don't generate a full report

Examples:
- "what MCP servers are available?" → scan `.mcp.json` + catalog, list all with status
- "how does memory work?" → read memory dir structure, MEMORY.md, explain the tiers
- "what hooks are registered?" → parse settings.json hooks section, categorize by event

---

## Phase 4 — Cache & Output

1. **Write cache:** Save the report data to `~/.claude/skills/capabilities/cache/capabilities-<YYYY-MM-DD>.json`
   - Include the fingerprint counts for freshness checking
   - Include the discovery sources list (may have been updated during scan)
   - Prune cache files older than 7 days

2. **Output the report** to the terminal

3. **If `large` was requested:** Also generate an HTML report:
   - Write markdown to temp file
   - Invoke `/create-report` with `dashboard` style
   - Save to `~/.claude/assets/reports/capabilities-<YYYYMMDD>.html`

---

## Self-Updating Discovery

The Discovery Sources table in this SKILL.md is the starting point, but the config evolves.
During each scan:

1. Check if any new directories or files exist under `~/.claude/` that aren't in the table
2. If found, include them in the report and note: "New discovery: <path> — <what it contains>"
3. Update the cache's `discovery_sources` list so future runs check the new location
4. At the end of the run, if new sources were found, print:
   ```
   New config locations discovered:
   - ~/.claude/<new-path> — <description>
   Consider updating the SKILL.md discovery table.
   ```

This ensures the skill doesn't go stale as the config grows.

---

## Notes

- This skill is read-only — it never modifies configuration, only reports on it
- The `context: fork` frontmatter runs this in a subagent to avoid polluting the main context with discovery data
- Cache is per-day, not per-session — multiple runs on the same day reuse the cache if counts match
- For `large` reports, the scan may take 30-60 seconds due to reading many files — this is expected
- The skill should feel like running `neofetch` but for your Claude config — a quick snapshot of everything available
- When listing skills, always indicate which are user-invokable vs background-only
- The "Unique Capabilities" section should explicitly contrast with factory Claude — what can THIS instance do that a fresh `claude` install cannot?
