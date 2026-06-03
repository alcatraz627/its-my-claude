#!/usr/bin/env bash
# hint-injector.sh — UserPromptSubmit hook that runs all hinters and aggregates
# their output into a single additionalContext injection.
#
# Hinters live in ~/.claude/hinters/ and are executed in sort order (00-, 10-, etc).
# Each hinter reads the prompt from stdin and emits at most one hint line to stdout.
# Hinters that emit nothing are silently skipped.
#
# Each hinter is hard-capped at 2s (see _cap_hinter below) so a runaway can't
# stall the prompt. Hinters should still aim for <100ms; the cap is a backstop.
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

# Hard per-hinter time cap so one slow hinter can't stall the user's prompt.
# macOS ships no `timeout`; fall back to a perl alarm (a pending alarm survives
# exec, so it still kills the bash that replaces perl).
TIMEOUT_BIN=$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || true)
_cap_hinter() {
    if [[ -n "$TIMEOUT_BIN" ]]; then
        "$TIMEOUT_BIN" 2 bash "$1" 2>/dev/null
    else
        # No `timeout` on macOS. Fork the hinter into its OWN process group and
        # kill the whole group on alarm — a plain alarm+exec only kills the
        # shell, leaving a hung child holding the output pipe open past the cap
        # (verified: it didn't time out at all). This kills children too.
        perl -e 'my $p=fork; if($p==0){setpgrp(0,0); exec(@ARGV) or exit 127} local $SIG{ALRM}=sub{kill "KILL",-$p}; alarm 2; waitpid($p,0)' bash "$1" 2>/dev/null
    fi
}

# Run each hinter, collect non-empty output
HINTS=""
for hinter in "$HINTER_DIR"/*.sh; do
    [[ -f "$hinter" ]] || continue
    [[ -x "$hinter" ]] || continue

    # Run hinter (time-capped), feed prompt via stdin
    hint=$(echo "$PROMPT" | _cap_hinter "$hinter" || true)
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
