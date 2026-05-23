#!/usr/bin/env bash
# warn-git-add-enumeration.sh — PreToolUse hook on Bash.
#
# Graduated from atone pattern: generalize-before-enumerate (S3, 3×).
# When the agent ships `git add a.ts b.ts c.ts d.ts ...` with ≥4 paths, it
# often means a parent dir would have covered the set cleanly. Listing items
# invites the user to execute literally before noticing the abstraction.
#
# This hook is ADVISORY (always exits 0). It emits a stderr warning before
# the command runs, suggesting a parent-dir check. The agent still runs the
# command; the user gets a visible hint that the form is enumeration-shaped.
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

# Mute via env (one-shot) or file (per-session)
[ "${ATONE_NO_ADD_WARN:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/atone/.add-warn-off" ] && exit 0

# Skip when invoked from an atone-suite script
echo "$CMD" | grep -qE '/\.claude/scripts/atone' && exit 0

# Extract `git add <args>`. Skip if the command is something else entirely.
# We allow leading env-vars (e.g. `FOO=bar git add ...`) but stop at && / | / ;.
GIT_ADD_LINE=$(echo "$CMD" | grep -oE '\bgit\s+add\s+[^&|;]*' | head -1)
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

[ "$N_PATHS" -lt 4 ] && exit 0

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

cat >&2 <<EOF
[warn-git-add-enumeration] git add has $N_PATHS path args — consider generalizing first.

  Pattern: generalize-before-enumerate (atone S3, 3 recurrences)
  Risk:    enumerated commit recipes get executed literally by the user
           before the abstraction is noticed.

  Pre-check (run before submitting the list):
    git status ${COMMON_PARENT:-<parent-dir>}    # if clean (no leaks), parent IS the answer

  Mute: touch ~/.claude/atone/.add-warn-off
  One-shot bypass: ATONE_NO_ADD_WARN=1 git add ...

EOF
exit 0
