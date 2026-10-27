#!/usr/bin/env bash
# subagent-box.sh: one glanceable box at subagent dispatch and one at landing.
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
    # The goal line is a summary a person reads at a glance: the seat header
    # line (if any) is metadata, not goal, and the cut lands on a word boundary.
    read -r seat out goal < <(ti prompt | python3 -c '
import re, sys
p = sys.stdin.read()
m = re.match(r"\s*\[seat (s-[0-9a-f-]+)\][^\n]*", p)
seat = m.group(1) if m else "-"
o = re.search(r"\boutput=(\S+)", m.group(0)) if m else None
body = " ".join((p[m.end():] if m else p).split())
if len(body) > 170:
    body = body[:170].rsplit(" ", 1)[0].rstrip(",;:") + " …"
print(seat, o.group(1) if o else "-", body)' 2>/dev/null)
    [ "$seat" = "-" ] && seat=""; [ "$out" = "-" ] && out=""
    printf '%s|%s|%s\n' "${desc//|/ }" "$out" "$seat" >> "$STASH_DIR/dispatch-queue" 2>/dev/null || true
    bgnote=""; [ "$bg" = "true" ] && bgnote=" · background"
    body=$(printf 'seat: %s%s%s\ngoal: %s%s' \
      "${typ:-general-purpose}${name:+ as $name}" "$bgnote" "${seat:+ · $seat}" \
      "${desc:+$desc: }" "$goal")
    box=$(printf '%s\n' "$body" | hook_box_kind dispatch "${typ:-general-purpose}" "${model:-inherit}")
    # The whole box is owner text: a gcc-mods session draws it as a transcript
    # line and the model never reads it; any other session pastes it as before.
    emit_ctx "PreToolUse" "$(printf '%s\nSurface this box verbatim to the user (rules/surface-hook-nudges-to-user.md), then continue.' "$box" | hook_owner_wrap log subagent-box)"
    ;;
  SubagentStart)
    aid=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
    typ=$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null)
    [ -n "$aid" ] || exit 0
    mkdir -p "$STASH_DIR" 2>/dev/null || true
    # Starts arrive in dispatch order, so the oldest queued dispatch is this
    # agent's: carry its description and output path to the landing box.
    q="$STASH_DIR/dispatch-queue" first=""
    if [ -s "$q" ]; then
      first=$(head -n 1 "$q"); tail -n +2 "$q" > "$q.tmp" 2>/dev/null && mv "$q.tmp" "$q"
    fi
    printf '%s|%s|%s\n' "${typ:-?}" "$(date +%s)" "$first" > "$STASH_DIR/$aid" 2>/dev/null || true
    ;;
  SubagentStop)
    aid=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
    typ=$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null)
    # The harness re-fires SubagentStop for a lingering agent every few seconds
    # (measured 2026-08-14: 14 fires for one probe); park one box per agent.
    if [ -n "$aid" ] && [ -f "$STASH_DIR/parked-$aid" ]; then exit 0; fi
    [ -n "$aid" ] && : > "$STASH_DIR/parked-$aid" 2>/dev/null
    # Stop-only strays (task #18, diagnosed 2026-08-14): the harness runs an
    # internal, unnamed agent roughly once per user turn; only its Stop reaches
    # hooks (bare-hex id, never a SubagentStart, no dispatch of ours; 79
    # stop-only vs 29 started machine-wide, while real seats always Start
    # first). Boxing each one trained the reader to ignore landings, so an
    # unmatched Stop goes to a ledger and the drain's deduped line-tag, never
    # a box. A real landing always has a stash entry and keeps the full box.
    if [ -n "$aid" ] && [ ! -f "$STASH_DIR/$aid" ]; then
      echo "$(date +%s)|$aid|${typ:-?}" >> "$STASH_DIR/unmatched.log" 2>/dev/null || true
      echo "$(date +%s)|SubagentStop-unmatched|$aid|rc0" >> "$STASH_DIR/fires.log" 2>/dev/null || true
      exit 0
    fi
    dur="unknown" ldesc="" lout=""
    if [ -n "$aid" ] && [ -f "$STASH_DIR/$aid" ]; then
      started=$(cut -d'|' -f2 "$STASH_DIR/$aid" 2>/dev/null)
      ldesc=$(cut -d'|' -f3 "$STASH_DIR/$aid" 2>/dev/null)
      lout=$(cut -d'|' -f4 "$STASH_DIR/$aid" 2>/dev/null)
      if [ -n "$started" ]; then
        el=$(( $(date +%s) - started ))
        if [ "$el" -lt 60 ]; then dur="${el}s"; else dur="$(( el / 60 ))m"; fi
      fi
      rm -f "$STASH_DIR/$aid" 2>/dev/null || true
    fi
    # Whether the seat wrote its file is the first thing the reader checks; the
    # path goes on its own unwrapped ▸ line, absolute, so the terminal links it.
    body="${ldesc:+goal: $ldesc}"
    [ -n "$body" ] || body=$(printf 'seat: %s · id: %s' "${typ:-?}" "${aid:-?}")
    box=""
    if [ -n "$lout" ] && [ -x "$HOME/.claude/scripts/box/box.sh" ]; then
      if [ -s "$lout" ]; then act="output written; read it before using what the seat said"
      else act="output NOT written: check the seat before relying on it"; fi
      box=$(printf '%s\n👉 %s\n' "$body" "$act" | "$HOME/.claude/scripts/box/box.sh" landing "${typ:-unknown}" \
        --attr "ran $dur" --ref "$lout" 2>/dev/null) || box=""
    fi
    [ -n "$box" ] || box=$(printf '%s\n' "$body" | hook_box_kind landing "${typ:-unknown}" "ran $dur")
    # SubagentStop context delivery is unrouted in this harness (verified
    # 2026-08-14: the box was emitted and never arrived). Park it for the
    # UserPromptSubmit drain below; the direct emit stays as cheap insurance.
    mkdir -p "$STASH_DIR" 2>/dev/null || true
    printf '%s\n' "$box" >> "$STASH_DIR/pending-boxes" 2>/dev/null || true
    emit_ctx "SubagentStop" "$(printf '%s\n' "$box" | hook_owner_wrap log subagent-box)"
    ;;
  UserPromptSubmit)
    p="$STASH_DIR/pending-boxes"
    boxes=''
    if [ -s "$p" ]; then
      boxes=$(cat "$p" 2>/dev/null); : > "$p" 2>/dev/null || true
    fi
    # Stop-only strays are harness internals with no action owed: they stay in
    # unmatched.log (written above) and never reach the model.
    if [ -n "$boxes" ]; then
      # The boxes and the paste instruction are owner text; the duty to verify
      # each agent's output stays outside the block so the model keeps it.
      owner=$(printf '%s\nSubagent landing(s) since your last turn. Surface each box verbatim to the user (rules/surface-hook-nudges-to-user.md).' "$boxes" | hook_owner_wrap log subagent-box)
      ctx="$owner
Subagent landing(s) since your last turn: verify each agent's output before acting on it."
      emit_ctx "UserPromptSubmit" "$ctx"
    fi
    ;;
esac
echo "$(date +%s)|$event|${aid:-}|rc0" >> "$STASH_DIR/fires.log" 2>/dev/null || true
exit 0
