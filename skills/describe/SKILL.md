---
name: describe
description: Analyzes a named Claude skill, MCP server, plugin, or custom feature in depth — reads its prompt, code, and runtime notes, then generates a terminal-style HTML report with architecture diagrams, workflow breakdowns, examples, and operational insights.
allowed-tools: Read, Glob, Grep, Bash, Write, Agent
user-invokable: true
argument-hint: "<name>"
context: fork
---

## Brief

Deep-analyzes any Claude Code extension by name — skills, MCP servers, plugins, or custom
features — producing a structured terminal-themed HTML report via `/create-report`. Reads all
source files, maps the workflow, generates architecture diagrams, and compiles operational notes.

# Describe Skill

Generates a comprehensive, structured analysis of any named Claude Code extension. The output
is a terminal-style HTML report covering intent, architecture, workflow, tool usage, examples,
and operational notes — with inline ASCII diagrams.

## Usage

```
/describe <name>
```

**Arguments:**

- `name` (required): Name of the skill, MCP server, plugin, or custom feature to analyze.
  Examples: `create-report`, `mongodb`, `chrome-devtools`, `diagram`, `file-tools`

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the **file lock
protocol** — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock hygiene: run `bash ~/.claude/skills/shared/lock-file.sh cleanup` once at skill start
> to clear any stale locks from crashed sessions. Then acquire a lock via `lock-file.sh
acquire` before every Edit/Write, and release it immediately after. Never write to
> `runtime-notes.md` or any SKILL.md without holding its lock.

---

## Phase 1 — Discovery & Resolution

Resolve `<name>` to one or more source locations. Search in this order (stop at first match
category, but collect all files within that category):

### 1.1 — Skills Directory

```
Glob(".claude/skills/<name>/SKILL.md")
Glob(".claude/skills/<name>/USAGE.md")
Glob(".claude/skills/<name>/**/*")       # code, scripts, templates
```

If found, this is a **skill**. Collect:

- `SKILL.md` — the primary definition (frontmatter + workflow)
- `USAGE.md` — quick-reference card (if exists)
- All files in the skill directory (scripts, templates, configs)
- Runtime notes mentioning this skill: `Grep("<name>", path=".claude/skills/runtime-notes.md")`

### 1.2 — MCP Server (Project-level)

```
Read(".mcp.json")   # or the project's MCP config
```

Search for `<name>` in the MCP server definitions. If found, this is an **MCP server**. Collect:

- The server configuration block (command, args, env)
- Any tool schemas available via the MCP connection
- Related CLAUDE.md instructions mentioning this MCP server

### 1.3 — MCP Server (Global)

```
Read("~/.claude.json")
```

Search for `<name>` in global MCP server definitions. Same collection as 1.2.

### 1.4 — Plugin Registry

Check if `<name>` matches a known plugin prefix (e.g., `chrome-devtools`, `playwright`).
Plugins appear in MCP configs with a `plugin_` prefix pattern. Collect:

- Plugin MCP config entries
- Any skill files that reference this plugin (e.g., `.claude/skills/chrome-devtools-mcp/`)
- CLAUDE.md instructions mentioning the plugin

### 1.5 — Custom Feature in CLAUDE.md

Search all CLAUDE.md files for a section or feature matching `<name>`:

```
Grep("<name>", glob="**/CLAUDE.md")
Grep("<name>", path="~/.claude/CLAUDE.md")
```

If found, this is a **custom feature**. Collect the relevant CLAUDE.md sections.

### 1.6 — Ambiguity Resolution

If **no match** is found:

- Print: `No skill, MCP server, plugin, or feature found matching "<name>".`
- Use `AskUserQuestion` to ask the user to clarify or provide the correct name.
- Suggest close matches using fuzzy search across skill names and MCP server names.

If **multiple categories** match (e.g., `chrome-devtools` matches both a plugin and a skill directory):

- Use `AskUserQuestion` to let the user pick which one to analyze, or offer to analyze all.

---

## Phase 2 — Analysis

Parse all collected source files into a structured analysis. The analysis must cover these
sections, adapting to the item type:

### 2.1 — Identity & Intent

| Field       | Source                                          |
| ----------- | ----------------------------------------------- |
| Name        | Frontmatter `name` or MCP server key            |
| Type        | skill / mcp-server / plugin / custom-feature    |
| Description | Frontmatter `description` or inferred from docs |
| Invocation  | `/command`, MCP tool call, or usage pattern     |
| Arguments   | From `argument-hint` or tool schemas            |

Write a **1-paragraph plain-English summary** of what this item does and why it exists.

### 2.2 — Workflow & Phases

For **skills**: extract the phase structure from SKILL.md headings and content.
For **MCP servers**: map the available tools into logical groups by operation type.
For **plugins**: trace the interaction flow (connection → targeting → action → result).

Produce a numbered list of steps describing the execution flow from invocation to completion.

Generate an **architecture or flow diagram** using `/diagram`:

- Skills → flowchart of phases with decision points
- MCP servers → tree diagram of tool categories
- Plugins → sequence diagram of the interaction cycle

### 2.3 — Tool & Dependency Analysis

