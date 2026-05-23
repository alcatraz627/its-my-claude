---
name: create-skill
description: Guides the user through creating a new Claude Code skill. Asks structured questions one at a time, formalizes each answer into canonical skill language, shows a draft plan for approval, then writes the SKILL.md and a companion USAGE.md.
allowed-tools: Read, Write, Edit, Bash, Glob
user-invokable: true
argument-hint: "[skill-name]"
---

## Brief

Guides you step-by-step through creating a new Claude Code skill: asks structured questions, formalizes your answers into canonical skill language, shows a draft plan for approval, then writes the SKILL.md and a companion USAGE.md into the right directory.

# Create Skill

An interactive wizard that turns your description of a skill idea into a well-structured, production-ready SKILL.md. You provide intent; the wizard formalizes it and handles the boilerplate.

**What it produces:**

- `.claude/skills/<name>/SKILL.md` — full skill definition following the four-phase skeleton
- `.claude/skills/<name>/USAGE.md` — quick-reference card with usage, examples, caveats, and dependencies

## Usage

```
/create-skill [skill-name]
```

**Arguments:**

- `skill-name` (optional): The kebab-case name for the new skill. If not provided, the wizard will ask.

---

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, and post-run insights — for the entire
duration of this skill run.

Also read `.claude/skills/runtime-notes.md`. Scan all entries for:

- Naming patterns used by existing skills (helps Q1 validation)
- Common tool choices and phase structures (informs Q5 tool inference)
- Past failures or bugs to avoid repeating in the new skill's instructions

If `runtime-notes.md` does not exist yet, continue without it.

---

## How the Q&A Loop Works

For every question, the wizard follows this pattern:

1. **Ask** — print the question with a brief explanation of why it matters
2. **Wait** — do not proceed until the user responds
3. **Formalize** — rewrite the user's raw answer into polished, canonical skill language
4. **Confirm** — print the formalized version and ask: `"Does this capture it? Any changes?"` — wait for a response
5. **Iterate** — if the user requests changes, revise and re-confirm; repeat until the user accepts

Only move to the next question after the current answer is confirmed. Never skip a question.

---

## Phase 1 — Information Gathering

### Q1: Skill Name

**Only ask if not provided as an argument.**

Print:

```
What should the skill be called?
This becomes the /command-name users type. Use lowercase-with-hyphens (e.g., "code-review", "deps-audit").
→
```

Wait for input. Validate: must be lowercase, hyphens only, no spaces or special chars.

**Formalize:** `name: <normalized-name>`

**Confirm:** `"I'll use the name \`<name>\` — invoked as \`/<name>\`. Good?"`

---

### Q2: Goal

Print:

```
What does this skill do? What problem does it solve?
Describe it in 1–3 sentences — don't worry about precision yet, just the core idea.
→
```

Wait for input.

**Formalize:** Rewrite as a tight 1–2 sentence description:

- Start with a verb ("Scans…", "Generates…", "Guides…", "Analyzes…")
- Name the input, the action, and the output
- Avoid vague words like "helps" or "assists" — be concrete

Example transformation:

- Raw: "it should check all the components and see if they have tests"
- Formalized: "Scans all React components in `src/` and reports which ones lack a corresponding test file, outputting a checklist sorted by directory."

**Confirm:** Print the formalized version and ask for changes.

---

### Q3: Usage & Arguments

Print:

```
How is this skill invoked? What arguments does it take?
Examples:
  /skill-name                          (no args)
  /skill-name <required>               (one required arg)
  /skill-name <required> [optional]    (required + optional)
  /skill-name [flag | path]            (mutually exclusive)
→
```

Wait for input. The user might say "no arguments", "just a file path", "a question like arch-qa", etc.

**Formalize:** Produce:

1. The invocation syntax line
2. A bullet list of arguments with types and descriptions
3. A `argument-hint` value for the frontmatter

Example:

```
/deps-audit [--fix]

Arguments:
- `--fix` (optional): Automatically apply safe dependency updates
argument-hint: "[--fix]"
```

