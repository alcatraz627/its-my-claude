#!/usr/bin/env bash
# Claude Code statusline v5: five category rows (who, spend, code, work, system)
# Config: ~/.claude/statusline.conf  |  Detail hint: /tmp/claude-detail-$PPID
# Daemon: ~/.claude/scripts/process-stats-daemon.sh (collects slow data every 4s)
# Layout and visual rules: ~/.claude/conventions/mods-handbook.md
#
# Flow: JSON stdin → parse → daemon read → conditions → five rows → print
# Each row starts with its category glyph. Optional segments appear only when
# they apply. Width: segments are dropped from the right end of a row as the
# terminal narrows, and low-value ones go first (see the show_* thresholds).

set -uo pipefail
# Note: set -e intentionally omitted — (( expr )) returns exit 1 when false,
# which kills the script under set -e. A statusline should never abort early.
shopt -s extglob  # enables *([0-9;]) patterns in ${var//} substitutions (used by _vlen)

# Segment widths are counted in characters, so the locale must be UTF-8.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in *[Uu][Tt][Ff]*) ;; *) export LC_CTYPE=en_US.UTF-8 ;; esac

input=$(cat)

# ── Colors ──
dim="\033[2m"  rst="\033[0m"  red="\033[31m"  grn="\033[32m"
ylw="\033[33m" blu="\033[34m" mag="\033[35m"  cyn="\033[36m"
bld="\033[1m"  wht="\033[37m"
sep="${dim} │ ${rst}"

_cpct() { # sets _c based on val vs warn/crit thresholds
  local v=$1 w=${2:-50} c=${3:-80}
  if (( v > c )); then _c="$red"; elif (( v > w )); then _c="$ylw"; else _c="$dim"; fi
}
_ccost() {
  local c=$1
  if (( c > 500 )); then _c="$red"; elif (( c > 200 )); then _c="$ylw"
  elif (( c > 50 )); then _c="$rst"; else _c="$dim"; fi
}
# Build a 10-char block bar from a 0-100 percentage
_bar10() {
  local pct=${1:-0} bar="" filled empty
  filled=$(( pct * 10 / 100 )); empty=$(( 10 - filled ))
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  printf '%s' "$bar"
}

# Pure-bash ANSI-stripping length — 0 subprocess forks (extglob enabled at top)
# Strips \e[Nm / \e[N;Mm color codes only. OSC 8 links: pass visible length explicitly.
# Result stored in _VLEN (global) to avoid subshell overhead.
_VLEN=0
_vlen() {
  local s="$1" _esc=$'\033'
  s="${s//${_esc}\[*([0-9;])m/}"
  _VLEN="${#s}"
}

# ── Load config ──
CONF="$HOME/.claude/statusline.conf"
PROFILE="${STATUSLINE_PROFILE:-custom}"

# Segment defaults (all auto)
seg_dir=1; seg_git=1; seg_model=1; seg_cost=auto
seg_lines=auto; seg_rate=auto; seg_countdown=auto; seg_cpu=auto
seg_warn_200k=auto; seg_context=1
# New always-on
seg_agent=auto; seg_session_id=auto
# New auto/model-decided
seg_tools=auto; seg_wal=auto
seg_uncommitted=auto; seg_ext_changes=auto; seg_scratchpad=auto
seg_turns=auto; seg_network=auto
# Contextual
seg_pm2=auto; seg_ports=auto; seg_mcp=auto; seg_pr=auto
# Subagent tracking
seg_subagents=auto
# Analytics / visualization
seg_timeline=auto
# New segments
seg_mem=auto; seg_disk=auto; seg_tok_speed=auto; seg_git_stash=auto; seg_uptime=auto
# Batch 2 — analytics / contextual
seg_edit_ratio=auto; seg_branch_age=auto; seg_cost_vel=auto; seg_focus_file=auto; seg_test_status=auto
# Batch 3 — new widgets
seg_cache_hit=auto; seg_merge_conflicts=auto; seg_cloud=auto
# Batch 4 — token analytics + runtime versions + session file ops + security
seg_cache_write=auto; seg_out_ratio=auto; seg_runtime_ver=auto; seg_files_touched=auto; seg_sudo=auto
# Batch 5 — environment context + tool telemetry
seg_tmux=auto; seg_docker=auto; seg_exit_code=auto; seg_latency=auto
# Batch 6 — decision-wizard: pages handed to the user, awaiting an answer
seg_decwait=auto

# Parse config
if [[ -f "$CONF" ]]; then
  in_profile=false
  while IFS= read -r line; do
    line="${line%%#*}"; line="${line// /}"
    [[ -z "$line" ]] && continue
    if [[ "$line" == "[$PROFILE]" ]]; then in_profile=true; continue
    elif [[ "$line" == "["* ]]; then $in_profile && break; continue; fi
    $in_profile || continue
    key="${line%%=*}"; val="${line#*=}"
    # Validate: key must be alphanumeric/underscore, val must be 0/1/auto/nerd
    [[ "$key" =~ ^[a-z_]+$ && "$val" =~ ^(0|1|auto|nerd)$ ]] && eval "seg_${key}=${val}" || true
  done < "$CONF"
fi

seg_on() {
  local val auto_val="${2:-1}"
  eval "val=\${seg_$1:-auto}"
  case "$val" in 1) return 0;; 0) return 1;; auto) [[ "$auto_val" == "1" ]] && return 0 || return 1;; esac
}

# ── Nerd Font Icons ──
# When icons=1 or icons=nerd, use Nerd Font glyphs for denser display
# Requires terminal with Nerd Font installed (FiraCode NF, JetBrains Mono NF, etc.)
use_icons=0
[[ "${seg_icons:-0}" == "1" || "${seg_icons:-0}" == "nerd" ]] && use_icons=1
# Icon definitions (safe fallbacks when icons=0)
if (( use_icons )); then
  # Prefer nf-fa/nf-pl (single-width) over nf-md (often double-width)
  # Every icon ends with a space for consistent "icon value" formatting
  ic_git=" "      # nf-pl-branch (U+E0A0) — git branch
  ic_model=" "     # nf-fa-code (U+F121) — model name
  ic_cost=" "      # nf-fa-dollar (U+F155) — cost
  ic_rate=" "      # nf-fa-tachometer (U+F0E4) — rate limit
  ic_cpu=" "      # nf-fa-microchip (U+F2DB) — cpu/mem
  ic_ctx=" "      # nf-fa-cogs (U+F085) — context window
  ic_wal=" "      # nf-fa-bookmark (U+F02E) — WAL entries
  ic_turn=" "     # nf-fa-repeat (U+F01E) — turns
  ic_pm2=" "      # nf-fa-server (U+F233) — pm2 procs
  ic_spark=" "     # nf-fa-line-chart (U+F201) — sparkline
  ic_agent=" "     # nf-fa-user-secret (U+F21B) — agent
  ic_warn=" "     # nf-fa-warning (U+F071) — 200k warn
  ic_net=" "      # nf-fa-globe (U+F0AC) — network
  ic_mem=" "     # nf-fa-database (U+F1C0) — memory
  ic_disk=" "      # nf-fa-hdd-o (U+F0A0) — disk
  ic_tspd=" "     # nf-fa-bolt (U+F0E7) — tok/speed
  ic_stash=" "     # nf-fa-archive (U+F187) — git stash
  ic_up=" "      # nf-fa-clock-o (U+F017) — uptime
  ic_eratio=" "    # nf-fa-pencil (U+F040) — edit ratio
  ic_branch=" "   # nf-fa-code-fork (U+F126) — branch age
  ic_burn=" "      # nf-fa-fire (U+F06D) — burn rate
  ic_focus=" "     # nf-fa-eye (U+F06E) — focus file
  ic_test=" "     # nf-fa-flask (U+F0C3) — test status
  ic_cache=" "   # nf-fa-database (U+F1C0) — cache hit ratio
  ic_cloud=" "   # nf-fa-cloud (U+F0C2) — cloud profile
else
  # ASCII fallbacks — short labels as icon stand-ins
  ic_git="git:"
  ic_model=""
  ic_cost="$ "
  ic_rate="5h: "
  ic_cpu="cpu:"
  ic_ctx="ctx:"
  ic_wal="W: "
  ic_turn="T: "
  ic_pm2="pm2: "
  ic_spark=""
  ic_agent=""
  ic_warn="! "
  ic_net="net: "
  ic_mem="mem: "
  ic_disk="dsk: "
  ic_tspd=""
  ic_stash="s: "
  ic_up="up: "
  ic_eratio="e/t: "
  ic_branch=""
  ic_burn="$/m: "
  ic_focus=""
  ic_test="tst: "
  ic_cache=""  # label is in widget text
  ic_cloud=""  # label is in widget text
fi

# ── Agent detail hint ──
# Agent writes "minimal"|"normal"|"full" to this file to control verbosity
DETAIL_FILE="/tmp/claude-detail-${PPID}"
detail="normal"
[[ -f "$DETAIL_FILE" ]] && detail=$(cat "$DETAIL_FILE" 2>/dev/null | tr -d '[:space:]') || true
[[ "$detail" != "minimal" && "$detail" != "full" ]] && detail="normal"

