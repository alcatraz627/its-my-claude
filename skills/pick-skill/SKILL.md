---
name: pick-skill
description: Reads user intent, loads the skill catalogue, asks clarifying questions if needed, then confirms and executes the best matching skill end-to-end.
allowed-tools: Read, Bash, Glob, Grep
argument-hint: "[prompt]"
user-invokable: true
---

## Brief

Routes a raw user prompt to the most appropriate skill or agent. Asks clarifying questions to resolve ambiguity, confirms the chosen skill, executes it, and optionally runs /create-report on any markdown output produced.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules — forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the **file lock protocol**
— for the entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

## Usage

```
/pick-skill [prompt]
```

| Argument | Type     | Description                                                                          |
| -------- | -------- | ------------------------------------------------------------------------------------ |
| `prompt` | optional | Raw intent or question in plain language. If omitted, an interactive prompt appears. |

## Phase 1 — Information Gathering

### 1.1 Load skill catalogue

Glob all `skills/*/SKILL.md` files. For each, extract:

- The frontmatter `name` field (or derive from directory name)
- The `description` frontmatter field
- The `## Brief` section (first paragraph only)

Build an in-memory catalogue: `{ name, description, brief }[]`.

Print: `Loaded N skills from .claude/skills/`

### 1.2 Collect user prompt

If `[prompt]` was passed as an argument, use it directly.

If not, prompt interactively:

```bash
gum write --placeholder "What do you want to do? Describe in plain language..." --width 80
```

Print the captured prompt back to confirm it was received.

## Phase 2 — Planning (Match + Clarify)

### 2.1 Score and match

Compare the user's prompt against each skill's `name`, `description`, and `brief` using keyword and intent matching. Identify:

- **Strong match:** One skill clearly fits — proceed to 2.3
- **Ambiguous match:** 2–3 plausible skills — ask clarifying questions (2.2)
- **No match:** No skill fits well — proceed to 2.4

### 2.2 Clarifying questions (ambiguous only)

Ask at most **2** targeted questions using `gum choose` or `gum input` to narrow intent:

```bash
gum choose "Option A: description" "Option B: description" "Option C: description"
```

Use the answer to re-score and select the single best match.

### 2.3 Present chosen skill

Print:

```
Chosen skill: /<name>
Rationale:    [one sentence explaining why this skill fits]
```

Ask for confirmation:

```bash
gum confirm "Run /<name>?"
```

If confirmed → Phase 3.
If declined → ask what to adjust, re-score, repeat (up to 2 re-matches before stopping).

### 2.4 No-match fallback

If no skill fits:

1. Explain the gap: "No existing skill covers [X] because [reason]."
2. Print the 3 closest partial matches with their briefs.
3. Suggest: "You could build this with `/create-skill`."

```bash
gum confirm "Open /create-skill to build a new skill for this?"
```

Stop here — do not attempt to handle the task without a confirmed skill.

## Phase 3 — Execution

### 3.1 Invoke the chosen skill

Invoke the confirmed skill, passing the user's original prompt as context. The invoked skill takes full ownership of the task — follow its own workflow, tools, and output format.

Do not constrain what the invoked skill does. It may read files, write files, run commands, or spawn subagents as needed.

### 3.2 Post-run: offer /create-report

After the invoked skill completes, check if it produced any `.md` output file. If so:

```bash
gum confirm "Generate an HTML report from the output with /create-report?"
```

If confirmed → invoke `/create-report` on the output file.

## Phase 4 — Verification

After execution completes:

1. Confirm the invoked skill exited successfully (no unhandled errors reported).
2. Print a closing summary:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_complete "pick-skill" \
  "Skill invoked=/<name>" \
  "Rationale=[one sentence]" \
  "Outcome=[brief description of what was produced]"
```

3. Write a runtime-notes entry:

```bash
cat > /tmp/runtime-note-entry.md << 'ENTRY'
## pick-skill: routed to /<name> — [YYYY-MM-DD HH:MM]
**Purpose:** [what the user's original prompt was trying to accomplish]

**Insights:**
1. [point about matching accuracy or keywords that worked]
2. [point about clarifying questions used or skipped]
3. [point about execution outcome or post-run report]

---
ENTRY

bash ~/.claude/skills/shared/prepend-runtime-note.sh "pick-skill" /tmp/runtime-note-entry.md
```

## Notes

- Never executes a skill without explicit `gum confirm` approval
- Delegates all file/tool permissions to the chosen skill — pick-skill itself has minimal footprint
- No-match path always surfaces 3 closest partial matches before suggesting `/create-skill`
- Post-run `/create-report` is offered, not forced — skip if the invoked skill produced no markdown output
- If the user declines the matched skill, re-ask rather than giving up — attempt up to 2 re-matches before stopping
