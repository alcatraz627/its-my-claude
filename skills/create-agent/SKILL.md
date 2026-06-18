---
name: create-agent
description: Reads all existing skills as context then scaffolds a new autonomous agent SKILL.md — with context: fork, no interactive prompts, and structured output — from user instructions, or rewrites an existing skill in agent format. Suggests a template when a similar skill exists.
allowed-tools: Read, Write, Edit, Bash, Glob, Skill
user-invokable: true
argument-hint: "<instructions | existing-skill-name>"
---

## Brief

Scaffolds new autonomous agent SKILL.md files or converts existing skills to agent format. Reads the full skill catalogue to detect template matches, derives a plan, shows a diff-style preview before writing, and validates that the result has `context: fork`, no interactive prompts, and the Claude-consumption shape (action-oriented routing description + tiered output contract).

The scaffolded agent body follows the Claude-consumption standard in `~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md` — the agent body is system-prompt material read by Claude, so it is shaped for a model, not for a human reader.

# Create Agent

Unlike `/create-skill` which builds interactive Q&A wizards with approval gates, `/create-agent` specializes in **autonomous agents** — skills that run unattended in a forked context, read files or run commands, and return a single structured report with no mid-run user interaction.

**What it produces:**

- `.claude/skills/<name>/SKILL.md` — agent definition with `context: fork`, autonomous multi-phase workflow, structured terminal report output
- `.claude/skills/<name>/USAGE.md` — quick-reference card

**Two modes:**

- **New**: User describes what to automate → agent scaffolded from scratch (or from a suggested template)
- **Convert**: User passes an existing skill name → that skill's SKILL.md rewritten in agent format

## Usage

```
/create-agent <instructions | existing-skill-name>
```

| Argument       | Type     | Description                                                                                                    |
| -------------- | -------- | -------------------------------------------------------------------------------------------------------------- |
| `instructions` | required | Natural-language description of what the agent should do, OR an existing skill name to convert to agent format |

**Examples:**

```
/create-agent "scan all api routes and report missing auth guards"
/create-agent route-audit
/create-agent "compare backend pydantic models with frontend TypeScript types"
```

---

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

## Phase 1 — Load Skill Catalogue

### 1.1 — Discover all existing skills

```
Glob(".claude/skills/*/SKILL.md")
```

For each skill found, read the frontmatter (`name`, `description`, `allowed-tools`, `context`) and the `## Brief` section (first paragraph only). Build a catalogue:

| Skill   | Brief (truncated)                   | Has `context: fork`? |
| ------- | ----------------------------------- | -------------------- |
| arch-qa | Answers tech architecture questions | yes                  |
| …       | …                                   | …                    |

Print: `  Loaded N existing skills into context.`

### 1.2 — Determine mode

Parse the `<instructions>` argument:

1. Normalize: strip whitespace, lowercase
2. Compare against all skill `name` fields in the catalogue (exact match)
3. **If exact match found:** set `MODE=convert`, `TARGET=<skill-name>` — print: `  Mode: convert → <skill-name>`
4. **If no match:** set `MODE=new`, `INTENT=<instructions>` — print: `  Mode: new → "<intent>"`

---

## Phase 2 — Analysis

### 2.1 (convert mode) — Analyze the existing skill

Read `.claude/skills/<TARGET>/SKILL.md` in full.

Scan for agent-incompatible patterns:

| Pattern                                                       | Action                                                         |
| ------------------------------------------------------------- | -------------------------------------------------------------- |
| `AskUserQuestion` call                                        | Remove — agents cannot pause for user input in forked context  |
| `"Wait for input"` string                                     | Remove — same reason                                           |
| `gum confirm` / `gum choose`                                  | Remove — no interactive TTY in forked context                  |
| `context: fork` already present                               | Note — skill is already an agent; offer to improve/restructure |
| Self-modification steps (Edit/Write own SKILL.md)             | Flag — unusual for agents; keep only if clearly intentional    |
| Self-update instructions ("update this file after answering") | Remove — agents don't learn by editing themselves              |

Print a conversion summary:

```
  Skill: <name>
  Interactive elements to remove: [list or "none"]
  Self-update references to remove: [list or "none"]
  Will add: context: fork
  Phases to preserve: [list exploration/analysis phases]
```

### 2.2 (new mode) — Find template candidates

Score each catalogued skill for similarity to `INTENT` using keyword overlap between the intent and each skill's name, description, and brief. Look for:

- Similar domain keywords (e.g., "routes" → `route-audit`; "types" → `type-audit`)
- Similar output type (audit report, scaffolded files, terminal summary)
- Similar tool requirements (file-reading → Read/Glob/Grep; shell commands → Bash)

**If a skill scores high similarity** (clear thematic match):

```
  Suggested template: <skill-name>
    Brief: <brief text>
    Reason: [one-sentence rationale]
  Use as template? (yes / no)
  →
```

Wait for input. If "yes": read the template skill's SKILL.md in full and use its phase structure as a starting point.

