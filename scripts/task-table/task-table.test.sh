#!/usr/bin/env bash
# task-table.test.sh — the grouped /tasks view: grouping resolution (flag > project
# view file > auto), full-width ids, a loud empty store, and a loud height cap that
# names what it hid. Runs against a sandbox HOME so no real store or view file moves.
#
# 2026-09-05: the flat table this suite was written against was replaced by the
# ruled goal-box layout (assets/reports/20260904-tasks-visual-variants/final.md).
# Assertions that pinned the flat layout itself (GATES/BATCH/GOAL/LATER bands, the
# legend: prefix, lanes:, "no vertical borders") are retired here; the layout is
# covered by goal-box.test.sh, render-hygiene.test.sh and state-matrix.test.sh.
# What stays are the concepts this file always owned: grouping resolution, ids,
# the empty store, the height law, the --session contract.
set -uo pipefail
SRC=/Users/alcatraz627/.claude/scripts/task-table
pass=0; fail=0; ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
SB=$(mktemp -d); REAL="$HOME"; export HOME="$SB"
mkdir -p "$HOME/.claude/tasks" "$HOME/.claude/scripts/task-table" "$SB/proj"
cp "$SRC/task-table.sh" "$SRC/task.sh" "$SRC/resolve-store.sh" "$HOME/.claude/scripts/task-table/" 2>/dev/null
TT="$HOME/.claude/scripts/task-table/task-table.sh"; T="$HOME/.claude/scripts/task-table/task.sh"
export CLAUDE_CODE_SESSION_ID=eeeeeeee-0000-0000-0000-000000000004
cd "$SB/proj"
render(){ bash "$TT" --session eeeeeeee "$@" 2>&1; }

echo "== auto grouping =="
$T add "plain one" --new >/dev/null; $T add "plain two" --blocked-on "USER: rule" >/dev/null; $T add "plain three" >/dev/null
render | rg -q "grouped by actor, auto" && ok "no metadata: auto → actor" || ko "auto actor"
render | rg -q "^⚡ CLEAR NOW" && ok "a gated row reaches CLEAR NOW (Q1a)" || ko "gates band"
$T update 1 --domain hooks >/dev/null
render | rg -q "grouped by domain(, then batch)?, auto" && ok "domain present: auto → domain" || ko "auto domain"
render | rg -q "\(no domain\)" && ok "rows without the key land in a named (no domain) group" || ko "no-key group"
$T meta 2 batch=B >/dev/null; $T meta 3 batch=B >/dev/null; $T meta 1 batch=A >/dev/null
render | rg -q "grouped by batch, auto" && ok "batch present: auto → batch" || ko "auto batch"
out=$(render); [ "$(echo "$out" | rg -n "^[🔴🟠🔵🟢⚪] · [^A-Za-z]*B( |$)" | head -1 | cut -d: -f1)" -lt "$(echo "$out" | rg -n "^[🔴🟠🔵🟢⚪] · [^A-Za-z]*A( |$)" | head -1 | cut -d: -f1)" ] && ok "the box holding the gate renders first" || ko "batch order"
render | rg -q "▸ do +rule" && render | rg -q "USER: rule" && ok "the gate's prose is its CLEAR NOW do-line AND its blocked_on text stays on the row" || ko "do-line/blocked line"

echo "== explicit lane beats prose inference =="
$T add "answer the card that needs you, with a choice" --lane gcc --tier opus >/dev/null
render | rg -q "^   [0-9]  #4\b" && ko "a gcc-lane row whose prose says 'needs you' must not be a gate" || ok "a gcc-lane row whose prose says 'needs you' is not a gate (#48, 2026-08-23)"
$T add "owner's own item" --lane owner >/dev/null
render | rg -q "^   [0-9]  #5\b" && ok "an owner-lane row is a gate without any phrase, and reaches CLEAR NOW" || ko "owner lane → gate"
$T add "parked thing" --goal later >/dev/null
for i in 1 2 3; do $T update $i --tier sonnet >/dev/null; done   # the earlier rows, so only #5 and #6 lack a tier
render | rg -q "carry no tier" && ko "deferred rows must not count in the no-tier warning" || ok "deferred and owner rows are skipped by the no-tier warning"
$T update 4 --lane "" >/dev/null; $T done 5 6 >/dev/null

