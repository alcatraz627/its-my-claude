#!/usr/bin/env bash
# subagent-box.sh: one glanceable box at subagent dispatch and one at landing.
#
# Owner request 2026-08-13: every dispatch and every landing should print a
# summary of the seat's config and goal. Three or more seats sent out together
# share one fleet box instead, with a cost estimate per seat, and land into one
# fleet box that fills in as each seat reports, with what it actually cost
# (owner, 2026-10-28). Hooks cannot write to the transcript, so a box travels as
# additionalContext with a surface-verbatim instruction; the agent's standing
# rule (rules/surface-hook-nudges-to-user.md) is the bridge. Events:
#   PreToolUse (Agent|Task)  -> the DISPATCH box, or the fleet box at 3+ seats
#   SubagentStart            -> stash id/type/ts for landing correlation (silent)
#   SubagentStop             -> the LANDING box, or the updated fleet landing
#   UserPromptSubmit         -> drain the parked landing boxes to the model
#
# Mute: SUBAGENT_BOX_OFF=1 (process) · touch ~/.claude/.no-subagent-box (machine-wide).
set -uo pipefail
[ -n "${SUBAGENT_BOX_OFF:-}" ] && exit 0
[ -f "$HOME/.claude/.no-subagent-box" ] && exit 0

. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || true

BOXSH="$HOME/.claude/scripts/box/box.sh"
COST="$HOME/.claude/scripts/box/seat-cost.py"
# Dispatches closer together than this belong to one batch: parallel Agent
# calls in one message arrive within a second or two of each other.
BURST_GAP="${SUBAGENT_BURST_GAP:-20}"
FLEET_MIN=3

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


# fleet_out <bid>: the dispatch box for a whole batch, one row per seat.
fleet_out() {
  local bid="$1" args=() n=0 total=0 known=0 ts b i model est desc
  while IFS='|' read -r ts b i model est desc; do
    [ "$b" = "$bid" ] || continue
    n=$((n + 1))
    [ -n "$est" ] && { total=$(awk -v a="$total" -v b="$est" 'BEGIN{printf "%.2f", a+b}'); known=$((known + 1)); }
    args+=(--row "info:$i" "$(printf '%-6s  %-6s  %s' "$model" "${est:+~\$$est}" "$desc")")
  done < "$STASH_DIR/burst"
  # No estimate at all says nothing; a partial one says it is a floor.
  local attr=""
  [ "$known" -gt 0 ] && attr="est ~\$$total"
  [ "$known" -gt 0 ] && [ "$known" -lt "$n" ] && attr="$attr+"
  bash "$BOXSH" fleet-out "$n seats" ${attr:+--attr "$attr"} "${args[@]}" 2>/dev/null
}

