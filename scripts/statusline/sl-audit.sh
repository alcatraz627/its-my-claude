#!/usr/bin/env bash
# sl-audit.sh — Audit statusline configuration for known issues
# Usage: sl-audit.sh [--claude] [--profile <name>] [--fix <check>]
# Exit code: 0 = clean, 1 = warnings, 2 = critical failures

SL="${HOME}/.claude/scripts/statusline/statusline.sh"
CONF="${HOME}/.claude/statusline.conf"
PROFILE="${STATUSLINE_PROFILE:-custom}"
CLAUDE_MODE=0
FIX_CHECK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude)       CLAUDE_MODE=1; shift ;;
    --profile|-p)   PROFILE="$2"; shift 2 ;;
    --fix)          FIX_CHECK="$2"; shift 2 ;;
    *)              shift ;;
  esac
done

bold=$'\033[1m'; dim=$'\033[2m'; rst=$'\033[0m'
grn=$'\033[32m'; ylw=$'\033[33m'; red=$'\033[31m'; cyn=$'\033[36m'

_warnings=0
_failures=0

pass() { printf "  ${grn}✓${rst}  %-40s\n"  "$1"; }
warn() { printf "  ${ylw}⚠${rst}  %-40s  ${dim}%s${rst}\n" "$1" "${2:-}"; (( _warnings++ )) || true; }
fail() { printf "  ${red}✗${rst}  %-40s  ${dim}%s${rst}\n" "$1" "${2:-}"; (( _failures++ )) || true; }
info() { printf "  ${dim}·${rst}  %s\n" "$1"; }

section() { printf "\n${bold}%s${rst}\n" "$1"; }

echo ""
printf "${bold}Statusline Audit${rst}  ${dim}%s  profile: %s${rst}\n" "$(date '+%Y-%m-%d %H:%M')" "$PROFILE"

# ── 1. Syntax ──
section "Syntax"
if [[ ! -f "$SL" ]]; then
  fail "statusline.sh not found" "$SL"
elif bash -n "$SL" 2>/dev/null; then
  pass "statusline.sh parses cleanly (bash -n)"
else
  fail "SYNTAX ERROR in statusline.sh"
  bash -n "$SL" 2>&1 | head -5 | while read -r l; do info "  $l"; done
fi

# ── 2. Backup ──
section "Backup"
latest_bak=""
for bak in "${SL}.bak_1" "${SL}_bak" "${SL}.bak"; do
  [[ -f "$bak" ]] && latest_bak="$bak" && break
done
if [[ -n "$latest_bak" ]]; then
  age_days=$(( ( $(date +%s) - $(stat -f %m "$latest_bak" 2>/dev/null || echo 0) ) / 86400 ))
  pass "Backup exists: $(basename "$latest_bak") (${age_days}d old)"
else
  warn "No backup found" "Run: cp statusline.sh statusline.sh.bak_1"
fi

# ── 3. Profile ──
section "Profile"
if [[ -z "${STATUSLINE_PROFILE:-}" ]]; then
  warn "STATUSLINE_PROFILE not set" "Add 'export STATUSLINE_PROFILE=custom' to .zshrc"
else
  pass "STATUSLINE_PROFILE=${STATUSLINE_PROFILE}"
fi
if [[ ! -f "$CONF" ]]; then
  fail "statusline.conf not found" "$CONF"
elif grep -q "^\[${PROFILE}\]" "$CONF" 2>/dev/null; then
  pass "Profile [$PROFILE] found in statusline.conf"
else
  fail "Profile [$PROFILE] not in statusline.conf" "Available: $(grep -oE '^\[[a-z_]+\]' "$CONF" | tr -d '[]' | tr '\n' ' ')"
fi

