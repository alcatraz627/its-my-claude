#!/usr/bin/env bash
# prefer-tmp-py-over-inline.test.sh — nudge behaviour + heed measurement.
#
# The hook nudges on a multi-line inline `python3 -c`, then measures whether the
# agent's NEXT python run switched to a script file (heeded) or went inline again
# (ignored). The heed lines are what hook-health.sh reads to compute a real rate.
#
# Isolation: WARN_LOG_STORE redirects the ledger to a temp file so tests never
# touch the live audit log; the session marker uses a test sid.
#
# Run: bash ~/.claude/scripts/hooks/prefer-tmp-py-over-inline.test.sh  (exit 0 = pass)

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/prefer-tmp-py-over-inline.sh"

STORE="$(mktemp "${TMPDIR:-/tmp}/ptpo-ledger-XXXXXX")"
export WARN_LOG_STORE="$STORE"
export CLAUDE_SESSION_ID="testptpo-1111-2222-3333-444455556666"
SID8="testptpo"
MARK="/tmp/claude-tmp-py-nudge-${SID8}"
rm -f "$MARK"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }

# feed <command> -> runs the hook, returns "NUDGE" if it emitted additionalContext, else "quiet"
feed(){
  local out
  out=$(printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)" | bash "$HOOK" 2>/dev/null)
  if printf '%s' "$out" | grep -q 'additionalContext'; then echo NUDGE; else echo quiet; fi
}
# last heed verdict written to the ledger (true|false|none)
last_heed(){ jq -r 'select(.kind=="heed") | .heeded' "$STORE" 2>/dev/null | tail -1; }
heed_count(){ jq -r 'select(.kind=="heed")' "$STORE" 2>/dev/null | jq -s length; }

# multi-line bodies (>5 newlines) for the inline case
BIG=$'import sys\nimport os\nimport re\nimport json\nx=1\ny=2\nz=3\nprint(x)'

echo "── nudge trigger ──"
ok "inline -c >5 newlines nudges"     "$(feed "python3 -c '$BIG'")"          NUDGE
ok "short one-liner stays quiet"      "$(feed "python3 -c 'print(1)'")"       quiet
ok "script file stays quiet"          "$(feed 'python3 /tmp/foo.py')"         quiet
ok "non-python stays quiet"           "$(feed 'ls -la')"                      quiet

echo "── heed = true: nudge, then switch to a script file ──"
rm -f "$MARK"; : > "$STORE"
feed "python3 -c '$BIG'" >/dev/null            # arms the marker
ok "marker armed after nudge"          "$([ -f "$MARK" ] && echo yes || echo no)"  yes
feed 'python3 /tmp/slug.py' >/dev/null         # switched to a script → heeded
ok "heed recorded true"                "$(last_heed)"                          true
ok "marker cleared after resolve"      "$([ -f "$MARK" ] && echo yes || echo no)"  no

echo "── heed = false: nudge, then go inline again ──"
rm -f "$MARK"; : > "$STORE"
feed "python3 -c '$BIG'" >/dev/null            # arms
feed "python3 -c '$BIG'" >/dev/null            # inline again → ignored (and re-arms)
ok "heed recorded false"               "$(last_heed)"                          false
ok "re-armed for the next run"         "$([ -f "$MARK" ] && echo yes || echo no)"  yes

echo "── an unrelated command between does NOT resolve the nudge ──"
rm -f "$MARK"; : > "$STORE"
feed "python3 -c '$BIG'" >/dev/null            # arms
feed 'ls -la' >/dev/null                       # 'other' → leave marker alone
ok "no heed line from unrelated cmd"   "$(heed_count)"                         0
ok "marker still armed"                "$([ -f "$MARK" ] && echo yes || echo no)"  yes

echo "── mute suppresses everything ──"
# Never clobber a real user mute file: only exercise this if it doesn't pre-exist.
MUTE="$HOME/.claude/.no-inline-py-hint"
if [ -f "$MUTE" ]; then
  echo "  (skipped — mute file already set by the user; not touching it)"
else
  rm -f "$MARK"; : > "$STORE"
  touch "$MUTE"
  ok "muted -> quiet"                  "$(feed "python3 -c '$BIG'")"           quiet
  ok "muted -> no marker"              "$([ -f "$MARK" ] && echo yes || echo no)"  no
  rm -f "$MUTE"
fi

rm -f "$MARK" "$STORE"
echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
