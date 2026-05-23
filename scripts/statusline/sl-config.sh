#!/usr/bin/env bash
# sl-config.sh — Show active statusline configuration
# Usage: sl-config.sh [--profile <name>] [--raw]

CONF="${HOME}/.claude/statusline.conf"
PROFILE="${STATUSLINE_PROFILE:-custom}"
RAW=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --raw)        RAW=1; shift ;;
    *)            shift ;;
  esac
done

# ── ANSI ──
bold=$'\033[1m'; dim=$'\033[2m'; rst=$'\033[0m'
grn=$'\033[32m'; ylw=$'\033[33m'; red=$'\033[31m'; cyn=$'\033[36m'; mag=$'\033[35m'

# Color-code a segment value
seg_color() {
  case "$1" in
    1)       printf "${grn}on  ${rst}" ;;
    0)       printf "${red}off ${rst}" ;;
    auto)    printf "${cyn}auto${rst}" ;;
    nerd)    printf "${ylw}nerd${rst}" ;;
    "not set") printf "${dim}----${rst}" ;;
    *)       printf "${dim}%-4s${rst}" "$1" ;;
  esac
}

# Parse the active profile into a temp file (bash 3.2 compatible — no declare -A)
_TMP_CONF=$(mktemp)
trap "rm -f '$_TMP_CONF'" EXIT

if [[ -f "$CONF" ]]; then
  in_profile=false
  while IFS= read -r line; do
    line="${line%%#*}"           # strip comments
    line="${line//[[:space:]]/}" # strip all whitespace
    [[ -z "$line" ]] && continue
    if [[ "$line" == "[$PROFILE]" ]]; then
      in_profile=true; continue
    elif [[ "$line" == "["* ]]; then
      $in_profile && break; continue
    fi
    $in_profile || continue
    key="${line%%=*}"; val="${line#*=}"
    [[ "$key" =~ ^[a-z_]+$ ]] && echo "${key}=${val}" >> "$_TMP_CONF"
  done < "$CONF"
fi

# Lookup helper: get value for a key from temp file (bash 3.2 safe)
seg_get() {
  local k="$1" result
  result=$(grep -m1 "^${k}=" "$_TMP_CONF" 2>/dev/null)
  if [[ -z "$result" ]]; then
    echo "not set"
  else
    echo "${result#*=}"
  fi
}

if [[ $RAW -eq 1 ]]; then
  sort "$_TMP_CONF"
  exit 0
fi

# Get available profiles
profiles=$(grep -oE '^\[[a-z_]+\]' "$CONF" 2>/dev/null | tr -d '[]' | tr '\n' ' ')

echo ""
printf "${bold}Statusline Config${rst}  ${dim}%s${rst}\n" "$CONF"
printf "Profile: ${bold}${ylw}%s${rst}   Available: ${dim}%s${rst}\n" "$PROFILE" "$profiles"

# ── Display grouped by category ──
# Format: name (padded), value (colored), description
show_group() {
  local group_name="$1"; shift
  printf "\n${bold}${dim}%s${rst}\n" "$group_name"
  for seg in "$@"; do
    val=$(seg_get "$seg")
    printf "  %-22s %s\n" "$seg" "$(seg_color "$val")"
  done
}

show_group "Core / Identity ────────────────────────────────" \
  dir git model context agent session_id icons

show_group "Cost / Performance ─────────────────────────────" \
  cost duration lines rate countdown cpu warn_200k thinking_effort

show_group "Agent-decided ──────────────────────────────────" \
  tools wal ctx_comp uncommitted ext_changes scratchpad complexity turns network

show_group "Contextual ─────────────────────────────────────" \
  pm2 ports mcp pr

show_group "Analytics ──────────────────────────────────────" \
  sparkline depletion subagents timeline

show_group "System / Environment ───────────────────────────" \
  mem disk tok_speed git_stash uptime

show_group "Efficiency / Insight ───────────────────────────" \
  edit_ratio branch_age cost_vel focus_file test_status

show_group "Token Analytics ────────────────────────────────" \
  cache_hit cache_write out_ratio

show_group "Git / Workflow ─────────────────────────────────" \
  merge_conflicts files_touched

show_group "Runtime / Environment ──────────────────────────" \
  runtime_ver cloud sudo

show_group "Environment Context ────────────────────────────" \
  tmux docker

show_group "Tool Telemetry ─────────────────────────────────" \
  exit_code latency

echo ""
printf "${dim}Values: ${grn}on${dim}=always  ${red}off${dim}=never  ${cyn}auto${dim}=context-dependent  ${dim}----=not in profile${rst}\n"
printf "${dim}Edit:   %s${rst}\n" "$CONF"
echo ""
