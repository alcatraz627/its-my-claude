# Gum Guide — Interactive TUI for Claude Code Skills

`gum` is a Charmbracelet CLI tool that provides blocking, styled TUI widgets for
Bash scripts. Skills use it to replace plain-text prompts with structured pickers,
confirmations, spinners, and tables — making multi-turn interactions clear and
reducing user input errors.

Install: `brew install gum`
Docs: https://github.com/charmbracelet/gum

---

## Availability Check

Always guard gum usage at the top of any skill section that calls it:

```bash
command -v gum >/dev/null 2>&1 || {
  echo "gum is required for this skill. Install with: brew install gum" >&2
  exit 1
}
```

---

## TTY Compatibility (Claude Code Bash Tool)

Claude Code's Bash tool runs in a sandboxed shell **without a TTY**. Most gum components
use the Bubble Tea framework which opens `/dev/tty` directly — they will fail with
`"could not open a new TTY: open /dev/tty: device not configured"`.

### Works without TTY (use freely in Bash tool)

| Component          | Notes                                         |
| ------------------ | --------------------------------------------- |
| `gum style`        | Full styling — colors, borders, alignment     |
| `gum format`       | Markdown, code, emoji, template rendering     |
| `gum log`          | Leveled logging with timestamps               |
| `gum join`         | Horizontal/vertical layout composition        |
| `gum table --print`| Static table output (**must include `-p`**)   |

### Requires TTY (will fail in Bash tool)

| Component     | Workaround                                      |
| ------------- | ----------------------------------------------- |
| `gum choose`  | None — use `! gum choose` for user to run live  |
| `gum confirm` | None — use `! gum confirm` for user to run live |
| `gum input`   | Use shell variables or arguments instead        |
| `gum write`   | Use heredocs or temp files instead              |
| `gum filter`  | Use `grep`/`fzf` alternatives                  |
| `gum file`    | Use `find`/`ls` instead                         |
| `gum pager`   | Just `cat` the content directly                 |
| `gum spin`    | Runs the inner command but garbles ANSI output  |

### gum-tui.sh Library

For non-TTY environments, source the shared wrapper library:

```bash
source ~/.claude/skills/shared/gum-tui.sh
```

This provides 20+ functions that wrap the TTY-safe components into reusable patterns:
`gum_header`, `gum_table`, `gum_success`, `gum_error`, `gum_panel`, `gum_dashboard`,
`gum_complete`, `gum_progress`, `gum_kv`, `gum_log`, `gum_markdown`, and more.

All functions are zsh-compatible (no bash-only syntax).

---

## Component Reference

### `gum choose` — Single or multi-select list

**Single select** (user picks one, result captured in variable):

```bash
ACTION=$(gum choose "explain" "edit" "simplify" "skip")
echo "User chose: $ACTION"
```

**Multi-select** (user picks any number with space, confirms with enter):

```bash
ITEMS=$(gum choose --no-limit \
  "consolidate instructions" \
  "extract new skill" \
  "remove dead instructions" \
  "promote to guidelines")
# ITEMS is newline-separated list of chosen values
echo "$ITEMS" | while read -r item; do
  echo "Applying: $item"
done
```

**Dynamic list from command output:**

```bash
SKILL=$(ls .claude/skills/ | grep -v shared | gum choose --header "Select a skill:")
```

**Styling:**

```bash
gum choose --cursor "→ " --selected-prefix "✓ " --unselected-prefix "  " \
  "Option A" "Option B" "Option C"
```

---

### `gum filter` — Fuzzy search over a list

Use when the list has more than ~8 items or is dynamic:

```bash
# Pick from all skill names
SKILL=$(ls .claude/skills/ | grep -v shared | grep -v README \
  | gum filter --placeholder "Type to search skills...")

# Pick from file list
FILE=$(find src/ -name "*.ts" | gum filter --placeholder "Search TypeScript files...")
```

---

### `gum input` — Single-line text input

```bash
SCOPE=$(gum input \
  --placeholder "e.g. consolidate shared instructions" \
  --prompt "Scope: " \
  --width 60)
```

**With validation loop:**

