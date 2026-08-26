# /describe — Usage Guide

## What it does

Deep-analyzes any Claude Code extension by name — skills, MCP servers, plugins, or custom
features — and produces a terminal-themed HTML report with architecture diagrams, workflow
breakdowns, tool maps, examples, and operational insights gathered from runtime notes.

## Usage

```
/describe <name>
```

| Argument | Type     | Description                                                                                            |
| -------- | -------- | ------------------------------------------------------------------------------------------------------ |
| `name`   | required | Name of the skill, MCP server, plugin, or custom feature to analyze (e.g., `create-report`, `mongodb`) |

## Examples

### Example 1: Describe a skill

```
/describe create-report
```

Analyzes the `/create-report` skill end-to-end:

- Reads `SKILL.md`, `USAGE.md`, and all scripts in the skill directory
- Maps the 4-phase workflow (argument handling → markdown parse → JSON transform → HTML render)
- Diagrams the 8-style system architecture and the LLM↔Node.js division of labor
- Pulls runtime notes for past performance observations and gotchas
- Outputs a terminal-style HTML report to `.claude/output/`

### Example 2: Describe an MCP server

```
/describe mongodb
```

Analyzes the MongoDB MCP server:

- Reads the MCP configuration from `.mcp.json` or `~/.claude.json`
- Lists and categorizes all 25+ available tools by operation type (CRUD, schema, admin, export)
- Generates a tree diagram of the tool taxonomy
- Documents connection model, environment variables, and required setup
- Outputs a terminal-style HTML report

### Example 3: Describe a plugin

```
/describe chrome-devtools
```

Analyzes the Chrome DevTools MCP plugin:

- Finds both the plugin MCP entries and the companion skill directory
- Traces the page targeting → DOM interaction → result flow
- Generates a sequence diagram of the debug→snapshot→analyze cycle
- Covers all sub-skills (debugging, troubleshooting, LCP optimization, a11y)
- Outputs a terminal-style HTML report

### Example 4: Describe a custom feature

```
/describe shell-mem
```

Analyzes the shell memory (diy-mem) system:

- Reads CLAUDE.md instructions, the skill's SKILL.md, and hook configurations
- Maps the auto-logging pipeline and MCP/CLI dispatcher
- Documents the log file format and cleanup lifecycle
- Outputs a terminal-style HTML report

## Caveats

- **Read-only** — never modifies the target's source files
- **Does not execute** the target — only reads and documents it
- **Runs in a forked context** (`context: fork`) — keeps the main conversation clean but
  means it cannot reference prior conversation history
- **Report generation depends on `/create-report`** — if that skill has issues, the HTML
  output step will fail (the markdown intermediate file at `/tmp/describe-<name>.md` will
  still be available)
- **MCP tool schemas** — for MCP servers, the analysis quality depends on whether the server
  is currently connected and exposing tool schemas. Disconnected servers can still be
  analyzed from config alone, but with less detail.
- **Maximum 2 clarifying questions** — the skill may ask the user for context via
  `AskUserQuestion` but limits itself to avoid being chatty

## Dependencies

| Dependency         | Type         | Notes                                                 |
| ------------------ | ------------ | ----------------------------------------------------- |
| `GUIDELINES.md`    | Shared rules | Read at start of every run                            |
| `runtime-notes.md` | Shared file  | Scanned for operational history about the target      |
| `/diagram`         | Skill chain  | Generates architecture and flow diagrams inline       |
| `/create-report`   | Skill chain  | Renders the final terminal-style HTML report          |
| `.mcp.json`        | Config file  | Project-level MCP server definitions                  |
| `~/.claude.json`   | Config file  | Global MCP server definitions                         |
| `CLAUDE.md`        | Config file  | Custom feature definitions and MCP usage instructions |

## Tips

- **Combine with `/improve-skill`** — run `/describe <skill>` first to understand it fully,
  then `/improve-skill <skill>` to fix any issues the analysis reveals
- **Use for onboarding** — when joining a project with many custom skills, run `/describe`
  on each one to build a quick understanding of the tooling landscape
- **MCP discovery** — if you're unsure what MCP servers are available, check `.mcp.json`
  first, then use `/describe` on each server name to understand their capabilities
- **The terminal style** is chosen for consistency with the CLI environment — if you prefer
  a different look, the intermediate markdown at `/tmp/describe-<name>.md` can be re-rendered
  with any `/create-report` style
