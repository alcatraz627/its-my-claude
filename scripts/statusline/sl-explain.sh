#!/usr/bin/env bash
# sl-explain.sh — Explain statusline widgets: what they show and when they fire
# Usage: sl-explain.sh [L1|L2|L3|L4|<widget-name>]
# Filter examples:
#   sl-explain.sh L2        — only L2 widgets
#   sl-explain.sh rate      — only the 'rate' widget
#   sl-explain.sh (none)    — full reference

FILTER="${1:-}"

bold=$'\033[1m'; dim=$'\033[2m'; rst=$'\033[0m'
grn=$'\033[32m'; ylw=$'\033[33m'; red=$'\033[31m'; cyn=$'\033[36m'; mag=$'\033[35m'

# Track current line for line-level filter
_current_line=""

# Print line header; return 1 if line is filtered out
begin_line() {
  local line_id="$1" desc="$2"
  _current_line="$line_id"
  # If filter is a line ID and doesn't match, suppress this line
  if [[ -n "$FILTER" && "$FILTER" == L* && "$FILTER" != "$line_id" ]]; then
    return 1
  fi
  printf "\n${bold}%-3s${rst} ${dim}— %s${rst}\n" "$line_id" "$desc"
  printf '%s\n' "──────────────────────────────────────────────────────────"
  return 0
}

# Print one widget row; respects filter
widget() {
  local name="$1" trigger="$2" desc="$3"

  # Line-level filter: if active and doesn't match current line, skip
  if [[ -n "$FILTER" && "$FILTER" == L* ]]; then
    [[ "$_current_line" != "$FILTER" ]] && return
  fi

  # Widget-level filter: partial name match
  if [[ -n "$FILTER" && "$FILTER" != L* ]]; then
    [[ "$name" != *"$FILTER"* ]] && return
  fi

  # Trigger color coding
  local tcol="$dim"
  case "$trigger" in
    always)   tcol="$grn" ;;
    auto)     tcol="$cyn" ;;
    phase*)   tcol="$ylw" ;;
  esac

  printf "  ${cyn}%-24s${rst} ${tcol}[%-16s${tcol}]${rst}  %s\n" "$name" "$trigger" "$desc"
}

echo ""
printf "${bold}Statusline Widget Reference${rst}"
if [[ -n "$FILTER" ]]; then
  printf "  ${dim}filter: %s${rst}" "$FILTER"
fi
printf "\n${dim}Trigger: ${grn}[always]${dim}=unconditional  ${cyn}[auto]${dim}=data/context dependent  ${ylw}[phase:X]${dim}=requires session depth${rst}\n"

# ─────────────────────────────────────────────────────────────────────────
begin_line "L1" "Identity / Performance — always rendered at top of statusline" && {
  widget "dir"              "always"          "Working dir basename, or git repo root name when in a repo"
  widget "git"              "always"          "Current git branch; turns red + dirty count when uncommitted changes"
  widget "model"            "always"          "Active Claude model display name (e.g. 'claude-sonnet-4-5')"
  widget "context"          "always"          "Context window remaining %: 10-char block bar + number. Turns red <20%"
  widget "warn_200k"        "auto"            "Alert badge when total tokens exceed 200K (signals context pressure)"
  widget "thinking_effort"  "auto"            "Current thinking mode shown as a filled bar: low/med/high/extended. Fades after 5min if no new requests"
}

# ─────────────────────────────────────────────────────────────────────────
begin_line "L2" "Rate / Session — rate limits, session metadata, tool activity" && {
  widget "rate"             "always"          "5h rate limit % + 7d rate limit % — both always shown when available"
  widget "countdown"        "auto"            "Minutes until 5h rate window resets (shown when rate > 0)"
  widget "tools"            "auto"            "Per-tool call counts: 'read:N edit:N bash:N grep:N ...' (full names at wide widths)"
  widget "turns"            "auto"            "Conversation turn counter — tracks how deep the session is"
  widget "agent"            "auto"            "Active agent name when running in agent/subagent mode"
  widget "wal"              "auto"            "WAL entries since last checkpoint; shown when > 8 (writing activity alert)"
  widget "session_id"       "auto"            "Short session ID (first 8 chars) for log correlation"
}

