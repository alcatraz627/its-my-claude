#!/usr/bin/env bash
# pick.sh — the one fzf → gum → read degradation ladder for std::claude::tui.
#
# Candidates arrive on STDIN (one per line); the chosen value goes to STDOUT; all
# UI (the picker, prompts) goes to the terminal, so these compose in a pipe:
#     sel="$(printf '%s\n' "${items[@]}" | tui_pick_one --prompt 'pick> ')"
#
# Ships:
#   tui_pick_one   pick one from stdin (fzf → gum filter → numbered read)
#   tui_pick_many  multi-select from stdin (fzf -m → gum choose → numbered multi)
#   tui_choose     pick one from a small STATIC arg list (wrapper, no stdin plumbing)
#   tui_confirm    yes/no destructive gate (gum confirm → y/N read; headless = NO)

: "${HOME:?pick.sh: HOME must be set to locate sibling modules}"
command -v tui_have     >/dev/null 2>&1 || . "$HOME/.claude/scripts/tui/require.sh" 2>/dev/null || true
command -v tui_read_tty >/dev/null 2>&1 || . "$HOME/.claude/scripts/tui/tty.sh"     2>/dev/null || true
# Fail loud + early if a sibling didn't load — better than an undefined-function
# crash later, far from the cause.
if ! command -v tui_have >/dev/null 2>&1 || ! command -v tui_read_tty >/dev/null 2>&1; then
  printf 'pick.sh: sibling modules not found under %s/.claude/scripts/tui/ (require.sh / tty.sh)\n' "$HOME" >&2
  return 1 2>/dev/null || exit 1
fi

# tui_pick_one [--prompt P] [--preview CMD] [--non-tty fail|first|passthrough] — pick one line from stdin
#   Ladder: fzf (fuzzy + preview) → gum filter → numbered read menu. With no usable
#   tty, applies the --non-tty policy (default fail — a picker can't guess for you):
#     fail        return 1, print nothing (caller takes its own default)
#     first       echo the first candidate
#     passthrough echo it iff there is exactly one candidate, else return 1
tui_pick_one() {
  local prompt='pick> ' preview='' nontty='fail'
  while [ $# -gt 0 ]; do
    case "$1" in
      --prompt)  prompt="$2"; shift 2 ;;
      --preview) preview="$2"; shift 2 ;;
      --non-tty) nontty="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  # Candidates MUST be piped. If stdin is a terminal the caller forgot to pipe —
  # reading would hang waiting for hand-typed EOF, so fail fast instead.
  [ -t 0 ] && { echo "tui_pick_one: candidates must be piped on stdin" >&2; return 2; }
  local input; input="$(command cat)"          # `command` so a cat=… alias can't bite
  if tui_have_tty && tui_have fzf; then
    if [ -n "$preview" ]; then
      printf '%s\n' "$input" | fzf --height="${TUI_PICK_HEIGHT:-40%}" --reverse --prompt "$prompt" --preview "$preview"
    else
      printf '%s\n' "$input" | fzf --height="${TUI_PICK_HEIGHT:-40%}" --reverse --prompt "$prompt"
    fi
    return
  elif tui_have_tty && tui_have gum; then
    local out rc
    out="$(printf '%s\n' "$input" | gum filter --placeholder "$prompt")"; rc=$?
    stty sane 2>/dev/null || true             # gum leaves raw mode; restore the line discipline
    printf '%s' "$out"; return "$rc"
  elif tui_have_tty; then
    _tui_numbered_menu "$prompt" "$input"; return
  fi
  case "$nontty" in                            # no tty
    first)       printf '%s\n' "$input" | head -1 ;;
    passthrough) case "$input" in ''|*$'\n'*) return 1 ;; *) printf '%s\n' "$input" ;; esac ;;
    *)           return 1 ;;
  esac
}

