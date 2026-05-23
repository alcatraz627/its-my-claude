#!/usr/bin/env bash
# desktop.sh — macOS GUI automation helper (Phase 1 / v1)
#
# Usage:
#   desktop screenshot display N           — capture display N to ~/.claude/assets/images/
#   desktop screenshot app NAME            — capture named app's front window (region-based)
#   desktop screenshot region X Y W H      — capture a specific screen region
#   desktop annotate PATH [--grid N]       — overlay coordinate grid on a screenshot
#   desktop annotate PATH --marks "X,Y ..." — add crosshair marks at given coords
#   desktop windows                        — list all visible windows with bounds
#   desktop click X Y                      — click at screen coordinates (STEALS FOCUS)
#   desktop type "text"                    — type text into focused window (STEALS FOCUS)
#   desktop key COMBO                      — send key combo (STEALS FOCUS)
#   desktop space N                        — switch to Space N 1-4 (STEALS FOCUS)
#   desktop focus APP                      — bring app to front (STEALS FOCUS)
#   desktop check                          — verify permissions and tool availability
#
# Screenshot storage: ~/.claude/assets/images/ (timestamped filenames)
# Focus behaviour: screenshot/windows/annotate do NOT steal focus.
#                  click/type/key/space/focus DO steal focus.
#
# Error policy: ALL commands exit non-zero on failure with a clear message to stderr.
#   Screenshot commands additionally check file size — < 5KB is treated as a failure.
#   Never silently swallow errors. Claude must STOP on any failure.
#
# Phase 2 note: this script is the shell foundation for the future MCP server.
# Full reference: ~/.claude/skills/shared/desktop-automation.md

set -euo pipefail

IMAGES_DIR="$HOME/.claude/assets/images"
ANNOTATE_SCRIPT="$HOME/.claude/scripts/annotate-screenshot.py"
MIN_SCREENSHOT_BYTES=5120   # < 5KB = blank/failed capture

mkdir -p "$IMAGES_DIR"

timestamp() { date +%Y%m%d-%H%M%S; }

# Validate a screenshot file exists and is non-trivial in size.
# Exits non-zero with a loud error if the file is missing or suspiciously small.
validate_screenshot() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "SCREENSHOT FAILED: file not created at $path" >&2
    echo "Possible causes: permission denied, invalid coordinates, app not visible" >&2
    exit 1
  fi
  local size
  size=$(stat -f%z "$path" 2>/dev/null || echo 0)
  if [[ "$size" -lt "$MIN_SCREENSHOT_BYTES" ]]; then
    echo "SCREENSHOT FAILED: file is only ${size} bytes (expected > ${MIN_SCREENSHOT_BYTES})" >&2
    echo "Path: $path" >&2
    echo "Possible causes: window not visible, occluded, wrong app name, blank display" >&2
    echo "Do NOT continue the task — report this failure to the user." >&2
    exit 1
  fi
}

cmd="${1:-}"

case "$cmd" in

  screenshot)
    sub="${2:-display}"
    case "$sub" in
      display)
        n="${3:-1}"
        out="$IMAGES_DIR/display${n}-$(timestamp).png"
        screencapture -x -D "$n" "$out"
        validate_screenshot "$out"
        echo "$out"
        ;;
      app|window)
        name="${3:-}"
        if [[ -z "$name" ]]; then
          echo "Usage: desktop screenshot app <AppName>" >&2
          exit 1
        fi
        # Use region-based capture: get window position + size via AppleScript.
        # Works for ALL apps (Chrome, Electron, native) without window IDs.
        # The window must be visible and not fully occluded by another window.
        # Write AppleScript to temp file to avoid bash $(heredoc+parens) parse issues
        _tmp_bounds=$(mktemp /tmp/desktop-bounds-XXXX.scpt)
        printf 'tell application "System Events"\n  tell process "%s"\n    set p to position of window 1\n    set s to size of window 1\n    return ((item 1 of p) as text) & " " & ((item 2 of p) as text) & " " & ((item 1 of s) as text) & " " & ((item 2 of s) as text)\n  end tell\nend tell\n' "$name" > "$_tmp_bounds"
        BOUNDS=$(osascript "$_tmp_bounds" 2>/dev/null || echo "")
        rm -f "$_tmp_bounds"
        if [[ -z "$BOUNDS" ]]; then
          echo "SCREENSHOT FAILED: could not get window bounds for '$name'" >&2
          echo "Is '$name' running and visible? Check: bash ~/.claude/scripts/desktop.sh windows" >&2
          exit 1
        fi
        read -r x y w h <<< "$BOUNDS"
        safe_name="${name// /-}"
        out="$IMAGES_DIR/${safe_name}-$(timestamp).png"
        screencapture -x -R "${x},${y},${w},${h}" "$out"
        validate_screenshot "$out"
        echo "$out"
        ;;
      region)
        x="${3:-}" y="${4:-}" w="${5:-}" h="${6:-}"
        if [[ -z "$x" || -z "$y" || -z "$w" || -z "$h" ]]; then
          echo "Usage: desktop screenshot region X Y W H" >&2
          exit 1
        fi
        out="$IMAGES_DIR/region-$(timestamp).png"
        screencapture -x -R "${x},${y},${w},${h}" "$out"
        validate_screenshot "$out"
        echo "$out"
        ;;
      *)
        echo "Usage: desktop screenshot [display N | app NAME | region X Y W H]" >&2
        exit 1
        ;;
    esac
    ;;

  annotate)
    # Overlay a coordinate grid (and optional crosshair marks) on an existing screenshot.
    # Output is saved alongside the original with '-annotated' suffix.
    # Does NOT steal focus. Does NOT take a new screenshot — annotates an existing file.
    input="${2:-}"
    if [[ -z "$input" ]]; then
      echo "Usage: desktop annotate PATH [--grid N] [--marks 'X1,Y1 X2,Y2']" >&2
      exit 1
    fi
    if [[ ! -f "$input" ]]; then
      echo "ANNOTATE FAILED: file not found: $input" >&2
      exit 1
    fi
    # Build output path: same dir, add -annotated before .png
    base="${input%.png}"
    out="${base}-annotated.png"
    # Pass remaining args to the Python script
    shift 2
    python3 "$ANNOTATE_SCRIPT" "$input" "$out" "$@"
    echo "$out"
    ;;

  windows)
    # Returns: AppName | Window Title | X Y W H for every visible window.
    # Does NOT steal focus. Uses a temp file to avoid bash $(heredoc+parens) parse issues.
    _tmp_as=$(mktemp /tmp/desktop-windows-XXXX.scpt)
    cat > "$_tmp_as" << 'OSASCRIPT'
