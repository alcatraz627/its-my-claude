#!/usr/bin/env bash
# snapshot-pre-edit.sh — keep one copy of each file as it looked before this
# session first touched it.
#
# review-gate-stop's Gate 2 asks "what did this change add?", and until now it
# answered with `git diff HEAD`. That answer includes every uncommitted line in
# the file, whoever wrote it. On a machine where several sessions work the same
# tree (this repo carries 150 uncommitted files) the gate reads another session's
# work as yours, which is nine proposals' worth of complaint under
# prop-20260807-102156-94 and its siblings.
#
# A snapshot taken in PostToolUse cannot help, because by then the edit has
# landed. So this runs in PreToolUse, writes once per file per session, and never
# overwrites: the first copy is the only honest baseline.
#
# Cheap by construction. One `cp` per file per session, into a session directory
# that /tmp reaps. Files over 2MB are skipped rather than copied.
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$fp" ] && [ -n "$sid" ] || exit 0

DIR="/tmp/claude-presnap-${sid:0:8}"
mkdir -p "$DIR" 2>/dev/null || exit 0
# Canonicalise before hashing. On macOS /tmp and /var are symlinks, so the
# writer and the reader must agree on one form or the lookup silently misses
# and the gate falls back to the shared HEAD baseline it was built to replace.
fp_real=$(cd "$(dirname "$fp")" 2>/dev/null && printf '%s/%s' "$(pwd -P)" "$(basename "$fp")") || fp_real="$fp"
key=$(printf '%s' "$fp_real" | shasum 2>/dev/null | awk '{print $1}')
[ -n "$key" ] || exit 0
snap="$DIR/$key"

# First write wins. A later edit in the same session must not move the baseline,
# or the gate stops seeing everything the session did.
[ -e "$snap" ] && exit 0

# A file that does not exist yet gets an EMPTY baseline, not no baseline. This is
# the case that made the gate undercount: a Write creates the file, nothing is
# snapshotted because there is nothing to copy, then a later Edit snapshots
# content that ALREADY contains the session's own new exports. Diffing against
# that hides them. An empty baseline makes the whole body read as added, which
# is what a session-authored file actually is.
if [ ! -f "$fp" ]; then
  : > "$snap" 2>/dev/null || true
  exit 0
fi

sz=$(wc -c < "$fp" 2>/dev/null | tr -d ' ')
[ "${sz:-0}" -le 2097152 ] 2>/dev/null || exit 0
cp -f "$fp" "$snap" 2>/dev/null || true
exit 0
