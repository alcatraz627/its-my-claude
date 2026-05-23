#!/usr/bin/env bash
# guidance.sh — neutral standing directives the user wants internalized.
#
# A third channel alongside atone (mistakes) and affirm (good calls): NEITHER a
# correction NOR a compliment — a steer on how to think/choose, written rarely
# when the user observes the agent's work. Read by the MAIN agent (relevance-
# gated, via the 06-guidance hinter) AND by every dispatch checker (juror,
# skeptical-review, future homework-checkers) via `guidance.sh show`.
#
# Usage:
#   guidance.sh add "<note>" ["<scope-keywords>"]   append a dated directive
#   guidance.sh show                                 print all directives
#   guidance.sh relevant "<prompt text>"             print directives relevant
#                                                    to this turn (the hinter)

set -uo pipefail
NOTES="$HOME/.claude/guidance/notes.md"
cmd="${1:-show}"

init_notes() {
  mkdir -p "$(dirname "$NOTES")"
  cat > "$NOTES" <<'HDR'
# Guidance — standing directives from the user

Neutral steers the user wants internalized — NOT mistakes (see atone) or
compliments (see affirm). Written rarely, when observing the agent's work.
Read by the main agent (relevance-gated via the 06-guidance hinter) and by
dispatch checkers (juror, skeptical-review, future homework-checkers) via
`bash ~/.claude/scripts/guidance.sh show`.

Format: `- YYYY-MM-DD [scope] the directive`
  `[all]` surfaces broadly; `[kw1, kw2]` surfaces when the prompt mentions a
  keyword (e.g. `[css, frontend]`). Add via `guidance.sh add` or just tell the
  agent "note this for the future: …".

<!-- notes below -->
HDR
}

case "$cmd" in
  add)
    note="${2:-}"; scope="${3:-all}"
    [ -n "$note" ] || { echo "usage: guidance.sh add \"<note>\" [\"<scope-keywords>\"]" >&2; exit 2; }
    mkdir -p "$(dirname "$NOTES")"
    [ -f "$NOTES" ] || init_notes
    printf -- '- %s [%s] %s\n' "$(date +%F)" "$scope" "$note" >> "$NOTES"
    echo "noted → $NOTES"
    ;;

  show)
    [ -f "$NOTES" ] && cat "$NOTES" || echo "(no guidance notes yet — add with: guidance.sh add \"...\")"
    ;;

  relevant)
    prompt=$(printf '%s' "${2:-}" | tr 'A-Z' 'a-z')
    [ -f "$NOTES" ] || exit 0
    while IFS= read -r line; do
      # Only top-level note lines: start with "- " and carry a [scope] tag.
      printf '%s' "$line" | rg -q '^- .*\[[^]]+\]' || continue
      tags=$(printf '%s' "$line" | sed -n 's/^- [^[]*\[\([^]]*\)\].*/\1/p' | tr 'A-Z' 'a-z' | tr ',' ' ')
      show=0
      for kw in $tags; do
        [ "$kw" = "all" ] && { show=1; break; }
        case "$prompt" in *"$kw"*) show=1; break ;; esac
      done
      [ "$show" = 1 ] && printf '%s\n' "$line"
    done < "$NOTES"
    ;;

  *) echo "usage: guidance.sh {add|show|relevant} ..." >&2; exit 2 ;;
esac
