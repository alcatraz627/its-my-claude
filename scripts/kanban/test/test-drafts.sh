#!/usr/bin/env bash
# Suite for the draft lane (drafts, pulls, templates). Runs against a throwaway
# KANBAN_ROOT so the owner's real store is never touched.
#
# Covers what the rung turns on: a draft becomes project material only when an
# agent pulls it, a template is reused rather than consumed, and both work with
# no server running.

set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
ROOT=$(mktemp -d "${TMPDIR:-/tmp}/kanban-drafts-XXXXXX")
export KANBAN_ROOT="$ROOT"
trap 'rm -rf "$ROOT"' EXIT

pass=0; fail=0
ok()  { printf '  PASS  %s\n' "$1"; pass=$((pass+1)); }
# This suite has flaked 67/1 twice (2026-08-23, 2026-08-24) and gone green on
# the next run both times, so the failing row was never captured and the caveat
# could not be chased. Every failure now also appends to a log that survives the
# re-run, which turns "it flaked again" into a row with a name.
FLAKE_LOG="${FLAKE_LOG:-/tmp/kanban-test-drafts-failures.log}"
bad() { printf '  FAIL  %s\n     %s\n' "$1" "${2:-}"; fail=$((fail+1));
        printf '%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$1" "${2:-}" >> "$FLAKE_LOG"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]"; fi; }
# -F, not -q alone: these patterns carry [brackets], which a basic regex reads as
# a character class. The bracketed form made one assertion fail loudly and its
# sibling pass vacuously, which is the worse half.
has()   { if printf '%s' "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1" "no [$3] in [$2]"; fi; }
hasnt() { if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1" "unwanted [$3] in [$2]"; else ok "$1"; fi; }
# A draft id is two characters, and a listing prints a randomly-slugged board on
# its header line, so a bare `grep -F d3` matched "proj-e34cd3" and this suite
# failed at random. The loud half was the 67/1 above; the quiet half is worse,
# because the same collision lets a `has` pass while its row is absent. These
# match the ID COLUMN — start of line, then the id, then whitespace — so the
# assertion asks about the row it names and nothing else.
idrow()    { printf '%s' "$1" | grep -qE "^[[:space:]]*$2([[:space:]]|$)"; }
hasrow()   { if idrow "$2" "$3"; then ok "$1"; else bad "$1" "no row for [$3] in [$2]"; fi; }
hasntrow() { if idrow "$2" "$3"; then bad "$1" "unwanted row for [$3] in [$2]"; else ok "$1"; fi; }

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
# Bump a draft the way the owner does from the board: `body` rewrites the text
# (which moves updatedAt), `trigger` is the "Offer to a session" button.
touch_draft() {  # touch_draft <id> <body|trigger> [text]
  python3 - "$ROOT" "$1" "$2" "${3:-}" <<'PY2'
import json, os, sys, datetime, time
root, did, what, text = sys.argv[1:5]
p = os.path.join(root, "drafts.json")
d = json.load(open(p))
time.sleep(0.01)  # ISO ms resolution: a same-instant edit is not a later one
now = datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")
for rec in d["drafts"]:
    if rec["id"] == did:
        if what == "body": rec["body"] = text; rec["updatedAt"] = now
        else: rec["triggered"] = now
        break
else: raise SystemExit(f"no draft {did}")
json.dump(d, open(p, "w"), indent=2)
PY2
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
hasrow   "pending lists an unassigned draft" "$out" "d1"
hasrow   "pending lists a same-board draft"  "$out" "d2"
hasntrow "pending hides a template"          "$out" "t1"
out=$(K drafts --templates)
hasrow   "template list shows the template"  "$out" "t1"
hasntrow "template list hides a draft"       "$out" "d1"

# Board scoping: run from inside the project so the CLI resolves its own board.
out=$(cd "$PROJ" && K drafts)
hasrow   "in-project sweep keeps its own board's draft" "$out" "d2"
hasrow   "in-project sweep keeps unassigned drafts"     "$out" "d1"
hasntrow "in-project sweep drops another board's draft" "$out" "d3"

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
hasrow "--all still shows the pulled one" "$out" "d1"

# ---- 5. reversal ----------------------------------------------------------
out=$(K pull d1 --undo)
has "undo confirms" "$out" "un-pulled d1"
out=$(K drafts --global)
hasrow "an un-pulled draft is pending again" "$out" "d1"
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

# ---- 8. a revision outlives its pull ------------------------------------
# A pull consumes the text that was there when it was taken. If the owner edits
# the draft afterwards, or offers it again, what is waiting is no longer what the
# agent read — so the pull is spent and the draft comes back. Keyed on the id
# alone this never happened: a draft consumed once was invisible to every session
# forever, while the board went on rendering it as offered.
seed d9 "first version"
K pull d9 --note "read the first version" >/dev/null
out=$(K drafts --global)
hasnt "a freshly pulled draft is not pending" "$out" "d9  [pending]"

touch_draft d9 body "second version, written after the pull"
out=$(K drafts --global)
has "an edit after the pull brings the draft back" "$out" "d9  [pending]"
out=$(K drafts d9)
has "the returned draft carries the new text"  "$out" "second version"
has "the returned draft offers the pull again" "$out" "kanban.sh pull d9"

K pull d9 --note "read the second version" >/dev/null
out=$(K drafts --global)
hasnt "pulling the revision consumes it again" "$out" "d9  [pending]"

touch_draft d9 trigger
out=$(K drafts --global)
hasrow "offering a consumed draft brings it back"     "$out" "d9"
has "an offered draft is marked for pickup now"    "$out" "d9  [now]"

# The marker and the sweep must answer the same question. They read the same
# store from two call sites, so they can disagree, and a draft that is listed as
# waiting while being marked consumed is unactionable in both directions.
out=$(K drafts --all --global)
hasnt "the marker agrees with the sweep" "$out" "d9  [pulled]"

# ---- 9. a broken store must name itself broken --------------------------
cp "$ROOT/drafts.json" "$ROOT/drafts.ok.json"
printf '{ this is not json' > "$ROOT/drafts.json"
out=$(K drafts --global); rc=$?
has  "a broken store says what is wrong" "$out" "could not be read"
if [ "$rc" -ne 0 ]; then ok "a broken store exits non-zero"; else bad "a broken store exits non-zero" "got 0"; fi
hasnt "a broken store never reads as an empty desk" "$out" "no drafts pending"
cp "$ROOT/drafts.ok.json" "$ROOT/drafts.json"

# ---- 10. no server was ever running ------------------------------------
if [ ! -f "$ROOT/server.json" ]; then ok "the whole lane ran with no server"; else bad "the whole lane ran with no server" "server.json exists"; fi

# ---- 11. the session line and the CLI answer the same question ----------
# "Pending" is defined twice: once in lib.ts, once mirrored in jq inside
# session-start-line.sh, because that line must run with no bun and no server.
# Two definitions drift, and the drift is invisible when each side is only ever
# tested on its own. So both are asked about ONE fixture here, in the three
# states that separate them.
REALPROJ=$(cd "$PROJ" && pwd -P)
sline() { printf '{"cwd":"%s"}' "$REALPROJ" | KANBAN_ROOT="$ROOT" bash "$HERE/session-start-line.sh" 2>/dev/null; }
# Count, never presence: the fixture holds other legitimately-waiting drafts, so
# "does the phrase appear" cannot isolate one draft. An earlier version of this
# test asserted presence and failed on its own noise.
sline_n() { sline | sed -n 's/.*the owner has drafts (\([0-9]*\) waiting.*/\1/p' | head -1; }
sline_n0() { local n; n=$(sline_n); printf '%s' "${n:-0}"; }
cli_pending() { K drafts --global | grep -cF "$1  [" || true; }

base=$(sline_n0)
seed d11 "a document the owner sat down and wrote" "Routing plan"
touch_draft d11 trigger
check "the session line counts the new draft"  "$(sline_n0)" "$((base+1))"
has   "the session line says it was offered"   "$(sline)" "OFFERED TO A SESSION"
check "the CLI agrees it is pending"           "$(cli_pending d11)" "1"

K pull d11 --note "read it" >/dev/null
check "a consumed draft leaves the session line" "$(sline_n0)" "$base"
check "the CLI agrees it is consumed"            "$(cli_pending d11)" "0"

touch_draft d11 body "the owner revised it after the pull"
check "a revision returns to the session line"   "$(sline_n0)" "$((base+1))"
check "the CLI agrees the revision is pending"   "$(cli_pending d11)" "1"

# An unreadable store must say so on both sides rather than read as an empty desk.
cp "$ROOT/drafts.json" "$ROOT/drafts.ok2.json"
printf '{ broken' > "$ROOT/drafts.json"
line=$(sline)
has "the session line warns on an unreadable drafts store" "$line" "could not be read"
cp "$ROOT/drafts.ok2.json" "$ROOT/drafts.json"

# ---- 12. a revision comes back as a change, not as 44 lines again -------
# The pull snapshots the body, so when the owner edits afterwards the agent is
# handed what MOVED. Without it a returning draft is indistinguishable from a
# new one and the reader has to diff it by eye.
seed d12 $'line one\nline two\nline three' "Routing"
K pull d12 --note "read v1" >/dev/null
touch_draft d12 body $'line one\nline two CHANGED\nline three\nline four'
out=$(K drafts d12)
has   "a revised draft says it was revised"        "$out" "REVISED since you pulled it"
has   "the diff shows what was removed"            "$out" "- line two"
has   "the diff shows what replaced it"            "$out" "+ line two CHANGED"
has   "the diff shows what was added"              "$out" "+ line four"
hasnt "an unchanged line is not reported as moved" "$out" "- line one"
has   "the full text still follows the diff"       "$out" "the draft in full"

# Offered again with no edit is a different event and must not read as a change.
K pull d12 --note "read v2" >/dev/null
touch_draft d12 trigger
out=$(K drafts d12)
has "an unchanged re-offer says so instead of showing a diff" "$out" "text is unchanged"

# A pull taken before snapshots existed must say it cannot diff, not show a wrong one.
seed d13 "old body"
K pull d13 --note "legacy" >/dev/null
python3 - "$ROOT" <<'PY2'
import json, os, sys
p = os.path.join(sys.argv[1], "pulls.json")
d = json.load(open(p))
d["pulls"]["d13"].pop("text", None)     # a pull record from before this feature
json.dump(d, open(p, "w"), indent=2)
PY2
touch_draft d13 body "new body"
out=$(K drafts d13)
has "a pull with no snapshot says why it cannot diff" "$out" "No diff"

# ---- 13. a draft can name who it is for ---------------------------------
# D2: an unaddressed draft behaves exactly as before, which matters because every
# draft written until today is unaddressed.
# D7: an agent-addressed draft is invisible to every other agent. This is the one
# whose failure is silent and whose cost is the owner's private text reaching the
# wrong reader, so it is asserted from BOTH sides rather than once.
seed d20 "for anyone"
out=$(KANBAN_ALIAS=someone K drafts --global)
has "an unaddressed draft still reaches anyone" "$out" "d20"

seed d21 "for one agent only"
K to d21 agent:gcp-fable >/dev/null
out=$(KANBAN_ALIAS=gcp-fable K drafts --global)
has   "the addressed agent sees it"        "$out" "d21"
has   "the row says who it is for"         "$out" "agent:gcp-fable"
out=$(KANBAN_ALIAS=someone-else K drafts --global)
hasnt "another agent does not see it"      "$out" "d21"
has   "and still sees the unaddressed one" "$out" "d20"
out=$(K drafts --global)
hasnt "an agent that cannot name itself does not see it either" "$out" "d21"

# A board recipient is the other half of the same field.
out=$(K to d21 "board:$SLUG")
has "retargeting to a board confirms" "$out" "board:"
out=$(KANBAN_ALIAS=gcp-fable K drafts --project "$OTHER")
hasnt "the previously addressed agent no longer sees it elsewhere" "$out" "d21"
out=$(K drafts --project "$PROJ")
has "the addressed board sees it with no alias at all" "$out" "d21"

out=$(K to d21 --clear)
has "clearing returns it to anyone" "$out" "for anyone"
out=$(KANBAN_ALIAS=someone-else K drafts --global)
has "and anyone means anyone" "$out" "d21"

# Refusals, so a draft is never addressed to a place that does not exist.
out=$(K to d21 "board:nosuch" 2>&1)
has "an unknown board is refused"   "$out" "no board nosuch"
out=$(K to d21 "gcp-fable" 2>&1)
has "an unprefixed recipient is refused" "$out" "not a recipient"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
