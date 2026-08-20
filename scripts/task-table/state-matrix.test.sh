#!/usr/bin/env bash
# state-matrix.test.sh — render /tasks across a GRID of store shapes, and across
# every REAL store on this machine, asserting invariants that must hold in every
# cell.
#
# Why this exists as a second suite rather than more rows in task-table.test.sh.
# That suite has 51 assertions and every one of them renders a store WITH open
# rows. The zero-open state is never rendered once, so the branch that prints
# "written never ago" was unreachable from the entire suite no matter how many
# cases were added. Every defect the owner or a reviewer caught this week lived
# outside the shape its fixture had in mind:
#
#   - the height row sat green at 47/44 (its fixture had 2 bands; the overshoot
#     scales with band count)
#   - the subgroup guard stayed green when deleted (its fixture used 12 goals, so
#     the goal-level check bailed before the subgroup check ran)
#   - the all-done render was never exercised at all
#
# So the unit here is not a case, it is a CONDITION GRID plus the real corpus.
# Assertions are deliberately dumb and eyeball-checkable. A clever heuristic in
# a test is one more instrument that can be confidently wrong, and this file has
# already been bitten twice by that: an `rg -q` pipeline under `set -o pipefail`
# reports failure even on a match, because rg exits at the first hit and the
# producer dies of SIGPIPE. Every check below CAPTURES first, then matches.
set -uo pipefail

TT_SRC="${TT_SRC:-$HOME/.claude/scripts/task-table}"
REAL_HOME="$HOME"
pass=0; fail=0
ok(){ pass=$((pass+1)); }
ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

SB=$(mktemp -d)
mkdir -p "$SB/.claude/scripts/task-table" "$SB/.claude/tasks"
cp "$TT_SRC"/task-table.sh "$TT_SRC"/task.sh "$TT_SRC"/resolve-store.sh \
   "$SB/.claude/scripts/task-table/" 2>/dev/null
TT="$SB/.claude/scripts/task-table/task-table.sh"

# ---------------------------------------------------------------- invariants
# Each takes the captured output and a label. They never pipe into `rg -q`.
GLYPHS_LEGEND='✅:done ▶:running ○:ready ⛓:after 🔴:needs-you-declared ⏳:needs-you-inferred'

