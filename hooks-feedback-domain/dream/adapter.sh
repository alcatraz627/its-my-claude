#!/usr/bin/env bash
# adapter.sh — claude-audit domain return channel (i-dream contract §5).
#
# i-dream pipes the DreamOutput JSON to stdin after each dream pass. We turn
# actionable insights into proposals in the shared backlog:
#   decay_candidate      -> TUNE/PRUNE proposal (action ∈ tune|downgrade|remove)
#   graduation_candidate -> strengthen-hook proposal
# Idempotent: a dedupe key per (type, slug, action) is recorded so re-runs skip.
# Best-effort: i-dream records insights.jsonl regardless; failures here are swallowed.

set -uo pipefail
PROPOSE="$HOME/.claude/scripts/propose.sh"
SEEN="$HOME/.claude/hooks-feedback-domain/dream/.adapter-seen"
mkdir -p "$(dirname "$SEEN")"; touch "$SEEN" 2>/dev/null || true

INPUT=$(cat 2>/dev/null || echo "{}")

# Python parses DreamOutput → TSV (key \t title \t body) per actionable insight.
ACTIONS=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
rows = []
for ins in (d.get("insights") or []):
    t = ins.get("type")
    if t == "decay_candidate":
        slug = ins.get("slug","?"); action = ins.get("action","tune"); why = ins.get("rationale","")
        rows.append((f"decay::{slug}::{action}",
                     f"[hook-feedback] {action.upper()} hook \x27{slug}\x27 (dream-derived)",
                     f"i-dream claude-audit dream-pass flagged \x27{slug}\x27 as decay_candidate (action={action}). Rationale: {why}"))
    elif t == "graduation_candidate":
        slug = ins.get("slug","?"); tgt = ins.get("target",""); why = ins.get("rationale","")
        rows.append((f"grad::{slug}",
                     f"[hook-feedback] strengthen hook \x27{slug}\x27 (dream-derived)",
                     f"dream-pass graduation_candidate for \x27{slug}\x27 (target={tgt}). Rationale: {why}"))
for key, title, body in rows:
    clean = lambda x: x.replace("\t"," ").replace("\n"," ")
    print("\t".join(clean(x) for x in (key, title, body)))
' 2>/dev/null || true)

[ -z "$ACTIONS" ] && exit 0

filed=0
while IFS=$'\t' read -r key title body; do
  [ -n "$key" ] || continue
  grep -qxF "$key" "$SEEN" 2>/dev/null && continue   # idempotent: exact-line match (a key must not substring-match another)
  if [ -x "$PROPOSE" ]; then
    if bash "$PROPOSE" add --title "$title" --body "$body" \
         --category hooks --effort small --tags "hook-feedback dream-derived" >/dev/null 2>&1; then
      echo "$key" >> "$SEEN"
      filed=$((filed+1))
    fi
  fi
done <<< "$ACTIONS"

echo "adapter: filed $filed proposal(s) from DreamOutput"
