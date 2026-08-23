#!/usr/bin/env bash
# Suite for the owner-item lane (items, landings, pins). Runs against a throwaway
# KANBAN_ROOT so the owner's real store is never touched.
#
# Covers the two things the design turns on: an item is not board material until
# an agent classifies it, and classification works with no server running.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(mktemp -d "${TMPDIR:-/tmp}/kanban-items-XXXXXX")
export KANBAN_ROOT="$ROOT"
trap 'rm -rf "$ROOT"' EXIT

pass=0; fail=0
ok()  { printf '  PASS  %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  FAIL  %s\n     %s\n' "$1" "${2:-}"; fail=$((fail+1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]"; fi; }

echo "item lane suite on $ROOT"

# A project to own a board, so slug-scoping has something real to scope to.
PROJ="$ROOT/proj"; mkdir -p "$PROJ"
# The registry stores the realpath, and on macOS $TMPDIR is a symlink, so a cwd
# built from the un-resolved path matches nothing and the line reads empty.
REALPROJ=$(cd "$PROJ" && pwd -P)
printf '# TODO\n\n- [ ] a harvested card\n' > "$PROJ/TODO.md"
bun run "$HERE/cli.ts" init --project "$PROJ" >/dev/null 2>&1
SLUG=$(bun run "$HERE/cli.ts" status --project "$PROJ" --json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin).get("slug",""))' 2>/dev/null)
[ -n "$SLUG" ] || SLUG=$(python3 -c "
import json,os
print(list(json.load(open(os.path.join('$ROOT','registry.json')))['boards'])[0])" 2>/dev/null)

seed() {  # seed <id> <body> [slug] [starred]
  python3 - "$ROOT" "$1" "$2" "${3:-}" "${4:-}" <<'PY'
import json, os, sys, datetime
root, iid, body, slug, star = sys.argv[1:6]
p = os.path.join(root, "items.json")
d = json.load(open(p)) if os.path.exists(p) else {"items": []}
now = datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")
it = {"id": iid, "body": body, "createdAt": now, "updatedAt": now}
if slug: it["slug"] = slug
if star: it["starred"] = True
d["items"].append(it)
json.dump(d, open(p, "w"), indent=2)
PY
}

seed i1 "unassigned ask"
seed i2 "board ask" "$SLUG"
seed i3 "starred ask" "$SLUG" 1

n=$(bun run "$HERE/cli.ts" items --global --json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin)["pending"])')
check "all three seeded items are pending" "$n" "3"

first=$(bun run "$HERE/cli.ts" items --global --json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin)["items"][0]["id"])')
check "a starred item sorts to the front" "$first" "i3"

# The load-bearing one: classification is a file write, no server involved.
out=$(bun run "$HERE/cli.ts" classify i1 remark --note "left as a remark" 2>&1)
case "$out" in *"classified i1 as remark"*) ok "classify records a landing with no server running" ;;
  *) bad "classify records a landing with no server running" "$out" ;; esac

n=$(bun run "$HERE/cli.ts" items --global --json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin)["pending"])')
check "a classified item leaves the pending set" "$n" "2"

out=$(bun run "$HERE/cli.ts" classify i2 nonsense 2>&1)
case "$out" in *"usage"*) ok "an unknown shape is refused" ;; *) bad "an unknown shape is refused" "$out" ;; esac

out=$(bun run "$HERE/cli.ts" classify i2 task --card zzz 2>&1)
case "$out" in *"12-hex"*) ok "a malformed card id is refused" ;; *) bad "a malformed card id is refused" "$out" ;; esac

out=$(bun run "$HERE/cli.ts" classify i2 task --card aaaaaaaaaaaa 2>&1)
case "$out" in *"not on any board"*) ok "a card id on no board is refused, so no dead landing link" ;;
  *) bad "a card id on no board is refused" "$out" ;; esac

