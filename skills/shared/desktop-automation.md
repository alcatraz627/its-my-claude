# Desktop Automation — macOS GUI Control

> **Version:** v1 (shell-only)  
> **Phase:** 1 of 2 — all operations use native macOS shell tools via the Bash tool  
> **Installed tools:** `screencapture` (built-in), `osascript` (built-in), `cliclick` (brew)  
> **Helper script:** `~/.claude/scripts/desktop.sh`

---

## Quick Reference

| Goal | Command | Focus stolen? |
|------|---------|--------------|
| Screenshot display 1 | `desktop screenshot display 1` | No |
| Screenshot display 2 | `desktop screenshot display 2` | No |
| Screenshot named app window | `desktop screenshot app Slack` | No |
| Screenshot a screen region | `desktop screenshot region X Y W H` | No |
| Add coordinate grid to screenshot | `desktop annotate PATH` | No |
| Annotate with custom grid + marks | `desktop annotate PATH --grid 50 --marks "820,450"` | No |
| List all visible windows + bounds | `desktop windows` | No |
| Verify environment / permissions | `desktop check` | No |
| Click at coordinates | `desktop click 820 450` | **Yes** |
| Type text | `desktop type "hello world"` | **Yes** |
| Send key combo | `desktop key cmd+c` | **Yes** |
| Switch to Space N | `desktop space 2` | **Yes** |

Or use the raw commands directly — see sections below.

### The Improved Vision Loop (with annotation)

```
1. screenshot → ~/.claude/assets/images/step-1.png
2. annotate step-1.png  → step-1-annotated.png  (adds coordinate grid)
3. Read step-1-annotated.png → Claude reads exact pixel coords from grid labels
4. Identify element: "Submit button center is at grid intersection ~820,450"
5. Optionally: annotate --marks "820,450" to drop a crosshair and verify visually
6. Confirm with user (mcp__inputs__confirm) before any click
7. click 820 450
8. sleep 0.5
9. screenshot → step-2.png → annotate → Read → verify
```

**Grid spacing guidance:**
- `--grid 100` (default): good for full-display screenshots, elements > 50px
- `--grid 50`: dense UIs, small buttons, toolbar items
- `--grid 200`: very large windows where only rough position matters

---

## Prerequisites

**Accessibility permission** — required for `cliclick` and `osascript` click/type:
> System Settings → Privacy & Security → Accessibility → add ghostty (or Terminal)

**Screen Recording permission** — required for `screencapture` in some contexts:
> System Settings → Privacy & Security → Screen Recording → add ghostty (or Terminal)

---

## Screenshots

```bash
# All of display 1 (3440×1440 ultrawide)
screencapture -x -D 1 ~/.claude/assets/screenshots/display1.png

# All of display 2 (3024×1964 Retina)
screencapture -x -D 2 ~/.claude/assets/screenshots/display2.png

# Specific app window — most apps (uses System Events)
WINID=$(osascript -e 'tell application "System Events" to tell process "Slack" to id of window 1')
screencapture -x -l "$WINID" ~/.claude/assets/screenshots/slack-window.png

# Specific app window — Chrome and multi-process apps (use JXA instead)
# System Events fails for Chrome with "Can't get id of window 1 (-1728)"
WINID=$(osascript -l JavaScript -e "
  var se = Application('System Events');
  var proc = se.processes.whose({name: 'Google Chrome'})[0];
  proc.windows()[0].id();
")
screencapture -x -l "$WINID" ~/.claude/assets/screenshots/chrome-window.png

# After taking screenshot: Read the file — Claude sees the screen via vision
```

**Storage rule:** Always save to `~/.claude/assets/screenshots/`. Never use `/tmp` (it resolves to `/private/tmp` which is deny-listed in settings.json).

**Viewing:** Use the `Read` tool on the `.png` file — Claude's vision model reads it directly.

---

## Window Discovery

