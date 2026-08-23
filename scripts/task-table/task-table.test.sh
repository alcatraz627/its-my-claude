#!/usr/bin/env bash
# task-table.test.sh — the grouped /tasks view: grouping resolution (flag > project
# view file > auto), full-width ids, a loud empty store, and a loud height cap that
# names what it hid. Runs against a sandbox HOME so no real store or view file moves.
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
render | rg -q "grouped: actor \(auto" && ok "no metadata: auto → actor" || ko "auto actor"
render | rg -q "GATES \(you\)" && ok "gated rows land in the GATES band" || ko "gates band"
$T update 1 --domain hooks >/dev/null
render | rg -q "grouped: domain( › batch)? \(auto" && ok "domain present: auto → domain" || ko "auto domain"
render | rg -q "\(no domain\)" && ok "rows without the key land in a named (no domain) group" || ko "no-key group"
$T meta 2 batch=B >/dev/null; $T meta 3 batch=B >/dev/null; $T meta 1 batch=A >/dev/null
render | rg -q "grouped: batch \(auto" && ok "batch present: auto → batch" || ko "auto batch"
out=$(render); [ "$(echo "$out" | rg -n "^BATCH A" | cut -d: -f1)" -lt "$(echo "$out" | rg -n "^GATES|^BATCH B" | tail -1 | cut -d: -f1)" ] && ok "batches in natural order (gates first)" || ko "batch order"
render | rg -q "needs you: #2" && render | rg -q "blocked: USER: rule" && ok "gate shows in the summary line AND its blocked_on text on the row" || ko "summary/blocked line"

echo "== explicit lane beats prose inference =="
$T add "answer the card that needs you, with a choice" --lane gcc --tier opus >/dev/null
render | rg -q "needs you:.*#4\b" && ko "a gcc-lane row whose prose says 'needs you' must not be a gate" || ok "a gcc-lane row whose prose says 'needs you' is not a gate (#48, 2026-08-23)"
$T add "owner's own item" --lane owner >/dev/null
render | rg -q "needs you:.*#5" && ok "an owner-lane row is a gate without any phrase" || ko "owner lane → gate"
$T add "parked thing" --goal later >/dev/null
for i in 1 2 3; do $T update $i --tier sonnet >/dev/null; done   # the earlier rows, so only #5 and #6 lack a tier
render | rg -q "carry no tier" && ko "deferred rows must not count in the no-tier warning" || ok "deferred and owner rows are skipped by the no-tier warning"
$T update 4 --lane "" >/dev/null; $T done 5 6 >/dev/null

echo "== flag and project view file =="
render --group class | rg -q "grouped: class( › batch)? \(flag\)" && ok "--group overrides auto" || ko "flag"
bash "$TT" --set-group domain | rg -q "group=domain" && ok "--set-group writes the project view" || ko "set-group"
[ -f "$SB/proj/.claude/tasks-view.json" ] && ok "view file lives under the project's .claude/" || ko "view path: $(ls -a $SB/proj)"
render | rg -q "grouped: domain( › batch)? \(project view file\)" && ok "view file outranks auto" || ko "view precedence"
render --group batch | rg -q "grouped: batch \(flag\)" && ok "flag outranks the view file" || ko "flag over file"
jq '.group="batch" | .order=["B","A"] | .labels={"B":"B · second batch first"}' "$SB/proj/.claude/tasks-view.json" > "$SB/v.json" && mv -f "$SB/v.json" "$SB/proj/.claude/tasks-view.json"
out=$(render); echo "$out" | rg -q "^BATCH B · second batch first" && ok "labels render" || ko "labels"
[ "$(echo "$out" | rg -n "second batch first" | cut -d: -f1)" -lt "$(echo "$out" | rg -n "^BATCH A" | cut -d: -f1)" ] && ok "order from the view file wins over natural order" || ko "order"
echo "not json" > "$SB/proj/.claude/tasks-view.json"; render | rg -q "view file did not parse" && ok "broken view file is reported, not fatal" || ko "broken view"
trash "$SB/proj/.claude/tasks-view.json" 2>/dev/null || true

