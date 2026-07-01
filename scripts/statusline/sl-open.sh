#!/usr/bin/env bash
# sl-open.sh — Open statusline-related files, prompting for program choice
# Usage: sl-open.sh [target]
# Targets: sh, conf, skill, playground, dev-guide, widget-ref, server, audit, cli

# Shared TUI libs — TTY-gated palette + hardened terminal read. Degrade quietly
# if a lib is absent (no color, safe default) rather than hard-fail.
for _lib in colors tty; do . "${HOME}/.claude/scripts/tui/${_lib}.sh" 2>/dev/null || true; done
command -v tui_colors_init >/dev/null 2>&1 && tui_colors_init

SCRIPTS="${HOME}/.claude/scripts"
ASSETS_STATIC="${HOME}/.claude/assets/static"
ASSETS_DOCS="${HOME}/.claude/assets/docs"
SKILLS="${HOME}/.claude/skills"

TARGET="${1:-}"

# ── Resolve target alias → absolute path ──────────────────────────────────────
resolve_target() {
  local t="$1"
  case "$t" in
    sh|statusline.sh)           echo "${HOME}/.claude/scripts/statusline/statusline.sh" ;;
    conf|statusline.conf|config) echo "${HOME}/.claude/statusline.conf" ;;
    skill|SKILL.md)             echo "${SKILLS}/statusline/SKILL.md" ;;
    playground|play)            echo "${ASSETS_STATIC}/statusline-playground.html" ;;
    server|statusline-server)   echo "${ASSETS_STATIC}/statusline-server.mjs" ;;
    dev-guide|devguide|guide)   echo "${ASSETS_DOCS}/statusline-dev-guide.md" ;;
    widget-ref|widgets|ref)
      latest=$(ls -t "${ASSETS_DOCS}"/*statusline-widget-ref*.html 2>/dev/null | head -1)
      [[ -n "$latest" ]] && echo "$latest" || echo "${ASSETS_DOCS}/statusline-dev-guide.md"
      ;;
    audit|sl-audit)             echo "${SCRIPTS}/sl-audit.sh" ;;
    cli|sl-cli)                 echo "${SCRIPTS}/sl-cli.sh" ;;
    *)
      # Partial filename match across known dirs
      local found=""
      for dir in "$SCRIPTS" "$ASSETS_DOCS" "$ASSETS_STATIC" "$SKILLS/statusline"; do
        local match
        match=$(ls "$dir" 2>/dev/null | grep -i "$t" | head -1)
        if [[ -n "$match" ]]; then found="$dir/$match"; break; fi
      done
      echo "$found"
      ;;
  esac
}

# ── Show target list ───────────────────────────────────────────────────────────
show_list() {
  echo ""
  printf "${B}Statusline Files${R}\n"
  echo ""
  printf "  ${C}%-18s${R}  %s\n" "sh"          "statusline.sh — main render script"
  printf "  ${C}%-18s${R}  %s\n" "conf"         "statusline.conf — segment on/off settings"
  printf "  ${C}%-18s${R}  %s\n" "skill"        "statusline/SKILL.md — Claude skill definition"
  printf "  ${C}%-18s${R}  %s\n" "playground"   "statusline-playground.html — interactive preview"
  printf "  ${C}%-18s${R}  %s\n" "server"       "statusline-server.mjs — render server"
  printf "  ${C}%-18s${R}  %s\n" "dev-guide"    "statusline-dev-guide.md — developer guide"
  printf "  ${C}%-18s${R}  %s\n" "widget-ref"   "statusline-widget-ref.html — widget reference"
  printf "  ${C}%-18s${R}  %s\n" "audit"        "sl-audit.sh — audit script"
  printf "  ${C}%-18s${R}  %s\n" "cli"          "sl-cli.sh — dispatcher"
  echo ""
  printf "${D}Usage: statusline open <target>${R}\n"
  echo ""
}

# ── Prompt user to pick a program ─────────────────────────────────────────────
prompt_program() {
  local path="$1"
  local glow_cmd="cat"
  command -v glow &>/dev/null && glow_cmd="glow"

  # Print file path on line 1
  printf "%s\n" "$path"
  # Print options on line 2
  printf "${D}Open with: ${R}${C}[1]${R} code  ${C}[2]${R} nano  ${C}[3]${R} google-chrome  ${C}[4]${R} %s  ${C}[5]${R} open ${D}(default)${R}  ${D}[Enter] print path only${R}\n" "$glow_cmd"
  printf "${D}> ${R}"

  local choice=""
  # Hardened read: honest tty probe, never hangs headless. No tty / Enter → "" →
  # the empty-default branch below prints the path only (behavior preserved).
  tui_read_tty choice 2>/dev/null || choice=""

  case "$choice" in
    1|code)
      printf "${G}↗${R}  code %s\n" "$path"
      code "$path" 2>/dev/null || { printf "${RED}✗${R}  'code' not found\n" >&2; exit 1; }
      ;;
    2|nano)
      nano "$path"
      ;;
    3|chrome|google-chrome)
      printf "${G}↗${R}  google-chrome %s\n" "$path"
      open -a "Google Chrome" "$path" 2>/dev/null || \
        google-chrome "$path" 2>/dev/null || \
        { printf "${RED}✗${R}  Google Chrome not found\n" >&2; exit 1; }
      ;;
    4|glow|cat)
      if command -v glow &>/dev/null; then
        glow "$path"
      else
        cat "$path"
      fi
      ;;
    5|open|"")
      # Empty = just printed path above, no open
      if [[ -z "$choice" ]]; then
        :  # Already printed path on line 1; done
      else
        printf "${G}↗${R}  open %s\n" "$path"
        open "$path" 2>/dev/null
      fi
      ;;
    *)
      # Treat unknown input as a raw command name
      printf "${G}↗${R}  %s %s\n" "$choice" "$path"
      "$choice" "$path" 2>/dev/null || { printf "${RED}✗${R}  command not found: %s\n" "$choice" >&2; exit 1; }
      ;;
  esac
}

# ── Entry point ────────────────────────────────────────────────────────────────
if [[ -z "$TARGET" ]]; then
  show_list
  exit 0
fi

path=$(resolve_target "$TARGET")
if [[ -z "$path" ]]; then
  printf "${RED}✗${R}  Unknown target: '%s'\n" "$TARGET" >&2
  echo ""
  show_list
  exit 1
fi

if [[ ! -f "$path" ]]; then
  printf "${RED}✗${R}  File not found: %s\n" "$path" >&2
  exit 1
fi

prompt_program "$path"
