#!/usr/bin/env bash
# pin-location.test.sh — the live-session pin lives outside ~/.claude/tasks, and
# a pin left in the old place still resolves.
#
# WHY IT MOVED. The pin used to sit at tasks/.live-session-map/<live8> and the
# LIVE session's own entry kept disappearing: written, confirmed on disk, read
# back correctly by the next wake, gone by the wake after. Measured across four
# fleet wakes on 2026-09-04. Nothing in this repo removes it, and running every
# task-table command in turn against a fresh pin removed none of them. What the
# evidence shows is a difference by location: sixty pins for dead sessions have
# sat there since August and tasks-view.json, outside tasks/, is untouched since
# 19 August, while only the entry named for the live session vanishes.
# ~/.claude/tasks is the harness's own Task-tool storage and a file in it named
# exactly the live session id reads as harness session state.
#
# So these cases pin the LOCATION, which is the part the evidence supports. They
# deliberately do not assert anything about what was deleting it, because that
# was not findable and a test that encodes a guess is worse than no test.
#
# Run: bash ~/.claude/scripts/task-table/pin-location.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TT="$HERE/task-table.sh"
TS="$HERE/task.sh"
RS="$HERE/resolve-store.sh"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pinloc-XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT

SID="pin00001"
STORE="$ROOT/.claude/tasks/session-$SID"
mkdir -p "$STORE"
python3 - "$STORE/1.json" <<'PY'
import json, sys
json.dump({"id": "1", "subject": "a row so the store is not empty", "description": "",
           "status": "pending", "activeForm": None, "blocks": [], "blockedBy": [],
           "metadata": {"lane": "hands", "tier": "opus"}}, open(sys.argv[1], "w"), indent=1)
PY

LIVE="f0000000-1111-2222-3333-444444444444"
LIVE8="f0000000"
pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }
has(){ if rg -q -- "$2" "$3" 2>/dev/null; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — no match for [$2]"; fi; }

run(){ HOME="$ROOT" CLAUDE_CODE_SESSION_ID="$LIVE" "$@"; }

echo "── --pin writes outside ~/.claude/tasks ──"
run bash "$TT" --pin "$SID" > /dev/null 2>&1
ok "the pin is in the new location"  "$([ -f "$ROOT/.claude/tasks-pins/$LIVE8" ] && echo yes || echo no)" "yes"
ok "and NOT back inside tasks/"      "$([ -f "$ROOT/.claude/tasks/.live-session-map/$LIVE8" ] && echo yes || echo no)" "no"
ok "it names the right store"        "$(cat "$ROOT/.claude/tasks-pins/$LIVE8")" "$SID"

echo "── every reader resolves from it ──"
run bash "$TT" > "$ROOT/render" 2>&1
has "task-table renders the pinned store" "session-$SID" "$ROOT/render"
has "and says the pin resolved it"        "found by the pin for this session" "$ROOT/render"
ok "task.sh agrees"      "$(run bash "$TS" store 2>/dev/null)" "$ROOT/.claude/tasks/session-$SID"
ok "resolve-store agrees" "$(run bash "$RS" 2>/dev/null)"      "$ROOT/.claude/tasks/session-$SID"

echo "── a pin left in the OLD place still works ──"
# Nobody writes there any more, but an existing one must not stop resolving the
# day this lands, or every session with a working pin loses it at once.
rm -rf "$ROOT/.claude/tasks-pins"
mkdir -p "$ROOT/.claude/tasks/.live-session-map"
printf '%s' "$SID" > "$ROOT/.claude/tasks/.live-session-map/$LIVE8"
run bash "$TT" > "$ROOT/legacy" 2>&1
has "task-table still finds the store" "session-$SID" "$ROOT/legacy"
has "and says the location is the old one"  "the pin for this session \(old location\)" "$ROOT/legacy"
ok "task.sh reads it too"      "$(run bash "$TS" store 2>/dev/null)" "$ROOT/.claude/tasks/session-$SID"
ok "resolve-store reads it too" "$(run bash "$RS" 2>/dev/null)"      "$ROOT/.claude/tasks/session-$SID"

echo "── a pin naming a store that no longer exists is not used ──"
rm -rf "$ROOT/.claude/tasks/.live-session-map"
mkdir -p "$ROOT/.claude/tasks-pins"
printf '%s' "gone0001" > "$ROOT/.claude/tasks-pins/$LIVE8"
run bash "$TT" > "$ROOT/stale" 2>&1
ok "it refuses rather than rendering a ghost" "$([ $? -ne 0 ] || rg -q 'could not identify' "$ROOT/stale" && echo refused || echo rendered)" "refused"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
