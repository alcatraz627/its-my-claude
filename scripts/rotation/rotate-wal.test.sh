#!/usr/bin/env bash
# Checks that rotate-wal.sh archives BOTH the JSONL WAL and the legacy markdown WAL
# once they pass their thresholds, and leaves each below-threshold file alone.
# Runs under a throwaway HOME so it never touches the real ~/.claude/wal.* files.
#
# Why wal.md is covered: three hooks still append to it (shell-mem session-end,
# shell-mem pre-compact, session-mgmt pre-compact-checkpoint) and five readers parse
# it, but only wal.jsonl was ever rotated. It reached 2.6 MB / 53k lines as the
# largest file in the config root (gcc-map v4 D6, 2026-09-05).
#
# Run: bash ~/.claude/scripts/rotation/rotate-wal.test.sh
set -uo pipefail

ROTATE="$(cd "$(dirname "$0")" && pwd)/rotate-wal.sh"
pass=0; fail=0
ok()  { echo "  ok    $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }

T=$(mktemp -d /tmp/rotate-wal-test.XXXXXX)
REAL_HOME="$HOME"; export HOME="$T"
mkdir -p "$HOME/.claude"
trap 'export HOME="$REAL_HOME"; trash "$T" 2>/dev/null || true' EXIT

# 1. Below threshold: nothing moves.
printf '{"ts":"2026-09-01T00:00:00Z","kind":"action"}\n' > "$HOME/.claude/wal.jsonl"
printf '# WAL — ~/.claude cross-project\n<!-- Keep last 2 sessions only -->\n\n[10:00:00] shell: 1 cmd(s)\n' > "$HOME/.claude/wal.md"
WAL_ROTATE_THRESHOLD=1000000 WAL_MD_ROTATE_THRESHOLD=1000000 bash "$ROTATE" </dev/null 2>/dev/null
[ "$(wc -l < "$HOME/.claude/wal.jsonl")" -eq 1 ] && ok "small wal.jsonl untouched" || bad "small wal.jsonl was rotated"
[ "$(wc -l < "$HOME/.claude/wal.md")" -eq 4 ]    && ok "small wal.md untouched"    || bad "small wal.md was rotated"
[ -z "$(ls "$HOME/.claude/assets/backups/wal-archive" 2>/dev/null)" ] && ok "no archive written below threshold" || bad "archive written below threshold"

# 2. Above threshold: both archived, wal.md keeps its two header lines.
WAL_ROTATE_THRESHOLD=10 WAL_MD_ROTATE_THRESHOLD=10 bash "$ROTATE" </dev/null 2>/dev/null
jsonl_archives=$(ls "$HOME/.claude/assets/backups/wal-archive"/wal-global-*.jsonl.gz 2>/dev/null | wc -l | tr -d ' ')
md_archives=$(ls "$HOME/.claude/assets/backups/wal-archive"/wal-md-global-*.md.gz 2>/dev/null | wc -l | tr -d ' ')
[ "$jsonl_archives" -eq 1 ] && ok "wal.jsonl archived once" || bad "wal.jsonl archives: $jsonl_archives"
[ "$md_archives" -eq 1 ]    && ok "wal.md archived once"    || bad "wal.md archives: $md_archives"
[ ! -s "$HOME/.claude/wal.jsonl" ] && ok "wal.jsonl reset to empty" || bad "wal.jsonl not emptied"
first=$(sed -n '1p' "$HOME/.claude/wal.md"); second=$(sed -n '2p' "$HOME/.claude/wal.md")
[ "$first" = "# WAL — ~/.claude cross-project" ] && ok "wal.md keeps its title line" || bad "wal.md title line: '$first'"
[ "$second" = "<!-- Keep last 2 sessions only -->" ] && ok "wal.md keeps its policy comment" || bad "wal.md second line: '$second'"
[ "$(wc -l < "$HOME/.claude/wal.md")" -eq 2 ] && ok "wal.md body cleared" || bad "wal.md still has $(wc -l < "$HOME/.claude/wal.md") lines"
archived_body=$(gzip -dc "$HOME/.claude/assets/backups/wal-archive"/wal-md-global-*.md.gz | rg -c 'shell: 1 cmd' || true)
[ "$archived_body" = "1" ] && ok "archived wal.md carries the old body" || bad "archived wal.md body missing"

# 3. Project-local wal.md from the Stop-hook CWD is rotated too.
mkdir -p "$T/proj/.claude"
printf '# WAL — proj\n<!-- Keep last 2 sessions only -->\n\nline\n' > "$T/proj/.claude/wal.md"
printf '{"cwd":"%s"}' "$T/proj" | WAL_ROTATE_THRESHOLD=10 WAL_MD_ROTATE_THRESHOLD=10 bash "$ROTATE" 2>/dev/null
# Label glob is loose on purpose: the label code (unchanged, pre-existing) maps
# basename's trailing newline to "_", so the archive is "wal-md-proj_-<date>".
proj_archives=$(ls "$HOME/.claude/assets/backups/wal-archive"/wal-md-proj*.md.gz 2>/dev/null | wc -l | tr -d ' ')
[ "$proj_archives" -eq 1 ] && ok "project-local wal.md archived" || bad "project-local wal.md archives: $proj_archives"

echo "---- pass=$pass fail=$fail ----"
[ $fail -eq 0 ]
