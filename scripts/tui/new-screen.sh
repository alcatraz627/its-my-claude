#!/usr/bin/env bash
# new-screen.sh: start a new terminal tool from the list-and-preview screen every tool here shares.
#
# tui_new_screen NAME [FOLDER]: write NAME, NAME-helper.py and NAME.test.py into FOLDER (default: here)
#
# The three files are a working tool: a grouped list, a fixed preview pane, try-then-save with
# a floating confirm box, and tests for the promises a screen must keep. Replace the sample rows
# in the helper with your own. Nothing is overwritten: an existing file stops it.
#
# Then, before calling it done:
#   python3 NAME.test.py
#   python3 ~/.claude/scripts/tui/lint.py NAME NAME-helper.py
#   bash ~/.claude/scripts/tui/smoke.sh -- NAME        (once NAME is on your PATH)
# Guide: ~/.claude/conventions/tui-handbook.md §11.
set -u

here="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
name="${1:-}"
folder="${2:-.}"
case "$name" in
  ""|-h|--help) sed -n '2,14p' "$0"; [ -n "$name" ] && exit 0 || exit 2 ;;
  *[!a-z0-9-]*|-*) printf 'new-screen: the name must be lowercase letters, digits and dashes, as it will be typed: %s\n' "$name" >&2; exit 2 ;;
esac
[ -d "$folder" ] || { printf 'new-screen: no such folder: %s\n' "$folder" >&2; exit 2; }

upper=$(printf '%s' "$name" | tr 'a-z-' 'A-Z_')
tool="$folder/$name" helper="$folder/$name-helper.py" test="$folder/$name.test.py"
for target in "$tool" "$helper" "$test"; do
  [ -e "$target" ] && { printf 'new-screen: %s already exists, so nothing was written.\n' "$target" >&2; exit 1; }
done

fill() { sed -e "s/__NAME__/$name/g" -e "s/__UPPER__/$upper/g" "$here/templates/screen/$1" > "$2"; }
fill tool.sh "$tool"
fill helper.py "$helper"
fill test.py "$test"
chmod +x "$tool"

printf 'wrote %s\n      %s\n      %s\n\n' "$tool" "$helper" "$test"
printf 'next: put your rows in %s, then run its test, the lint and the smoke check (see --help).\n' "$helper"
