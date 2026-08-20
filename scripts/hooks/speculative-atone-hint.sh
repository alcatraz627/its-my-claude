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

tone="unresolved speculative atones from the residue review; resolve each this session"
[ "$n" -ge "$ESCALATE_AT" ] && tone="IGNORED $n TURNS — the Stop gate is now armed; turn-ends will block until these are resolved"

msg="┌─ 🙏 atone · speculative ─────────────────────── nag $n ──
$(printf '%s\n' "$pending" | head -12 | sed 's/^/│/')
│ → $tone: confirm = run /atone then \`atone-speculative.sh confirm <id> --atone <mist-id>\` · refute = \`atone-speculative.sh refute <id> --evidence \"<cited>\"\`
└──────────────────────────────────────────────────────────────
Surface this box to the user (rules/surface-hook-nudges-to-user.md), then act on it."

jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $c}}' 2>/dev/null || true
exit 0
