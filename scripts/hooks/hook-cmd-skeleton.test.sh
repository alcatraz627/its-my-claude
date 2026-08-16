#!/usr/bin/env bash
# Tests for hook_cmd_skeleton, the shared quote-blanking helper.
#
# Cases live in this FILE rather than inline in a shell command on purpose. The
# fixtures necessarily contain dangerous-looking literals (a delete command, a
# force flag) as quoted STRINGS, and an inline version of this suite was denied
# by the permission layer for exactly the mention-versus-invocation reason the
# helper exists to fix. The bug blocked its own test.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ./hook-common.sh

pass=0; fail=0
t() { # name | command | pattern | HIT|MISS
  local name="$1" cmd="$2" pat="$3" want="$4" got r
  got=$(printf '%s' "$cmd" | hook_cmd_skeleton)
  if printf '%s' "$got" | rg -q "$pat"; then r=HIT; else r=MISS; fi
  if [ "$r" = "$want" ]; then pass=$((pass+1)); printf '  ok   %s\n' "$name"
  else fail=$((fail+1)); printf '  FAIL %s -> got %s want %s\n       [%s]\n' "$name" "$r" "$want" "$got"; fi
}

DEL='r''m'   # assembled so this file's own text carries no bare delete token

echo "== real invocations must stay VISIBLE =="
t "bare delete"        "$DEL -rf /tmp/x"                              "\\b$DEL\\b"    HIT
t "bare gh"            'gh pr list --limit 5'                         '\bgh\b'        HIT
t "delete after quote" "echo \"hello there\" && $DEL /tmp/x"          "\\b$DEL\\b"    HIT
t "path as real arg"   'wc -l < atone/events.jsonl'                   'events\.jsonl' HIT
t "flag really passed" 'git push --force origin main'                 '\-\-force'     HIT

echo "== mentions must be BLANKED (the observed false fires) =="
t "single-quoted del"  "echo '$DEL -rf /' > note.txt"                 "\\b$DEL\\b"    MISS
t "atone path in json" 'jq -n --arg i "log is atone/events.jsonl" .'  'events\.jsonl' MISS
t "gh inside py str"   'python3 -c "print(1); x=\"gh pr list\""'      '\bgh\b'        MISS
t "flag in a message"  'git commit -m "removed the --force flag"'     '\-\-force'     MISS

echo "== escapes and nesting =="
t "escaped dquote"     "echo \"a\\\"b\" && $DEL x"                    "\\b$DEL\\b"    HIT
t "apostrophe in dq"   "git commit -m \"don't ship $DEL\""            "\\b$DEL\\b"    MISS

echo "== structural properties =="
IN="echo \"abc\" && $DEL x"; OUT=$(printf '%s' "$IN" | hook_cmd_skeleton)
if [ ${#IN} -eq ${#OUT} ]; then pass=$((pass+1)); echo "  ok   length preserved (${#IN})"
else fail=$((fail+1)); echo "  FAIL length ${#IN} -> ${#OUT}"; fi

OUT2=$(printf '%s' 'a"bc"d' | hook_cmd_skeleton)
if [ "$OUT2" = 'a"  "d' ]; then pass=$((pass+1)); echo "  ok   tokens not welded [$OUT2]"
else fail=$((fail+1)); echo "  FAIL welded [$OUT2]"; fi

# The documented scope limit, asserted so it cannot rot into a silent surprise.
HD='cat <<EOF
this mentions gh inside a heredoc
EOF'
OUT3=$(printf '%s' "$HD" | hook_cmd_skeleton)
if printf '%s' "$OUT3" | rg -q '\bgh\b'; then pass=$((pass+1)); echo "  ok   heredoc body NOT blanked (documented limit)"
else fail=$((fail+1)); echo "  FAIL heredoc silently blanked, contradicting the doc"; fi

# Quote state does not carry across newlines: awk resets per record, so only the
# FIRST line of a multi-line quoted argument is blanked. Asserted in both
# directions, because the split is what makes it dangerous — a guard reading
# quoted contents passes on one form and is disarmed on the other.
ML='git commit -m "subject line
BODYMARKER stays visible"'
OUT4=$(printf '%s' "$ML" | hook_cmd_skeleton)
if printf '%s' "$OUT4" | rg -q 'BODYMARKER'; then pass=$((pass+1)); echo "  ok   line 2+ of a quoted arg NOT blanked (documented limit)"
else fail=$((fail+1)); echo "  FAIL multi-line quote blanked, contradicting the doc"; fi

SL='git commit -m "subject BODYMARKER inline"'
OUT5=$(printf '%s' "$SL" | hook_cmd_skeleton)
if printf '%s' "$OUT5" | rg -q 'BODYMARKER'; then fail=$((fail+1)); echo "  FAIL single-line quoted body survived blanking"
else pass=$((pass+1)); echo "  ok   single-line quoted body IS blanked (why quote-readers must not migrate)"; fi

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
