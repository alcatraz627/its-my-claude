#!/usr/bin/env bash
# zreclaim.test.sh — proves zreclaim never deletes anything you could need.
#
# Self-contained: builds a fixture tree in a temp dir, asserts against the
# hidden verbs and the real commands, tears down. PASS/FAIL per case; exits
# non-zero if any case fails. Touches only its own temp tree, never real repos.
set -uo pipefail

ZR="$(cd "$(dirname "$0")" && pwd)/zreclaim.sh"
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '        %s\n' "$2"; }
have() { grep -qF "$1" "$2"; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/zreclaim-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# ── build fixtures ───────────────────────────────────────────────────────────
# plain project (no git): mix of caches + real source that must survive
P="$TMP/proj"
mkdir -p "$P/src" "$P/data" "$P/node_modules/pkg/node_modules" "$P/.venv/lib" \
         "$P/__pycache__" "$P/dist" "$P/.next/cache"
echo "app" > "$P/src/app.js"
echo "secret" > "$P/.env"
echo "readme" > "$P/README.md"
echo "important" > "$P/data/important.csv"
echo "junk" > "$P/node_modules/pkg/index.js"
echo "junk" > "$P/node_modules/pkg/node_modules/nested.js"
echo "junk" > "$P/.venv/lib/x.py"
echo "junk" > "$P/__pycache__/x.pyc"
echo "junk" > "$P/dist/bundle.js"
echo "junk" > "$P/.next/cache/c"

# plain project with an untracked build/ (should be a candidate)
mkdir -p "$TMP/plain/build"; echo x > "$TMP/plain/build/out"

# rust: target only a candidate when Cargo.toml sits beside it
mkdir -p "$TMP/rustproj/target"; echo x > "$TMP/rustproj/target/o"; echo "[package]" > "$TMP/rustproj/Cargo.toml"
mkdir -p "$TMP/nottrust/target"; echo x > "$TMP/nottrust/target/o"

# git repo: build/ committed (tracked → must be EXCLUDED); node_modules untracked
G="$TMP/repo"
mkdir -p "$G/build" "$G/node_modules"
( cd "$G" && git init -q && git config user.email t@t && git config user.name t \
  && echo out > build/out.txt && echo nm > node_modules/x.js \
  && echo "node_modules/" > .gitignore \
  && git add build .gitignore && git commit -qm init ) >/dev/null 2>&1

# git repo with a large tracked file for the git-large report
BIG="$TMP/bigrepo"
mkdir -p "$BIG"
( cd "$BIG" && git init -q && git config user.email t@t && git config user.name t \
  && mkfile 6m huge.bin 2>/dev/null || dd if=/dev/zero of=huge.bin bs=1m count=6 >/dev/null 2>&1
  git add huge.bin && git commit -qm big ) >/dev/null 2>&1

echo "zreclaim tests"

# ── 1. detection: caches are candidates, source is not ───────────────────────
C="$TMP/cands.txt"
bash "$ZR" --__candidates "$P" > "$C" 2>/dev/null
if have "/node_modules" "$C" && have "/.venv" "$C" && have "/__pycache__" "$C" \
   && have "/dist" "$C" && have "/.next" "$C"; then ok "detects all cache categories"; else bad "detection: missing a category" "$(cat "$C")"; fi
if grep -q "/src" "$C" || grep -q "/data" "$C" || grep -q "README" "$C" || grep -q "\.env" "$C"; then
  bad "detection: a source/keep path leaked into candidates" "$(cat "$C")"; else ok "never lists src/data/.env/README"; fi

# ── 2. no descent into a matched dir ─────────────────────────────────────────
if [ "$(grep -c "/node_modules" "$C")" -eq 1 ]; then ok "prunes nested node_modules (no descent)"; else bad "descent: nested node_modules listed" "$(grep '/node_modules' "$C")"; fi

# ── 3. git-tracked exclusion + its mutation (build tracked vs untracked) ─────
RC="$TMP/repo_cands.txt"; RT="$TMP/repo_tracked.txt"
bash "$ZR" --__candidates "$G" > "$RC" 2>/dev/null
bash "$ZR" --__tracked    "$G" > "$RT" 2>/dev/null
if have "/node_modules" "$RC"; then ok "untracked node_modules IS a candidate (in repo)"; else bad "guard: node_modules missing" "$(cat "$RC")"; fi
if grep -q "/build" "$RC"; then bad "guard: TRACKED build/ leaked into deletable candidates" "$(cat "$RC")"; else ok "tracked build/ EXCLUDED from candidates"; fi
if have "/build" "$RT"; then ok "tracked build/ flagged in excluded list"; else bad "guard: tracked build/ not flagged" "$(cat "$RT")"; fi
# mutation: same-named build/ in a NON-tracked context IS a candidate → proves exclusion is caused by tracking
PC="$TMP/plain_cands.txt"; bash "$ZR" --__candidates "$TMP/plain" > "$PC" 2>/dev/null
if have "/build" "$PC"; then ok "untracked build/ IS a candidate (mutation: exclusion is caused by tracking)"; else bad "mutation: untracked build/ not detected" "$(cat "$PC")"; fi

# ── 4. target requires a Cargo.toml sibling ──────────────────────────────────
bash "$ZR" --__candidates "$TMP/rustproj" > "$TMP/rc.txt" 2>/dev/null
bash "$ZR" --__candidates "$TMP/nottrust" > "$TMP/nc.txt" 2>/dev/null
if have "/target" "$TMP/rc.txt"; then ok "target/ with Cargo.toml IS a candidate"; else bad "target: not detected with Cargo.toml" "$(cat "$TMP/rc.txt")"; fi
if grep -q "/target" "$TMP/nc.txt"; then bad "target: bare target/ (no Cargo.toml) wrongly a candidate" "$(cat "$TMP/nc.txt")"; else ok "bare target/ (no Cargo.toml) is NOT a candidate"; fi

# ── 5. delete removes only candidates; keeps survive ─────────────────────────
bash "$ZR" --__delete "$P/node_modules" "$P/.venv" "$P/__pycache__" >/dev/null 2>&1
[ ! -d "$P/node_modules" ] && [ ! -d "$P/.venv" ] && [ ! -d "$P/__pycache__" ] && ok "delete removed the named cache dirs" || bad "delete: a cache dir survived"
[ -f "$P/src/app.js" ] && [ -f "$P/.env" ] && [ -f "$P/README.md" ] && [ -f "$P/data/important.csv" ] && ok "delete left src/.env/README/data intact" || bad "delete: a keep-file was removed"

# ── 6. delete REFUSES a non-candidate path (defense in depth) ────────────────
if bash "$ZR" --__delete "$P/src" >/dev/null 2>&1; then bad "delete: accepted a non-candidate (src)"; else ok "delete refuses a non-candidate path"; fi
[ -f "$P/src/app.js" ] && ok "refused delete left src intact" || bad "refused delete still removed src"
# tracked dir is refused too
if bash "$ZR" --__delete "$G/build" >/dev/null 2>&1; then bad "delete: accepted a tracked dir"; else ok "delete refuses a git-tracked dir"; fi
[ -f "$G/build/out.txt" ] && ok "refused tracked delete left build/ intact" || bad "tracked build/ was removed"

# ── 7. protected-root refusal ────────────────────────────────────────────────
if bash "$ZR" scan / >/dev/null 2>&1; then bad "did not refuse root /"; else ok "refuses to scan /"; fi
if bash "$ZR" clean "$HOME" --dry-run >/dev/null 2>&1; then bad "did not refuse \$HOME"; else ok "refuses to clean \$HOME"; fi

# ── 8. git-large is report-only ──────────────────────────────────────────────
GL="$TMP/gl.txt"; bash "$ZR" git-large "$BIG" > "$GL" 2>/dev/null
if have "huge.bin" "$GL"; then ok "git-large reports the large tracked file"; else bad "git-large: did not report huge.bin" "$(cat "$GL")"; fi
[ -f "$BIG/huge.bin" ] && ok "git-large left the file on disk (report only)" || bad "git-large removed a file"

# ── 9. pareto: [100,50,10,1] @90% → {100,50} only ────────────────────────────
PF="$TMP/pareto.txt"
printf '100\ta\t/a\n50\tb\t/b\n10\tc\t/c\n1\td\t/d\n' > "$PF"
PR="$(bash "$ZR" --__pareto "$PF" 90 2>/dev/null)"
if [ "$(printf '%s\n' "$PR" | wc -l | tr -d ' ')" -eq 2 ] && printf '%s' "$PR" | grep -q "/a" && printf '%s' "$PR" | grep -q "/b" && ! printf '%s' "$PR" | grep -q "/c"; then
  ok "pareto selects fewest-biggest to reach coverage"; else bad "pareto: wrong selection" "$PR"; fi

# ── 10. empty tree → nothing to reclaim, exit 0 ──────────────────────────────
mkdir -p "$TMP/emptyproj/src"; echo x > "$TMP/emptyproj/src/a.js"
if bash "$ZR" scan "$TMP/emptyproj" >/dev/null 2>&1; then ok "empty tree scans cleanly (exit 0)"; else bad "empty tree scan errored"; fi

# ── 11. --json parses ────────────────────────────────────────────────────────
bash "$ZR" scan --json "$TMP/plain" > "$TMP/out.json" 2>/dev/null
if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$TMP/out.json" 2>/dev/null; then ok "scan --json emits valid JSON"; else bad "json: invalid" "$(cat "$TMP/out.json")"; fi

# ── 12. ephemeral test/playwright residue is a candidate ─────────────────────
EPH="$TMP/eph"; mkdir -p "$EPH/test-results" "$EPH/playwright-report" "$EPH/.playwright-mcp"
echo x > "$EPH/test-results/a"; echo x > "$EPH/playwright-report/b"; echo x > "$EPH/.playwright-mcp/c"
bash "$ZR" --__candidates "$EPH" > "$TMP/eph.txt" 2>/dev/null
if have "/test-results" "$TMP/eph.txt" && have "/playwright-report" "$TMP/eph.txt" && have "/.playwright-mcp" "$TMP/eph.txt"; then
  ok "playwright/test residue detected as candidates"; else bad "ephemeral: not all detected" "$(cat "$TMP/eph.txt")"; fi

# ── 13. large loose file (outside scope) is FLAGGED but never deletable ───────
LO="$TMP/loose"; mkdir -p "$LO/node_modules"
dd if=/dev/zero of="$LO/video.bin" bs=1m count=2 >/dev/null 2>&1
dd if=/dev/zero of="$LO/node_modules/inside.bin" bs=1m count=2 >/dev/null 2>&1
SC="$TMP/scan_loose.txt"; bash "$ZR" scan --big 1 "$LO" > "$SC" 2>/dev/null
if have "video.bin" "$SC"; then ok "large loose file flagged in scan"; else bad "loose: video.bin not flagged" "$(cat "$SC")"; fi
if grep -q "inside.bin" "$SC"; then bad "loose: flagged a file INSIDE node_modules (should be pruned)"; else ok "loose finder ignores files inside cache dirs"; fi
if bash "$ZR" --__delete "$LO/video.bin" >/dev/null 2>&1; then bad "delete: accepted a loose file"; else ok "delete refuses a loose (non-dir) file"; fi
[ -f "$LO/video.bin" ] && ok "flagged loose file left on disk (report only)" || bad "loose file was deleted"

# ── 14. --min threshold filters what clean considers ─────────────────────────
# (capture to a file first: `| grep -q` under pipefail flags the producer's SIGPIPE)
bash "$ZR" clean --dry-run --min 999999 "$LO" > "$TMP/min_hi.txt" 2>/dev/null
if grep -q "Nothing to reclaim" "$TMP/min_hi.txt"; then ok "clean --min above all sizes selects nothing"; else bad "min: high --min still selected something" "$(cat "$TMP/min_hi.txt")"; fi
bash "$ZR" clean --dry-run --min 0 "$LO" > "$TMP/min_lo.txt" 2>/dev/null
if grep -q "node_modules" "$TMP/min_lo.txt"; then ok "clean --min 0 considers the node_modules candidate"; else bad "min: --min 0 missed a candidate" "$(cat "$TMP/min_lo.txt")"; fi

echo
printf 'total: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