# fleet_in <bid>: the landing box for a batch; seats still out show as waiting.
fleet_in() {
  local bid="$1" args=() n=0 back=0 sum=0 known=0 first=0 ts b i model est desc
  local outs=() st dur cost ldesc lout line
  while IFS='|' read -r ts b i model est desc; do
    [ "$b" = "$bid" ] || continue
    n=$((n + 1)); [ "$first" = 0 ] && first="$ts"
    line=$(rg -m 1 "^$i\|" "$STASH_DIR/land-$bid" 2>/dev/null)
    if [ -n "$line" ]; then
      IFS='|' read -r _ st dur cost ldesc lout <<< "$line"
      back=$((back + 1))
      [ -n "$cost" ] && { sum=$(awk -v a="$sum" -v b="$cost" 'BEGIN{printf "%.2f", a+b}'); known=1; }
      [ -n "$lout" ] && outs+=("$lout")
      if [ "$st" = "missing" ]; then
        args+=(--row "blocked:$i" "$(printf '%-4s  %-6s  %s (no output written)' "$dur" "${cost:+\$$cost}" "$desc")")
      else
        args+=(--row "done:$i" "$(printf '%-4s  %-6s  %s' "$dur" "${cost:+\$$cost}" "$desc")")
      fi
    else
      args+=(--row "wait:$i" "$(printf '%-4s  %-6s  %s' "" "" "$desc")")
    fi
  done < "$STASH_DIR/burst"
  local el=$(( $(date +%s) - first )) name attr
  if [ "$el" -lt 60 ]; then el="${el}s"; else el="$((el / 60))m"; fi
  local spent=""
  [ "$known" = 1 ] && spent="\$$sum"
  if [ "$back" = "$n" ]; then name="all $n back"; attr="${spent:+$spent · }$el"
  else name="$back of $n back"; attr="${spent:+$spent so far · }$el"; fi
  # One folder when the seats wrote side by side, else each path.
  local copies=() dir common=1
  if [ ${#outs[@]} -gt 0 ]; then
    dir=$(dirname "${outs[0]}")
    for o in "${outs[@]}"; do [ "$(dirname "$o")" = "$dir" ] || common=0; done
    if [ "$common" = 1 ] && [ ${#outs[@]} -gt 1 ]; then copies+=(--copy "$dir/")
    else for o in "${outs[@]}"; do copies+=(--copy "$o"); done; fi
  fi
  bash "$BOXSH" fleet-in "$name" --attr "$attr" "${args[@]}" ${copies[@]+"${copies[@]}"} 2>/dev/null
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
m = re.match(r"\s*\[seat (s-[0-9a-z-]+)\][^\n]*", p)
seat = m.group(1) if m else "-"
o = re.search(r"\boutput=(\S+)", m.group(0)) if m else None
body = " ".join((p[m.end():] if m else p).split())
if len(body) > 170:
    body = body[:170].rsplit(" ", 1)[0].rstrip(",;:") + " …"
print(seat, o.group(1) if o else "-", body)' 2>/dev/null)
    [ "$seat" = "-" ] && seat=""; [ "$out" = "-" ] && out=""
    est=$(python3 "$COST" estimate "${model:-$typ}" 2>/dev/null)

    # Batch bookkeeping: a dispatch within BURST_GAP of the last one joins its batch.
    now=$(date +%s) bid="$now" idx=1
    if [ -s "$STASH_DIR/burst" ]; then
      IFS='|' read -r lts lbid lidx _ < <(tail -n 1 "$STASH_DIR/burst")
      if [ $(( now - lts )) -le "$BURST_GAP" ]; then bid="$lbid"; idx=$((lidx + 1)); fi
    fi
    printf '%s|%s|%s|%s|%s|%s\n' "$now" "$bid" "$idx" "${model:-inherit}" "$est" "${desc//|/ }" >> "$STASH_DIR/burst"
    printf '%s|%s|%s|%s|%s|%s\n' "${desc//|/ }" "$out" "$seat" "$bid" "$idx" "${model:-inherit}" >> "$STASH_DIR/dispatch-queue" 2>/dev/null || true

    if [ "$idx" -ge "$FLEET_MIN" ]; then
      box=$(fleet_out "$bid")
      msg="$box
This fleet box replaces the separate dispatch boxes for this batch: surface only the latest fleet box to the user (rules/surface-hook-nudges-to-user.md), then continue."
    else
      seatrow="${typ:-general-purpose}${name:+ as $name}"
      [ "$bg" = "true" ] && seatrow="$seatrow · background"
      [ -n "$seat" ] && seatrow="$seatrow · $seat"
      box=$(bash "$BOXSH" dispatch "${typ:-general-purpose}" --attr "${model:-inherit}${est:+ · ~\$$est}" \
        --row info:goal "${desc:+$desc: }$goal" --row info:seat "$seatrow" 2>/dev/null)
      msg="$box
Surface this box verbatim to the user (rules/surface-hook-nudges-to-user.md), then continue."
    fi
    # The whole box is owner text: a gcc-mods session draws it as a transcript
    # line and the model never reads it; any other session pastes it as before.
    emit_ctx "PreToolUse" "$(printf '%s' "$msg" | hook_owner_wrap log subagent-box)"
    ;;
  SubagentStart)
    aid=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
    typ=$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null)
    [ -n "$aid" ] || exit 0
    # Starts arrive in dispatch order, so the oldest queued dispatch is this
    # agent's: carry its description, output path and batch to the landing.
    q="$STASH_DIR/dispatch-queue" first=""
    if [ -s "$q" ]; then
      first=$(head -n 1 "$q"); tail -n +2 "$q" > "$q.tmp" 2>/dev/null && mv "$q.tmp" "$q"
    fi
    printf '%s|%s|%s\n' "${typ:-?}" "$(date +%s)" "$first" > "$STASH_DIR/$aid" 2>/dev/null || true
    ;;
  SubagentStop)
    aid=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
    typ=$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null)
    tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
    # The harness re-fires SubagentStop for a lingering agent every few seconds
    # (measured 2026-08-14: 14 fires for one probe); park one box per agent.
    if [ -n "$aid" ] && [ -f "$STASH_DIR/parked-$aid" ]; then exit 0; fi
    [ -n "$aid" ] && : > "$STASH_DIR/parked-$aid" 2>/dev/null
    # Stop-only strays: the harness runs an internal, unnamed agent roughly once
    # per user turn; only its Stop reaches hooks (bare-hex id, never a
    # SubagentStart, no dispatch of ours). Boxing each one trained the reader to
    # ignore landings, so an unmatched Stop goes to a ledger, never a box.
    if [ -n "$aid" ] && [ ! -f "$STASH_DIR/$aid" ]; then
      echo "$(date +%s)|$aid|${typ:-?}" >> "$STASH_DIR/unmatched.log" 2>/dev/null || true
      echo "$(date +%s)|SubagentStop-unmatched|$aid|rc0" >> "$STASH_DIR/fires.log" 2>/dev/null || true
      exit 0
    fi
    dur="?" ldesc="" lout="" bid="" idx=""
    if [ -n "$aid" ] && [ -f "$STASH_DIR/$aid" ]; then
      IFS='|' read -r _ started ldesc lout _ bid idx _ < "$STASH_DIR/$aid"
      if [ -n "$started" ]; then
        el=$(( $(date +%s) - started ))
        if [ "$el" -lt 60 ]; then dur="${el}s"; else dur="$(( el / 60 ))m"; fi
      fi
      rm -f "$STASH_DIR/$aid" 2>/dev/null || true
    fi
    # The seat's own transcript sits beside the session's, so what it cost is
    # read from there rather than estimated.
    cost=""
    at=$(printf '%s' "$input" | jq -r '.agent_transcript_path // empty' 2>/dev/null)
    [ -z "$at" ] && [ -n "$tp" ] && [ -n "$aid" ] && at="${tp%.jsonl}/subagents/agent-$aid.jsonl"
    [ -n "$at" ] && [ -f "$at" ] && cost=$(python3 "$COST" cost "$at" 2>/dev/null)
    st="none"
    if [ -n "$lout" ]; then if [ -s "$lout" ]; then st="written"; else st="missing"; fi; fi

    bsize=0
    [ -n "$bid" ] && bsize=$(rg -c "^[0-9]+\|$bid\|" "$STASH_DIR/burst" 2>/dev/null || echo 0)
    if [ "${bsize:-0}" -ge "$FLEET_MIN" ]; then
      printf '%s|%s|%s|%s|%s|%s\n' "$idx" "$st" "$dur" "$cost" "$ldesc" "$lout" >> "$STASH_DIR/land-$bid"
      # The latest fleet landing replaces the earlier one for the same batch.
      fleet_in "$bid" > "$STASH_DIR/pending-fleet-$bid" 2>/dev/null
      box=$(cat "$STASH_DIR/pending-fleet-$bid")
    else
      case "$st" in
        written) row=(--row done:goal "${ldesc:-$typ} · output written") ;;
        missing) row=(--row blocked:goal "${ldesc:-$typ} · output NOT written") ;;
        *)       row=(--row info:goal "${ldesc:-${typ:-?} · id ${aid:-?}}") ;;
      esac
      box=$(bash "$BOXSH" landing "${typ:-unknown}" --attr "ran $dur${cost:+ · \$$cost}" "${row[@]}" \
        ${lout:+--copy "$lout"} 2>/dev/null)
      [ -n "$box" ] || box=$(printf 'goal: %s\n' "$ldesc" | hook_box_kind landing "${typ:-unknown}" "ran $dur")
      printf '%s\n' "$box" >> "$STASH_DIR/pending-boxes" 2>/dev/null || true
    fi
    # SubagentStop context delivery is unrouted in this harness (verified
    # 2026-08-14: the box was emitted and never arrived). The parked box goes
    # out with the UserPromptSubmit drain below; the direct emit is insurance.
    emit_ctx "SubagentStop" "$(printf '%s\n' "$box" | hook_owner_wrap log subagent-box)"
    ;;
  UserPromptSubmit)
    boxes=''
    if [ -s "$STASH_DIR/pending-boxes" ]; then
      boxes=$(cat "$STASH_DIR/pending-boxes" 2>/dev/null); : > "$STASH_DIR/pending-boxes" 2>/dev/null || true
    fi
    for f in "$STASH_DIR"/pending-fleet-*; do
      [ -s "$f" ] || continue
      boxes="${boxes:+$boxes
}$(cat "$f")"
      rm -f "$f" 2>/dev/null || true
    done
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
