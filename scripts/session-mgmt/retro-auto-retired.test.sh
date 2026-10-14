#!/usr/bin/env bash
# The automatic retro-dump path stays retired (owner ruling 2026-10-13: no just-in-case dumps).
# Read-only: checks the live tree, writes nothing. Override ROOT to point at a copy.
set -uo pipefail
ROOT="${ROOT:-$HOME/.claude}"
pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }

TASKS="$ROOT/scripts/hook-orchestrator/SessionStart.tasks"
if rg -v '^\s*#' "$TASKS" | rg -q "40-retro-checkpoint-queue"; then bad "SessionStart.tasks still runs the retro queue hook"
else ok "SessionStart.tasks does not run the retro queue hook"; fi

if [ -e "$ROOT/scripts/session-mgmt/40-retro-checkpoint-queue.sh" ]; then bad "queue hook is still live in session-mgmt/"
else ok "queue hook is not live in session-mgmt/"; fi
[ -f "$ROOT/scripts/session-mgmt/retired/40-retro-checkpoint-queue.sh" ] && ok "queue hook kept under session-mgmt/retired/" || bad "queue hook missing from retired/"

if [ -e "$ROOT/scripts/startup/tasks/30-retro-checkpoint-flush.sh" ]; then bad "login flush task is still live in startup/tasks/"
else ok "login flush task is not live in startup/tasks/"; fi
[ -f "$ROOT/scripts/startup/tasks/retired/30-retro-checkpoint-flush.sh" ] && ok "flush task kept under startup/tasks/retired/" || bad "flush task missing from retired/"

if rg -q "retro-checkpoint-(queue|flush)" "$ROOT/settings.json"; then bad "settings.json still registers a retro checkpoint hook"
else ok "settings.json registers no retro checkpoint hook"; fi

if rg -q "AUTO path" "$ROOT/skills/retro-dump/SKILL.md"; then bad "retro-dump SKILL.md still advertises the AUTO path"
else ok "retro-dump SKILL.md does not advertise an AUTO path"; fi

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