check_cell() {  # check_cell <label> <output> <store_dir>
  local label="$1" out="$2" dir="${3:-}" n body legend bad=0

  n=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  legend=$(printf '%s\n' "$out" | rg '^legend:' || true)
  body=$(printf '%s\n' "$out" | rg -v '^legend:' || true)

  # I1 — no internal placeholder or sentinel ever reaches the reader. Matched on
  # WORD BOUNDARIES, and usage-hint lines are exempt. A plain substring test was
  # tried first and flagged 'nan' inside the real task subject "Rezonant" and
  # '<sid8>' inside a legitimate "run: task-table.sh --session <sid8>" hint. A
  # check that cries wolf on real data gets muted, which is worse than no check.
  local leak
  leak=$(printf '%s\n' "$out" | python3 -c '
import sys, re
BAD = re.compile(r"\bnever ago\b|\bNone\b|\bnan\b|\bundefined\b|\$\{|Traceback")
HINT = re.compile(r"task-table\.sh|task\.sh|--session|--pin|regroup:")
for l in sys.stdin:
    if HINT.search(l): continue
    m = BAD.search(l)
    if m: print(m.group(0)); break
' 2>/dev/null || true)
  [ -z "$leak" ] || { ko "$label: output leaks the internal value '$leak'"; bad=1; }

  # I2 — the owner's height law. Wider is fine, taller is not.
  [ "$n" -le 44 ] || { ko "$label: $n lines, over the 44-line law"; bad=1; }

  # I3 — a band header must have at least one row before the next rule.
  printf '%s\n' "$out" | python3 -c '
import sys, re
L=[l.rstrip() for l in sys.stdin]
RULE=re.compile(r"^─{10,}")
TITLE=re.compile(r"^(GATES |LATER |[A-Z][A-Z/ ]+ )|^  [A-Z][A-Z]+ ")
ROW=re.compile(r"^\s+(○|▶|⛓|\U0001f534|⏳|✅)")
for i,l in enumerate(L):
    if l.startswith("TASKS ") or not TITLE.match(l): continue
    j=i+1; seen=False
    while j < len(L) and not RULE.match(L[j]):
        if ROW.match(L[j]): seen=True; break
        j+=1
    if not seen:
        print(l.strip()[:40]); sys.exit(1)
' >/dev/null 2>&1 || { ko "$label: a band header renders with zero rows under it"; bad=1; }

  # I8 — a DONE band must be titled by a real grouping key, never by an actor
  # bucket. With nothing live, auto-grouping used to probe the empty live list and
  # fall through to "actor", titling a finished store's bands "DONE · AGENT-READY"
  # while every row carried a goal. No invariant read band TITLES, which is why
  # that fix was unpinned (second seat, 2026-08-20).
  case "$out" in
    *"DONE · AGENT-READY"*|*"DONE · NEEDS YOU"*|*"DONE · NOW"*)
      ko "$label: a DONE band is titled with an actor bucket"; bad=1 ;;
  esac

  # I4 — the legend may only advertise glyphs the render actually used.
  if [ -n "$legend" ]; then
    local pair gl name
    for pair in $GLYPHS_LEGEND; do
      gl=${pair%%:*}; name=${pair##*:}
      case "$legend" in *"$gl"*) ;; *) continue;; esac
      case "$body"   in *"$gl"*) ;; *) ko "$label: legend advertises '$gl' ($name) but no row uses it"; bad=1;; esac
    done
  fi

  # I5 — a non-empty store must put at least one SUBJECT on screen. A table whose
  # entire content is a row of bare ids tells an out-of-context reader nothing,
  # which is the skill's own 2026-08-15 ruling applied to its own output.
  if [ -n "$dir" ] && [ "$(ls "$dir"/*.json 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]; then
    local subj; subj=$(python3 - "$dir" <<'PY' 2>/dev/null
import json, sys, glob, os
for f in sorted(glob.glob(os.path.join(sys.argv[1], "*.json")))[:1]:
    print((json.load(open(f)).get("subject") or "")[:18])
PY
)
    if [ -n "$subj" ]; then
      case "$out" in *"$subj"*) ;; *)
        # only a finding if NO subject at all appears, not just the first one
        local any=0 s
        while IFS= read -r s; do
          [ -z "$s" ] && continue
          case "$out" in *"$s"*) any=1; break;; esac
        done < <(python3 - "$dir" <<'PY' 2>/dev/null
import json, sys, glob, os
for f in sorted(glob.glob(os.path.join(sys.argv[1], "*.json"))):
    print((json.load(open(f)).get("subject") or "")[:18])
PY
)
        [ "$any" = 1 ] || { ko "$label: non-empty store, not one subject on screen"; bad=1; }
      ;; esac
    fi
  fi

  # I6 — if rows were dropped, the COUNT it claims must match the ids it names.
  # The first cut only asked whether a "#" appeared anywhere in the whole output,
  # which is true of every table that renders a single row, so it could not fail.
  case "$out" in
    *"held by the height cap"*)
      printf '%s\n' "$out" | python3 -c '
import sys, re
txt = sys.stdin.read()
m = re.search(r"\u2026 \+(\d+) rows held by the height cap[^:]*:(.*)", txt, re.S)
if not m: sys.exit(0)
claimed = int(m.group(1))
tail = m.group(2).split("legend:")[0]
named = len(re.findall(r"#\d+", tail))
extra = re.search(r"\u2026 \+(\d+) more ids in --json", tail)
if extra: named += int(extra.group(1))
sys.exit(1 if named != claimed else 0)
' >/dev/null 2>&1 || { ko "$label: hidden-row count does not match the ids named"; bad=1; } ;;
  esac

  [ $bad = 0 ] && ok
}

