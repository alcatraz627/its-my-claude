#!/usr/bin/env bash
# Tests that the hook audit says UNMEASURED, not a verdict, when a hook has no heed
# rows: the weekly pulse note from extract-events.sh and the heed column of
# hook-health.sh. extract-events.sh writes next to itself, so it runs from a copy.
set -uo pipefail
DOM="$(cd "$(dirname "$0")" && pwd)"
HEALTH="${HOOK_HEALTH_SH:-$HOME/.claude/scripts/ledger/hook-health.sh}"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

NOW=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
mkdir -p "$T/hooks" "$T/dom"
cp -f "$DOM/extract-events.sh" "$T/dom/extract-events.sh"
printf '%s\n' \
  "{\"id\":\"w1\",\"ts\":\"$NOW\",\"kind\":\"warn\",\"hook_id\":\"quiet-hook\",\"fired\":1,\"heeded\":\"unknown\"}" \
  "{\"id\":\"w2\",\"ts\":\"$NOW\",\"kind\":\"warn\",\"hook_id\":\"tracked-hook\",\"fired\":1,\"heeded\":\"unknown\"}" \
  "{\"id\":\"h1\",\"ts\":\"$NOW\",\"kind\":\"heed\",\"hook_id\":\"tracked-hook\",\"heeded\":\"true\",\"ref\":\"tracked-hook:abc\"}" \
  > "$T/hooks/warn-events.jsonl"
: > "$T/hooks/feedback.jsonl"

HOOKS_FEEDBACK_HOOKS_DIR="$T/hooks" bash "$T/dom/extract-events.sh" >/dev/null 2>&1
quiet=$(jq -r 'select(.slug=="quiet-hook") | .note' "$T/dom/events.jsonl")
tracked=$(jq -r 'select(.slug=="tracked-hook") | .note' "$T/dom/events.jsonl")
case "$quiet" in *"heed UNMEASURED"*) ok "pulse note for a hook with no heed rows says UNMEASURED" ;; *) bad "pulse note for a hook with no heed rows says UNMEASURED: $quiet" ;; esac
case "$quiet" in *"0/0"*) bad "pulse note must not print 0/0" ;; *) ok "pulse note does not print 0/0" ;; esac
case "$tracked" in *"heeded 1/1 of tracked"*) ok "pulse note for a tracked hook keeps the ratio" ;; *) bad "pulse note for a tracked hook keeps the ratio: $tracked" ;; esac

table=$(HOOK_HEALTH_WARN="$T/hooks/warn-events.jsonl" HOOK_HEALTH_MUTE_ROOT="$T" bash "$HEALTH" 2>&1)
printf '%s\n' "$table" | rg -q '^quiet-hook .*UNMEASURED' && ok "hook-health heed column says UNMEASURED for a hook with no heed rows" || bad "hook-health heed column says UNMEASURED for a hook with no heed rows"
printf '%s\n' "$table" | rg -q '^tracked-hook .* 1/1 ' && ok "hook-health keeps the ratio for a tracked hook" || bad "hook-health keeps the ratio for a tracked hook"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
