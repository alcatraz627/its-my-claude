#!/usr/bin/env bash
# ui-callouts-gate — a done-claim on a UI surface re-runs the owner's open
# call-outs first, or the Stop is refused once.
#
# The owner's review findings live in <repo>/.claude/callouts.jsonl with a
# re-runnable check per row (callouts.sh). Advisory routing measured 1-28%
# heed on this account; Stop-tier gates measure 85-100% (adversarial-review
# 2026-08-30, §S1-2), so this is a Stop hook in declared-ready-stop.sh's
# shape. Ruled by the owner 2026-08-31 ("1a").
#
# Fires ONLY when all three hold this turn:
#   1. a UI file was edited inside a repo that has .claude/callouts.jsonl
#   2. the final assistant message claims done-ness
#   3. an open row's surface name appears in the edited paths or the claim
# Then callouts.sh gate <surface> decides; unmet rows block ONCE (loop-safe;
# the second Stop passes with a note). Everything else is silent.
# Mute: touch ~/.claude/.no-ui-callouts-gate (machine-wide until removed).
set -uo pipefail
[ -f "$HOME/.claude/.no-ui-callouts-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"
WARN="$HOME/.claude/scripts/hooks/warn-log.sh"
note() { # soft systemMessage, telemetry, exit 0
  jq -cn --arg m "$1" '{systemMessage:$m}' 2>/dev/null || true
  [ -x "$WARN" ] && bash "$WARN" --hook ui-callouts-gate --action soft --heeded unknown >/dev/null 2>&1 || true
  exit 0
}

EDITED="/tmp/claude-edited-files-${sid8}"
[ -s "$EDITED" ] || exit 0
ui_paths=$(rg -i '\.(tsx|jsx|css|scss|sass|less|vue|svelte|html)$|/(app|components|pages)/.*\.(ts|js)$' "$EDITED" 2>/dev/null | sort -u)
[ -n "$ui_paths" ] || exit 0

# nearest ancestor holding a callouts store; first hit wins
store=""; root=""
while IFS= read -r p; do
  d=$(dirname "$p")
  for _ in 1 2 3 4 5 6 7 8; do
    if [ -f "$d/.claude/callouts.jsonl" ]; then store="$d/.claude/callouts.jsonl"; root="$d"; break 2; fi
    [ "$d" = "/" ] && break
    d=$(dirname "$d")
  done
done <<< "$ui_paths"
[ -n "$store" ] || exit 0

# final assistant text of this turn (declared-ready's boundary logic, condensed)
window=$(tail -n 1200 "$tp" 2>/dev/null); [ -n "$window" ] || exit 0
boundary=$(printf '%s\n' "$window" | jq -rc '
  select(.type=="user"
    and ( (.message.content|type=="string" and (.|length>0))
       or (.message.content|type=="array" and (any(.[]?; .type=="text"))) ))
  | input_line_number' 2>/dev/null | tail -n 1)
turn_json="$window"; [ -n "$boundary" ] && turn_json=$(printf '%s\n' "$window" | tail -n +"$boundary")
claim_text=$(printf '%s\n' "$turn_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -n 1 \
  | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$claim_text" ] || exit 0
printf '%s' "$claim_text" | rg -qi '\b(done|fixed|complete|completed|ready|shipped|verified|works now|looks good)\b' || exit 0

# surfaces with open rows whose name appears in the edits or the claim
surfaces=$(jq -r 'select(.status=="open") | .surface' "$store" 2>/dev/null | sort -u)
[ -n "$surfaces" ] || exit 0
matched=""
while IFS= read -r s; do
  [ -n "$s" ] || continue
  if printf '%s\n%s' "$ui_paths" "$claim_text" | rg -qi -F -- "$s"; then matched="$matched $s"; fi
done <<< "$surfaces"
matched=$(printf '%s' "$matched" | tr ' ' '\n' | rg -v '^$' | sort -u)
[ -n "$matched" ] || exit 0

STATE="/tmp/claude-ui-callouts-gate-${sid8}"
sig=$(printf '%s' "$matched" | tr '\n' ',')
if [ -f "$STATE" ] && [ "$(cat "$STATE" 2>/dev/null)" = "$sig" ]; then
  note "ui-callouts-gate: open call-outs still unmet on: $sig — letting the Stop pass (block fires once). The rows remain open until the owner retires them."
fi

CALLOUTS="$HOME/.claude/scripts/callouts/callouts.sh"
[ -x "$CALLOUTS" ] || exit 0
unmet=""
while IFS= read -r s; do
  out=$(cd "$root" && bash "$CALLOUTS" gate "$s" 2>/dev/null)
  rc=$?
  [ "$rc" -ne 0 ] && unmet="$unmet
── surface '$s' ──
$out"
done <<< "$matched"

if [ -z "$unmet" ]; then
  # warn-log's action vocabulary is block|soft|nudge|muted; a clean gate is a
  # heeded soft so the weekly fires-vs-passes measure can read both sides.
  [ -x "$WARN" ] && bash "$WARN" --hook ui-callouts-gate --action soft --heeded true >/dev/null 2>&1 || true
  exit 0
fi
printf '%s' "$sig" > "$STATE" 2>/dev/null || true
[ -x "$WARN" ] && bash "$WARN" --hook ui-callouts-gate --action block --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg r "ui-callouts-gate: this done-claim touches surfaces with OPEN owner call-outs that were not re-run:
$unmet
Re-run each row's check and record it (callouts.sh recheck <id> pass|fail --evidence \"...\"), or scope the claim to what was actually verified. Only the owner retires rows. This block fires once per surface set; mute: touch ~/.claude/.no-ui-callouts-gate" \
  '{decision:"block", reason:$r}'
exit 0
