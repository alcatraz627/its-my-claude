#!/usr/bin/env bash
# sessionstart-inject.sh — the synchronous SessionStart injection lane.
#
# Context-injecting hooks must be SYNCHRONOUS (their whole purpose is stdout that
# Claude Code reads into the session) and must speak SessionStart's schema. The
# individual injectors below were registered inside the async hook-orchestrator,
# whose run.sh sends every task's stdout to /dev/null AND which is itself marked
# async — so their injections were silently dropped (dream insights, pending
# proposals, the post-crash /catchup hint, health/settings warnings all went
# nowhere). On top of that they emit the legacy top-level {"additionalContext"}
# shape, not SessionStart's {"hookSpecificOutput":{...}}.
#
# This one synchronous hook fixes both at once: it runs each injector with the
# real SessionStart payload, extracts its additionalContext value (accepting
# either schema), merges them, and emits ONE correctly-shaped SessionStart object.
# Side-effect-only SessionStart tasks stay in the async orchestrator where they
# belong.
#
# Runtime contract: a DIRECT (non-async) SessionStart hook in settings.json.
# Reads the payload on stdin, prints one {hookSpecificOutput} object when any
# injector produced context, nothing otherwise. Always exits 0.
# Mute the whole lane: touch ~/.claude/.no-sessionstart-inject

set -uo pipefail
[ -f "$HOME/.claude/.no-sessionstart-inject" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || echo '{}')

# The injectors, in display order. Each is a script that reads the SessionStart
# payload on stdin and prints {additionalContext|hookSpecificOutput} or nothing.
INJECTORS=(
  "$HOME/.claude/scripts/dream/dream-insights.sh"
  "$HOME/.claude/scripts/pending-proposals.sh"
  "$HOME/.claude/scripts/dream/dream-metrics-context.sh"
  "$HOME/.claude/scripts/session-mgmt/detect-stale-session.sh"
  "$HOME/.claude/scripts/health-check.sh"
  "$HOME/.claude/scripts/validate-settings-hooks.sh"
  "$HOME/.claude/scripts/hooks/backlog-surface.sh"
)

# Per-injector cap so one slow/hung script can't freeze session start. Use
# timeout/gtimeout if available; otherwise run bare (these are all sub-second).
runner() {
  if command -v timeout >/dev/null 2>&1; then timeout 8 bash "$1"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout 8 bash "$1"
  else bash "$1"; fi
}

TMP=$(mktemp -d 2>/dev/null) || exit 0
pids=()
i=0
for inj in "${INJECTORS[@]}"; do
  [ -f "$inj" ] || { i=$((i + 1)); continue; }
  ( printf '%s' "$INPUT" | runner "$inj" > "$TMP/$i.out" 2>/dev/null ) &
  pids+=($!)
  i=$((i + 1))
done
for p in "${pids[@]}"; do wait "$p" 2>/dev/null; done

# Merge each injector's additionalContext (accept either schema), in order.
merged=""
fired=0
j=0
while [ "$j" -lt "$i" ]; do
  f="$TMP/$j.out"
  j=$((j + 1))
  [ -s "$f" ] || continue
  ctx=$(jq -r '(.additionalContext // .hookSpecificOutput.additionalContext // empty)' "$f" 2>/dev/null)
  [ -z "$ctx" ] && continue
  if [ -z "$merged" ]; then merged="$ctx"; else merged="$merged"$'\n\n---\n\n'"$ctx"; fi
  fired=$((fired + 1))
done

rm -rf "$TMP" 2>/dev/null || true
[ -z "$merged" ] && exit 0

# Record start-time injection cost to the plug-events ledger (FIRED side).
sid=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
bash "$HOME/.claude/scripts/ledger/plug-log.sh" --plug sessionstart-lane --lifecycle start --outcome injected --chars "${#merged}" --session "$sid" --tags "injectors:$fired" >/dev/null 2>&1 || true

jq -nc --arg c "$merged" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
exit 0
