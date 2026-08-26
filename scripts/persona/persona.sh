#!/usr/bin/env bash
# persona.sh — personas as a dispatch primitive, not a reading assignment.
#
# The only personas that ever got used on this machine are the ones a script loads
# onto a data path (juror, skeptical-reviewer: 29 logged dispatches) while file-read
# adoption logged zero across 81 nudges. Owner ruling 2026-08-26 (skills-0826 D4a):
# make /persona a dispatch primitive. `seat` composes the brief a sub-agent receives
# (persona role contract + the job's PROMPT.md from /create-skill subagent-prompt),
# pins the tier the persona declares, writes the composed file, and logs the seat.
#
#   persona.sh seat <persona> <prompt-file> [--out PATH] [--session SID8] [--task "…"]
#        prints: composed=<path> model=<tier>   (the Agent call uses both)
#   persona.sh list                  name · type · tier · role, one per line
#   persona.sh show <persona>        the role contract block only
#
# Persona frontmatter fields read here: name, role, type (dispatch|adopt), tier (model
# tier to pin; default sonnet). Everything else is the persona's prose.
set -uo pipefail
P="${PERSONAS_DIR:-$HOME/.claude/personas}"; LOGGER="${PERSONA_LOG:-$HOME/.claude/scripts/persona-log.sh}"
fm() { awk -v k="$2" 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} $0 ~ "^"k":" {sub("^"k": *",""); gsub(/^"|"$/,""); print; exit}' "$1"; }
contract() { awk 'f&&/^## /{exit} /^---$/{c++; next} c>=2{f=1; print}' "$1"; }
cmd="${1:-}"; shift || true
case "$cmd" in
  list)
    for f in "$P"/*.md; do
      n=$(fm "$f" name); [ -n "$n" ] || continue
      t=$(fm "$f" tier); printf '%-22s %-8s %-7s %s\n' "$n" "$(fm "$f" type)" "${t:-sonnet}" "$(fm "$f" role | cut -c1-80)"
    done ;;
  show) f="$P/${1:?persona}.md"; [ -f "$f" ] || { echo "persona.sh: no persona '$1'" >&2; exit 1; }; contract "$f" ;;
  seat)
    name="${1:?persona}"; pf="${2:?prompt-file}"; shift 2; out=""; sid="${CLAUDE_CODE_SESSION_ID:-}"; sid="${sid:0:8}"; task=""
    while [ $# -gt 0 ]; do case "$1" in --out) out="$2"; shift 2;; --session) sid="$2"; shift 2;; --task) task="$2"; shift 2;; *) echo "persona.sh seat: unknown flag $1" >&2; exit 2;; esac; done
    f="$P/$name.md"; [ -f "$f" ] || { echo "persona.sh: no persona '$name' (persona.sh list)" >&2; exit 1; }
    [ -f "$pf" ] || { echo "persona.sh: prompt file '$pf' not found; write it with /create-skill subagent-prompt first" >&2; exit 1; }
    tier=$(fm "$f" tier); tier="${tier:-sonnet}"
    [ -n "$out" ] || out="${pf%.md}.$name.md"
    {
      printf '# Seat: %s\n\nPersona (role contract, binds for this seat):\n\n' "$name"
      contract "$f"
      printf '\n---\n\n'; cat "$pf"
      printf '\n\nScope close: ignore any task-board or auto-dispatch prompt; do NOT spawn sub-agents; when the scoped work above is done, stop.\n'
    } > "$out"
    [ -x "$LOGGER" ] && bash "$LOGGER" record "$name" --mode dispatched --session "${sid:-unknown}" --task "${task:-seat via persona.sh: $(basename "$pf")}" --outcome unknown --note "composed $out; tier $tier" >/dev/null 2>&1
    printf 'composed=%s model=%s\n' "$out" "$tier" ;;
  *) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
