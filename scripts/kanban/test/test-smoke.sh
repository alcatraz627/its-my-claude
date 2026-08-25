#!/usr/bin/env bash
# Everything the 2026-08-26 adversarial fix round changed, exercised together
# against a running server. Individually-verified pieces can still disagree once
# they share a process, which is what this catches: the milestone endpoint that
#404'd because it was declared in the POST block, and the milestone write that
# 500'd on a helper nobody had imported, both looked fine in isolation.
#
#   bash test/test-smoke.sh            # against the live server on :5106
#   PORT=6222 bash test/test-smoke.sh  # against the sandbox
set -uo pipefail
PORT="${PORT:-5106}"
S="http://localhost:$PORT"
pass=0; fail=0
ok(){ echo "  PASS  $1"; pass=$((pass+1)); }
no(){ echo "  FAIL  $1"; echo "     $2"; fail=$((fail+1)); }
# Presence before absence: every "must not contain" below is vacuously true on an
# empty response, so a dead server would otherwise read as a clean run.
alive(){ curl -s -o /dev/null -w '%{http_code}' "$S/" | grep -q 200; }

alive || { echo "no server on :$PORT — start it (pm2 restart kanban) and re-run"; exit 2; }
echo "server on :$PORT is up"

code(){ curl -s -o /dev/null -w '%{http_code}' "$@"; }
body(){ curl -s "$@"; }

echo; echo "-- the doc viewer's error pages (F17) --"
for probe in "no-path::$S/doc:400" \
             "a-directory::$S/doc?path=$HOME/.claude/scripts/kanban/docs:400" \
             "outside-allowlist::$S/doc?path=/etc/hosts:403" \
             "wrong-type::$S/doc?path=$HOME/.claude/scripts/kanban/server.ts:415"; do
  name="${probe%%::*}"; rest="${probe#*::}"; url="${rest%:*}"; want="${rest##*:}"
  got=$(code "$url"); page=$(body "$url")
  if [ "$got" != "$want" ]; then no "$name returns $want" "got $got"; continue; fi
  # An error page is still a page (charter §18c): it must wear the bar, not be raw JSON.
  case "$page" in
    *navbar*) ok "$name returns $want as a page with the bar" ;;
    *) no "$name returns $want as a page with the bar" "no navbar in the response" ;;
  esac
done
got=$(code "$S/doc?path=$HOME/.claude/scripts/kanban/docs/UI-CHARTER.md")
[ "$got" = "200" ] && ok "a real document still renders (200)" || no "a real document still renders" "got $got"

echo; echo "-- the renderer (F2, F3, F4) --"
bash "$(dirname "$0")/test-render.sh" >/tmp/smoke-render.out 2>&1
if tail -1 /tmp/smoke-render.out | grep -q 'fail=0'; then
  ok "test-render.sh: $(tail -1 /tmp/smoke-render.out)"
else
  no "test-render.sh" "$(tail -3 /tmp/smoke-render.out)"
fi

echo; echo "-- recorded decisions reach the hub, and unseen is reachable (F13) --"
j=$(body "$S/api/surfaces")
python3 - "$j" <<'PY' && ok "surfaces carries recorded decisions and a real seen flag" || no "surfaces carries recorded decisions" "see above"
import sys, json
d = json.loads(sys.argv[1])
ds = d.get("decisions", [])
assert ds, "no decisions at all"
assert d.get("recordedError") is None, f"recordedError: {d.get('recordedError')}"
kinds = {x.get("kind") for x in ds}
assert "recorded" in kinds, f"no recorded decisions in surfaces; kinds={kinds}"
# seen must be a real boolean per row, never hardcoded true for the recorded ones
rec = [x for x in ds if x.get("kind") == "recorded"]
assert all(isinstance(x.get("seen"), bool) for x in rec), "a recorded decision has a non-boolean seen"
PY

