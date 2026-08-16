#!/usr/bin/env bash
# relpath-stop.sh — Stop hook: notice when the final message hands the user a
# deliverable by a path that will not resolve for them.
#
# Why. The agent holds a working directory; the reader does not. `assets/reports/
# 20260728-run-page-spec/spec.md` is a correct citation inside a checkpoint and an
# unresolvable one the moment it crosses into a reply, which is why this misses so
# reliably: the path was right where it was copied from. rules/communication.md
# § "Expand paths at the reader boundary" requires the first mention in a
# user-facing reply to start with / or ~. Recurrence 16 of
# file-referenced-without-full-path at the time this was built.
#
# WARN, NEVER BLOCK. The proposals behind this asked for a warn rung twice by
# name (prop-20260721-121503-50 "add a warn (not block) rung",
# prop-20260716-075008-a2 "warn once"). It is the right call on cost-of-false-fire
# grounds too: a miss costs the user one question, while a false block costs a
# whole turn on a hook whose subject (does this path read as a deliverable?) is a
# judgment a regex cannot make. features/hook-design.md reserves blocking for
# high cost-of-miss, and this is not that.
#
# Scope is deliberately narrow, and narrowness IS the FP tuning. Only paths under
# the three deliverable roots the proposal named are considered. A relative path
# to source code is a normal way to talk about a repo and must not fire.
#
# Exemptions, each for a stated reason:
#   fenced code            a block is quoted material, not a citation
#   file:line              a code reference, exempt by prop-20260721-121503-50
#   already absolute       the same path appears with / or ~ in the same message
#   command position       `cat docs/x.md` is an instruction to run, not a handoff
#
# Mute: touch ~/.claude/.no-relpath-gate (machine-wide until removed).

set -uo pipefail
[ -f "$HOME/.claude/.no-relpath-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0

HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8=$(hook_sid8 "$sid")

tail_json=$(tail -n 400 "$tp" 2>/dev/null) || exit 0
last_asst=$(printf '%s\n' "$tail_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -n 1)
[ -n "$last_asst" ] || exit 0
text=$(printf '%s' "$last_asst" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$text" ] || exit 0

# Strip fenced blocks. A path inside ``` ``` is quoted material or a command the
# user will paste from a known directory, not a handoff citation.
prose=$(printf '%s\n' "$text" | awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}')
[ -n "$prose" ] || exit 0

# The deliverable roots, from prop-20260716-075008-a2. Anything else relative is
# ordinary repo talk and is none of this hook's business.
ROOTS='\.claude/output|docs|assets'

# A relative mention: the root is NOT preceded by / ~ . or a word character, so
# /Users/x/docs/a.md, ~/docs/a.md and ./docs/a.md are all excluded by the guard.
#
# The two trailing lookaheads must be in this order and both are load-bearing.
# (?![A-Za-z0-9]) forces the extension to be maximal FIRST. Without it the engine
# backtracks: on docs/x/design.md:42 it happily matches extension "m", then finds
# "d" rather than ":4" and the file:line exemption silently does nothing. That
# shipped in the first cut and the suite caught it.
PAT='(?<![/~.[:alnum:]_-])('"$ROOTS"')/[A-Za-z0-9._/@-]+\.[A-Za-z0-9]+(?![A-Za-z0-9])(?!:[0-9])'

hits=$(printf '%s\n' "$prose" | rg -oP "$PAT" 2>/dev/null | sort -u)
[ -n "$hits" ] || hits=""

# Drop any hit whose absolute form is already present in the same message: the
# reader has been given a resolvable path, and a later shorthand is fine.
pending=""
while IFS= read -r h; do
  [ -n "$h" ] || continue
  if printf '%s\n' "$prose" | rg -qF "/$h" 2>/dev/null; then continue; fi
  # Command position: a runner word immediately before it means "run this".
  if printf '%s\n' "$prose" | rg -qP '\b(cat|bash|sh|python3?|node|open|less|rg|grep|vim|code|jq|Read|glow|bat)\s+`?'"$(printf '%s' "$h" | sed 's/[.[\*^$()+?{|]/\\&/g')" 2>/dev/null; then continue; fi
  pending="${pending}${h}
"
done <<EOF
$hits
EOF

MARK="/tmp/claude-relpath-${sid8}"

if [ -z "${pending//[[:space:]]/}" ]; then
  # Clean message. A lingering signature means the previous warning was acted on.
  if [ -f "$MARK" ]; then
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook relpath \
      --heed-of "relpath:$sid8" --heeded true >/dev/null 2>&1 || true
    rm -f "$MARK" 2>/dev/null || true
  fi
  exit 0
fi

# Loop-safe: an identical message does not get warned twice.
if ! hook_loop_check "$MARK" "$prose"; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook relpath \
    --heed-of "relpath:$sid8" --heeded false >/dev/null 2>&1 || true
  exit 0
fi

listed=$(printf '%s' "$pending" | rg -v '^\s*$' | head -4 | sed 's/^/  /')
msg="⚠ relative deliverable path — these will not resolve from the user's terminal, because they hold no working directory:

$listed

Expand each to an absolute path (/ or ~) on its FIRST mention. The usual cause is a copy out of a checkpoint, plan, or sub-agent report, where the relative form was correct. Mute: touch ~/.claude/.no-relpath-gate"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook relpath --action nudge \
  --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
exit 0
