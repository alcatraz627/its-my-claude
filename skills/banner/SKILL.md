---
name: banner
description: Generates a customized terminal banner by prompting for title, sections, and theme — renders using std::claude::shared banner.py with guaranteed alignment.
allowed-tools: Read, Bash, Glob
argument-hint: "[description of what to display]"
user-invokable: true
---

## Brief

Renders a fixed-width terminal banner with aligned Unicode borders. Takes a free-form description of what to display, infers the best sections/layout, picks a theme, and prints to terminal. Uses `std::claude::shared/banner.py` for rendering — all output is guaranteed aligned at W=68.

> ⚠️ **For terminals only.** This banner uses Unicode box-drawing + ANSI colors and is not for README files — colors strip in markdown and box-drawing breaks under proportional fonts. If the user wants a README banner, route them to `/readme` (which writes `assets/cover.svg` and references it via `<img src=...>`); never paste this banner's text or wrap it in ` ``` ` blocks inside a README.

## Step 0: Load Shared Guidelines

Read `~/.claude/skills/GUIDELINES.md`. Apply all rules for the duration of this skill run.

## Usage

```
/banner [description]
```

| Argument      | Type     | Description                                                                                  |
| ------------- | -------- | -------------------------------------------------------------------------------------------- |
| `description` | optional | Free-form description of what the banner should show. If omitted, prompt the user for input. |

**Examples:**

- `/banner deploy status for prod-east`
- `/banner pm2 process list with ports and uptime`
- `/banner session summary for fix-auth-3b`
- `/banner` (prompts: "What should the banner display?")

## Phase 1 — Interpret Intent

1. If no description argument was provided, ask the user:

   ```
   What should the banner display?
   (e.g., "deploy status", "session summary", "server health", or any structured data)
   →
   ```

   Wait for a response.

2. From the description (argument or user response), determine:
   - **Title** — 1-3 words for the header box (e.g., "DEPLOY STATUS", "PM2 PROCS", "SESSION")
   - **Subtitle** — contextual identifier (e.g., cluster name, session ID, app name)
   - **Sections** — what logical groups of information to show. Each section has:
     - A symbol from the safe set: `◆ ◇ ▶ △ ◎ ⊕ ⊙ ● ○ ■`
     - A title (ALL CAPS, 1-2 words)
     - Items with tree prefixes (`├-`, `└-`)
   - **Theme** — pick from: `default`, `minimal`, `heavy`, `dots`
   - **Footer** — optional one-liner for the bottom bar

3. **If the description references live data** (e.g., "pm2 process list", "git status", "port registry"), gather that data first:
   - Run the appropriate commands via Bash
   - Parse the output into section items
   - Use real values, not placeholders

4. **If the description is abstract** (e.g., "something cool", "test banner"), design a demo layout.

5. Print the plan before rendering:
   ```
   Banner plan:
     Title:    <title>
     Subtitle: <subtitle>
     Theme:    <theme>
     Sections: <N> (<list of section titles>)
     Data:     <live | static>
   ```

## Phase 2 — Build and Render

1. Write a Python script to `/tmp/banner-render.py` that:
   - Imports from `std::claude::shared`: `sys.path.insert(0, os.path.expanduser("~/.claude/skills"))` then `from shared import Banner, Section, Item, tree, kv_line, truncate_path, THEMES`
   - Creates a `Banner` instance with the resolved parameters
   - Adds sections via `banner.add_section()` or `Banner.from_dict()`
   - Uses `tree()` helper for auto-prefixed item lists
   - Uses `kv_line()` helper for key-value pairs with dot-leaders
   - Calls `banner.verify()` and prints errors if any
   - Prints `banner.render()`

2. Run the script:

   ```bash
   python3 /tmp/banner-render.py
   ```

3. If verification fails (any line != W chars), diagnose and fix before showing to user.

## Phase 3 — Offer Customization

After printing the banner, offer:

```
Adjustments? (theme, width, sections, or "save" to write to file)
→
```

- **Theme change**: re-render with new theme
- **Width change**: re-render with new W (min 50, max 120)
- **Section edits**: add/remove/reorder sections
- **"save"**: write the rendered banner to a file (ask for path, default `/tmp/banner-output.txt`)
- **"json"**: export the banner config as JSON for reuse with `python3 banner.py --config`
- **Enter / "done"**: finish

## Phase 4 — Completion

Print:

```
─────────────────────────────────────────────────────
  ✓ Banner rendered
─────────────────────────────────────────────────────

  Theme:   <theme>
  Width:   <W>
  Sections: <N>

  Re-render: python3 /tmp/banner-render.py
  Library:   ~/.claude/skills/shared/banner.py

─────────────────────────────────────────────────────
```

## Notes

- **Rendering library:** `std::claude::shared/banner.py` at `~/.claude/skills/shared/banner.py`. Supports 4 themes, JSON config, CLI, and Python API. All output is verified at the character level — every line must be exactly W chars.
- **Safe characters only:** ASCII `=`/`-` for horizontal fills. Unicode `╔╗╚╝╠╣║` for corners/verticals. Never use `═` (U+2550) or `─` (U+2500) — they cause cumulative glyph drift over 60+ repetitions.
- **Section symbols (verified 1-wide):** `◆ ◇ ▶ △ ◎ ⊕ ⊙ ● ○ ■`. Forbidden: `⚡` (2-wide), `⏩` (2-wide), `⊞` (wider in some fonts).
- **Live data pattern:** When the user asks for something like "pm2 status" or "port registry", gather real data via Bash first, then feed it into the banner. Don't use placeholder values.
- This skill produces terminal output only — no files are written unless the user asks to save.
