#!/usr/bin/env bash
# require.sh — dependency preflight for std::claude::tui shell tools.
#
#   tui_have DEP        boolean (no output, no exit) — for CHOOSING a degradation
#                       rung where a missing dep is not fatal (pick.sh uses this).
#   tui_require DEP...   all present → silent, returns 0. First missing → a
#                       consistent install hint on stderr, returns 1. It does NOT
#                       `exit` — the caller decides if a missing dep is fatal:
#                         degrading tool:  tui_have fzf || fall_back
#                         hard-dep tool:   tui_require curl || exit 1
#
# Resolves the REAL binary via `command -v` (not alias-aware), so a shell alias
# such as `cat=glow` can't mask a genuinely-absent tool.
#
# Under `set -e`: GUARD it — `tui_require curl || exit 1`, `tui_have fzf || fall_back`.
# A bare `tui_require dep` that returns 1 aborts a set -e caller (standard bash);
# the function returns status so you can decide whether a missing dep is fatal.

_tui_brew_pkg() {                          # command → brew package, where they differ
  case "$1" in
    rg) printf ripgrep ;;
    *)  printf '%s' "$1" ;;                # fd/gum/fzf/jq/bat/… are same-named
  esac
}

# tui_have DEP — boolean: is DEP a real command? (for choosing a degradation rung)
tui_have() { command -v "$1" >/dev/null 2>&1; }

# tui_require DEP... — all present? silent 0. First missing → install hint on stderr, returns 1 (no exit).
tui_require() {
  local dep miss=0
  for dep in "$@"; do
    command -v "$dep" >/dev/null 2>&1 && continue
    printf '%s not found — install: brew install %s\n' "$dep" "$(_tui_brew_pkg "$dep")" >&2
    miss=1
  done
  return "$miss"
}
