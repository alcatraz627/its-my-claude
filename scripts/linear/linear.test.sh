#!/usr/bin/env bash
# Exercise /linear's script. Offline by default: markdown conversion, the read path refusing a
# mutation, estimate scales, and that no command prints the key. With --live it also runs every
# read verb against the real workspace and previews writes, which send nothing without --yes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
L="python3 $HERE/linear.py"
T=$(mktemp -d)
pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok    $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL  $1"; }
has()  { if printf '%s' "$2" | rg -q -- "$1"; then ok "$3"; else bad "$3 (wanted /$1/)"; fi; }
lacks(){ if printf '%s' "$2" | rg -q -- "$1"; then bad "$3 (found /$1/)"; else ok "$3"; fi; }
ALL=""

echo "# markdown conversion"
cat > "$T/a.md" <<'MD'
---
key: a
---
# Title

<!-- sessions: x -->

| k | v |
|---|---|
| row | Lead.<br>• one<br>• two |

See [b](b.md#section) and [c](c.md).
MD
cat > "$T/b.md" <<'MD'
# B
MD
printf '{"issue":"VER-1","docs":["a.md","b.md"]}' > "$T/cfg.json"
out=$($L docs publish "$T/cfg.json" --dry-run 2>&1); ALL="$ALL$out"
has "preview written" "$out" "dry run writes a preview without calling Linear"
prev=$(cat "$T/.linear-preview/a.md")
lacks "<br>" "$prev" "no <br> left in table cells"
has "Lead\. • one • two" "$prev" "cell bullets joined on one line"
lacks "<!--" "$prev" "HTML comments stripped"
lacks "^key:" "$prev" "frontmatter stripped"
has "\[b\]\(https://linear.app/doc/b\)" "$prev" "link to a file in the set rewritten, anchor dropped"
has "\[c\]\(c\.md\)" "$prev" "link to a file outside the set left alone"

echo "# read path refuses a mutation"
out=$(python3 -c "
import sys; sys.path.insert(0, '$HERE')
import client
c = client.Client(key='x')
try:
    c.read('mutation { issueUpdate(id:\"x\", input:{}) { success } }')
    print('SENT')
except SystemExit as e:
    print(e)
" 2>&1); ALL="$ALL$out"
has "refuses a mutation" "$out" "Client.read() refuses mutation text"
lacks "SENT" "$out" "nothing sent"

echo "# estimate scales"
out=$(python3 -c "
import sys; sys.path.insert(0, '$HERE')
import client
r = client.Resolver(None)
r._cache['team'] = {'key':'VER','issueEstimationType':'fibonacci','issueEstimationAllowZero':True,'issueEstimationExtended':True}
print(r.allowed_estimates())
try:
    r.estimate(4)
except SystemExit as e:
    print(e)
" 2>&1); ALL="$ALL$out"
has "\[0, 1, 2, 3, 5, 8, 13, 21\]" "$out" "fibonacci extended with zero"
has "estimate 4 is not on team VER" "$out" "off-scale estimate refused before sending"

echo "# name matching"
out=$(python3 -c "
import sys; sys.path.insert(0, '$HERE')
import client
items = [{'name':'In Review'},{'name':'In Progress'},{'name':'Review / Testing'}]
print(client.pick('state','in review',items)['name'])
try:
    client.pick('state','in',items)
except SystemExit as e:
    print(e)
try:
    client.pick('state','nope',items)
except SystemExit as e:
    print(e)
" 2>&1); ALL="$ALL$out"
has "^In Review$" "$out" "exact match wins over prefix matches"
has "matches several" "$out" "an ambiguous name lists the candidates"
has "no state named 'nope'. Closest" "$out" "a miss names the closest options"

if [ "${1:-}" = "--live" ]; then
  echo "# live reads (Versable)"
  for cmd in "whoami" "issue show VER-986" "issues --cycle current --limit 5" "issues --mine --limit 5" "search sor --limit 3" \
             "search system --docs --limit 3" "projects" "project show V6" "milestones V6" "cycle current" "cycle next" \
             "points --cycle current" "points --project V6" "labels" "states" "users" "templates" "views" "comments VER-986" "docs list VER-986"; do
    out=$($L $cmd 2>&1); rc=$?; ALL="$ALL$out"
    [ $rc -eq 0 ] && ok "$cmd" || bad "$cmd: $(printf '%s' "$out" | tail -1)"
  done
  out=$($L doc history 41d2fc5cb790 2>&1); ALL="$ALL$out"
  has "2026-09-28" "$out" "doc history returns the revision of VER-986's 08 document"
  out=$($L --json issues --limit 2 2>&1); ALL="$ALL$out"
  printf '%s' "$out" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null && ok "--json output parses" || bad "--json output is not JSON"
  out=$($L issues --state nope 2>&1); rc=$?
  [ $rc -ne 0 ] && ok "unknown state exits non-zero" || bad "unknown state exited 0"
  has "Closest" "$out" "unknown state lists closest names"
  echo "# live write previews (nothing sent)"
  out=$($L issue update VER-986 --state "In Review" --estimate 3 --cycle next 2>&1); ALL="$ALL$out"
  has "Nothing sent" "$out" "update without --yes sends nothing"
  has "state: In Review" "$out" "preview shows the resolved state"
  has "cycle: 97" "$out" "preview resolves next cycle"
  out=$($L issue update VER-986 --estimate 4 2>&1); rc=$?
  [ $rc -ne 0 ] && ok "off-scale estimate stops the preview" || bad "off-scale estimate accepted"
  out=$($L docs publish /Users/alcatraz627/Code/Versable/sor/linear.json 2>&1); ALL="$ALL$out"
  has "Nothing sent" "$out" "publish without --yes sends nothing"
  n_up=$(printf '%s\n' "$out" | rg -c "^  update ")
  n_new=$(printf '%s\n' "$out" | rg -c "^  create ")
  [ "$n_up" = "9" ] && ok "publish plan updates the 9 existing documents" || bad "publish plan updates $n_up, wanted 9"
  [ "$n_new" = "3" ] && ok "publish plan creates only 09, 10, 11" || bad "publish plan creates $n_new, wanted 3"
  has "empty on Linear today" "$out" "the empty 03 document is flagged"
fi

echo "# the key never appears in output"
lacks "lin_api_" "$ALL" "no lin_api_ string in any output"

rm -rf "$T"
echo "$pass passed, $fail failed"
[ $fail -eq 0 ]
