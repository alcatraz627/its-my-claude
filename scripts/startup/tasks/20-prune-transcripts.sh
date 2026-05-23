#!/usr/bin/env bash
# 20-prune-transcripts.sh — Compress + age out Claude Code session transcripts.
#
# Policy:
#   - jsonl >6 months old  → gzip in place (typical ~10× reduction)
#   - .jsonl.gz >12 months → delete
#
# Default policy is conservative: 6-month retention as full transcripts,
# 6 more months as compressed archives, then delete. Total max age = 12 mo.
#
# REVIVAL:
#   Gzipped transcripts decompress with `gunzip <file>.jsonl.gz` — the
#   original is restored byte-for-byte. The past-sessions skill should
#   transparently read both .jsonl and .jsonl.gz (verify before relying).
#   Deletion at 12 months is hard — the data is gone. Bump --delete-days
#   higher if you want longer retention.
#
# Files live under ~/.claude/projects/<encoded-project-path>/<session-uuid>.jsonl
# (Anthropic-managed dir; we only touch *.jsonl by age).

set -uo pipefail

DRY_RUN=0
COMPRESS_DAYS=180
DELETE_DAYS=365
PROJECTS_DIR="${HOME}/.claude/projects"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --compress-days) COMPRESS_DAYS="${2:-180}"; shift ;;
    --delete-days)   DELETE_DAYS="${2:-365}"; shift ;;
  esac
  shift
done

[[ -d "$PROJECTS_DIR" ]] || { printf 'no projects dir at %s\n' "$PROJECTS_DIR"; exit 0; }

before_size=$(du -sk "$PROJECTS_DIR" 2>/dev/null | cut -f1)

# Stage 1: compress *.jsonl older than COMPRESS_DAYS
to_compress=0; compressed=0
while IFS= read -r -d '' f; do
  to_compress=$((to_compress + 1))
  if (( DRY_RUN )); then
    compressed=$((compressed + 1))
  else
    gzip -q "$f" 2>/dev/null && compressed=$((compressed + 1))
  fi
done < <(find "$PROJECTS_DIR" -type f -name '*.jsonl' -mtime "+${COMPRESS_DAYS}" -print0 2>/dev/null)

# Stage 2: delete *.jsonl.gz older than DELETE_DAYS
to_delete=0; deleted=0
while IFS= read -r -d '' f; do
  to_delete=$((to_delete + 1))
  if (( DRY_RUN )); then
    deleted=$((deleted + 1))
  else
    rm -f "$f" 2>/dev/null && deleted=$((deleted + 1))
  fi
done < <(find "$PROJECTS_DIR" -type f -name '*.jsonl.gz' -mtime "+${DELETE_DAYS}" -print0 2>/dev/null)

after_size=$(du -sk "$PROJECTS_DIR" 2>/dev/null | cut -f1)
freed_kb=$((before_size - after_size))

# Friendly size formatting
fmt_kb() {
  local kb="$1"
  if   (( kb > 1048576 )); then printf '%.1f GB' "$(echo "$kb/1048576" | bc -l)"
  elif (( kb > 1024 ));    then printf '%.1f MB' "$(echo "$kb/1024"    | bc -l)"
  else                          printf '%d KB' "$kb"
  fi
}

if (( DRY_RUN )); then
  printf 'would compress %d *.jsonl files (>%dd) and delete %d *.jsonl.gz files (>%dd)\n' \
    "$to_compress" "$COMPRESS_DAYS" "$to_delete" "$DELETE_DAYS"
  printf 'current projects size: %s\n' "$(fmt_kb "$before_size")"
else
  printf 'compressed %d/%d, deleted %d/%d; size %s → %s (freed %s)\n' \
    "$compressed" "$to_compress" "$deleted" "$to_delete" \
    "$(fmt_kb "$before_size")" "$(fmt_kb "$after_size")" "$(fmt_kb "$freed_kb")"
fi