out=$(bun run "$HERE/cli.ts" classify nosuch remark 2>&1)
case "$out" in *"no item nosuch"*) ok "classifying a missing item is refused" ;; *) bad "classifying a missing item is refused" "$out" ;; esac

# Archive is computed from the landing timestamp, so backdating one is the whole test.
python3 - "$ROOT" <<'PY'
import json, os, sys, datetime
p = os.path.join(sys.argv[1], "landings.json")
d = json.load(open(p))
old = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=8)
d["landings"]["i1"]["at"] = old.isoformat().replace("+00:00", "Z")
json.dump(d, open(p, "w"), indent=2)
PY
arch=$(bun run "$HERE/cli.ts" items --global --all 2>/dev/null | grep -c '\[archived\]')
check "a landing older than 7 days reads as archived" "$arch" "1"

# Board scoping keeps the unassigned ones: they are routable to any board.
scoped=$(bun run "$HERE/cli.ts" items --project "$PROJ" --json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin)["pending"])')
check "board scope keeps its own items plus the unassigned" "$scoped" "2"

# The session-start line is the sweep path; it must name unsorted asks.
line=$(printf '{"cwd":"%s"}' "$REALPROJ" | KANBAN_ROOT="$ROOT" bash "$HERE/session-start-line.sh" 2>/dev/null)
case "$line" in *"unsorted asks"*) ok "the session-start line names unsorted asks" ;;
  *) bad "the session-start line names unsorted asks" "${line:-<empty>}" ;; esac

bun run "$HERE/cli.ts" classify i2 remark >/dev/null 2>&1
bun run "$HERE/cli.ts" classify i3 remark >/dev/null 2>&1
line=$(printf '{"cwd":"%s"}' "$REALPROJ" | KANBAN_ROOT="$ROOT" bash "$HERE/session-start-line.sh" 2>/dev/null)
# Two assertions, not one: an empty line would satisfy "no clause" while proving
# nothing, so the board line must still render for the absence to mean anything.
case "$line" in
  *"unsorted asks"*) bad "the clause disappears once everything is sorted" "$line" ;;
  *"[kanban] board"*) ok "the clause disappears once everything is sorted, line still renders" ;;
  *) bad "the clause disappears once everything is sorted" "line was empty, so the absence proves nothing: ${line:-<empty>}" ;;
esac

# --- display-scope tags (owner ruling 2026-08-17) --------------------------
# Visibility is a display rule layered on the data, so an ask can be shown on
# boards other than the one it was written on, and hidden from the rest.

PROJ2="$ROOT/proj2"; mkdir -p "$PROJ2"; printf '# TODO\n\n- [ ] another\n' > "$PROJ2/TODO.md"
REALPROJ2=$(cd "$PROJ2" && pwd -P)
bun run "$HERE/cli.ts" init --project "$PROJ2" >/dev/null 2>&1
SLUG2=$(python3 -c "
import json,os
r=json.load(open(os.path.join('$ROOT','registry.json')))['boards']
print(next(s for s in r if s != '$SLUG'))")

seed s1 "unscoped, shows on every rail"
pre1=$(bun run "$HERE/cli.ts" items --project "$PROJ"  --json 2>/dev/null | python3 -c 'import sys,json;print("yes" if any(i["id"]=="s1" for i in json.load(sys.stdin)["items"]) else "no")')
pre2=$(bun run "$HERE/cli.ts" items --project "$PROJ2" --json 2>/dev/null | python3 -c 'import sys,json;print("yes" if any(i["id"]=="s1" for i in json.load(sys.stdin)["items"]) else "no")')
check "an untagged ask shows on board one" "$pre1" "yes"
check "an untagged ask shows on board two as well" "$pre2" "yes"

# Now scope it to board TWO only; board one must stop seeing it.
SCOPE_TO="$SLUG2" python3 - "$ROOT" <<'PY'
import json, os, sys
p = os.path.join(sys.argv[1], "items.json")
d = json.load(open(p))
for i in d["items"]:
    if i["id"] == "s1": i["boards"] = [os.environ["SCOPE_TO"]]
json.dump(d, open(p, "w"), indent=2)
PY
seen1=$(bun run "$HERE/cli.ts" items --project "$PROJ"  --json 2>/dev/null | python3 -c 'import sys,json;print("yes" if any(i["id"]=="s1" for i in json.load(sys.stdin)["items"]) else "no")')
seen2=$(bun run "$HERE/cli.ts" items --project "$PROJ2" --json 2>/dev/null | python3 -c 'import sys,json;print("yes" if any(i["id"]=="s1" for i in json.load(sys.stdin)["items"]) else "no")')
check "a scoped ask is hidden from the board it is not tagged to" "$seen1" "no"
check "a scoped ask is visible on the board it IS tagged to" "$seen2" "yes"

# The session line mirrors the same rule in jq; both sides must agree.
l1=$(printf '{"cwd":"%s"}' "$REALPROJ"  | KANBAN_ROOT="$ROOT" bash "$HERE/session-start-line.sh" 2>/dev/null)
l2=$(printf '{"cwd":"%s"}' "$REALPROJ2" | KANBAN_ROOT="$ROOT" bash "$HERE/session-start-line.sh" 2>/dev/null)
case "$l2" in *"unsorted asks"*) ok "the session line on the tagged board counts the scoped ask" ;;
  *) bad "the session line on the tagged board counts the scoped ask" "$l2" ;; esac
