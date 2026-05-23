#!/usr/bin/env bash
# atone-unsafe-unlock.sh — ESCAPE HATCH. Clears kernel protection on raw atone
# data so a human operator can recover from corruption or run admin repair.
#
# Phrase-gated to prevent any agent from satisfying the prompt.
# Confirmation phrase is hard-coded literal text — no env override, no flag.
# Logs every unlock to ~/.claude/atone-snapshots/_unlock-log.txt (uappnd-flagged).

set -uo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/atone-common.sh"

PHRASE="I UNDERSTAND THIS REMOVES PROTECTION"
ATONE_DIR="$HOME/.claude/atone"
STORE="$ATONE_DIR/events.jsonl"
JUDGMENTS_LOG="$ATONE_DIR/judgments.jsonl"
RCA_DIR="$ATONE_DIR/rca"
UNLOCK_LOG="$HOME/.claude/atone-snapshots/_unlock-log.txt"

show_help() {
  printf '\n  %s%satone-unsafe-unlock%s %s—%s Clear kernel protection (escape hatch)\n' \
    "$C_BOLD" "$C_RED" "$C_RESET" "$C_DIM" "$C_RESET"

  _section "USAGE"
  _cmd 'atone-unsafe-unlock.sh [reason]'  'phrase-gated unlock'
  _cmd 'atone-unsafe-unlock.sh --help'    'this help'

  _section "WHAT IT DOES"
  _dim "Clears chflags uappnd from events.jsonl and chflags uchg from RCA files."
  _dim "After running, raw data CAN be deleted by accident. Re-lock immediately"
  _dim "with: bash ~/.claude/scripts/atone.sh lock"
  echo
  _dim "Every unlock is logged to: $UNLOCK_LOG"
  echo
}

case "${1:-}" in
  -h|--help|help) show_help; exit 0 ;;
esac

REASON="${1:-no-reason-given}"

gum_panel "DANGER — Remove raw-data protection" \
  "This clears append-only flags on:" \
  "  • ~/.claude/atone/events.jsonl  (uappnd)" \
  "  • ~/.claude/atone/rca/*.md       (uchg)" \
  "" \
  "After unlock, raw data CAN be deleted by accident. The action is logged." \
  "Re-lock immediately when done: bash ~/.claude/scripts/atone.sh lock"

echo
printf '%sType the confirmation phrase EXACTLY to continue:%s\n' "$C_BOLD" "$C_RESET"
printf '%s> %s' "$C_DIM" "$C_RESET"
read -r INPUT

if [ "$INPUT" != "$PHRASE" ]; then
  _err "Aborted — phrase did not match."
  exit 1
fi

# Unlock events.jsonl
if [ -f "$STORE" ]; then
  if chflags nouappnd "$STORE" 2>/dev/null; then
    _ok "uappnd cleared on events.jsonl"
  else
    _warn "uappnd already cleared on events.jsonl (or chflags failed)"
  fi
fi

# Unlock judgments.jsonl
if [ -f "$JUDGMENTS_LOG" ]; then
  if chflags nouappnd "$JUDGMENTS_LOG" 2>/dev/null; then
    _ok "uappnd cleared on judgments.jsonl"
  else
    _warn "uappnd already cleared on judgments.jsonl (or chflags failed)"
  fi
fi

# Unlock RCAs
count=0
if [ -d "$RCA_DIR" ]; then
  while IFS= read -r -d '' f; do
    chflags nouchg "$f" 2>/dev/null && count=$((count+1)) || true
    chmod 0644 "$f" 2>/dev/null || true
  done < <(find "$RCA_DIR" -type f -name '*.md' -print0)
fi
_ok "uchg cleared on $count RCA file(s)"

# Log the unlock (the log file itself stays uappnd so this append works
# but historical lines cannot be modified)
mkdir -p "$(dirname "$UNLOCK_LOG")"
printf '%s  reason=%q  user=%s\n' \
  "$(date -Iseconds)" "$REASON" "${USER:-?}" \
  >> "$UNLOCK_LOG"
chflags uappnd "$UNLOCK_LOG" 2>/dev/null || true

echo
_subhead "Next step"
_dim "Re-lock when done:  bash ~/.claude/scripts/atone.sh lock"
echo
