#!/usr/bin/env bash
# prepend-runtime-note.test.sh — runnable checks for notes-file resolution.
#
# The helper used to derive its target from where THIS SCRIPT lives, so it always
# wrote the global notes file even when the caller sat in a project holding its
# own. Three separate sessions filed the same proposal rather than fixing it, and
# versable-builder sessions moved the note across by hand for two weeks.
#
# The whole suite runs inside a sandboxed copy of skills/shared, so SCRIPT_DIR
# resolves into the sandbox and a "global" write lands on a throwaway file rather
# than the real one.
#
# Run: bash ~/.claude/skills/shared/prepend-runtime-note.test.sh   (exit 0 = pass)

set -uo pipefail

REAL_SHARED="$(cd "$(dirname "$0")" && pwd)"
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/prn-test-XXXXXX")"
mkdir -p "$SANDBOX/skills/shared"
cp -f "$REAL_SHARED/prepend-runtime-note.sh" "$SANDBOX/skills/shared/"
cp -f "$REAL_SHARED/lock-file.sh"            "$SANDBOX/skills/shared/"
HELPER="$SANDBOX/skills/shared/prepend-runtime-note.sh"
GLOBAL="$SANDBOX/skills/runtime-notes.md"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }

ENTRY="$SANDBOX/entry.md"
printf '## test: a note · 2026-09-04 03:00\n**Purpose:** fixture.\n' > "$ENTRY"

# A project that HAS opted in, and a nested subdir inside it.
PROJ="$SANDBOX/proj"
mkdir -p "$PROJ/.claude/skills" "$PROJ/src/deep"
PROJ_NOTES="$PROJ/.claude/skills/runtime-notes.md"
printf '# Skill Runtime Notes\n\nfixture header.\n\n---\n\nOLDEST ENTRY MARKER\n' > "$PROJ_NOTES"

# A project that has a .claude/ but NO notes file: it has not opted in.
BARE="$SANDBOX/bare"
mkdir -p "$BARE/.claude/skills" "$BARE/sub"

grew(){ # grew <file> -> yes|no   (did the fixture gain our entry?)
  [ -f "$1" ] && rg -q 'test: a note' "$1" 2>/dev/null && echo yes || echo no
}
# Reseed both fixtures with a valid header rather than deleting them: this
# account bans rm, and an empty-but-present notes file would send the helper
# down its create-header branch with a different shape than a real one.
reset(){
  local seed='# Skill Runtime Notes\n\nfixture header.\n\n---\n\nOLDEST ENTRY MARKER\n'
  printf "$seed" > "$PROJ_NOTES"
  mkdir -p "$(dirname "$GLOBAL")"
  printf "$seed" > "$GLOBAL"
}

echo "── resolution: the caller's project wins when it has opted in ──"
reset; ( cd "$PROJ" && bash "$HELPER" test-skill "$ENTRY" >/dev/null 2>&1 )
ok "from the project root, project file grows" "$(grew "$PROJ_NOTES")" yes
ok "from the project root, global stays untouched" "$(grew "$GLOBAL")" no

reset; ( cd "$PROJ/src/deep" && bash "$HELPER" test-skill "$ENTRY" >/dev/null 2>&1 )
ok "from a nested subdir, ancestor walk finds it" "$(grew "$PROJ_NOTES")" yes

echo
echo "── B-P2 parity: callers outside a project keep writing the global file ──"
reset; ( cd "$BARE" && bash "$HELPER" test-skill "$ENTRY" >/dev/null 2>&1 )
ok "a .claude/ with no notes file has NOT opted in" "$(grew "$PROJ_NOTES")" no
ok "  and the note lands in the global file"        "$(grew "$GLOBAL")"     yes

reset; ( cd "$SANDBOX" && bash "$HELPER" test-skill "$ENTRY" >/dev/null 2>&1 )
ok "from a plain directory, global file grows" "$(grew "$GLOBAL")" yes

echo
echo "── explicit overrides ──"
reset; ( cd "$PROJ" && bash "$HELPER" --global test-skill "$ENTRY" >/dev/null 2>&1 )
ok "--global beats detection"                  "$(grew "$GLOBAL")"     yes
ok "  and leaves the project file alone"       "$(grew "$PROJ_NOTES")" no

reset; ( cd "$SANDBOX" && bash "$HELPER" --project "$PROJ" test-skill "$ENTRY" >/dev/null 2>&1 )
ok "--project targets the named tree"          "$(grew "$PROJ_NOTES")" yes

echo
echo "── B-P3 parity: the file shape /catchup parses is unchanged ──"
reset; ( cd "$PROJ" && bash "$HELPER" test-skill "$ENTRY" >/dev/null 2>&1 )
ok "header line survives"        "$(head -1 "$PROJ_NOTES")"                        "# Skill Runtime Notes"
ok "new entry is above the old"  "$(rg -n 'test: a note|OLDEST ENTRY MARKER' "$PROJ_NOTES" | head -1 | rg -o 'test: a note')" "test: a note"
ok "separator count is sane"     "$(rg -c '^---$' "$PROJ_NOTES")"                  2

echo
echo "── the suite can tell a write from a no-write ──"
reset
ok "control: fixture starts clean" "$(grew "$PROJ_NOTES")" no

echo
echo "---- pass=$pass fail=$fail"
echo "sandbox: $SANDBOX"
[ "$fail" -eq 0 ]
