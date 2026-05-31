#!/usr/bin/env bash
# Background daemon: collects all slow statusline data every 3-5 seconds
# Writes to /tmp/claude-statusline-$PPID as key=value pairs
# Started by statusline.sh on first render, self-terminates when parent dies

# Note: set -e intentionally omitted — (( expr )) returns exit 1 when false,
# which kills the daemon. Matches statusline.sh's documented rationale.
set -uo pipefail

TARGET_PID="${1:?Usage: process-stats-daemon.sh <pid> <output_file>}"
OUTPUT_FILE="${2:?Usage: process-stats-daemon.sh <pid> <output_file>}"
INTERVAL=4

kill -0 "$TARGET_PID" 2>/dev/null || exit 0

# ── Platform Compatibility ──
# All platform-specific calls are isolated here.
# To add a new platform: extend these functions only — no uname checks elsewhere.
_PLATFORM="$(uname -s)"

# _stat_mtime <file> → epoch seconds of last modification
_stat_mtime() {
  if [[ "$_PLATFORM" == "Darwin" ]]; then
    stat -f%m "$1" 2>/dev/null || echo 0
  else
    stat -c%Y "$1" 2>/dev/null || echo 0
  fi
}

# _df_free_gb <path> → free disk space in integer GB
_df_free_gb() {
  if [[ "$_PLATFORM" == "Darwin" ]]; then
    df -g "${1:-.}" 2>/dev/null | awk 'NR==2{print $4}'
  else
    df --block-size=1G "${1:-.}" 2>/dev/null | awk 'NR==2{gsub(/G/,"",$4); print $4}'
  fi
}

# _mem_free_mb → free/available system memory in MB (free + inactive on macOS)
_mem_free_mb() {
  if [[ "$_PLATFORM" == "Darwin" ]]; then
    local page_size; page_size=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
    local fp ip
    fp=$(vm_stat 2>/dev/null | awk '/Pages free/{gsub(/\./,"",$3); print $3}')
    ip=$(vm_stat 2>/dev/null | awk '/Pages inactive/{gsub(/\./,"",$3); print $3}')
    echo $(( (${fp:-0} + ${ip:-0}) * page_size / 1048576 ))
  else
    awk '/MemAvailable/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0
  fi
}

# _mem_total_mb → total installed RAM in MB
_mem_total_mb() {
  if [[ "$_PLATFORM" == "Darwin" ]]; then
    echo $(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1048576 ))
  else
    awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0
  fi
}

# _checksum <file> → SHA-256 hex digest (sha256sum on Linux, shasum on macOS)
_checksum() {
  if command -v sha256sum &>/dev/null; then
    sha256sum "$1" 2>/dev/null | cut -d' ' -f1
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1
  fi
}

# Resolve cwd from the Claude process
# Linux: use /proc/$PID/cwd (always available, no lsof dependency)
# macOS: use lsof (lsof is bundled; /proc not available on Darwin)
get_cwd() {
  if [[ "$_PLATFORM" == "Linux" && -L "/proc/$TARGET_PID/cwd" ]]; then
    readlink -f "/proc/$TARGET_PID/cwd" 2>/dev/null || pwd
  else
    lsof -p "$TARGET_PID" -Fn 2>/dev/null | grep '^n/' | head -1 | cut -c2- || pwd
  fi
}

# ── Script integrity baseline ──
# Record statusline.sh checksum at session start. Compared each loop iteration so
# script_changed=1 persists for the entire session if the file is externally edited.
_SCRIPT_PATH="$HOME/.claude/scripts/statusline/statusline.sh"
_ORIG_CKSUM_FILE="/tmp/claude-statusline-orig-cksum-${TARGET_PID}"
if [[ ! -f "$_ORIG_CKSUM_FILE" ]]; then
  _checksum "$_SCRIPT_PATH" > "$_ORIG_CKSUM_FILE" 2>/dev/null || true
fi

