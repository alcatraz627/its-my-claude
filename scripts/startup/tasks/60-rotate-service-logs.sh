#!/usr/bin/env bash
# 60-rotate-service-logs.sh — Keep local service logs to a 2-week window.
#
# Policy (owner, 2026-08-06: "retention of 2 weeks, I don't need older logs locally"):
#   - a tracked log over --min-size is rotated to <name>.<YYYYMMDD-HHMM>.gz
#   - rotations older than --keep-days are deleted
#
# These logs are single append-only files, not dated series, so "keep 2 weeks"
# cannot mean "delete old files" — there are none. It has to mean rotate first,
# then expire the rotations. The window therefore starts filling from today.
#
# ROTATION SAFETY:
#   Truncating a file a process holds open leaves that process writing at its
#   old offset, producing a sparse file that still reports the original size.
#   So writers that support signal-based rotation get the signal (mongod takes
#   SIGUSR1 and reopens cleanly); everything else is copy-truncated, which is
#   safe for plain appenders because they never seek.
#
# REVIVAL:
#   Rotations are gzipped, not deleted, until --keep-days passes. Read one with
#   `zcat <file>.gz`. After that the data is gone; raise --keep-days for longer.
#
# Registered logs live in the TRACKED array below. Add a path there to cover it.

set -uo pipefail

DRY_RUN=0
KEEP_DAYS=14
MIN_SIZE_MB=5

usage() {
  cat <<'EOF'
60-rotate-service-logs.sh [--dry-run] [--keep-days N] [--min-size-mb N]

  --dry-run        show what would happen, change nothing
  --keep-days N    delete rotations older than N days (default 14)
  --min-size-mb N  only rotate logs larger than N MB (default 5)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --keep-days) KEEP_DAYS="${2:-14}"; shift ;;
    --min-size-mb) MIN_SIZE_MB="${2:-5}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Logs this task owns. Each entry is a path; globs are expanded at run time.
TRACKED=(
  "/opt/homebrew/var/log/mongodb/mongo.log"
  "/opt/homebrew/var/log/nginx/error.log"
  "$HOME/Code/local-models/logs/ollama-serve.err.log"
  "$HOME/Code/local-models/logs/ollama-serve.log"
  "$HOME/.claude/logs/statusline-width.log"
  "$HOME/.claude/logs/statusline-ratelimit.log"
  "$HOME/.pm2/logs/*.log"
  "$HOME/.claude/dev-servers/logs/*.log"
)

STAMP="$(date '+%Y%m%d-%H%M')"
rotated=0 reclaimed=0 expired=0

say() { printf '%s\n' "$*"; }
run() { [ "$DRY_RUN" = 1 ] && return 0; "$@"; }

size_mb() { echo $(( $(stat -f %z "$1" 2>/dev/null || echo 0) / 1048576 )); }

# Ask the writer to reopen its log, so we never truncate a held-open file.
# Returns 0 when a signal was sent and the writer handled it.
signal_rotate() { # signal_rotate <path>
  case "$1" in
    */mongodb/mongo.log)
      local pid; pid=$(pgrep -f "mongodb-community/bin/mongod" | head -1)
      [ -z "$pid" ] && return 1
      run kill -USR1 "$pid" 2>/dev/null || return 1
      return 0 ;;
    */nginx/*)
      local pid; pid=$(pgrep -f "nginx: master" | head -1)
      [ -z "$pid" ] && return 1
      run kill -USR1 "$pid" 2>/dev/null || return 1
      return 0 ;;
  esac
  return 1
}

say "log retention: keep ${KEEP_DAYS}d, rotate over ${MIN_SIZE_MB}MB$([ "$DRY_RUN" = 1 ] && echo '  [DRY RUN]')"

for pattern in "${TRACKED[@]}"; do
  for f in $pattern; do
    [ -f "$f" ] || continue
    mb=$(size_mb "$f")
    [ "$mb" -lt "$MIN_SIZE_MB" ] && continue

    say "  rotate ${f}  (${mb}MB)"

    if signal_rotate "$f"; then
      # The writer renamed and reopened for us; its cast-off file is whatever
      # now sits beside the live one. mongod names it <log>.<ISO timestamp>.
      sleep 1
      for cast in "$f".20*; do
        [ -f "$cast" ] || continue
        run gzip -f "$cast" 2>/dev/null && say "    signalled writer, archived $(basename "$cast").gz"
      done
    else
      # Plain appender: copy the content aside, then truncate in place. The
      # writer keeps its offset at 0 because it never seeks.
      run cp "$f" "${f}.${STAMP}" 2>/dev/null || { say "    copy failed, skipping"; continue; }
      run sh -c ": > '$f'"
      run gzip -f "${f}.${STAMP}" 2>/dev/null
      say "    archived $(basename "$f").${STAMP}.gz, truncated live file"
    fi

    rotated=$((rotated + 1))
    reclaimed=$((reclaimed + mb))
  done
done

# Expire old rotations.
for pattern in "${TRACKED[@]}"; do
  for f in $pattern; do
    d=$(dirname "$f" 2>/dev/null); [ -d "$d" ] || continue
    while IFS= read -r old; do
      [ -z "$old" ] && continue
      say "  expire $(basename "$old") (older than ${KEEP_DAYS}d)"
      run trash "$old" 2>/dev/null || run rm -f "$old"
      expired=$((expired + 1))
    done < <(find "$d" -maxdepth 1 -name "*.gz" -type f -mtime +"${KEEP_DAYS}" 2>/dev/null)
  done
done

say "done: ${rotated} rotated (~${reclaimed}MB reclaimed), ${expired} expired"
exit 0