**Confirm:** Show the formalized usage block and ask for changes.

---

### Q4: Constraints

Print:

```
What should this skill NOT do? Any hard limits or guardrails?
Think about: destructive actions, files it shouldn't touch, decisions it shouldn't make autonomously, scope limits.
(Press enter to skip if nothing comes to mind.)
→
```

Wait for input. Accept a skip/empty answer.

**Formalize:** If the user provided constraints, write them as a bullet list of clear prohibitions:

- "Never modify files outside `.claude/`"
- "Never commit or push — analysis only"
- "Never run `rm` without user confirmation"

If skipped, note: "No additional constraints beyond GUIDELINES.md defaults."

**Confirm:** Show the constraints list (or the skip note) and ask for changes.

---

### Q5: Tools

Print:

```
Which Claude tools will this skill need?

Available tools:
  Read        — read files from disk
  Write       — create new files
  Edit        — patch existing files
  Bash        — run shell commands
  Glob        — find files by pattern
  Grep        — search file contents
  Task        — spawn subagents for complex research
  WebFetch    — fetch web content

List the ones that apply, or say "not sure" and I'll infer from the goal.
→
```

Wait for input.

**Formalize:** Produce a clean `allowed-tools` frontmatter line. If the user said "not sure", infer based on the goal:

- Reads files → `Read, Glob, Grep`
- Writes/creates output → add `Write`
- Patches existing files → add `Edit`
- Runs commands → add `Bash`
- Does deep research → add `Task`

**Confirm:** Show `allowed-tools: <list>` and ask for changes.

---

### Q6: Example Use Cases

Print:

```
Give 2–3 concrete examples of running this skill — what the user types and what they get back.
These become the examples in the SKILL.md and USAGE.md.
→
```

Wait for input. The user might be rough: "like you run it and it scans and shows a list".

**Formalize:** Turn each example into:

```
/skill-name argument
→ [One-line description of what the output looks like]
```

Example:

```
/deps-audit
→ Prints a table of 14 outdated packages grouped by risk level (breaking / minor / patch)

/deps-audit --fix
→ Automatically updates 8 safe (patch-level) packages and lists 6 that need manual review
```

**Confirm:** Show the formatted examples and ask for changes.

---

### Q7: Anything Else

Print:

```
Anything else worth capturing?
Think about:
  - Does it chain with another skill? (e.g., calls /create-report at the end)
  - Special output format? (markdown file, HTML, terminal-only)
  - Edge cases or error conditions to handle?
  - Post-run actions? (open a file, print a summary, update a log)
(Press enter to skip.)
→
```

Wait for input. Accept a skip.

**Formalize:** If provided, add a "Notes" section summarizing these points in bullet form.

**Confirm:** Show the notes (or skip confirmation) and ask for changes.

---

## Phase 2 — Planning

After all 7 questions are confirmed, generate a **plan outline** — not the full file, just the structure. Print it clearly so the user can review before anything is written.

**Format:**

```
─────────────────────────────────────────────────────
  Draft plan for /<name>
─────────────────────────────────────────────────────

  Frontmatter
    name:          <name>
    description:   <formalized goal — truncated to 80 chars>
    allowed-tools: <tool list>
    argument-hint: <usage hint>

  ## Brief
    <1-2 sentence brief>

  ## Workflow

    Phase 1 — Information Gathering
      [Describe what data the skill collects and how]

    Phase 2 — Planning
      [How the skill decides what to do with what it found]

    Phase 3 — Execution
      [What it writes, edits, or runs]

    Phase 4 — Verification
      [How it confirms the output is correct]

  ## Notes
    [Constraints, integrations, edge cases — if any]

─────────────────────────────────────────────────────
  USAGE.md will also be written with:
    - Usage syntax + argument table
    - 2-3 worked examples
    - Caveats and known limitations
    - Dependencies (other skills, tools, files it reads)
─────────────────────────────────────────────────────
```

Then ask:

```
Does this plan look right? Describe any changes, or say "looks good" to write the files.
→
```

