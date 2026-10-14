#!/usr/bin/env bash
# Suite for guard-duplicate-symbol.sh: a real duplicate of a long exported name
# still blocks, while short names, test names, private names and a match in a
# different top-level package do not. The name set mirrors the 43 blocks seen in
# 14 days of transcripts (D33 audit, 2026-10-15): expect, check, classify, _post,
# _request, test_unknown_job_is_404, compute_output_completeness and the like.
# GUARD_UNDER_TEST points the suite at a mutated copy in scripts/hooks/.
set -uo pipefail
HOOK="${GUARD_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/guard-duplicate-symbol.sh}"
REAL_HOOKS="$(cd "$(dirname "$0")" && pwd)"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

# Sandbox HOME: hook-common, warn-log and the snooze store resolve under it.
T=$(mktemp -d)
mkdir -p "$T/.claude/scripts"
ln -s "$REAL_HOOKS" "$T/.claude/scripts/hooks"
P="$T/proj"
mkdir -p "$P/backend" "$P/tests" "$P/tools"
git init -q "$P"

# Existing definitions in the backend package
cat > "$P/backend/existing.py" <<'EOF'
def compute_output_completeness(job):
    return 1

class ScraperAPIProvider:
    pass

def _stored_metadata(row):
    return row

def classify(x):
    return x

def check(x):
    return x

def compute_stat(x):
    return x

def compute_sta(x):
    return x

def test_unknown_job_is_404():
    pass
EOF
cat > "$P/tools/helper.py" <<'EOF'
def render_dashboard_summary(x):
    return x
EOF
cat > "$P/backend/api.ts" <<'EOF'
export function computeOutputCompleteness(job: number) { return job }
EOF

fire() { # fire <relative file> <content>
  jq -nc --arg f "$P/$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$f, content:$c}}' \
    | HOME="$T" bash "$HOOK" 2>/dev/null
}
blocked() { [ -n "$(fire "$1" "$2")" ] && ok "BLOCKED: $3" || bad "not blocked: $3"; }
allowed() { [ -z "$(fire "$1" "$2")" ] && ok "allow: $3" || bad "blocked (should pass): $3"; }

# A real duplicate of a long exported name still blocks
blocked backend/new.py $'def compute_output_completeness(job):\n    return 2\n' "long function name, same package"
blocked backend/new.py $'class ScraperAPIProvider:\n    pass\n' "long class name, same package"
blocked backend/new.ts $'export function computeOutputCompleteness(job: number) { return 1 }\n' "long exported TS function, same package"
blocked backend/new.py $'def compute_stat(x):\n    return 2\n' "boundary: 12 characters blocks"

# The noise the audit measured
allowed backend/new.py $'def classify(x):\n    return 2\n' "short name: classify"
allowed backend/new.py $'def check(x):\n    return 2\n' "short name: check"
allowed backend/new.py $'def compute_sta(x):\n    return 2\n' "boundary: 11 characters passes"
allowed backend/test_new.py $'def test_unknown_job_is_404():\n    pass\n' "test name"
allowed backend/new.py $'def _stored_metadata(row):\n    return 2\n' "private name"
allowed tools/new.py $'def compute_output_completeness(job):\n    return 3\n' "same name in a different top-level package"

# And a long name that exists nowhere is plainly fine
allowed backend/new.py $'def brand_new_long_function_name(x):\n    return x\n' "name defined nowhere"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
