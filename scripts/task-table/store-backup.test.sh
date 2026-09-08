#!/usr/bin/env bash
# store-backup.test.sh — the snapshot is faithful, the lock is respected, and the
# restore does not destroy what it replaces.
#
# The restore cases matter most. A backup nobody has restored is a belief, not a
# backup, and the failure mode is silent until the one moment it is needed.
#
# Run: bash ~/.claude/scripts/task-table/store-backup.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
B="$HERE/store-backup.sh"
CHK="$HERE/migration-check.py"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/stbak-XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
STORE="$ROOT/.claude/tasks/session-bak001"
mkdir -p "$STORE"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }
has(){ if rg -q -- "$2" "$3" 2>/dev/null; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — no match for [$2]"; fi; }

mk(){ python3 - "$STORE/$1.json" "$1" "$2" <<'PY'
import json, sys
p, tid, subj = sys.argv[1:4]
json.dump({"id": tid, "subject": subj, "description": "", "status": "pending",
           "activeForm": None, "blocks": [], "blockedBy": [],
           "metadata": {"lane": "hands", "tier": "opus"}}, open(p, "w"), indent=1)
PY
}
for i in 1 2 3 4 5; do mk "$i" "row $i"; done

echo "── a snapshot copies every row ──"
out=$(HOME="$ROOT" bash "$B" bak001 2>&1)
snap=$(printf '%s' "$out" | rg -o 'snapshot: (.*)' -r '$1' | head -1)
ok "it names where it went" "$([ -n "$snap" ] && echo yes || echo no)" "yes"
ok "all five rows copied" "$(find "$snap/session-bak001" -name '*.json' | wc -l | tr -d ' ')" "5"

echo "── and the snapshot diffs clean against its source ──"
python3 "$CHK" "$snap/session-bak001" "$STORE" --quiet > "$ROOT/chk" 2>&1
ok "migration-check sees no difference" "$?" "0"
has "it says so" 'PASS' "$ROOT/chk"

echo "── the lock is never copied into the snapshot ──"
# Restoring a lock leaves a store every writer waits 5s on before giving up.
ok "no lock inside the snapshot" "$([ -d "$snap/session-bak001/.task-sh.lock" ] && echo present || echo absent)" "absent"

echo "── a store being written is REFUSED, not torn ──"
mkdir -p "$STORE/.task-sh.lock"
out=$(HOME="$ROOT" bash "$B" bak001 --out "$ROOT/locked" 2>&1)
rc=$?
rmdir "$STORE/.task-sh.lock"
ok "it exits non-zero" "$([ "$rc" != 0 ] && echo yes || echo no)" "yes"
printf '%s' "$out" > "$ROOT/lockout"
has "and says why, in the backup's own terms" 'not a backup' "$ROOT/lockout"

echo "── restore puts the rows back ──"
rm -f "$STORE"/*.json
mk 9 "the only row left"
ok "the store really was damaged" "$(find "$STORE" -name '*.json' | wc -l | tr -d ' ')" "1"
HOME="$ROOT" bash "$B" --restore "$snap" bak001 > "$ROOT/rest" 2>&1
ok "all five rows are back" "$(find "$STORE" -name '*.json' | wc -l | tr -d ' ')" "5"
python3 "$CHK" "$snap/session-bak001" "$STORE" --quiet > /dev/null 2>&1
ok "and they match the snapshot exactly" "$?" "0"

echo "── restore does not destroy what it replaced ──"
# The damaged store is moved aside, not deleted: a restore that discards the
# thing it replaces gives you one shot at being right about which copy was good.
aside=$(find "$ROOT/.claude/tasks" -maxdepth 1 -type d -name 'session-bak001.superseded-*' | head -1)
ok "the damaged store was kept" "$([ -n "$aside" ] && echo yes || echo no)" "yes"
ok "and it still holds the row it had" "$(find "$aside" -name '9.json' | wc -l | tr -d ' ')" "1"
has "the restore says where it went" 'moved aside' "$ROOT/rest"

echo "── a store that does not exist is refused by name ──"
HOME="$ROOT" bash "$B" nosuch01 > "$ROOT/none" 2>&1
ok "non-zero exit" "$?" "4"
has "names the store it could not find" 'session-nosuch01' "$ROOT/none"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
