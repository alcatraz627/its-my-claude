#!/usr/bin/env bash
# guidance.sh: neutral standing directives the user wants internalized.
#
# A third channel alongside atone (mistakes) and affirm (good calls): NEITHER a
# correction NOR a compliment: a steer on how to think/choose, written rarely
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
NOTES="${GUIDANCE_NOTES:-$HOME/.claude/guidance/notes.md}"
cmd="${1:-show}"

# Does a note's scope list apply to this prompt? Scopes are comma separated and
# each one is matched whole: "port" is not found inside "report", and a phrase
# such as "next dev" must appear as that phrase, not as "next" or "dev" alone.
# Punctuation and hyphens count as word edges; letters, digits and "_" do not.
# `all` always applies. Case is ignored. Args: prompt, comma-separated scope list.
scope_matches() {
  local text kw esc
  text=" $(printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -s '[:space:]' ' ') "
  local IFS=','
  for kw in $(printf '%s' "$2" | tr 'A-Z' 'a-z'); do
    kw="${kw#"${kw%%[![:space:]]*}"}"; kw="${kw%"${kw##*[![:space:]]}"}"
    [ -n "$kw" ] || continue
    [ "$kw" = "all" ] && return 0
    esc=$(printf '%s' "$kw" | sed 's/[][\.*^$+?(){}|/]/\\&/g')
    [[ "$text" =~ (^|[^a-z0-9_])${esc}($|[^a-z0-9_]) ]] && return 0
  done
  return 1
}
[ "${GUIDANCE_SOURCE_ONLY:-}" = 1 ] && return 0

init_notes() {
  mkdir -p "$(dirname "$NOTES")"
  cat > "$NOTES" <<'HDR'
# Guidance: standing directives from the user

Neutral steers the user wants internalized: NOT mistakes (see atone) or
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
    # A note that IS a flag means the caller invented a syntax this tool doesn't
    # have (e.g. --scope): the real directive would be silently dropped. Two
    # entries were lost exactly this way (2026-06-25, 2026-07-10) pre-guard.
    case "$note" in
      --*) echo "guidance add: note looks like a flag ('$note'): args are POSITIONAL: guidance.sh add \"<note>\" [\"<scope-keywords>\"]" >&2; exit 2 ;;
    esac
    mkdir -p "$(dirname "$NOTES")"
    [ -f "$NOTES" ] || init_notes
    printf -- '- %s [%s] %s\n' "$(date +%F)" "$scope" "$note" >> "$NOTES"
    echo "noted → $NOTES"
    ;;

  show)
    [ -f "$NOTES" ] && cat "$NOTES" || echo "(no guidance notes yet: add with: guidance.sh add \"...\")"
    ;;

  relevant)
    prompt=$(printf '%s' "${2:-}" | tr 'A-Z' 'a-z')
    [ -f "$NOTES" ] || exit 0
    shown=0
    while IFS= read -r line; do
      # Only top-level note lines: start with "- " and carry a [scope] tag.
      printf '%s' "$line" | rg -q '^- .*\[[^]]+\]' || continue
      tags=$(printf '%s' "$line" | sed -n 's/^- [^[]*\[\([^]]*\)\].*/\1/p' | tr 'A-Z' 'a-z')
      scope_matches "$prompt" "$tags" && { printf '%s\n' "$line"; shown=1; }
    done < "$NOTES"
    [ "$shown" = 1 ] && bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guidance --action nudge >/dev/null 2>&1
    exit 0
    ;;

  *) echo "usage: guidance.sh {add|show|relevant} ..." >&2; exit 2 ;;
esac
