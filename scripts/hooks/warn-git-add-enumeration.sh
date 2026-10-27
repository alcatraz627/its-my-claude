#!/usr/bin/env bash
# warn-git-add-enumeration.sh: PreToolUse hook on Bash.
#
# Graduated from atone pattern: generalize-before-enumerate (S3, 3×).
# When the agent ships `git add a.ts b.ts c.ts d.ts ...` with ≥4 paths, it
# often means a parent dir would have covered the set cleanly. Listing items
# invites the user to execute literally before noticing the abstraction.
#
# This hook is ADVISORY (always exits 0). It injects an additionalContext nudge
# before the command runs, suggesting a parent-dir check; the agent still runs
# the command but surfaces the nudge to the user (stderr would reach neither:
# see features/hooks-tui-limits.md).
#
# Why advisory instead of blocking: legitimate cases exist (cherry-picking
# specific files across non-overlapping dirs). A block would frustrate; a
# warning informs.

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
echo "$INPUT" | jq empty 2>/dev/null || exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

SID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
# Heed tracking: a fire is heeded when the next `git add` in the session is not an
# enumeration of 4 or more paths (hook_heed_note in hook-common.sh).
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || true
heed() { type hook_heed_note >/dev/null 2>&1 && hook_heed_note warn-git-add-enumeration "$SID" git-add "$1"; return 0; }

# Mute via env (one-shot) or file (per-session)
[ "${ATONE_NO_ADD_WARN:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/atone/.add-warn-off" ] && exit 0
# Multi-session repo with a live sibling in the same cwd: enumeration IS the safety
# property (a parent add sweeps the sibling's edits), so the warning would argue for
# the wrong thing. prop-20260717-152247-a0, fired again on the 2026-08-27 commit.
if command -v claude-ipc >/dev/null 2>&1; then
  me="${CLAUDE_CODE_SESSION_ID:-}"
  live=$(claude-ipc peers --by-session 2>/dev/null | jq -r --arg cwd "$PWD" --arg me "$me" '[.peers[]? | select(.status=="live" and .cwd==$cwd and .sessionId!=$me)] | length' 2>/dev/null)
  [ "${live:-0}" -gt 0 ] && exit 0
fi

# Skip when invoked from an atone-suite script
echo "$CMD" | grep -qE '/\.claude/scripts/atone' && exit 0

# Extract `git add <args>`. Skip if the command is something else entirely.
# We allow leading env-vars (e.g. `FOO=bar git add ...`) but stop at && / | / ;.
#
# Scan a copy with quoted strings and heredoc bodies blanked, and count `git add`
# only at a command position, so a commit message, doc string or heredoc that
# DESCRIBES a staging call is not read as one. Falls back to the raw command when
# the helper is unreadable.
STRIP="$HOME/.claude/scripts/hooks/strip-payloads.py"
SCAN="$CMD"
if [ -r "$STRIP" ]; then
  _stripped=$(printf '%s' "$CMD" | python3 "$STRIP" 2>/dev/null)
  [ -n "$_stripped" ] && SCAN="$_stripped"
fi
GIT_ADD_LINE=$(printf '%s\n' "$SCAN" | grep -oE '(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*git[[:space:]]+add[[:space:]]+[^&|;]*' | head -1)
[ -z "$GIT_ADD_LINE" ] && exit 0

# Count path-shaped args after `git add` (anything not starting with `-`).
N_PATHS=$(echo "$GIT_ADD_LINE" | awk '{
  count = 0
  found_add = 0
  for (i = 1; i <= NF; i++) {
    if (!found_add) {
      if ($i == "add") found_add = 1
      continue
    }
    # Skip flags
    if ($i ~ /^-/) continue
    count++
  }
  print count
}')

[ "$N_PATHS" -lt 4 ] && { heed clean; exit 0; }

# Try to find a common parent directory for the args (best-effort hint).
COMMON_PARENT=$(echo "$GIT_ADD_LINE" | awk '{
  found_add = 0
  for (i = 1; i <= NF; i++) {
    if (!found_add) { if ($i == "add") found_add = 1; continue }
    if ($i ~ /^-/) continue
    paths[NR ":" i] = $i
  }
}
END {
  # Find longest common prefix that ends at a "/"
  prefix = ""
  first = 1
  for (k in paths) {
    if (first) { prefix = paths[k]; first = 0; continue }
    while (index(paths[k], prefix) != 1 && length(prefix) > 0) {
      prefix = substr(prefix, 1, length(prefix) - 1)
    }
  }
  # Trim to last /
  while (length(prefix) > 0 && substr(prefix, length(prefix), 1) != "/") {
    prefix = substr(prefix, 1, length(prefix) - 1)
  }
  if (length(prefix) > 0) print prefix
}')

# Record feedback signal
( bash "$HOME/.claude/scripts/atone.sh" feedback \
    --kind fired-and-useful \
    --slug generalize-before-enumerate \
    --trigger-id trig-generalize-before-enumerate \
    --notes "advisory fired: git add with $N_PATHS path args" \
    >/dev/null 2>&1 & ) &

heed fired
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook warn-git-add-enumeration --action nudge --heeded unknown >/dev/null 2>&1 || true

msg="[warn-git-add-enumeration] git add has $N_PATHS path args — consider generalizing first (generalize-before-enumerate, atone S3). Risk: enumerated commit recipes get executed literally by the user before the abstraction is noticed. Pre-check: 'git status ${COMMON_PARENT:-<parent-dir>}' — if clean (no leaks), the parent IS the answer. (mute: touch ~/.claude/atone/.add-warn-off ; one-shot: ATONE_NO_ADD_WARN=1)  →→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."
jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
exit 0
