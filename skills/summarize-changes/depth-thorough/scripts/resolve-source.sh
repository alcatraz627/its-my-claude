#!/usr/bin/env bash
# resolve-source.sh — turn a source spec into commits.tsv + files.txt
#
# Usage:
#   resolve-source.sh pr <N> [--include-worktree]
#   resolve-source.sh branch <A>...<B> [--include-worktree]
#   resolve-source.sh commit <SHA1>..<SHA2>
#   resolve-source.sh date "<since>" "<until>"
#   resolve-source.sh worktree
#
# Outputs to current dir:
#   01-commits.tsv  — tab-separated: short-sha<TAB>subject
#   02-files.txt    — one path per line, deduped, sorted
#
# Notes:
# - Uses /usr/bin/git explicitly (avoids shell-wrapper interception).
# - PR mode requires `gh` configured; falls back to manual branch entry if it fails.

set -euo pipefail
GIT=/usr/bin/git
mode="${1:-}"; shift || true

case "$mode" in
  pr)
    pr_num="${1:-}"; shift || true
    include_wt=0
    [[ "${1:-}" == "--include-worktree" ]] && include_wt=1
    if ! command -v gh >/dev/null 2>&1; then
      echo "gh not installed — fall back to: resolve-source.sh branch <range>" >&2; exit 2
    fi
    if ! base_branch=$(gh pr view "$pr_num" --json baseRefName -q .baseRefName 2>/dev/null); then
      echo "gh pr view failed for #$pr_num — auth, fork, or closed PR?" >&2; exit 2
    fi
    head_branch=$(gh pr view "$pr_num" --json headRefName -q .headRefName)
    range="origin/${base_branch}...origin/${head_branch}"
    ;;
  branch)
    range="${1:-}"; shift || true
    include_wt=0
    [[ "${1:-}" == "--include-worktree" ]] && include_wt=1
    ;;
  commit)
    range="${1:-}"; shift || true
    include_wt=0
    ;;
  date)
    since="${1:-}"; until="${2:-now}"
    range=""
    include_wt=0
    ;;
  worktree)
    range=""
    include_wt=1
    ;;
  *)
    echo "Usage: resolve-source.sh {pr|branch|commit|date|worktree} ..." >&2; exit 2
    ;;
esac

# commits
if [[ -n "$range" ]]; then
  $GIT log --pretty=format:'%h	%s' "$range" > 01-commits.tsv
elif [[ "$mode" == "date" ]]; then
  $GIT log --pretty=format:'%h	%s' --since="$since" --until="$until" > 01-commits.tsv
else
  : > 01-commits.tsv
fi

# files
{
  if [[ -n "$range" ]]; then
    $GIT diff --name-only "$range"
  elif [[ "$mode" == "date" ]]; then
    $GIT log --name-only --pretty=format: --since="$since" --until="$until" | /usr/bin/grep -v '^$' || true
  fi
  if (( include_wt )); then
    $GIT diff --name-only          # unstaged
    $GIT diff --cached --name-only # staged
    $GIT ls-files --others --exclude-standard
  fi
} | /usr/bin/sort -u > 02-files.txt

cn=$(/usr/bin/wc -l < 01-commits.tsv | tr -d ' ')
fn=$(/usr/bin/wc -l < 02-files.txt | tr -d ' ')
echo "resolved: $cn commits, $fn files"