while kill -0 "$TARGET_PID" 2>/dev/null; do
  _NOW=$(date +%s)  # Single epoch timestamp for entire loop iteration
  tmp="${OUTPUT_FILE}.tmp"
  {
    # ── Process stats ──
    stats=$(ps -o %cpu=,%mem=,rss= -p "$TARGET_PID" 2>/dev/null | tr -s ' ') || true
    if [[ -n "$stats" ]]; then
      printf 'proc_cpu=%s\n' "$(echo "$stats" | awk '{printf "%.0f", $1}')"
      printf 'proc_mem=%s\n' "$(echo "$stats" | awk '{printf "%.0f", $2}')"
      printf 'proc_rss=%s\n' "$(echo "$stats" | awk '{printf "%.0f", $3/1024}')"
    fi

    # ── Git stats (uncommitted count, ahead/behind) ──
    cwd=$(get_cwd)
    if cd "$cwd" 2>/dev/null && timeout 2 git rev-parse --is-inside-work-tree &>/dev/null; then
      uncommitted=$(timeout 2 git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
      staged=$(timeout 2 git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
      printf 'git_uncommitted=%s\n' "$(( uncommitted + staged ))"

      # Ahead/behind
      ab=$(timeout 2 git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null) || true
      if [[ -n "$ab" ]]; then
        printf 'git_ahead=%s\n' "$(echo "$ab" | awk '{print $1}')"
        printf 'git_behind=%s\n' "$(echo "$ab" | awk '{print $2}')"
      fi

      # Open PR (check every 60s via a sub-cache)
      pr_cache="/tmp/claude-pr-${TARGET_PID}"
      branch=$(git branch --show-current 2>/dev/null) || true
      if [[ -n "$branch" ]]; then
        if [[ ! -f "$pr_cache" ]] || (( _NOW - $(_stat_mtime "$pr_cache") > 60 )); then
          pr_info=$(gh pr list --head "$branch" --json number,state --jq '.[0] // empty' 2>/dev/null) || true
          echo "${pr_info:-}" > "$pr_cache"
        fi
        pr_info=$(cat "$pr_cache" 2>/dev/null) || true
        if [[ -n "$pr_info" ]]; then
          pr_num=$(echo "$pr_info" | jq -r '.number // empty' 2>/dev/null) || true
          printf 'git_pr=%s\n' "${pr_num:-}"
        fi
      fi
    fi

    # ── pm2 status ──
    if command -v pm2 &>/dev/null; then
      pm2_json=$(pm2 jlist 2>/dev/null) || true
      if [[ -n "$pm2_json" && "$pm2_json" != "[]" ]]; then
        online=$(echo "$pm2_json" | jq '[.[] | select(.pm2_env.status=="online")] | length' 2>/dev/null) || true
        errored=$(echo "$pm2_json" | jq '[.[] | select(.pm2_env.status=="errored")] | length' 2>/dev/null) || true
        printf 'pm2_online=%s\n' "${online:-0}"
        printf 'pm2_errored=%s\n' "${errored:-0}"
      fi
    fi

    # ── WAL stats ──
    for wal_path in "$cwd/.claude/wal.md" "$HOME/.claude/wal.md"; do
      if [[ -f "$wal_path" ]]; then
        # Count entries since last CHECKPOINT
        since_chkpt=$(awk '/=== CHECKPOINT/{n=0} /^\[/{n++} END{print n}' "$wal_path" 2>/dev/null) || true
        printf 'wal_since_checkpoint=%s\n' "${since_chkpt:-0}"
        # Last checkpoint age
        last_ts=$(grep -o 'CHECKPOINT \[[0-9:]*\]' "$wal_path" | tail -1 | grep -o '[0-9:]*') || true
        if [[ -n "$last_ts" ]]; then
          printf 'wal_last_checkpoint=%s\n' "$last_ts"
        fi
        break
      fi
    done

    # ── Network probe (every 30s via sub-cache) ──
    net_cache="/tmp/claude-net-${TARGET_PID}"
    if [[ ! -f "$net_cache" ]] || (( _NOW - $(_stat_mtime "$net_cache") > 30 )); then
      latency=$(curl -so /dev/null -w '%{time_total}' --connect-timeout 2 --max-time 3 https://api.anthropic.com 2>/dev/null) || latency="offline"
      echo "$latency" > "$net_cache"
    fi
    net_val=$(cat "$net_cache" 2>/dev/null) || true
    printf 'net_latency=%s\n' "${net_val:-unknown}"

    # ── Network throughput (cumulative byte delta per interval → KB/s) ──
    # netstat -ib: cols 7=Ibytes, 10=Obytes per interface. Sum en0+en1 only.
    NET_BYTES_FILE="/tmp/claude-net-bytes-${TARGET_PID}"
    _nb=$(netstat -ib 2>/dev/null | awk '/^en[0-9]+[[:space:]]/ {rx+=$7; tx+=$10} END {print rx+0, tx+0}')
    _nb_rx=$(echo "$_nb" | awk '{print $1}')
    _nb_tx=$(echo "$_nb" | awk '{print $2}')
    if [[ -f "$NET_BYTES_FILE" ]]; then
      read -r _prev_rx _prev_tx _prev_ts < "$NET_BYTES_FILE" 2>/dev/null || { _prev_rx=0; _prev_tx=0; _prev_ts=1; }
      _dt=$(( _NOW - _prev_ts ))
      if (( _dt > 0 && _nb_rx >= _prev_rx && _nb_tx >= _prev_tx )); then
        _rx_rate=$(( (_nb_rx - _prev_rx) / _dt / 1024 ))
        _tx_rate=$(( (_nb_tx - _prev_tx) / _dt / 1024 ))
        printf 'net_rx_kbps=%s\n' "$_rx_rate"
        printf 'net_tx_kbps=%s\n' "$_tx_rate"
      fi
    fi
    echo "${_nb_rx:-0} ${_nb_tx:-0} $_NOW" > "$NET_BYTES_FILE" 2>/dev/null || true

    # ── Scratchpad size ──
    sp_count=0
    for sp_dir in "$cwd/.claude/scratchpad" "$HOME/.claude/scratchpad"; do
      if [[ -d "$sp_dir" ]]; then
        sp_count=$(find "$sp_dir" -maxdepth 2 -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
        break
      fi
    done
    printf 'scratchpad_count=%s\n' "$sp_count"

    # ── External file changes (files changed since session start) ──
    # Gated behind segment config — disabled by default (ext_changes=auto resolves to off)
    session_marker="/tmp/claude-session-start-${TARGET_PID}"
    if [[ ! -f "$session_marker" ]]; then
      touch "$session_marker"
    fi
    ext_changes=0
    EXT_CONF="/tmp/claude-ext-enabled-${TARGET_PID}"
    if [[ -f "$EXT_CONF" ]] && cd "$cwd" 2>/dev/null; then
      ext_changes=$(find . -maxdepth 3 -newer "$session_marker" -not -path './.git/*' -not -path './node_modules/*' -not -path './.next/*' -type f 2>/dev/null | wc -l | tr -d ' ')
    fi
    printf 'ext_changes=%s\n' "$ext_changes"

    # ── Port occupancy (only ports whose project dir matches current cwd) ──
    # Parses port-registry table rows: | Port | Service | Project | Ecosystem file | ...
    # Matches port to cwd by checking if the ecosystem file's directory == cwd (or parent).
    port_reg="$HOME/.claude/scratchpad/global/port-registry.md"
    ports_up=""
    if [[ -f "$port_reg" ]]; then
      while IFS='|' read -r _ port _ _ ecosystem _; do
        port=$(echo "$port" | tr -d ' ')
        [[ ! "$port" =~ ^[0-9]{4,5}$ ]] && continue
        ecosystem=$(echo "$ecosystem" | tr -d ' ' | sed "s|^~|$HOME|")
        proj_dir=$(dirname "$ecosystem" 2>/dev/null)
        # Show port only when cwd is at or under the project directory
        [[ "$cwd" == "$proj_dir" || "$cwd" == "$proj_dir/"* ]] || continue
        if nc -z localhost "$port" 2>/dev/null; then
          ports_up="${ports_up:+$ports_up,}${port}"
        fi
      done < <(grep -E '^\|[[:space:]]*[0-9]{4,5}[[:space:]]*\|' "$port_reg" 2>/dev/null)
    fi
    printf 'ports_up=%s\n' "$ports_up"

    # ── MCP server health (cached 120s) ──
    # Strategy: npx/uvx servers are managed by Claude Code (spawned on-demand via stdio).
    # pgrep is unreliable for these — they may be lazy-loaded, wrapped under different
    # process names, or not running between tool calls. Only pgrep-check "persistent"
    # servers (node/python/etc with local scripts). For npx/uvx, check if the Claude
    # parent process is alive — if so, assume its managed servers are fine.
    mcp_healthy="" ; mcp_down="" ; mcp_managed=""
    mcp_cache="/tmp/claude-mcp-health-${TARGET_PID}"
    if [[ ! -f "$mcp_cache" ]] || (( _NOW - $(_stat_mtime "$mcp_cache") > 120 )); then
    # Check if Claude Code parent is alive (managed servers are fine if parent lives)
    claude_alive=0
    if kill -0 "$TARGET_PID" 2>/dev/null; then
      claude_alive=1
    fi
    for mcp_conf in "$cwd/.mcp.json" "$HOME/.claude/.mcp.json"; do
      if [[ -f "$mcp_conf" ]]; then
        while IFS='|' read -r name cmd pkg_arg; do
          [[ -z "$name" || "$name" == "null" ]] && continue
          case "$cmd" in
            npx|uvx)
              # Managed by Claude Code — don't pgrep, trust parent process
              if (( claude_alive )); then
                mcp_managed="${mcp_managed:+$mcp_managed,}$name"
              else
                mcp_down="${mcp_down:+$mcp_down,}$name"
              fi
              continue
              ;;
          esac
          # Persistent servers — pgrep check
          search_pat=""
          case "$cmd" in
            node) search_pat="${pkg_arg:-}" ;;
            *)    search_pat="$cmd" ;;
          esac
          if [[ -z "$search_pat" ]]; then
            continue
          elif pgrep -f "$search_pat" &>/dev/null; then
            mcp_healthy="${mcp_healthy:+$mcp_healthy,}$name"
          else
            mcp_down="${mcp_down:+$mcp_down,}$name"
          fi
        done < <(jq -r '
          .mcpServers | to_entries[] |
          [.key, .value.command,
           (.value.args | map(select(startswith("-") | not)) | first // "")
          ] | join("|")
        ' "$mcp_conf" 2>/dev/null)
        break
      fi
    done
      # Merge managed into healthy for display purposes
      if [[ -n "$mcp_managed" ]]; then
        mcp_healthy="${mcp_healthy:+$mcp_healthy,}$mcp_managed"
      fi
      printf '%s\n%s' "$mcp_healthy" "$mcp_down" > "$mcp_cache"
    else
      { read -r mcp_healthy; read -r mcp_down; } < "$mcp_cache" 2>/dev/null || true
    fi
    printf 'mcp_healthy=%s\n' "$mcp_healthy"
    printf 'mcp_down=%s\n' "$mcp_down"

    # ── Complexity delta (file count + line count vs session start) ──
    # Gated to 30s cadence — two find+wc-l passes are the heaviest daemon operations
    complexity_cache="/tmp/claude-complexity-${TARGET_PID}"
    COMPLEXITY_TS_FILE="/tmp/claude-complexity-ts-${TARGET_PID}"
    _complexity_stale=1
    if [[ -f "$COMPLEXITY_TS_FILE" ]]; then
      _last_complexity_ts=$(cat "$COMPLEXITY_TS_FILE" 2>/dev/null | tr -d '[:space:]')
      (( _NOW - ${_last_complexity_ts:-0} < 30 )) && _complexity_stale=0
    fi
    if (( _complexity_stale )) && cd "$cwd" 2>/dev/null && [[ -d ".git" || -f "package.json" || -f "pyproject.toml" ]]; then
      echo "$_NOW" > "$COMPLEXITY_TS_FILE" 2>/dev/null || true
      # Count source files and lines (exclude build artifacts)
      src_files=$(find . -maxdepth 4 -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' \) -not -path '*/node_modules/*' -not -path '*/.next/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
      src_lines=$(find . -maxdepth 4 -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' \) -not -path '*/node_modules/*' -not -path '*/.next/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.git/*' -print0 2>/dev/null | xargs -0 wc -l 2>/dev/null | tail -1 | awk '{print $1}')
      src_files=${src_files:-0}; src_lines=${src_lines:-0}

      # Save snapshot on first run
      if [[ ! -f "$complexity_cache" ]]; then
        printf '%s %s' "$src_files" "$src_lines" > "$complexity_cache"
      fi

      # Read baseline and compute delta
      read -r base_files base_lines < "$complexity_cache" 2>/dev/null || true
      base_files=${base_files:-0}; base_lines=${base_lines:-0}
      delta_files=$((src_files - base_files))
      delta_lines=$((src_lines - base_lines))
      printf 'complexity_df=%s\n' "$delta_files"
      printf 'complexity_dl=%s\n' "$delta_lines"
    fi

    # ── System memory ──
    printf 'sys_free_mb=%s\n' "$(_mem_free_mb)"
    printf 'sys_total_mb=%s\n' "$(_mem_total_mb)"

    # ── Disk free (working directory volume) ──
    if cd "$cwd" 2>/dev/null; then
      printf 'disk_free_gb=%s\n' "$(_df_free_gb . || echo 0)"
    fi

    # ── Git stash count ──
    if cd "$cwd" 2>/dev/null && timeout 2 git rev-parse --is-inside-work-tree &>/dev/null; then
      stash_count=$(timeout 2 git stash list 2>/dev/null | wc -l | tr -d ' ')
      printf 'git_stash=%s\n' "${stash_count:-0}"
    fi

    # ── Token speed ring buffer ──
    # Read token count from statusline-written file, compute delta per interval
    TOK_FILE="/tmp/claude-tokens-${TARGET_PID}"
    TOK_SPEED_FILE="/tmp/claude-tokspeed-${TARGET_PID}"
    TOK_LAST="/tmp/claude-toklast-${TARGET_PID}"
    if [[ -f "$TOK_FILE" ]]; then
      curr_tokens=$(cat "$TOK_FILE" 2>/dev/null | tr -d '[:space:]')
      curr_tokens=${curr_tokens:-0}
      prev_tokens=0
      [[ -f "$TOK_LAST" ]] && prev_tokens=$(cat "$TOK_LAST" 2>/dev/null | tr -d '[:space:]') || true
      prev_tokens=${prev_tokens:-0}
      tok_delta=$((curr_tokens - prev_tokens))
      (( tok_delta < 0 )) && tok_delta=0
      # tokens per second = delta / interval
      tok_per_sec=$((tok_delta / INTERVAL))
      echo "$curr_tokens" > "$TOK_LAST" 2>/dev/null || true
      printf 'tok_speed=%s\n' "$tok_per_sec"
    fi

    # ── Branch age (days since branch diverged from main, commits behind) ──
    if cd "$cwd" 2>/dev/null && timeout 2 git rev-parse --is-inside-work-tree &>/dev/null; then
      current_branch=$(timeout 2 git branch --show-current 2>/dev/null) || true
      if [[ -n "$current_branch" && "$current_branch" != "main" && "$current_branch" != "master" ]]; then
        # Detect default branch
        default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || true
        default_branch=${default_branch:-main}
        merge_base=$(git merge-base HEAD "$default_branch" 2>/dev/null) || true
        if [[ -n "$merge_base" ]]; then
          base_ts=$(git log -1 --format=%ct "$merge_base" 2>/dev/null) || true
          if [[ -n "$base_ts" ]]; then
            age_days=$(( (_NOW - base_ts) / 86400 ))
            printf 'branch_age_days=%s\n' "$age_days"
          fi
          behind=$(git rev-list --count "HEAD..${default_branch}" 2>/dev/null) || true
          printf 'branch_behind=%s\n' "${behind:-0}"
        fi
      fi
    fi

    # ── Cost velocity (rolling $/min from cost ring buffer) ──
    COST_FWD="/tmp/claude-cost-${TARGET_PID}"
    COST_RING="/tmp/claude-costring-${TARGET_PID}"
    if [[ -f "$COST_FWD" ]]; then
      curr_cost=$(cat "$COST_FWD" 2>/dev/null | tr -d '[:space:]')
      # Append timestamp:cost to ring buffer, keep last 15 (60s / 4s interval)
      if [[ -n "$curr_cost" ]]; then
        if [[ -f "$COST_RING" ]]; then
          tail -14 "$COST_RING" > "${COST_RING}.tmp" 2>/dev/null
          echo "${_NOW}:${curr_cost}" >> "${COST_RING}.tmp"
          mv "${COST_RING}.tmp" "$COST_RING" 2>/dev/null || true
        else
          echo "${_NOW}:${curr_cost}" > "$COST_RING"
        fi
        # Compute cost delta over the ring buffer window
        first_line=$(head -1 "$COST_RING" 2>/dev/null)
        last_line=$(tail -1 "$COST_RING" 2>/dev/null)
        if [[ -n "$first_line" && -n "$last_line" ]]; then
          first_ts=${first_line%%:*}; first_c=${first_line#*:}
          last_ts=${last_line%%:*}; last_c=${last_line#*:}
          dt=$((last_ts - first_ts))
          if (( dt > 0 )); then
            # Compute in integer: cents-per-minute * 100
            # dc = (last_c - first_c) in dollars → multiply by 10000 for cents*100
            # Use awk for float math
            cpm=$(awk "BEGIN { dc = ($last_c - $first_c); if(dc<0) dc=0; printf \"%.0f\", (dc * 6000 / $dt) }" 2>/dev/null) || cpm=0
            printf 'cost_vel_cpm=%s\n' "${cpm:-0}"
          fi
        fi
      fi
    fi

    # ── Focus file (most-edited file from transcript) ──
    TPATH_FWD="/tmp/claude-tpath-${TARGET_PID}"
    FOCUS_CACHE="/tmp/claude-focus-cache-${TARGET_PID}"
    if [[ -f "$TPATH_FWD" ]]; then
      tpath=$(cat "$TPATH_FWD" 2>/dev/null | tr -d '[:space:]')
      if [[ -n "$tpath" && -f "$tpath" ]]; then
        # Only reparse every 30s
        if [[ ! -f "$FOCUS_CACHE" ]] || (( _NOW - $(_stat_mtime "$FOCUS_CACHE") > 30 )); then
          # Extract file_path from Edit/Write tool_use entries (tail last 2000 lines for performance)
          focus_result=$(tail -2000 "$tpath" 2>/dev/null | grep -o '"file_path":"[^"]*"' | sed 's/"file_path":"//;s/"//' | sort | uniq -c | sort -rn | head -1 | awk '{print $1, $2}') || true
          if [[ -n "$focus_result" ]]; then
            echo "$focus_result" > "$FOCUS_CACHE"
          fi
        fi
        if [[ -f "$FOCUS_CACHE" ]]; then
          read -r fcount fpath < "$FOCUS_CACHE" 2>/dev/null || true
          printf 'focus_count=%s\n' "${fcount:-0}"
          printf 'focus_file=%s\n' "${fpath:-}"
        fi
      fi
    fi

    # ── Sparkline ring buffer (sample every ~30s for useful history depth) ──
    # Sampling every 4s fills 20 slots in 80s — too fast to show meaningful trend.
    # By gating to 30s, 20 samples spans ~10 minutes of context usage.
    CTX_FILE="/tmp/claude-ctx-${TARGET_PID}"
    SPARK_FILE="/tmp/claude-sparkline-${TARGET_PID}"
    if [[ -f "$CTX_FILE" ]]; then
      _spark_age=9999
      [[ -f "$SPARK_FILE" ]] && _spark_age=$(( _NOW - $(_stat_mtime "$SPARK_FILE") ))
      if (( _spark_age >= 30 )); then
        ctx_val=$(cat "$CTX_FILE" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$ctx_val" && "$ctx_val" =~ ^[0-9]+$ ]]; then
          if [[ -f "$SPARK_FILE" ]]; then
            tail -19 "$SPARK_FILE" > "${SPARK_FILE}.tmp" 2>/dev/null
            echo "$ctx_val" >> "${SPARK_FILE}.tmp"
            mv "${SPARK_FILE}.tmp" "$SPARK_FILE" 2>/dev/null || true
          else
            echo "$ctx_val" > "$SPARK_FILE"
          fi
        fi
      fi
    fi

    # ── Activity timeline ring buffer (tool calls per daemon interval) ──
    TOOL_FILE="/tmp/claude-tools-${TARGET_PID}"
    TIMELINE_FILE="/tmp/claude-timeline-${TARGET_PID}"
    TIMELINE_LAST="/tmp/claude-timeline-last-${TARGET_PID}"
    if [[ -f "$TOOL_FILE" ]]; then
      current_total=$(grep '^_total=' "$TOOL_FILE" 2>/dev/null | cut -d= -f2) || true
      current_total=${current_total:-0}
      last_total=0
      [[ -f "$TIMELINE_LAST" ]] && last_total=$(cat "$TIMELINE_LAST" 2>/dev/null | tr -d '[:space:]') || true
      last_total=${last_total:-0}
      delta=$((current_total - last_total))
      (( delta < 0 )) && delta=0
      echo "$current_total" > "$TIMELINE_LAST" 2>/dev/null || true
      # Append to timeline ring buffer, keep last 30 entries
      if [[ -f "$TIMELINE_FILE" ]]; then
        tail -29 "$TIMELINE_FILE" > "${TIMELINE_FILE}.tmp" 2>/dev/null
        echo "$delta" >> "${TIMELINE_FILE}.tmp"
        mv "${TIMELINE_FILE}.tmp" "$TIMELINE_FILE" 2>/dev/null || true
      else
        echo "$delta" > "$TIMELINE_FILE"
      fi
    fi

    # ── Script integrity check ──
    # Emit script_changed=1 if statusline.sh was modified since this session started.
    # Persists until the session ends (orig cksum never updated).
    _cur_cksum=$(_checksum "$_SCRIPT_PATH")
    _orig_cksum=$(cat "$_ORIG_CKSUM_FILE" 2>/dev/null) || true
    if [[ -n "$_cur_cksum" && -n "$_orig_cksum" && "$_cur_cksum" != "$_orig_cksum" ]]; then
      printf 'script_changed=1\n'
    else
      printf 'script_changed=0\n'
    fi

  } > "$tmp" 2>/dev/null
  mv "$tmp" "$OUTPUT_FILE" 2>/dev/null || true

  sleep "$INTERVAL"
done

# Cleanup on exit
rm -f "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp" "/tmp/claude-pr-${TARGET_PID}" "/tmp/claude-net-${TARGET_PID}" "/tmp/claude-net-bytes-${TARGET_PID}" "/tmp/claude-session-start-${TARGET_PID}" "/tmp/claude-complexity-${TARGET_PID}" "/tmp/claude-complexity-ts-${TARGET_PID}" "/tmp/claude-ext-enabled-${TARGET_PID}" "/tmp/claude-mcp-health-${TARGET_PID}" "/tmp/claude-ctx-${TARGET_PID}" "/tmp/claude-sparkline-${TARGET_PID}" "/tmp/claude-timeline-${TARGET_PID}" "/tmp/claude-timeline-last-${TARGET_PID}" "/tmp/claude-tokens-${TARGET_PID}" "/tmp/claude-tokspeed-${TARGET_PID}" "/tmp/claude-toklast-${TARGET_PID}" "/tmp/claude-cost-${TARGET_PID}" "/tmp/claude-costring-${TARGET_PID}" "/tmp/claude-tpath-${TARGET_PID}" "/tmp/claude-focus-cache-${TARGET_PID}" "/tmp/claude-statusline-orig-cksum-${TARGET_PID}" 2>/dev/null
