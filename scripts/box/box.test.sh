#!/usr/bin/env bash
# box.test.sh: the box renderer draws rows with markers, keeps wrapped text
# under its own column, stays square, and prints copy lines bare below the box.
set -uo pipefail
B="${BOX_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/box.sh}"
pass=0 fail=0
ok() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); printf '  FAIL: %s: got [%s] want [%s]\n' "$1" "$2" "$3"; fi; }
cols() { python3 -c '
import sys, unicodedata
w = 0
for ch in sys.argv[1]:
    if unicodedata.combining(ch) or ch in "️‍":
        continue
    w += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
print(w)' "$1"; }

out=$(bash "$B" dump s1 --attr "6h ago" --row next "a value long enough that it has to wrap onto a second line under its own column for sure" \
  --row you "short" --foot "📋 copy" --copy "/catchup at /abs/x.md" --copy "clo -n s1 \"/catchup at /abs/x.md\"")
top=$(printf '%s\n' "$out" | head -1)
bot=$(printf '%s\n' "$out" | rg '^└')
ok "top rule is 84 columns" "$(cols "$top")" "84"
ok "bottom rule is 84 columns" "$(cols "$bot")" "84"
ok "attr sits at the right end" "$(printf '%s' "$top" | rg -c '6h ago ──$')" "1"
ok "second line is a blank rail" "$(printf '%s\n' "$out" | sed -n '2p')" "│"
ok "next row carries its marker" "$(printf '%s\n' "$out" | rg -c '^│  ➡️ next  a value')" "1"
ok "wrapped text sits under the value column" "$(printf '%s\n' "$out" | rg -c '^│           [a-z]')" "1"
ok "labels are padded to one width" "$(printf '%s\n' "$out" | rg -c '^│  🟠 you   short$')" "1"
ok "footer text sits in the bottom rule" "$(printf '%s' "$bot" | rg -c '^└─ 📋 copy ─')" "1"
ok "a blank line separates box and copy lines" "$(printf '%s\n' "$out" | rg -n '^$' | cut -d: -f1)" "$(( $(printf '%s\n' "$out" | rg -n '^└' | cut -d: -f1) + 1 ))"
ok "copy lines print bare" "$(printf '%s\n' "$out" | tail -2 | rg -c '^(/catchup|clo) ')" "2"

g=$(bash "$B" gate g1 --row blocked:why "x" --copy "touch ~/.claude/.no-x")
ok "gate keeps heavy rails" "$(printf '%s\n' "$g" | head -1 | rg -c '^┏━ ⛔ gate · g1')" "1"
ok "gate bottom is heavy" "$(printf '%s\n' "$g" | rg -c '^┗━+$')" "1"
ok "a custom label replaces the role name" "$(printf '%s\n' "$g" | rg -c '^┃  🔴 why  x$')" "1"

bash "$B" dump s1 --row nope "x" >/dev/null 2>&1
ok "an unknown role is refused" "$?" "1"
bash "$B" dump s1 </dev/null >/dev/null 2>&1
ok "an empty box is refused" "$?" "1"

legacy=$(bash "$B" landing l1 --body "goal: g" --action "read it")
ok "--action renders as a next row" "$(printf '%s\n' "$legacy" | rg -c '^│  ➡️ next  read it$')" "1"
ok "--body renders unmarked" "$(printf '%s\n' "$legacy" | rg -c '^│  goal: g$')" "1"

printf -- '---\npass=%s fail=%s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
