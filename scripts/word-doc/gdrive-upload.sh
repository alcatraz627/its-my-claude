#!/bin/bash
# Upload a .docx to Google Drive as a native Google Doc (converted on upload).
#
# One-time setup, done by the human because it opens a browser login:
#   rclone config        -> n (new remote), name: gdrive, storage: drive,
#                           accept defaults, say y to the browser auth
# The refresh token rclone stores is durable; re-auth is rare, and when it is
# needed rclone says so plainly rather than failing silently.
#
# Usage: gdrive-upload.sh <file.docx> [drive-folder-path]
set -euo pipefail

f=${1:?usage: gdrive-upload.sh <file.docx> [drive-folder-path]}
dest=${2:-Docs}

command -v rclone >/dev/null || { echo "rclone missing: brew install rclone"; exit 3; }
# Any configured drive remote works; RCLONE_REMOTE overrides, else the first one.
remote=${RCLONE_REMOTE:-$(rclone listremotes 2>/dev/null | head -1 | tr -d ':')}
[ -n "$remote" ] || {
  echo "no rclone remote configured. Run once in your own terminal:"
  echo "  rclone config   (new remote, storage: drive)"
  exit 4
}
[ -f "$f" ] || { echo "no such file: $f"; exit 2; }

rclone copy --drive-import-formats docx "$f" "$remote:$dest" -P
echo "uploaded: $remote:$dest/$(basename "$f" .docx) (converted to a Google Doc on upload)"
echo "link it: rclone link \"$remote:$dest/$(basename "$f" .docx)\""