If "no" or no candidate found: proceed without a template.

---

## Phase 3 — Plan

Generate the agent SKILL.md plan. **Do not write files yet.**

### 3.1 — Agent name

- **Convert mode:** Keep `<TARGET>` name. Existing SKILL.md will be overwritten.
- **New mode:** Derive from intent — lowercase, 2–4 words, hyphens, verb-noun form (e.g., `route-audit`, `api-diff`, `type-scan`). Print:

```
  Proposed name: <name>  (invoked as /<name>)
  Good? Or enter a different name:
  →
```

Wait for input.

### 3.2 — Derive the agent body shape

The scaffolded body follows the Claude-consumption shape — **no interactive gates** anywhere. Don't bake a fixed "Information Gathering → Analysis → Report" template into every agent; that rigid three-phase skeleton fits an audit but not, say, a generator or a sync-checker. Instead, fit the body to what the agent actually does, in this order:

```
1. ONE-LINE IDENTITY      A single sentence: what this agent is and the one job it does.
                          (e.g. "Scans App Router route files and flags missing auth guards.")

2. WHEN TO INVOKE         The trigger — the situation that should route work here, in the
                          user's terms. (e.g. "after editing auth middleware, or before a PR
                          that touches a mutation handler.")

3. WORKFLOW (numbered)    The autonomous steps the agent runs, or a loop if it iterates. Each
                          step is an action on real files/commands — no prompts between them.
                          Match the step count to the task; a sync-checker may be 2 steps, an
                          audit 4. Don't pad to three.

4. CHECKLIST / HEURISTICS A few canonical things to look for or rules to apply — not an
                          exhaustive edge-case enumeration. Heuristics + examples beat lists.

5. OUTPUT CONTRACT        The load-bearing section. A tiered, structured block the parent
                          agent consumes (see the report format in §4.3). Put it where it
                          can't be missed.
```

This is the shape from `claude-consumption-spec.md` (§ "Shared section shape"). The output contract is what makes the agent's work machine-consumable by the parent — prioritize it over flavor.

For convert mode: map the existing skill's phases onto this shape. Remove interactive steps, preserve all exploration logic, keep the step count the original needed.

For new mode: derive the workflow from intent, using template structure if a template was accepted.

### 3.2.1 — Write the routing `description`

The frontmatter `description` drives Claude Code's delegation — Claude reads it to decide when to route work to this agent. Write it **action-oriented**: a job plus its trigger, not a capability list.

- Good: `"Inspect changed auth routes and flag handlers missing an auth guard or input validation. Use after editing middleware or before a PR touching mutations."`
- Weak: `"A security expert for Next.js routes."` (an identity, not a trigger — routes poorly.)

The shape is **verb + object + trigger**: what it does, to what, and the situation that should invoke it. Include a "use after X" / "use before declaring Y done" clause when there's a natural trigger moment — it encourages proactive pickup.

### 3.3 — Print the plan

```
─────────────────────────────────────────────────────
  Agent plan: /<name>
  [Mode: convert | new]
─────────────────────────────────────────────────────
  Frontmatter
    name:           <name>
    description:    <action-oriented: verb + object + trigger; see §3.2.1>
    allowed-tools:  <list>
    argument-hint:  <hint>
    context:        fork      ← key agent property
    user-invokable: true

  ## Brief
    <1–2 sentence brief>

  Identity
    <one-line: what this agent is and the one job it does>

  When to invoke
    <the trigger situation, in the user's terms>

  Workflow
    <numbered autonomous steps — match count to the task, no prompts>

  Checklist / heuristics
    <a few canonical things to look for / rules to apply>

  Output contract
    <tiered structured block the parent consumes>

  [Convert mode only — Changes from original:]
    ✗ Removed: [interactive elements]
    ✗ Removed: [self-update references]
    + Added:   context: fork
    ✎ Changed: [reshaped workflow to fit the consumption shape, if any]
─────────────────────────────────────────────────────
```

Then ask:

```
Does this plan look right? Describe any changes, or say "looks good" to write the files.
→
```

Wait for input. Revise and re-print if needed.

---

## Phase 4 — Execution

### 4.1 — Create directory (new mode only)

```bash
mkdir -p .claude/skills/<name>
```

Print: `  Created .claude/skills/<name>/`

### 4.2 — Check for existing SKILL.md (new mode only)

```bash
ls .claude/skills/<name>/SKILL.md 2>/dev/null
```

If exists: print warning and ask `"Overwrite? (yes / no)"`. If "no" → stop.

Convert mode always overwrites the existing SKILL.md.

### 4.3 — Write SKILL.md

Write a complete agent SKILL.md. The body follows the Claude-consumption shape from `~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md` — it's system-prompt material a model reads, so it's a tight operating procedure, not an essay. **Required elements:**