Wait for input. If changes requested: revise the relevant section(s) of the plan and re-print the full updated plan. Repeat until the user accepts.

---

## Phase 3 — Execution

Once the plan is approved:

### 3.1 — Create the directory

```bash
mkdir -p .claude/skills/<name>
```

Print: `  Created .claude/skills/<name>/`

### 3.2 — Check for existing SKILL.md

```bash
ls .claude/skills/<name>/SKILL.md 2>/dev/null
```

If it exists: print a warning and ask:

```
.claude/skills/<name>/SKILL.md already exists. Overwrite? (yes / no)
→
```

If "no" → stop and report. If "yes" → proceed.

### 3.3 — Write SKILL.md

Write the full SKILL.md expanding the approved plan into a complete, working skill definition.

**Required elements:**

- Frontmatter with all fields (`name`, `description`, `allowed-tools`, `user-invokable: true`, `argument-hint`)
  - `description`: must start with a verb ("Scans…", "Generates…", "Guides…"), name the input + action + output, max 2 sentences, no vague words like "helps" or "assists"
  - `argument-hint`: must use `<name>` for required args and `[name]` for optional; e.g. `"<target> [--fix]"` or `"[skill-name | all]"`; use `""` if the skill takes no arguments
- `## Brief` immediately after frontmatter `---`
- `## Step 0: Load Shared Guidelines and Runtime Context` preamble block (copy verbatim from template below)
- `## Usage` section with syntax and argument table
- Four phases following the approved plan
- `## Notes` section (if constraints or integrations exist)

**Step 0 preamble template (copy verbatim):**

```markdown
## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.
```

Print: `  Writing .claude/skills/<name>/SKILL.md ...`

### 3.4 — Write USAGE.md

Write a concise quick-reference card at `.claude/skills/<name>/USAGE.md`.

**Structure:**

```markdown
# /<name> — Usage Guide

## What it does

[1-2 sentence summary]

## Usage

\`\`\`
/<name> [arguments]
\`\`\`

| Argument | Type | Description |
| -------- | ---- | ----------- |
| ...      | ...  | ...         |

## Examples

### Example 1: [title]

\`\`\`
/<name> argument
\`\`\`
[What happens and what the output looks like]

### Example 2: [title]

...

## Caveats

- [Known limitation or gotcha]
- [What the skill does NOT do]
- [Any prerequisite state required]

## Dependencies

| Dependency    | Type         | Notes                      |
| ------------- | ------------ | -------------------------- |
| GUIDELINES.md | Shared rules | Read at start of every run |
| [other skill] | Skill        | Called at step N           |
| [file/dir]    | File         | Must exist before running  |

## Tips

- [Usage tip]
- [How to combine with other skills]
```

Print: `  Writing .claude/skills/<name>/USAGE.md ...`

### 3.5 — Format both files

```bash
npx prettier --write .claude/skills/<name>/SKILL.md .claude/skills/<name>/USAGE.md
```

Print the prettier output.

---

## Phase 4 — Verification

Read back both written files and confirm they exist and are non-empty:

```bash
ls -la .claude/skills/<name>/
```

Print a final summary:

```
─────────────────────────────────────────────────────
  ✓ Skill created: /<name>
─────────────────────────────────────────────────────

  Files written:
    .claude/skills/<name>/SKILL.md     (<N> lines)
    .claude/skills/<name>/USAGE.md     (<N> lines)

  To use: type /<name> in any Claude Code session.
  To review: /user-config edit → select the new skill.

─────────────────────────────────────────────────────
```

---

## Notes

- The wizard never writes files until Phase 3 — all Q&A and planning happen first.
- If the user gives vague or partial answers, the formalization step is where the wizard adds structure and precision. Trust the process.
- The wizard should not invent constraints the user didn't imply — only formalize what was actually described.
- Skill names must be unique. Before writing, check for an existing directory with the same name.
- After writing, remind the user that `/user-config` can be used to review, explain, edit, or simplify the new skill.