# tui_pick_many [--prompt P] — multi-select from stdin; selections newline-separated on stdout
#   Ladder: fzf -m → gum choose --no-limit → numbered "1 3 5" read. No tty → return 1.
tui_pick_many() {
  local prompt='pick (multi)> '
  while [ $# -gt 0 ]; do case "$1" in --prompt) prompt="$2"; shift 2 ;; *) shift ;; esac; done
  [ -t 0 ] && { echo "tui_pick_many: candidates must be piped on stdin" >&2; return 2; }
  local input; input="$(command cat)"
  if tui_have_tty && tui_have fzf; then
    printf '%s\n' "$input" | fzf -m --height="${TUI_PICK_HEIGHT:-40%}" --reverse --prompt "$prompt"
  elif tui_have_tty && tui_have gum; then
    local out rc
    out="$(printf '%s\n' "$input" | gum choose --no-limit)"; rc=$?
    stty sane 2>/dev/null || true
    printf '%s' "$out"; return "$rc"
  elif tui_have_tty; then
    _tui_numbered_multi "$prompt" "$input"; return
  fi
  return 1
}

# tui_choose [--prompt P] [--preview C] OPT1 OPT2 ... — pick one from a STATIC arg list
#   Ergonomic wrapper around tui_pick_one for small fixed option sets (no stdin plumbing).
tui_choose() {
  local pass=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --prompt|--preview|--non-tty) pass+=("$1" "$2"); shift 2 ;;
      *) break ;;
    esac
  done
  [ $# -gt 0 ] || { echo "tui_choose: no options given" >&2; return 2; }
  printf '%s\n' "$@" | tui_pick_one ${pass[@]+"${pass[@]}"}   # set -u-safe empty-array expansion
}

_tui_numbered_menu() {   # read-rung: numbered list to stderr, picked value to stdout
  local prompt="$1" input="$2" i=1 line choice n
  [ -n "$input" ] || return 1                              # nothing to pick (no blank "1)" row)
  while IFS= read -r line; do printf '%2d) %s\n' "$i" "$line" >&2; i=$((i + 1)); done <<EOF
$input
EOF
  tui_read_tty -p "$prompt" choice || return 1
  case "$choice" in ''|*[!0-9]*) return 1 ;; esac          # non-numeric → no selection
  n="$(printf '%s\n' "$input" | wc -l | tr -d ' ')"
  [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ] || return 1  # out of range → no selection
  printf '%s\n' "$input" | sed -n "${choice}p"
}

_tui_numbered_multi() {  # read-rung multi: "1 3 5" → those lines, one per line on stdout
  local prompt="$1" input="$2" i=1 line choices tok n
  [ -n "$input" ] || return 1
  while IFS= read -r line; do printf '%2d) %s\n' "$i" "$line" >&2; i=$((i + 1)); done <<EOF
$input
EOF
  n=$((i - 1))
  tui_read_tty -p "${prompt}(e.g. 1 3 5) " choices || return 1
  [ -n "$choices" ] || return 1
  for tok in $choices; do
    case "$tok" in ''|*[!0-9]*) continue ;; esac
    [ "$tok" -ge 1 ] && [ "$tok" -le "$n" ] && printf '%s\n' "$input" | sed -n "${tok}p"
  done
}

# tui_confirm PROMPT — destructive-action gate. Returns 0=yes, 1=no. With no tty
# it returns 1 (safe default = NO; a confirm must never auto-yes headless).
tui_confirm() {
  local prompt="${1:-Proceed?}"
  if tui_have_tty && tui_have gum; then
    local rc
    gum confirm "$prompt"; rc=$?
    stty sane 2>/dev/null || true
    return "$rc"
  elif tui_have_tty; then
    local ans=''
    tui_read_tty -p "$prompt [y/N] " ans || return 1
    case "$ans" in [yY]*) return 0 ;; *) return 1 ;; esac
  fi
  return 1
}

# ── Enriched pickers (colored display, clean value; suggest-or-add) ──────────
# The reusable half of the "interactive CLI standard": a colored list whose
# selection still parses cleanly, and a selector that suggests existing options
# without forbidding a new one. See conventions/tui-handbook.md § Enriched pickers.

# tui_strip_ansi — filter: drop SGR color escapes from stdin. The clean way to get
# a plain value back out of a colored display.
tui_strip_ansi() { sed $'s/\033\\[[0-9;]*m//g'; }

