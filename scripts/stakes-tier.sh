#!/usr/bin/env bash
# stakes-tier.sh — resolve a project path to its stakes tier: high | low.
#
# "Stakes" is how much a sloppy mistake there actually costs. high = code the
# user also works in and/or that ships to production (Versable, ~/.claude); low =
# throwaway/personal tooling. The atone gates read this to scale friction: hard in
# high-stakes repos, near-silent in low. (Design/efficacy elevation is a separate
# axis the gates derive from task-shape, not from this resolver.)
#
# Resolution order (config: ~/.claude/stakes.json):
#   1. Longest path-prefix match in high[]/low[] wins (most specific path).
#   2. No match BUT the repo has a git remote -> treated "low" (no surprise
#      friction) and logged once to ~/.claude/.stakes-pending.jsonl for the user
#      to promote to high. ("let claude flag it, with my approval, as things mature")
#   3. No match, no remote -> "low".
#
# Usage:  stakes-tier.sh [PATH]      (PATH defaults to $PWD)
# Output: one line — high | low

set -uo pipefail

CONFIG="${STAKES_CONFIG:-$HOME/.claude/stakes.json}"
PENDING="$HOME/.claude/.stakes-pending.jsonl"

path="${1:-$PWD}"
# Resolve to an absolute, symlink-free path when possible (best-effort).
if command -v realpath >/dev/null 2>&1; then
  path=$(realpath -q "$path" 2>/dev/null || printf '%s' "$path")
fi

# No config or no jq -> safe default: low (never invent friction).
{ [ -f "$CONFIG" ] && command -v jq >/dev/null 2>&1; } || { echo low; exit 0; }

tier=$(jq -r --arg p "$path" --arg home "$HOME" '
  def expand: sub("^~"; $home);
  ( [ (.high[]? | {t:"high", e:(expand)}),
      (.low[]?  | {t:"low",  e:(expand)}) ]
    | map(. as $o | select($p == $o.e or ($p | startswith($o.e + "/"))))
    | sort_by(.e | length) | last ) as $m
  | if $m then $m.t else "none" end
' "$CONFIG" 2>/dev/null || echo none)

if [ "$tier" = "high" ] || [ "$tier" = "low" ]; then
  echo "$tier"
  exit 0
fi

# Unlisted. If it's a git repo with a remote, flag it for promotion review but
# behave as low for now (don't surprise the user with friction on an unknown repo).
remote=""
if git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  remote=$(git -C "$path" remote get-url origin 2>/dev/null || git -C "$path" remote 2>/dev/null | head -1)
fi
if [ -n "$remote" ]; then
  root=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$path")
  # Append once per repo root (dedup on root).
  if ! { [ -f "$PENDING" ] && grep -qF "\"root\":\"$root\"" "$PENDING" 2>/dev/null; }; then
    ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
    printf '{"root":"%s","remote":"%s","first_seen":"%s","suggested":"high","status":"pending-approval"}\n' \
      "$root" "$remote" "$ts" >> "$PENDING" 2>/dev/null || true
  fi
fi
echo low