echo; echo "-- an answered decision page cannot be silently overwritten (claim 1) --"
ans=$(ls -d "$HOME/.claude/assets/decision-pages"/*/ 2>/dev/null | while read -r d; do
  [ -f "$d/.answer.json" ] && basename "$d" && break; done)
if [ -z "$ans" ]; then
  echo "  SKIP  no answered decision page on this machine to test against"
else
  got=$(code -X POST "$S/api/dp-submit/$ans" -H 'content-type: application/json' -d '{"answer":"SMOKE"}')
  [ "$got" = "409" ] && ok "re-submitting '$ans' is refused (409)" \
                     || no "re-submitting '$ans' is refused" "got $got — A RULING CAN BE OVERWRITTEN"
  # The guard's FIRST version read `!body?.replace`, which is truthiness, so
  # replace:"false" and replace:[] both sailed through and destroyed the ruling
  # with a 200. This suite was green throughout, because it only ever sent the
  # field ABSENT — the one input that happened to work. That is
  # [real-input-distribution]: the fixture was chosen by whoever wrote the check,
  # so it exercised the branch they had in mind. Every truthy-but-not-true shape
  # is sent now, and each is a separate row so a partial regression is legible.
  for bad in '"false"' '[]' '{}' '1' '"yes"'; do
    got=$(code -X POST "$S/api/dp-submit/$ans" -H 'content-type: application/json' \
          -d "{\"answer\":\"SMOKE\",\"replace\":$bad}")
    [ "$got" = "409" ] && ok "replace:$bad is not accepted as consent" \
                       || no "replace:$bad is not accepted as consent" "got $got — A RULING CAN BE OVERWRITTEN"
  done
fi

echo; echo "-- milestones as a registry kind (owner ruled 2026-08-26) --"
j=$(body "$S/api/milestones")
python3 - "$j" <<'PY' && ok "/api/milestones answers with counts and progress" || no "/api/milestones" "see above"
import sys, json
d = json.loads(sys.argv[1])
assert d.get("error") is None, d["error"]
assert "counts" in d and "milestones" in d, f"keys: {list(d)}"
for m in d["milestones"]:
    for k in ("name", "board", "cards", "done", "order"):
        assert k in m, f"milestone missing {k}: {m}"
    assert m["done"] <= m["cards"], f"{m['name']}: {m['done']} done of {m['cards']} cards"
PY
grep -q '"milestones"' "$(dirname "$0")/../kinds.js" && ok "milestones is in the kind registry" \
  || no "milestones is in the kind registry" "kinds.js has no milestones entry"
# The myopia check the owner asked for: no literal kind array outside the
# registry. Comments are stripped first — the fix for this very bug QUOTES the
# array it removed, so a naive grep matches the explanation and reports the bug
# as still present. A checker that reads its own prose as evidence is the
# wrong-moment failure this whole round was about.
hits=$(sed 's://.*::' "$(dirname "$0")/.."/*.html | rg -n '\["boards",\s*"' || true)
[ -z "$hits" ] && ok "no page hardcodes a kind list (owner, 2026-08-24)" \
               || no "no page hardcodes a kind list" "$hits"

echo; echo "-- the plan-change object (owner ruled 2026-08-26) --"
slug=$(body "$S/api/boards" | python3 -c "
import sys,json
bs=json.load(sys.stdin)['boards']
print(bs[0]['slug'] if bs else '')")
if [ -n "$slug" ]; then
  j=$(body "$S/api/changes?slug=$slug&since=30d")
  python3 - "$j" <<'PY' && ok "/api/changes answers for a real board" || no "/api/changes" "see above"
import sys, json
d = json.loads(sys.argv[1])
assert d.get("error") is None, d["error"]
assert "changes" in d and "count" in d, f"keys: {list(d)}"
PY
  got=$(code "$S/api/changes?slug=no-such-board")
  [ "$got" = "404" ] && ok "an unknown board is refused, not answered with an empty list" \
                     || no "an unknown board is refused" "got $got"
fi

echo; echo "-- the board tells the truth about dragging (F1) --"
# Two traps in one line, both found by mutation-testing this very check.
#
# 1. Comments are stripped, because the comment explaining why this string was
#    removed contains the string.
# 2. The result is CAPTURED rather than tested through the pipeline's exit
#    status. Under `set -o pipefail`, `sed ... | rg -q PATTERN` reports FAILURE
#    on a match: rg -q exits the moment it finds one, sed dies of SIGPIPE (141),
#    and pipefail surfaces that. So the guard read "match" as "clean" and stayed
#    green with the bug deliberately reinstated. A guard that inverts on success
#    is worse than no guard.
hits=$(sed 's://.*::' "$(dirname "$0")/../board.html" | rg 'Drag one here to move it' || true)
[ -z "$hits" ] && ok "no empty column instructs a drag the app cannot do" \
               || no "no empty column instructs a drag the app cannot do" "still live: $hits"

echo; echo "-- Escape does not write a durable collapse (prosecutor, 2nd highest) --"
coll=$(rg -U 'function closeDrawer[\s\S]{0,600}?setCollapsed\(true\)' "$(dirname "$0")/../board.html" || true)
[ -z "$coll" ] && ok "closeDrawer closes rather than durably collapsing" \
               || no "closeDrawer closes rather than durably collapsing" "setCollapsed(true) is back in closeDrawer"
# Captured, not piped, for the pipefail reason above.
lad=$(rg 'getElementById\("colcard"\)\) closeColCard' "$(dirname "$0")/../board.html" || true)
[ -n "$lad" ] && ok "a popover is first on the Escape ladder" \
              || no "a popover is first on the Escape ladder" "#colcard is not in the ladder"

echo
echo "======== pass=$pass fail=$fail ========"
[ "$fail" = 0 ]
