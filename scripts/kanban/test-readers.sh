#!/usr/bin/env bash
# Reader sweep for the multi-note store. Every reader of notes.json is exercised
# against a board whose notes carry a notes[] array, including the jq one that no
# compiler sees. Assertions are POSITIVE: a negative-only check passes on the
# silent-zero failure this suite exists to catch.
#
#   bash test-readers.sh            run
#   bash test-readers.sh --mutate   break the derived field first, expect RED
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="${TMPDIR:-/tmp}/kanban-readertest.$$"
BOARDS="$HOME/.claude/kanban/boards"
pass=0; fail=0
ok(){ echo "  PASS  $1"; pass=$((pass+1)); }
no(){ echo "  FAIL  $1"; fail=$((fail+1)); }

mkdir -p "$ROOT/docs"
# the registry stores the canonical root, and /tmp is a symlink on macOS, so a
# cwd of /tmp/... never matches and every reader goes silently quiet
ROOT="$(cd "$ROOT" && pwd -P)"
cat > "$ROOT/docs/plan.md" <<'EOF'
# Plan

## In progress

- [ ] first item
- [ ] second item
EOF

slug=$(bun "$HERE/cli.ts" init --project "$ROOT" 2>/dev/null | rg -o 'board ready: ([a-z0-9-]+)' -r '$1' | head -1)
[ -n "$slug" ] || { echo "SETUP FAILED: no board"; exit 1; }
dir="$BOARDS/$slug"
card=$(python3 -c "
import json;print(json.load(open('$dir/board.json'))['cards'][0]['id'])")

# Two notes on one card, one of them @me. @me must suppress; the other must not.
python3 - "$dir/notes.json" "$card" <<'PY'
import json, sys
path, card = sys.argv[1], sys.argv[2]
now = "2099-01-01T00:00:00.000Z"
notes = [
    {"id": "n1", "body": "!now the visible ask", "updatedAt": now},
    {"id": "n2", "body": "@me a private reminder", "updatedAt": now},
]
json.dump({card: {"note": "!now the visible ask", "updatedAt": now,
                  "notes": notes, "activeId": "n1"}}, open(path, "w"), indent=2)
PY

if [ "${1:-}" = "--mutate" ]; then
  # Break the derived field the way a bad migration would: leave notes[] correct
  # and let the legacy string go empty. Every reader below must notice.
  python3 -c "
import json
p='$dir/notes.json'; d=json.load(open(p))
for v in d.values(): v['note']=''
json.dump(d,open(p,'w'),indent=2)"
  echo "  (mutated: legacy derived field emptied)"
fi

echo "reader sweep on $slug"

# 1. the jq reader, the one with no compiler between it and the schema
out=$(echo "{\"cwd\":\"$ROOT\"}" | bash "$HERE/session-start-line.sh" 2>/dev/null)
n=$(printf '%s' "$out" | jq -r '.additionalContext // ""' 2>/dev/null | rg -o '([0-9]+) unread' -r '$1' | head -1)
[ "${n:-0}" -ge 1 ] 2>/dev/null && ok "session-start-line reports ${n:-0} unread (non-zero)" \
  || no "session-start-line reported '${n:-0}' unread; silent-zero is the failure mode"

# 2. the @me note must NOT be counted, so exactly one is unread
[ "${n:-0}" = "1" ] && ok "@me suppressed: 1 of 2 notes unread" || no "@me suppression wrong: got '${n:-0}', want 1"

# 3. the CLI reader
cli=$(bun "$HERE/cli.ts" notes --project "$ROOT" 2>/dev/null)
printf '%s' "$cli" | rg -q "the visible ask" && ok "cli notes shows the visible note" || no "cli notes lost the visible note"

# 4. sync must preserve a card that carries notes
bun "$HERE/cli.ts" sync --project "$ROOT" >/dev/null 2>&1
python3 -c "
import json,sys
d=json.load(open('$dir/notes.json'))
sys.exit(0 if d.get('$card',{}).get('notes') else 1)" \
  && ok "sync preserved notes[]" || no "sync dropped notes[]"

bun "$HERE/cli.ts" unregister "$slug" >/dev/null 2>&1
rm -rf "$ROOT" 2>/dev/null
echo "  ---- $pass passed, $fail failed"
[ "$fail" -eq 0 ]
