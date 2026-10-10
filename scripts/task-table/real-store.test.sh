#!/usr/bin/env bash
# The renderer is tested on the two stores the owner actually types /tasks into,
# frozen as fixtures, so a change that makes the forge-console render worse turns
# this red (alignment check 5). Synthetic fixtures never exceeded the height cap;
# these two do, which is where the renderer failed on 2026-09-07.
set -uo pipefail
FX="$HOME/.claude/scripts/task-table/fixtures"
# The frozen stores are Versable project text and the remote is public, so they
# stay local (unblock-0908 D4a, 2026-09-08); a clone without them skips, saying how.
if ! ls "$FX"/session-*.json >/dev/null 2>&1; then
  echo "SKIPPED: no frozen stores under $FX; freeze them locally: python3 $FX/freeze.py 1523e931 f04ae843"
  exit 0
fi
# A sandbox HOME, like every other suite: the fixtures used to unpack under the
# live ~/.claude/tasks, and a mid-run death left a store there (review 2026-09-08).
SRC="$HOME/.claude/scripts/task-table"; REAL="$HOME"; SB=$(mktemp -d "${TMPDIR:-/tmp}/realstore-home-XXXXXX")
mkdir -p "$SB/.claude/tasks" "$SB/.claude/scripts/task-table"
cp -f "$SRC/task-table.sh" "$SRC/task.sh" "$SRC/resolve-store.sh" "$SB/.claude/scripts/task-table/"
export HOME="$SB"
TT="$HOME/.claude/scripts/task-table/task-table.sh"
pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }
ROOT=$(mktemp -d "${TMPDIR:-/tmp}/realstore-XXXXXX")
trap 'export HOME="$REAL"; trash "$ROOT" "$SB" 2>/dev/null || true' EXIT

# Unpack a bundle into a throwaway store dir, restoring write times.
unpack(){ python3 - "$1" "$2" <<'PY'
import json, os, sys
b = json.load(open(sys.argv[1])); d = sys.argv[2]
os.makedirs(d, exist_ok=True)
for r in b["rows"]:
    p = os.path.join(d, r["name"]); json.dump(r["row"], open(p, "w"), indent=2)
    os.utime(p, (r["mtime"], r["mtime"]))
if b.get("project"): open(os.path.join(d, ".project"), "w").write(b["project"])
PY
}

for sid in f04ae843 1523e931 b8008a10 f452498c f5c44d78; do
  echo "── session-$sid, frozen ──"
  B="$FX/session-$sid.json"; G="$FX/session-$sid.golden.txt"
  [ -f "$B" ] && [ -f "$G" ] || { bad "fixture and golden present for $sid"; continue; }
  # Render the fixture under the live renderer by giving it a store dir of its own.
  # --session takes a sid8, so the fixture is unpacked under the real tasks root
  # with a fixture-only name and removed afterwards.
  FSID="fx${sid:0:6}"; D="$HOME/.claude/tasks/session-$FSID"
  unpack "$B" "$D"
  proj=$(cat "$D/.project" 2>/dev/null || echo "$HOME")
  ( cd "$proj" && bash "$TT" --session "$FSID" ) > "$ROOT/render-$sid.txt" 2>&1
  python3 "$FX/signature.py" < "$ROOT/render-$sid.txt" > "$ROOT/sig-$sid.txt"
  # the header names the fixture store, so drop that line's store name before comparing nothing else
  # REALSTORE_UPDATE=1 rewrites the golden from this render; used once when the
  # signature gains a fact, never to make a red run green.
  [ "${REALSTORE_UPDATE:-0}" = 1 ] && cp -f "$ROOT/sig-$sid.txt" "$G"
  if diff -q "$G" "$ROOT/sig-$sid.txt" >/dev/null; then ok "signature matches the golden"
  else bad "signature drifted from the golden"; diff "$G" "$ROOT/sig-$sid.txt" | sed 's/^/        /'; fi
  h=$(rg -o 'height ([0-9]+)/44' -r '$1' "$ROOT/render-$sid.txt" | head -1)
  [ -n "$h" ] && [ "$h" -le 44 ] && ok "height $h within the law" || bad "height ${h:-missing} breaks the law"
  # F5 (adv-tasks, owner D3a 2026-09-18): a store that drops rows must fill to
  # near the cap. Dropping a whole goal box while lines sit empty is the defect
  # b8008a10 exhibited (a 4-row box gone, 6+ lines unspent). A drop is allowed
  # only within 2 lines of the cap.
  if rg -q "rows not on screen|no room left for" "$ROOT/render-$sid.txt"; then
    { [ -n "$h" ] && [ "$h" -ge 42 ]; } && ok "drops rows only near the cap (height $h/44)" \
      || bad "F5: drops rows at height ${h:-?}/44, leaving $((44 - ${h:-44})) lines unspent"
  fi
  # control: a fixture with one OPEN gate removed must not match the golden. The
  # removable gate is an open row declared through blocked_on USER: or
  # metadata.state owner-gate; a store whose only gates are regex-detected or
  # already completed has none to pull, and the control is n/a rather than failed
  # (f5c44d78: all USER: rows completed, its live gate regex-detected).
  rm_id=$(python3 - "$D" <<'PY'
import glob, json, os, sys
d = sys.argv[1]; removed = "NONE"
for f in sorted(glob.glob(os.path.join(d, "*.json"))):
    t = json.load(open(f)); m = t.get("metadata") or {}
    st = (m.get("state") or "").lower()
    gate = str(m.get("blocked_on", "")).startswith("USER:") or st == "owner-gate"
    if t.get("status") != "completed" and gate:
        os.remove(f); removed = str(t.get("id", "?")); break
print(removed)
PY
)
  if [ "$rm_id" = NONE ]; then
    ok "mutation control n/a (no open declared gate to remove)"
  else
    ( cd "$proj" && bash "$TT" --session "$FSID" ) > "$ROOT/mut-$sid.txt" 2>&1
    python3 "$FX/signature.py" < "$ROOT/mut-$sid.txt" > "$ROOT/mutsig-$sid.txt"
    if diff -q "$G" "$ROOT/mutsig-$sid.txt" >/dev/null; then bad "MUTATION: removing gate #$rm_id left the signature unchanged"
    else ok "MUTATION: removing gate #$rm_id changes the signature"; fi
  fi
  trash "$D" 2>/dev/null || true
done
echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