```bash
# List all visible apps
osascript -e 'tell application "System Events" to get name of every process whose visible is true'

# List all windows with titles (all visible apps)
osascript << 'EOF'
tell application "System Events"
  set winList to {}
  repeat with proc in (every process whose visible is true)
    set pname to name of proc
    repeat with win in (every window of proc)
      set end of winList to pname & ": " & name of win
    end repeat
  end repeat
  return winList
end tell
EOF

# Get window bounds (position + size) for a specific app
osascript -e 'tell application "System Events" to tell process "Slack" to get {position, size} of window 1'

# Get window ID for screencapture -l targeting (most apps)
osascript -e 'tell application "System Events" to tell process "Slack" to id of window 1'
```

### JXA — JavaScript for Automation (use when AppleScript fails)

Chrome, and some other apps with multi-process architectures, block AppleScript from reading
window IDs via System Events (error -1728). Use JXA (`osascript -l JavaScript`) instead:

```bash
# List all tabs across all Chrome windows
osascript -l JavaScript << 'EOF'
var chrome = Application('Google Chrome');
var tabs = [];
for (var w = 0; w < chrome.windows.length; w++) {
  for (var t = 0; t < chrome.windows[w].tabs.length; t++) {
    tabs.push("W" + w + "T" + t + ": " + chrome.windows[w].tabs[t].title());
  }
}
tabs.join("\n");
EOF

# Get Chrome window ID via JXA (works where AppleScript fails)
osascript -l JavaScript -e "
  var se = Application('System Events');
  var proc = se.processes.whose({name: 'Google Chrome'})[0];
  proc.windows()[0].id();
"

# Switch Chrome to a specific tab (1-indexed)
osascript -l JavaScript -e "
  var chrome = Application('Google Chrome');
  chrome.windows[0].activeTabIndex = 3;
"

# Bring an app to the front via JXA (more reliable than 'tell app X to activate')
osascript -l JavaScript -e "
  var se = Application('System Events');
  var ghostty = se.processes.whose({name: 'ghostty'})[0];
  ghostty.frontmost = true;
"
```

**When to use JXA vs AppleScript:**

| Situation | Use |
|-----------|-----|
| Native macOS app (Slack, Preview, Calendar) | AppleScript — simpler syntax |
| Chrome tab enumeration or switching | JXA — AppleScript requires Automation permission |
| Chrome window ID for `screencapture -l` | JXA — System Events returns -1728 for Chrome |
| Bringing Ghostty to front | JXA `frontmost = true` — `activate` fails if Chrome is pinned |
| Space switching | AppleScript `key code N using control down` — JXA has no advantage |

---

## Mouse & Keyboard (`cliclick`)

```bash
# Move mouse (no click)
cliclick m:500,300

# Single click
cliclick c:820,450

# Double-click
cliclick dc:820,450

# Right-click
cliclick rc:820,450

# Type text into focused window
cliclick t:"Hello world"

# Key press — simple key
cliclick p:return
cliclick p:tab
cliclick p:escape

# Key combinations (hold modifier, press key, release modifier)
cliclick kd:cmd p:c ku:cmd          # Cmd+C (copy)
cliclick kd:cmd p:v ku:cmd          # Cmd+V (paste)
cliclick kd:cmd p:a ku:cmd          # Cmd+A (select all)
cliclick kd:cmd p:z ku:cmd          # Cmd+Z (undo)
cliclick kd:cmd kd:shift p:4 ku:shift ku:cmd   # Cmd+Shift+4
cliclick kd:cmd p:tab ku:cmd        # Cmd+Tab (app switcher)

# Move mouse then click (ensure hover state first)
cliclick m:820,450 && sleep 0.1 && cliclick c:820,450
```

---

## Space Switching (Virtual Desktops)

```bash
# Switch to Space 1-4 via keyboard shortcut
osascript -e 'tell application "System Events" to key code 18 using control down'  # Space 1
osascript -e 'tell application "System Events" to key code 19 using control down'  # Space 2
osascript -e 'tell application "System Events" to key code 20 using control down'  # Space 3
osascript -e 'tell application "System Events" to key code 21 using control down'  # Space 4

# Screenshot a background Space (switch, wait, capture, switch back)
osascript -e 'tell application "System Events" to key code 19 using control down'  # go to Space 2
sleep 0.4
screencapture -x -D 1 ~/.claude/assets/screenshots/space2.png
osascript -e 'tell application "System Events" to key code 18 using control down'  # back to Space 1
```

