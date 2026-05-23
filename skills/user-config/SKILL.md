---
name: user-config
description: Lists and manages all Claude configuration in this project — guidelines, skill definitions, personal settings, and shared utilities. Use /user-config to view config or /user-config edit to interactively explain, edit, or simplify any item.
user-invokable: true
argument-hint: "[edit]"
---

## Brief

Provides a structured overview of all Claude configuration in .claude/ — guidelines, skill definitions, personal settings, and shared utilities. In edit mode, launches an interactive numbered menu to explain, edit, or simplify any config item.

# User Config Skill

Scans `.claude/` and presents a structured overview of every piece of Claude configuration in this project. For each skill, it reads or auto-generates a `## Brief` section. In `edit` mode it presents an interactive numbered menu where any item can be explained, edited, or simplified.

## Step 0: Load Shared Guidelines

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, and post-run insights — for the entire
duration of this skill run.

## Usage

```
/user-config [edit]
```

**Arguments:**
- *(no argument)*: Print a structured overview of all Claude config in `.claude/` and stop
- `edit`: Print the overview, then launch the interactive selection menu

---

## What This Skill Covers

| Category | File(s) | Purpose |
|---|---|---|
| General instructions | `.claude/personal.md` | User roles and profiles |
| Permissions | `.claude/settings.local.json` | Allowed bash commands (personal) |
| Shared permissions | `.claude/settings.json` | Team deny/ask rules, env vars, hooks |
| Hooks | `.claude/settings.json` → `hooks` key | Deterministic automation (PostToolUse, PreToolUse, etc.) |
| Shared rules | `.claude/skills/GUIDELINES.md` | Forbidden paths, retry, verbosity, timeouts, post-run |
| Path-scoped rules | `.claude/rules/*.md` | Rules that activate for specific file paths |
| Skills | `.claude/skills/*/SKILL.md` | All skill definitions (with briefs) |
| Shared utilities | `.claude/skills/shared/*.sh` | Reusable helper scripts |
| Run history | `.claude/skills/runtime-notes.md` | Post-run insights log |
| Project index | `.claude/project-index.md` | Generated project overview |

---

## Workflow

### Step 1: Discover all config files

Print: `Scanning .claude/ for configuration files...`

Discover in this order — print each path as it is found:

1. `Read .claude/personal.md` → print: `  ✓ personal.md`
2. `Read .claude/settings.local.json` → print: `  ✓ settings.local.json`
3. `Read .claude/settings.json` → print: `  ✓ settings.json` (or `  — settings.json not found`)
4. `Read .claude/skills/GUIDELINES.md` → print: `  ✓ skills/GUIDELINES.md`
5. `Glob(".claude/rules/*.md")` → for each match, print: `  ✓ rules/[filename]` (or `  — rules/ not found`)
6. `Glob(".claude/skills/*/SKILL.md")` → for each match, print: `  ✓ skills/[name]/SKILL.md`
7. `Glob(".claude/skills/shared/*")` → for each match, print: `  ✓ skills/shared/[filename]`
8. Check optional files (print exists/not found):
   - `.claude/skills/runtime-notes.md`
   - `.claude/project-index.md`

---

### Step 2: Extract or generate briefs for each skill

For each `SKILL.md` found in Step 1:

**2.1** — Print: `Reading brief for [skill-name]...`

**2.2** — Scan the file for a `## Brief` section (must appear before the `# Title` heading).

**2.3a — Brief found:** Extract the text immediately after `## Brief` up to the next heading. Print: `  ✓ [skill-name]: [brief text]`

**2.3b — Brief NOT found:**

Print: `  ✗ No brief found for [skill-name] — generating...`

Generate a 1–2 sentence brief that answers:
- What does this skill do?
- When should someone use it?

Then insert the `## Brief` section into the file using `Edit`, placing it **after the closing `---` of the frontmatter** and **before the `# Title` heading**:

```markdown
---
... frontmatter ...
---

## Brief
[generated brief text]

# Skill Title
```

Print: `  ✓ Saved brief for [skill-name]`

---

### Step 3: Print formatted overview

Source gum-tui.sh and render using this layout:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Claude Config — [project-root folder name]"

gum_divider "GENERAL CONFIG"
gum_kv "personal.md" "Roles: [list roles from file, comma-separated]"
gum_kv "settings.local.json" "Allowed: [comma-separated list from permissions.allow]"

