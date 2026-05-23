---
name: gotchas-update
description: Appends a new dated entry to gotchas.md after a bug fix, architectural discovery, or lesson learned — keeping the project's developer pitfall log current.
allowed-tools: Read, Edit, Write, Bash
user-invokable: true
argument-hint: "[description]"
---

## Brief

Prompts for a short description of a new pitfall or lesson learned, then appends a dated entry to `gotchas.md` — the project's existing developer notes file. Run after fixing an unexpected bug or discovering a non-obvious behavior.

# Gotchas Update

Keeps the project's `gotchas.md` file current with dated entries about pitfalls, surprises, and lessons learned during development.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after.

## Usage

```
/gotchas-update [description]
```

**Arguments:**
- `description` (optional): One-line description of the gotcha. If not provided, the skill will ask.

---

## Phase 1 — Read the Argument

If a `description` argument was provided, use it directly.

If not, ask:

```
What's the gotcha? Describe it in 1–2 sentences:
→
```

Wait for input.

---

## Phase 2 — Read Existing Gotchas

Read `gotchas.md` to understand the existing format:

```bash
ls gotchas.md 2>/dev/null
```

- **If found:** Read the file. Note the format used for entries (date style, heading style, etc.) and replicate it exactly.
- **If not found:** Create a new file with a standard header (see Phase 3).

---

## Phase 3 — Format the New Entry

Format the entry to match the existing file's style, or use this default:

```markdown
## YYYY-MM-DD — [one-line title]

[1–3 sentence description of the pitfall, what caused it, and how to avoid it]

**Fix:** [What was done to resolve it, or what to watch out for]
```

Get today's date:
```bash
date '+%Y-%m-%d'
```

---

## Phase 4 — Append the Entry

Acquire a lock, append the entry, release:

```bash
bash ~/.claude/skills/shared/lock-file.sh acquire "gotchas.md" "gotchas-update"
```

- If the file exists: use `Edit` to append to the end
- If the file does not exist: use `Write` to create it with a header + the first entry:

```markdown
# Gotchas

Developer notes on non-obvious behaviors, pitfalls, and lessons learned.
Newest entries at the bottom.

---

[first entry here]
```

```bash
bash ~/.claude/skills/shared/lock-file.sh release "gotchas.md" "gotchas-update"
```

---

## Phase 5 — Confirm

Print:

```
✓ Gotcha added to gotchas.md
  [YYYY-MM-DD] [title]
```

---

## Notes

- This skill appends only — never modifies or deletes existing entries.
- If the description is vague, ask one clarifying question before writing.
- The `gotchas.md` file is in the project root (same level as `package.json`).