**Note:** `screencapture -D N` captures *displays* (physical monitors), not Spaces. Spaces are virtual layers — you must switch to them before capturing.

---

## The Automation Loop

This is the core pattern for all GUI interactions. **Always annotate before clicking — never guess coordinates from a plain screenshot.**

```
1. screenshot → ~/.claude/assets/images/step-1.png
2. annotate step-1.png → step-1-annotated.png  (adds pixel grid)
3. Read step-1-annotated.png → read coordinates from grid labels, not visual estimation
4. Identify element center from grid: "Submit button is at grid ~820,450"
5. Optional: annotate --marks "820,450" → Read → verify crosshair is on the right element
6. Confirm with user via mcp__inputs__confirm BEFORE clicking
7. click 820 450
8. sleep 0.5  (wait for UI animation)
9. screenshot → step-2.png → annotate → Read → verify action worked
10. Repeat until goal reached
```

**Coordinate strategy:**
- The image is at native resolution (3440×1440 for display 1, 3024×1964 for display 2)
- Retina displays: coordinates are in logical pixels — divide physical pixel count by scale factor (~2)
- `desktop windows` output gives you the app's origin (X Y) and size (W H) — element coords are relative to that origin
- Grid labels in annotated images are **logical pixel coordinates** — use them directly with `cliclick`

**Hard STOP conditions — never continue past these:**
- Screenshot file < 5KB → captured blank or wrong window → stop, report to user
- Window bounds returned empty → app not running or not visible → stop, report to user
- Annotated image shows crosshair in wrong position → recalculate, do not click → re-annotate
- `desktop.sh` exits non-zero for any reason → stop, show the error, ask user how to proceed
- Never assume or hallucinate screen content — if you can't see it, say so

---

## Usage Examples

### Example 1 — Read what's on screen right now

```bash
screencapture -x -D 1 ~/.claude/assets/screenshots/now.png
# Then: Read ~/.claude/assets/screenshots/now.png
# Claude describes everything visible
```

### Example 2 — Click a button by approximate position

```bash
# First: screenshot to find where the button is
screencapture -x -D 1 ~/.claude/assets/screenshots/before.png
# Read it → identify button position → click
cliclick c:1200,750
sleep 0.3
# Screenshot after to verify
screencapture -x -D 1 ~/.claude/assets/screenshots/after.png
```

### Example 3 — Type into a text field in a specific app

```bash
# Focus the app window
osascript -e 'tell application "Slack" to activate'
sleep 0.2
# Click the text field (approximate coords from screenshot)
cliclick c:600,900
sleep 0.1
# Type the message
cliclick t:"Hello from Claude"
cliclick p:return
```

### Example 4 — Capture a specific app window (not the full display)

For most apps (Slack, Preview, etc.):
```bash
WINID=$(osascript -e 'tell application "System Events" to tell process "Slack" to id of window 1')
screencapture -x -l "$WINID" ~/.claude/assets/screenshots/slack-window.png
# Read ~/.claude/assets/screenshots/slack-window.png
```

For Chrome (System Events returns -1728 — use JXA):
```bash
WINID=$(osascript -l JavaScript -e "
  var se = Application('System Events');
  var proc = se.processes.whose({name: 'Google Chrome'})[0];
  proc.windows()[0].id();
")
screencapture -x -l "$WINID" ~/.claude/assets/screenshots/chrome-window.png
# Read ~/.claude/assets/screenshots/chrome-window.png
```

### Example 4b — Screenshot a specific Chrome tab

