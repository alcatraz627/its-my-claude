#!/usr/bin/env bash
# scripts/git/state.sh — Canonical git state check before push/commit.
#
# Replaces the three-command chain that CLAUDE.md mandates before any push:
#   git status + git log --oneline -3 + git diff --stat
#
# Output is one consistent block so it's easy to scan + share. Always exits 0;
# if there's no git context, prints "(not a git repo)" and exits.
#
# Usage:
#   bash ~/.claude/scripts/git/state.sh             # in current dir
#   bash ~/.claude/scripts/git/state.sh /path       # in a specific dir
#   bash ~/.claude/scripts/git/state.sh --staged    # focus on staged-only diff
#   bash ~/.claude/scripts/git/state.sh -n 10       # show last N commits (default 3)

set -uo pipefail

DIR="${PWD}"
N=3
STAGED_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged) STAGED_ONLY=1 ;;
    -n)       N="$2"; shift ;;
    -*)       printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
    *)        DIR="$1" ;;
  esac
  shift
done

cd "$DIR" 2>/dev/null || { printf 'not a directory: %s\n' "$DIR"; exit 1; }

# Is this a git repo?
if ! git -c core.useBuiltinFSMonitor=false rev-parse --git-dir >/dev/null 2>&1; then
  printf '(not a git repo: %s)\n' "$DIR"
  exit 0
fi

branch=$(git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null)
tracking=$(git -c core.useBuiltinFSMonitor=false rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "(no upstream)")
ahead_behind=$(git -c core.useBuiltinFSMonitor=false rev-list --left-right --count "@{u}..HEAD" 2>/dev/null || echo "0	0")
behind=$(echo "$ahead_behind" | awk '{print $1}')
ahead=$(echo "$ahead_behind" | awk '{print $2}')

cat <<EOF
─────────────────────────────────────────────────────
  git state — $DIR
─────────────────────────────────────────────────────
  branch:   $branch  →  $tracking   (ahead=$ahead behind=$behind)

  STATUS
EOF
git -c core.useBuiltinFSMonitor=false status --short 2>/dev/null | sed 's/^/    /'
[[ -z "$(git -c core.useBuiltinFSMonitor=false status --short 2>/dev/null)" ]] && echo "    (clean)"

cat <<EOF

  RECENT COMMITS (last $N)
EOF
git -c core.useBuiltinFSMonitor=false log --oneline -"$N" 2>/dev/null | sed 's/^/    /' || echo "    (no commits)"

cat <<EOF

  DIFF SUMMARY$( ((STAGED_ONLY)) && echo " (staged only)" )
EOF
if (( STAGED_ONLY )); then
  git -c core.useBuiltinFSMonitor=false diff --cached --stat 2>/dev/null | sed 's/^/    /'
else
  git -c core.useBuiltinFSMonitor=false diff --stat 2>/dev/null | sed 's/^/    /'
  git -c core.useBuiltinFSMonitor=false diff --cached --stat 2>/dev/null | sed 's/^/    /'
fi

cat <<'EOF'
─────────────────────────────────────────────────────
EOF
