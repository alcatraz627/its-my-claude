#!/usr/bin/env bash
# speculative-atone-hint.sh — UserPromptSubmit: the "MUST address" half of the
# residue review. Injects this session's unresolved speculative atones every turn
# until each is confirmed (real /atone filed and linked) or refuted (evidence
# logged). The repetition is the design: given a choice, an agent picks the easier
# path, so silence is removed from the menu (owner, 2026-08-20). After
# ESCALATE_AT injections with no resolution, its sibling Stop gate
# (speculative-atone-stop.sh) starts blocking turn-ends.
# Mute (owner only, machine-wide): touch ~/.claude/.no-spec-atone-hint
set -uo pipefail
[ -f "$HOME/.claude/.no-spec-atone-hint" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
SPEC="$HOME/.claude/scripts/atone-speculative.sh"
STORE="${SPEC_ATONE_STORE:-$HOME/.claude/atone/speculative.jsonl}"
[ -f "$STORE" ] || exit 0
ESCALATE_AT=5

INPUT=$(cat 2>/dev/null || echo "{}")
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$SID" ] || SID="${CLAUDE_CODE_SESSION_ID:-}"
[ -n "$SID" ] || exit 0
SID8="${SID:0:8}"

# Rows for this session. The auditor records the session's ipc alias; resolve this
# session's aliases from the registry, fall back to the sid8 prefix.
aliases=$(claude-ipc peers 2>/dev/null | jq -r --arg sid "$SID" \
  '.peers[] | select(.sessionId == $sid) | (.sessionAliases // [.alias])[]' 2>/dev/null | paste -sd'|' -)
match="${aliases:-claude-$SID8}"
pending=$(jq -r --arg m "$match" '
  select(.status == "pending") | select(.session | test("^(" + $m + ")$"))
  | " \(.id)  [\(.severity // "?")] \(.slug // "unslugged")  \(.issue[0:76])"' "$STORE" 2>/dev/null)
[ -z "$pending" ] && exit 0

CNT_DIR="$HOME/.claude/.turn-state"; mkdir -p "$CNT_DIR"
CNT_FILE="$CNT_DIR/spec-atone-nags-$SID8"
n=$(( $(cat "$CNT_FILE" 2>/dev/null || echo 0) + 1 )); printf '%s' "$n" > "$CNT_FILE"

# Two identical fires, then one line. The same ten-line box on four consecutive
# turns was ignored three times and the owner had to ask for it himself (ledger
# 10, sys-monitor 2026-09-07); five identical re-injections sat inside a live
# exchange about missing hardware (ledger 20). Repetition was the design, and it
# stays for the escalation count, but the SAME box a third time carries nothing
# the second did not. So: the full box while the pending set is new or changed,
# then one line naming the count and the ids until the set changes.
SIG_FILE="$CNT_DIR/spec-atone-sig-$SID8"
sig=$(printf '%s' "$pending" | shasum | cut -c1-12)
prev=$(cat "$SIG_FILE" 2>/dev/null || echo "")
prev_sig="${prev%% *}"; prev_cnt="${prev##* }"
case "$prev_cnt" in ''|*[!0-9]*) prev_cnt=0 ;; esac
if [ "$prev_sig" = "$sig" ]; then same=$((prev_cnt + 1)); else same=1; fi
printf '%s %s' "$sig" "$same" > "$SIG_FILE"

tone="unresolved speculative atones from the residue review; resolve each this session"
[ "$n" -ge "$ESCALATE_AT" ] && tone="IGNORED $n TURNS — the Stop gate is armed and blocks turn-ends once the owner has been quiet 30 minutes"
verbs="confirm = run /atone then \`atone-speculative.sh confirm <id> --atone <mist-id>\` · agree = \`atone-speculative.sh agree <id> --evidence \"<cited>\"\` (you accept it; the atone follows when idle) · refute = \`atone-speculative.sh refute <id> --evidence \"<cited>\"\`"

if [ "$same" -gt 2 ]; then
  ids=$(printf '%s\n' "$pending" | awk '{print $1}' | head -6 | paste -sd' ' -)
  cnt=$(printf '%s\n' "$pending" | rg -c . 2>/dev/null || echo 0)
  msg="🙏 atone · speculative: $cnt row(s) still pending after $same identical nags ($ids) · $tone · bash ~/.claude/scripts/atone-speculative.sh pending · $verbs"
else
  msg="┌─ 🙏 atone · speculative ─────────────────────── nag $n ──
$(printf '%s\n' "$pending" | head -12 | sed 's/^/│/')
│ → $tone: $verbs
└──────────────────────────────────────────────────────────────
Surface this box to the user (rules/surface-hook-nudges-to-user.md), then act on it."
fi

jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $c}}' 2>/dev/null || true
exit 0
