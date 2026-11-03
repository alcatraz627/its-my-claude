#!/usr/bin/env bash
# Reminds an agent that a pull request which changes how a screen looks is easier to
# review with a picture of it. A suggestion and never a block, and it says up front that
# the agent may skip it: the owner wants a screenshot only when one is worth having and
# cheap to get (owner, 2026-11-03).
#
# PreToolUse on Bash. Fires on `gh pr create` and `gh pr edit` when the branch's diff
# touches UI files, once per session, agent, repo and branch. Stays quiet when the command
# already carries an image. Mute: touch ~/.claude/.no-ui-pr-screenshot-nudge
# One-shot skip: UI_PR_SCREENSHOT_NUDGE_OFF=1
# Test: bash ~/.claude/scripts/hooks/ui-pr-screenshot-nudge.test.sh
[ "${UI_PR_SCREENSHOT_NUDGE_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-ui-pr-screenshot-nudge" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

[ "$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)" = "Bash" ] || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# Look for the command only where a command starts, with quoted text blanked, so a commit
# message or a PR body that mentions `gh pr create` never fires it.
bare=$(printf '%s' "$cmd" | tr '\n' '\001' | sed -E "s/'[^']*'/''/g; s/\"([^\"\\\\]|\\\\.)*\"/\"\"/g" | tr '\001' ';')
printf '%s' "$bare" | rg -q '(^|[;&|(]\s*)(\S*/)?gh(\s+(-R|--repo)\s+\S+)?\s+pr\s+(create|edit)\b' 2>/dev/null || exit 0

# A command that already carries an image (markdown image, or a link to an image file, in
# the body or the body file) has nothing to be reminded of.
body_file=$(printf '%s' "$cmd" | rg -o -- '(--body-file|-F)[ =]\S+' 2>/dev/null | head -1 | sed -E 's/^(--body-file|-F)[ =]//')
carries_image() { rg -q '!\[[^]]*\]\(|https?://\S+\.(png|jpe?g|gif|webp|svg)\b' 2>/dev/null; }
printf '%s' "$cmd" | carries_image && exit 0
[ -n "$body_file" ] && [ -r "$body_file" ] && carries_image < "$body_file" && exit 0

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=$PWD

# The files the pull request changes. `gh pr edit 12` names its own pull request, so ask
# GitHub about that one; otherwise the checked-out branch against its base is the answer.
files=""
explicit=$(printf '%s' "$bare" | rg -o 'pr\s+edit\s+(https://\S+/pull/[0-9]+|[0-9]+)\b' 2>/dev/null | head -1 | awk '{print $3}')
if [ -n "$explicit" ]; then
  gh_bin="${UI_PR_NUDGE_GH:-gh}"
  command -v "$gh_bin" >/dev/null 2>&1 || exit 0
  if command -v timeout >/dev/null 2>&1; then
    files=$(cd "$cwd" && timeout 8 "$gh_bin" pr diff "$explicit" --name-only 2>/dev/null)
  else
    files=$(cd "$cwd" && "$gh_bin" pr diff "$explicit" --name-only 2>/dev/null)
  fi
else
  base=$(printf '%s' "$cmd" | rg -o -- '(--base|-B)[ =]\S+' 2>/dev/null | head -1 | sed -E 's/^(--base|-B)[ =]//')
  ref=""
  for cand in ${base:+"origin/$base"} ${base:+"$base"} "origin/HEAD" "origin/main" "origin/master" "main" "master"; do
    if git -C "$cwd" rev-parse --verify --quiet "$cand" >/dev/null 2>&1; then ref=$cand; break; fi
  done
  [ -n "$ref" ] || exit 0
  files=$(git -C "$cwd" diff --name-only "$ref"...HEAD 2>/dev/null)
fi
[ -n "$files" ] || exit 0

# What counts as a UI file matches ui-brief-nudge.sh: pages, styles and component files;
# plain JS only inside a folder that holds pages.
is_ui=""
while IFS= read -r f; do
  p="/$f"
  case "$p" in
    */node_modules/*|*/dist/*|*/build/*|*/.next/*|*/vendor/*|*/coverage/*|*.test.*|*.spec.*|*.min.*|*/tests/*|*/__tests__/*|*/fixtures/*|*/.claude/output/*|*/assets/reports/*|*/scratchpad/*) continue ;;
    *.html|*.htm|*.css|*.scss|*.jsx|*.tsx|*.vue|*.svelte) is_ui=1; break ;;
    */page/*.js|*/pages/*.js|*/public/*.js|*/static/*.js|*/views/*.js|*/components/*.js|*/ui/*.js) is_ui=1; break ;;
  esac
done <<EOF
$files
EOF
[ -n "$is_ui" ] || exit 0

agent=$(printf '%s' "$input" | jq -r '.agent_id // "main"' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || root=$cwd
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
marks="$HOME/.claude/state/ui-pr-screenshot-nudged"
key=$(printf '%s|%s|%s|%s|%s' "$sid" "$agent" "$root" "$branch" "$explicit" | shasum | cut -c1-16)
[ -f "$marks/$key" ] && exit 0
mkdir -p "$marks" 2>/dev/null
touch "$marks/$key" 2>/dev/null

msg="This pull request changes UI files. A screenshot of the changed screen in the description helps a reviewer, so add one if you already have it or can get it easily; the gh command cannot upload an image itself, so it has to be a link to one that is already hosted or committed. If you do not think a screenshot is worth it, or you cannot get one easily, skip it and open the pull request as it is: do not set up a browser or a stand-in server just for this. This is a suggestion, not a requirement."
jq -cn --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$c}}'
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook ui-pr-screenshot-nudge --action nudge --heeded unknown >/dev/null 2>&1 || true
exit 0