tell application "System Events"
  set winList to {}
  repeat with proc in (every process whose visible is true)
    set pname to name of proc
    try
      repeat with win in (every window of proc)
        try
          set wname to name of win
          set wpos to position of win
          set wsize to size of win
          set xp to item 1 of wpos
          set yp to item 2 of wpos
          set wp to item 1 of wsize
          set hp to item 2 of wsize
          set end of winList to pname & " | " & wname & " | " & xp & " " & yp & " " & wp & " " & hp
        end try
      end repeat
    end try
  end repeat
  return winList
end tell
OSASCRIPT
    result=$(osascript "$_tmp_as" 2>/dev/null || echo "")
    rm -f "$_tmp_as"
    if [[ -z "$result" ]]; then
      echo "WINDOWS FAILED: no output from System Events — is Accessibility permission granted?" >&2
      echo "Run: bash ~/.claude/scripts/desktop.sh check   to diagnose" >&2
      exit 1
    fi
    echo "$result"
    ;;

  click)
    x="${2:-}"
    y="${3:-}"
    if [[ -z "$x" || -z "$y" ]]; then
      echo "Usage: desktop click X Y" >&2
      exit 1
    fi
    # STEALS FOCUS — caller must have confirmed with user before invoking
    if ! cliclick c:"${x},${y}" 2>/dev/null; then
      echo "CLICK FAILED at (${x},${y})" >&2
      echo "Is Accessibility permission granted? Run: desktop check" >&2
      exit 1
    fi
    ;;

  type)
    text="${2:-}"
    if [[ -z "$text" ]]; then
      echo "Usage: desktop type \"text\"" >&2
      exit 1
    fi
    # STEALS FOCUS — caller must have confirmed with user before invoking
    if ! cliclick t:"$text" 2>/dev/null; then
      echo "TYPE FAILED: could not send keystrokes" >&2
      echo "Is Accessibility permission granted? Run: desktop check" >&2
      exit 1
    fi
    ;;

  key)
    combo="${2:-}"
    if [[ -z "$combo" ]]; then
      echo "Usage: desktop key COMBO (e.g. cmd+c, cmd+v, return, tab, escape)" >&2
      exit 1
    fi
    # Parse combo: split on +, last token is the key, others are modifiers
    IFS='+' read -ra parts <<< "$combo"
    n="${#parts[@]}"
    key="${parts[$((n-1))]}"

    # Build cliclick command
    cmd_parts=()
    if [[ $n -gt 1 ]]; then
      for (( i=0; i<n-1; i++ )); do
        cmd_parts+=("kd:${parts[$i]}")
      done
    fi
    cmd_parts+=("kp:${key}")
    if [[ $n -gt 1 ]]; then
      for (( i=n-2; i>=0; i-- )); do
        cmd_parts+=("ku:${parts[$i]}")
      done
    fi
    # STEALS FOCUS — caller must have confirmed with user before invoking
    if ! cliclick "${cmd_parts[@]}" 2>/dev/null; then
      echo "KEY FAILED: could not send combo '$combo'" >&2
      echo "Is Accessibility permission granted? Run: desktop check" >&2
      exit 1
    fi
    ;;

  space)
    n="${2:-1}"
    # Key codes: Space 1=18, 2=19, 3=20, 4=21
    declare -A keycodes=([1]=18 [2]=19 [3]=20 [4]=21)
    kc="${keycodes[$n]:-}"
    if [[ -z "$kc" ]]; then
      echo "ERROR: Space must be 1-4" >&2
      exit 1
    fi
    # STEALS FOCUS — switches the active virtual desktop
    osascript -e "tell application \"System Events\" to key code $kc using control down"
    sleep 0.4
    echo "Switched to Space $n"
    ;;

  focus)
    app="${2:-}"
    if [[ -z "$app" ]]; then
      echo "Usage: desktop focus AppName" >&2
      exit 1
    fi
    # STEALS FOCUS — raises app to foreground
    osascript -e "tell application \"$app\" to activate"
    sleep 0.2
    echo "Focused: $app"
    ;;

  check)
    # Diagnose environment: permissions, installed tools, screenshot dir.
    # Does NOT steal focus.
    echo "=== desktop.sh environment check ==="
    echo ""

    # cliclick installed?
    if command -v cliclick &>/dev/null; then
      echo "[OK] cliclick: $(which cliclick) $(cliclick --version 2>/dev/null || echo '')"
    else
      echo "[FAIL] cliclick not found — install with: brew install cliclick"
    fi

    # python3 + PIL for annotate
    if python3 -c "from PIL import Image" &>/dev/null; then
      echo "[OK] python3 + Pillow: annotation available"
    else
      echo "[WARN] Pillow not installed — annotate command unavailable"
      echo "       Fix: pip3 install Pillow --break-system-packages"
    fi

    # Accessibility — test cliclick by moving mouse 0px (no-op)
    if cliclick m:0,0 &>/dev/null 2>&1; then
      echo "[OK] Accessibility permission: granted"
    else
      echo "[FAIL] Accessibility permission: DENIED"
      echo "       Grant in: System Settings → Privacy & Security → Accessibility → add ghostty"
    fi

    # Screen Recording — test screencapture
    test_png="/tmp/desktop-check-$$.png"
    if screencapture -x -R "0,0,10,10" "$test_png" 2>/dev/null && [[ -f "$test_png" ]]; then
      size=$(stat -f%z "$test_png")
      rm -f "$test_png"
      if [[ "$size" -gt 100 ]]; then
        echo "[OK] Screen Recording permission: granted"
      else
        echo "[WARN] Screen Recording: file was tiny (${size}B) — may be restricted"
      fi
    else
      echo "[FAIL] Screen Recording permission: DENIED or screencapture failed"
      echo "       Grant in: System Settings → Privacy & Security → Screen Recording → add ghostty"
    fi

    # System Events (window enumeration)
    if osascript -e 'tell application "System Events" to get name of first process' &>/dev/null; then
      echo "[OK] System Events (osascript): accessible"
    else
      echo "[FAIL] System Events: not accessible — Automation permission may be missing"
    fi

    # Images dir
    echo "[OK] Screenshot dir: $IMAGES_DIR"
    count=$(ls "$IMAGES_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
    echo "     Existing screenshots: $count"

    echo ""
    echo "=== check complete ==="
    ;;

  help|--help|-h|"")
    cat << 'HELP'