# By now every ask of board one's own is sorted and s1 was scoped to board two,
# so board one must show NO asks clause while board two does. Both halves are
# asserted: a blank line would satisfy "no clause" while proving nothing.
case "$l1" in
  *"unsorted asks"*) bad "the scoped ask is gone from the board it is not tagged to" "board one still counts it: $l1" ;;
  *"[kanban] board"*) ok "the scoped ask is gone from the board it is not tagged to, line still renders" ;;
  *) bad "the scoped ask is gone from the board it is not tagged to" "line was empty, so the absence proves nothing: ${l1:-<empty>}" ;;
esac

# --- regressions from the 2026-08-17 adversarial review -------------------
# Each of these shipped broken and was caught by prosecution, not by this suite.

out=$(bun run "$HERE/cli.ts" classify i1 --undo 2>&1)
case "$out" in *"unclassified i1"*) ok "classify --undo retracts a landing (finding 7)" ;;
  *) bad "classify --undo retracts a landing" "$out" ;; esac
back=$(bun run "$HERE/cli.ts" items --global --json 2>/dev/null | python3 -c 'import sys,json;print("yes" if any(i["id"]=="i1" and not i.get("landing") for i in json.load(sys.stdin)["items"]) else "no")')
check "an undone item is pending again" "$back" "yes"

# Deleting an ask must not leave its landing behind: ids are short and
# recyclable, so a stale landing makes a fresh ask arrive pre-sorted.
bun run "$HERE/cli.ts" classify i1 remark >/dev/null 2>&1
python3 - "$ROOT" <<'PY'
import json, os, sys
p = os.path.join(sys.argv[1], "items.json")
d = json.load(open(p))
d["items"] = [i for i in d["items"] if i["id"] != "i1"]
json.dump(d, open(p, "w"), indent=2)
PY
bun run "$HERE/cli.ts" items --global >/dev/null 2>&1   # the GC runs here
orph=$(python3 -c "
import json,os,sys
print('yes' if 'i1' in json.load(open(os.path.join('$ROOT','landings.json')))['landings'] else 'no')")
check "a deleted ask's landing is swept (finding 12)" "$orph" "no"

# A corrupt store must never read as an empty queue: all three readers report.
cp "$ROOT/items.json" "$ROOT/items.ok"
printf '{"items": [ {"id":"x1","body":"half a wri' > "$ROOT/items.json"

out=$(bun run "$HERE/cli.ts" items --global 2>&1)
case "$out" in *"could not be read"*) ok "the CLI names a corrupt store, not a stack trace (finding 1)" ;;
  *) bad "the CLI names a corrupt store" "$(printf '%s' "$out" | head -2)" ;; esac

