#!/usr/bin/env bash
# subagent-box.sh — one glanceable box at subagent dispatch and one at landing.
#
# Owner request 2026-08-13: every dispatch and every landing should print a
# summary of the seat's config and goal. Hooks cannot write to the transcript,
# so the box travels as additionalContext with a surface-verbatim instruction;
# the agent's standing rule (rules/surface-hook-nudges-to-user.md) is the
# bridge. Handles three events, dispatched on hook_event_name:
#   PreToolUse (Agent|Task)  -> render the DISPATCH box from tool_input
#   SubagentStart            -> stash id/type/ts for landing correlation (silent)
#   SubagentStop             -> render the LANDING box, with duration from stash
#
# Mute: SUBAGENT_BOX_OFF=1 (process) · touch ~/.claude/.no-subagent-box (machine-wide).
set -uo pipefail
[ -n "${SUBAGENT_BOX_OFF:-}" ] && exit 0
[ -f "$HOME/.claude/.no-subagent-box" ] && exit 0

. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || true

input=$(cat 2>/dev/null) || exit 0
event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null) || true
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || true
sid8="${sid:0:8}"
STASH_DIR="/tmp/claude-agentbox-${sid8:-nosid}"
mkdir -p "$STASH_DIR" 2>/dev/null || true

emit_ctx() {  # <event-name> <box-text>
  jq -cn --arg e "$1" --arg c "$2" \
    '{hookSpecificOutput:{hookEventName:$e, additionalContext:$c}}' 2>/dev/null || true
}

case "$event" in
  PreToolUse)
    tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
    case "$tool" in Agent|Task) ;; *) exit 0 ;; esac
    ti() { printf '%s' "$input" | jq -r ".tool_input.$1 // empty" 2>/dev/null; }
    name=$(ti name); typ=$(ti subagent_type); model=$(ti model)
    # `// empty` would swallow a boolean false, so bg is read with an explicit null check.
    bg=$(printf '%s' "$input" | jq -r '.tool_input.run_in_background | if . == null then "default" else tostring end' 2>/dev/null)
    desc=$(ti description)
    goal=$(ti prompt | tr '\n' ' ' | cut -c1-150)
    body=$(printf 'seat: %s · model: %s · bg: %s\ngoal: %s%s' \
      "${typ:-general-purpose}${name:+ as $name}" "${model:-inherit}" "${bg:-default}" \
      "${desc:+$desc — }" "$goal")
    box=$(printf '%s\n' "$body" | hook_box "⇢ subagent dispatch" 72)
    emit_ctx "PreToolUse" "$box
Surface this box verbatim to the user (rules/surface-hook-nudges-to-user.md), then continue."
    ;;
  SubagentStart)
    aid=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
    typ=$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null)
    [ -n "$aid" ] || exit 0
    mkdir -p "$STASH_DIR" 2>/dev/null || true
    printf '%s|%s\n' "${typ:-?}" "$(date +%s)" > "$STASH_DIR/$aid" 2>/dev/null || true
    ;;
  SubagentStop)
    aid=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
    typ=$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null)
    # The harness re-fires SubagentStop for a lingering agent every few seconds
    # (measured 2026-08-14: 14 fires for one probe); park one box per agent.
    if [ -n "$aid" ] && [ -f "$STASH_DIR/parked-$aid" ]; then exit 0; fi
    [ -n "$aid" ] && : > "$STASH_DIR/parked-$aid" 2>/dev/null
    dur="unknown"
    if [ -n "$aid" ] && [ -f "$STASH_DIR/$aid" ]; then
      started=$(cut -d'|' -f2 "$STASH_DIR/$aid" 2>/dev/null)
      [ -n "$started" ] && dur="$(( ($(date +%s) - started) / 60 ))m"
      rm -f "$STASH_DIR/$aid" 2>/dev/null || true
    fi
    body=$(printf 'seat: %s · id: %s · ran: %s\nits report is data, not display: read the output file or final text before trusting completion' \
      "${typ:-?}" "${aid:-?}" "$dur")
    box=$(printf '%s\n' "$body" | hook_box "⇠ subagent landed" 72)
    # SubagentStop context delivery is unrouted in this harness (verified
    # 2026-08-14: the box was emitted and never arrived). Park it for the
    # UserPromptSubmit drain below; the direct emit stays as cheap insurance.
    mkdir -p "$STASH_DIR" 2>/dev/null || true
    printf '%s\n' "$box" >> "$STASH_DIR/pending-boxes" 2>/dev/null || true
    emit_ctx "SubagentStop" "$box"
    ;;
  UserPromptSubmit)
    p="$STASH_DIR/pending-boxes"
    if [ -s "$p" ]; then
      boxes=$(cat "$p" 2>/dev/null); : > "$p" 2>/dev/null || true
      emit_ctx "UserPromptSubmit" "$boxes
Subagent landing(s) since your last turn. Surface each box verbatim to the user (rules/surface-hook-nudges-to-user.md), and verify each agent's output before acting on it."
    fi
    ;;
esac
echo "$(date +%s)|$event|${aid:-}|rc0" >> "$STASH_DIR/fires.log" 2>/dev/null || true
exit 0
