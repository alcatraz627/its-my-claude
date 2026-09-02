#!/usr/bin/env bash
# Regression test for turnstate-active.sh, the shared "is this session mid-turn?"
# primitive that the warden beat, ward-revive, and ipc-wake all call. The wedge
# (an orphaned sentinel read as mid-turn forever) recurred once because the fix
# repointed two of three call sites; this pins the primitive so a future edit
# that reverts to bare existence goes red. The orphan case is the one that
# matters and the one the warden suites' fresh-only fixtures never exercised.
set -uo pipefail
SUT="$(cd "$(dirname "$0")" && pwd)/turnstate-active.sh"
SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
pass=0; fail=0
ok(){ printf '  ok    %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  FAIL  %s\n' "$1"; fail=$((fail+1)); }

# fresh sentinel → genuinely mid-turn (exit 0)
: > "$SB/fresh.json"
WARDEN_TURNSTATE_DIR="$SB" bash "$SUT" fresh && ok "fresh sentinel → active" || no "fresh should be active"

# 2h-old orphan → NOT mid-turn (exit 1). THE WEDGE CASE.
: > "$SB/orphan.json"; touch -t "$(date -v-2H +%Y%m%d%H%M)" "$SB/orphan.json"
WARDEN_TURNSTATE_DIR="$SB" bash "$SUT" orphan && no "orphan MUST NOT be active (the wedge)" || ok "2h orphan → not active (wedge stays fixed)"

# absent sentinel → not active
WARDEN_TURNSTATE_DIR="$SB" bash "$SUT" absent && no "absent should not be active" || ok "absent → not active"

# TTL boundary: 25m < 30m default → active; 35m > 30m → not
: > "$SB/under.json"; touch -t "$(date -v-25M +%Y%m%d%H%M)" "$SB/under.json"
: > "$SB/over.json";  touch -t "$(date -v-35M +%Y%m%d%H%M)" "$SB/over.json"
WARDEN_TURNSTATE_DIR="$SB" bash "$SUT" under && ok "25m < 30m TTL → active" || no "25m should be active"
WARDEN_TURNSTATE_DIR="$SB" bash "$SUT" over && no "35m should be stale" || ok "35m > 30m TTL → not active"

# custom TTL honored
WARDEN_TURNSTATE_DIR="$SB" bash "$SUT" under --ttl-min 5 && no "25m under a 5m TTL should be stale" || ok "--ttl-min 5 makes 25m stale"

printf -- '---- pass=%d fail=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