line=$(printf '{"cwd":"%s"}' "$REALPROJ" | KANBAN_ROOT="$ROOT" bash "$HERE/session-start-line.sh" 2>/dev/null)
case "$line" in
  *"could not be read"*) ok "the session line warns on a corrupt store instead of going quiet (finding 1)" ;;
  *"unsorted asks"*) bad "the session line warns on a corrupt store" "it reported counts off a broken file: $line" ;;
  *) bad "the session line warns on a corrupt store" "it fell silent, which reads as nothing to do: ${line:-<empty>}" ;;
esac
cp "$ROOT/items.ok" "$ROOT/items.json"

# show --json carries goal and tags on the card object. They live in plan.json,
# and an agent reading the card alone used to get neither (vb-fable, #49).
BDIR=$(python3 -c "
import json,os; r=json.load(open(os.path.join('$ROOT','registry.json')))['boards']
print(r['$SLUG']['dir'] if isinstance(r['$SLUG'],dict) and 'dir' in r['$SLUG'] else os.path.join('$ROOT','boards','$SLUG'))")
CARD=$(python3 -c "import json;print(json.load(open('$BDIR/board.json'))['cards'][0]['id'])" 2>/dev/null)
if [ -n "$CARD" ]; then
  python3 - "$BDIR" "$CARD" <<'PY'
import json,sys,os
d,c=sys.argv[1],sys.argv[2]
json.dump({"tags":[{"id":"t1","name":"M2","kind":"milestone","createdAt":"2026-08-23T00:00:00Z"}],
           "on":{c:["t1"]},"goals":{c:"prove the contract"},"updatedAt":None}, open(os.path.join(d,"plan.json"),"w"))
PY
  got=$(bun run "$HERE/cli.ts" show "$CARD" --project "$PROJ" --json 2>/dev/null | python3 -c 'import sys,json;c=json.load(sys.stdin)["card"];print(c.get("goal"),"|",",".join(t["kind"]+":"+t["name"] for t in c.get("tags",[])))')
  check "show --json carries goal and tags on the card object (#49)" "$got" "prove the contract | milestone:M2"
  # execution order rides the same store; a predecessor that is not on the board is dropped when served, kept raw here
  python3 - "$BDIR" "$CARD" <<'PY'
import json,sys,os
d,c=sys.argv[1],sys.argv[2]; p=json.load(open(os.path.join(d,"plan.json"))); p["seq"]={c:["aaaaaaaaaaaa"]}
json.dump(p, open(os.path.join(d,"plan.json"),"w"))
PY
  got=$(bun run "$HERE/cli.ts" show "$CARD" --project "$PROJ" --json 2>/dev/null | python3 -c 'import sys,json;print(",".join(json.load(sys.stdin)["card"].get("after",[])))')
  check "show --json carries the card's execution order (after)" "$got" "aaaaaaaaaaaa"
else
  bad "show --json carries goal and tags" "no card in the fixture board to show"
fi

# drop with no server: plan rows cannot be forgotten (the server owns plan.json),
# so the CLI must say so rather than go quiet. The server path was exercised live
# on 2026-08-23 (task #43's note); this pins the honest fallback.
if [ -n "$CARD" ]; then
  err=$(bun run "$HERE/cli.ts" drop "$CARD" --project "$PROJ" 2>&1 >/dev/null)
  still=$(python3 -c "import json;p=json.load(open('$BDIR/plan.json'));print(bool(p['on'].get('$CARD')), bool(p['goals'].get('$CARD')))")
  case "$err" in *"NOT removed"*) ok "drop without a server says the plan rows were not removed (#43)" ;;
    *) bad "drop without a server says the plan rows were not removed (#43)" "$err" ;; esac
  check "and the rows really are still there, so the message is true" "$still" "True True"
fi

printf '  ---- %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