gum_divider "GUIDELINES"
gum_kv "GUIDELINES.md" "Sections: [list ## headings, pipe-separated]"

gum_divider "SKILLS"
gum_table "Name,Brief" \
  "[name],[brief text]" \
  "[name],[brief text]"

gum_divider "SHARED UTILITIES"
gum_table "File,Description" \
  "[filename],[one-line description from script comments or filename]"

gum_divider "LOGS & GENERATED FILES"
gum_kv "runtime-notes.md" "[exists — N entries | not found]"
gum_kv "project-index.md" "[exists — last modified YYYY-MM-DD | not found]"
```

---

### Step 4 (edit mode only): Interactive selection menu

If argument is `edit`, after printing the overview, assign a sequential number to every item (config files, skills, shared scripts) and render this menu:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_panel "Select an item" \
  "GENERAL CONFIG" \
  "  1. GUIDELINES.md         Shared skill rules" \
  "  2. personal.md           User profiles & roles" \
  "  3. settings.local.json   Allowed commands" \
  "" \
  "SKILLS" \
  "  4. arch-qa               [brief — truncated to 50 ch]" \
  "  5. create-report         [brief — truncated to 50 ch]" \
  "  6. project-index         [brief — truncated to 50 ch]" \
  "  7. user-config           [brief — truncated to 50 ch]" \
  "" \
  "SHARED UTILITIES" \
  "  8. check-path.sh         Path validation" \
  "  9. log-run.sh            Run logging" \
  "" \
  "Type: \"<number> explain\"  /  \"<number> edit\"  /  \"<number> simplify\"" \
  "Or just a number to see action choices for that item."
```

**Wait for user input. Do not proceed until the user responds.**

**Parsing the response:**
- `<number>` only → print the three action choices for that item, wait again
- `<number> explain` → run **Step 4a**
- `<number> edit` → run **Step 4b**
- `<number> simplify` → run **Step 4c**
- `back`, `exit`, `q`, or `done` → end the session, run post-run insights (Step 5)
- Anything else → print "Unrecognized input. Type a number, or 'done' to exit." and reprint the menu

After completing any action (4a/4b/4c), return to the menu automatically unless the user typed `done`.

---

### Step 4a: Explain

1. Read the full content of the selected file. Print: `Reading [filename]...`
2. Provide a plain-English explanation covering:
   - **Purpose** — what this file/skill does and why it exists
   - **Structure** — key sections and their roles
   - **Key rules or patterns** — the most important things to know
   - **Dependencies** — what other files it references or affects
3. Use concrete quotes from the actual content. Keep the tone conversational.
4. Print `─────` then return to the menu.

---

### Step 4b: Edit

1. Read the full content of the selected file. Print: `Reading [filename]...`
2. Ask the user: `What would you like to change?` and wait for their response.
3. Apply the change using `Edit` (or `Write` if a full rewrite is needed).
4. Confirm: `Updated [filename]. Change: [one-line summary of what changed]`
5. Return to the menu.

---

### Step 4c: Simplify

1. Read the full content of the selected file. Print: `Reading [filename]...`
2. Identify sections that are:
   - Redundant or repeated across the file
   - Overly verbose relative to their purpose
   - Using complex phrasing where plain language works equally well
3. Produce a simplified version.
4. Print a reduction summary before asking to save:
   ```
   Simplification summary:
     "Retry Mechanism" section: 14 lines → 6 lines
     "Verbosity" section:        9 lines → 4 lines
     Total: 42 lines → 27 lines (-36%)
   ```
5. Ask: `Save the simplified version? (yes / no / show diff)`
   - `yes` → Write the simplified content, confirm saved
   - `no` → Discard, return to menu
   - `show diff` → Print the before/after side-by-side for changed sections, then ask again
6. Return to the menu.

---

### Step 5: Post-Run Insights

After the run completes (whether overview or edit mode), follow GUIDELINES.md §7:
- Generate 2–6 insight points that would help a future run of this skill be faster or more accurate
- Print them as the final output section
- Prepend an entry to `.claude/skills/runtime-notes.md`

---

## Notes for Self-Updating

After running `/user-config`, if new skills were discovered that did not previously have a `## Brief` section, those briefs are now saved. No further action is needed — future runs will read them directly.

When creating a new skill, always add a `## Brief` section immediately after the frontmatter closing `---`. See the README.md template for the correct format.
