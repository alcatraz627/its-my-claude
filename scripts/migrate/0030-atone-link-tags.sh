#!/usr/bin/env bash
# 0030 — give atone-graduated proposals a real provenance edge.
#
# Proposals filed by atone-consolidate carried a bare `atone-prevention <target>
# <slug>` tag. The backlog consolidator builds its corroboration graph from
# `link:*` tags ONLY (backlog-consolidate.py:127), so those proposals could never
# corroborate — not even with the gcc-signal-capture auto-stub naming the same
# slug — and aged out into DROP-REVIEW as "stale, no corroboration".
#
# This rewrites them in place to the protocol shape:
#   atone-prevention <target> <slug>
#     -> link:atone:<slug>  src:atone-graduation  target:<target>
#
# It also re-opens the atone-graduated proposals that were rejected on 2026-07-11
# for a corroboration they were structurally incapable of earning, EXCEPT those
# whose rejection reason says "Superseded" (those were judged on their merits and
# stay closed).
#
#   --dry-run   show what would change, write nothing (default)
#   --apply     write it
set -uo pipefail

STORE="${PROPOSE_STORE:-$HOME/.claude/proposals.jsonl}"
MODE="dry-run"
case "${1:-}" in
  --apply)   MODE="apply" ;;
  --dry-run|"") MODE="dry-run" ;;
  *) echo "0030: unknown flag '$1' (valid: --dry-run, --apply)" >&2; exit 2 ;;
esac

[ -s "$STORE" ] || { echo "0030: no store at $STORE" >&2; exit 1; }

# The transform, as one jq program. `target:` keeps the placement hint that the
# old tag's middle field carried (hook-draft / claude-md-rule / rules-entry).
JQ_PROG='
def atone_slug: (.tags // []) as $t
  | ($t | index("atone-prevention")) as $has
  | if $has == null then null
    else ($t | map(select(. != "atone-prevention"))) as $rest
      | ($rest | map(select(. == "hook-draft" or . == "claude-md-rule" or . == "rules-entry"))) as $tg
      | ($rest | map(select(. != "hook-draft" and . != "claude-md-rule" and . != "rules-entry"))) as $slugs
      | { slug: ($slugs | first), target: ($tg | first // "unknown") }
    end;

if (.tags // []) | index("atone-prevention") then
  atone_slug as $a
  | if $a.slug == null then .
    else
      .tags = (["link:atone:\($a.slug)", "src:atone-graduation", "target:\($a.target)"])
      # Re-open a rejection that was only ever about un-earnable corroboration.
      | if (.status == "rejected"
            and ((.reason // "") | test("Superseded"; "i") | not)
            and ((.reason // "") | test("Stale|corroboration"; "i")))
        then .status = "open"
           | .reason = "reopened by migration 0030: rejected 2026-07-11 for a corroboration this proposal could not structurally earn (no link: tag); re-tagged and returned to the gate"
        else . end
    end
else . end
'

changed=$(jq -c "select((.tags // []) | index(\"atone-prevention\"))" "$STORE" | wc -l | tr -d ' ')
reopened=$(jq -c "select((.tags // []) | index(\"atone-prevention\")) | select(.status==\"rejected\") | select(((.reason // \"\") | test(\"Superseded\";\"i\")) | not) | select((.reason // \"\") | test(\"Stale|corroboration\";\"i\"))" "$STORE" | wc -l | tr -d ' ')

echo "0030 [$MODE]"
echo "  store:        $STORE"
echo "  re-tagged:    $changed proposals (atone-prevention -> link:atone:<slug>)"
echo "  re-opened:    $reopened rejected-for-uncorroboration proposals"

if [ "$MODE" = "dry-run" ]; then
  echo
  echo "  sample (first 3, after transform):"
  jq -c "select((.tags // []) | index(\"atone-prevention\")) | $JQ_PROG | {id, status, tags}" "$STORE" 2>/dev/null | head -3 | sed 's/^/    /'
  echo
  echo "  re-run with --apply to write."
  exit 0
fi

BAK="$HOME/.claude/assets/backups/proposals-pre-0030-$(date -u +%Y%m%dT%H%M%SZ).jsonl"
mkdir -p "$(dirname "$BAK")"
cp "$STORE" "$BAK"
echo "  backup:       $BAK"

TMP=$(mktemp "${STORE}.XXXXXX")
if jq -c "$JQ_PROG" "$STORE" > "$TMP" && [ -s "$TMP" ]; then
  # Never shrink the store: a transform that loses lines is a bug, not a migration.
  before=$(wc -l < "$STORE" | tr -d ' '); after=$(wc -l < "$TMP" | tr -d ' ')
  if [ "$before" != "$after" ]; then
    echo "  ABORT: line count changed ($before -> $after); store untouched." >&2
    rm -f "$TMP"; exit 1
  fi
  mv "$TMP" "$STORE"
  echo "  applied. $after lines intact."
else
  echo "  ABORT: jq transform failed; store untouched." >&2
  rm -f "$TMP"; exit 1
fi