echo "== flag and project view file =="
render --group class | rg -q "grouped by class(, then batch)?, from the --group flag" && ok "--group overrides auto" || ko "flag"
bash "$TT" --set-group domain | rg -q "group=domain" && ok "--set-group writes the project view" || ko "set-group"
[ -f "$SB/proj/.claude/tasks-view.json" ] && ok "view file lives under the project's .claude/" || ko "view path: $(ls -a $SB/proj)"
render | rg -q "grouped by domain(, then batch)?, set in this project's view file" && ok "view file outranks auto" || ko "view precedence"
render --group batch | rg -q "grouped by batch, from the --group flag" && ok "flag outranks the view file" || ko "flag over file"
jq '.group="batch" | .order=["B","A"] | .labels={"B":"B · second batch first"}' "$SB/proj/.claude/tasks-view.json" > "$SB/v.json" && mv -f "$SB/v.json" "$SB/proj/.claude/tasks-view.json"
out=$(render); echo "$out" | rg -q "^[🔴🟠🔵🟢⚪] · .*B · second batch first" && ok "labels render" || ko "labels"
[ "$(echo "$out" | rg -n "second batch first" | head -1 | cut -d: -f1)" -lt "$(echo "$out" | rg -n "^[🔴🟠🔵🟢⚪] · [^A-Za-z]*A( |$)" | head -1 | cut -d: -f1)" ] && ok "order from the view file wins over natural order" || ko "order"
echo "not json" > "$SB/proj/.claude/tasks-view.json"; render | rg -q "view file did not parse" && ok "broken view file is reported, not fatal" || ko "broken view"
trash "$SB/proj/.claude/tasks-view.json" 2>/dev/null || true

echo "== ids, empty store, height cap =="
for i in $(seq 3 121); do printf '{"id":"%s","subject":"row %s","description":"","status":"%s","blocks":[],"blockedBy":[],"metadata":{"batch":"%s"}}' $i $i "$([ $((i%2)) = 0 ] && echo pending || echo completed)" "$([ $((i%2)) = 0 ] && echo A || echo B)" > "$HOME/.claude/tasks/session-eeeeeeee/$i.json"; done
out=$(render); echo "$out" | rg -q "rows held by the height cap" && ok "height cap truncates loudly and names hidden ids" || { echo "$out" | tail -8; ko "loud cap"; }
render --json > "$SB/ids.json"; jq -e '[.tasks[].id|tostring] | index("118") != null' "$SB/ids.json" >/dev/null && ok "three-digit ids survive (#118 is a whole id, never #11)" || ko "hidden id names"
render --detail | wc -l | awk '{exit !($1>44)}' && ok "--detail exceeds the cap (every line printed)" || ko "detail"
for i in $(seq 3 121); do trash "$HOME/.claude/tasks/session-eeeeeeee/$i.json" 2>/dev/null; done
printf '{"id":"121","subject":"row 121","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"batch":"A"}}' > "$HOME/.claude/tasks/session-eeeeeeee/121.json"
render | rg -q "#121 " && ok "three-digit id renders in full" || ko "id width"
n=$(echo "$out" | wc -l | tr -d ' '); [ "$n" -le 44 ] && ok "stays within 44 lines ($n)" || ko "height $n"
mkdir -p "$HOME/.claude/tasks/session-ffffffff"; bash "$TT" --session ffffffff 2>&1 | rg -q "!! EMPTY STORE" && ok "empty store is loud" || ko "empty store"
render --json > "$SB/j.json"; jq -e '.group=="batch" and (.groups|has("A")) and (.groups.A|length)>0' "$SB/j.json" >/dev/null && ok "--json carries groups" || { head -c 300 "$SB/j.json"; ko "json groups"; }
echo "== the ruled shape: goal › batch as boxes and bands, one trait per column, sequence =="
$T add "goal row one" --goal G1 --batch b1 --lane hands --tier opus --session eeeeeeee >/dev/null
$T add "goal row two, after one" --goal G1 --batch b1 --lane hands --tier opus --blocked-by 122 --session eeeeeeee >/dev/null
$T add "deferred thing" --goal G1 --batch "after V1" --lane builder --tier fable --session eeeeeeee >/dev/null
# Auto-grouping picks the first key that MOST open rows carry (a 70% bar, added
# 2026-09-04 after 98 of 180 owner rows landed in one nameless band). Three goal
# rows of five open is 60%, so batch at 100% would win and the assertion below
# would be testing the fixture, not the rule. File the other two open rows.
for r in 1 2 4 121; do $T --session eeeeeeee meta "$r" goal=G2 batch=b2 >/dev/null 2>&1; done
out=$(render); echo "$out" | rg -q "grouped by goal, then batch" && ok "goal present on most rows: goal › batch" || ko "goal>batch: $(echo "$out" | sed -n 2p)"
echo "$out" | rg -q "^[🔴🟠🔵🟢⚪] · .*G1" && echo "$out" | rg -q "▸ b1" && ok "goal box with a milestone band" || ko "bands"
echo "$out" | rg -q "◆ hands" && echo "$out" | rg -q "◇ opus" && ok "lane and tier each in their own column" || ko "lane tag"
echo "$out" | rg -q "after #122" && ok "sequenced row says after #x" || ko "sequence note"
[ "$(echo "$out" | rg -n "#122 " | head -1 | cut -d: -f1)" -lt "$(echo "$out" | rg -n "#123 " | head -1 | cut -d: -f1)" ] && ok "blockedBy chain orders the batch" || ko "chain order"
echo "$out" | rg -q "│" && ok "goal boxes draw their rail" || ko "no rail: the box is not closed"
# The legend is now a KEY to what is on screen, not a static six-glyph banner, so
# it starts with whichever glyph the render actually used. Asserting the old
# "legend: ✅ done" prefix pinned the banner, which is the thing that printed all
# six glyphs under a table with zero rows.
legend_line=$(echo "$out" | rg "needs you|ready|running|in review|deferred|unassigned" | tail -1 || true)
[ -n "$legend_line" ] && ok "legend present" || ko "legend missing"
case "$legend_line" in *"ready"*) ok "legend names the state this fixture uses" ;;
                               *) ko "legend omits ready though open rows render: $legend_line" ;; esac
