#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Feeds real shapes of command to the Ghostty guard and checks what it blocks.
# Run: bash ~/.claude/scripts/hooks/guard-ghostty.test.sh
GUARD="$(cd "$(dirname "$0")" && pwd)/guard-ghostty.sh"
fails=0; total=0
# -a: Ghostty is an ancestor of this shell, and pgrep hides ancestors by default.
GHOSTTY_PID=$(pgrep -a -x ghostty | head -1)

run() { jq -cn --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}' | "$GUARD"; }

blocks() {
  total=$((total + 1))
  if run "$1" | rg -q '"permissionDecision":"deny"'; then echo "PASS blocks: $1"
  else echo "FAIL should block: $1"; fails=$((fails + 1)); fi
}
passes() {
  total=$((total + 1))
  if run "$1" | rg -q 'deny'; then echo "FAIL should pass: $1"; fails=$((fails + 1))
  else echo "PASS allows: $1"; fi
}

blocks "open -na Ghostty.app --args -e zsh -lc 'claude'"
blocks "open -n -a Ghostty"
blocks "open -a Ghostty.app -n"
blocks "open --new -a Ghostty"
blocks "cd /tmp && open -na 'Ghostty.app' --args --working-directory=/tmp"
blocks "ghostty -e claude hello"
blocks "/Applications/Ghostty.app/Contents/MacOS/ghostty -e claude"
blocks "pkill -x ghostty"
blocks "killall Ghostty"
blocks "kill \$(pgrep ghostty)"
blocks "osascript -e 'tell application \"Ghostty\" to quit'"
blocks "osascript -e 'tell application \"Ghostty\" to close front window'"
[ -n "$GHOSTTY_PID" ] && blocks "kill $GHOSTTY_PID"

passes "open -a Ghostty"
passes "ghostty +version"
passes "/Applications/Ghostty.app/Contents/MacOS/ghostty +list-fonts"
passes "echo 'open -na Ghostty.app is banned'"
passes "git commit -m 'stop using open -na Ghostty'"
passes "rg ghostty /tmp/notes.md"
passes "~/.claude/scripts/ghostty/ghostty-open --cwd /tmp -- 'claude --resume x'"
passes "kill 99999"
passes "osascript -e 'tell application \"Ghostty\" to activate'"

echo; echo "$((total - fails))/$total passed"
[ "$fails" = 0 ]
