#!/usr/bin/env bash
# parked.sh — the working surface over ~/.claude/skills-parked/.
#
# Parked skills are kept but not loaded, so they need three things a live skill
# gets for free: an index the agent can read (tldr + tags + activation criteria),
# a match against the project at hand (the owner's two-way check, half one), and a
# copy verb that installs one into a project's own .claude/skills/. The friction
# verbs carry half two: shapes of heavy sessions, counted per project, so the
# SECOND occurrence asks the owner whether to commission a skill (their ruling:
# twice, not thrice).
#
#   parked.sh index                    regenerate INDEX.md from SKILL.md + tags.tsv
#   parked.sh list                     one line per parked skill
#   parked.sh match [--project DIR]    parked skills whose tags fit the project
#   parked.sh copy <name> [--to DIR]   install into <project>/.claude/skills/<name>
#   parked.sh friction add "<shape>" --project DIR [--note "..."]
#   parked.sh friction check [--project DIR]   shapes at count >= 2
#
# Test overrides: PARKED_DIR, PARKED_FRICTION.
set -uo pipefail

PARKED="${PARKED_DIR:-$HOME/.claude/skills-parked}"
FRICTION="${PARKED_FRICTION:-$PARKED/friction.jsonl}"
TAGS="$PARKED/tags.tsv"
command -v jq >/dev/null 2>&1 || { echo "parked: jq required" >&2; exit 2; }
source "$HOME/.claude/scripts/ledger/ledger-common.sh"

_desc() { # first sentence of a SKILL.md description
  rg -m1 '^description:' "$1" 2>/dev/null | sed 's/^description: *//' | cut -c1-140
}
_tags_row() { rg -m1 "^${1}	" "$TAGS" 2>/dev/null; }