# ─────────────────────────────────────────────────────────────────────────
begin_line "L3" "Code / Services — git state, external services, environment context" && {
  widget "uncommitted"      "auto"            "Uncommitted file count (shown when > 2; turns yellow/red at higher counts)"
  widget "git_stash"        "auto"            "Stash entry count — shown when stash is non-empty"
  widget "merge_conflicts"  "auto"            "Files with unresolved merge conflicts (non-zero = shown)"
  widget "branch_age"       "auto"            "Days since branch diverged from main + commits-behind count"
  widget "pr"               "auto"            "Open PR number for the current branch (fetched by daemon)"
  widget "focus_file"       "auto"            "Most-edited file in session when edited ≥ 2 times"
  widget "scratchpad"       "auto"            "Active scratchpad entry count (from MCP scratchpad server)"
  widget "mcp"              "auto"            "Healthy MCP server count. Turns red when any server is down"
  widget "pm2"              "auto"            "pm2 process status: 'pm2:N' online, red when any errored"
  widget "network"          "auto"            "Offline alert, or latency: yellow > 200ms, red > 500ms"
  widget "exit_code"        "auto"            "Last bash tool exit code — shown only when non-zero (failed commands)"
  widget "ext_changes"      "auto"            "External file changes detected outside Claude's edits"
}

# ─────────────────────────────────────────────────────────────────────────
begin_line "L4" "Metadata / IDs — analytics, system resources, efficiency metrics" && {
  widget "cost"             "auto"            "Session cost in USD — shown when > \$0.05"
  widget "duration"         "auto"            "Total session wall-clock time"
  widget "lines"            "auto"            "Lines added / removed across all edits this session"
  widget "cpu"              "auto"            "Claude process CPU% + RSS MB — shown when CPU > 10% or RSS > 500MB"
  widget "mem"              "auto"            "Free system RAM — shown when < 8192 MB (system memory pressure)"
  widget "disk"             "auto"            "Free disk space — shown when < 20 GB"
  widget "tok_speed"        "auto"            "Token generation speed in tok/s (shown when > 50)"
  widget "uptime"           "auto"            "Session uptime derived from duration_ms"
  widget "edit_ratio"       "phase:active"    "Lines changed per 1K tokens — efficiency metric. Requires > 10 lines changed"
  widget "cost_vel"         "phase:active"    "Cost velocity in \$/min — burn rate. Shown when > \$0 and not early phase"
  widget "cache_hit"        "auto"            "Prompt cache hit ratio % — what fraction of input came from cache"
  widget "cache_write"      "auto"            "Prompt cache write ratio % — tokens being written to cache this turn"
  widget "out_ratio"        "auto"            "Output token % of total — shows how 'verbose' the model is"
  widget "files_touched"    "auto"            "File ops (Read + Edit + Write). T0 sessions: shows > 2; T1+: shows > 5"
  widget "runtime_ver"      "auto"            "Node version from .nvmrc or Python version from .python-version"
  widget "cloud"            "auto"            "Active cloud profile: AWS_PROFILE, GCLOUD_PROJECT, or AZURE_SUBSCRIPTION_ID"
  widget "sudo"             "auto"            "Shown when sudo credentials are active (sudo -n check passes)"
  widget "tmux"             "auto"            "Number of active tmux sessions"
  widget "docker"           "auto"            "Running Docker container count (only checked when daemon socket exists)"
  widget "subagents"        "auto"            "Active subagent count — entries < 5 min old from agents file"
  widget "test_status"      "auto"            "Last test run: pass/fail + count (written by test hook)"
  widget "timeline"         "auto"            "10-turn activity bar: tool calls per turn as block chars (▁▃▅▇)"
  widget "latency"          "auto"            "Hook execution latency in ms"
  widget "sparkline"        "auto"            "Context depletion trend sparkline"
  widget "depletion"        "auto"            "Estimated turns remaining before context full"
}

echo ""
printf "${dim}Line assignment: L1=identity, L2=rate+session, L3=code+services, L4=analytics${rst}\n"
printf "${dim}Budget system: segments are added in priority order; later segments cut first at narrow widths${rst}\n"
printf "${dim}Edit:  ~/.claude/statusline.conf | Docs: ~/.claude/assets/docs/statusline-dev-guide.md${rst}\n"
echo ""