# ── 4. Config key validity ──
section "Config Validity"
# All known segment keys
known_keys=" dir git model context agent session_id icons cost duration lines rate countdown cpu warn_200k thinking_effort tools wal ctx_comp uncommitted ext_changes scratchpad complexity turns network pm2 ports mcp pr sparkline depletion subagents timeline mem disk tok_speed git_stash uptime edit_ratio branch_age cost_vel focus_file test_status cache_hit cache_write out_ratio merge_conflicts files_touched runtime_ver cloud sudo tmux docker exit_code latency "
unknown_count=0
invalid_val_count=0
if [[ -f "$CONF" ]]; then
  in_profile=false
  while IFS= read -r line; do
    line="${line%%#*}"; line="${line//[[:space:]]/}"
    [[ -z "$line" ]] && continue
    if [[ "$line" == "[$PROFILE]" ]]; then in_profile=true; continue
    elif [[ "$line" == "["* ]]; then $in_profile && break; continue; fi
    $in_profile || continue
    key="${line%%=*}"; val="${line#*=}"
    [[ ! "$key" =~ ^[a-z_]+$ ]] && continue
    if ! echo "$known_keys" | grep -q " $key "; then
      warn "Unknown key: $key" "Not a recognized segment — may be ignored"
      (( unknown_count++ )) || true
    fi
    if ! [[ "$val" =~ ^(0|1|auto|nerd)$ ]]; then
      warn "Invalid value for $key: '$val'" "Must be: 0, 1, auto, or nerd"
      (( invalid_val_count++ )) || true
    fi
  done < "$CONF"
fi
[[ $unknown_count -eq 0 && $invalid_val_count -eq 0 ]] && pass "All config keys and values are valid"

# ── 5. Daemon data ──
section "Daemon Data"
PPID_SEARCH="${PPID:-0}"
stats_fresh=0
stats_age=""
# Find stats files (any PPID; we look for the freshest)
_sl_glob=$(ls /tmp/claude-statusline-* 2>/dev/null || true)
for f in $_sl_glob; do
  [[ -f "$f" ]] || continue
  age_s=$(( $(date +%s) - $(stat -f %m "$f" 2>/dev/null || echo 0) ))
  if [[ $stats_fresh -eq 0 || $age_s -lt ${_best_age:-9999} ]]; then
    _best_age=$age_s; stats_age="${age_s}s"
  fi
  stats_fresh=1
done
if [[ $stats_fresh -eq 1 ]]; then
  if (( _best_age < 30 )); then
    pass "Daemon data fresh (${stats_age} old)"
  elif (( _best_age < 120 )); then
    warn "Daemon data ${stats_age} old" "Daemon may be slow; normal under light use"
  else
    warn "Daemon data stale (${stats_age} old)" "Daemon may not be running — check process-stats-daemon.sh"
  fi
else
  warn "No daemon stats file at /tmp/claude-statusline-*" "System metrics (mem/disk/cpu) won't show until Claude session starts"
fi

# ── 6. Known-good patterns ──
section "Known Issues"

# _P9K_TTY /dev/* validation
if grep -qE '_P9K_TTY.*==/dev/' "$SL" 2>/dev/null || grep -q '== /dev/\*' "$SL" 2>/dev/null || \
   grep -qE '\"\$\{_P9K_TTY' "$SL" 2>/dev/null && grep -q '/dev/\*' "$SL" 2>/dev/null; then
  pass "_P9K_TTY /dev/* guard present (prevents 80-col fallback)"
else
  warn "_P9K_TTY validation unclear" "Check lines 211-220 in statusline.sh for /dev/* prefix guard"
fi

# head -5 cap on tool summary
if grep -qE 'tool_summary_wide.*\|.*head\s+-[0-9]' "$SL" 2>/dev/null || \
   grep -E 'head -[0-9]' "$SL" 2>/dev/null | grep -q 'tool_summary'; then
  warn "tool_summary_wide has a head -N cap" "Remove it — budget system handles truncation naturally"
else
  pass "tool_summary_wide is uncapped (budget handles truncation)"
fi

# has_mem threshold (should be 8192)
if grep -qE 'has_mem=0.*sys_free_mb.*lt 4096' "$SL" 2>/dev/null; then
  warn "has_mem threshold is 4096 MB" "Raise to 8192 for earlier triggering"
elif grep -qE 'sys_free_mb.*8192' "$SL" 2>/dev/null; then
  pass "has_mem threshold is 8192 MB"
else
  info "has_mem threshold: could not determine (check line ~431)"
fi

