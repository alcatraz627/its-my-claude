#!/usr/bin/env bash
# goal-box.test.sh — the ruled goal-box layout, and the guards that hold it up.
#
# The design is assets/reports/20260904-tasks-visual-variants/final.md, revision
# 2, owner-approved after four rounds. This suite pins the claims that document
# makes, not the pixels: the box is closed, the ball rides the rail and reports
# whether the goal can continue WITHOUT him, the emoji identifies the goal and
# does not move when the ball does, every row gets two lines, CLEAR NOW carries
# three blockers and counts the rest, and the whole thing stays inside 44 lines.
#
# EVERY GUARD HERE CARRIES ITS OWN MUTATION. A green suite says nothing about a
# guard; only watching it go red does. Each case plants the defect in a COPY of
# the renderer, asserts that copy fails the same check, and leaves the real file
# untouched (rules/testing-patterns.md, [mutation-test-the-guard]).
#
# Run: bash ~/.claude/scripts/task-table/goal-box.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TT="$HERE/task-table.sh"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/goalbox-XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
STORE="$ROOT/.claude/tasks/session-box00001"
mkdir -p "$STORE"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }
has(){ if rg -q -- "$2" "$3" 2>/dev/null; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — no match for [$2]"; fi; }
hasnt(){ if rg -q -- "$2" "$3" 2>/dev/null; then fail=$((fail+1)); echo "  FAIL: $1 — unexpected match for [$2]"; else pass=$((pass+1)); fi; }

# mutate <name> <find> <replace> — a copy of the renderer with one defect planted.
# It asserts the substitution actually applied, because a mutation that silently
# matches nothing reads as a passing guard and is the commonest way this kind of
# test lies about itself.
mutate(){
  local out="$ROOT/mut-$1.sh"
  python3 - "$TT" "$out" "$2" "$3" <<'PY'
import sys
src, dst, find, repl = sys.argv[1:5]
s = open(src).read()
assert find in s, "mutation target not found: " + find[:60]
open(dst, "w").write(s.replace(find, repl, 1))
PY
  printf '%s' "$out"
}

mk(){ # mk <id> <status> <goal> <milestone> <lane> <tier> <class> <domain> [blocked_on] [closer]
  python3 - "$STORE/$1.json" "$@" <<'PY'
import json, sys
p = sys.argv[1]
tid, status, goal, ms, lane, tier, cls, dom = sys.argv[2:10]
blocked = sys.argv[10] if len(sys.argv) > 10 else ""
closer  = sys.argv[11] if len(sys.argv) > 11 else ""
meta = {"goal": goal, "batch": ms, "lane": lane, "tier": tier, "class": cls, "domain": dom}
if blocked: meta["blocked_on"] = blocked
if closer:  meta["closer"] = closer
json.dump({"id": tid, "subject": f"Row {tid} states an outcome in a readable subject",
           "description": "", "status": status, "activeForm": None,
           "blocks": [], "blockedBy": [], "metadata": meta}, open(p, "w"), indent=1)
PY
}
reset(){ rm -f "$STORE"/*.json; }
render(){ rm -f "$ROOT/out"; HOME="$ROOT" bash "${1:-$TT}" --session box00001 > "$ROOT/out" 2>&1; }

echo "── 1. the box is closed, and the ball rides the rail rather than replacing it ──"
reset
mk 1 pending "Ship the thing" "M1" hands opus fix tasks
mk 2 pending "Ship the thing" "M1" hands opus build tasks
render
has "the box opens on a curved corner"     '^╭▏' "$ROOT/out"
has "the ball leads the plain title line, then the emoji" '^[🔴🟠🔵🟢⚪] · ' "$ROOT/out"
has "a rail runs down the left edge"       '^│' "$ROOT/out"
has "a full-width rule opens the box under the plain title" '^╭▏─────' "$ROOT/out"
has "the box closes on a curved corner"    '^╰▏' "$ROOT/out"

echo
echo "── 2. the column grid survives double-width emoji ──"
# The one defect most likely to sink this layout: emoji are two terminal columns
# and box characters are one, so a width computed with len() drifts the right
# edge of every line that carries a ball. The oracle below is deliberately NOT
# the renderer's own function — it is a hardcoded table of the glyphs this
# fixture uses, so a bug in dwidth() cannot hide by being consulted twice.
width_check(){
  python3 - "$1" <<'PY'
import sys, unicodedata
WIDE = set("🔴🟠🔵🟢⚪🤝💤✅⚡🏁📥🎯⚙🪝🎨🔧📄📐🧩🏭🔬🏃🛒🧰🔨📜🧱🔑💻🧪🧠📋📡🧭🧬"
           "🌀🔷🔶🟣🟤🧿🪐🍀🔺🧊")
def w(s):
    n = 0
    for ch in s:
        if ch in ("️", "︎") or unicodedata.category(ch) in ("Mn", "Me", "Cf"):
            continue
        n += 2 if (ch in WIDE or unicodedata.east_asian_width(ch) in ("W", "F")) else 1
    return n
# Since D3 (2026-09-08) the title is plain text and the corner carries only
# box characters, so the lines whose right edge depends on the width function
# are the rows (a clipped subject, the origin glyph) and the title lines (the
# lead glyphs). The widest of them must stay inside the box.
mx = 0
for line in open(sys.argv[1]):
    line = line.rstrip("\n")
    if line.startswith("│") or line.startswith("╭▏") or line[:1] in "🔴🟠🔵🟢⚪":
        mx = max(mx, w(line))
print(mx)
PY
}
# A measured row with a subject past the title width: its clip is the one place
# a len()-based width lets an extra column through.
python3 - "$STORE/3.json" <<'PY'
import json, sys
# One long token: a word-boundary clip would absorb a one-column drift.
json.dump({"id": "3", "subject": "Row3" + "x" * 160, "description": "",
           "status": "pending", "activeForm": None, "blocks": [], "blockedBy": [],
           "metadata": {"goal": "Ship the thing", "batch": "M1", "lane": "hands", "tier": "opus",
                        "class": "build", "domain": "tasks", "origin": "measured"}}, open(sys.argv[1], "w"), indent=1)
PY
render
w_real=$(width_check "$ROOT/out")
ok "no row, corner or title runs past the box width" "$([ "$w_real" -le 92 ] && echo inside || echo "over ($w_real)")" "inside"

M=$(mutate dwidth 'def dwidth(s):' 'def dwidth(s):
    return len(s)
def _dead_dwidth(s):')
render "$M"
w_mut=$(width_check "$ROOT/out")
ok "MUTATION: a len()-based width moves the right edge" \
   "$([ "$w_mut" = "$w_real" ] && echo same || echo drifted)" "drifted"
rm -f "$STORE/3.json"

echo
echo "── 3. the ball answers continuability, and is not any one task's state ──"
# A goal holding an owner gate reads 🔴 even though it also holds pickable work.
# That is the whole point of the field: it says whether the goal can move WITHOUT
# him, not what its first row happens to be doing.
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
mk 2 pending "Ship the thing" "M1" hands opus fix tasks "USER: rule on the shape"
render
has "a goal holding a gate reads red"       '^🔴 · ' "$ROOT/out"
has "and its ready row still renders green" '^│ +🟢 ○ ' "$ROOT/out"

reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
mk 2 in_progress "Ship the thing" "M1" brains opus fix tasks
render
has "ready outranks running when nothing is gated" '^🟢 · ' "$ROOT/out"

reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
mk 2 pending "Ship the thing" "M1" hands opus fix tasks "USER: rule on the shape"
M=$(mutate ballrank \
  'BALL_RANK = ["gate", "ready", "running", "review", "waiting", "unassigned",' \
  'BALL_RANK = ["ready", "gate", "running", "review", "waiting", "unassigned",')
render "$M"
hasnt "MUTATION: reordering precedence hides the gate" '^🔴 · ' "$ROOT/out"

echo
echo "── 4. the emoji identifies the goal and does not move when the ball does ──"
# The regression final.md records: revision 2 put the ball where the emoji was
# and the emoji vanished. They answer different questions, so this asserts BOTH
# are present and that the emoji is unchanged across a state change.
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
render
before=$(rg -o '^[🔴🟠🔵🟢⚪] · ([^ ]+)' -r '$1' "$ROOT/out" | head -1)
mk 2 pending "Ship the thing" "M1" hands opus fix tasks "USER: rule on the shape"
render
after=$(rg -o '^[🔴🟠🔵🟢⚪] · ([^ ]+)' -r '$1' "$ROOT/out" | head -1)
ok "the emoji is stable while the ball changes" "$before" "$after"
has "and the ball did change"                   '^🔴 · ' "$ROOT/out"
ok "the emoji is the domain's, not a hash"      "$before" "⚙️"

M=$(mutate emoji 'lead = f"{ball} · {emo}  "' 'lead = f"{ball}  "')
render "$M"
hasnt "MUTATION: dropping the emoji is caught" '^[🔴🟠🔵🟢⚪] · ' "$ROOT/out"

echo
echo "── 5. two lines always, and the traits never share a column ──"
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
render
has "the row carries a trait line under it (rail or not: one-row goals draw none)" '^[│ ] +◆ hands' "$ROOT/out"
has "each trait has its own marker"         '◆ hands.*◇ opus.*▪ build.*▫ tasks' "$ROOT/out"
hasnt "and nothing is stacked into one cell" 'hands·opus' "$ROOT/out"

M=$(mutate traits \
  'w("│" + " " * (ID_COL - 2) + cells.rstrip())' \
  'pass')
render "$M"
hasnt "MUTATION: dropping the trait line is caught" '^[│ ] +◆ hands' "$ROOT/out"

echo
echo "── 6. CLEAR NOW shows three and counts the rest, each with a closer ──"
reset
for i in 1 2 3 4 5; do
  mk "$i" pending "Ship the thing" "M1" hands opus fix tasks \
     "USER: clear item $i" "run: bash /tmp/clear-$i.sh — dry-run first"
done
mk 6 pending "Ship the thing" "M1" hands opus build tasks
render
has "the band names itself"          '^⚡ CLEAR NOW ' "$ROOT/out"
has "it shows three of five"         'CLEAR NOW   3 of 5 waiting on you' "$ROOT/out"
has "it says it spans goals and lanes" 'across 1 goal and 1 lane' "$ROOT/out"
has "each entry carries its closer"  '▸ run   bash /tmp/clear-1.sh' "$ROOT/out"
has "the hint survives beside it"    'dry-run first' "$ROOT/out"
has "and the remainder is counted, not listed" '\+2 more waiting on you' "$ROOT/out"

M=$(mutate clearcap 'CLEAR_CAP = 3' 'CLEAR_CAP = 99')
render "$M"
hasnt "MUTATION: an uncapped band stops reading as a sitting" '\+2 more waiting on you' "$ROOT/out"

echo
echo "── 7. a gate with no command-shaped closer still reaches CLEAR NOW, in the owner's words (Q1a) ──"
# Owner ruling 2026-09-05: "Every USER: gate reaches CLEAR NOW, capped at three
# with the rest counted; the steer/errand split is dropped." The old split printed
# "no closer" beside "USER: push is yours" and kept the band off five of six tabs.
reset
mk 1 pending "Ship the thing" "M1" hands opus fix tasks "USER: which shape do you want"
mk 2 pending "Ship the thing" "M1" hands opus build tasks
render
has "the gate reaches CLEAR NOW"            '^⚡ CLEAR NOW   1 of 1 waiting on you' "$ROOT/out"
has "its do-line is the owner's own prose"  '▸ do    which shape do you want' "$ROOT/out"
has "the header counts what needs him, in the legend's words" '🔴 1 need you' "$ROOT/out"
hasnt "no row is labelled as lacking a closer" 'no closer' "$ROOT/out"
hasnt "and no steers line remains"           '☎️' "$ROOT/out"

M=$(mutate admit 'clear_now = list(gates)' 'clear_now = [x for x in gates if meta_of(x, "closer")]')
render "$M"
hasnt "MUTATION: readmitting the split hides the ask from CLEAR NOW" '^⚡ CLEAR NOW' "$ROOT/out"
M=$(mutate prose 'if prose: found.append(("do", ellip(prose, 74), ""))' 'pass')
render "$M"
hasnt "MUTATION: dropping the prose fallback loses the do-line" '▸ do    which shape do you want' "$ROOT/out"

echo
echo "── 8. the 44-line law holds, and the id list is paid for out of the budget ──"
# The failure this pins is specific and was live: the held-id block is written
# after the boxes, so a budget that does not reserve it walks the render to 45
# and 46 while the footer still reports 44. Four real stores did exactly that.
reset
for i in $(seq 1 60); do
  mk "$i" pending "Ship the thing" "M$((i % 4))" hands opus build tasks
done
render
h=$(rg -o 'height ([0-9]+)/44' -r '$1' "$ROOT/out" | tail -1)
n=$(wc -l < "$ROOT/out" | tr -d ' ')
ok "the reported height is inside the law"  "$([ "${h:-99}" -le 44 ] && echo yes || echo "no ($h)")" "yes"
ok "and the reported height is the real one" "$h" "$n"
has "the truncation is loud"                'rows held by the height cap' "$ROOT/out"
has "and it accuses the data"               '^⚠ [0-9]+ rows not on screen' "$ROOT/out"

M=$(mutate budget \
  'LINE_CAP = HEIGHT - FOOTER - _res' \
  'LINE_CAP = HEIGHT - FOOTER')
render "$M"
mh=$(wc -l < "$ROOT/out" | tr -d ' ')
ok "MUTATION: unreserving the id block breaks the law" \
   "$([ "$mh" -gt 44 ] && echo over || echo "inside ($mh)")" "over"

echo
echo "── 9. the closing corner is charged to the budget ──"
# Its own fixture, and the count matters. Row cost changed on 2026-09-05 (the
# per-row blank line went, an all-empty trait row stopped printing, and a short
# note folded onto the trait row), and at 60 rows the render happened to land on
# 44 either way, so the guard passed while proving nothing. Measured across
# 20/30/40/50/60/80: the corner decides at 20, 40, 50 and 80 and is absorbed at
# 30 and 60. Re-measured 2026-09-05 after bands began ordering by recency (#56),
# which changes which band leads and so which row the cap lands on: the corner
# decides at 20, 40, 45, 70, 80, 90 and 100 and is absorbed at 30, 50, 55 and
# 60. Re-measured 2026-09-08 after the footer gained its "today: filed, closed"
# line, which moves every remainder by one: the corner now decides at 25, 30,
# 35, 55 and 60 and is absorbed at 20, 40, 45, 50, 70 and up (40, the previous
# pick, passed while proving nothing for a day). 30 is used here, and the
# assertion is that the mutation breaks the 44-line law outright rather than
# merely that the render grew, because "grew" is a fact about this fixture and
# "over the cap" is the actual defect.
reset
for i in $(seq 1 30); do
  mk "$i" pending "Ship the thing" "M$((i % 4))" hands opus build tasks
done
M=$(mutate boxowed 'def fits(n): return detail or len(out) + n + _box_owed <= LINE_CAP' \
                   'def fits(n): return detail or len(out) + n <= LINE_CAP')
render "$M"
mh=$(wc -l < "$ROOT/out" | tr -d ' ')
ok "MUTATION: an uncharged corner walks the render past the law" \
   "$([ "$mh" -gt 44 ] && echo over || echo "inside ($mh)")" "over"
render
h2=$(wc -l < "$ROOT/out" | tr -d ' ')
ok "and the real render stays inside it" \
   "$([ "$h2" -le 44 ] && echo inside || echo "over ($h2)")" "inside"

echo
echo
echo "── 11. the header names the store, never the reader (adv-tasks F1) ──"
# Rendering any store used to print the READER's ipc alias over another session's
# rows, and a hardcoded false alias survived every suite. The header now carries
# the store id, which cannot be wrong about whose rows these are.
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
render
has "the header carries the store id" '^TASKS  session-' "$ROOT/out"
hasnt "and not a reader alias" '^TASKS  gcc-work' "$ROOT/out"
M=$(mutate readeralias '_head = f"TASKS  {d.name}"' '_head = f"TASKS  SOMEONE-ELSES-SESSION"')
render "$M"
hasnt "MUTATION: a false identity in the header goes red" '^TASKS  session-' "$ROOT/out"

echo
echo "── 12. the goal emoji does not move when work closes (adv-tasks F6) ──"
# Three of five rows are 'hooks', two are 'tasks'. Close the three hooks rows and
# the dominant OPEN domain flips to tasks; the emoji must not follow it, because
# it identifies the goal across sessions and a field that changes cannot do that.
reset
mk 1 pending "Ship the thing" "M1" hands opus build hooks
mk 2 pending "Ship the thing" "M1" hands opus build hooks
mk 3 pending "Ship the thing" "M1" hands opus build hooks
mk 4 pending "Ship the thing" "M1" hands opus build tasks
mk 5 pending "Ship the thing" "M1" hands opus build tasks
render
e1=$(rg -o '^[🔴🟠🔵🟢⚪] · [^ ]+' "$ROOT/out" | head -1)
mk 1 completed "Ship the thing" "M1" hands opus build hooks
mk 2 completed "Ship the thing" "M1" hands opus build hooks
mk 3 completed "Ship the thing" "M1" hands opus build hooks
render
e2=$(rg -o '^[🔴🟠🔵🟢⚪] · [^ ]+' "$ROOT/out" | head -1)
ok "the emoji is the same after three rows close" "$e2" "$e1"

echo
echo "── 13. width follows the terminal; a long kind is not clipped (adv-tasks F10) ──"
# Owner: "It can be wider, that's fine". Piped output has no terminal, so the
# floor (92) applies and captured renders stay stable; a wide COLUMNS widens.
reset
mk 1 pending "Ship the thing" "M1" hands opus measure-then-tune tasks
mk 2 pending "Ship the thing" "M1" hands opus build tasks   # two rows: a one-row goal draws no rule (D3a)
render
has "a 17-char kind renders whole at the floor width" '▪ measure-then-tune' "$ROOT/out"
w0=$(rg -o '^╭▏─+' "$ROOT/out" | head -1 | wc -m | tr -d ' ')
rm -f "$ROOT/out"; HOME="$ROOT" COLUMNS=140 bash "$TT" --session box00001 > "$ROOT/out" 2>&1
w1=$(rg -o '^╭▏─+' "$ROOT/out" | head -1 | wc -m | tr -d ' ')
ok "COLUMNS=140 draws a wider rule than the floor" "$([ "${w1:-0}" -gt "${w0:-0}" ] && echo wider || echo "same ($w0 vs $w1)")" "wider"

echo
echo "── 14. a milestone named by one letter is flagged, a real name is not (owner 2026-09-05) ──"
reset
mk 1 pending "Ship the thing" "A" hands opus build tasks
mk 2 pending "Ship the thing" "A" hands opus fix tasks   # the flag rides the band header, which a one-row goal has no room for (D3a)
render
has "a one-letter milestone is marked too thin" '⚠ name too thin' "$ROOT/out"
reset
mk 1 pending "Ship the thing" "the change is under review as a PR" hands opus build tasks
mk 2 pending "Ship the thing" "the change is under review as a PR" hands opus fix tasks
render
hasnt "a state-shaped name is not marked" '⚠ name too thin' "$ROOT/out"
M=$(mutate thinflag 'if name in ("", "no milestone named yet") or len(letters) >= 3: return ""' 'if True: return ""')
reset
mk 1 pending "Ship the thing" "A" hands opus build tasks
render "$M"
hasnt "MUTATION: with the flag disabled the one-letter name passes silently" '⚠ name too thin' "$ROOT/out"

echo
echo "── 15. a parked goal and a stale running row are named, not miscounted (fleet #55 #56) ──"
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
mk 2 pending "Someday thing" "after V1" hands opus build tasks
render
has "a goal whose only open row is deferred reads as parked" '2 goal tags, 0 met, 1 parked' "$ROOT/out"
reset
mk 1 in_progress "Ship the thing" "M1" hands opus build tasks
touch -t 202601010000 "$STORE/1.json"
render
has "an in_progress row untouched for a day is named stale" '0 running, 1 stale' "$ROOT/out"
M=$(mutate stale '> 86400]' '> 86400000]')
render "$M"
hasnt "MUTATION: with the stale window widened the tombstone reads as running" '1 stale' "$ROOT/out"

echo
echo "── 16. what moved recently is named (fleet #56) ──"
reset
mk 1 completed "Ship the thing" "M1" hands opus build tasks
mk 2 pending "Ship the thing" "M1" hands opus build tasks
render
# Q8a (owner, 2026-09-05): counts, never ids; the ids live in --json.
# The "today: N filed, M closed" clause sits between the two since 2026-09-08
# (the backlog's growth on the first screen); this row pins the moved count and
# the done count on either side of it, not the exact middle.
has "a row closed just now is counted as moved" '1 moved in the last 6h   ·   today: 2 filed, 1 closed   ·   1 done, 1 closed with nothing named as proof   ·   ids in --json' "$ROOT/out"
hasnt "and the footer prints no id wall"        'done \(1\): #1' "$ROOT/out"
hasnt "nor a moved id list"                     'moved in the last 6h: #' "$ROOT/out"
HOME="$ROOT" bash "$TT" --session box00001 --json > "$ROOT/out.json" 2>&1
ok "--json carries the moved ids" "$(jq -r '.moved_recently | map(tostring) | index("1") != null' "$ROOT/out.json" 2>/dev/null)" "true"
M=$(mutate idwall "if _recent: _parts.append(f\"{len(_recent)} moved in the last {RECENT_H}h\")" "if _recent: _parts.append(\"moved in the last 6h: \" + \" \".join(f\"#{x['id']}\" for x in _recent))")
render "$M"
has "MUTATION: an id list in the footer is caught" 'moved in the last 6h: #' "$ROOT/out"
touch -t 202601010000 "$STORE/1.json"
render
hasnt "a row closed long ago is not counted" 'moved in the last' "$ROOT/out"

echo "── 17. the band that moved last comes first; unfiled never outranks a name (fleet #56) ──"
# f04ae843: the one band that fit was "(no batch)" holding August rows, and the
# three rows filed that evening were off screen. Alpha is stale, Zulu is fresh,
# and the unfiled row is fresher than both yet must still come last.
reset
mk 1 pending "Ship the thing" "Alpha" hands opus build tasks
mk 2 pending "Ship the thing" "Zulu"  hands opus build tasks
mk 3 pending "Ship the thing" ""      hands opus build tasks
touch -t 202601010000 "$STORE/1.json"
touch -t 202606010000 "$STORE/2.json"
bands(){ python3 - "$1" <<'PY'
import sys, re
print("|".join(re.sub(r"^.*▸ ", "", l.rstrip()) for l in open(sys.argv[1]) if "▸ " in l))
PY
}
render
ok "fresh Zulu, then stale Alpha, then the unfiled band" "$(bands "$ROOT/out")" "Zulu|Alpha|no milestone named yet"
M=$(mutate bandorder 'for sk in sorted(subs, key=_band_key)]' 'for sk in sorted(subs, key=natkey)]')
render "$M"
ok "MUTATION: natural order puts the unfiled band first and Alpha before Zulu" "$(bands "$ROOT/out")" "no milestone named yet|Alpha|Zulu"

echo "── 18. a box or a band never opens onto nothing, across a sweep of budgets (visual audit V1, V2) ──"
# f452498c closed a box on zero rows and fabad34c closed on a band header with
# nothing under it: the box priced its first row at one line and the band at two,
# while gate rows with a wrapped note cost up to five. One fixture size proves
# nothing here because the defect depends on the budget remainder at the moment
# the box is considered, so the sweep walks thirty remainders.
cat > "$ROOT/inv.py" <<'PY'
import sys, re
# A row is ball, twin, id. The ball alone is not enough: the "✅ when:" line under
# a meter (P3, case 26) carries the done ball at the row position and is not a
# row, and with the looser pattern this detector read an empty box as full.
ROW = re.compile("^│\\s+(🔴|🟠|🔵|🟢|🟣|💤|⚪|🤝|✅) \\S+ #\\d+")
lines = [l.rstrip("\n") for l in open(sys.argv[1], encoding="utf-8")]
bad = 0
for i, l in enumerate(lines):
    if l.startswith("╭▏"):
        j = i + 1
        while j < len(lines) and not lines[j].startswith("╰▏"): j += 1
        if not any(ROW.match(x) for x in lines[i:j]): bad += 1
    if l.startswith("│") and "▸ " in l:
        nxt = lines[i + 2] if i + 2 < len(lines) else ""
        if not ROW.match(nxt): bad += 1
print(bad)
PY
GATENOTE="USER: a ruling long enough that the note wraps onto its own lines and the row costs more than the two the old threshold assumed"
sweep(){ # sweep <renderer> -> violations summed over 1..45 filler rows
  # 45, not 30: once every gate also occupies CLEAR NOW lines (Q1a), the budget
  # remainders shifted and the flat-nine mutant needed a wider walk to bite.
  local tot=0 n i
  for n in $(seq 1 45); do
    reset
    for i in $(seq 1 "$n"); do mk "$i" pending "Alpha goal" "M1" hands opus build tasks; done
    # One gate per goal, not three: since Q1a every gate also takes two CLEAR NOW
    # lines, and six of them filled the screen before any box could meet the
    # remainder window the flat-nine mutant needs.
    for i in 41; do mk "$i" pending "Alpha goal" "M2" hands opus build tasks "$GATENOTE"; done
    # Two rows, because a one-row goal draws no box since D3a (2026-09-08) and the
    # expensive-first-row box is the one the flat nine opens onto nothing.
    for i in 51; do mk "$i" pending "Beta goal"  "B1" hands opus build tasks "$GATENOTE"; done
    for i in 52; do mk "$i" pending "Beta goal"  "B1" hands opus build tasks; done
    # A third goal with no gate draws last and is the one the cap refuses.
    for i in 61 62; do mk "$i" pending "Gamma goal" "G1" hands opus build tasks; done
    # The expensive band must come SECOND, because the box prices its first band
    # atomically; bands order by recency, so the gate rows are aged.
    for i in 41; do touch -t 202601010000 "$STORE/$i.json"; done
    render "$1"
    tot=$((tot + $(python3 "$ROOT/inv.py" "$ROOT/out")))
  done
  echo "$tot"
}
ok "no box or band opens onto nothing across thirty budgets" "$(sweep "$TT")" "0"
has "a goal the cap refused is named in one line" '^  no room left for: ' "$ROOT/out"
M=$(mutate boxnine 'if not fits(5 + len(_tlines) + _first + _dcost + _wcost):' 'if not fits(9):')
v=$(sweep "$M")
ok "MUTATION: a flat nine opens boxes onto nothing somewhere in the sweep" "$([ "$v" -gt 0 ] && echo caught || echo "missed (0)")" "caught"
M=$(mutate bandfour 'if not fits(2 + first_row_cost(body) + (0 if first else 1)):' 'if not fits(4 if first else 5):')
v=$(sweep "$M")
ok "MUTATION: a flat four leaves band headers with nothing under them" "$([ "$v" -gt 0 ] && echo caught || echo "missed (0)")" "caught"

echo "── 19. a long goal title wraps whole; it is never elided from the middle (visual audit V6) ──"
# The owner's own goal rendered as "tell the owner … without him decoding it": the
# mid-cut deleted "the truth" and left a sentence that still parsed. Wrapping costs
# one line, which the box prices in, so the 44-line law still holds under it.
reset
LONGTITLE="the /tasks and /goal surfaces tell the owner the truth without him decoding it, and every render says which store it read"
for i in $(seq 1 30); do mk "$i" pending "$LONGTITLE" "M1" hands opus build tasks; done
render
hasnt "no mid-ellipsis anywhere in the title" ' … ' "$ROOT/out"
has "the head of the title is on the lead line"     '^🟢 · .*the /tasks and /goal surfaces tell the owner the truth' "$ROOT/out"
has "and the tail follows on the next line, whole, with no rail in front of it"  '^every render says which store it read$' "$ROOT/out"
python3 - "$ROOT/out" "$LONGTITLE" > "$ROOT/joined" <<'PY'
import sys
lines = [l.rstrip("\n") for l in open(sys.argv[1], encoding="utf-8")]
i = next(k for k, l in enumerate(lines) if l.startswith(("🔴 · ", "🟠 · ", "🔵 · ", "🟢 · ", "⚪ · ")))
head = lines[i].split("  ", 1)[1].strip()
tail = lines[i + 1].strip()
print("WHOLE" if (head + " " + tail) == sys.argv[2] else f"CUT: {head} | {tail}")
PY
ok "the two lines together are the whole title, no word lost" "$(cat "$ROOT/joined")" "WHOLE"
n=$(wc -l < "$ROOT/out" | tr -d ' ')
ok "the wrapped title is paid for: the render stays inside the law" "$([ "$n" -le 44 ] && echo inside || echo "over ($n)")" "inside"
M=$(mutate titleclip '_tlines = wrap(title, room)' '_tlines = [title[:room // 2].rstrip() + " … " + title[-(room // 4):]]')
render "$M"
has "MUTATION: a mid-cut title is caught" ' … ' "$ROOT/out"

echo "── 20. a goal with no milestone named draws an empty meter, never a full one (visual audit V8) ──"
# mk always writes a batch key, and an empty one still counts as an unnamed
# milestone, so the zero-of-zero meter is reached by grouping on a key that has
# no milestones at all: domain.
reset
mk 1 pending "A goal that has named no state yet" "" hands opus build tasks
mk 2 pending "A goal that has named no state yet" "" hands opus fix tasks   # the meter is box chrome; one row draws none (D3a)
HOME="$ROOT" bash "$TT" --session box00001 --group domain > "$ROOT/out" 2>&1
has "zero of zero is an empty bar"   '▱▱▱▱▱▱▱▱▱▱  no milestone named yet' "$ROOT/out"
hasnt "and never a full one"         '██████████' "$ROOT/out"
M=$(mutate meterfull 'if not total: return "▱" * 10' 'if not total: return "█" * 10')
HOME="$ROOT" bash "$M" --session box00001 --group domain > "$ROOT/out" 2>&1
has "MUTATION: the full bar is caught" '██████████' "$ROOT/out"

echo "── 21. the header prints one !! at most; the rest, and every nag, live in --detail (visual audit V14) ──"
# Three stale gates fire two notes at once (the gates themselves, and the whole
# queue not having moved). Plain: the one that names rows he can re-check, with a
# count of what --detail holds. No header line ends in a question.
reset
for i in 1 2 3; do mk "$i" pending "Ship the thing" "M1" hands opus build tasks "USER: decide item $i"; done
for i in 1 2 3; do touch -t 202601010000 "$STORE/$i.json"; done
render
ok "exactly one !! line on the plain render"  "$(rg -c '^  !! ' "$ROOT/out" || echo 0)" "1"
has "and it is the one naming rows to re-check" '^  !! 3 gate\(s\) untouched >24h.*\+1 more nag in --detail' "$ROOT/out"
hasnt "no header line asks the reader a question" '^  .*\?$' "$ROOT/out"
HOME="$ROOT" bash "$TT" --session box00001 --detail > "$ROOT/out" 2>&1
ok "--detail carries both notes"  "$(rg -c '^  !! ' "$ROOT/out" || echo 0)" "2"
M=$(mutate hdrcap 'w(_bangs[0] + (f"   ·   +{_rest} more nag{'"'"'s'"'"' if _rest != 1 else '"'"''"'"'} in --detail" if _rest else ""))' 'for _l in _bangs: w(_l)')
render "$M"
ok "MUTATION: an uncapped header is caught" "$(rg -c '^  !! ' "$ROOT/out" || echo 0)" "2"

echo "── 10. an expanded note left-aligns to the row block, not the trait indent ──"
reset
LONGNOTE="USER: a ruling long enough that it cannot sit on the tail of one line and must take the full remaining width of the box to be read at all"
mk 1 pending "Ship the thing" "M1" hands opus fix tasks "$LONGNOTE"
mk 2 pending "Ship the thing" "M1" hands opus build tasks
render
# the collapsed note sits under the id (column 11); the expanded one starts left
# of it, at the ball's column, so it gets the width the design asked for
has "the expanded note starts at the ball column" '^│    » ' "$ROOT/out"
hasnt "and not at the trait indent"               '^│         » USER: a ruling long enough that it cannot sit on the tail of one line and' "$ROOT/out"

echo
echo "── 23. the goal is copyable: plain title above the rails (unblock-0908 D3 note, 2026-09-08) ──"
# Owner: "the box around the goal makes it hard to copy paste it, no fancy
# characters between the terminal text flow". A wrapped title's second line used
# to start with a rail, which rode along with the selection.
reset
LONG="The push gate accepts an answer the owner gives in the conversation from any client he uses, and a rail glyph never lands inside the text he selects"
mk 1 pending "$LONG" "M1" hands opus build tasks
mk 2 pending "$LONG" "M1" hands opus fix tasks
render
hasnt "no rail glyph on a title continuation line"   '^│ +[a-z].*he selects$' "$ROOT/out"
has "the continuation line is plain text at column 0" '^[a-z].*he selects$' "$ROOT/out"
has "the rule and the age moved to the opening corner" '^╭▏─+  ·  [0-9]+m$' "$ROOT/out"
hasnt "no rule line inside the box any more"         '^│  ─────' "$ROOT/out"
M=$(mutate railback 'for _tl in _tlines[1:]: w(_tl)' 'for _tl in _tlines[1:]: w("│  " + _tl)')
render "$M"
has "MUTATION: a rail on the continuation is caught" '^│ +[a-z].*he selects$' "$ROOT/out"

echo
echo "── 24. a one-row goal is its title and its row (unblock-0908 D3a, #44) ──"
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
render
hasnt "a one-row goal draws no corner"                 '^╭▏' "$ROOT/out"
has "its title carries the age on the same line"      '^🟢 · ⚙️  Ship the thing  ·  [0-9]+m$' "$ROOT/out"
has "and the row follows without a rail"              '^ +🟢 ○ #1 ' "$ROOT/out"
hasnt "no rail anywhere on a one-row store"            '^│' "$ROOT/out"
mk 2 pending "Ship the thing" "M1" hands opus fix tasks
render
has "two rows and the box is back"                     '^╭▏' "$ROOT/out"
reset
mk 1 pending "Ship the thing" "" hands opus build tasks
render
has "one row with no milestone still says what is missing" '^ +no milestone named yet' "$ROOT/out"
M=$(mutate collapse 'one_row = len(items) == 1 and not unfiled' 'one_row = False')
reset; mk 1 pending "Ship the thing" "M1" hands opus build tasks
render "$M"
has "MUTATION: the six-line box returns for one row"  '^╭▏' "$ROOT/out"

echo
echo "── 25. the armed goal rides its own /goal line, whole (unblock-0908 D2b, #38) ──"
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
mk 2 pending "Ship the thing" "M1" hands opus fix tasks
GOAL="The first screen of /tasks on a real project names what to act on, what is wrong and what is moving without scrolling, and each row names the outcome it serves. A closed row names what proved it."
rm -f "$ROOT/out"; HOME="$ROOT" TASKS_ARMED_GOAL="$GOAL" bash "$TT" --session box00001 > "$ROOT/out" 2>&1
has "line 1 says a goal is armed, without the text"   '^TASKS .*🎯 armed, on the /goal line below' "$ROOT/out"
hasnt "line 1 no longer clips the goal (Q7a retired)"  '^TASKS .*armed: The first' "$ROOT/out"
has "the goal rides its own /goal line, whole at the head" '^/goal The first screen of /tasks on a real project' "$ROOT/out"
has "and its tail follows at column 0 with no glyph"  '^[a-z].*proved it\.$' "$ROOT/out"
python3 - "$ROOT/out" "/goal $GOAL" > "$ROOT/joined" <<'PY'
import sys
lines = [l.rstrip("\n") for l in open(sys.argv[1], encoding="utf-8")]
i = next(k for k, l in enumerate(lines) if l.startswith("/goal "))
j = i
while j + 1 < len(lines) and lines[j + 1] and not lines[j + 1].startswith(("⚡", " ")): j += 1
print("WHOLE" if " ".join(lines[i:j + 1]) == sys.argv[2] else "CUT: " + " ".join(lines[i:j + 1]))
PY
ok "the /goal lines together are the whole goal, no word lost or clipped" "$(cat "$ROOT/joined")" "WHOLE"
n=$(wc -l < "$ROOT/out" | tr -d ' ')
ok "the goal lines are paid for: the render stays inside the law" "$([ "$n" -le 44 ] && echo inside || echo "over ($n)")" "inside"
M=$(mutate goalline 'for _gl in wrap("/goal " + _armed, BOX_W): w(_gl)' 'pass')
rm -f "$ROOT/out"; HOME="$ROOT" TASKS_ARMED_GOAL="$GOAL" bash "$M" --session box00001 > "$ROOT/out" 2>&1
hasnt "MUTATION: dropping the /goal line is caught"    '^/goal The first screen' "$ROOT/out"

echo
echo "── 26. what a goal says about itself: 🧭 direction above the title, ✅ when under the meter (P3, #24, 2026-09-08) ──"
# The store cannot say which direction a goal serves or what check closes it;
# directions.md could, and only on paper. P3 lands both as goal-level fields in
# a store sidecar (.goals, no .json suffix: pathlib's *.json glob reads dotfiles
# as rows). Additive: a store with no sidecar renders exactly as before.
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
mk 2 pending "Ship the thing" "M1" hands opus fix tasks
mk 3 pending "Land the other thing" "N1" hands opus build tasks
mk 4 pending "Land the other thing" "N1" hands opus fix tasks
render
hasnt "no sidecar: no direction line"                  '^🧭 ' "$ROOT/out"
hasnt "no sidecar: no when line"                       '✅ when: ' "$ROOT/out"
hasnt "no sidecar: the legend keys neither"            'direction the goal serves' "$ROOT/out"
base=$(wc -l < "$ROOT/out" | tr -d ' ')
cat > "$STORE/.goals" <<'JSON'
{"Ship the thing": {"direction": "See where things stand", "when": "checks 1 and 3 are green and a stranger answers the four questions"},
 "Land the other thing": {"direction": "See where things stand"}}
JSON
render
has "the direction is drawn above the box title, at column 0"  '^🧭 See where things stand$' "$ROOT/out"
ok "one direction line for two boxes that share it" "$(rg -c '^🧭 ' "$ROOT/out")" "1"
has "the when rides under the meter, on the rail"     '^│  ✅ when: checks 1 and 3 are green' "$ROOT/out"
ok "a goal with no when draws no when line (the legend's key is not a when line)" "$(rg -c '^│  ✅ when: ' "$ROOT/out")" "1"
has "the legend keys both"                             '🧭 direction the goal serves   ✅ when: the check that closes the goal' "$ROOT/out"
python3 - "$ROOT/out" > "$ROOT/order" <<'PY'
import sys
L = [l.rstrip("\n") for l in open(sys.argv[1], encoding="utf-8")]
d = next(i for i, l in enumerate(L) if l.startswith("🧭 "))
print("above a title" if L[d + 1][:1] in "🔴🟠🔵🟢" else f"line after: {L[d + 1][:40]!r}")
PY
ok "the direction line sits immediately above a box title" "$(cat "$ROOT/order")" "above a title"
n=$(wc -l < "$ROOT/out" | tr -d ' ')
ok "the two lines are paid for: one shared direction plus one when, inside the law" "$((n - base))·$([ "$n" -le 44 ] && echo inside || echo over)" "2·inside"
HOME="$ROOT" bash "$TT" --session box00001 --json > "$ROOT/out.json" 2>&1
ok "--json carries the goal-level fields by goal text" "$(jq -r '.goals["Ship the thing"].when | length > 0' "$ROOT/out.json" 2>/dev/null)" "true"
ok "and the sidecar is never read as a row"           "$(jq -r '[.tasks[].id] | length' "$ROOT/out.json")" "4"
# The one-row collapse (D3a) keeps both lines: the direction above the title,
# the when under it, without a rail since there is no box.
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
render
has "one-row goal: direction above the title"         '^🧭 See where things stand$' "$ROOT/out"
has "one-row goal: when under the title, no rail"     '^ +✅ when: checks 1 and 3' "$ROOT/out"
# A sidecar that does not parse is named in the header nag, never fatal.
echo "not json" > "$STORE/.goals"
render
has "a broken sidecar is reported, not fatal"          'goal sidecar did not parse' "$ROOT/out"
has "and the rows still render"                        '#1 ' "$ROOT/out"
rm -f "$STORE/.goals"
# Mutations, one per guard.
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
mk 2 pending "Ship the thing" "M1" hands opus fix tasks
printf '{"Ship the thing": {"direction": "See where things stand", "when": "checks 1 and 3 are green"}}' > "$STORE/.goals"
M=$(mutate nodir 'w(ellip(_dline, BOX_W)); _goal_lines_used.add("direction")' 'pass')
render "$M"
hasnt "MUTATION: dropping the direction line is caught" '^🧭 ' "$ROOT/out"
M=$(mutate nowhen 'if _when:
            for _wl in _when_lines("│  "): w(_wl)' 'pass')
render "$M"
hasnt "MUTATION: dropping the when line is caught"      '✅ when: ' "$ROOT/out"
# A dotfile JSON in the store is metadata, never a row. The first sidecar was
# named .goals.json and the renderer read it as a task (KeyError: status); the
# name changed AND the loader now skips dotfiles, so the class is closed twice.
printf '{"stray": "a dotfile json that is not a row"}' > "$STORE/.stray.json"
render
has "a stray dotfile json does not stop the render"    '#1 ' "$ROOT/out"
ok "and it is not counted as a row"                    "$(HOME="$ROOT" bash "$TT" --session box00001 --json 2>/dev/null | jq -r '[.tasks[].id] | length')" "2"
M=$(mutate dotrow 'if f.name.startswith("."): continue' 'pass')
render "$M"
has "MUTATION: without the skip, the dotfile is read as a row and the render dies" "KeyError|Traceback" "$ROOT/out"
rm -f "$STORE/.stray.json"
# The two lines are priced into the box's open-or-refuse decision. Pricing only
# bites at the margin, so the guard is a sweep like case 18, with case 18's
# detector: an unpriced box opens two lines short, its first row no longer
# fits, and the box closes on nothing (visual audit V1). The height law holds
# either way, because the row loop prices what it draws; the defect is the
# empty box, so that is what the sweep counts.
M=$(mutate unpriced 'if not fits(5 + len(_tlines) + _first + _dcost + _wcost):' 'if not fits(5 + len(_tlines) + _first):')
sweep_goal(){ # sweep_goal <renderer> -> "<empty boxes>/<max height>" over 1..45 filler rows
  local bad=0 mx=0 n i h
  for n in $(seq 1 45); do
    reset
    for i in $(seq 1 "$n"); do mk "$i" pending "Alpha goal" "M1" hands opus build tasks; done
    mk 51 pending "Beta goal" "B1" hands opus build tasks
    mk 52 pending "Beta goal" "B1" hands opus fix tasks
    printf '{"Beta goal": {"direction": "See where things stand", "when": "checks 1 and 3 are green"}}' > "$STORE/.goals"
    render "$1"
    bad=$((bad + $(python3 "$ROOT/inv.py" "$ROOT/out")))
    h=$(wc -l < "$ROOT/out" | tr -d ' '); [ "$h" -gt "$mx" ] && mx=$h
  done
  echo "$bad/$mx"
}
r=$(sweep_goal "$TT")
ok "the real render opens no empty box and stays inside the law across the sweep" "$([ "${r%/*}" -eq 0 ] && [ "${r#*/}" -le 44 ] && echo clean || echo "$r")" "clean"
r=$(sweep_goal "$M")
ok "MUTATION: unpriced goal lines open a box onto nothing somewhere in the sweep" "$([ "${r%/*}" -gt 0 ] && echo caught || echo "missed ($r)")" "caught"
rm -f "$STORE/.goals"

echo
echo "── 27. under batch grouping the milestone box still says direction › goal (the owner's gcp view groups by batch) ──"
reset
mk 1 pending "Ship the thing" "M1" hands opus build tasks
mk 2 pending "Ship the thing" "M1" hands opus fix tasks
mk 3 pending "Land the other thing" "N1" hands opus build tasks
mk 4 pending "Land the other thing" "N1" hands opus fix tasks
printf '{"Ship the thing": {"direction": "See where things stand", "when": "checks 1 and 3 are green"}}' > "$STORE/.goals"
rm -f "$ROOT/out"; HOME="$ROOT" bash "$TT" --session box00001 --group batch > "$ROOT/out" 2>&1
has "the M1 box carries direction › goal above its title" '^🧭 See where things stand › Ship the thing$' "$ROOT/out"
hasnt "a goal-level when is not drawn on a milestone box"  '✅ when: checks' "$ROOT/out"
ok "the N1 box, whose goal has no direction, draws no line" "$(rg -c '^🧭 ' "$ROOT/out")" "1"
rm -f "$STORE/.goals"

echo
echo "── 28. a milestone box under batch grouping meters its own rows (cold-read-P2b Q4, 2026-09-09) ──"
reset
mk 1 pending   "Ship the thing" "M1" hands opus build tasks
mk 2 completed "Ship the thing" "M1" hands opus fix tasks
mk 3 pending   "Ship the thing" "M1" hands opus fix tasks
mk 4 pending   "Ship the thing" "M2" hands opus build tasks
rm -f "$ROOT/out"; HOME="$ROOT" bash "$TT" --session box00001 --group batch > "$ROOT/out" 2>&1
has "the M1 box says how many of its rows are closed"  '^│  ▰▰▰▱▱▱▱▱▱▱  1 of 3 rows closed in this milestone$' "$ROOT/out"
hasnt "a batch box never says no milestone named yet"  'no milestone named yet' "$ROOT/out"
hasnt "the legend no longer says ball"                  "box's ball" "$ROOT/out"
M=$(mutate batchmeter 'if _allb:' 'if False:')
rm -f "$ROOT/out"; HOME="$ROOT" bash "$M" --session box00001 --group batch > "$ROOT/out" 2>&1
has "MUTATION: without the batch meter the cold reader's lie returns" 'no milestone named yet' "$ROOT/out"

echo
echo "── 29. the all-done screen: the done box meters its rows, the footer names no percentage of an empty queue (2026-09-09) ──"
reset
for i in $(seq 1 30); do mk "$i" completed "Ship the thing" "M$((i % 3))" hands opus build tasks; done
render
has "the done box carries a full meter of its own rows"  '^│  ▰▰▰▰▰▰▰▰▰▰  30 of 30 rows closed$' "$ROOT/out"
hasnt "no 'no milestone named yet' on a finished store"    'no milestone named yet' "$ROOT/out"
hasnt "no percentage of an empty queue"                    '% of the queue' "$ROOT/out"
has "the hidden done rows are named as done, with the flag that shows them" '^⚠ [0-9]+ done rows not on screen; --detail shows them' "$ROOT/out"
hasnt "no median over zero open rows"                      'median subject 0 chars' "$ROOT/out"
M=$(mutate donemeter 'if fixed_ball:' 'if False:')
render "$M"
has "MUTATION: without the synthetic-box meter the lie returns" 'no milestone named yet' "$ROOT/out"

echo
echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