```bash
# Step 1: List all tabs to find the right one
osascript -l JavaScript << 'EOF'
var chrome = Application('Google Chrome');
var out = [];
for (var w = 0; w < chrome.windows.length; w++) {
  for (var t = 0; t < chrome.windows[w].tabs.length; t++) {
    out.push("W" + w + " T" + (t+1) + ": " + chrome.windows[w].tabs[t].title());
  }
}
out.join("\n");
EOF

# Step 2: Switch to that tab (e.g. window 0, tab 3)
osascript -l JavaScript -e "Application('Google Chrome').windows[0].activeTabIndex = 3;"
sleep 0.3

# Step 3: Screenshot Chrome's window
WINID=$(osascript -l JavaScript -e "
  Application('System Events').processes.whose({name: 'Google Chrome'})[0].windows()[0].id();
")
screencapture -x -l "$WINID" ~/.claude/assets/screenshots/chrome-tab.png
# Read ~/.claude/assets/screenshots/chrome-tab.png
```

### Example 5 — Switch Space, capture, come back

```bash
osascript -e 'tell application "System Events" to key code 19 using control down'
sleep 0.4
screencapture -x -D 1 ~/.claude/assets/screenshots/space2-snapshot.png
osascript -e 'tell application "System Events" to key code 18 using control down'
# Read the snapshot
```

### Example 6 — Enumerate all windows and their bounds

```bash
bash ~/.claude/scripts/desktop.sh windows
# Returns: AppName | Window Title | X Y W H
```

---

## Known Limitations (v1)

| Limitation | Workaround |
|------------|-----------|
| No OCR/element-by-text targeting | Estimate coordinates from screenshot; see Phase 2 |
| Coordinate-brittle clicks | Re-screenshot after each action to verify and adjust |
| Can't screenshot background Spaces | Switch to Space first (adds ~400ms delay) |
| `cliclick` needs Accessibility permission | Grant in System Settings once |
| Window IDs are ephemeral (change on reopen) | Re-query `osascript` each time |
| Chrome window ID fails via System Events (-1728) | Use JXA (`osascript -l JavaScript`) — see Window Discovery section |
| Chrome tab switching via AppleScript needs Automation permission | Use JXA `chrome.windows[0].activeTabIndex = N` instead |
| `tell application "X" to activate` may not front app if another is pinned to all Spaces | Use JXA `proc.frontmost = true` via System Events |

---

## Phase 2 Upgrade Guide

### When to build Phase 2

Build the MCP server when any of these are true:

- **OCR frustration**: You're frequently mis-clicking because coordinate estimation is hard
- **Repeated boilerplate**: Every session starts with 5+ identical screencapture/osascript commands
- **Element targeting**: You need "click the button labeled Submit" not "click at 820,450"
- **Parallel automation**: Multiple automation chains running concurrently
- **Cross-session state**: Tracking which windows are open, their states, across sessions

### Phase 2 Design Spec

The MCP server **wraps Phase 1 shell tools** — it does not replace them. The Bash tool remains the fallback for any operation the MCP doesn't expose.

```
┌─────────────────────────────────────────────────────────┐
│  Phase 2 MCP Tools (structured, named parameters)       │
│                                                         │
│  screenshot(display?, app?, window?)  → path            │
│  get_windows()                        → JSON array      │
│  find_text(text, screenshot_path)     → {x, y}         │
│  click(x, y)             → wraps cliclick c:X,Y        │
│  type(text)              → wraps cliclick t:"..."      │
│  key(combo)              → wraps cliclick kd/p/ku      │
│  switch_space(n)         → wraps osascript key code    │
│                                                         │
│  Internal: all tools shell out to Phase 1 commands      │
│  Fallback: use Bash tool directly for anything missing  │
└─────────────────────────────────────────────────────────┘
```

**Stack:** Python 3.13 (already installed) + `pyautogui` for OCR/image search, wrapping the existing shell commands for screenshots and window management.

**MCP server location:** `~/.claude/mcp-servers/desktop-automation/`  
**Registration:** inject into `.mcp.json` as a global always-on server

**Key difference from v1:** Phase 2 adds `find_text()` which uses image recognition to locate UI elements by their label text — eliminating coordinate guessing.

### Migration notes

- All Phase 1 shell patterns continue to work after Phase 2 is built
- Phase 2 MCP tools are additive — use whichever is more convenient per task
- No config changes needed: the Bash tool is always available as fallback
- To trigger Phase 2 build: "Build the desktop automation MCP" — Claude will read this doc first
