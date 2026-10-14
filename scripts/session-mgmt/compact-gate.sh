#!/usr/bin/env bash
# Stops Claude Code from compacting a session on its own, unless the owner told
# that session to keep working through compaction.
#
# The owner's own /compact always goes through. An automatic compaction (context
# full, or the idle pre-expiry one) is refused unless the session opted in with
# `compact-gate.sh on`, which an agent runs when the owner says to keep going
# through compaction. A refused compaction makes no API call, so it costs nothing.
# Every decision and opt-in is logged so compaction can be compared with
# /core-dump + /catchup on real sessions (`compact-gate.sh report`).
#
# Usage:
#   compact-gate.sh hook      PreCompact hook (payload on stdin); exit 2 refuses
#   compact-gate.sh on|off    opt this session in or out (uses CLAUDE_CODE_SESSION_ID)
#   compact-gate.sh status | report
# Machine-wide mute (every session may auto-compact): touch ~/.claude/.no-compact-gate

set -uo pipefail

DIR="${COMPACT_GATE_DIR:-/tmp/claude-compact-through}"
MUTE="${COMPACT_GATE_MUTE:-$HOME/.claude/.no-compact-gate}"
LOG="${COMPACT_GATE_LOG:-$HOME/.claude/compact-gate/events.jsonl}"
THRESHOLD=$(jq -r '.env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE // "92"' "$HOME/.claude/settings.json" 2>/dev/null)

marker() { printf '%s/%s' "$DIR" "$1"; }

# Context used, in percent, from the statusline's per-process reading (it stores
# percent LEFT). Empty when there is no reading.
ctx_pct() {
  local f="/tmp/claude-ctx-${CLAUDE_PID:-$PPID}"
  [[ -r "$f" ]] && awk '{ printf "%d", 100 - $1 }' "$f" 2>/dev/null
}

log() { # event sid [key value]...
  mkdir -p "$(dirname "$LOG")"
  local ev="$1" sid="$2"; shift 2
  jq -cn --arg ev "$ev" --arg sid "$sid" --arg ts "$(date -u +%FT%TZ)" --arg ctx "$(ctx_pct)" \
    --args '{ts:$ts, ev:$ev, sid:$sid, ctx_pct:($ctx|tonumber? // null)}
            + ($ARGS.positional as $p | [range(0; $p|length; 2) | {($p[.]): $p[.+1]}] | add // {})' "$@" >> "$LOG" 2>/dev/null
}

case "${1:-}" in
  hook)
    input=$(cat 2>/dev/null)
    trigger=$(printf '%s' "$input" | jq -r '.trigger // empty' 2>/dev/null)
    sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
    tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
    if [[ "$trigger" != "auto" ]]; then log manual "$sid" transcript "$tp"; exit 0; fi
    if [[ -f "$MUTE" ]]; then log allowed "$sid" why mute transcript "$tp"; exit 0; fi
    if [[ -n "$sid" && -f "$(marker "$sid")" ]]; then log allowed "$sid" why opted-in transcript "$tp"; exit 0; fi
    log refused "$sid" transcript "$tp"
    echo "Auto-compaction refused: this session was not told to keep going through compaction. Run /compact yourself, or tell the agent to keep going (it runs compact-gate.sh on)." >&2
    exit 2
    ;;
  on|off|status)
    sid="${CLAUDE_CODE_SESSION_ID:-}"
    [[ -n "$sid" ]] || { echo "compact-gate: no CLAUDE_CODE_SESSION_ID; run this from inside a Claude session" >&2; exit 1; }
    case "$1" in
      on)
        mkdir -p "$DIR"; touch "$(marker "$sid")"; log on "$sid"
        pct=$(ctx_pct)
        echo "auto-compaction allowed for ${sid:0:8} (compacts at ${THRESHOLD}% context; now ${pct:-?}%)"
        if [[ -n "$pct" && "$pct" -ge "$THRESHOLD" ]]; then
          echo "Already past the threshold: compaction runs at the next model call, mid-task."
        fi
        echo "Before it runs, make the Task list and session notes current; the summary carries them."
        ;;
      off) trash "$(marker "$sid")" 2>/dev/null; log off "$sid"; echo "auto-compaction refused for ${sid:0:8}" ;;
      status) [[ -f "$(marker "$sid")" ]] && echo "allowed" || echo "refused" ;;
    esac
    ;;
  report)
    [[ -s "$LOG" ]] || { echo "no compaction events yet ($LOG)"; exit 0; }
    jq -rs 'group_by(.ev) | map("\(.[0].ev): \(length)  ctx% median \((map(.ctx_pct // empty) | sort | if length > 0 then .[length/2|floor] else "-" end))") | .[]' "$LOG"
    ;;
  *)
    sed -n '2,17p' "$0"
    exit 1
    ;;
esac
