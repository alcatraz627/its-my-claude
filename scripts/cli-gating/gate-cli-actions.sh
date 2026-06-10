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
# (Cheap substring screen — the Python core does the real word-boundary check,
# so over-matching here costs only an extra python spawn, never correctness.)
# Whitespace is normalized first so a tab/newline between the CLI and its
# subcommand (`aws<TAB>s3 rm`) can't dodge the screen and skip the classifier.
_screen=$(printf '%s' "$command" | tr '\t\n' '  ')
case " $_screen " in
  *render*|*vercel*|*gh\ *|*\ gh*|*aws\ *) : ;;
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
  if printf '%s' "$command" | grep -qE '\b(render (deploy|restart|scale|secret|env)|vercel (deploy|env|alias|rm|rollback)|gh (repo delete|release|secret|push|pr merge)|aws s3 (rm|cp|sync|mv|mb|rb)|aws [a-z0-9-]+ (delete|create|put|update|terminate|modify|attach|detach|run|stop|reboot|deregister|register|revoke|authorize|disable|enable|remove|set|associate|disassociate))\b'; then
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
    # Per-command approval: a one-shot nonce keyed on the EXACT command. If the
    # human approved THIS command (via AskUserQuestion) and dropped the nonce,
    # allow it once and consume the nonce. The exit 2 below fires even in bypass.
    HASH=$(printf '%s' "$command" | shasum -a 256 2>/dev/null | cut -c1-16)
    NONCE="$HOME/.claude/.cli-approve-$HASH"
    if [ -n "$HASH" ] && [ -f "$NONCE" ]; then
      AGE=$(( $(date +%s) - $(stat -f %m "$NONCE" 2>/dev/null || echo 0) ))
      rm -f "$NONCE"
      [ "$AGE" -ge 0 ] && [ "$AGE" -le 300 ] && exit 0
    fi
    # Telemetry: record the fire so the claude-audit dream domain can see it.
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook cli-gating --heeded unknown >/dev/null 2>&1 &
    printf '🛑 CLI WRITE GATE — human approval required (fires even in bypass).\n\nReason: %s\n\nEVERY write to a gated CLI (render/vercel/gh), any env, needs per-command approval. To proceed:\n  1. SHOW the user the exact command + a one-line plain-English note of what it does + its env, THEN ask with AskUserQuestion. Never ask without showing the command first.\n  2. On approval:  touch %s\n  3. Re-issue the EXACT same command. Approval is one-shot, expires in 300s.\n\nReads are never gated. If this blocked a READ, it is a bug: log it (bash ~/.claude/scripts/hooks/hook-feedback.sh --hook cli-gating --kind false-positive --note "...") and tell the user. Broad override: touch ~/.claude/cli-gating.off\n' "$reason" "$NONCE" >&2
    exit 2
    ;;
  *)
    # Unknown verdict — fail closed for safety.
    printf '🛑 CLI GATE: unrecognized classifier output (%s). Blocked for safety.\n' "$verdict" >&2
    exit 2
    ;;
esac