```bash
while true; do
  NAME=$(gum input --placeholder "kebab-case-name" --prompt "Skill name: ")
  if echo "$NAME" | grep -qE '^[a-z][a-z0-9-]+$'; then
    break
  fi
  gum style --foreground 1 "✗ Must be lowercase with hyphens only. Try again."
done
```

---

### `gum write` — Multi-line text input

For longer free-form input (description, notes, modification prompt):

```bash
NOTES=$(gum write \
  --placeholder "Describe any additional constraints or focus areas..." \
  --width 70 \
  --height 8 \
  --header "Additional notes (ctrl+d to submit):")
```

---

### `gum confirm` — Yes/no prompt

Exits 0 for yes, 1 for no — use directly in conditionals:

```bash
if gum confirm "Apply all 12 improvements?"; then
  echo "Applying..."
else
  echo "Skipped."
fi

# With custom button labels
if gum confirm "Generate HTML report?" --affirmative "Yes, generate" --negative "Skip"; then
  # invoke /create-report
fi
```

---

### `gum spin` — Spinner for long operations

Runs a command in the background while showing a spinner. Exits with the
command's exit code:

```bash
gum spin --spinner dot --title "Running /project-index..." -- \
  bash -c "npx tsx .claude/skills/project-index/generate.ts > /tmp/index.json"

gum spin --spinner globe --title "Formatting files..." -- \
  npx prettier --write .claude/skills/improve-claude/SKILL.md
```

**Spinner styles:** `line`, `dot`, `minidot`, `jump`, `pulse`, `points`,
`globe`, `moon`, `monkey`, `meter`, `hamburger`

---

### `gum style` — Styled output

Use for headers, warnings, and section labels instead of plain `echo`:

```bash
# Section header
gum style \
  --foreground 212 --border-foreground 212 --border double \
  --align center --width 50 --margin "1 0" \
  "Analysis Complete"

# Warning
gum style --foreground 1 --bold "✗ Lock acquisition failed — skipping file."

# Success
gum style --foreground 2 "✓ All improvements applied."

# Dim/muted info
gum style --foreground 8 "  (no runtime history for this skill)"
```

**Common foreground color codes:**
- `1` = red (errors)
- `2` = green (success)
- `3` = yellow (warnings)
- `4` = blue (info)
- `8` = gray (muted)
- `212` = pink/magenta (headers)

---

### `gum table` — Tabular data display

Pipe tab-separated data. First row is the header:

```bash
printf "Skill\tStatus\tChanges\n" > /tmp/results.tsv
printf "arch-qa\t✓ Applied\t3\n" >> /tmp/results.tsv
printf "create-report\t– Skipped\t0\n" >> /tmp/results.tsv
printf "project-index\t✓ Applied\t1\n" >> /tmp/results.tsv
gum table < /tmp/results.tsv
```

**With column widths:**

```bash
gum table --widths 20,12,10 < /tmp/results.tsv
```

#### Pitfalls (learned the hard way)

Captured from a 10-row Walmart-loadsheet audit render where two separator
choices both broke before the third worked. Worth knowing before you reach for
`gum table` with user-supplied data.

1. **`--separator` MUST be a single character.** `gum_table --sep "@@"` fails
   with `separator must be single character`. Stick to one char.
2. **Avoid any single char that can appear inside cell values.**
   - **`|` pipe** is the default and looks safe in headers, but breaks if any
     cell holds verbose data like `Year: 2014 | Make: Chevrolet | Model: Impala`
     or VCdb-style `1986 BUICK RIVIERA | Liter: 3.8 | SubModel: LUXURY` — each
     internal pipe creates a phantom column.
   - **`^` caret** is rarely in human text but appears in regex anchors. Putting
     a literal `^1\d{9}$` inside a "Fix scope" cell breaks the row.
   - **Tab `\t`** is the safest default unless your data was extracted from
     real CSVs / TSVs that already contain tabs.
3. **Field count must exactly match the header.** Trailing extra separators
   silently yield `invalid data provided`. A row like `"a^b^c^"` (4 fields,
   last empty) breaks against a 3-column header. Drop trailing empty cells.