# has_disk threshold (should be 20)
if grep -qE 'disk_free_gb.*lt 10\b' "$SL" 2>/dev/null; then
  warn "has_disk threshold is 10 GB" "Raise to 20 for earlier triggering"
elif grep -qE 'disk_free_gb.*20\b' "$SL" 2>/dev/null; then
  pass "has_disk threshold is 20 GB"
else
  info "has_disk threshold: could not determine (check line ~432)"
fi

# 7d rate limit guard removed
if grep -qE 'r7.*gt 20\|r7.*-gt 20\|rate_7d.*20' "$SL" 2>/dev/null; then
  warn "7d rate limit has a >20% guard" "Remove guard to always show 7d usage"
else
  pass "7d rate limit always shown (no >20% guard)"
fi

# ── 7. Render server ──
section "Render Server"
if command -v nc &>/dev/null && nc -z -G 1 localhost 5081 2>/dev/null; then
  pass "Render server running (localhost:5081)"
else
  info "Render server not running (port 5081) — optional for testing"
  info "Start: node ~/.claude/assets/static/statusline-server.mjs"
fi

# ── 8. Stale temp files ──
section "Temp Files"
stale_count=0
_tmp_glob=$(ls /tmp/claude-* /tmp/statusline-* 2>/dev/null || true)
for f in $_tmp_glob; do
  [[ -f "$f" ]] || continue
  age_s=$(( $(date +%s) - $(stat -f %m "$f" 2>/dev/null || echo 0) ))
  (( age_s > 86400 )) && (( stale_count++ )) || true
done
if (( stale_count > 20 )); then
  warn "${stale_count} stale /tmp/claude-* files (> 24h)" "Consider: trash /tmp/claude-* /tmp/statusline-*"
else
  pass "Temp file count OK (${stale_count} stale > 24h)"
fi

# ── 9. Statusline.conf vs script consistency ──
section "Config Consistency"
# Check if conf has segments that don't exist in the script
if [[ -f "$CONF" && -f "$SL" ]]; then
  orphaned=0
  in_profile=false
  while IFS= read -r line; do
    line="${line%%#*}"; line="${line//[[:space:]]/}"
    [[ -z "$line" ]] && continue
    if [[ "$line" == "[$PROFILE]" ]]; then in_profile=true; continue
    elif [[ "$line" == "["* ]]; then $in_profile && break; continue; fi
    $in_profile || continue
    key="${line%%=*}"
    [[ ! "$key" =~ ^[a-z_]+$ || "$key" == "icons" || "$key" == "duration" ]] && continue
    # Check if seg_<key> appears in statusline.sh
    if ! grep -qE "seg_${key}[^a-z]" "$SL" 2>/dev/null; then
      warn "Config key '$key' has no matching seg_${key} in statusline.sh" "May be unused or renamed"
      (( orphaned++ )) || true
    fi
  done < "$CONF"
  [[ $orphaned -eq 0 ]] && pass "All config keys have matching seg_ variables in statusline.sh"
fi

# ── Summary ──
echo ""
printf "${bold}────────────────────────────────────────${rst}\n"
if [[ $_failures -eq 0 && $_warnings -eq 0 ]]; then
  printf "${grn}${bold}✓ Clean — no issues found${rst}\n"
elif [[ $_failures -eq 0 ]]; then
  printf "${ylw}${bold}⚠ ${_warnings} warning(s) — no critical failures${rst}\n"
else
  printf "${red}${bold}✗ ${_failures} failure(s), ${_warnings} warning(s)${rst}\n"
fi
echo ""

# ── Claude context block (only with --claude flag) ──
if [[ $CLAUDE_MODE -eq 1 ]]; then
  cat << 'CLAUDE_BLOCK'
---CLAUDE_ANALYSIS_REQUEST---
The audit above has been completed. Please:
1. Summarize the findings concisely (pass/warn/fail counts)
2. For each warning/failure, explain the root cause and provide a specific fix
3. If all checks pass, confirm the configuration is healthy and note any optional improvements
CLAUDE_BLOCK
fi

# Exit code reflects severity
[[ $_failures -gt 0 ]] && exit 2
[[ $_warnings -gt 0 ]] && exit 1
exit 0
