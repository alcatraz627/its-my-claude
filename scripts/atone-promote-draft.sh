#!/usr/bin/env bash
# atone-promote-draft.sh — Promotes ~/.claude/atone/events.jsonl.draft to
# ~/.claude/atone/events.jsonl as the final step of Stage 2 migration.
#
# Idempotent: refuses to overwrite an existing events.jsonl unless --force,
# and even with --force takes a timestamped backup first.
#
# Whitelisted by protect-atone-raw.sh (regex matches atone-promote-draft.sh).

set -uo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/atone-common.sh"

ATONE_DIR="$HOME/.claude/atone"
STORE="$ATONE_DIR/events.jsonl"
DRAFT="$ATONE_DIR/events.jsonl.draft"

show_help() {
  printf '\n  %s%satone-promote-draft%s %s—%s Migration step: draft → events.jsonl\n' \
    "$C_BOLD" "$C_MAGENTA" "$C_RESET" "$C_DIM" "$C_RESET"

  _section "USAGE"
  _cmd 'atone-promote-draft.sh'           'promote (refuses if events.jsonl non-empty)'
  _cmd 'atone-promote-draft.sh --force'   'overwrite (backup taken first)'
  _cmd 'atone-promote-draft.sh --help'    'this help'

  _section "WHAT IT DOES"
  _dim "1. validates draft is well-formed JSONL"
  _dim "2. backs up current events.jsonl to events.jsonl.pre-promote.bak.<ts>"
  _dim "3. mv events.jsonl.draft → events.jsonl"
  _dim "4. git add + commit"
  _dim "5. does NOT apply chflags — run 'atone.sh lock' after verifying"
  echo
}

FORCE=0
case "${1:-}" in
  -h|--help|help) show_help; exit 0 ;;
  --force)        FORCE=1 ;;
  '') ;;
  *) _err "unknown flag: $1"; show_help; exit 2 ;;
esac

[ -f "$DRAFT" ] || _die "no draft at $DRAFT — run the migration parser first"

# Validate JSONL
if ! python3 -c "
import json, sys
for i, l in enumerate(open('$DRAFT'), 1):
    if l.strip():
        try: json.loads(l)
        except Exception as e: print(f'line {i}: {e}'); sys.exit(1)
" >&2; then
  _die "draft has invalid JSONL — fix before promoting"
fi

LINES=$(wc -l < "$DRAFT" | tr -d ' ')
_ok "draft validated — $LINES events ready to promote"

if [ -s "$STORE" ]; then
  EXISTING=$(wc -l < "$STORE" | tr -d ' ')
  if [ "$FORCE" = "0" ]; then
    _warn "events.jsonl already has $EXISTING line(s)"
    _dim "Re-run with --force to overwrite (a backup will be saved)."
    exit 3
  fi
  BAK="$ATONE_DIR/events.jsonl.pre-promote.bak.$(date +%s)"
  cp "$STORE" "$BAK"
  _ok "existing events.jsonl backed up to ${BAK##*/}"
fi

mv "$DRAFT" "$STORE"
_ok "draft → events.jsonl ($LINES lines)"

cd "$ATONE_DIR" || _die "cannot cd to $ATONE_DIR"
git add events.jsonl 2>/dev/null || true
if git diff --cached --quiet 2>/dev/null; then
  _info "(no git changes to commit)"
else
  git commit -q -m "atone: migrate v1 mistake-patterns.md → events.jsonl ($LINES events)"
  _ok "committed: $(git log -1 --oneline)"
fi

echo
_subhead "Verify the migrated data"
_dim "bash ~/.claude/scripts/atone.sh list | head -20"
_dim "bash ~/.claude/scripts/atone.sh slugs"
echo
_subhead "When ready, apply the kernel-level lock"
_dim "bash ~/.claude/scripts/atone.sh lock"
echo