echo "== ids, empty store, height cap =="
for i in $(seq 3 121); do printf '{"id":"%s","subject":"row %s","description":"","status":"%s","blocks":[],"blockedBy":[],"metadata":{"batch":"%s"}}' $i $i "$([ $((i%2)) = 0 ] && echo pending || echo completed)" "$([ $((i%2)) = 0 ] && echo A || echo B)" > "$HOME/.claude/tasks/session-eeeeeeee/$i.json"; done
out=$(render); echo "$out" | rg -q "rows held by the height cap" && ok "height cap truncates loudly and names hidden ids" || { echo "$out" | tail -8; ko "loud cap"; }
echo "$out" | rg -q "#118\b" && ok "three-digit ids survive (#118 named somewhere, never #11)" || { echo "$out" | rg -n "held by|#11" | head -3; ko "hidden id names"; }
render --detail | wc -l | awk '{exit !($1>44)}' && ok "--detail exceeds the cap (every line printed)" || ko "detail"
for i in $(seq 3 121); do trash "$HOME/.claude/tasks/session-eeeeeeee/$i.json" 2>/dev/null; done
printf '{"id":"121","subject":"row 121","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"batch":"A"}}' > "$HOME/.claude/tasks/session-eeeeeeee/121.json"
render | rg -q "○ #121 " && ok "three-digit id renders in full" || ko "id width"
n=$(echo "$out" | wc -l | tr -d ' '); [ "$n" -le 44 ] && ok "stays within 44 lines ($n)" || ko "height $n"
mkdir -p "$HOME/.claude/tasks/session-ffffffff"; bash "$TT" --session ffffffff 2>&1 | rg -q "!! EMPTY STORE" && ok "empty store is loud" || ko "empty store"
render --json > "$SB/j.json"; jq -e '.group=="batch" and (.groups|has("A")) and (.groups.A|length)>0' "$SB/j.json" >/dev/null && ok "--json carries groups" || { head -c 300 "$SB/j.json"; ko "json groups"; }
echo "== the ratified shape: goal › batch, lane·tier, sequence, gates first, no box =="
$T add "goal row one" --goal G1 --batch b1 --lane hands --tier opus --session eeeeeeee >/dev/null
$T add "goal row two, after one" --goal G1 --batch b1 --lane hands --tier opus --blocked-by 122 --session eeeeeeee >/dev/null
$T add "deferred thing" --goal G1 --batch "after V1" --lane builder --tier fable --session eeeeeeee >/dev/null
out=$(render); echo "$out" | rg -q "grouped: goal › batch" && ok "goal present: goal › batch" || ko "goal>batch: $(echo "$out" | sed -n 2p)"
echo "$out" | rg -q "^GOAL G1" && echo "$out" | rg -q "^  BATCH b1" && ok "GOAL band with BATCH sub-band" || ko "bands"
echo "$out" | rg -q "hands·opus" && ok "lane·tier tag renders" || ko "lane tag"
echo "$out" | rg -q "⛓ #123 +\[after #122\]" && ok "sequenced row says after #x" || ko "sequence note"
[ "$(echo "$out" | rg -n "#122 " | head -1 | cut -d: -f1)" -lt "$(echo "$out" | rg -n "#123 " | head -1 | cut -d: -f1)" ] && ok "blockedBy chain orders the batch" || ko "chain order"
echo "$out" | rg -q "^LATER · deferred / after V1" && ok "deferred rows get their own band" || ko "later band"
[ "$(echo "$out" | rg -n "^GATES \(you\)" | cut -d: -f1)" -lt "$(echo "$out" | rg -n "^GOAL G1" | cut -d: -f1)" ] && ok "gates band renders before goals" || ko "gates first"
echo "$out" | rg -q "│" && ko "vertical box borders present" || ok "no vertical box borders anywhere"
# The legend is now a KEY to what is on screen, not a static six-glyph banner, so
# it starts with whichever glyph the render actually used. Asserting the old
# "legend: ✅ done" prefix pinned the banner, which is the thing that printed all
# six glyphs under a table with zero rows.
legend_line=$(echo "$out" | rg "^legend:" || true)
[ -n "$legend_line" ] && ok "legend present" || ko "legend missing"
case "$legend_line" in *"○ ready"*) ok "legend names the glyph this fixture uses" ;;
                                 *) ko "legend omits ○ though open rows render: $legend_line" ;; esac
case "$legend_line" in *"▶ running"*) ko "legend advertises ▶ with no running row" ;;
                                   *) ok "legend omits glyphs no row uses" ;; esac
echo "$out" | rg -q "lanes: builder · hands" && ok "lanes listed in the legend" || ko "lanes legend"
echo "$out" | rg -q "carry no tier \(rendered '\?'\)" && ok "unset tier is loud" || ko "tier loud"


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
echo "$out" | rg -q "^height ([0-9]+)/44" && \
  [ "$(echo "$out" | rg -o '^height ([0-9]+)/44' -r '$1')" -le 44 ] && \
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
echo "$out" | rg -q "^GATES \(you\)" && ok "GATES survives the cap and stays first" || ko "gates eaten by the cap"
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
echo "$out" | rg -q "resolved by explicit \(matched by prefix\)" \
  && ok "the prefix match names itself in the header" || ko "prefix resolution not labelled"

# An exact sid is still the fast path and still labelled plain "explicit".
bash "$TT" --pin eeeeeeee >/dev/null 2>&1
bash "$TT" --session eeeeeeee 2>&1 | rg -q "resolved by explicit\b" \
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

cd /; export HOME="$REAL"; trash "$SB" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
