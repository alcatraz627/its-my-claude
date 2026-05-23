#!/usr/bin/env bash
# PreToolUse[Bash] hook: hard-stop prod/unknown-env writes to gated CLIs.
#
# Stops the command (exit 2) so the human confirms by re-issuing after explicit
# approval. exit-2 is used deliberately — it is the only PreToolUse mechanism
# that fires regardless of permission mode (including --dangerously-skip-
# permissions), and is immune to CC#39344. Reads + proven-dev writes pass.
#
# Reads JSON on stdin (tool_name, tool_input.command). Policy: cli-gating.json.

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY="$HOME/.claude/conventions/cli-gating.json"
PROJECT_POLICY=""  # resolved below from cwd if present
DISABLE_MARKER="$HOME/.claude/cli-gating.off"

[ -f "$DISABLE_MARKER" ] && exit 0

input=$(cat 2>/dev/null)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool_name" = "Bash" ] || exit 0

command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$command" ] || exit 0

# Early bail: if no gated CLI name appears at all, skip the Python spawn.
# (Cheap substring screen — the Python core does the real word-boundary check.)
case " $command " in
  *render*|*vercel*|*gh\ *|*\ gh*) : ;;
  *) exit 0 ;;
esac

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$cwd" ] && [ -f "$cwd/.claude/cli-gating.json" ]; then
  PROJECT_POLICY="$cwd/.claude/cli-gating.json"
fi

# Run the classifier. Use project policy if present (tighten-only merge is the
# Python core's job in a later iteration; for now project policy fully replaces
# when present — Phase 1 keeps it simple, global is the safe default).
EFFECTIVE_POLICY="${PROJECT_POLICY:-$POLICY}"

verdict=$(python3 "$DIR/gate_cli_actions.py" "$command" "$EFFECTIVE_POLICY" 2>/dev/null)
rc=$?

if [ $rc -ne 0 ] || [ -z "$verdict" ]; then
  # Classifier crashed. Fail-split: block only if the command plainly contains a
  # gated write verb; otherwise allow (don't brick reads on a hook bug).
  if printf '%s' "$command" | grep -qE '\b(render (deploy|restart|scale|secret|env)|vercel (deploy|env|alias|rm|rollback)|gh (repo delete|release|secret|push|pr merge))\b'; then
    printf '🛑 CLI GATE (fail-closed): classifier errored on a command containing a gated write verb. Blocked for safety.\nCommand: %s\nTo proceed: have the human confirm, then re-issue.\n' "$command" >&2
    exit 2
  fi
  exit 0
fi

case "$verdict" in
  ALLOW)
    exit 0
    ;;
  BLOCK*)
    reason="${verdict#BLOCK	}"
    # Telemetry: record the fire so the claude-audit dream domain can see it.
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook cli-gating --heeded unknown >/dev/null 2>&1 &
    printf '🛑 CLI PROD-WRITE GATE — hard stop (not a guess).\n\nReason: %s\n\nThis is blocked to prevent an accidental production write. To proceed:\n  1. The human explicitly confirms this exact operation.\n  2. Re-issue the command after confirmation.\n\nSafe alternatives:\n  • render/vercel: drop the --prod/--production flag for a preview/dev op.\n  • gh: target a non-default branch, or run the read-only variant (view/list).\n\n⚠ Do NOT try to work around this gate. If you believe it is WRONG (e.g. it blocked a read), do BOTH:\n  • log it: bash ~/.claude/scripts/hooks/hook-feedback.sh --hook cli-gating --kind false-positive --note "<what you were doing>"\n  • tell the user. Routing around a guard instead of surfacing it is itself the failure mode.\nOverride entirely: touch ~/.claude/cli-gating.off (disables ALL CLI gating).\n' "$reason" >&2
    exit 2
    ;;
  *)
    # Unknown verdict — fail closed for safety.
    printf '🛑 CLI GATE: unrecognized classifier output (%s). Blocked for safety.\n' "$verdict" >&2
    exit 2
    ;;
esac