cmd_index() {
  local out="$PARKED/INDEX.md" d name
  {
    echo "# Parked skills — tldr, tags, activation"
    echo
    echo "Not loaded; see README.md for the two-way check. Regenerate: \`bash ~/.claude/scripts/parked/parked.sh index\`."
    echo
    echo "| skill | tldr | tags | copy in when |"
    echo "|---|---|---|---|"
    for d in "$PARKED"/*/; do
      name=$(basename "$d")
      [ -f "$d/SKILL.md" ] || continue
      local row tags="" act=""
      row=$(_tags_row "$name") || true
      [ -n "$row" ] && { tags=$(printf '%s' "$row" | cut -f2); act=$(printf '%s' "$row" | cut -f3); }
      printf '| `%s` | %s | %s | %s |\n' "$name" "$(_desc "$d/SKILL.md" | sed 's/|/\\|/g')" "$tags" "$(printf '%s' "$act" | sed 's/|/\\|/g')"
    done
  } > "$out"
  echo "index regenerated: $out ($(rg -c '^\| `' "$out") skills)"
}

cmd_list() {
  local d
  for d in "$PARKED"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    printf '  %-18s %s\n' "$(basename "$d")" "$(_desc "$d/SKILL.md" | cut -c1-90)"
  done
}

# Tag-to-marker match. Markers are cheap file probes, not a project model; a match
# is a suggestion for the agent to weigh, never an auto-copy.
_project_markers() {
  local p="$1" m=""
  [ -n "$(ls "$p"/*.xcodeproj 2>/dev/null)" ] || [ -f "$p/Package.swift" ] && m="$m macos ios swift swiftui xcode"
  [ -f "$p/next.config.js" ] || [ -f "$p/next.config.mjs" ] || [ -f "$p/next.config.ts" ] && m="$m nextjs"
  [ -f "$p/package.json" ] && m="$m npm node dependencies"
  [ -f "$p/tsconfig.json" ] && m="$m typescript"
  [ -f "$p/.mcp.json" ] && m="$m mcp"
  printf '%s' "$m"
}

cmd_match() {
  local proj="$PWD"
  while [ $# -gt 0 ]; do case "$1" in --project) proj="$2"; shift 2;; *) shift;; esac; done
  local markers hits=""
  markers=$(_project_markers "$proj")
  [ -z "$markers" ] && return 0
  local name tags t
  while IFS=$'\t' read -r name tags _; do
    [ "${name#\#}" = "$name" ] || continue
    [ -d "$PARKED/$name" ] || continue
    for t in $(printf '%s' "$tags" | tr ',' ' '); do
      if printf ' %s ' "$markers" | rg -q " $t "; then hits="$hits$name "; break; fi
    done
  done < "$TAGS"
  [ -n "$hits" ] && printf '%s\n' "$hits" | tr ' ' '\n' | rg -v '^$'
}

cmd_copy() {
  local name="${1:-}"; shift || true
  local to="$PWD"
  while [ $# -gt 0 ]; do case "$1" in --to) to="$2"; shift 2;; *) shift;; esac; done
  [ -n "$name" ] && [ -d "$PARKED/$name" ] || { echo "parked copy: no parked skill '$name'" >&2; exit 2; }
  [ "$to" = "$HOME/.claude" ] && { echo "parked copy: to un-park globally, mv the dir back into ~/.claude/skills/ instead" >&2; exit 2; }
  local dest="$to/.claude/skills/$name"
  [ -e "$dest" ] && { echo "parked copy: $dest already exists" >&2; exit 2; }
  mkdir -p "$(dirname "$dest")" && cp -R "$PARKED/$name" "$dest" \
    && echo "copied: $dest (loads for that project; the parked original stays canonical)"
}

cmd_friction() {
  local verb="${1:-}"; shift || true
  case "$verb" in
    add)
      local shape="${1:-}"; shift || true
      local proj="" note=""
      while [ $# -gt 0 ]; do case "$1" in
        --project) proj="$2"; shift 2;; --note) note="$2"; shift 2;; *) shift;; esac; done
      [ -n "$shape" ] && [ -n "$proj" ] || { echo 'parked friction add: "<shape>" --project DIR' >&2; exit 2; }
      local line
      line=$(jq -cn --arg id "$(ledger_id fric)" --arg ts "$(ledger_ts)" --arg sh "$shape" \
        --arg p "$proj" --arg n "$note" --arg sid "${CLAUDE_CODE_SESSION_ID:-}" \
        '{id:$id, ts:$ts, shape:$sh, project:$p, note:$n, session_id:$sid}
         | with_entries(select(.value != "" and .value != null))')
      ledger_append "$FRICTION" "$FRICTION.lock" "$line"
      # The owner's twice-rule, enforced at write time so the asker cannot forget.
      local n
      n=$(jq -r --arg sh "$shape" --arg p "$proj" 'select(.shape == $sh and .project == $p) | .id' "$FRICTION" | wc -l | tr -d ' ')
      if [ "$n" -ge 2 ]; then
        echo "SECOND occurrence of shape '$shape' in $proj — ask the owner now whether to commission a skill for it (their ruling, 2026-08-20: twice builds the repo)."
      else
        echo "recorded (1st occurrence of this shape here)"
      fi;;
    check)
      local proj=""
      while [ $# -gt 0 ]; do case "$1" in --project) proj="$2"; shift 2;; *) shift;; esac; done
      [ -f "$FRICTION" ] || return 0
      jq -r --arg p "$proj" 'select(($p == "") or (.project == $p)) | [.project, .shape] | @tsv' "$FRICTION" \
        | sort | uniq -c | awk '$1 >= 2 { $1=$1"x"; print "  " $0 }';;
    *) echo 'parked friction: add "<shape>" --project DIR | check [--project DIR]' >&2; exit 2;;
  esac
}

case "${1:-}" in
  index) shift; cmd_index "$@";;
  list) shift; cmd_list "$@";;
  match) shift; cmd_match "$@";;
  copy) shift; cmd_copy "$@";;
  friction) shift; cmd_friction "$@";;
  *) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//';;
esac
