#!/usr/bin/env bash
# 06-guidance.test.sh: all-scope directives come once per session and again after
# /clear; tag-matched directives still come on every prompt that names the tag.
# H=<path> points the suite at a mutated copy of the hinter.
set -uo pipefail
REAL="$HOME"
H="${H:-$REAL/.claude/hinters/06-guidance.sh}"
RESET="${RESET:-$REAL/.claude/scripts/session-mgmt/post-clear-counter-reset.sh}"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude/guidance"
ln -s "$REAL/.claude/scripts" "$T/.claude/scripts"
cat > "$T/.claude/guidance/notes.md" <<'N'
# Guidance
<!-- notes below -->
- 2026-10-01 [all] ALLDIRECTIVE keep the user's wording
- 2026-10-02 [css, layout] CSSDIRECTIVE keep the grid honest
N
run(){ printf '%s' "$2" | env CLAUDE_HINT_SID="$1" bash "$H"; }
has(){ printf '%s' "$1" | rg -q "$2"; }

o=$(run sessAAAA1 "keep going")
has "$o" ALLDIRECTIVE && ok "first prompt carries the all-scope directive" || ko "first prompt silent"
o=$(run sessAAAA1 "yes")
[ -z "$o" ] && ok "second prompt, no tag: silent" || ko "repeat fired: $o"
o=$(run sessAAAA1 "fix the css please")
has "$o" CSSDIRECTIVE && ok "tag-matched directive still fires" || ko "tag-matched silent"
has "$o" ALLDIRECTIVE && ko "all-scope repeated on a tag-matched prompt" || ok "all-scope not repeated on a tag-matched prompt"
o=$(run sessAAAA1 "fix the css again")
has "$o" CSSDIRECTIVE && ok "tag-matched directive fires on every matching prompt" || ko "tag-matched dedup'd"
o=$(run sessBBBB2 "keep going")
has "$o" ALLDIRECTIVE && ok "a new session gets the all-scope directive again" || ko "new session silent"
o=$(run sessBBBB2 "keep going")
[ -z "$o" ] && ok "and then stays quiet" || ko "new session repeated"
printf '{"source":"clear","session_id":"sessBBBB2"}' | bash "$RESET"
o=$(run sessBBBB2 "keep going")
has "$o" ALLDIRECTIVE && ok "after /clear the all-scope directive returns" || ko "silent after clear"

export HOME="$REAL"; trash "$T" "/tmp/claude-clear-reset-sessBBBB" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