# ── Parse JSON ──
eval "$(echo "$input" | jq -r '
  "cwd=" + (.workspace.current_dir // "" | @sh),
  "remaining=" + (.context_window.remaining_percentage // "" | tostring | @sh),
  "model_name=" + (.model.display_name // "" | @sh),
  "cost_usd=" + (.cost.total_cost_usd // "" | tostring | @sh),
  "duration_ms=" + (.cost.total_duration_ms // "" | tostring | @sh),
  "lines_add=" + (.cost.total_lines_added // "" | tostring | @sh),
  "lines_rm=" + (.cost.total_lines_removed // "" | tostring | @sh),
  "rate_5h=" + (.rate_limits.five_hour.used_percentage // "" | tostring | @sh),
  "rate_7d=" + (.rate_limits.seven_day.used_percentage // "" | tostring | @sh),
  "rate_5h_resets=" + (.rate_limits.five_hour.resets_at // "" | tostring | @sh),
  "rate_7d_resets=" + (.rate_limits.seven_day.resets_at // "" | tostring | @sh),
  "exceeds_200k=" + (.exceeds_200k_tokens // false | tostring | @sh),
  "agent_name=" + (.agent.name // "" | @sh),
  "session_id=" + (.session_id // "" | @sh),
  "input_tokens=" + (.context_window.total_input_tokens // 0 | tostring | @sh),
  "output_tokens=" + (.context_window.total_output_tokens // 0 | tostring | @sh),
  "ctx_size=" + (.context_window.context_window_size // 0 | tostring | @sh),
  "transcript=" + (.transcript_path // "" | @sh),
  "thinking_effort=" + (.effort.level // .thinking_effort // "" | tostring | @sh),
  "model_id=" + (.model.id // "" | @sh),
  "cc_version=" + (.version // "" | tostring | @sh),
  "used_pct=" + (.context_window.used_percentage // "" | tostring | @sh),
  "api_ms=" + (.cost.total_api_duration_ms // "" | tostring | @sh),
  "cur_in=" + (.context_window.current_usage.input_tokens // 0 | tostring | @sh),
  "cache_read_tok=" + (.context_window.current_usage.cache_read_input_tokens // 0 | tostring | @sh),
  "cache_create_tok=" + (.context_window.current_usage.cache_creation_input_tokens // 0 | tostring | @sh),
  "pc_state=" + (.prompt_cache | if . == null then "" elif .caching_observed == false then "off" elif .warm == true then "warm" else "cold" end | @sh),
  "pc_expires=" + (.prompt_cache.expires_at // "" | tostring | @sh),
  "pc_hit=" + (.prompt_cache.hit_ratio | if . == null then "" else (. * 100 | floor | tostring) end | @sh),
  "pc_recache=" + (.prompt_cache.recache_tokens_if_cold // "" | tostring | @sh),
  "repo_host=" + (.workspace.repo.host // "" | @sh),
  "repo_owner=" + (.workspace.repo.owner // "" | @sh),
  "repo_name=" + (.workspace.repo.name // "" | @sh)
' 2>/dev/null)" || true

cwd="${cwd:-$(pwd)}"
shortdir="${cwd##*/}"; [[ -z "$shortdir" ]] && shortdir="/"

# Saves this render's raw stdin while ~/.claude/.statusline-capture exists, so
# segment work can read the exact field names Claude Code sends. Builtin write, no fork.
[[ -f "$HOME/.claude/.statusline-capture" ]] && printf '%s\n' "$input" > "/tmp/claude-statusline-stdin-${session_id:0:8}.json" 2>/dev/null

# ── Rate-limit debug capture (env-gated) ────────────────────────────────────
# Set STATUSLINE_RATELIMIT_DEBUG=1 in your shell to log every render's parsed
# rate-limit values. Used to confirm whether Claude Code's stdin JSON is
# feeding stale rate_limits.* fields (the suspected cause of the 7d lag).
if [[ "${STATUSLINE_RATELIMIT_DEBUG:-0}" == "1" ]]; then
  _rl_log="$HOME/.claude/logs/statusline-ratelimit.log"
  mkdir -p "${_rl_log%/*}" 2>/dev/null
  printf '[%s] sid=%s | rate_5h=%q rate_5h_resets=%q | rate_7d=%q rate_7d_resets=%q\n' \
    "$(date '+%F %T')" "${session_id:-unknown}" \
    "${rate_5h:-}" "${rate_5h_resets:-}" \
    "${rate_7d:-}" "${rate_7d_resets:-}" \
    >> "$_rl_log" 2>/dev/null || true
fi

# ── Terminal Width Detection ──
# Hook runs in a non-TTY subprocess — tput falls back to 80. Priority:
#   1. STATUSLINE_COLS: explicit override (render server / testing)
#   2. _P9K_TTY: real terminal device stored by Powerlevel10k
#   3. COLUMNS: shell env var (if > 0)
#   4. tput cols: last-resort fallback
cols=0
_width_src="none"
_width_p9k_raw=""; _width_columns_raw="${COLUMNS:-}"; _width_tput_raw=""
if [[ "${STATUSLINE_COLS:-0}" -gt 0 ]]; then
  cols=$STATUSLINE_COLS; _width_src="STATUSLINE_COLS"
else
  # Only use P9K vars if they look like device paths (P9K_TTY may be set to "old" in non-SSH sessions)
  _real_tty=""
  [[ "${_P9K_TTY:-}" == /dev/* ]] && _real_tty="$_P9K_TTY"
  [[ -z "$_real_tty" && "${_P9K_SSH_TTY:-}" == /dev/* ]] && _real_tty="$_P9K_SSH_TTY"
  if [[ -n "$_real_tty" && -r "$_real_tty" ]]; then
    _width_p9k_raw=$(stty size < "$_real_tty" 2>/dev/null | awk '{print $2}')
    if [[ "${_width_p9k_raw:-0}" -gt 0 ]]; then
      cols=$_width_p9k_raw; _width_src="p9k_tty:$_real_tty"
    fi
  fi
  if [[ "${cols:-0}" -le 0 && "${COLUMNS:-0}" -gt 0 ]]; then
    cols=$COLUMNS; _width_src="COLUMNS"
  fi
  if [[ "${cols:-0}" -le 0 ]]; then
    # No reliable width signal. Default to the universally-safe 80 (NOT 120):
    # in a non-TTY hook with no P9K/COLUMNS, we cannot know the live pane width,
    # and an over-wide assumption causes line-wrap → Claude Code's wrap-blind
    # redraw overwrites scrollback. 80 fits any real terminal; richer detail
    # returns automatically once a real signal (P9K_TTY/COLUMNS) is present.
    _width_tput_raw=$(tput cols 2>/dev/null || echo 80)
    cols=$_width_tput_raw; _width_src="tput_or_fallback"
  fi
  # v4 cap: reserve right margin for Claude Code's own status labels
  # (model name + token count shown at the right edge of Claude Code's UI, ~40 chars).
  # Only apply at wide terminals where the UI labels are visible.
  # Render server (STATUSLINE_COLS) bypasses this entirely.
  if (( cols > 160 )); then
    cols=$(( cols - 10 ))   # narrow right-margin reserve for Claude Code UI labels
  fi
  # Only scale down truly ultra-wide displays (monitors > 240 cols)
  if (( cols > 240 )); then cols=$(( cols * 90 / 100 )); fi
  # No cap below 160 — standard terminals use full width
fi
[[ "${cols:-0}" -lt 60 ]] && cols=60

# Opt-in width-detection debug log. Enable with STATUSLINE_WIDTH_DEBUG=1 to
# diagnose wrap/scrollback-corruption issues — captures EVERY candidate width
# source so a stale COLUMNS or mismatched _P9K_TTY shows up immediately. Off
# by default (zero cost). Log: ~/.claude/logs/statusline-width.log
if [[ "${STATUSLINE_WIDTH_DEBUG:-0}" == "1" ]]; then
  _wlog="$HOME/.claude/logs/statusline-width.log"
  mkdir -p "${_wlog%/*}" 2>/dev/null
  printf '[%s] cols=%d src=%s | P9K_TTY=%q stty=%q | COLUMNS=%q | tput=%q | session=%s\n' \
    "$(date '+%F %T')" "$cols" "$_width_src" \
    "${_P9K_TTY:-}" "${_width_p9k_raw:-}" \
    "${_width_columns_raw:-}" "${_width_tput_raw:-}" \
    "${session_id:-unknown}" >> "$_wlog" 2>/dev/null || true
fi

# ── IDE detection (VS Code lock file) ──
ide_name=""
for _il in "$HOME/.claude/ide/"*.lock; do
  [[ -f "$_il" ]] || continue
  _ilc=""; read -r -d '' _ilc < "$_il" 2>/dev/null || true
  [[ "$_ilc" =~ \"ideName\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && ide_name="${BASH_REMATCH[1]}"
  break
done

# ── Start daemon if needed (single-daemon-per-PPID guard) ──
# Prior bug: concurrent statusline renders (rapid turns, streaming updates)
# both saw !STATS_FILE and both spawned a daemon — over a long session this
# accumulated 5+ daemons per claude PID. The pgrep gate closes the race by
# checking against the kernel-side process table (atomic enough that the
# window shrinks from ms-scale file-stat to µs-scale syscall). The trailing
# space in the pattern prevents PID-prefix matches (e.g. 80 vs 8000).
STATS_FILE="/tmp/claude-statusline-${PPID}"
DAEMON="$HOME/.claude/scripts/process-stats-daemon.sh"
# Tell the daemon which session this is (it looks up the ipc alias from it).
[[ -n "${session_id:-}" ]] && printf '%s' "$session_id" > "/tmp/claude-sidfwd-${PPID}" 2>/dev/null
if [[ ! -f "$STATS_FILE" ]] && [[ -x "$DAEMON" ]]; then
  if ! pgrep -f "process-stats-daemon.sh ${PPID} " >/dev/null 2>&1; then
    nohup bash "$DAEMON" "$PPID" "$STATS_FILE" &>/dev/null &
    disown
  fi
fi

# ── Read daemon data (key=value file → source it directly) ──
proc_cpu=0; proc_rss=0; proc_mem=0; git_uncommitted=0; git_ahead=0; git_behind=0; git_pr=""
pm2_online=0; pm2_errored=0; wal_since_checkpoint=0; net_latency=""; scratchpad_count=0
ext_changes=0; ports_up=""
mcp_healthy=""; mcp_down=""; complexity_df=0; complexity_dl=0
sys_free_mb=0; sys_total_mb=0; disk_free_gb=0; git_stash=0; tok_speed=0
branch_age_days=0; branch_behind=0; cost_vel_cpm=0; focus_file=""; focus_count=0
test_status=""; test_total=0; test_failed=0
net_rx_kbps=0; net_tx_kbps=0
sudo_active=0; tmux_sessions=0; ipc_unseen=""; dec_count=0
if [[ -f "$STATS_FILE" ]]; then
  # Only accept lines matching a safe key=value pattern (alphanumeric keys, no
  # shell metacharacters in values). Pure bash: no grep or eval fork.
  _kvre='^([a-z_]+)=([A-Za-z0-9_.,:/ -]*)$'
  while IFS= read -r _kvl || [[ -n "$_kvl" ]]; do
    [[ "$_kvl" =~ $_kvre ]] && printf -v "${BASH_REMATCH[1]}" '%s' "${BASH_REMATCH[2]}"
  done < "$STATS_FILE"
fi

# ── Read tool call counters (pure bash: no grep/sort/awk forks) ──
# The file holds KEY=count lines (B=61, R=40, _total=140). Names are widened and
# coloured per tool; the busiest tool comes first.
_lc() { # lower-case $1 into _LC without a fork
  _LC="$1"
  local _u
  for _u in A:a B:b C:c D:d E:e F:f G:g H:h I:i J:j K:k L:l M:m N:n O:o P:p Q:q R:r S:s T:t U:u V:v W:w X:x Y:y Z:z; do
    _LC="${_LC//${_u%:*}/${_u#*:}}"
  done
}
tool_summary_wide=""; tool_total=""; files_touched=0
TOOL_FILE="/tmp/claude-tools-${PPID}"
if [[ -f "$TOOL_FILE" ]]; then
  _tk=(); _tn=(); _tfr=0; _tfe=0; _tfw=0
  shopt -s nocasematch
  while IFS='=' read -r _k _v || [[ -n "$_k" ]]; do
    [[ -z "$_k" ]] && continue
    if [[ "$_k" == "_total" ]]; then tool_total="$_v"; continue; fi
    [[ "$_v" =~ ^[0-9]+$ ]] || continue
    _tk+=("$_k"); _tn+=("$_v")
    case "$_k" in r|read) _tfr=$_v;; e|edit) _tfe=$_v;; w|write) _tfw=$_v;; esac
  done < "$TOOL_FILE"
  files_touched=$(( _tfr + _tfe + _tfw ))
  _nt=${#_tk[@]}; _picked=" "
  for ((_a=0; _a<_nt; _a++)); do
    _best=-1; _bv=-1
    for ((_b=0; _b<_nt; _b++)); do
      [[ "$_picked" == *" $_b "* ]] && continue
      if (( _tn[_b] > _bv )); then _bv=${_tn[_b]}; _best=$_b; fi
    done
    (( _best < 0 )) && break
    _picked+="$_best "
    _tname="${_tk[_best]}"
    case "$_tname" in
      r) _tname=read;; e) _tname=edit;; w) _tname=write;; b) _tname=bash;; g) _tname=glob;;
      gr) _tname=grep;; ag) _tname=agent;; sk) _tname=skill;; o) _tname=other;;
    esac
    _lc "$_tname"; _tname="$_LC"
    case "$_tname" in
      read) _tcol=$'\033[2;34m';; edit) _tcol=$'\033[2;33m';; write) _tcol=$'\033[2;35m';;
      bash) _tcol=$'\033[2;32m';; grep|glob) _tcol=$'\033[2;36m';; agent) _tcol=$'\033[2;33m';;
      skill) _tcol=$'\033[2;37m';; *) _tcol=$'\033[2m';;
    esac
    tool_summary_wide+="${_tcol}${_tname}:${_tn[_best]}"$'\033[0m '
  done
  shopt -u nocasematch
fi

# ── Read turn counter ──
turn_count=0
sid_short="${session_id:0:8}"
# Fallback: if session_id not in JSON, use parent PID as stable identifier
[[ -z "${sid_short:-}" ]] && sid_short="${PPID}"
TURN_FILE="/tmp/claude-turns-${sid_short}"
[[ -f "$TURN_FILE" ]] && { read -r turn_count < "$TURN_FILE" 2>/dev/null || true; }
[[ "$turn_count" =~ ^[0-9]+$ ]] || turn_count=0
# Epoch cached here, shared by subagents, countdowns and the rate-limit parser
_NOW=$(date +%s)

# ── Read active subagents ──
subagent_count=0; subagent_names=""
AGENTS_FILE="/tmp/claude-agents-${sid_short}"
if [[ -f "$AGENTS_FILE" ]]; then
  while IFS='|' read -r _aid atype ats; do
    age=$(( _NOW - ${ats:-0} ))
    (( age > 300 )) && continue  # skip stale entries
    (( subagent_count++ ))
    [[ -n "$subagent_names" ]] && subagent_names+=","
    subagent_names+="$atype"
  done < "$AGENTS_FILE"
fi

# ── Idle: how long since this session last did anything ──
# A refresh render (refreshInterval) carries the same numbers as the one before
# it, so "activity" is a change in API time, cost, tool count or output tokens.
# The first render after a quiet spell stamps the new moment.
_act_sig="${api_ms:-}:${cost_usd:-}:${tool_total:-}:${output_tokens:-}"
_IDLE_FILE="/tmp/claude-idle-${PPID}"
_idle_ts=$_NOW; _idle_sig=""
[[ -f "$_IDLE_FILE" ]] && { read -r _idle_ts _idle_sig < "$_IDLE_FILE" 2>/dev/null || true; }
[[ "$_idle_ts" =~ ^[0-9]+$ ]] || _idle_ts=$_NOW
_act_changed=0
if [[ "$_act_sig" != "$_idle_sig" ]]; then
  _idle_ts=$_NOW; _act_changed=1
  printf '%s %s\n' "$_NOW" "$_act_sig" > "$_IDLE_FILE" 2>/dev/null || true
fi
render_lat_s=$(( _NOW - _idle_ts ))

# ── Activity bar: per-turn tool call delta ring buffer (10 turns → 10 chars) ──
# Appends only when the session did something, so refresh renders do not fill
# the ring with zeros.
TL_TURN_FILE="/tmp/statusline-tl-turns-${PPID}"   # ring buffer (10 entries)
TL_TURN_LAST="/tmp/statusline-tl-last-${PPID}"    # last seen total
_tl_current_total="${tool_total:-0}"
_tl_last_total=0
[[ -f "$TL_TURN_LAST" ]] && { read -r _tl_last_total < "$TL_TURN_LAST" 2>/dev/null || true; }
[[ "$_tl_last_total" =~ ^[0-9]+$ ]] || _tl_last_total=0
[[ "$_tl_current_total" =~ ^[0-9]+$ ]] || _tl_current_total=0
_tl_delta=$(( _tl_current_total - _tl_last_total ))
(( _tl_delta < 0 )) && _tl_delta=0
if (( _act_changed || _tl_delta > 0 )); then
  printf '%s\n' "$_tl_current_total" > "$TL_TURN_LAST" 2>/dev/null || true
  _tl_ring=()
  if [[ -f "$TL_TURN_FILE" ]]; then
    while IFS= read -r _tv || [[ -n "$_tv" ]]; do [[ "$_tv" =~ ^[0-9]+$ ]] && _tl_ring+=("$_tv"); done < "$TL_TURN_FILE"
  fi
  _tl_ring+=("$_tl_delta")
  (( ${#_tl_ring[@]} > 10 )) && _tl_ring=("${_tl_ring[@]: -10}")
  printf '%s\n' "${_tl_ring[@]}" > "$TL_TURN_FILE" 2>/dev/null || true
fi

# ── Git info (cached; refreshed every 10th turn, once per turn number) ──
# Cache keyed by PPID (stable for the Claude Code session, unlike $$ which changes each invocation)
git_branch=""; git_dirty="0"; git_conflicts=0; _git_cache_turn=-1
GIT_CACHE="/tmp/statusline-git-${PPID}"
_git_refresh=0
if [[ ! -f "$GIT_CACHE" ]]; then
  _git_refresh=1
else
  { read -r git_branch; read -r git_dirty; read -r git_conflicts; read -r _git_cache_turn; } < "$GIT_CACHE" 2>/dev/null || true
  # Every 10th turn catches branch changes; the turn number is stored so the
  # 30 s refresh renders on turn 10 do not re-run git each time.
  if (( (turn_count % 10) == 0 && turn_count > 0 )) && [[ "$_git_cache_turn" != "$turn_count" ]]; then
    _git_refresh=1
  fi
fi
if (( _git_refresh )); then
  git_branch=$(cd "$cwd" 2>/dev/null && git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null) || true
  git_dirty=$(cd "$cwd" 2>/dev/null && git -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null | wc -l | tr -d ' ') || true
  git_conflicts=$(cd "$cwd" 2>/dev/null && git -c core.useBuiltinFSMonitor=false diff --name-only --diff-filter=U 2>/dev/null | wc -l | tr -d ' ') || true
  printf '%s\n%s\n%s\n%s\n' "${git_branch:-}" "${git_dirty:-0}" "${git_conflicts:-0}" "$turn_count" > "$GIT_CACHE" 2>/dev/null || true
fi
git_conflicts=${git_conflicts:-0}

# ── Session phase detection ──
# Phase determines which "insight" segments are worth showing:
#   early (turns<5, cost<$0.10): suppress efficiency metrics, they lack data
#   active (turns 5-20): show most segments
#   deep (turns>20 or cost>$1): show everything, including efficiency insights
total_tok=$(( ${input_tokens:-0} + ${output_tokens:-0} ))
total_lines_changed=$(( ${lines_add:-0} + ${lines_rm:-0} ))
session_phase="early"
[[ $turn_count -ge 5 ]] && session_phase="active"
[[ $turn_count -ge 20 ]] && session_phase="deep"

# ── Cross-session rate-limit freshness propagation ─────────────────────────
# Symptom this fixes: Claude Code refetches rate_limits at coarse intervals
# inside a long-running session, so the session's stdin JSON often carries
# values that are 5h/1d behind reality. Different sessions on the same
# account see different values at the same moment. New sessions boot with
# fresh values; long-running sessions stay stale.
#
# Mechanism: ~/.claude/widgets/.limits.json is already written by every
# statusline render (a few lines below). Read it FIRST and pick whichever
# of (own stdin, cached file) has a later `resets_at` timestamp. Since the
# 5h/7d windows are rolling, a fresher fetch produces a later resets_at —
# so resets_at is a free freshness proxy without needing a separate
# fetched_at timestamp.
#
# Net effect: the moment any session has fresh data, every other session
# picks it up on its next render. Architecture unchanged — same file,
# same daemon, same display segments. Only adds one file read per render.
_limits_file="$HOME/.claude/widgets/.limits.json"
_cached_r5=""; _cached_r5_resets=""; _cached_r7=""; _cached_r7_resets=""
if [[ -f "$_limits_file" ]]; then
  eval "$(jq -r '
    "_cached_r5=" + ((."5h".pct // "" | tostring) | @sh),
    "_cached_r5_resets=" + ((.resets_at // "") | @sh),
    "_cached_r7=" + ((.week.pct // "" | tostring) | @sh),
    "_cached_r7_resets=" + ((.resets_at_weekly // "") | @sh)
  ' "$_limits_file" 2>/dev/null)"
fi
# Parse a resets timestamp (empty, epoch int, or ISO datetime) to epoch.
#
# Returns 0 for "unknown", and a reset date more than ~14 days out counts as
# unknown: Claude Code sends 9999999999 when it does not know the reset time, and
# that is a sentinel, not a timestamp. Taken literally it parses to the year 2286
# — the largest epoch in play — so it always wins the "later resets_at is fresher"
# merge below, and a stale local value can override a genuinely fresher cached one
# indefinitely. Same 14-day plausibility bound the countdown guard uses.
_rl_to_epoch() {
  local v="$1" e now
  [[ -z "$v" || "$v" == "null" ]] && { echo 0; return; }
  if [[ "$v" =~ ^[0-9]+$ ]]; then e="$v"
  else e=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${v%%.*}" "+%s" 2>/dev/null \
       || date -d "${v%%.*}" "+%s" 2>/dev/null \
       || echo 0); fi
  [[ "$e" =~ ^[0-9]+$ ]] || { echo 0; return; }
  now="${_NOW:-$(date +%s)}"   # same render second as the rest of the script
  (( e > now + 1209600 )) && { echo 0; return; }
  echo "$e"
}
# 7d merge: pick freshest by two signals in priority order.
#
#   1. Later resets_at wins → handles window-roll case (own just rolled
#      into a new 7-day window, percentage dropped to ~0; cached still has
#      the old window's 80%). Without this, max-value would stick on 80%.
#   2. Within the same window (equal resets_at), higher percentage wins →
#      handles the common "halted session is 60% while running session is
#      61%" case. Usage in a rolling window essentially only goes up, so
#      a higher value is a fresher fetch.
#   3. Otherwise own value wins (status quo).
#
# Why not resets_at as the sole signal: empirically Claude Code seems to
# emit the SAME resets_at across all sessions in one window (it's the
# window-end clock-time, not a per-fetch shifting timestamp). Without the
# value comparison, the merge has no signal to discriminate same-window
# stale-vs-fresh values, which is the exact symptom we're fixing.
_own_r7_ep=$(_rl_to_epoch "${rate_7d_resets:-}")
_cached_r7_ep=$(_rl_to_epoch "$_cached_r7_resets")
_own_r7_int=$(printf '%.0f' "${rate_7d:-0}" 2>/dev/null || echo 0)
_cached_r7_int=$(printf '%.0f' "${_cached_r7:-0}" 2>/dev/null || echo 0)
_r7_ep=$_own_r7_ep   # epoch of whichever 7d reset wins the merge (0 = unknown)
if [[ -n "$_cached_r7" ]]; then
  if   (( _cached_r7_ep >  _own_r7_ep )); then
    rate_7d="$_cached_r7"; rate_7d_resets="$_cached_r7_resets"; _r7_ep=$_cached_r7_ep
  elif (( _cached_r7_ep == _own_r7_ep && _cached_r7_int > _own_r7_int )); then
    rate_7d="$_cached_r7"; rate_7d_resets="$_cached_r7_resets"; _r7_ep=$_cached_r7_ep
  fi
fi
# 5h merge: same shape. The 5h window is much shorter (5 hours) so
# window-rolls are more frequent and resets_at moves more often — but
# the value-comparison fallback handles same-window staleness regardless.
_own_r5_ep=$(_rl_to_epoch "${rate_5h_resets:-}")
_cached_r5_ep=$(_rl_to_epoch "$_cached_r5_resets")
_own_r5_int=$(printf '%.0f' "${rate_5h:-0}" 2>/dev/null || echo 0)
_cached_r5_int=$(printf '%.0f' "${_cached_r5:-0}" 2>/dev/null || echo 0)
_r5_ep=$_own_r5_ep
if [[ -n "$_cached_r5" ]]; then
  if   (( _cached_r5_ep >  _own_r5_ep )); then
    rate_5h="$_cached_r5"; rate_5h_resets="$_cached_r5_resets"; _r5_ep=$_cached_r5_ep
  elif (( _cached_r5_ep == _own_r5_ep && _cached_r5_int > _own_r5_int )); then
    rate_5h="$_cached_r5"; rate_5h_resets="$_cached_r5_resets"; _r5_ep=$_cached_r5_ep
  fi
fi

# ── Precompute conditions ──
# Cost: show when above $0.05 (skip trivial early-session costs)
has_cost=0; [[ -n "${cost_usd:-}" && "$cost_usd" != "null" && "$cost_usd" != "0" ]] && has_cost=1
has_lines=0; [[ -n "${lines_add:-}" && "${lines_add:-}" != "null" && ( "${lines_add:-0}" != "0" || "${lines_rm:-0}" != "0" ) ]] && has_lines=1
# ── Decision pages awaiting the user's answer (decision-wizard pending ledger) ──
# The daemon counts only unanswered pages whose config origin.project matches
# this directory, the same rule the gcc-mods status line uses.
has_decwait=0; decwait_n=0
[[ "${dec_count:-0}" =~ ^[0-9]+$ ]] && decwait_n=$dec_count
(( decwait_n > 0 )) && has_decwait=1
r5=0; has_rate=0; [[ -n "${rate_5h:-}" && "$rate_5h" != "null" ]] && { r5=$(printf "%.0f" "$rate_5h" 2>/dev/null || echo 0); has_rate=1; }
# Note: (( expr )) returns exit code 1 when false, which kills set -e.
# Use [[ ]] for all conditions, or guard with || true.
has_countdown=0; [[ $r5 -gt 0 && -n "${rate_5h_resets:-}" && "$rate_5h_resets" != "null" ]] && has_countdown=1
# Side-effect: write rate limits to widgets cache for claude-instances-bar
if (( has_rate )); then
  _r7_int=$(printf "%.0f" "${rate_7d:-0}" 2>/dev/null || echo 0)
  _limits_json="{\"5h\":{\"pct\":${r5},\"used\":0,\"cap\":0}"
  [[ $_r7_int -gt 0 ]] && _limits_json+=",\"week\":{\"pct\":${_r7_int},\"used\":0,\"cap\":0}"
  # Persist resets_at timestamps if available (ISO string or epoch).
  # `resets_at` is the 5h-window reset (existing); `resets_at_weekly` is the
  # 7d-window reset (new — read by claude-instances-bar's 7d countdown).
  if [[ -n "${rate_5h_resets:-}" && "$rate_5h_resets" != "null" ]]; then
    _limits_json+=",\"resets_at\":\"${rate_5h_resets}\""
  fi
  if [[ -n "${rate_7d_resets:-}" && "$rate_7d_resets" != "null" ]]; then
    _limits_json+=",\"resets_at_weekly\":\"${rate_7d_resets}\""
  fi
  _limits_json+="}"
  mkdir -p "$HOME/.claude/widgets" 2>/dev/null || true
  printf '%s' "$_limits_json" > "$HOME/.claude/widgets/.limits.json" 2>/dev/null || true
  # The whole rate_limits object as Claude Code sent it, so the Switchboard can
  # show any per-model window (fable, opus) the moment one appears.
  printf '%s' "$input" | jq -c '.rate_limits // empty' > "$HOME/.claude/widgets/.rate-limits-raw.json" 2>/dev/null || true
fi
# Thinking effort → percentage for visual bar
# Persist last seen non-zero effort for 10 minutes so the bar stays visible
# between requests even when thinking_effort field is absent from the hook JSON.
TE_PERSIST="/tmp/statusline-think-${PPID}"  # format: "pct timestamp"
_te_pct=0
case "${thinking_effort:-}" in
  low|Low|1)                       _te_pct=25 ;;
  medium|Medium|2)                 _te_pct=50 ;;
  high|High|3)                     _te_pct=75 ;;
  extended|Extended|xhigh|XHigh|turbo|max|Max|4|5) _te_pct=100 ;;
esac
if (( _te_pct > 0 )); then
  printf '%d %d\n' "$_te_pct" "$_NOW" > "$TE_PERSIST" 2>/dev/null || true
elif [[ -f "$TE_PERSIST" ]]; then
  # Read persisted value; use it if <10 min old
  read -r _te_pct_saved _te_ts_saved < "$TE_PERSIST" 2>/dev/null || true
  _te_age=$(( _NOW - ${_te_ts_saved:-0} ))
  if (( _te_age < 600 )); then
    _te_pct=${_te_pct_saved:-0}
    # Fade: dim the bar color based on age (fresh=bright, old=very dim)
    _te_faded=$(( _te_age > 300 ? 1 : 0 ))  # >5 min = faded
  fi
fi
has_thinking=0; (( _te_pct > 0 )) && has_thinking=1
has_200k=0; [[ "${exceeds_200k:-}" == "true" ]] && has_200k=1
has_cpu=0; [[ $proc_cpu -gt 10 || $proc_rss -gt 500 ]] && has_cpu=1
has_agent=0; [[ -n "${agent_name:-}" ]] && has_agent=1
has_uncommitted=0; [[ $git_uncommitted -gt 2 ]] && has_uncommitted=1
has_pm2=0; [[ $pm2_online -gt 0 || $pm2_errored -gt 0 ]] && has_pm2=1
has_wal=0; [[ $wal_since_checkpoint -gt 8 ]] && has_wal=1
has_net=0; [[ "$net_latency" == "offline" ]] && has_net=1
[[ "$net_latency" =~ ^[0-9]+$ && $net_latency -gt 200 ]] && has_net=1
has_pr=0; [[ -n "$git_pr" ]] && has_pr=1
has_scratchpad=0; [[ $scratchpad_count -gt 0 ]] && has_scratchpad=1
has_subagents=0; [[ $subagent_count -gt 0 ]] && has_subagents=1
# System: only flag when genuinely concerning (was: any nonzero → now: actual thresholds)
has_mem=0; [[ $sys_free_mb -gt 0 && $sys_total_mb -gt 0 && $sys_free_mb -lt 8192 ]] && has_mem=1
has_disk=0; [[ ${disk_free_gb:-0} -gt 0 && ${disk_free_gb:-0} -lt 20 ]] && has_disk=1
has_stash=0; [[ $git_stash -gt 0 ]] && has_stash=1
has_tok_speed=0; [[ $tok_speed -gt 50 ]] && has_tok_speed=1
has_uptime=0; [[ -n "${duration_ms:-}" && "$duration_ms" != "null" && "$duration_ms" != "0" ]] && has_uptime=1
# Efficiency metrics — only meaningful after enough data accumulates
has_edit_ratio=0
[[ $total_lines_changed -gt 10 && $total_tok -gt 5000 && "$session_phase" != "early" ]] && has_edit_ratio=1
has_branch_age=0; [[ $branch_age_days -gt 1 || $branch_behind -gt 0 ]] && has_branch_age=1
has_cost_vel=0; [[ $cost_vel_cpm -gt 0 && "$session_phase" != "early" ]] && has_cost_vel=1
has_focus=0; [[ -n "$focus_file" && "$focus_file" != "0" && $focus_count -ge 2 ]] && has_focus=1
has_test=0
TEST_MARKER="/tmp/claude-test-${PPID}"
if [[ -f "$TEST_MARKER" ]]; then
  while IFS= read -r _tml || [[ -n "$_tml" ]]; do
    [[ "$_tml" =~ ^(test_status|test_total|test_failed)=([A-Za-z0-9_]*)$ ]] && printf -v "${BASH_REMATCH[1]}" '%s' "${BASH_REMATCH[2]}"
  done < "$TEST_MARKER"
  [[ -n "${test_status:-}" ]] && has_test=1
fi
# Detect external edits to statusline.sh (daemon compares checksum to session baseline)
has_script_changed=0; [[ "${script_changed:-0}" == "1" ]] && has_script_changed=1

# ── Cache hit ratio: Claude Code's own prompt_cache.hit_ratio ──
has_cache=0; cache_hit_pct=0
if [[ "${pc_hit:-}" =~ ^[0-9]+$ ]]; then
  cache_hit_pct=$pc_hit; has_cache=1
fi

# ── Cache write share of the last turn: cache_creation over all three input kinds ──
has_cache_write=0; cache_write_pct=0
_cr=${cache_read_tok:-0}; _cc=${cache_create_tok:-0}
_cur_total=$(( ${cur_in:-0} + _cc + _cr ))
if (( _cc > 0 && _cur_total > 0 )); then
  cache_write_pct=$(( _cc * 100 / _cur_total ))
  (( cache_write_pct > 0 )) && has_cache_write=1
fi

# ── Output token ratio (output / (input + output)) ──
has_out_ratio=0; out_ratio_pct=0
_ot=${output_tokens:-0}; _it=${input_tokens:-0}
if (( _ot > 0 && _it + _ot > 0 )); then
  out_ratio_pct=$(( _ot * 100 / (_it + _ot) ))
  (( out_ratio_pct > 0 )) && has_out_ratio=1
fi

# ── Merge conflicts ──
has_conflicts=0; (( git_conflicts > 0 )) && has_conflicts=1

# ── Active cloud profile (from launch-time environment) ──
cloud_provider=""; cloud_profile=""
if [[ -n "${AWS_PROFILE:-}" ]]; then
  cloud_provider="aws"; cloud_profile="${AWS_PROFILE}"
elif [[ -n "${AWS_DEFAULT_PROFILE:-}" ]]; then
  cloud_provider="aws"; cloud_profile="${AWS_DEFAULT_PROFILE}"
elif [[ -n "${GCLOUD_PROJECT:-}" ]]; then
  cloud_provider="gcp"; cloud_profile="${GCLOUD_PROJECT}"
elif [[ -n "${CLOUDSDK_CORE_PROJECT:-}" ]]; then
  cloud_provider="gcp"; cloud_profile="${CLOUDSDK_CORE_PROJECT}"
elif [[ -n "${AZURE_SUBSCRIPTION_ID:-}" ]]; then
  cloud_provider="az"; cloud_profile="${AZURE_SUBSCRIPTION_ID:0:8}"
fi
has_cloud=0; [[ -n "$cloud_provider" ]] && has_cloud=1

# ── Sudo credential active: checked by the daemon (up to 4 s late), not per render ──
has_sudo=0; [[ "${sudo_active:-0}" == "1" ]] && has_sudo=1

# ── Runtime version detection (reads .nvmrc / .python-version from project root) ──
# No subprocess forks — pure bash file reads. Checks cwd first, then walks up 2 levels.
node_ver=""; python_ver=""
_vcheck_dir="$cwd"
for _vd in "$_vcheck_dir" "${_vcheck_dir%/*}" "${_vcheck_dir%/*/*}"; do
  [[ -z "$node_ver" && -f "${_vd}/.nvmrc" ]] && { read -r node_ver < "${_vd}/.nvmrc" 2>/dev/null || true; node_ver="${node_ver#v}"; }
  [[ -z "$python_ver" && -f "${_vd}/.python-version" ]] && { read -r python_ver < "${_vd}/.python-version" 2>/dev/null || true; }
done
has_node_ver=0; [[ -n "$node_ver" ]] && has_node_ver=1
has_python_ver=0; [[ -n "$python_ver" ]] && has_python_ver=1

# ── Tmux session count (fast; only calls tmux if binary exists) ──
has_tmux=0; tmux_count=0
if [[ "${tmux_sessions:-0}" =~ ^[0-9]+$ && "${tmux_sessions:-0}" -gt 0 ]]; then
  tmux_count="$tmux_sessions"; has_tmux=1
fi

# ── Docker running containers — daemon-guarded to avoid slow timeout ──
# Only run docker ps if the Unix socket exists (confirms daemon is up).
# docker ps hangs ~10s if daemon is unreachable; socket check is instant.
# timeout 2 prevents hangs if socket exists but daemon is stalled.
has_docker=0; docker_count=0
if [[ -S /var/run/docker.sock ]] && command -v docker &>/dev/null; then
  _dc=$(timeout 2 docker ps -q 2>/dev/null | wc -l | tr -d ' ')
  [[ "$_dc" =~ ^[0-9]+$ ]] && docker_count="$_dc" && has_docker=1 || true
fi

# ── Last bash exit code (written by exit-code-hook.sh PostToolUse) ──
has_exit_code=0; last_exit_code=0
_exit_file="/tmp/claude-last-exit-${PPID}"
if [[ -f "$_exit_file" ]]; then
  _ec=""; read -r _ec < "$_exit_file" 2>/dev/null || true
  [[ "$_ec" =~ ^[0-9]+$ ]] && last_exit_code="$_ec" && has_exit_code=1 || true
fi

# Idle (time since the session last did anything) is computed above, with the
# activity signature, so refresh renders do not reset it.
has_latency=0; (( render_lat_s >= 60 )) && has_latency=1

# ── Animation: event-tick spinner (advances on every hook invocation) ──
_SPIN=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
_spin_ctr=$(( ${tool_call_count:-0} + turn_count ))
_sf=$(( _spin_ctr % 10 ))
_spin="${_SPIN[$_sf]}"

# Daemon side-effect writes (cost/token forwarding for ring buffers)
CTX_FILE="/tmp/claude-ctx-${PPID}"
[[ -n "${remaining:-}" && "$remaining" != "null" ]] && printf "%.0f" "$remaining" > "$CTX_FILE" 2>/dev/null || true
TOK_FILE="/tmp/claude-tokens-${PPID}"
(( total_tok > 0 )) && echo "$total_tok" > "$TOK_FILE" 2>/dev/null || true
COST_FWD="/tmp/claude-cost-${PPID}"
[[ -n "${cost_usd:-}" && "$cost_usd" != "null" ]] && echo "$cost_usd" > "$COST_FWD" 2>/dev/null || true
TPATH_FWD="/tmp/claude-tpath-${PPID}"
[[ -n "${transcript:-}" ]] && echo "$transcript" > "$TPATH_FWD" 2>/dev/null || true

# ══════════════════════════════════════════════════════════════════════
# RENDERING: five rows, each led by its category glyph.
#   who    dir, ide, model + effort, ipc, sid, up, idle
#   spend  context, cache, 5h/wk limits, cost, ping + hit, out share
#   code   branch, changed, lines, conflicts, stash, notes, tests, PR, runtimes
#   work   agents, tools, focus, decisions, checkpoint drift, exit, eff, speed
#   system cpu, mem, net, disk, ports, pm2, mcp, cloud, sudo, tmux, docker, act
# Visual rules: conventions/mods-handbook.md (chips, colour, glyphs, links).
# Escapes are real ESC bytes so _vlen can measure them.
# ══════════════════════════════════════════════════════════════════════

_ESC=$'\033'
rst="${_ESC}[0m"; dim="${_ESC}[2m"; bld="${_ESC}[1m"
C_OK="${_ESC}[38;2;158;206;106m";   C_WARN="${_ESC}[38;2;224;175;104m"; C_BAD="${_ESC}[38;2;247;118;142m"
C_INFO="${_ESC}[38;2;125;207;255m"; C_LBL="${_ESC}[38;2;86;95;137m";    C_FAINT="${_ESC}[38;2;59;66;97m"
# Values sit in a muted foreground; only a value that earns it (the sid) uses the bright one.
C_FG="${_ESC}[38;2;154;165;206m";   C_STRONG="${_ESC}[38;2;192;202;245m"; C_WHITE="${_ESC}[38;2;255;255;255m"
C_WHO="${_ESC}[38;2;122;162;247m";  C_SPEND="${_ESC}[38;2;224;175;104m"; C_CODE="${_ESC}[38;2;187;154;247m"
C_WORK="${_ESC}[38;2;125;207;255m"; C_SYS="${_ESC}[38;2;115;122;162m"
BG_CHIP="${_ESC}[48;2;36;40;59m"
_SEP="${C_FAINT} │ ${rst}"

# Category glyphs (Nerd Font when icons=1, plain otherwise)
if (( use_icons )); then
  G_WHO=$'\xef\x80\x87'; G_SPEND='$'; G_CODE=$'\xee\x82\xa0'; G_WORK=$'\xef\x82\xad'; G_SYS=$'\xef\x8b\x9b'
  G_MAIL=$'\xef\x83\xa0'; G_CKPT=$'\xef\x83\x87'; G_DEC=$'\xef\x83\xa3'
else
  G_WHO='@'; G_SPEND='$'; G_CODE='⎇'; G_WORK='⚒'; G_SYS='▣'
  G_MAIL='✉'; G_CKPT='↻'; G_DEC='◆'
fi

# Width thresholds for optional segments. Dropped in this order as the
# terminal narrows: act, net, notes, eff, hit, ping, idle, up.
show_act=0;   (( cols >= 150 )) && show_act=1
show_net=0;   (( cols >= 140 )) && show_net=1
show_notes=0; (( cols >= 130 )) && show_notes=1
show_eff=0;   (( cols >= 120 )) && show_eff=1
show_hit=0;   (( cols >= 110 )) && show_hit=1
show_ping=0;  (( cols >= 100 )) && show_ping=1
show_idle=0;  (( cols >= 90  )) && show_idle=1
show_up=0;    (( cols >= 80  )) && show_up=1

# Visible length of a string, ignoring colour codes and OSC 8 link wrappers.
_VLEN=0
_e1="${_ESC}["; _e2="${_ESC}]8;;"; _e3="${_ESC}\\"
# Plain loops, because extglob substitution is quadratic in bash 3.2.
_vlen() {
  local s="$1" pre
  while [[ "$s" == *"$_e1"* ]]; do pre=${s%%"$_e1"*}; s=${s#*"$_e1"}; s="${pre}${s#*m}"; done
  while [[ "$s" == *"$_e2"* ]]; do pre=${s%%"$_e2"*}; s=${s#*"$_e2"}; s="${pre}${s#*"$_e3"}"; done
  _VLEN=${#s}
}

# 380K, 1M, 1.5M
_hum() {
  local n=$1 t
  if (( n >= 1000000 )); then
    t=$(( (n + 50000) / 100000 ))
    if (( t % 10 == 0 )); then _H="$(( t / 10 ))M"; else _H="$(( t / 10 )).$(( t % 10 ))M"; fi
  elif (( n >= 1000 )); then _H="$(( (n + 500) / 1000 ))K"
  else _H="$n"; fi
}
# 45s, 21m, 1h30m, 3d2h
_dur() {
  local s=$1 m h
  if (( s < 60 )); then _D="${s}s"
  elif (( s < 3600 )); then _D="$(( s / 60 ))m"
  elif (( s < 86400 )); then
    h=$(( s / 3600 )); m=$(( (s % 3600) / 60 )); _D="${h}h"; if (( m > 0 )); then _D+="${m}m"; fi
  else
    h=$(( (s % 86400) / 3600 )); _D="$(( s / 86400 ))d"; if (( h > 0 )); then _D+="${h}h"; fi
  fi
}
# Clock time of an epoch, cached per tag so `date` runs only when the epoch changes.
_CLK=""
_clock() { # $1=format $2=epoch $3=tag
  local f="/tmp/claude-clk-${PPID}-$3" e="" t=""
  _CLK=""
  if [[ -f "$f" ]]; then read -r e t < "$f" 2>/dev/null || true; fi
  if [[ "$e" == "$2" && -n "$t" ]]; then _CLK="$t"; return; fi
  _CLK=$(date -r "$2" "+$1" 2>/dev/null || date -d "@$2" "+$1" 2>/dev/null || true)
  printf '%s %s\n' "$2" "$_CLK" > "$f" 2>/dev/null || true
}
_cents() { # "12.2231" -> _CC cents (integer)
  local c="$1"
  if [[ "$c" =~ ^([0-9]+)(\.([0-9]*))?$ ]]; then
    local f="${BASH_REMATCH[3]}00"
    _CC=$(( 10#${BASH_REMATCH[1]} * 100 + 10#${f:0:2} ))
  else
    _CC=$(awk -v c="$c" 'BEGIN{printf "%d", c * 100}')
  fi
}
_money() { printf -v _M '$%d.%02d' "$(( $1 / 100 ))" "$(( $1 % 100 ))"; }
_chip() { _CHIP="${BG_CHIP} $1 ${rst}"; }                      # soft background for live gauges
_link() { _LNK="${_ESC}]8;;$1${_ESC}\\$2${_ESC}]8;;${_ESC}\\"; } # OSC 8 hyperlink
_docurl() { # file path -> file:// link; the OS default app opens it (markdown goes to the browser)
  _URL="file://${1// /%20}"
}

# Row builder: segments are appended left to right; a segment that no longer
# fits ends the row there, so a row is never wider than the terminal.
_R_OUT=""; _R_LEN=0; _R_N=0; _R_FULL=0
_row_start() { _R_OUT="$2$1${rst} "; _R_LEN=2; _R_N=0; _R_FULL=0; }
_add() {
  (( _R_FULL )) && return 1
  [[ -z "$1" ]] && return 1
  _vlen "$1"
  local need=$(( _R_LEN + _VLEN + (_R_N > 0 ? 3 : 0) ))
  if (( need > cols )); then _R_FULL=1; return 1; fi
  if (( _R_N > 0 )); then _R_OUT+="$_SEP"; _R_LEN=$(( _R_LEN + 3 )); fi
  _R_OUT+="$1${rst}"; _R_LEN=$(( _R_LEN + _VLEN )); _R_N=$(( _R_N + 1 ))
  return 0
}
# %s, not %b: every escape here is a real byte, and %b would read the backslash
# of an OSC 8 terminator as the start of an octal escape ("ESC\" + "6 decisions").
_row_print() { if (( _R_N > 0 )); then printf '%s\n' "$_R_OUT"; fi; }

# ── ROW 1: who ─────────────────────────────────────────────────────
_row_start "$G_WHO" "$C_WHO"

if seg_on dir 1; then _add "${C_WHO}${bld}${shortdir}"; fi

if [[ -n "${ide_name:-}" ]]; then
  case "$ide_name" in *Visual*|*VS*Code*) _is="vsc";; *Cursor*) _is="cur";; *) _is="ide";; esac
  _add "${C_LBL}${_is}"
fi

# Model plus effort meter (▮▮▮▯ from effort.level)
if seg_on model 1 && [[ -n "${model_name:-}" ]]; then
  if (( cols >= 80 )); then _mn="$model_name"
  else
    case "$model_name" in *Opus*) _mn="Opus";; *Sonnet*) _mn="Snnt";; *Haiku*) _mn="Hiku";; *) _mn="${model_name:0:6}";; esac
    [[ "$model_name" == *"1M"* ]] && _mn+=" 1M"
  fi
  _mseg="${C_INFO}${ic_model}${_mn}"
  if seg_on thinking_effort "$has_thinking" && (( has_thinking )); then
    _pips=$(( _te_pct / 25 )); _pf=""; _pe=""
    for ((i=0; i<4; i++)); do if (( i < _pips )); then _pf+="▮"; else _pe+="▯"; fi; done
    if (( ${_te_faded:-0} )); then _mseg+=" ${C_LBL}${_pf}${_pe}"; else _mseg+=" ${C_FG}${_pf}${C_FAINT}${_pe}"; fi
  fi
  _add "$_mseg"
fi

if seg_on agent "$has_agent" && (( has_agent )); then
  _add "${C_WARN}[${agent_name}] ${_spin}"
fi

# ipc alias in purple; the mail icon is blue with unseen mail (or unknown), grey with none
if seg_on ipc 1 && [[ -n "${session_id:-}" ]]; then
  _ipc_alias=""; _ipc_f="${CLAUDE_IPC_HOME:-$HOME/.claude-ipc}/alias-by-sid/${session_id}"
  [[ -f "$_ipc_f" ]] && { read -r _ipc_alias < "$_ipc_f" 2>/dev/null || true; }
  if [[ -n "${_ipc_alias:-}" ]]; then
    _mc="$C_INFO"; [[ "${ipc_unseen:-}" == "0" ]] && _mc="$C_LBL"
    _add "${_mc}${G_MAIL} ${C_CODE}${_ipc_alias}"
  fi
fi

if seg_on session_id 1 && [[ -n "${sid_short:-}" ]]; then _add "${C_LBL}sid ${C_STRONG}${sid_short}"; fi

# Session age: white under 2 min, green under 1 h, yellow under 4 h, red after; a WTF chip past 2 days
if (( show_up )) && seg_on uptime "$has_uptime" && (( has_uptime )); then
  _up_sec=$(( ${duration_ms%.*} / 1000 ))
  _dur "$_up_sec"
  if (( _up_sec > 172800 )); then _chip "${C_BAD}${bld}up ${_D} WTF"; _add "$_CHIP"
  else
    if   (( _up_sec < 120 ));   then _uc="$C_WHITE"
    elif (( _up_sec < 3600 ));  then _uc="$C_OK"
    elif (( _up_sec < 14400 )); then _uc="$C_WARN"
    else                             _uc="$C_BAD"; fi
    _add "${C_LBL}up ${_uc}${_D}"
  fi
fi

# Idle: time since the session last did anything (not the gap between renders)
if (( show_idle )) && seg_on latency "$has_latency" && (( has_latency )); then
  _dur "$render_lat_s"
  if (( render_lat_s >= 1800 )); then _ic="$C_WARN"; else _ic="$C_FG"; fi
  _add "${C_LBL}idle ${_ic}${_D}"
fi
_row_print

# ── ROW 2: spend ───────────────────────────────────────────────────
_row_start "$G_SPEND" "$C_SPEND"

# Context: used percent and tokens, two-tone gauge with a tick at the 70% auto-compact line
_used=""
if [[ "${used_pct:-}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then _used=${used_pct%.*}
elif [[ -n "${remaining:-}" && "$remaining" != "null" ]]; then _used=$(( 100 - ${remaining%.*} )); fi
if seg_on context 1 && [[ -n "$_used" ]]; then
  (( _used < 0 )) && _used=0; (( _used > 100 )) && _used=100
  _ctok=$(( ${cur_in:-0} + ${cache_read_tok:-0} + ${cache_create_tok:-0} ))
  (( _ctok == 0 )) && _ctok=${input_tokens:-0}
  _hum "$_ctok"; _tk_s="$_H"; _hum "${ctx_size:-0}"; _win_s="$_H"
  if   (( _used >= 70 )); then _sc="$C_BAD"; elif (( _used >= 55 )); then _sc="$C_WARN"; else _sc="$C_FG"; fi
  _pct_s="${_used}%"; (( _used >= 90 )) && _pct_s="${_ESC}[5m${_pct_s}${_ESC}[25m"
  _ctext="${C_LBL}${ic_ctx}${_sc}${_pct_s}"
  (( ctx_size > 0 )) && _ctext+=" ${C_FG}${_tk_s}${C_LBL}/${_win_s}"
  _chip "$_ctext"; _cseg="$_CHIP"
  if   (( _used >= 70 )); then _gc="$C_BAD"; elif (( _used >= 55 )); then _gc="$C_WARN"; else _gc="$C_OK"; fi
  _fill=$(( _used * 10 / 100 )); _gauge=" "
  for ((i=0; i<10; i++)); do
    (( i == 7 )) && _gauge+="${C_LBL}┊"
    if (( i < _fill )); then _gauge+="${_gc}█"; else _gauge+="${C_FAINT}█"; fi
  done
  _cseg+="$_gauge"
  if (( _used >= 70 )) && [[ ! -f "/tmp/claude-compact-through/${session_id}" ]]; then _cseg+=" ${C_BAD}gate"; fi
  if (( _used >= 60 )); then _cseg+=" ${C_WARN}dump?"; fi
  _add "$_cseg"

  # Context history sparkline and turns-to-full estimate
  SPARK_FILE="/tmp/claude-sparkline-${PPID}"
  if (( cols >= 120 )) && seg_on sparkline 1 && [[ -f "$SPARK_FILE" ]]; then
    _spark_data=()
    while IFS= read -r _sv; do [[ -n "$_sv" ]] && _spark_data+=("$_sv"); done < "$SPARK_FILE"
    if (( ${#_spark_data[@]} >= 3 )); then
      _spark_str=""; _sblocks=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
      _spark_disp=("${_spark_data[@]}")
      (( ${#_spark_disp[@]} > 12 )) && _spark_disp=("${_spark_disp[@]: -12}")
      _spark_used=()
      for _sv in "${_spark_disp[@]}"; do
        _su=$(( 100 - _sv )); (( _su < 0 )) && _su=0; (( _su > 100 )) && _su=100
        _spark_used+=("$_su")
      done
      _sp_min=${_spark_used[0]}; _sp_max=${_spark_used[0]}
      for _su in "${_spark_used[@]}"; do
        (( _su < _sp_min )) && _sp_min=$_su
        (( _su > _sp_max )) && _sp_max=$_su
      done
      _sp_range=$(( _sp_max - _sp_min ))
      for _su in "${_spark_used[@]}"; do
        if (( _sp_range == 0 )); then _spark_str+="${_sblocks[3]}"
        else _spark_str+="${_sblocks[$(( (_su - _sp_min) * 7 / _sp_range ))]}"; fi
      done
      _l2_spark="${C_LBL}cxh ${_gc}${_spark_str}"
      if seg_on depletion 1 && (( ${#_spark_data[@]} >= 5 )); then
        _su_old=$(( 100 - ${_spark_data[$(( ${#_spark_data[@]} - 5 ))]} ))
        _su_new=$(( 100 - ${_spark_data[$(( ${#_spark_data[@]} - 1 ))]} ))
        _rdelta=$(( _su_new - _su_old ))
        if (( _rdelta > 2 )); then
          _rpp=$(( _rdelta * 100 / 5 ))
          if (( _rpp > 0 )); then
            _rl=$(( (100 - _su_new) * 100 / _rpp ))
            if (( _rl > 0 && _rl < 100 )); then
              if (( _rl < 5 )); then _dc="$C_BAD"; elif (( _rl < 15 )); then _dc="$C_WARN"; else _dc="$C_LBL"; fi
              _l2_spark+=" ${_dc}~${_rl}t"
            fi
          fi
        fi
      fi
      _add "$_l2_spark"
    fi
  fi
fi

# Cache clock: warm until prompt_cache.expires_at, or cold with the price of the next turn
if [[ "${pc_state:-}" == "warm" || "${pc_state:-}" == "cold" ]]; then
  _pc_exp=0; [[ "${pc_expires:-}" =~ ^[0-9]+ ]] && _pc_exp=${pc_expires%%.*}
  if [[ "$pc_state" == "warm" ]] && (( _pc_exp > _NOW )); then
    _left=$(( _pc_exp - _NOW )); _dur "$_left"
    if (( _left < 600 )); then _wc="$C_WARN"; else _wc="$C_FG"; fi
    _chip "${C_OK}●${C_FG} warm${C_LBL} · ${_wc}cold in ${_D}"
    _add "$_CHIP"
  else
    # Price: tokens x 2 (1 h cache write) x the model's input rate, from model-rates.tsv
    _price=""
    _rtok=${pc_recache:-0}; [[ "$_rtok" =~ ^[0-9]+$ && "$_rtok" -gt 0 ]] || _rtok=$(( ${cur_in:-0} + ${cache_read_tok:-0} + ${cache_create_tok:-0} ))
    _rates="${BASH_SOURCE[0]%/*}/model-rates.tsv"
    if [[ -n "${model_id:-}" && -f "$_rates" && "$_rtok" -gt 0 ]]; then
      while IFS=$'\t' read -r _rm _ri _ro; do
        [[ "$_rm" == "$model_id" ]] || continue
        if [[ "$_ri" =~ ^([0-9]+)(\.([0-9]+))?$ ]]; then
          _rf="${BASH_REMATCH[3]}00"; _rh=$(( 10#${BASH_REMATCH[1]} * 100 + 10#${_rf:0:2} ))
          _pcents=$(( _rtok * 2 * _rh / 1000000 ))
          if (( _pcents >= 1000 )); then _price="~\$$(( _pcents / 100 ))"; else _money "$_pcents"; _price="~${_M}"; fi
        fi
        break
      done < "$_rates"
    fi
    if [[ -n "$_price" ]]; then _chip "${C_WARN}○ cold${C_LBL} · ${C_WARN}re-cache ${_price}"
    else _chip "${C_WARN}○ cold"; fi
    _add "$_CHIP"
  fi
fi

# 5h and weekly limits with reset countdowns
if seg_on rate "$has_rate" && (( has_rate )); then
  if   (( r5 > 80 )); then _rc="$C_BAD"; elif (( r5 > 50 )); then _rc="$C_WARN"; else _rc="$C_FG"; fi
  _rp="${r5}%"; (( r5 >= 90 )) && _rp="${_ESC}[5m${_rp}${_ESC}[25m"
  _rseg="${C_LBL}5h ${_rc}${_rp}"
  if seg_on countdown "$has_countdown" && (( has_countdown )) && (( _r5_ep > _NOW )); then
    _dur "$(( _r5_ep - _NOW ))"; _rseg+=" ${C_LBL}↻${_D}"
    if (( cols >= 140 )); then
      _clock '%-I:%M%p' "$_r5_ep" r5; [[ -n "$_CLK" ]] && _rseg+=" ${C_LBL}${_CLK}"
    fi
  fi
  _chip "$_rseg"; _add "$_CHIP"
  if [[ -n "${rate_7d:-}" && "$rate_7d" != "null" ]]; then
    _r7=$(printf "%.0f" "$rate_7d" 2>/dev/null || echo 0)
    if   (( _r7 > 80 )); then _rc="$C_BAD"; elif (( _r7 > 50 )); then _rc="$C_WARN"; else _rc="$C_FG"; fi
    if (( _r7_ep > 0 && _r7_ep < _NOW )); then
      # The weekly window already expired: the number is stale, so mark it
      _wseg="${C_LBL}wk ${C_BAD}${_r7}%~"
    else
      _wseg="${C_LBL}wk ${_rc}${_r7}%"
      if (( _r7_ep > _NOW )); then _dur "$(( _r7_ep - _NOW ))"; _wseg+=" ${C_LBL}↻${_D}"; fi
    fi
    _chip "$_wseg"; _add "$_CHIP"
  fi
fi

# Cost: total and cents per turn; red with a ▲ when the context is past 200K
if seg_on cost "$has_cost" && (( has_cost )); then
  _cents "$cost_usd"; _cc_total=$_CC
  if (( has_200k || _cc_total > 500 )); then _cc_col="$C_BAD"
  elif (( _cc_total > 200 )); then _cc_col="$C_WARN"
  elif (( _cc_total > 50 )); then _cc_col="$C_FG"
  else _cc_col="$C_LBL"; fi
  _money "$_cc_total"
  _cstr="${C_LBL}${ic_cost}${_cc_col}${_M#\$}"
  (( has_200k )) && _cstr+="${bld} ▲${_ESC}[22m"
  if (( turn_count > 0 )); then
    _pt=$(( _cc_total / turn_count ))
    if (( _pt >= 100 )); then _money "$_pt"; _pts="${_M}/turn"; else _pts="${_pt}¢/turn"; fi
    _cstr+="${C_LBL} · ${C_FG}${_pts}"
  fi
  if (( cols >= 140 )) && seg_on cost_vel "$has_cost_vel" && (( cost_vel_cpm > 0 )); then
    _cstr+="${C_LBL} · ${C_FG}$(printf '$%d.%02d/min' "$(( cost_vel_cpm / 100 ))" "$(( cost_vel_cpm % 100 ))")"
  fi
  _chip "$_cstr"; _add "$_CHIP"
elif (( has_200k )); then
  _chip "${C_BAD}${bld}200K+"; _add "$_CHIP"
fi

# ping (next keep-warm wake) and cache hit ratio
_ph=""
if (( show_ping )) && [[ -f "$HOME/.claude/.keepwarm-on" && -n "${session_id:-}" ]]; then
  _kw=""; _kwf="$HOME/.claude/keepwarm/${session_id}.json"
  [[ -f "$_kwf" ]] && { read -r -d '' _kw < "$_kwf" 2>/dev/null || true; }
  if [[ -n "$_kw" && ! "$_kw" =~ \"stopped\":\ *true && "$_kw" =~ \"armed_at\":\ *([0-9]+) ]]; then
    _arm="${BASH_REMATCH[1]}"
    if (( _arm > _NOW )); then
      _clock '%H:%M' "$_arm" ping
      [[ -n "$_CLK" ]] && _ph="${C_LBL}ping ${C_FG}${_CLK}"
    fi
  fi
fi
if (( show_hit )) && seg_on cache_hit "$has_cache" && (( has_cache )); then
  if (( cache_hit_pct >= 80 )); then _hc="$C_OK"; elif (( cache_hit_pct >= 50 )); then _hc="$C_FG"; else _hc="$C_WARN"; fi
  [[ -n "$_ph" ]] && _ph+="${C_LBL} · "
  _ph+="${C_LBL}hit ${_hc}${cache_hit_pct}%"
fi
if (( show_hit )) && seg_on cache_write "$has_cache_write" && (( has_cache_write )); then
  [[ -n "$_ph" ]] && _ph+="${C_LBL} · "
  _ph+="${C_LBL}cw ${C_FG}${cache_write_pct}%"
fi
[[ -n "$_ph" ]] && _add "$_ph"

# Output share of all tokens (end of the row)
if (( cols >= 140 )) && seg_on out_ratio "$has_out_ratio" && (( has_out_ratio )); then
  if (( out_ratio_pct >= 30 )); then _oc="$C_WARN"; else _oc="$C_FG"; fi
  _add "${C_LBL}out ${_oc}${out_ratio_pct}%"
fi
_row_print

# ── ROW 3: code ────────────────────────────────────────────────────
_row_start "$G_CODE" "$C_CODE"

if seg_on git 1 && [[ -n "$git_branch" ]]; then
  _gb="${C_CODE}${git_branch}"; [[ "$git_dirty" != "0" ]] && _gb+="*"   # the row glyph already is the branch icon
  (( git_ahead > 0 )) && _gb+=" ${C_OK}↑${git_ahead}"
  (( git_behind > 0 )) && _gb+=" ${C_WARN}↓${git_behind}"
  _add "$_gb"
fi

if seg_on uncommitted "$has_uncommitted" && (( git_uncommitted > 2 )); then
  if (( git_uncommitted > 5 )); then _uc="$C_BAD"; else _uc="$C_WARN"; fi
  if (( git_uncommitted > 20 )); then _chip "${_uc}${git_uncommitted} changed"; _add "$_CHIP"
  else _add "${_uc}${git_uncommitted} changed"; fi
fi

if seg_on lines "$has_lines" && (( has_lines )); then
  _add "${C_OK}+${lines_add:-0}${C_BAD}-${lines_rm:-0}"
fi

if seg_on merge_conflicts "$has_conflicts" && (( has_conflicts )); then
  _chip "${C_BAD}${bld}${git_conflicts} conflicts"; _add "$_CHIP"
fi

if seg_on git_stash "$has_stash" && (( git_stash > 0 )); then
  if (( git_stash > 5 )); then _stc="$C_WARN"; else _stc="$C_FG"; fi
  _add "${C_LBL}stash ${_stc}${git_stash}"
fi

# notes: scratchpad entries as dots
if (( show_notes )) && seg_on scratchpad "$has_scratchpad" && [[ "$detail" != "minimal" ]] && (( scratchpad_count > 0 )); then
  if (( scratchpad_count >= 6 )); then _spc="$C_WARN"; else _spc="$C_FG"; fi
  if (( scratchpad_count <= 4 )); then
    _sp_dots=""; for ((i=0; i<scratchpad_count; i++)); do _sp_dots+="●"; done
    _add "${C_LBL}notes ${_spc}${_sp_dots}"
  else
    _add "${C_LBL}notes ${_spc}●●●● +$(( scratchpad_count - 4 ))"
  fi
fi

if seg_on test_status "$has_test" && (( has_test )); then
  if [[ "$test_status" == "pass" ]]; then _add "${C_OK}✓ ${test_total} tests"
  else _chip "${C_BAD}${bld}✗ ${test_failed}/${test_total} tests"; _add "$_CHIP"; fi
fi

if seg_on pr "$has_pr" && [[ -n "$git_pr" ]]; then
  if [[ -n "${repo_host:-}" && -n "${repo_owner:-}" && -n "${repo_name:-}" ]]; then
    _link "https://${repo_host}/${repo_owner}/${repo_name}/pull/${git_pr}" "PR #${git_pr}"
    _prs="${C_INFO}${_LNK}"; _vlen "$_prs"
  else _prs="${C_INFO}PR #${git_pr}"; fi
  _add "$_prs"
fi

if seg_on runtime_ver 1 && (( has_node_ver || has_python_ver )); then
  _rv=""
  if [[ -n "$node_ver" ]]; then _nv="${node_ver:0:7}"; _nv="${_nv%.}"; _rv+="${C_LBL}node ${C_FG}${_nv}"; fi
  if [[ -n "$python_ver" ]]; then
    _pv="${python_ver:0:7}"; _pv="${_pv%.}"
    [[ -n "$_rv" ]] && _rv+="${C_LBL} · "
    _rv+="${C_LBL}py ${C_FG}${_pv}"
  fi
  _add "$_rv"
fi

_ft_thresh=5; (( cols >= 140 )) && _ft_thresh=2
if seg_on files_touched 1 && (( files_touched > _ft_thresh )); then
  if (( files_touched > 50 )); then _ftc="$C_WARN"; else _ftc="$C_FG"; fi
  _add "${C_LBL}files ${_ftc}${files_touched}"
fi

# Claude Code version, from stdin
if [[ -n "${cc_version:-}" && "$cc_version" != "null" ]]; then _add "${C_LBL}cc ${C_FG}${cc_version}"; fi

if seg_on branch_age "$has_branch_age" && (( has_branch_age )); then
  _ba="${branch_age_days}d"; [[ $branch_behind -gt 0 ]] && _ba+=" ↓${branch_behind}"
  if (( branch_age_days > 7 || branch_behind > 20 )); then _bac="$C_BAD"
  elif (( branch_age_days > 3 || branch_behind > 10 )); then _bac="$C_WARN"
  else _bac="$C_FG"; fi
  _add "${C_LBL}br ${_bac}${_ba}"
fi

if seg_on ext_changes 1 && (( ${ext_changes:-0} > 5 )); then _add "${C_LBL}ext ${C_WARN}${ext_changes}"; fi
_row_print

# ── ROW 4: work ────────────────────────────────────────────────────
_row_start "$G_WORK" "$C_WORK"

# Agents running: a state dot, a count, and what kind
if seg_on subagents "$has_subagents" && (( subagent_count > 0 )); then
  _ag_u=(); _ag_c=(); _rest="${subagent_names},"
  while [[ -n "$_rest" ]]; do
    _an="${_rest%%,*}"; _rest="${_rest#*,}"; _found=-1
    for ((i=0; i<${#_ag_u[@]}; i++)); do [[ "${_ag_u[i]}" == "$_an" ]] && _found=$i; done
    if (( _found >= 0 )); then _ag_c[_found]=$(( ${_ag_c[_found]} + 1 ))
    else _ag_u+=("$_an"); _ag_c+=(1); fi
  done
  _ag_txt=""
  for ((i=0; i<${#_ag_u[@]} && i<3; i++)); do
    [[ -n "$_ag_txt" ]] && _ag_txt+=", "
    _ag_txt+="${_ag_u[i]} ×${_ag_c[i]}"
  done
  (( ${#_ag_u[@]} > 3 )) && _ag_txt+=", +$(( ${#_ag_u[@]} - 3 ))"
  _agw="agents"; (( subagent_count == 1 )) && _agw="agent"
  _chip "${C_INFO}◐${C_FG} ${subagent_count} ${_agw} ${C_LBL}(${_ag_txt})"; _add "$_CHIP"
fi

if seg_on turns 1 && (( turn_count > 10 )); then
  if (( turn_count > 30 )); then _tc="$C_WARN"; else _tc="$C_FG"; fi
  _add "${C_LBL}turns ${_tc}${turn_count}"
fi

# Tool counts keep their per-tool colours
if (( cols >= 100 )) && seg_on tools 1 && [[ -n "${tool_summary_wide:-}" ]]; then
  _add "${tool_summary_wide% }"
fi

# Focus file: opens in the doc viewer (md, txt) or as a file link
if seg_on focus_file "$has_focus" && (( has_focus )); then
  _ff="${focus_file##*/}"; (( ${#_ff} > 20 )) && _ff="${_ff:0:18}.."
  if (( focus_count >= 11 )); then _fc="$C_BAD"; elif (( focus_count >= 6 )); then _fc="$C_WARN"; else _fc="$C_FG"; fi
  _docurl "$focus_file"; _link "$_URL" "$_ff"
  _add "${C_LBL}focus ${_fc}${_LNK}${_fc} (${focus_count})"
fi

# Decision pages waiting for the owner (this project only)
if seg_on decwait "$has_decwait" && (( has_decwait )); then
  _dw="decisions"; (( decwait_n == 1 )) && _dw="decision"
  _link "http://localhost:5106/?view=decisions" "${decwait_n} ${_dw}"
  _chip "${C_INFO}${G_DEC} ${_LNK}"; _add "$_CHIP"
fi

# Checkpoint drift: log entries since the last checkpoint
if seg_on wal "$has_wal" && (( wal_since_checkpoint > 8 )); then
  if (( wal_since_checkpoint > 15 )); then _wc="$C_BAD"; else _wc="$C_WARN"; fi
  _chip "${_wc}${G_CKPT} ${wal_since_checkpoint} since checkpoint"; _add "$_CHIP"
fi

if seg_on exit_code "$has_exit_code" && (( has_exit_code && last_exit_code != 0 )); then
  _chip "${C_BAD}✗ exit ${last_exit_code}"; _add "$_CHIP"
fi

if (( show_eff )) && seg_on edit_ratio "$has_edit_ratio" && (( has_edit_ratio )); then
  _rx10=$(( total_lines_changed * 10000 / total_tok )); _ri=$(( _rx10 / 10 )); _rd=$(( _rx10 % 10 ))
  if (( _ri >= 5 )); then _erc="$C_OK"; elif (( _ri >= 1 )); then _erc="$C_FG"; else _erc="$C_WARN"; fi
  _add "${C_LBL}eff ${_erc}${_ri}.${_rd} lines/Kt"
fi

if seg_on tok_speed "$has_tok_speed" && (( tok_speed > 50 )); then
  if (( tok_speed > 500 )); then _tsc="$C_OK"; elif (( tok_speed > 200 )); then _tsc="$C_FG"; else _tsc="$C_WARN"; fi
  _add "${C_LBL}speed ${_tsc}${tok_speed} tok/s"
fi
_row_print

# ── ROW 5: system ──────────────────────────────────────────────────
_row_start "$G_SYS" "$C_SYS"

if seg_on cpu "$has_cpu" && (( has_cpu )); then
  if (( proc_cpu > 50 )); then _cpc="$C_BAD"; elif (( proc_cpu > 20 )); then _cpc="$C_WARN"; else _cpc="$C_FG"; fi
  _add "${C_LBL}cpu ${_cpc}${proc_cpu}%"
  if (( proc_rss > 0 )); then
    if (( proc_rss > 1000 )); then _mc="$C_BAD"; elif (( proc_rss > 500 )); then _mc="$C_WARN"; else _mc="$C_FG"; fi
    _add "${C_LBL}mem ${_mc}${proc_rss}MB"
  fi
fi

# net: throughput, plus API latency when it is slow
if (( show_net )) && seg_on network 1; then
  _nseg=""
  if (( net_rx_kbps > 5 || net_tx_kbps > 5 )); then
    if (( net_rx_kbps >= 1024 )); then _rx_s="$(( net_rx_kbps / 1024 ))M"; else _rx_s="${net_rx_kbps}K"; fi
    if (( net_tx_kbps >= 1024 )); then _tx_s="$(( net_tx_kbps / 1024 ))M"; else _tx_s="${net_tx_kbps}K"; fi
    _nseg="${C_LBL}net ${C_FG}↓${_rx_s} ↑${_tx_s}"
  fi
  if [[ "$net_latency" =~ ^[0-9]+$ ]] && (( net_latency > 200 )); then
    if (( net_latency > 500 )); then _nl_c="$C_BAD"; else _nl_c="$C_WARN"; fi
    [[ -n "$_nseg" ]] && _nseg+="${C_LBL} · "
    _nseg+="${C_LBL}api ${_nl_c}${net_latency}ms"
  fi
  [[ -n "$_nseg" ]] && _add "$_nseg"
fi
if seg_on network "$has_net" && [[ "$net_latency" == "offline" ]]; then
  _chip "${C_BAD}${bld}${ic_net}OFFLINE"; _add "$_CHIP"
fi

if seg_on mem "$has_mem" && (( has_mem )); then
  if (( sys_free_mb < 2048 )); then _fmc="$C_BAD"; elif (( sys_free_mb < 4096 )); then _fmc="$C_WARN"; else _fmc="$C_FG"; fi
  _add "${C_LBL}free ${_fmc}$(( sys_free_mb / 1024 )).$(( (sys_free_mb % 1024) * 10 / 1024 ))G"
fi

if seg_on disk "$has_disk" && (( has_disk )); then
  if (( disk_free_gb < 5 )); then _dkc="$C_BAD"; elif (( disk_free_gb < 10 )); then _dkc="$C_WARN"; else _dkc="$C_FG"; fi
  _add "${C_LBL}disk ${_dkc}${disk_free_gb}G"
fi

if seg_on ports 1 && [[ -n "${ports_up:-}" ]]; then _add "${C_LBL}ports ${C_OK}${ports_up}"; fi

if seg_on pm2 "$has_pm2" && (( has_pm2 )); then
  if (( pm2_errored > 0 )); then _chip "${C_BAD}pm2 ${pm2_online}up/${pm2_errored}err"; _add "$_CHIP"
  elif (( cols >= 100 )); then _add "${C_LBL}pm2 ${C_FG}${pm2_online} up"; fi
fi

if seg_on mcp 1 && [[ -n "$mcp_down" ]]; then
  _mt="${mcp_down//[^,]/}"; _mcp_dc=$(( ${#_mt} + 1 ))
  if (( _mcp_dc > 2 )); then _mcp_t="${_mcp_dc} down"
  elif (( _mcp_dc == 2 )); then _m1="${mcp_down%%,*}"; _m2="${mcp_down#*,}"; _mcp_t="${_m1:0:6}, ${_m2:0:6}"
  else _mcp_t="${mcp_down:0:10}"; fi
  _chip "${C_BAD}mcp ↓ ${_mcp_t}"; _add "$_CHIP"
elif seg_on mcp 1 && [[ -n "$mcp_healthy" ]] && [[ "$detail" == "full" ]]; then
  _mt="${mcp_healthy//[^,]/}"; _add "${C_LBL}mcp ${C_FG}$(( ${#_mt} + 1 )) ok"
fi

if seg_on cloud "$has_cloud" && (( has_cloud )); then
  _cp="${cloud_profile}"; [[ ${#_cp} -gt 16 ]] && _cp="${_cp:0:14}.."
  _add "${C_LBL}${cloud_provider} ${C_FG}${_cp}"
fi

if (( cols >= 100 )) && seg_on sudo "$has_sudo" && (( has_sudo )); then _add "${C_WARN}sudo"; fi
if seg_on tmux "$has_tmux" && (( has_tmux )); then _add "${C_LBL}tmux ${C_FG}${tmux_count}"; fi
if seg_on docker "$has_docker" && (( has_docker )); then
  if (( docker_count > 0 )); then _dk_c="$C_OK"; else _dk_c="$C_FG"; fi
  _add "${C_LBL}docker ${_dk_c}${docker_count}"
fi

(( has_script_changed )) && _add "${C_WARN}${ic_warn}statusline edited"

# act: tool calls per recent turn as a sparkline
if (( show_act )) && seg_on timeline 0; then
  _tl_data=()
  if [[ -f "$TL_TURN_FILE" ]]; then
    while IFS= read -r _tv || [[ -n "$_tv" ]]; do [[ "$_tv" =~ ^[0-9]+$ ]] && _tl_data+=("$_tv"); done < "$TL_TURN_FILE"
  fi
  while (( ${#_tl_data[@]} < 10 )); do _tl_data=("0" "${_tl_data[@]-}"); done
  (( ${#_tl_data[@]} > 10 )) && _tl_data=("${_tl_data[@]: -10}")
  _tl_max=1
  for _tv in "${_tl_data[@]}"; do [[ "$_tv" =~ ^[0-9]+$ ]] && (( _tv > _tl_max )) && _tl_max=$_tv; done
  _tl_str=""; _sblocks_act=("░" "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
  for _tv in "${_tl_data[@]}"; do
    [[ "$_tv" =~ ^[0-9]+$ ]] || _tv=0
    if (( _tv == 0 )); then _tl_str+="░"; else _tl_str+="${_sblocks_act[$(( _tv * 8 / _tl_max ))]}"; fi
  done
  _ltv=${_tl_data[9]}; [[ "$_ltv" =~ ^[0-9]+$ ]] || _ltv=0
  if (( _ltv > _tl_max / 2 )); then _tlc="$C_WARN"; elif (( _ltv > 0 )); then _tlc="$C_FG"; else _tlc="$C_FAINT"; fi
  _add "${C_LBL}act ${_tlc}${_tl_str}"
fi
_row_print
