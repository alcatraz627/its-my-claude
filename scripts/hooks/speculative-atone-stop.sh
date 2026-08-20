#!/usr/bin/env bash
# speculative-atone-stop.sh — Stop: the escalation rung under the speculative-atone
# hinter. After the hinter has nagged ESCALATE_AT times with rows still pending for
# this session, a turn may no longer end silently: this blocks once per turn-count
# with the unresolved rows, until each is confirmed or refuted. Loop-safe the same
# way declared-ready-stop is: one block per nag-count value, so a session that
# genuinely cannot resolve (broker down, store gone) is slowed, never wedged.
# Mute (owner only, machine-wide): touch ~/.claude/.no-spec-atone-gate
set -uo pipefail
[ -f "$HOME/.claude/.no-spec-atone-gate" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
STORE="${SPEC_ATONE_STORE:-$HOME/.claude/atone/speculative.jsonl}"
[ -f "$STORE" ] || exit 0
ESCALATE_AT=5

INPUT=$(cat 2>/dev/null || echo "{}")
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$SID" ] || SID="${CLAUDE_CODE_SESSION_ID:-}"
[ -n "$SID" ] || exit 0
SID8="${SID:0:8}"

CNT_FILE="$HOME/.claude/.turn-state/spec-atone-nags-$SID8"
n=$(cat "$CNT_FILE" 2>/dev/null || echo 0)
[ "$n" -ge "$ESCALATE_AT" ] || exit 0

aliases=$(claude-ipc peers 2>/dev/null | jq -r --arg sid "$SID" \
  '.peers[] | select(.sessionId == $sid) | (.sessionAliases // [.alias])[]' 2>/dev/null | paste -sd'|' -)
match="${aliases:-claude-$SID8}"
pending=$(jq -r --arg m "$match" '
  select(.status == "pending") | select(.session | test("^(" + $m + ")$"))
  | "  \(.id)  \(.slug // "unslugged")"' "$STORE" 2>/dev/null)
[ -z "$pending" ] && exit 0

# One block per nag level: if we already blocked at this count, step aside.
MARK="$HOME/.claude/.turn-state/spec-atone-blocked-$SID8"
[ "$(cat "$MARK" 2>/dev/null || echo -1)" = "$n" ] && exit 0
printf '%s' "$n" > "$MARK"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook speculative-atone-stop --action block --heeded unknown >/dev/null 2>&1 || true

reason="Speculative atones ignored for $n turns; resolve before ending the turn (owner design: silence is not an option):
$pending
Each: confirm (run /atone, then \`bash ~/.claude/scripts/atone-speculative.sh confirm <id> --atone <mist-id>\`) or refute (\`... refute <id> --evidence \"<cited, 40+ chars>\"\`)."
jq -n --arg r "$reason" '{decision: "block", reason: $r}' 2>/dev/null || true
exit 0