# tui_pick_key [--prompt P] [--preview CMD] [--non-tty POLICY] — pick from
# `key<TAB>display` lines on stdin; SHOWS the (possibly colored) display, RETURNS
# the clean key. This is THE idiom for a colored list: fzf renders the color
# (--ansi) and searches only the display column, the key column never shows, and
# the caller gets a plain key back with no ANSI to strip. Falls to gum / a numbered
# read, both showing the display and returning the key. Preview {} is the FULL
# line, so a preview command extracts its key with `cut -f1`.
tui_pick_key() {
  local prompt='pick> ' preview='' nontty='fail'
  while [ $# -gt 0 ]; do case "$1" in
    --prompt)  prompt="$2"; shift 2 ;;
    --preview) preview="$2"; shift 2 ;;
    --non-tty) nontty="$2"; shift 2 ;;
    *) shift ;;
  esac; done
  [ -t 0 ] && { echo "tui_pick_key: candidates must be piped on stdin" >&2; return 2; }
  local input; input="$(command cat)"
  if tui_have_tty && tui_have fzf; then
    local fa=(--height="${TUI_PICK_HEIGHT:-40%}" --reverse --ansi --delimiter='\t' --with-nth='2..' --nth='2..' --prompt "$prompt")
    [ -n "$preview" ] && fa+=(--preview "$preview")
    printf '%s\n' "$input" | fzf "${fa[@]}" | cut -f1
    return "${PIPESTATUS[1]}"
  elif tui_have_tty && tui_have gum; then
    local disp sel rc
    disp="$(printf '%s\n' "$input" | cut -f2- | tui_strip_ansi)"
    sel="$(printf '%s\n' "$disp" | gum filter --placeholder "$prompt")"; rc=$?
    stty sane 2>/dev/null || true
    [ "$rc" = 0 ] && [ -n "$sel" ] || return 1
    printf '%s\n' "$input" | while IFS=$'\t' read -r k d; do
      [ "$(printf '%s' "$d" | tui_strip_ansi)" = "$sel" ] && { printf '%s\n' "$k"; break; }
    done
  elif tui_have_tty; then
    local i=1 k d choice n
    while IFS=$'\t' read -r k d; do printf '%2d) %s\n' "$i" "$(printf '%s' "$d" | tui_strip_ansi)" >&2; i=$((i+1)); done <<< "$input"
    n=$((i-1)); tui_read_tty -p "$prompt" choice || return 1
    case "$choice" in ''|*[!0-9]*) return 1 ;; esac
    { [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ]; } || return 1
    printf '%s\n' "$input" | sed -n "${choice}p" | cut -f1
  else
    case "$nontty" in
      first)       printf '%s\n' "$input" | head -1 | cut -f1 ;;
      passthrough) case "$input" in ''|*$'\n'*) return 1 ;; *) printf '%s\n' "$input" | cut -f1 ;; esac ;;
      *)           return 1 ;;
    esac
  fi
}

# tui_pick_or_add [--prompt P] — pick one of the seeded candidates (stdin, may be
# `key<TAB>display`) OR type a NEW value. Returns the chosen key, or the typed
# query verbatim when it matches nothing. For path / name selectors that should
# SUGGEST without RESTRICTING. fzf --print-query gives the typed query even when
# no row matches; the numbered fallback treats a number as a seed pick and any
# other text as the new value.
tui_pick_or_add() {
  local prompt='pick or type> '
  while [ $# -gt 0 ]; do case "$1" in --prompt) prompt="$2"; shift 2 ;; *) shift ;; esac; done
  [ -t 0 ] && { echo "tui_pick_or_add: candidates must be piped on stdin" >&2; return 2; }
  local input; input="$(command cat)"
  if tui_have_tty && tui_have fzf; then
    local out q sel
    out="$(printf '%s\n' "$input" | fzf --height="${TUI_PICK_HEIGHT:-40%}" --reverse --ansi --print-query \
            --delimiter='\t' --with-nth='2..' --nth='2..' --prompt "$prompt")"
    q="$(printf '%s\n' "$out" | sed -n 1p)"
    sel="$(printf '%s\n' "$out" | sed -n 2p | cut -f1)"
    if [ -n "$sel" ]; then printf '%s\n' "$sel"
    elif [ -n "$q" ]; then printf '%s\n' "$q"
    else return 1; fi
  elif tui_have_tty; then
    local i=1 k d choice n
    while IFS=$'\t' read -r k d; do printf '%2d) %s\n' "$i" "$(printf '%s' "${d:-$k}" | tui_strip_ansi)" >&2; i=$((i+1)); done <<< "$input"
    n=$((i-1)); printf '   %s(or type a new value)%s\n' "${DIM:-}" "${RST:-}" >&2
    tui_read_tty -p "$prompt" choice || return 1
    [ -n "$choice" ] || return 1
    case "$choice" in
      *[!0-9]*) printf '%s\n' "$choice" ;;
      *) if { [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ]; }; then printf '%s\n' "$input" | sed -n "${choice}p" | cut -f1; else printf '%s\n' "$choice"; fi ;;
    esac
  else
    return 1
  fi
}