case "$legend_line" in *"running"*) ko "legend advertises running with no running row" ;;
                                 *) ok "legend omits states no row uses" ;; esac
# retired: the lanes legend. Lane is one trait column now and the ◆ marker names it.
# The tier nag is a tidiness note and lives behind --detail since #58 (visual audit V14)
render --detail | rg -q "carry no tier" && ok "unset tier is named under --detail" || ko "tier note missing from --detail"
echo "$out" | rg -q "carry no tier" && ko "the tier nag must not spend a header line on the plain render" || ok "and stays off the plain header"


echo "== #103: many bands — the shape that actually overshot =="
# The height assertion above passed at 33/33 while the live store rendered 47/44,
# because its fixture had two batches. A band header costs two lines and used to
# be written before the cap was consulted, so the overshoot scales with the BAND
# COUNT, not the row count. Ten bands is the real distribution; two could never
# fire it. (rules/testing.md [real-input-distribution].)
for g in 1 2 3 4 5 6 7 8 9 10; do
  for r in 1 2 3; do
    id=$((200 + g*10 + r))
    printf '{"id":"%s","subject":"band %s row %s","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"g%s","batch":"b%s"}}' \
      "$id" "$g" "$r" "$g" "$g" > "$HOME/.claude/tasks/session-eeeeeeee/$id.json"
  done
done
out=$(render)
n=$(echo "$out" | wc -l | tr -d ' ')
[ "$n" -le 44 ] && ok "ten bands stays within 44 lines ($n)" || ko "ten bands overshot: $n lines"
echo "$out" | rg -q "height ([0-9]+)/44" && \
  [ "$(echo "$out" | rg -o --replace '$1' 'height ([0-9]+)/44')" -le 44 ] && \
  ok "the footer's own height figure is within the law" || ko "footer height figure over 44"

# No band may render as a header with nothing under it. A row line starts with
# whitespace then a state glyph; a band title starts at column 0 or with two
# spaces then an uppercase key. Walk the output and assert every title is
# followed by at least one row before the next title or rule.
echo "$out" | python3 -c '
import sys, re
lines=[l.rstrip() for l in sys.stdin]
RULE=re.compile(r"^\u2500{10,}")
TITLE=re.compile(r"^(GATES |LATER |[A-Z][A-Z/ ]+ )|^  [A-Z][A-Z]+ ")
ROW=re.compile(r"^\s+(\u25cb|\u25b6|\u26d3|\U0001f534|\u23f3|\u2705)")
# A band spans from its title to the next horizontal rule. In goal-then-batch
# mode a GOAL title is legitimately followed by a BATCH sub-title before any
# row, so the span, not the very next line, is what must contain a row.
bad=[]
for i,l in enumerate(lines):
    if l.startswith("TASKS ") or not TITLE.match(l): continue
    j=i+1; seen=False
    while j < len(lines) and not RULE.match(lines[j]):
        if ROW.match(lines[j]): seen=True; break
        j+=1
    if not seen: bad.append(l.strip()[:60])
