#!/usr/bin/env bash
# atone-common.sh — shared helpers for the atone script suite.
#
# Provides:
#   - gum-tui sourcing (with plain-text shim fallback)
#   - ANSI color codes (C_*), TTY-aware (NO_COLOR / TERM=dumb / non-tty stdout)
#   - help-text formatters (_section, _cmd, _opt, _ex, _exd) per
#     ~/.claude/conventions/cli-help-design.md
#   - outcome helpers (_ok, _info, _warn, _die)
#
# Source from any atone-*.sh:
#     # shellcheck disable=SC1091
#     source "$(dirname "${BASH_SOURCE[0]}")/atone-common.sh"

# Guard against double-sourcing
[ "${__ATONE_COMMON_LOADED:-0}" = "1" ] && return 0
__ATONE_COMMON_LOADED=1

# ─── Pipe-friendly TTY detection ─────────────────────────────────

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then
  ATONE_TTY=1
else
  ATONE_TTY=0
fi

# ─── Color codes (empty when non-TTY) ────────────────────────────

if [ "$ATONE_TTY" = "1" ]; then
  C_RESET=$'\033[0m';   C_BOLD=$'\033[1m';   C_DIM=$'\033[2m'
  C_CYAN=$'\033[36m';   C_YELLOW=$'\033[33m'; C_GREEN=$'\033[32m'
  C_BLUE=$'\033[34m';   C_MAGENTA=$'\033[35m';C_WHITE=$'\033[97m'
  C_RED=$'\033[31m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''
  C_CYAN=''; C_YELLOW=''; C_GREEN=''
  C_BLUE=''; C_MAGENTA=''; C_WHITE=''
  C_RED=''
fi

# ─── Help-text formatters (mirror llm-mini-core.sh) ──────────────

_section() { printf '\n%s%s%s%s\n' "$C_BOLD" "$C_YELLOW" "$1" "$C_RESET"; }
_cmd()     { printf '  %s%-30s%s %s%s%s\n' "$C_CYAN"  "$1" "$C_RESET" "$C_DIM" "$2" "$C_RESET"; }
_opt()     { printf '  %s%-22s%s %s\n'     "$C_GREEN" "$1" "$C_RESET" "$2"; }
_ex()      { printf '  %s$%s %s%s%s\n'     "$C_DIM"   "$C_RESET" "$C_WHITE" "$1" "$C_RESET"; }
_exd()     { printf '    %s# %s%s\n'       "$C_DIM"   "$1" "$C_RESET"; }
_subhead() { printf '\n  %s%s%s\n'         "$C_BOLD" "$1" "$C_RESET"; }
_dim()     { printf '  %s%s%s\n'           "$C_DIM" "$1" "$C_RESET"; }

# ─── Outcome helpers ─────────────────────────────────────────────

_ok()    { printf '%s✓%s %s\n'    "$C_GREEN"   "$C_RESET" "$*"; }
_info()  { printf '%s●%s %s\n'    "$C_CYAN"    "$C_RESET" "$*"; }
_warn()  { printf '%s⚠%s %s\n'    "$C_YELLOW"  "$C_RESET" "$*" >&2; }
_err()   { printf '%s✗%s %s\n'    "$C_RED"     "$C_RESET" "$*" >&2; }
_die()   { _err "$@"; exit "${EXIT_CODE:-2}"; }

# ─── gum-tui (optional, lazy) ────────────────────────────────────

_GUM_TUI="$HOME/.claude/skills/shared/gum-tui.sh"
ATONE_HAS_GUM=0
if [ "$ATONE_TTY" = "1" ] && [ -f "$_GUM_TUI" ]; then
  # shellcheck disable=SC1090
  if source "$_GUM_TUI" 2>/dev/null; then
    ATONE_HAS_GUM=1
  fi
fi

# Shim gum_* functions if gum-tui not available (plain-text equivalents)
if [ "$ATONE_HAS_GUM" = "0" ]; then
  gum_header()    { printf '\n%s═══ %s ═══%s\n' "$C_BOLD" "$1" "$C_RESET"; }
  gum_subheader() { printf '\n%s── %s ──%s\n'   "$C_BOLD" "$1" "$C_RESET"; }
  gum_panel()     { local t="$1"; shift; printf '\n%s┌─ %s%s\n' "$C_DIM" "$t" "$C_RESET"
                    printf '%s│%s %s\n' "$C_DIM" "$C_RESET" "$@"
                    printf '%s└──%s\n' "$C_DIM" "$C_RESET"; }
  gum_kv()        { printf '  %s%-20s%s %s\n' "$C_DIM" "$1:" "$C_RESET" "$2"; }
  gum_divider()   { printf '%s─────────────────────────────────────────────────%s\n' "$C_DIM" "$C_RESET"; }
  gum_info()      { _info "$@"; }
  gum_success()   { _ok "$@"; }
  gum_error()     { _err "$@"; }
  gum_warn()      { _warn "$@"; }
fi

# ─── atone summary card ──────────────────────────────────────────
# render_atone_summary <inputs> <steps> <outputs> <residuals>
# Each arg is a newline-separated body: inputs/outputs as "label\tvalue"
# lines, steps/residuals as plain lines. Replaces the line-by-line log
# scroll with one scannable card. Uses gum when on a TTY, plain otherwise.
_atone_kv_lines() { while IFS=$'\t' read -r k v; do [ -n "$k" ] && printf '  %s%-14s%s %s\n' "${C_DIM}" "$k" "${C_RESET}" "$v"; done; }
_atone_li_lines() { while IFS= read -r l; do [ -n "$l" ] && printf '  %s•%s %s\n' "${C_DIM}" "${C_RESET}" "$l"; done; }
render_atone_summary() {
  local inputs="$1" steps="$2" outputs="$3" residuals="$4"
  local body
  body=$(
    printf '%sINPUTS%s\n'    "$C_BOLD" "$C_RESET"; printf '%s\n' "$inputs"   | _atone_kv_lines
    printf '\n%sSTEPS%s\n'   "$C_BOLD" "$C_RESET"; printf '%s\n' "$steps"    | _atone_li_lines
    printf '\n%sOUTPUTS%s\n' "$C_BOLD" "$C_RESET"; printf '%s\n' "$outputs"  | _atone_kv_lines
    if [ -n "$residuals" ]; then
      printf '\n%sRESIDUALS%s\n' "$C_BOLD" "$C_RESET"; printf '%s\n' "$residuals" | _atone_li_lines
    fi
  )
  if [ "${ATONE_HAS_GUM:-0}" = "1" ] && command -v gum >/dev/null 2>&1; then
    printf '%s\n' "$body" | gum style --border rounded --border-foreground 4 --padding "0 1" --margin "1 0"
  else
    printf '\n%s┌─ atone recorded ─────────────────────────────%s\n%s\n%s└──────────────────────────────────────────────%s\n' \
      "$C_DIM" "$C_RESET" "$body" "$C_DIM" "$C_RESET"
  fi
}

# ─── Convenience: assert tool present ────────────────────────────

_require() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || _die "required tool not found: $cmd"
  done
}
