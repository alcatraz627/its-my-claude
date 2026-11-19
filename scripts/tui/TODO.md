<!-- sessions: zterm-audit-7c@2026-11-10 -->

# TUI kit: what to build next

Open work on the terminal-UI kit in this folder, from building `zterminal look` and
`zterminal banner` on 10 November 2026. Each item says what it is, why it is wanted, and the
first step. Built already: `tuikit.py`, `smoke.sh`, `lint.py`, `new-screen.sh`, and the
`tui-smoke-stop.py` Stop hook. Guide: `~/.claude/conventions/tui-handbook.md`.

## 1. Colour in the smoke check

- **What:** capture the screen with its colours and render it to an image an agent can read.
- **Why:** every screen report that day ended "colours not seen". Text capture cannot tell a
  green key from an amber one, or whether a drawn icon looks like the icon.
- **First step:** `tmux capture-pane -e -p` keeps the colour codes. Turn that into HTML and
  screenshot it with headless Chrome, behind a `smoke.sh --image PATH` flag.

## 2. Smoke check waits for text, and takes several sizes

- **What:** `--until TEXT` in place of the fixed pause, and `--size` accepting a list.
- **Why:** fixed pauses made two runs fail on timing alone. Small-window faults (a cut header,
  a list squeezed to five rows) were found by luck, because one size was tried at a time.
- **First step:** loop on `capture-pane` until the text shows or a timeout passes. For sizes,
  run the whole check once per size and report each.

## 3. More of the screen in `tuikit.py`

- **What:** a grouped-list builder, a fixed-pane builder that enforces the three constant
  lines, the saved, draft and history store, and image-to-cells drawing.
- **Why:** these still live inside `zterminal-look.py`, and the scaffold template carries its
  own smaller copies. The next tool will copy them a third time.
- **First step:** move `icon_art` and `bitmap_rows` over as `tuikit.image_cells(path, size)`,
  since they have no ties to Ghostty. Then the store, as a small class taking a folder.

## 4. `tui_confirm` uses the floating box inside fzf

- **What:** `pick.sh`'s confirm draws `tuikit.dialog` when it is called from an fzf bind.
- **Why:** shell tools that confirm still switch to a new screen to ask.
- **First step:** detect the fzf case by an env var the caller sets (fzf exports `FZF_*`
  variables to its commands), and call `tuikit.py dialog` there.

## 5. `zcmd doctor` checks installed links

- **What:** for each tool in the zcmd manifest, start it through its installed link and
  confirm the files it looks for beside itself are found.
- **Why:** that was the blank-pane cause, and it applies to every tool installed as a link.
- **First step:** run each tool's `--help` through the link with a short timeout and flag
  "No such file" in the output. Then run `lint.py` on its source for trap A10.

## 6. Split the handbook

- **What:** three files: the build guide, the trap table, the list-and-preview blueprint.
- **Why:** it has roughly doubled, and an agent loads all of it to read one row.
- **First step:** move §4 to `conventions/tui-traps.md` and §11 to `conventions/tui-screen.md`,
  leave pointers, and update the triggers in each file's frontmatter.

## 7. The lint knows more traps

- **What:** checks for A13 (a single-key read without `tuikit.read_key`), A14 (an action
  offered without its precondition) where it can be seen in text, and A17 (a message printed
  just before `exec` back to the screen).
- **Why:** these three cost the most time that day and are not in `lint.py` yet.
- **First step:** A17 is the mechanical one: a `printf` followed within three lines by
  `exec "$SELF"` with no pause between.

## 8. The stacked layout in short windows

- **What:** when the preview sits below the list and the window is under about 30 rows, the
  list shows only a handful of rows.
- **Why:** seen on `zterminal banner` at 150 by 20: five list rows, groups scrolled out of view.
- **First step:** give the list its row count plus header and footer first, and the preview
  what is left, with a floor. Put the sizing in one shared function, since both screens need it.
