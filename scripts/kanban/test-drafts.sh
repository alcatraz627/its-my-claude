#!/usr/bin/env bash
# Suite for the draft lane (drafts, pulls, templates). Runs against a throwaway
# KANBAN_ROOT so the owner's real store is never touched.
#
# Covers what the rung turns on: a draft becomes project material only when an
# agent pulls it, a template is reused rather than consumed, and both work with
# no server running.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(mktemp -d "${TMPDIR:-/tmp}/kanban-drafts-XXXXXX")
export KANBAN_ROOT="$ROOT"
trap 'rm -rf "$ROOT"' EXIT

pass=0; fail=0
ok()  { printf '  PASS  %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  FAIL  %s\n     %s\n' "$1" "${2:-}"; fail=$((fail+1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]"; fi; }
# -F, not -q alone: these patterns carry [brackets], which a basic regex reads as
# a character class. The bracketed form made one assertion fail loudly and its
# sibling pass vacuously, which is the worse half.
has()   { if printf '%s' "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1" "no [$3] in [$2]"; fi; }
hasnt() { if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1" "unwanted [$3] in [$2]"; else ok "$1"; fi; }

K() { bun run "$HERE/cli.ts" "$@" 2>&1; }

echo "draft lane suite on $ROOT"

# Two projects, so board scoping has something real to scope to AND something
# real to scope away from.
PROJ="$ROOT/proj"; mkdir -p "$PROJ"
printf '# TODO\n\n- [ ] a harvested card\n' > "$PROJ/TODO.md"
K init --project "$PROJ" >/dev/null
OTHER="$ROOT/other"; mkdir -p "$OTHER"
printf '# TODO\n\n- [ ] elsewhere\n' > "$OTHER/TODO.md"
K init --project "$OTHER" >/dev/null
slug_of() {
  python3 - "$ROOT" "$1" <<'PY'
import json, os, sys
reg = json.load(open(os.path.join(sys.argv[1], "registry.json")))["boards"]
want = os.path.realpath(sys.argv[2])
for s, b in reg.items():
    if os.path.realpath(b["root"]) == want: print(s); break
PY
}
SLUG=$(slug_of "$PROJ")
SLUG2=$(slug_of "$OTHER")
CARD=$(python3 - "$ROOT" "$SLUG" <<'PY'
import json, os, sys
b = json.load(open(os.path.join(sys.argv[1], "boards", sys.argv[2], "board.json")))
print(b["cards"][0]["id"] if b["cards"] else "")
PY
)

seed() {  # seed <id> <body> [title] [slug] [template]
  python3 - "$ROOT" "$1" "$2" "${3:-}" "${4:-}" "${5:-}" <<'PY'
import json, os, sys, datetime
root, did, body, title, slug, tpl = sys.argv[1:7]
p = os.path.join(root, "drafts.json")
d = json.load(open(p)) if os.path.exists(p) else {"drafts": []}
now = datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")
rec = {"id": did, "body": body, "createdAt": now, "updatedAt": now}
if title: rec["title"] = title
if slug:  rec["slug"] = slug
if tpl:   rec["isTemplate"] = True
d["drafts"].append(rec)
json.dump(d, open(p, "w"), indent=2)
PY
}

# ---- 1. an empty store is a state, not a crash ------------------------------
out=$(K drafts --global)
check "empty store says so" "$out" "no drafts pending"
out=$(K drafts --templates)
check "empty template list says so" "$out" "no templates"

# ---- 2. what the sweep offers ----------------------------------------------
seed d1 "# Parser rewrite

Streaming, not slurp." "Parser rewrite"
seed d2 "scoped to this project" "" "$SLUG"
seed d3 "scoped elsewhere" "" "$SLUG2"
seed t1 "## What happened

## Expected" "Bug report" "" 1

out=$(K drafts --global)
has   "pending lists an unassigned draft" "$out" "d1"
has   "pending lists a same-board draft"  "$out" "d2"
hasnt "pending hides a template"          "$out" "t1"
out=$(K drafts --templates)
has   "template list shows the template"  "$out" "t1"
hasnt "template list hides a draft"       "$out" "d1"

# Board scoping: run from inside the project so the CLI resolves its own board.
out=$(cd "$PROJ" && K drafts)
has   "in-project sweep keeps its own board's draft" "$out" "d2"
has   "in-project sweep keeps unassigned drafts"     "$out" "d1"
hasnt "in-project sweep drops another board's draft" "$out" "d3"

# ---- 3. reading one in full is what a pull reads ---------------------------
out=$(K drafts d1)
has "reading a draft prints its body"  "$out" "Streaming, not slurp"
has "reading a draft prints its title" "$out" "Parser rewrite"
has "reading a pending draft names the pull command" "$out" "kanban.sh pull d1"
out=$(K drafts t1)
hasnt "reading a template does not offer a pull" "$out" "kanban.sh pull"

# ---- 4. the pull records the link -----------------------------------------
out=$(K pull d1 --card "$CARD" --note "made it a card")
has "pull confirms" "$out" "pulled d1"
rec=$(python3 - "$ROOT" <<'PY'
import json, os, sys
p = json.load(open(os.path.join(sys.argv[1], "pulls.json")))["pulls"]["d1"]
print(p.get("cardId", "-"), p.get("slug", "-"), p.get("note", "-"), sep="|")
PY
)
check "pull stores the card, its board, and the note" "$rec" "$CARD|$SLUG|made it a card"

out=$(K drafts --global)
hasnt "a pulled draft leaves the pending sweep" "$out" "d1  [pending]"
out=$(K drafts --all --global)
has "--all still shows the pulled one" "$out" "d1"

# ---- 5. reversal ----------------------------------------------------------
out=$(K pull d1 --undo)
has "undo confirms" "$out" "un-pulled d1"
out=$(K drafts --global)
has "an un-pulled draft is pending again" "$out" "d1"
out=$(K pull d1 --undo)
has "undo on an unpulled draft refuses" "$out" "not pulled"

# ---- 6. refusals ---------------------------------------------------------
out=$(K pull t1)
has "pull refuses a template" "$out" "is a template"
out=$(K pull d2 --card "zz")
has "pull refuses a malformed card id" "$out" "12-hex"
out=$(K pull d2 --card "aaaaaaaaaaaa")
has "pull refuses a card on no board" "$out" "not on any board"
out=$(K pull nosuch)
has "pull refuses an unknown draft" "$out" "no draft nosuch"

# ---- 7. the recycled-id trap --------------------------------------------
# ids are 8 chars and reusable, so a pull left behind by a deleted draft would
# make the next draft to take that id arrive already consumed and invisible.
K pull d2 --note "consumed" >/dev/null
python3 - "$ROOT" <<'PY'
import json, os, sys
p = os.path.join(sys.argv[1], "drafts.json")
d = json.load(open(p))
d["drafts"] = [x for x in d["drafts"] if x["id"] != "d2"]
json.dump(d, open(p, "w"), indent=2)
PY
K drafts --global >/dev/null            # the sweep is what GCs the orphan
left=$(python3 - "$ROOT" <<'PY'
import json, os, sys
print(",".join(sorted(json.load(open(os.path.join(sys.argv[1], "pulls.json")))["pulls"])))
PY
)
check "a deleted draft's pull is swept" "$left" ""
seed d2 "a different draft that recycled the id"
out=$(K drafts --global)
has "the id's new owner arrives pending, not pre-consumed" "$out" "d2  [pending]"

# ---- 8. a broken store must name itself broken --------------------------
cp "$ROOT/drafts.json" "$ROOT/drafts.ok.json"
printf '{ this is not json' > "$ROOT/drafts.json"
out=$(K drafts --global); rc=$?
has  "a broken store says what is wrong" "$out" "could not be read"
if [ "$rc" -ne 0 ]; then ok "a broken store exits non-zero"; else bad "a broken store exits non-zero" "got 0"; fi
hasnt "a broken store never reads as an empty desk" "$out" "no drafts pending"
cp "$ROOT/drafts.ok.json" "$ROOT/drafts.json"

# ---- 9. no server was ever running -------------------------------------
if [ ! -f "$ROOT/server.json" ]; then ok "the whole lane ran with no server"; else bad "the whole lane ran with no server" "server.json exists"; fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