mkstore() {  # mkstore <sid> <open> <done> <gated> <meta:none|part|full>
  local sid=$1 no=$2 nd=$3 ng=$4 meta=$5 d="$SB/.claude/tasks/session-$sid" i=1 g=0 k=0 M
  rm -rf "$d"; mkdir -p "$d"
  case $meta in
    none) M='{}' ;;
    part) M='{"goal":"G1","batch":"A"}' ;;
    *)    M='{"goal":"G1","batch":"A","lane":"gcc","tier":"opus","note":"a note long enough to force the continuation line","priority":"P1"}' ;;
  esac
  while [ $i -le "$no" ]; do
    printf '{"id":"%s","subject":"open item %s doing a thing","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":%s}' \
      "$i" "$i" "$M" > "$d/$i.json"; i=$((i+1))
  done
  # blocked_on lives in METADATA, not at the top level. The first cut of this
  # helper put it at the top and every "gated" row rendered as an ordinary one,
  # so the whole gate dimension of the grid was testing nothing. Verified against
  # a real gated task: tasks/session-f5c44d78/105.json carries it under metadata.
  local MG; MG=$(printf '%s' "$M" | python3 -c 'import json,sys; d=json.load(sys.stdin); d["blocked_on"]="USER: decide something"; print(json.dumps(d))')
  while [ $g -lt "$ng" ]; do
    printf '{"id":"%s","subject":"gated item %s","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":%s}' \
      "$i" "$i" "$MG" > "$d/$i.json"; i=$((i+1)); g=$((g+1))
  done
  while [ $k -lt "$nd" ]; do
    printf '{"id":"%s","subject":"finished item %s with a real subject","description":"","status":"completed","blocks":[],"blockedBy":[],"metadata":%s}' \
      "$i" "$i" "$M" > "$d/$i.json"; i=$((i+1)); k=$((k+1))
  done
  printf '%s' "$d"
}

echo "== condition grid =="
export HOME="$SB"
cells=0
for open_n in 0 1 6 40 200; do
  for done_n in 0 11 90; do
    for gate_n in 0 3; do
      for meta in none part full; do
        cells=$((cells+1))
        sid=$(printf 'g%07d' $cells)
        dir=$(mkstore "$sid" "$open_n" "$done_n" "$gate_n" "$meta")
        out=$(bash "$TT" --session "$sid" 2>&1)
        check_cell "open=$open_n done=$done_n gate=$gate_n meta=$meta" "$out" "$dir"
      done
    done
  done
done
echo "  grid cells: $cells"

echo "== grouping keys, on a store that has every metadata key =="
sid=grp00001; dir=$(mkstore "$sid" 12 4 2 full)
for g in goal batch domain class planning tier actor; do
  out=$(bash "$TT" --session "$sid" --group "$g" 2>&1)
  check_cell "--group $g" "$out" "$dir"
done

echo "== degenerate stores =="
d="$SB/.claude/tasks/session-empty001"; mkdir -p "$d"
out=$(bash "$TT" --session empty001 2>&1); check_cell "empty store" "$out" ""
d="$SB/.claude/tasks/session-onerow01"; mkdir -p "$d"
printf '{"id":"1","subject":"the only task","description":"","status":"completed","blocks":[],"blockedBy":[],"metadata":{}}' > "$d/1.json"
out=$(bash "$TT" --session onerow01 2>&1); check_cell "one done row, no metadata" "$out" "$d"

echo "== the tag cell cuts on tag boundaries, never mid-word =="
# Deliberately NOT a heuristic over real output. The first cut of this check
# guessed that a trailing tag under 4 characters was a truncation, and flagged
# the real domain names "kit", "ui" and "deck" on two live stores. A test that
# cries wolf on real data is the defect this suite exists to stop, so this
# constructs KNOWN tags and asserts an exact property instead.
export HOME="$SB"
d="$SB/.claude/tasks/session-tagcut01"; rm -rf "$d"; mkdir -p "$d"
printf '{"id":"1","subject":"short subject","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"class":"gate-adherence-with-a-very-long-name","domain":"forge-platform-services","batch":"deployment-pipeline","planning":"V1-showable-milestone"}}' > "$d/1.json"
tagout=$(bash "$TT" --session tagcut01 2>&1 | rg '^\s+○' || true)
cell=$(printf '%s' "$tagout" | sed 's/.*  //')
case "$cell" in
  *"…"|*"+1"|*"+2"|*"+3") ok ;;   # "…" = this tag is cut, "+N" = N whole tags dropped
  *) # nothing dropped: then every tag must be present whole
     miss=0
     for t in "gate-adherence-with-a-very-long-name" "forge-platform-services"; do
       case "$tagout" in *"$t"*) ;; *) miss=1;; esac
     done
     [ "$miss" = 0 ] && ok || ko "tag cell dropped tags without an ellipsis: [$cell]" ;;
