#!/usr/bin/env bash
# hint-injector.sh — UserPromptSubmit hook that runs all hinters and aggregates
# their output into a single additionalContext injection.
#
# Hinters live in ~/.claude/hinters/ and are executed in sort order (00-, 10-, etc).
# Each hinter reads the prompt from stdin and emits at most one hint line to stdout.
# Hinters that emit nothing are silently skipped.
#
# Each hinter has a 100ms timeout (generous for shell scripts, strict for latency).
# Total budget: ~300ms for all hinters combined.
#
# Output: JSON {"hookSpecificOutput": {"additionalContext": "..."}} to stdout.

set -uo pipefail

HINTER_DIR="${HOME}/.claude/hinters"

[[ -d "$HINTER_DIR" ]] || exit 0

# Read hook input from stdin
INPUT=$(cat 2>/dev/null || echo "{}")

# Extract prompt text from hook input
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")
[[ -z "$PROMPT" ]] && exit 0

# Run each hinter, collect non-empty output
HINTS=""
for hinter in "$HINTER_DIR"/*.sh; do
    [[ -f "$hinter" ]] || continue
    [[ -x "$hinter" ]] || continue

    # Run hinter, feed prompt via stdin
    hint=$(echo "$PROMPT" | bash "$hinter" 2>/dev/null || true)
    if [[ -n "$hint" ]]; then
        if [[ -n "$HINTS" ]]; then
            HINTS="${HINTS}\n${hint}"
        else
            HINTS="$hint"
        fi
    fi
done

[[ -z "$HINTS" ]] && exit 0

# Emit aggregated hints as additionalContext.
# Note (2026-05-15): hookSpecificOutput MUST include hookEventName per Claude
# Code's UserPromptSubmit hook contract. Prior version omitted this, which
# caused payloads to land as `hook_non_blocking_error` (still visible to the
# model via stdout, but marked as malformed). Fix surfaced via atone tone
# investigation; see assets/reports/20260515-backend-session-tone-investigation/.
CONTEXT=$(printf '%b' "$HINTS")
jq -cn --arg ctx "$CONTEXT" '{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": $ctx
  }
}'
