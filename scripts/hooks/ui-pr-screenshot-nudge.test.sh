#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Checks when the UI pull request nudge speaks (a pull request whose diff touches UI
# files) and when it stays quiet, and that its wording lets the agent skip the screenshot.
# Run: bash ~/.claude/scripts/hooks/ui-pr-screenshot-nudge.test.sh
set -uo pipefail

HOOK="${HOOK_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/ui-pr-screenshot-nudge.sh}"
T=$(mktemp -d)
export HOME_REAL="$HOME"
FAKE="$T/home"
mkdir -p "$FAKE/.claude"
pass=0 fail=0

git_in() { git -C "$1" -c user.email=t@t -c user.name=t "${@:2}" >/dev/null 2>&1; }
# repo NAME FILE...: a repo on main with one commit, then a branch that adds each FILE
repo() {
  local d="$T/$1"; shift
  mkdir -p "$d"
  git -C "$d" init -q -b main
  echo base > "$d/README.md"
  git_in "$d" add -A; git_in "$d" commit -m base
  git_in "$d" checkout -b feature
  for f in "$@"; do mkdir -p "$d/$(dirname "$f")"; echo x > "$d/$f"; done
  git_in "$d" add -A; git_in "$d" commit -m change
  echo "$d"
}
UI=$(repo ui src/pages/home.html)
DOCS=$(repo docs notes/readme.md)
TESTS=$(repo tests src/pages/home.test.tsx)
COMP=$(repo comp src/components/list.js)
UTIL=$(repo util src/lib/util.js)

# run SID DIR COMMAND [EXTRA_ENV...]: the hook's output for a Bash call
run() {
  local sid=$1 dir=$2 cmd=$3; shift 3
  jq -cn --arg s "$sid" --arg d "$dir" --arg c "$cmd" '{session_id:$s, cwd:$d, tool_name:"Bash", tool_input:{command:$c}}' \
    | env HOME="$FAKE" "$@" bash "$HOOK"
}
speaks() {  # $1 name, $2 output
  if [[ "$2" == *additionalContext* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1: got '$2'"; fi
}
quiet() {  # $1 name, $2 output
  if [ -z "$2" ]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1: got '$2'"; fi
}
has() {  # $1 name, $2 output, $3 needle
  if [[ "$2" == *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1: '$3' not in '$2'"; fi
}
lacks() {  # $1 name, $2 output (must be non-empty), $3 needle
  if [ -n "$2" ] && [[ "$2" != *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1: got '$2'"; fi
}

out=$(run c1 "$UI" 'gh pr create --fill')
speaks "gh pr create on a UI diff gets the nudge" "$out"
has "it tells the agent to skip when a screenshot is not worth it" "$out" "If you do not think a screenshot is worth it"
has "or when one cannot be got easily" "$out" "or you cannot get one easily, skip it"
has "and says it is a suggestion" "$out" "a suggestion, not a requirement"
lacks "it never blocks" "$out" "permissionDecision"
quiet "only once per branch in a session" "$(run c1 "$UI" 'gh pr create --fill')"
speaks "gh pr edit in another session gets it too" "$(run c2 "$UI" 'gh pr edit --title "New title"')"
speaks "gh with -R before the subcommand still counts" "$(run c3 "$UI" 'gh -R versable-git/demo pr create --fill')"
speaks "a command later in a chain counts" "$(run c4 "$UI" 'git push && gh pr create --fill')"
speaks "--base main resolves the base" "$(run c5 "$UI" 'gh pr create --base main --fill')"

quiet "a docs-only diff stays quiet" "$(run d1 "$DOCS" 'gh pr create --fill')"
quiet "a test file under pages stays quiet" "$(run d2 "$TESTS" 'gh pr create --fill')"
speaks "plain JS in a components folder counts" "$(run d3 "$COMP" 'gh pr create --fill')"
quiet "plain JS elsewhere does not" "$(run d4 "$UTIL" 'gh pr create --fill')"

quiet "a command that is not a pull request stays quiet" "$(run e1 "$UI" 'git status')"
quiet "gh pr view stays quiet" "$(run e2 "$UI" 'gh pr view 12')"
quiet "a quoted mention is not a command" "$(run e3 "$UI" 'git commit -m "wip; gh pr create later"')"
quiet "a single-quoted mention after a chain mark is not a command" "$(run e4 "$UI" "echo 'a && gh pr create'")"
quiet "a body that already has an image stays quiet" "$(run e5 "$UI" 'gh pr create --body "Before ![shot](https://x.test/a.png)"')"
quiet "a body that links an image file stays quiet" "$(run e6 "$UI" 'gh pr create --body "see https://x.test/shot.png"')"
printf 'Changes\n\n![home](https://x.test/home.png)\n' > "$T/body.md"
quiet "a body file with an image stays quiet" "$(run e7 "$UI" "gh pr create --body-file $T/body.md")"
printf 'Changes only\n' > "$T/plain.md"
speaks "a body file with no image does not silence it" "$(run e8 "$UI" "gh pr create --body-file $T/plain.md")"

# gh pr edit 12 names a pull request: ask GitHub for its files.
printf '#!/usr/bin/env bash\necho src/views/list.vue\n' > "$T/gh-ui"; chmod +x "$T/gh-ui"
printf '#!/usr/bin/env bash\necho docs/guide.md\n' > "$T/gh-docs"; chmod +x "$T/gh-docs"
speaks "gh pr edit 12 asks GitHub, and a UI file there speaks" "$(run f1 "$DOCS" 'gh pr edit 12 --body x' UI_PR_NUDGE_GH="$T/gh-ui")"
quiet "and a docs file there does not, whatever this checkout holds" "$(run f2 "$UI" 'gh pr edit 12 --body x' UI_PR_NUDGE_GH="$T/gh-docs")"
quiet "an unreadable gh stays quiet" "$(run f3 "$UI" 'gh pr edit 12 --body x' UI_PR_NUDGE_GH="$T/no-such-gh")"

quiet "no repo and no base stays quiet" "$(run g1 "$T" 'gh pr create --fill')"
quiet "bad input stays quiet" "$(printf 'not json' | env HOME="$FAKE" bash "$HOOK")"

touch "$FAKE/.claude/.no-ui-pr-screenshot-nudge"
quiet "the mute file silences it" "$(run h1 "$UI" 'gh pr create --fill')"
rm -f "$FAKE/.claude/.no-ui-pr-screenshot-nudge"
quiet "the one-shot off silences it" "$(run h2 "$UI" 'gh pr create --fill' UI_PR_SCREENSHOT_NUDGE_OFF=1)"
speaks "and it speaks again once the mute is gone" "$(run h3 "$UI" 'gh pr create --fill')"

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
