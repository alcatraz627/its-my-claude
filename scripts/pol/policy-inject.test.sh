#!/usr/bin/env bash
# policy-inject.test.sh: the SessionStart policy explainer is silent on default
# policy and speaks (once per start, as before) only when a value differs.
# P=<path> points the suite at a mutated copy of pol.sh.
set -uo pipefail
REAL="$HOME"
P="${P:-$REAL/.claude/scripts/pol/pol.sh}"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

R=$(mktemp -d); cp "$REAL/.claude/policy/registry.json" "$R/registry.json"
printf '{"global":{},"projects":{}}' > "$R/policy.json"
inj(){ printf '{"session_id":"s","cwd":"/tmp"}' | env POL_ROOT="$R" bash "$P" inject | jq -r '.additionalContext // empty'; }

o=$(inj)
[ -z "$o" ] && ok "default policy: silent" || ko "default policy spoke: $o"
o=$(inj)
[ -z "$o" ] && ok "default policy: silent on the next session too" || ko "repeat spoke"

printf '{"global":{"model.codex":{"value":"block","at":"2026-10-15T00:00:00Z"}},"projects":{}}' > "$R/policy.json"
o=$(inj)
printf '%s' "$o" | rg -q "Non-default: model.codex=block" && ok "a non-default value is announced" || ko "non-default silent: $o"

printf '{"global":{"model.codex":{"value":"encourage","at":"2026-10-15T00:00:00Z"}},"projects":{}}' > "$R/policy.json"
o=$(inj)
printf '%s' "$o" | rg -q "Codex is encouraged" && ok "codex encouraged is announced" || ko "encourage silent"

printf '{"global":{},"projects":{}}' > "$R/policy.json"
o=$(inj)
[ -z "$o" ] && ok "back to defaults: silent again" || ko "still speaking after reset"

trash "$R" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