esac
# and no cut may leave a bare word fragment of a KNOWN tag
frag=0
for t in "gate-adherenc" "forge-platfor" "deployment-pipelin" "V1-showabl"; do
  case "$tagout" in *"$t "*|*"$t"$'\n'*) frag=1;; esac
done
[ "$frag" = 0 ] && ok || ko "tag cell contains a mid-word fragment of a known tag"

echo "== a glyph inside a subject does not vote itself into the legend =="
d="$SB/.claude/tasks/session-glyph001"; rm -rf "$d"; mkdir -p "$d"
printf '{"id":"1","subject":"ship it \u2705 and mark \U0001F534 urgent","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"G1"}}' > "$d/1.json"
gl=$(bash "$TT" --session glyph001 2>&1 | rg "^legend:" || true)
case "$gl" in
  *"✅ done"*) ko "a ✅ in a subject put 'done' in the legend with no done row" ;;
  *) ok ;;
esac
case "$gl" in
  *"🔴 needs you"*) ko "a 🔴 in a subject put 'needs you' in the legend with no gated row" ;;
  *) ok ;;
esac

echo "== --json always answers in JSON, including when it refuses =="
# A refusal must arrive in the format the caller asked for. `--json` was printing
# the human refusal to stdout, so a caller piping into jq got a parse error
# instead of a reason it could act on (gcp-fable, 2026-08-20).
export HOME="$SB"
# ALL THREE refusal paths, not just the two I first thought of. --pin was a third
# and emitted no JSON (second seat, 2026-08-20).
jout=$(bash "$TT" --json --session zzzzzzzz 2>/dev/null)
printf '%s' "$jout" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null \
  && ok || ko "--json --session <unknown>: not parseable JSON"
jout=$(bash "$TT" --json --pin zzzzzzzz 2>/dev/null)
printf '%s' "$jout" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null \
  && ok || ko "--json --pin <unknown>: not parseable JSON"
jout=$(bash "$TT" --json 2>/dev/null)
printf '%s' "$jout" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null \
  && ok || ko "--json with no resolvable store: not parseable JSON"
sid=jok00001; dir=$(mkstore "$sid" 5 2 1 full)
jout=$(bash "$TT" --json --session "$sid" 2>/dev/null)
printf '%s' "$jout" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null \
  && ok || ko "--json on a good store: not parseable JSON"

echo "== peer-reported shapes: status vocabulary and deferral markers =="
export HOME="$SB"
# (a) A store in the wild carried status "done", not "completed". The renderer
# counted those rows as neither open nor done, so seven finished rows vanished
# from the tally AND the done line (vb-fable, real store c8bc2450, 2026-08-20).
d="$SB/.claude/tasks/session-stat0001"; rm -rf "$d"; mkdir -p "$d"
printf '{"id":"1","subject":"finished the old way","description":"","status":"done","blocks":[],"blockedBy":[],"metadata":{"goal":"G1"}}' > "$d/1.json"
printf '{"id":"2","subject":"finished the new way","description":"","status":"completed","blocks":[],"blockedBy":[],"metadata":{"goal":"G1"}}' > "$d/2.json"
so=$(bash "$TT" --session stat0001 2>&1)
case "$so" in *"2 done"*) ok ;; *) ko "status 'done' not counted: $(printf '%s' "$so" | head -1)" ;; esac
case "$so" in *"other"*) ko "a 'done' row was bucketed as 'other'" ;; *) ok ;; esac
case "$so" in *"finished the old way"*) ok ;; *) ko "the status-'done' row never reached the screen" ;; esac