print("EMPTYBANDS:" + ("|".join(bad) if bad else "none"))
' > "$SB/bands.txt"
rg -q "EMPTYBANDS:none" "$SB/bands.txt" && ok "no band renders as a header with zero rows" \
  || ko "empty band(s): $(cat "$SB/bands.txt")"

echo "$out" | rg -q "rows held by the height cap" && ok "the dropped bands' ids are still named" || ko "dropped bands went unnamed"
echo "$out" | rg -q "⚡ CLEAR NOW" && ok "CLEAR NOW survives the cap" || ko "gates eaten by the cap"
render --detail | rg -q "band 10 row 3" && ok "--detail still prints every dropped row" || ko "detail lost rows"
for g in 1 2 3 4 5 6 7 8 9 10; do for r in 1 2 3; do trash "$HOME/.claude/tasks/session-eeeeeeee/$((200 + g*10 + r)).json" 2>/dev/null; done; done

echo "== #104: --session must win or lose loudly, never fall through =="
bash "$TT" --pin eeeeeeee >/dev/null 2>&1
out=$(bash "$TT" --session deadbeef 2>&1); rc=$?
[ "$rc" != 0 ] && ok "an unknown --session exits non-zero ($rc)" || ko "unknown --session exited 0"
echo "$out" | rg -q "names no store" && ok "it says the sid named no store" || ko "no explanation given"
echo "$out" | rg -q "^TASKS " && ko "it rendered a table anyway (fell through to the pin)" \
                             || ok "no table is rendered for an unknown sid"
echo "$out" | rg -q "Candidates, newest first" && ok "candidates are offered so the caller can act" || ko "refused without evidence"

# Deriving beats refusing: a full uuid still identifies the sid8 store. Pin a
# DIFFERENT store first, or this row passes under the bug too: falling through to
# a pin that happens to point at the right store proves nothing. ffffffff is the
# empty store created above, so a fallthrough is unmistakable in the output.
bash "$TT" --pin ffffffff >/dev/null 2>&1
out=$(bash "$TT" --session eeeeeeee-0000-0000-0000-000000000004 2>&1)
echo "$out" | rg -q "EMPTY STORE" && ko "full uuid fell through to the pinned (wrong) store" \
                                 || ok "a full uuid resolves to its own sid8 store, not the pin"
echo "$out" | rg -q "^TASKS " && ok "the full-uuid render is a real table" || ko "full uuid refused"
echo "$out" | rg -q "found by the --session you passed \(prefix match\)" \
  && ok "the prefix match names itself in the header" || ko "prefix resolution not labelled"

# An exact sid is still the fast path and still labelled plain "explicit".
bash "$TT" --pin eeeeeeee >/dev/null 2>&1
bash "$TT" --session eeeeeeee 2>&1 | rg -q "found by the --session you passed  ·" \
  && ok "an exact sid still resolves as explicit" || ko "exact sid regressed"

echo "== #103 round 2: a compact row is TWO lines when it carries note/blocked_on =="
# The first fix guarded band HEADERS and left this: room() asked for one line and
# row() emitted two, so the last admitted row landed past the cap and the table
# rendered 45/44 (adversarial review 2026-08-20). Pinned with a note set, because
# a fixture without one cannot reach the second line and cannot fail either way.
for i in $(seq 300 420); do
  printf '{"id":"%s","subject":"row %s subject text here","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"batch":"A","note":"a note long enough to force the continuation line","lane":"gcc","tier":"opus"}}' \
    "$i" "$i" > "$HOME/.claude/tasks/session-eeeeeeee/$i.json"
done
n=$(render | wc -l | tr -d ' ')
[ "$n" -le 44 ] && ok "rows carrying a note stay within 44 ($n)" || ko "note continuation overshot: $n"
render | rg -q "rows held by the height cap" && ok "the rows it dropped are still named" || ko "silent drop"
for i in $(seq 300 420); do trash "$HOME/.claude/tasks/session-eeeeeeee/$i.json" 2>/dev/null; done

