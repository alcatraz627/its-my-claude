#!/bin/bash
# Set up the memory guard on another Mac from an unpacked bundle: no pm2, Claude Code or
# Homebrew needed. Run it from the unpacked zrecover folder.
#
# Usage: ./install-guard.sh <profile> [--no-daemon]    for example: ./install-guard.sh creative
set -u

PROFILE="${1:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.claude/scripts/zrecover"

if [ -z "$PROFILE" ] || [ ! -f "$HERE/profiles/$PROFILE.json" ]; then
  echo "usage: ./install-guard.sh <profile>   profiles: $(ls "$HERE/profiles" | sed 's/.json//' | tr '\n' ' ')" >&2
  exit 2
fi
# /usr/bin/python3 is a stub until the Command Line Tools exist, and launchd cannot answer its prompt.
if ! /usr/bin/python3 -c "import ctypes, sqlite3" >/dev/null 2>&1; then
  echo "This Mac needs the Command Line Tools first. Run: xcode-select --install, then run this again." >&2
  exit 1
fi

mkdir -p "$DEST"
if [ "$HERE" != "$DEST" ]; then
  cp -R "$HERE/." "$DEST/"
fi
chmod +x "$DEST/gcc-zrecover"
/usr/bin/python3 "$DEST/zrecover.py" profile use "$PROFILE" || exit 1
if [ "${2:-}" != "--no-daemon" ]; then
  /usr/bin/python3 "$DEST/zrecover.py" daemon install || exit 1
fi
echo
/usr/bin/python3 "$DEST/zrecover.py" doctor
echo
echo "If macOS shows a Background Items notice for gcc-zrecover, leave it allowed."
echo "To stop it: /usr/bin/python3 $DEST/zrecover.py daemon uninstall"