# (b) A deferral marker LEADS a label. Searching the whole string banished a lane
# whose goal merely mentioned "after", and any batch whose label said "deploy".
d="$SB/.claude/tasks/session-defr0001"; rm -rf "$d"; mkdir -p "$d"
printf '{"id":"1","subject":"active lane work","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"Kit lane after the console handover","batch":"deploy pipeline"}}' > "$d/1.json"
printf '{"id":"2","subject":"genuinely parked","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"Kit lane after the console handover","batch":"after V1"}}' > "$d/2.json"
do_=$(bash "$TT" --session defr0001 2>&1)
printf '%s\n' "$do_" | python3 -c '
import sys
L=[l.rstrip() for l in sys.stdin]
later=False; banished=False; parked=False
for l in L:
    if l.startswith("LATER"): later=True; continue
    if l and not l.startswith(" ") and not l.startswith("\u2500"): later=False
    if later and "active lane work" in l: banished=True
    if later and "genuinely parked" in l: parked=True
sys.exit(0 if (not banished and parked) else 1)' >/dev/null 2>&1 \
  && ok || ko "deferral inference wrong: prose 'after'/'deploy' banished active work, or 'after V1' failed to defer"

echo "== a delegated row belongs to neither the owner nor this agent =="
# Owner instruction relayed 2026-08-20: mark work another agent took as delegated,
# with metadata naming who. The point is honesty in the counts: a peer had 42
# owner-gates of which five were only there because the work was FILED in their
# store, and that inflation is what made their render unusable.
export HOME="$SB"
d="$SB/.claude/tasks/session-deleg001"; rm -rf "$d"; mkdir -p "$d"
printf '{"id":"1","subject":"mine to do","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"G1"}}' > "$d/1.json"
printf '{"id":"2","subject":"someone else has this","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"G1","blocked_on":"USER: decide","delegated_to":"peer-x"}}' > "$d/2.json"
printf '{"id":"3","subject":"handed over and acknowledged","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"G1","delegated_to":"peer-y","delegated_confirmed":"true"}}' > "$d/3.json"
dout=$(bash "$TT" --session deleg001 --detail 2>&1)
case "$dout" in *"DELEGATED"*) ok "delegated rows get their own band" ;; *) ko "no DELEGATED band" ;; esac
case "$dout" in *"delegated to peer-x"*) ok "the band names who took it" ;; *) ko "band does not name the delegate" ;; esac
case "$dout" in *"unconfirmed"*) ok "delegated-but-unacknowledged is distinguishable" ;; *) ko "unconfirmed state not shown" ;; esac
case "$dout" in *"CONFIRMED"*) ok "delegated-and-acknowledged is distinguishable" ;; *) ko "confirmed state not shown" ;; esac
# the load-bearing one: a delegated row that ALSO carries blocked_on must not
# count as an owner gate, or the inflation this feature exists to remove survives
gline=$(printf '%s\n' "$dout" | rg "^GATES" || true)
[ -z "$gline" ] && ok "a delegated row carrying blocked_on does NOT inflate GATES" \
                || ko "delegated row still counted as an owner gate: $gline"
dig=$(bash "$TT" --session deleg001 --compact 2>&1)
case "$dig" in *"2 delegated"*) ok "the injected digest counts them separately" ;; *) ko "digest hides delegation: $dig" ;; esac

echo "== the TRANSCRIPT path: content-match, end to end =="
# The owner asked for "actual session transcripts". Every arm above reaches the
# renderer through --session, which is the explicit rung and bypasses
# resolve-store.sh entirely. The resolver is the component that decides WHICH
# table you see, its own header records that misidentification "rendered agents
# each other's queues (owner report 2026-08-16)", and it reads TRANSCRIPTS. So
# this arm builds a real transcript, with real task subjects in it, and drives
# the bare command that a session actually runs.
export HOME="$SB"
TSID=11111111-2222-3333-4444-555555555555
PROJ="$SB/proj"; mkdir -p "$PROJ"
TDIR="$SB/.claude/projects/$(printf '%s' "$PROJ" | sed 's#/#-#g')"; mkdir -p "$TDIR"
d="$SB/.claude/tasks/session-tr000001"; rm -rf "$d"; mkdir -p "$d"
i=1
for subj in "wire the census exporter to the new schema" \
            "backfill the delivery ledger for July" \
            "retire the legacy webhook shim"; do
  printf '{"id":"%s","subject":"%s","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"goal":"G1"}}' \
    "$i" "$subj" > "$d/$i.json"; i=$((i+1))