4. **`gum table --print`** is what `gum_table` uses under the hood — it prints
   formatted output and exits, no interactive selection. Use that, not bare
   `gum table`, when you want a static rendered table embedded in a script.
5. **Sanitize cells before passing data with regex / shell metachars**: replace
   inline regex with descriptive text (`reject IDs starting with 1` instead of
   `^1\d{9}$`). Same for any string containing the chosen separator — escape
   with `sed` first, or pick a separator your data provably doesn't contain.
6. **Emoji column-width is terminal-dependent.** ✅ (3-cell wide) and 🟡
   (2-cell in some fonts) make Verdict-style columns slightly ragged in Apple
   Terminal but pixel-perfect in iTerm2 / VS Code. Don't rely on emoji-column
   alignment for parseable output.
7. **Preferred separator hierarchy** when building data on the fly:
   `\t` > `^` (if no regex content) > `|` (only if you've sanitized the data) >
   anything else. ASCII Unit Separator `\x1f` is theoretically perfect but
   awkward to type and inspect — use only for programmatic pipelines.

#### Defensive pattern

```bash
# Sanitize cells before joining with the separator
sanitize() { /usr/bin/sed 's/\t/ /g; s/[\^|]/ /g' <<< "$1"; }

gum_table --sep $'\t' \
"Cell\tValue\tNote" \
"$(sanitize "$cell1")\t$(sanitize "$val1")\t$(sanitize "$note1")"
```

---

## Multi-Turn Interaction Patterns

### Pattern 1: Loop menu (return-to-menu after each action)

The standard pattern for skills that offer multiple actions on multiple items:

```bash
while true; do
  # Build the choice list dynamically
  CHOICE=$(gum choose \
    "1. arch-qa — explain" \
    "2. create-report — edit" \
    "3. GUIDELINES.md — simplify" \
    "─── done ───")

  case "$CHOICE" in
    *"done"*)
      break
      ;;
    *"arch-qa"*)
      # handle arch-qa action
      ;;
    *"create-report"*)
      # handle create-report action
      ;;
  esac

  # After each action, pause so the user can read output
  gum confirm "Return to menu?" --affirmative "Continue" --negative "Exit" || break
done
```

---

### Pattern 2: Wizard (sequential questions, confirm-each)

For skills like `/new-skill` that gather information step by step:

```bash
gum style --bold --foreground 212 "Step 1 of 7 — Skill Name"

while true; do
  NAME=$(gum input --placeholder "kebab-case-name" --prompt "Name: " --width 40)

  # Show formalized version
  gum style --border rounded --padding "0 1" "I'll use: \`$NAME\` — invoked as \`/$NAME\`"

  if gum confirm "Does this look right?"; then
    break
  fi
done

gum style --bold --foreground 212 "Step 2 of 7 — Goal"
GOAL=$(gum write --placeholder "What does this skill do?" --width 60 --height 5)
```

---

### Pattern 3: Approval gate with numbered list

For showing a change list and getting selective approval:

```bash
# Build items array
ITEMS=(
  "1. [cross-cutting] Add lock protocol to arch-qa (risk: low)"
  "2. [per-skill] Fix stale description in create-report (risk: low)"
  "3. [consolidation] Merge improve-skill into improve-claude (risk: high)"
)

# Show as styled list
gum style --bold "Proposed improvements:"
printf '%s\n' "${ITEMS[@]}" | gum style --padding "0 2"

# Multi-select which to apply
SELECTED=$(printf '%s\n' "${ITEMS[@]}" | gum choose --no-limit \
  --header "Space to select, enter to confirm:")

# Confirm before writing
COUNT=$(echo "$SELECTED" | grep -c '^' || true)
if gum confirm "Apply $COUNT improvement(s)?"; then
  echo "$SELECTED" | while read -r item; do
    echo "Applying: $item"
    # ... apply logic ...
  done
fi
```

---

### Pattern 4: Progress tracking across multiple files

For skills that process N files sequentially, show progress:

```bash
FILES=($(ls .claude/skills/*/SKILL.md))
TOTAL=${#FILES[@]}
CURRENT=0

for FILE in "${FILES[@]}"; do
  CURRENT=$(( CURRENT + 1 ))
  SKILL=$(basename "$(dirname "$FILE")")

  gum style --foreground 4 "[$CURRENT/$TOTAL] Processing: $SKILL"

  # Do the work (with spinner for slow steps)
  gum spin --spinner minidot --title "  Analyzing $SKILL..." -- \
    bash -c "sleep 0.5"  # replace with actual analysis

  gum style --foreground 2 "  ✓ $SKILL done"
done

gum style --bold --foreground 212 "All $TOTAL skills processed."
```

---

## Data Visualization Patterns

### Structured summary table

```bash
# Build TSV in memory
ROWS="Skill\tChanges\tRisk\tStatus"
ROWS+="\narch-qa\t3\tlow\t✓ Applied"
ROWS+="\ncreate-report\t0\t—\t– Skipped"
ROWS+="\nproject-index\t1\tmedium\t✓ Applied"

printf "$ROWS" | gum table --widths 18,10,8,12
```

### Before/after diff display

```bash
show_diff() {
  local label="$1" old="$2" new="$3"

  gum style --bold "Change: $label"
  gum join --horizontal \
    "$(gum style --foreground 1 --width 35 "Before:"$'\n'"$old")" \
    "$(gum style --foreground 2 --width 35 "After:"$'\n'"$new")"
}

show_diff "description field" \
  "Helps the user with skills" \
  "Audits skill files and applies approved improvements."
```

### Categorized improvement list

```bash
print_category() {
  local category="$1" count="$2" items="$3"
  gum style --bold --foreground 212 "$category ($count)"
  echo "$items" | while read -r item; do
    gum style --foreground 8 --padding "0 2" "• $item"
  done
}

print_category "cross-cutting" 2 "Add lock protocol everywhere
Update Step 0 preamble in all skills"

print_category "dead-instruction" 3 "Remove duplicate retry note in arch-qa
Remove obsolete glob pattern in project-index
Remove Prettier reminder already in GUIDELINES"
```

### Runtime notes entry count

```bash
ENTRY_COUNT=$(grep -c '^## ' .claude/skills/runtime-notes.md 2>/dev/null || echo 0)
gum style "Runtime history: $ENTRY_COUNT entries"
```

---

## Full Skill Example — Interactive Picker Loop

Minimal complete skill that uses gum throughout:

```bash
#!/usr/bin/env bash
set -euo pipefail

command -v gum >/dev/null 2>&1 || { echo "Install gum: brew install gum" >&2; exit 1; }

# Header
gum style \
  --foreground 212 --border-foreground 212 --border double \
  --align center --width 50 --margin "1 0" \
  "/my-skill — Interactive Mode"

# Step 1: pick target
SKILL=$(ls .claude/skills/ | grep -v shared | grep -v README \
  | gum filter --placeholder "Select a skill to work on...")

# Step 2: pick action
ACTION=$(gum choose \
  --header "What do you want to do with '$SKILL'?" \
  "explain" "edit" "simplify" "skip")

# Step 3: confirm
if ! gum confirm "Run '$ACTION' on '$SKILL'?"; then
  gum style --foreground 8 "Cancelled."
  exit 0
fi

# Step 4: do work with spinner
gum spin --spinner dot --title "Running $ACTION on $SKILL..." -- \
  bash -c "sleep 1"  # replace with actual work

# Step 5: result
gum style --foreground 2 --bold "✓ Done: $ACTION applied to $SKILL."
```

---

## Tips

- `gum choose` output is the **exact string** of the chosen item — match on substrings with `case *"keyword"*)` if items have extra formatting.
- All gum components read from stdin for list data and write the selection to stdout — pipe and capture naturally.
- `gum confirm` exits **0 for yes, 1 for no** — use directly in `if` or `&&`/`||` chains.
- For dynamic item lists, build with `printf '%s\n' "${array[@]}"` piped to `gum choose`.
- `gum spin` captures and suppresses the inner command's stdout — if you need the output, redirect it to a temp file inside the inner command.
- Combine `gum style` with `gum join` for side-by-side layouts (useful for before/after diffs).