echo "== #103 round 2: the SUBGROUP band guard, pinned on its own =="
# Removing the subgroup fits(2) alone used to leave the suite green, because the
# band-level fits(3) covered for it. Two fixes, one case, neither pinned: the
# exact trap in rules/testing.md [mutation-test-the-guard]. This fixture forces
# the goal-then-batch path so the subgroup guard is the one under test.
# ONE goal holding MANY batches. With several goals the goal-level fits(4) bails
# first and the subgroup guard never runs, which is why the previous shape of this
# fixture left the mutation green: the fixture could not reach the branch.
for g in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18; do
  for r in 1 2; do
    id=$((500 + g*10 + r))
    printf '{"id":"%s","subject":"sub band %s row %s","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"ONEGOAL","batch":"sb%s"}}' \
      "$id" "$g" "$r" "$g" > "$HOME/.claude/tasks/session-eeeeeeee/$id.json"
  done
done
out=$(render --group goal)
n=$(echo "$out" | wc -l | tr -d ' ')
[ "$n" -le 44 ] && ok "one goal with 18 subgroups stays within 44 ($n)" || ko "subgroup path overshot: $n"
echo "$out" | python3 -c '
import sys, re
lines=[l.rstrip() for l in sys.stdin]
RULE=re.compile(r"^\u2500{10,}")
SUB=re.compile(r"^  [A-Z][A-Z]+ ")
ROW=re.compile(r"^\s+(\u25cb|\u25b6|\u26d3|\U0001f534|\u23f3|\u2705)")
bad=[l.strip()[:40] for i,l in enumerate(lines) if SUB.match(l)
     and not any(ROW.match(x) for x in lines[i+1:i+2])]
print("EMPTYSUB:" + ("|".join(bad) if bad else "none"))' > "$SB/sub.txt"
rg -q "EMPTYSUB:none" "$SB/sub.txt" && ok "no SUBGROUP header renders with zero rows" \
  || ko "empty subgroup header(s): $(cat "$SB/sub.txt")"
for g in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18; do for r in 1 2; do trash "$HOME/.claude/tasks/session-eeeeeeee/$((500 + g*10 + r)).json" 2>/dev/null; done; done

echo "== #59: every clip that reaches the screen cuts at a word and says so =="
# Three hard [:N] slices ended text mid-word with no mark: the empty store's
# candidate quotes, the reference gloss on a note, and the compact digest's
# running row. Each now cuts at a word boundary and appends the ellipsis.
LONGS="a subject long enough that the candidate list, the gloss and the compact digest all have to cut it somewhere"
lid=$($T add "$LONGS" --note "kept whole so the render, not add, does the cut" | sed -E 's/^added #([0-9]+).*/\1/')
$T add "follow-up to #$lid" >/dev/null
touch "$HOME/.claude/tasks/session-eeeeeeee/$lid.json"     # newest, so the empty store lists it
$T start "$lid" >/dev/null
render --compact | rg -q "now: #$lid a subject long enough that[^…]*…" && ok "the compact digest cuts at a word and marks it" || ko "compact digest clip: $(render --compact | sed -n 2p)"
# --detail, because by this point the store is crowded and the capped render may hold the row
render --detail | rg -q "#$lid a subject long enough that[^…]*…" && ok "the reference gloss cuts at a word and marks it" || ko "gloss clip: $(render --detail | rg -m2 "follow-up|#$lid a subject" | tr '\n' '|')"
# --refs prints the glossary raw; its [:88] slice cut this task's own subject to "the mid-e"
# (second seat on #59). The glossary entry for the long subject must cut at a word and mark it.
render --refs | rg -q "#$lid .*a subject long enough that[^…]*…" && ok "the --refs glossary cuts at a word and marks it" || ko "refs glossary clip: $(render --refs | rg -m1 "#$lid" )"
$T done "$lid" >/dev/null

