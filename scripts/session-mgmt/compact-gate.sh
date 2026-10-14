#!/usr/bin/env bash
# Stops Claude Code from compacting a session on its own, unless the owner told
# that session to keep working through compaction.
#
# The owner's own /compact always goes through. An automatic compaction (context
# full, or the idle pre-expiry one) is refused unless the session opted in with
# `compact-gate.sh on`, which an agent runs when the owner says to keep going
# through compaction. A refused compaction makes no API call, so it costs nothing;
# the session carries on uncompacted until the owner compacts or clears it.
#
# Usage:
#   compact-gate.sh hook      PreCompact hook (payload on stdin); exit 2 refuses
#   compact-gate.sh on|off    opt this session in or out (uses CLAUDE_CODE_SESSION_ID)
#   compact-gate.sh status
# Machine-wide mute (every session may auto-compact): touch ~/.claude/.no-compact-gate

set -uo pipefail

DIR="${COMPACT_GATE_DIR:-/tmp/claude-compact-through}"
MUTE="${COMPACT_GATE_MUTE:-$HOME/.claude/.no-compact-gate}"

marker() { printf '%s/%s' "$DIR" "$1"; }

case "${1:-}" in
  hook)
    input=$(cat 2>/dev/null)
    trigger=$(printf '%s' "$input" | jq -r '.trigger // empty' 2>/dev/null)
    sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
    [[ "$trigger" == "auto" ]] || exit 0
    [[ -f "$MUTE" ]] && exit 0
    [[ -n "$sid" && -f "$(marker "$sid")" ]] && exit 0
    echo "Auto-compaction refused: this session was not told to keep going through compaction. Run /compact yourself, or tell the agent to keep going (it runs compact-gate.sh on)." >&2
    exit 2
    ;;
  on|off|status)
    sid="${CLAUDE_CODE_SESSION_ID:-}"
    [[ -n "$sid" ]] || { echo "compact-gate: no CLAUDE_CODE_SESSION_ID; run this from inside a Claude session" >&2; exit 1; }
    case "$1" in
      on) mkdir -p "$DIR"; touch "$(marker "$sid")"; echo "auto-compaction allowed for ${sid:0:8}" ;;
      off) trash "$(marker "$sid")" 2>/dev/null; echo "auto-compaction refused for ${sid:0:8}" ;;
      status) [[ -f "$(marker "$sid")" ]] && echo "allowed" || echo "refused" ;;
    esac
    ;;
  *)
    sed -n '2,16p' "$0"
    exit 1
    ;;
esac
