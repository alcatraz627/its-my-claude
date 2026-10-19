#!/usr/bin/env bash
# Tells a starting session which i-dream outcome checks are failing, so a dead
# stage shows within a day instead of after two weeks (it took 13 days in
# October 2026). Owner ruling review-maint-1019 D3: show them in the session
# start brief as well as on the widget.
#
# Runs as one injector inside sessionstart-inject.sh: reads the SessionStart
# payload on stdin (ignored), prints {"additionalContext": "..."} when any row
# of `i-dream verify` fails, nothing otherwise. Spoken once per change: the same
# set of failing rows is not repeated into every session. Always exits 0.
# Mute: touch ~/.claude/.no-idream-verify-inject

set -uo pipefail
[ -f "$HOME/.claude/.no-idream-verify-inject" ] && exit 0
cat >/dev/null 2>&1 || true
command -v jq >/dev/null 2>&1 || exit 0
BIN="${IDREAM_BIN:-$(command -v i-dream 2>/dev/null)}"
[ -n "$BIN" ] || exit 0

# verify exits 1 when a row fails and still prints the document.
doc=$("$BIN" verify --json 2>/dev/null)
fails=$(printf '%s' "$doc" | jq -r '[.checks[]? | select(.verdict == "fail") | "\(.row) (\(.detail))"] | join(" · ")' 2>/dev/null)
names=$(printf '%s' "$doc" | jq -r '[.checks[]? | select(.verdict == "fail") | .row] | join(",")' 2>/dev/null)

. "$HOME/.claude/scripts/hooks/inject-once.sh" 2>/dev/null || true
if command -v inject_once_changed >/dev/null 2>&1; then
  inject_once_changed idream-verify "$names" || exit 0
fi
[ -z "$fails" ] && exit 0

msg="[i-dream verify] Failing outcome rows: ${fails}. Spec: ~/Code/Claude/i-dream/docs/35-outcome-contract.md. A repair counts only when a real cycle turns its row green."
jq -cn --arg m "$msg" '{additionalContext: $m}'
exit 0