- Frontmatter: `name`, action-oriented `description` (§3.2.1), `allowed-tools`, `user-invokable: true`, `argument-hint`, **`context: fork`**
- `## Brief` immediately after frontmatter `---`
- `## Step 0` preamble (copy verbatim from GUIDELINES.md template)
- `## Usage` section with argument table
- The body shape from §3.2: one-line identity → when-to-invoke trigger → numbered workflow (count fit to the task) → checklist/heuristics → the output contract below — with no `AskUserQuestion`, no "Wait for input", no `gum` interactives anywhere
- `## Notes` section with any constraints or caveats

Keep emphasis plain. Reserve ALL-CAPS / "MUST" for the rare load-bearing guardrail — on current models they over-trigger when overused.

**Standard tiered output contract for the generated agent — this is the load-bearing section, the structured block the parent agent consumes:**

```
─────────────────────────────────────────────────────
  <Agent Name>: <scope or input>
─────────────────────────────────────────────────────

  ── ERRORS (must fix) ──────────────────────────────
  ✗ [file:line] — [description]

  ── WARNINGS (should fix) ──────────────────────────
  ⚠ [file:line] — [description]

  ── LOOKS GOOD ─────────────────────────────────────
  ✓ [what passed]

  ── SUMMARY ────────────────────────────────────────
  Errors: N | Warnings: N | Files scanned: N
─────────────────────────────────────────────────────
```

That errors/warnings/summary block fits an **audit-style** agent. Tier the contract to what the agent actually returns: a generator reports created files and a next step; a sync-checker reports matches/mismatches; a researcher reports findings with confidence + severity. Keep it tiered and structured so the parent can parse it — that's the invariant, not the specific tier names.

Acquire lock before writing:

```bash
bash ~/.claude/skills/shared/lock-file.sh acquire ".claude/skills/<name>/SKILL.md" "create-agent"
```

Write, then release lock. Print: `  Writing .claude/skills/<name>/SKILL.md ...`

### 4.4 — Write USAGE.md

Write a quick-reference card. Standard structure:

- **What it does** (1-2 sentences)
- **Usage** syntax + argument table
- **Examples** (2-3 worked examples)
- **Caveats**: mention `context: fork`, that it never prompts mid-run, and any destructive action warnings
- **Dependencies** table

Acquire lock, write, release. Print: `  Writing .claude/skills/<name>/USAGE.md ...`

### 4.5 — Format both files

```bash
npx prettier --write .claude/skills/<name>/SKILL.md .claude/skills/<name>/USAGE.md
```

---

## Phase 5 — Verification

### 5.1 — Mechanical checks

Read back `.claude/skills/<name>/SKILL.md` and confirm:

| Check                                 | Expected |
| ------------------------------------- | -------- |
| `context: fork` in frontmatter        | present  |
| action-oriented `description` (§3.2.1)| present  |
| `## Brief` section                    | present  |
| `## Step 0` preamble                  | present  |
| one-line identity + when-to-invoke    | present  |
| tiered output contract                | present  |
| `AskUserQuestion` in body             | absent   |
| `"Wait for input"` in body            | absent   |

Print result for each check. If any check fails, describe what to fix manually.

### 5.2 — Skeptical review before declaring done

Run `/skeptical-review` on the scaffolded agent before calling it done. It forks a fresh adversarial reviewer grounded in the actual tree to check the new SKILL.md against sibling agents — catching a weak routing description, a vague workflow, or an output contract the parent can't parse that the mechanical checks miss. Address or note its findings; don't print the success summary until the review has run.

Print final summary:

```
─────────────────────────────────────────────────────
  ✓ Agent created: /<name>  [convert | new]
─────────────────────────────────────────────────────

  Files written:
    .claude/skills/<name>/SKILL.md   (<N> lines)
    .claude/skills/<name>/USAGE.md   (<N> lines)

  Agent properties:
    context: fork ✓   — runs in isolated context
    interactive:  ✓   — none (fully autonomous)

  To use: type /<name> in any Claude Code session.
  To review: /user-config edit → select the agent.
─────────────────────────────────────────────────────
```

---

## Notes

- **Key difference from `/create-skill`**: Agents have no interactive prompts. If the task needs mid-run user decisions — approval gates, Q&A loops, menu navigation — use `/create-skill` instead.
- **`context: fork` scope**: Fork isolates the conversation context window, not the filesystem. Agents still read and write real files and run shell commands — they just don't flood the main conversation with hundreds of tool-call results.
- **Convert mode overwrites**: The existing SKILL.md is replaced. Ensure git is clean before converting so you can revert with `git checkout .claude/skills/<name>/SKILL.md` if needed.
- **Template suggestion is heuristic**: Keyword overlap — always review the suggested skill's brief before accepting.
- **The generated body is Claude-facing**: The agent's SKILL.md body becomes a model's operating procedure, so it follows `~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md` (the consumption standard), not human-doc style. The routing `description` is a first-class design surface, not boilerplate — it drives Claude Code's delegation, so it reads as a job + trigger, not an identity.
- After the skill run, update `runtime-notes.md` via the standard `prepend-runtime-note.sh` pattern from GUIDELINES.md §7.
