#!/usr/bin/env bash
# SessionStart hook: environment health check
# Checks for common issues and returns advisory warnings via additionalContext
# Must complete in <500ms — all checks are lightweight
set -uo pipefail

LOG=/tmp/hook-debug.log
echo "[health-check] started at $(date 2>/dev/null || echo '?')" >> "$LOG" 2>/dev/null
trap 'echo "[health-check] EXIT code=$?" >> '"$LOG"' 2>/dev/null' EXIT

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null) || true
cwd="${cwd:-$(pwd)}"

warnings=()

# 1. Stale worktrees (>3 days old)
if command -v git &>/dev/null && [[ -d "$cwd/.git" ]]; then
  while IFS= read -r line; do
    wt_path=$(echo "$line" | awk '{print $1}')
    # Skip bare repo and main worktree
    [[ "$wt_path" == "$cwd" ]] && continue
    # Check age via directory mtime
    if [[ -d "$wt_path" ]]; then
      wt_mtime=$(stat -f %m "$wt_path" 2>/dev/null || stat -c %Y "$wt_path" 2>/dev/null) || true
      wt_mtime=${wt_mtime:-$(date +%s)}  # default to now → age = 0 on stat failure
      age_days=$(( ( $(date +%s) - wt_mtime ) / 86400 ))
      if (( age_days > 3 )); then
        wt_name=$(basename "$wt_path")
        warnings+=("Stale worktree: $wt_name (${age_days}d old)")
      fi
    fi
  done < <(cd "$cwd" && git worktree list --porcelain 2>/dev/null | grep "^worktree " | sed 's/^worktree //')
fi

# 2. Orphaned pm2 processes (errored status)
if command -v pm2 &>/dev/null; then
  errored=$(pm2 jlist 2>/dev/null | jq -r '[.[] | select(.pm2_env.status == "errored")] | length' 2>/dev/null) || errored=0
  if (( errored > 0 )); then
    names=$(pm2 jlist 2>/dev/null | jq -r '[.[] | select(.pm2_env.status == "errored")] | .[0:3] | .[].name' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    warnings+=("pm2: ${errored} errored process(es): ${names}")
  fi
fi

# 3. Low disk space (<2GB free)
avail_kb=$(df -k / 2>/dev/null | awk 'NR==2{print $4}') || avail_kb=0
if (( avail_kb > 0 && avail_kb < 2097152 )); then
  avail_gb=$(awk "BEGIN{printf \"%.1f\", $avail_kb/1048576}")
  warnings+=("Low disk: ${avail_gb}GB free on /")
fi

# 4. Stale WAL (entries >24h old with no recent checkpoint)
for wal_path in "$cwd/.claude/wal.md" "$HOME/.claude/wal.md"; do
  if [[ -f "$wal_path" ]]; then
    wal_mtime=$(stat -f %m "$wal_path" 2>/dev/null || stat -c %Y "$wal_path" 2>/dev/null) || true
    wal_mtime=${wal_mtime:-$(date +%s)}
    wal_age_s=$(( $(date +%s) - wal_mtime ))
    if (( wal_age_s > 86400 )); then
      wal_age_d=$(( wal_age_s / 86400 ))
      warnings+=("Stale WAL: ${wal_age_d}d since last update")
    fi
    break
  fi
done

# 5. Uncommitted changes (>10 files)
if command -v git &>/dev/null && [[ -d "$cwd/.git" ]]; then
  dirty_count=$(cd "$cwd" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ') || dirty_count=0
  if (( dirty_count > 10 )); then
    warnings+=("Git: ${dirty_count} uncommitted files")
  fi
fi

# Output
if (( ${#warnings[@]} > 0 )); then
  # Build warning string (max 300 chars)
  msg="[HEALTH] "
  for w in "${warnings[@]}"; do
    if (( ${#msg} + ${#w} + 3 < 300 )); then
      msg+="$w. "
    fi
  done

  # Write to stderr for user visibility
  printf '\033[2m╭─ Health Check ─────────────────────────╮\033[0m\n' >&2
  for w in "${warnings[@]}"; do
    printf '\033[2m│\033[0m \033[33m⚠\033[0m %s\n' "$w" >&2
  done
  printf '\033[2m╰────────────────────────────────────────╯\033[0m\n' >&2

  # Also inject into context so Claude is aware
  json_out=$(jq -n --arg ctx "$msg" '{"additionalContext": $ctx}' 2>/dev/null) || json_out=""
  echo "[health-check] warnings=$(( ${#warnings[@]} )) json_out=$json_out" >> "$LOG" 2>/dev/null
  [ -n "$json_out" ] && echo "$json_out"
fi

exit 0
