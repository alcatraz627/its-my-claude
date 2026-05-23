#!/usr/bin/env bash
# prefer-tmp-py-over-inline.sh — PreToolUse[Bash] nudge.
# Multi-line `python3 -c '...'` has no traceback line numbers in Bash output
# and is shell-quoting-sensitive. Suggests /tmp/<slug>.py for debuggability.
#
# Threshold: >5 newlines in the -c arg. Short one-liners are fine.
#
# Mute: touch ~/.claude/.no-inline-py-hint

set -uo pipefail
[[ -f "$HOME/.claude/.no-inline-py-hint" ]] && exit 0

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# Detect python3 -c '...' and count newlines in the script body
# Match either single or double quoted forms. Use python3 itself for parsing
# to avoid bash-regex fragility on multi-line strings.
nl=$(python3 - "$CMD" <<'PY' 2>/dev/null
import sys, re
cmd = sys.argv[1]
# Find python3 -c '...' (or "...") — capture content
m = re.search(r"python3?\s+-c\s+(['\"])((?:(?!\1).|\n)*)\1", cmd)
if not m:
    print(0); sys.exit()
body = m.group(2)
print(body.count("\n"))
PY
)
nl=${nl:-0}
(( nl > 5 )) || exit 0

cat <<EOF
[hint] python3 -c with $nl newlines: tracebacks show "<string>" instead of
real line numbers. Prefer:
  cat > /tmp/<slug>.py <<'PY'
  ...script...
  PY
  python3 /tmp/<slug>.py
Wins: real line numbers in tracebacks, re-runnable, no shell-quote bugs.
Mute: touch ~/.claude/.no-inline-py-hint
EOF
exit 0
