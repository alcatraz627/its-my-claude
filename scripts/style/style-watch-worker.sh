#!/usr/bin/env bash
# style-watch-worker.sh — detached judgment half of the style watcher.
#
# For each candidate file: resolve its enforcement tier (approximating
# style/scope-map.json — that file stays authoritative for the critic persona),
# run the free tier-0 screen (regex tells / comment detector), and only on a
# positive screen spend the tier-2 sonnet judgment, which may cite ONLY active
# thesaurus entry ids — the watcher enforces the user's ledger, never its own
# taste. Verdicts land in style/pending-watch-notes.txt for next-turn
# injection; every fire/skip is telemetry in logs/style-watch.jsonl (tokens +
# instances — the user's explicit ask).
#
# args: <sid8> <cwd> <batch-file with one path per line>
# env:  STYLE_WATCH_FAKE_JUDGE=1  — skip the LLM, emit a canned finding (tests)
#       STYLE_WATCH_TIER2_CAP=N  — max sonnet calls per run (default 1)
set -uo pipefail

SID8="${1:-}"; CWD="${2:-}"; BATCH="${3:-}"
[ -n "$SID8" ] && [ -f "$BATCH" ] || exit 0

STYLE_DIR="$HOME/.claude/style"
PROCESSED="$STYLE_DIR/.watch-processed-$SID8"
NOTES="$STYLE_DIR/pending-watch-notes.txt"
LOGGER="$HOME/.claude/scripts/style/style-log.sh"
DETECT="$HOME/.claude/skills/cleanup-comments/detect.py"
TIER2_CAP="${STYLE_WATCH_TIER2_CAP:-1}"
tier2_used=0
TOKENS_FILE=$(mktemp); echo 0 > "$TOKENS_FILE"
trap 'rm -f "$TOKENS_FILE"' EXIT

mark() { echo "$1:$(shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1)" >> "$PROCESSED"; }
note() { printf '%s|%s|%s\n' "$(date -u +%s)" "$CWD" "$1" >> "$NOTES"; }

tier_for() {
  case "$1" in
    "$HOME"/Code/Versable/*) echo heavy ;;
    */README*.md|*/USAGE*.md|*/MIGRATION*.md|*/GUIDEBOOK*.md) echo heavy ;;
    *.ts|*.tsx|*.js|*.jsx|*.py|*.sh) echo comment-minimal ;;
    "$HOME"/.claude/*|"$HOME"/Code/Claude/*) echo off ;;   # claude-owned (doc names caught above)
    */docs/*) echo medium ;;
    *) echo medium ;;
  esac
}

screen0() {  # tier-0 free screen; exit 0 = hits found
  local f="$1" tier="$2"
  if [ "$tier" = "comment-minimal" ]; then
    [ -f "$DETECT" ] && python3 "$DETECT" "$f" 2>/dev/null | jq -e '.totals // {} | (add? // 0) > 0' >/dev/null 2>&1
  else
    rg -q "—|·  |it's worth noting|not just | simply | essentially | basically |You're absolutely right" "$f" 2>/dev/null
  fi
}

judge() {  # tier-2 sonnet; prints findings lines "entry-id|quote|rewrite" (may be empty)
  local f="$1" tier="$2" digestfile digest
  case "$tier" in comment-minimal) digestfile="$STYLE_DIR/derived/comment.md" ;; *) digestfile="$STYLE_DIR/derived/prose.md" ;; esac
  if [ "${STYLE_WATCH_FAKE_JUDGE:-0}" = "1" ]; then
    echo "thes-fake-0000|canned test finding|canned rewrite"
    return 0
  fi
  [ "$tier2_used" -ge "$TIER2_CAP" ] && return 1
  tier2_used=$((tier2_used + 1))
  command -v claude >/dev/null 2>&1 || return 1
  digest=$(cat "$digestfile" 2>/dev/null); [ -n "$digest" ] || return 1
  # JSON output so token spend lands in telemetry (the user's explicit ask).
  local raw
  raw=$(head -c 12000 "$f" | claude -p --model sonnet --output-format json \
    "You enforce a style ledger on the file content on stdin (tier: $tier). Ledger (the ONLY rules you may enforce):
$digest
Output at most 3 lines, each exactly: <entry-id>|<short offending quote>|<one-line rewrite>
Output nothing at all if the content violates no ledger entry. No prose, no explanation." 2>/dev/null)
  # claude -p json output is an EVENT ARRAY; the result object is the last
  # {"type":"result"} element (verified 2026-07-16 against the live CLI).
  printf '%s' "$raw" | jq -r '(if type=="array" then (map(select(.type=="result")) | last) else . end)
    | .usage // {} | ((.input_tokens // 0) + (.output_tokens // 0)
    + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))' \
    > "$TOKENS_FILE" 2>/dev/null || echo 0 > "$TOKENS_FILE"
  printf '%s' "$raw" | jq -r '(if type=="array" then (map(select(.type=="result")) | last) else . end)
    | .result // empty' 2>/dev/null | rg '^thes-' | head -3
}

count=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  count=$((count + 1)); [ "$count" -gt 3 ] && break
  tier=$(tier_for "$f")
  if [ "$tier" = "off" ]; then
    bash "$LOGGER" --kind watcher-skip --surface "off" --artifact "$f" >/dev/null 2>&1
    mark "$f"; continue
  fi
  if ! screen0 "$f" "$tier"; then
    bash "$LOGGER" --kind watcher-skip --surface "$tier/screen-clean" --artifact "$f" >/dev/null 2>&1
    mark "$f"; continue
  fi
  findings=$(judge "$f" "$tier" || true)
  n=$(printf '%s' "$findings" | rg -c '^thes-' 2>/dev/null || echo 0)
  if [ "$n" -gt 0 ]; then
    top=$(printf '%s\n' "$findings" | head -1)
    id="${top%%|*}"
    note "[style-watch] ${f##*/}: $n ledger finding(s) at tier $tier; top: $top — act or dismiss, then log heed: bash ~/.claude/scripts/style/style-log.sh --kind watcher-fire --entry $id --heeded yes|no"
    bash "$LOGGER" --kind watcher-fire --surface "$tier" --artifact "$f" --model sonnet --findings "$n" --entry "$id" --tokens "$(cat "$TOKENS_FILE" 2>/dev/null || echo 0)" >/dev/null 2>&1
    [ "${id}" != "thes-fake-0000" ] && bash "$HOME/.claude/scripts/style/thesaurus.sh" hit "$id" >/dev/null 2>&1
  else
    bash "$LOGGER" --kind watcher-skip --surface "$tier/judge-clean" --artifact "$f" >/dev/null 2>&1
  fi
  mark "$f"
done < "$BATCH"
rm -f "$BATCH" 2>/dev/null || true
