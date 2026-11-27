#!/usr/bin/env bash
# ui-callouts-gate: a done-claim on a UI surface re-runs the owner's open
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
#   2. the final assistant message claims done-ness (a claim word that is not
#      negated, so "nothing here is verified yet" is not a claim)
#   3. an open row's surface name appears in the UI files edited this turn or in
#      a claim clause (a surface named only in the rest of the reply is not claimed)
# Then callouts.sh gate <surface> decides; unmet rows block ONCE per surface
# (loop-safe; a later claim on the same surfaces, or fewer, passes with a note).
# Everything else is silent.
# Mute: touch ~/.claude/.no-ui-callouts-gate (machine-wide until removed).
# Advice for a person reading the reply: see hook_should_run.
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null && { hook_should_run owner-turn || exit 0; }

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
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || exit 0
# The claim is the Stop input's last_assistant_message (the transcript tail lags one
# message at Stop time, see hook_last_assistant_text in hook-common.sh).
claim_text=$(hook_last_assistant_text "$input" "$tp")
[ -n "$claim_text" ] || exit 0

# A done-claim is a claim word that is not negated just before it. "Nothing here is
# verified yet" and "I didn't claim those surfaces fixed" say the opposite of done, so
# they must not trip the gate (the agent's own explanation used to re-fire it).
# Prints the clauses that may name a surface: each claim clause plus the clause right
# after it when that one does not disclaim. Prints nothing when the reply makes no
# done-claim.
read -r -d '' CLAIM_PY <<'PY'
import re, sys
text = sys.stdin.read()
CLAIM = re.compile(r"\b(done|fixed|complete|completed|ready|shipped|verified|works now|looks good)\b", re.I)
NEG = re.compile(r"\b(not|never|nothing|none|neither|nor|without)\b|n['\N{RIGHT SINGLE QUOTATION MARK}]t\b", re.I)
UNV = re.compile(r"\b(unverified|untested|unconfirmed|not yet)\b|still (?:open|unverified)|stays? open", re.I)
clauses = re.split(r"(?<=[.!?])\s+|\n+|;|\N{EM DASH}|\s+(?:but|however|though|although)\b[,\s]*", text)
kept, real, follow = [], False, False
for c in (c.strip() for c in clauses):
    if not c:
        continue
    claims = False
    for m in CLAIM.finditer(c):
        before = c[:m.start()].rsplit(",", 1)[-1].split()[-8:]
        if not NEG.search(" ".join(before)):
            claims = True
            break
    real = real or claims
    # The clause after a claim may carry its subject ("Done. The about page is updated."),
    # unless it disclaims. A surface named elsewhere in a long reply is not claimed.
    if claims or (follow and not (NEG.search(c) or UNV.search(c))):
        kept.append(c)
    follow = claims
if real:
    print("\n".join(kept))
PY
claim_clauses=$(printf '%s' "$claim_text" | python3 -c "$CLAIM_PY" 2>/dev/null)
[ -n "$claim_clauses" ] || exit 0

# UI files edited in THIS turn. The session-wide list above only finds the repo; read as
# "edited now" it made every later reply in a session look like a UI done-claim.
turn_ui_paths=$(printf '%s\n' "$turn_json" | jq -r 'select(.type=="assistant") | .message.content[]?
    | select(.type=="tool_use" and (.name=="Edit" or .name=="MultiEdit" or .name=="Write"))
    | .input.file_path // empty' 2>/dev/null \
  | rg -i '\.(tsx|jsx|css|scss|sass|less|vue|svelte|html)$|/(app|components|pages)/.*\.(ts|js)$' | sort -u)

# surfaces with open rows whose name appears in this turn's UI edits or the claim
surfaces=$(jq -r 'select(.status=="open") | .surface' "$store" 2>/dev/null | sort -u)
[ -n "$surfaces" ] || exit 0
matched=""
while IFS= read -r s; do
  [ -n "$s" ] || continue
  if printf '%s\n%s' "$turn_ui_paths" "$claim_clauses" | rg -qi -F -- "$s"; then matched="$matched $s"; fi
done <<< "$surfaces"
matched=$(printf '%s' "$matched" | tr ' ' '\n' | rg -v '^$' | sort -u)
[ -n "$matched" ] || exit 0

STATE="/tmp/claude-ui-callouts-gate-${sid8}"
sig=$(printf '%s' "$matched" | tr '\n' ',')
# STATE lists every surface already blocked on this session. A later claim that names only
# those surfaces (the same set, or fewer) passes: the owner was told once, and the agent
# narrowing its claim to some of them is the fix this gate asks for, not a new offence.
if [ -f "$STATE" ] && [ -z "$(printf '%s\n' "$matched" | rg -v -x -F -f "$STATE" 2>/dev/null)" ]; then
  note "ui-callouts-gate: open call-outs still unmet on: $sig: letting the Stop pass (block fires once per surface). The rows remain open until the owner retires them."
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
printf '%s\n' "$matched" >> "$STATE" 2>/dev/null || true
[ -x "$WARN" ] && bash "$WARN" --hook ui-callouts-gate --action block --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg r "ui-callouts-gate: this done-claim touches surfaces with OPEN owner call-outs that were not re-run:
$unmet
Re-run each row's check and record it (callouts.sh recheck <id> pass|fail --evidence \"...\"), or scope the claim to what was actually verified. Only the owner retires rows. This block fires once per surface set; mute: touch ~/.claude/.no-ui-callouts-gate" \
  '{decision:"block", reason:$r}'
exit 0