echo "== #54 and the csync ask (2026-09-08): a resumed session's bare run finds the project's one store, or refuses honestly =="
# forge-console, 2026-09-05: the header said "resolved by content-match" two lines
# above EMPTY STORE. Since 2026-09-08 an empty own-store is never rendered while a
# populated store stamped with this project exists. Exactly ONE such store is the
# project's queue and resolves (csync: three candidates were offered by recency
# while every open row carried the project's own domain); two or more refuse and
# name them, so the reader pins one and a new session is told how to add a row.
mkdir -p "$HOME/.claude/tasks/session-dddddddd"
out=$(CLAUDE_CODE_SESSION_ID=dddddddd-0000-0000-0000-000000000004 bash "$TT" 2>&1); rc=$?
[ "$rc" -eq 0 ] && ok "one stamped store: the resumed session's bare run resolves (rc 0)" || ko "one stamped store refused (rc $rc): $(echo "$out" | sed -n 1p)"
echo "$out" | rg -q "TASKS  session-eeeeeeee" && ok "it renders the project's store, not the empty own one" || ko "wrong store: $(echo "$out" | sed -n 1p)"
echo "$out" | rg -q "found by project-stamp" && ok "the header says how it decided (project-stamp)" || ko "provenance: $(echo "$out" | sed -n 2p)"
echo "$out" | rg -q "EMPTY STORE" && ko "an empty table was rendered" || ok "no empty table"
# a second stamped, populated store: now the resolver must refuse and name both
mkdir -p "$HOME/.claude/tasks/session-ffff0000"
printf '%s' "$(git -C "$SB/proj" rev-parse --show-toplevel 2>/dev/null || echo "$SB/proj")" > "$HOME/.claude/tasks/session-ffff0000/.project"
printf '{"id":"1","subject":"the other project store","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{}}' > "$HOME/.claude/tasks/session-ffff0000/1.json"
trash "$HOME/.claude/tasks-pins/dddddddd" "$HOME/.claude/tasks-pins/dddddddd.by" 2>/dev/null || true
out=$(CLAUDE_CODE_SESSION_ID=dddddddd-0000-0000-0000-000000000004 bash "$TT" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ok "two stamped stores: the empty own-store is refused (rc $rc)" || ko "two stamped stores rendered a table (rc 0)"
echo "$out" | rg -q "TASKS  session-dddddddd" && ko "an empty table was rendered" || ok "no table for the empty own-store"
echo "$out" | rg -q "own store is empty" && ok "the refusal says the own store is empty" || ko "empty-store provenance: $(echo "$out" | sed -n 2p)"
echo "$out" | rg -q "stamped with this project" && echo "$out" | rg -q "session-eeeeeeee" && echo "$out" | rg -q "session-ffff0000" && ok "the refusal names both stamped candidates" || ko "stamped candidates not both named in a refusal"
echo "$out" | rg -q "matching your transcript" \
  && ko "an empty store must never be called a transcript match" || ok "no transcript-match claim on an empty store"
echo "$out" | rg -q "task.sh --new add" && ok "a new session is told how to add its first row" || ko "no path out for a new session"
echo "$out" | rg -q "Likely yours" \
  && ko "the candidate list must not claim a likelihood it cannot measure" || ok "the candidate list is labelled by recency, not likelihood"
# #59: the candidate subject is cut at a word and marked
echo "$out" | rg -q "a subject long enough that[^…]*…" && ok "a long candidate subject is cut at a word and marked" || ko "candidate quote clip: $(echo "$out" | rg -m1 'a subject long enough')"
trash "$HOME/.claude/tasks/session-ffff0000" 2>/dev/null || true

echo "== P11c: the origin glyph rides the subject, never a fifth trait column =="
$T add "measured origin row" --goal G2 --batch b2 --origin measured --session eeeeeeee >/dev/null
out=$(render --detail)
echo "$out" | rg -q "📏 measured origin row" && ok "a measured row carries 📏 before its subject" || ko "origin glyph on row: $(echo "$out" | rg -m1 'measured origin row')"
echo "$out" | rg -q "▫ domain   📏 measured" && ok "the origin key rides the trait legend, no fifth column" || ko "origin legend: $(echo "$out" | rg -m1 '◆ lane')"
out=$(render --detail --json); echo "$out" | jq -e '[.tasks[] | select(.subject=="measured origin row")] | length == 1' >/dev/null && ok "the stored subject stays clean; the glyph is render-only" || ko "glyph leaked into the store"

echo "== cold read P2 (2026-09-08): the four screen defects a stranger flagged in a minute =="
# (a) a gate that names no ask ranks after one that does, and its do-line says the ask is owed
# the no-ask gate gets the LOWER id, so natural order would put it first
$T add "gate with no ask" --goal G2 --batch b2 --lane owner --session eeeeeeee >/dev/null
$T add "gate with an ask" --goal G2 --batch b2 --blocked-on "USER: rule on the colour" --session eeeeeeee >/dev/null
out=$(render)
_ask=$(echo "$out" | rg -n "gate with an ask" | sed -n 1p | cut -d: -f1); _no=$(echo "$out" | rg -n "gate with no ask" | sed -n 1p | cut -d: -f1)
[ -n "$_ask" ] && [ -n "$_no" ] && [ "$_ask" -lt "$_no" ] && ok "a gate with an ask ranks above a gate with none in CLEAR NOW" || ko "CLEAR NOW order: ask at line ${_ask:-none}, no-ask at line ${_no:-none}"
echo "$out" | rg -q "names no ask" && ok "the no-ask do-line says the ask is owed, not a maintenance command" || ko "no-ask do-line: $(echo "$out" | rg -m1 'no instruction|names no ask')"
# (c) a box with no milestone prints no meter that reads 0 of 0
# Written as JSON: task.sh refuses a goal row with no milestone (D6a), and until
# 2026-09-08 this line's refusal was swallowed, so the assertion below was being
# satisfied by the deferred box's hint rather than by this row (a blind fixture).
printf '{"id":"126","subject":"lonely goal row","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"G3","lane":"hands","tier":"opus"}}' > "$HOME/.claude/tasks/session-eeeeeeee/126.json"
out=$(render --detail)
echo "$out" | rg -q "0 of 0 milestones" && ko "a box with no milestone printed 0 of 0" || ok "a box with no milestone prints no 0 of 0 meter"
echo "$out" | rg -q "no milestone named yet" && ok "and it says what is missing instead" || ko "the no-milestone line is absent (a prohibition alone is blind to omission)"
# (d) running rows held by the cap are named as running in the held line
for i in $(seq 300 360); do printf '{"id":"%s","subject":"filler %s","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"G2","batch":"b2"}}' $i $i > "$HOME/.claude/tasks/session-eeeeeeee/$i.json"; done
printf '{"id":"361","subject":"running but held","description":"","status":"in_progress","blocks":[],"blockedBy":[],"metadata":{"goal":"G2","batch":"zz"}}' > "$HOME/.claude/tasks/session-eeeeeeee/361.json"
touch -t 202601010000 "$HOME/.claude/tasks/session-eeeeeeee/361.json"   # oldest band, so the cap holds it
out=$(render)
echo "$out" | rg -q "running but held" && ko "the fixture no longer holds the running row off screen; the guard is unexercised" || ok "the aged running row is held off screen"
echo "$out" | rg -q "running, off screen: #361" && ok "a running row held by the cap is named as running in the key" || ko "held running row unnamed: $(echo "$out" | rg -m1 'held by the height cap')"

echo "== a running row in a lane no live session claims is named (ledger 15, 26, 33) =="
printf '{"peers":[{"alias":"forge-console","status":"live"},{"alias":"vb-fable","status":"idle"},{"alias":"old-watcher","status":"offline"}]}' > "$SB/peers.json"
$T add "watcher row still running" --goal G2 --batch b2 --lane watcher --status in_progress --session eeeeeeee >/dev/null
$T add "console row running" --goal G2 --batch b2 --lane console --status in_progress --session eeeeeeee >/dev/null
out=$(TASKS_PEERS_JSON="$SB/peers.json" render --detail)
echo "$out" | rg -q "running in a lane no live session claims: watcher" && ok "the retired lane's running row is named" || ko "orphan lane unnamed: $(echo "$out" | rg -m1 'no live session')"
echo "$out" | rg -q "claims: .*console" && ko "a lane a live alias contains was called orphaned" || ok "a lane a live alias contains (forge-console) is not flagged"
out=$(TASKS_PEERS_JSON="$SB/missing.json" render --detail)
echo "$out" | rg -q "no live session claims" && ko "nagged with no roster to read" || ok "no roster, no nag"

echo "== the backlog's growth is on the first screen (owner, 2026-09-08) =="
out=$(render)
echo "$out" | rg -q "today: [0-9]+ filed, [0-9]+ closed" && ok "the footer counts rows filed today beside rows closed today" || ko "no filed/closed count: $(echo "$out" | tail -3)"

cd /; export HOME="$REAL"; trash "$SB" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