desktop.sh — macOS GUI automation (Phase 1 / v1)

Commands:
  screenshot display N        Capture display N (1=main, 2=secondary)
  screenshot app NAME         Capture front window of named app (region-based; no focus steal)
  screenshot region X Y W H   Capture a specific screen rect
  annotate PATH               Overlay coordinate grid on a screenshot (no focus steal)
  annotate PATH --grid N      Custom grid spacing (default 100px)
  annotate PATH --marks X,Y   Add crosshair markers at coordinates
  windows                     List all visible windows: App | Title | X Y W H (no focus steal)
  check                       Diagnose permissions and tool availability (no focus steal)
  click X Y                   Click at coordinates    ⚠ STEALS FOCUS
  type "text"                 Type text               ⚠ STEALS FOCUS
  key COMBO                   Send key combo          ⚠ STEALS FOCUS
  space N                     Switch to Space N (1-4) ⚠ STEALS FOCUS
  focus APP                   Bring app to foreground ⚠ STEALS FOCUS

Output:
  screenshot/annotate → prints saved path (always ~/.claude/assets/images/)
  windows             → one line per window
  others              → silent on success, loud on failure

Error policy:
  All failures exit non-zero with a clear message.
  Screenshots < 5KB are treated as failures — never silently accepted.
  Claude must STOP on any failure. Never assume or hallucinate screen state.

Phase 2 upgrade: ~/.claude/skills/shared/desktop-automation.md#phase-2-upgrade-guide
HELP
    ;;

  *)
    echo "Unknown command: $cmd" >&2
    echo "Run: desktop help" >&2
    exit 1
    ;;

esac
