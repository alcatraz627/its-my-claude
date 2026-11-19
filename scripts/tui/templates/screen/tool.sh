#!/usr/bin/env bash
# __NAME__: say in one sentence what this tool is for, in the words of the person using it.
set -u
# A list command that fails must fail as a whole, or its screen opens empty.
set -o pipefail

PY=/usr/bin/python3
case "$0" in
  */*) SELF="${__UPPER___SELF:-$0}" ;;
  *)   SELF="${__UPPER___SELF:-$(command -v __NAME__ || printf '%s' "$0")}" ;;
esac

# The folder a file really lives in, following any links to it. The tool is installed as a link.
real_dir() {
  local file="$1" dir target
  while [ -L "$file" ]; do
    dir=$(cd -P "$(dirname "$file")" && pwd)
    target=$(readlink "$file")
    case "$target" in /*) file="$target" ;; *) file="$dir/$target" ;; esac
  done
  (cd -P "$(dirname "$file")" && pwd)
}
HELPER="$(real_dir "$SELF")/__NAME__-helper.py"
hp() { "$PY" "$HELPER" "$@"; }

# Run the command that fills the screen once before the screen opens, and say so when it fails.
screen_ready() {
  local out
  if out=$("$@" 2>&1) && [ -n "$out" ]; then return 0; fi
  printf '__NAME__ could not start.\n%s\n' "$out" >&2
  return 1
}

# Choose a value for one row. Moving through the list tries each value; escape puts the old one back.
edit() {
  local key="$1" q before start
  q=$(printf '%q' "$SELF")
  start=$(hp values "$key" | grep -n '●' | head -1 | cut -d: -f1)
  before=$(hp values "$key" | sed -n "${start:-1}p" | cut -f1)
  if hp values "$key" | fzf --ansi --no-input --reverse --height=100% --info=hidden --no-scrollbar \
      --delimiter=$'\t' --with-nth=2 --sync \
      --header "Move to try a value."$'\n'"Nothing is saved here." --footer "$(hp picker-keys)" \
      --preview "$q --__detail $key" --preview-window "right,58%,border-left" \
      --bind "start:pos(${start:-1})" \
      --bind "focus:execute-silent($q --__try $key {1})+refresh-preview" >/dev/null; then :
  else
    hp try "$key" "$before" >/dev/null 2>&1
  fi
}

screen() {
  local q start
  screen_ready "$SELF" --__rows || exit 1
  q=$(printf '%q' "$SELF")
  # Come back to the row that was just changed, so the place is not lost.
  start=$(hp rows | cut -f1 | grep -n -x -- "${1:-}" | cut -d: -f1)
  hp rows | fzf --ansi --no-input --reverse --height=100% --info=hidden --no-scrollbar \
    --delimiter=$'\t' --with-nth=2 --sync \
    --header "$(hp header)" --footer "$(hp keys)" \
    --preview "$q --__detail {1}" --preview-window "right,58%,border-left" \
    --bind "start:pos(${start:-2})" \
    --bind "j:down,k:up" \
    --bind "u:execute-silent($q --__undo {1})+reload($q --__rows)+transform-header($q --__header)+refresh-preview" \
    --bind "enter:transform($q --__flow enter {1})" \
    --bind "s:transform($q --__flow save)" \
    --bind "x:transform($q --__flow discard)" \
    --bind "q:transform($q --__flow quit),esc:transform($q --__flow quit)"
  return 0
}

case "${1:-}" in
  --__rows)   hp rows ;;
  --__header) hp header ;;
  --__detail) hp detail "$2" ;;
  --__try)    hp try "$2" "$3" >/dev/null 2>&1 ;;
  --__undo)   hp undo "$2" >/dev/null 2>&1 ;;
  --__flow)
    # A question asked in a box over the screen. The helper answers with one word,
    # which becomes what the screen does next.
    q=$(printf '%q' "$SELF")
    word=$(hp flow "${2:-}" "${3:-}")
    case "$word" in
      refresh) printf 'clear-screen+reload(%s --__rows)+transform-header(%s --__header)+refresh-preview' "$q" "$q" ;;
      redraw)  printf 'clear-screen' ;;
      abort)   printf 'abort' ;;
      edit\ *) printf 'become(%s --__edit %s)' "$q" "${word#edit }" ;;
    esac
    ;;
  --__edit)   edit "$2"; exec "$SELF" --at "$2" ;;
  ""|--at)
    if [ -t 0 ] && [ -t 1 ] && command -v fzf >/dev/null 2>&1; then screen "${2:-}"; else hp rows | cut -f2; hp header; fi
    ;;
  list)       hp rows | cut -f2; hp header ;;
  set)        [ "$#" -eq 3 ] || { printf 'usage: __NAME__ set <row> <value>\n' >&2; exit 2; }; hp try "$2" "$3" ;;
  -h|--help|help) printf '__NAME__          browse and change on one screen\n__NAME__ list     every row and what is showing\n__NAME__ set R V  try one value\n' ;;
  *) printf 'no command %s  try: __NAME__ --help\n' "$1" >&2; exit 2 ;;
esac