List all tools/dependencies this item uses:

| Dependency       | Type            | Purpose               |
| ---------------- | --------------- | --------------------- |
| `Read`           | Claude tool     | Reads source files    |
| `GUIDELINES.md`  | Shared file     | Loaded at startup     |
| `/create-report` | Skill chain     | Generates HTML output |
| `gum`            | External binary | TUI interactions      |

For MCP servers, list all available tools with a one-line description of each.

### 2.4 — Configuration & Frontmatter

For skills, extract and explain every frontmatter field:

- What it does
- Why it's set to its current value
- What would change if it were different

For MCP servers, explain the configuration:

- Connection method (stdio, SSE, etc.)
- Environment variables required
- Arguments and their purpose

### 2.5 — Examples & Usage Patterns

Extract examples from:

- USAGE.md example sections
- SKILL.md usage examples
- Runtime notes showing actual invocations and results

Present 2-4 concrete examples with:

- The invocation command
- What happens (step by step, briefly)
- What the output looks like

### 2.6 — Operational Notes

Compile from runtime-notes.md and any gotchas:

- **Known issues** or edge cases discovered in past runs
- **Performance notes** (how long it takes, what's expensive)
- **Tips** from runtime insights
- **Version history** — significant changes visible in the skill's evolution

### 2.7 — Interactive Clarification

At any point during analysis, if the agent determines that additional context from the user
would significantly improve the report quality, use `AskUserQuestion` to ask. Examples:

- "This MCP server has 25+ tools. Want me to focus on a specific tool group, or cover all?"
- "This skill chains with 3 other skills. Want me to include brief descriptions of those too?"
- "There are extensive runtime notes (15+ entries). Want the full history or just recent highlights?"

Keep questions focused and actionable. Maximum 2 clarifying questions per run.

---

## Phase 3 — Report Assembly

### 3.1 — Generate Diagrams

Invoke `/diagram` for each diagram identified in Phase 2. Capture the ASCII output and embed
it in the markdown as fenced code blocks.

Minimum diagrams:

- **Architecture/flow diagram** — the main workflow or tool taxonomy
- **Dependency diagram** (if the item has 3+ dependencies) — tree showing what it depends on

### 3.2 — Compose Markdown Report

Write the analysis to a temporary markdown file at `/tmp/describe-<name>.md`.

**Report structure:**

```markdown
# /describe: <name>

> <type> — <one-line description>

## Intent

<1-paragraph summary>

## At a Glance

| Field        | Value         |
| ------------ | ------------- |
| Type         | ...           |
| Invocation   | ...           |
| Arguments    | ...           |
| Tools Used   | ...           |
| Dependencies | ...           |
| Context      | fork / inline |

## Architecture

<ASCII diagram>

<Explanation of the diagram>

## Workflow

### Phase 1 — ...

<numbered steps>

### Phase 2 — ...

...

## Tool & Dependency Map

<dependency table>

<dependency tree diagram if applicable>

## Configuration

<frontmatter/config explanation>

## Examples

### Example 1: <title>

...

### Example 2: <title>

...

## Operational Notes

### Known Issues

- ...

### Performance

- ...

### Tips

- ...

### Runtime History

<highlights from runtime-notes>

## Analysis Metadata

| Field          | Value    |
| -------------- | -------- |
| Analyzed on    | <date>   |
| Source files   | <count>  |
| Lines analyzed | <approx> |
| Report style   | terminal |
```

### 3.3 — Generate HTML Report

Invoke `/create-report` on the markdown file:

```
/create-report /tmp/describe-<name>.md --style=terminal
```

This produces the final HTML output in `.claude/output/<timestamp>-describe-<name>/`.

---

## Phase 4 — Verification

### 4.1 — Confirm Output

Check that the HTML report was created:

```bash
ls -la .claude/output/*describe-<name>*/
```

Verify `index.html` exists and is non-empty.

### 4.2 — Print Summary

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_complete "describe" \
  "Target=<type> '<name>'" \
  "Source files=<N>" \
  "Runtime notes=<N> entries" \
  "Diagrams=<N> generated" \
  "Report=<absolute path to index.html>" \
  "Duration=<wall-clock time>" \
  "Tools used=<count>" \
  "Errors=<any issues, or none>"
```

### 4.3 — Open Report

After printing the summary, open the HTML report in the default browser:

```bash
open .claude/output/*describe-<name>*/index.html
```

---

## Notes

- **Read-only analysis** — never modify the target skill/MCP/plugin files being analyzed
- **Never execute** the target skill or its scripts — only read and document them
- **Output only** to `.claude/output/` via `/create-report` — never write to the target's directory
- **Interactive clarification** — use `AskUserQuestion` when the name is ambiguous (multiple
  matches) or when additional context from the user could improve the analysis depth. Maximum
  2 clarifying questions per run to avoid being chatty.
- **Chains with `/diagram`** — generates architecture and flow diagrams inline in the markdown
- **Chains with `/create-report --style=terminal`** — final output is a terminal-themed HTML report
- **Runtime notes** — always check for existing entries about the target to include operational
  history in the report
