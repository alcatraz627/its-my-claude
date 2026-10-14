#!/usr/bin/env bash
# goal-gate-note-stop.sh — tells the owner when a goal needs a step only he can take.
#
# A goal like "production runs the latest main" can never be met by the agent
# while pushing to main waits on the owner's approval, and the goal checker then
# keeps the session bouncing (clanky-opus, 2026-10-14: 127 blocks). This checks
# the goal proposed in the last reply, or the one armed now, against the live
# push and deploy policy. It speaks to the owner only, as a systemMessage: the
# agent never sees it, so it cannot mistake the note for a goal or arm from it.
# Owner, 2026-10-14: "it is only to show me never for its own arming".
#
# Once per distinct goal text per session. Mute: touch ~/.claude/.no-goal-gate-note
set -uo pipefail
[ -f "$HOME/.claude/.no-goal-gate-note" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$tp" ] && [ -f "$tp" ] && [ -n "$cwd" ] || exit 0

. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || exit 0
# Judge the reply just sent (Stop input), not the lagging transcript tail.
last=$(hook_last_assistant_text "$input" "$tp" | rg -o '^\s*/goal .*' | tail -1 | sed 's/^[[:space:]]*\/goal //')
goal="$last"; kind="proposed"
if [ -z "$goal" ]; then
  goal=$(bash "$HOME/.claude/scripts/goal/goal.sh" harness --sid "$sid" 2>/dev/null | jq -r 'select(.armed == true) | .text // empty' 2>/dev/null)
  kind="armed"
fi
[ -n "$goal" ] || exit 0

STATE="/tmp/claude-goalgate-${sid:0:8}"
h=$(printf '%s' "$goal" | shasum | cut -c1-12)
[ "$(cat "$STATE" 2>/dev/null)" = "$h" ] && exit 0
printf '%s' "$h" > "$STATE"

lower=$(printf '%s' "$goal" | tr 'A-Z' 'a-z')
pol() { bash "$HOME/.claude/scripts/pol/pol.sh" get "$1" --cwd "$cwd" 2>/dev/null; }
notes=()

push_words='(^|[^a-z])(push|pushed|main|production|prod|merge|merged|ship|shipped|live)([^a-z]|$)'
if [[ "$lower" =~ $push_words ]]; then
  top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  repo="${top:-$cwd}"
  if [ -n "$top" ] && { [ -f "$top/.claude/require-user-commit" ] || rg -qF "${top/#$HOME/~}" "$HOME/.claude/protected-repos.list" 2>/dev/null || rg -qF "$top" "$HOME/.claude/protected-repos.list" 2>/dev/null; }; then
    notes+=("pushing $repo needs your approval on every push (protected repo)")
  else
    case "$(pol git.push_main)" in
      ask)   notes+=("pushing to main in $repo waits on your approval (git.push_main = ask); set it to allow in the menu bar if the agent may push") ;;
      block) notes+=("pushing to main in $repo is switched off (git.push_main = block)") ;;
    esac
  fi
fi
for d in vercel cloudflare render; do
  [[ "$lower" == *"$d"* ]] || continue
  case "$(pol "deploy.$d")" in
    ask)   notes+=("a $d deploy waits on your approval (deploy.$d = ask)") ;;
    block) notes+=("$d deploys are switched off (deploy.$d = block)") ;;
  esac
done
[ ${#notes[@]} -gt 0 ] || exit 0

joined=$(printf '%s; ' "${notes[@]}"); joined="${joined%; }"
msg="[goal-gate] The $kind goal needs a step only you can take: $joined. Until you lift it, the agent cannot finish this goal on its own."
jq -cn --arg m "$msg" '{systemMessage: $m}'
