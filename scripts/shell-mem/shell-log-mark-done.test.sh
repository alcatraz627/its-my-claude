#!/usr/bin/env bash
# Checks that mark-done matches a command fragment literally (brackets and stars
# included), marks only the right line, and exits 1 when nothing matched.
set -uo pipefail
S="$(cd "$(dirname "$0")" && pwd)/shell-log-mark-done.sh"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
D=2026-01-02
mkdir -p "$T/.claude/shell-logs"
L="$T/.claude/shell-logs/$D.md"
cat > "$L" <<'EOF'
- [10:00:00] [sid:abc12345] `until [ -f /tmp/x ]; do sleep 1; done` [BG] [est:5s]
- [10:01:00] [sid:abc12345] `npm run dev` [BG] [est:5m]
- [10:02:00] [sid:other999] `until [ -f /tmp/x ]; do sleep 1; done` [BG] [est:5s]
EOF

out=$(HOME="$T" bash "$S" abc12345 'until [ -f /tmp/x ]' "$D"); rc=$?
[ "$rc" -eq 0 ] && ok "a fragment with [ ] matches (rc 0)" || bad "bracket fragment rc=$rc out=$out"
rg -q '^- \[10:00:00\].*\[BG:DONE\]' "$L" && ok "the matching line is marked done" || bad "line 1 not marked"
rg -q '^- \[10:01:00\].*`npm run dev` \[BG\] ' "$L" && ok "a different command stays open" || bad "line 2 changed"
rg -q '^- \[10:02:00\] \[sid:other999\].* \[BG\] ' "$L" && ok "another session's line stays open" || bad "line 3 changed"

HOME="$T" bash "$S" abc12345 'no such command' "$D" >/dev/null; rc=$?
[ "$rc" -eq 1 ] && ok "no match exits 1" || bad "no match rc=$rc"

HOME="$T" bash "$S" abc12345 'npm run *' "$D" >/dev/null; rc=$?
[ "$rc" -eq 1 ] && ok "a star is literal, not a wildcard" || bad "star treated as regex rc=$rc"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ "$fail" -eq 0 ]
