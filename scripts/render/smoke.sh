#!/bin/bash
# Exercises trace.sh across the shapes that broke it before, and measures the
# result. Structural lines must land on the requested width exactly: a frame one
# column short is the defect this catches, and it is invisible in prose review.
#
#   bash ~/.claude/scripts/render/smoke.sh            # run every scenario
#   bash ~/.claude/scripts/render/smoke.sh --mutate   # prove the check can fail
set -o pipefail
TRACE="$HOME/.claude/scripts/render/trace.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
MUTATE=0; [ "${1:-}" = "--mutate" ] && MUTATE=1
fails=0; runs=0

# A long unbroken path and a long goal are the two inputs that used to tear the
# layout, so every scenario carries at least one of them.
cat > "$TMP/full.json" <<'EOF'
{"session_id":"smoke-full","timestamp":"2026-08-11 03:20","status":"in-progress",
 "project_root":"/Users/x/proj","checkpoint_path":"_ckpt.claude.md",
 "goal":"A goal long enough to wrap at least twice at eighty columns so the hanging indent is exercised rather than assumed to work",
 "pipeline":["First action","A second action whose text runs past the available width and must wrap under itself"],
 "interrupts":["BLOCKED: a hard blocker","WARN: a caution","NOTE: a neutral remark"],
 "stack_trace":["Did a thing","Did another thing"],
 "files":[{"path":"src/a.ts","change":"+1 / -1"},{"path":"deeply/nested/directory/structure/with/a/very/long/file/name.tsx","change":"+120 / -46"}],
 "coprocessor":{"worked":["Something worked"],"failed":["Something failed"]}}
EOF
# Every section empty. The renderer must omit them, not print placeholders.
cat > "$TMP/empty.json" <<'EOF'
{"session_id":"smoke-empty","timestamp":"2026-08-11 03:20","status":"complete",
 "goal":"","pipeline":[],"interrupts":[],"stack_trace":[],"files":[],
 "coprocessor":{"worked":[],"failed":[]}}
EOF
# Absent keys rather than empty ones: a caller that omits fields must not crash.
echo '{"session_id":"smoke-sparse","goal":"Only a goal here"}' > "$TMP/sparse.json"
# The old renderer choked on em-dashes and other non-ASCII in the JSON, a
# fragility the runtime notes recorded four separate times. Character-aware
# padding is what fixes it, so it stays pinned.
cat > "$TMP/unicode.json" <<'EOF'
{"session_id":"smoke-unicode","timestamp":"2026-08-11","status":"testing",
 "goal":"A goal with an em-dash — plus curly quotes “like these”, an ellipsis… and an accent café, long enough to wrap",
 "pipeline":["Handle the em-dash — properly"],
 "interrupts":["BLOCKED: a blocker with — a dash"],
 "stack_trace":["Did — a thing"],
 "files":[{"path":"src/café/naïve.ts","change":"+1 / -1"}],
 "coprocessor":{"worked":["Worked — well"],"failed":[]}}
EOF
cat > "$TMP/catchup.json" <<'EOF'
{"session_id":"smoke-catchup","timestamp":"2h ago","status":"post-clear FULL",
 "project_root":"/Users/x/proj","checkpoint_path":"_ckpt.claude.md",
 "next_action":"Do the first thing",
 "blocked_on":"USER: confirm something",
 "constraints":["A constraint reproduced verbatim, long enough that it wraps and must stay readable"],
 "caveats":["An unverified claim"],"expired_auth":["a push approval"],
 "decaying":["a tunnel; re-arm with some command"],
 "pipeline":["Pending one","Pending two"],"drift":["a mismatch"],
 "running":["a server on :5106"],"mail":["one unread"],
 "goal":"The original goal","expectation":"What was awaited",
 "learnings":["A lesson"],"files":[{"path":"src/a.ts","change":"the anchor"}]}
EOF

measure() { # file, kind, theme, width
  local out rc
  out=$(bash "$TRACE" "$1" --kind "$2" --theme "$3" --width "$4" 2>&1); rc=$?
  runs=$((runs + 1))
  if [ $rc -ne 0 ]; then
    printf 'FAIL exit=%d  %s %s/%s/%s\n' "$rc" "$(basename "$1")" "$2" "$3" "$4"
    fails=$((fails + 1)); return
  fi
  local want="$4"; [ "$MUTATE" = "1" ] && want=$(( want + 4 ))
  local off
  off=$(printf '%s\n' "$out" | WANT="$want" python3 -c "
import sys,re,os
want=int(os.environ['WANT'])
strip=lambda s: re.sub(r'\033\[[0-9;]*m','',s)
n=0
for l in sys.stdin:
    s=strip(l).rstrip('\n')
    if not s.strip(): continue
    if s[0] in '╔╚╟║◆━' or re.search(r'[═·─]{6,}',s):
        if len(s)!=want: n+=1
print(n)")
  if [ "$off" != "0" ]; then
    printf 'FAIL width  %s %s/%s/%s  (%s structural lines off)\n' \
      "$(basename "$1")" "$2" "$3" "$4" "$off"
    fails=$((fails + 1))
  fi
}

for th in a b c; do
  for wd in 60 80 100; do
    measure "$TMP/full.json"    dump    "$th" "$wd"
    measure "$TMP/empty.json"   dump    "$th" "$wd"
    measure "$TMP/sparse.json"  dump    "$th" "$wd"
    measure "$TMP/unicode.json" dump    "$th" "$wd"
    measure "$TMP/catchup.json" catchup "$th" "$wd"
  done
done

# The empty scenario must produce a header and a seal and nothing between them.
body=$(bash "$TRACE" "$TMP/empty.json" --theme c --width 80 | sed 's/\x1b\[[0-9;]*m//g' \
       | grep -cE '^(◆|▸|‡|≡|▤|✓) ')
runs=$((runs + 1))
if [ "$body" != "0" ]; then
  printf 'FAIL empty  rendered %s section rule(s), expected none\n' "$body"
  fails=$((fails + 1))
fi

# NO_COLOR must strip every escape byte, not merely most of them.
esc=$(NO_COLOR=1 bash "$TRACE" "$TMP/full.json" --theme b --width 80 | grep -c $'\033')
runs=$((runs + 1))
if [ "$esc" != "0" ]; then
  printf 'FAIL NO_COLOR  %s line(s) still carry escapes\n' "$esc"
  fails=$((fails + 1))
fi

printf '\n%d run(s), %d failure(s)\n' "$runs" "$fails"
[ "$MUTATE" = "1" ] && printf 'mutation mode: failures above are the PASS condition\n'
[ "$fails" -eq 0 ] || exit 1
