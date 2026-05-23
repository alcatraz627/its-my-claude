#!/usr/bin/env bash
# sl-open.sh — Open statusline-related files, prompting for program choice
# Usage: sl-open.sh [target]
# Targets: sh, conf, skill, playground, dev-guide, widget-ref, server, audit, cli

bold=$'\033[1m'; dim=$'\033[2m'; rst=$'\033[0m'
grn=$'\033[32m'; ylw=$'\033[33m'; red=$'\033[31m'; cyn=$'\033[36m'; mag=$'\033[35m'

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
  printf "${bold}Statusline Files${rst}\n"
  echo ""
  printf "  ${cyn}%-18s${rst}  %s\n" "sh"          "statusline.sh — main render script"
  printf "  ${cyn}%-18s${rst}  %s\n" "conf"         "statusline.conf — segment on/off settings"
  printf "  ${cyn}%-18s${rst}  %s\n" "skill"        "statusline/SKILL.md — Claude skill definition"
  printf "  ${cyn}%-18s${rst}  %s\n" "playground"   "statusline-playground.html — interactive preview"
  printf "  ${cyn}%-18s${rst}  %s\n" "server"       "statusline-server.mjs — render server"
  printf "  ${cyn}%-18s${rst}  %s\n" "dev-guide"    "statusline-dev-guide.md — developer guide"
  printf "  ${cyn}%-18s${rst}  %s\n" "widget-ref"   "statusline-widget-ref.html — widget reference"
  printf "  ${cyn}%-18s${rst}  %s\n" "audit"        "sl-audit.sh — audit script"
  printf "  ${cyn}%-18s${rst}  %s\n" "cli"          "sl-cli.sh — dispatcher"
  echo ""
  printf "${dim}Usage: statusline open <target>${rst}\n"
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
  printf "${dim}Open with: ${rst}${cyn}[1]${rst} code  ${cyn}[2]${rst} nano  ${cyn}[3]${rst} google-chrome  ${cyn}[4]${rst} %s  ${cyn}[5]${rst} open ${dim}(default)${rst}  ${dim}[Enter] print path only${rst}\n" "$glow_cmd"
  printf "${dim}> ${rst}"

  local choice
  read -r choice </dev/tty 2>/dev/null
  choice="${choice:-}"

  case "$choice" in
    1|code)
      printf "${grn}↗${rst}  code %s\n" "$path"
      code "$path" 2>/dev/null || { printf "${red}✗${rst}  'code' not found\n" >&2; exit 1; }
      ;;
    2|nano)
      nano "$path"
      ;;
    3|chrome|google-chrome)
      printf "${grn}↗${rst}  google-chrome %s\n" "$path"
      open -a "Google Chrome" "$path" 2>/dev/null || \
        google-chrome "$path" 2>/dev/null || \
        { printf "${red}✗${rst}  Google Chrome not found\n" >&2; exit 1; }
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
        printf "${grn}↗${rst}  open %s\n" "$path"
        open "$path" 2>/dev/null
      fi
      ;;
    *)
      # Treat unknown input as a raw command name
      printf "${grn}↗${rst}  %s %s\n" "$choice" "$path"
      "$choice" "$path" 2>/dev/null || { printf "${red}✗${rst}  command not found: %s\n" "$choice" >&2; exit 1; }
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
  printf "${red}✗${rst}  Unknown target: '%s'\n" "$TARGET" >&2
  echo ""
  show_list
  exit 1
fi

if [[ ! -f "$path" ]]; then
  printf "${red}✗${rst}  File not found: %s\n" "$path" >&2
  exit 1
fi

prompt_program "$path"
