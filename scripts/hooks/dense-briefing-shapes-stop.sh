#!/usr/bin/env bash
# dense-briefing-shapes-stop.sh — Stop hook, DRY-RUN tier: the two dense-briefing
# shapes no detector covered (owner D4a, 2026-09-18; sweep S6).
#
# rules/dense-briefing-direct-answer.md names three shapes. Shape 1 (a title
# where the answer belongs) is prose-smell detector 8, warn-tier by ruling D2a.
# This hook covers the other two, which are mechanical in a way shape 1 is not:
#
#   shape 2 · the reply restates a file written this turn. A Write or Edit landed
#             a markdown file in this turn and the reply repeats two or more of
#             that file's headings. The owner can open the file; the reply owed
#             him the path and the one thing to decide.
#   shape 3 · a done-claim that skips the stated acceptance criteria. The user's
#             last message carried a criterion sentence (must / make sure / never /
#             don't / should / I want) and the reply claims done, fixed, verified
#             or shipped without any content word of that sentence.
#
# Dry-run: a WOULD-BLOCK systemMessage plus a warn-log line, two weeks of
# telemetry, then a promotion call. Real block only with DENSE_SHAPES_ENFORCE=1.
# Loop-safe: identical reply text never re-fires. Never fails the turn.
# Mute: DENSE_SHAPES_OFF=1 (process) · touch ~/.claude/.no-dense-shapes-gate (machine-wide).
set -uo pipefail
[ "${DENSE_SHAPES_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-dense-shapes-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty'); tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
[ -n "$sid" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"

verdict=$(python3 "$(cd "$(dirname "$0")" && pwd)/dense-briefing-shapes-stop.py" "$tp" 2>/dev/null)
[ -n "$verdict" ] || exit 0

h=$(printf '%s' "$verdict" | shasum | cut -c1-12)
STATE="/tmp/claude-dense-shapes-$sid8"; mkdir -p "$STATE"
[ -f "$STATE/$h" ] && exit 0; touch "$STATE/$h"

if [ "${DENSE_SHAPES_ENFORCE:-0}" = "1" ]; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook dense-briefing-shapes --action block --heeded unknown >/dev/null 2>&1 || true
  jq -cn --arg r "dense-briefing shape check (rules/dense-briefing-direct-answer.md): $verdict" '{decision:"block", reason:$r}'
else
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook dense-briefing-shapes --action soft --heeded unknown >/dev/null 2>&1 || true
  jq -cn --arg m "[dense-briefing-shapes WOULD-BLOCK · dry-run] $verdict (Enforce: DENSE_SHAPES_ENFORCE=1 · mute: touch ~/.claude/.no-dense-shapes-gate)" '{systemMessage: $m}'
fi
exit 0