done
# a decoy store, so a correct answer cannot come from "there is only one"
dd="$SB/.claude/tasks/session-tr000002"; rm -rf "$dd"; mkdir -p "$dd"
printf '{"id":"1","subject":"something completely unrelated about fonts","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{}}' > "$dd/1.json"
# The transcript must carry the literal "subject":"..." key UNESCAPED, because
# that is what resolve-store.sh scrapes (:158). In real transcripts it appears
# that way inside a TaskCreate tool_use input and its toolUseResult, which are
# structured JSON rather than strings, so the quotes are not escaped. Verified:
# 40 of 184 transcripts on this machine carry it, and they are exactly the
# sessions that had a Task tool. Two earlier cuts of this fixture wrote the
# subjects as prose, then as escaped JSON inside a string; both scraped to
# nothing and looked like a resolver bug rather than a fixture bug.
{
  printf '{"type":"user","timestamp":"2026-08-20T00:00:00Z","message":{"role":"user","content":"work the list"}}\n'
  for subj in "wire the census exporter to the new schema" \
              "backfill the delivery ledger for July" \
              "retire the legacy webhook shim"; do
    printf '{"type":"assistant","timestamp":"2026-08-20T00:00:01Z","message":{"role":"assistant","content":[{"type":"tool_use","name":"TaskCreate","input":{"subject":"%s","status":"pending"}}]}}\n' "$subj"
  done
} > "$TDIR/$TSID.jsonl"

( cd "$PROJ" && CLAUDE_CODE_SESSION_ID="$TSID" bash "$SB/.claude/scripts/task-table/resolve-store.sh" >"$SB/rs.out" 2>"$SB/rs.err" )
resolved=$(cat "$SB/rs.out" 2>/dev/null)
case "$resolved" in
  *session-tr000001*) ok ;;
  *) ko "resolver did not content-match the transcript to its store (got: '${resolved:-<empty>}')" ;;
esac
case "$resolved" in
  *session-tr000002*) ko "resolver picked the DECOY store" ;;
  *) ok ;;
esac
# and the bare command, the one a session actually types, must render that store
bare=$( cd "$PROJ" && CLAUDE_CODE_SESSION_ID="$TSID" bash "$TT" 2>&1 )
case "$bare" in
  *"census exporter"*) ok ;;
  *) ko "bare task-table.sh did not render the content-matched store" ;;
esac
check_cell "transcript-resolved bare run" "$bare" "$d"

echo "== the REAL corpus on this machine =="
# Synthetic shapes are chosen by whoever writes them, so they exercise the branch
# the author had in mind. These are not. rules/testing.md [real-input-distribution].
# HOME goes back to the real tree so --session finds the real STORES, but the
# script invoked is still $TT, the copy under test. Both halves matter: pointing
# this arm at the live script (it did until 2026-08-20) made 81 of the assertions
# immune to mutation, so a fix could be reverted and the suite stayed green, which
# is the unpinned-guard shape this suite exists to catch.
export HOME="$REAL_HOME"
real=0; skipped=0
for d in "$REAL_HOME"/.claude/tasks/session-*/; do
  [ -d "$d" ] || continue
  cnt=$(ls "$d"*.json 2>/dev/null | wc -l | tr -d ' ')
  [ "${cnt:-0}" -gt 0 ] || { skipped=$((skipped+1)); continue; }
  sid=$(basename "$d"); sid=${sid#session-}
  out=$(bash "$TT" --session "$sid" 2>&1)
  check_cell "real store $sid ($cnt rows)" "$out" "$d"
  real=$((real+1))
done
echo "  real stores rendered: $real (skipped $skipped empty)"

export HOME="$REAL_HOME"; trash "$SB" 2>/dev/null || rm -rf "$SB"
echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
