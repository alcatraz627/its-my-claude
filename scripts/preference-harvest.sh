#!/usr/bin/env bash
# preference-harvest.sh — surface CANDIDATE user-preference / vocabulary signals
# from the post-insight streams (atone, affirm, i-dream, runtime-notes, checkpoints)
# for HUMAN review. It NEVER writes to GLOSSARY / memory / rules — those require
# judgment (see conventions/preference-graduation.md). Output is a dated candidate
# list the human triages via the manual graduation pass.
#
# Usage: preference-harvest.sh [--days N] [--out PATH]
#   --days N   look-back window for time-filtered streams (default 30)
#   --out P    candidate file (default ~/.claude/topics/preference-candidates-YYYY-MM-DD.md)
set -o pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
DAYS=30
DATE="$(date +%F)"
OUT="$CLAUDE_DIR/topics/preference-candidates-$DATE.md"

while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS="$2"; shift 2 ;;
    --out)  OUT="$2"; shift 2 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
mkdir -p "$(dirname "$OUT")"

# Preference-signal language: "how I work" cues, not task content.
PAT="prefer|always |never |i (want|like|hate|love|prefer)|don't (want|like)|one-shot|just use chatgpt|efficacy|workflow|bake (this|it) in|how i work|my preference|reserve .* for|route .* to|too (slow|verbose|much)"

have() { command -v "$1" >/dev/null 2>&1; }
emit() { printf '%s\n' "$1" >> "$OUT"; }

: > "$OUT"
emit "# Preference candidates — $DATE"
emit ""
emit "> Auto-surfaced by \`scripts/preference-harvest.sh\` from the post-insight streams"
emit "> for **human review**. Nothing here is baked yet — triage real signals into"
emit "> GLOSSARY / memory / rules per \`conventions/preference-graduation.md\`."
emit "> (Already-baked terms — efficacy, one-shotting, work-routing triad — will recur"
emit "> here; ignore those.)"
emit ""

scan_jsonl() {  # $1 path  $2 label  $3 jq-text-expr
  local f="$1" label="$2" expr="$3" hits
  [ -f "$f" ] || return 0
  have jq || { emit "_(jq missing — skipped $label)_"; return 0; }
  hits="$(jq -r "$expr" "$f" 2>/dev/null | rg -iN "$PAT" 2>/dev/null | tail -40)"
  [ -n "$hits" ] || return 0
  emit "## $label"; emit ""
  printf '%s\n' "$hits" | while IFS= read -r l; do emit "- ${l:0:200}"; done
  emit ""
}

scan_text() {  # $1 label  shift; remaining = files/globs
  local label="$1"; shift
  local hits
  hits="$(rg -iN --no-filename "$PAT" "$@" 2>/dev/null | tail -40)"
  [ -n "$hits" ] || return 0
  emit "## $label"; emit ""
  printf '%s\n' "$hits" | while IFS= read -r l; do emit "- ${l:0:200}"; done
  emit ""
}

scan_jsonl "$CLAUDE_DIR/atone/events.jsonl"  "atone events (corrections)"   '.issue // .what_not_to_do // empty'
scan_jsonl "$CLAUDE_DIR/affirm/events.jsonl" "affirm events (good calls)"   '.what // .insight // .note // empty'

# i-dream surfaced insights + recent runtime-notes (preference-flavoured lines).
[ -d "$CLAUDE_DIR/subconscious/dreams" ] && \
  scan_text "i-dream insights" $(find "$CLAUDE_DIR/subconscious/dreams" -type f -name '*.md' -mtime "-$DAYS" 2>/dev/null)
scan_text "runtime-notes (recent)" $(find "$CLAUDE_DIR"/projects -type f -name 'runtime-notes.md' -mtime "-$DAYS" 2>/dev/null)

# If nothing matched, say so explicitly (honest empty result, not a silent pass).
if [ "$(wc -l < "$OUT")" -le 8 ]; then
  emit "_No preference candidates surfaced in the last $DAYS days._"
fi

echo "$OUT"
