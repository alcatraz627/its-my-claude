#!/usr/bin/env bash
# smoke.sh: open a terminal UI the way its owner will, and fail if the screen comes up empty.
#
# tui_smoke [--size COLSxROWS] [--keys "j j Enter"]... [--expect TEXT]... [--wait SECS] [--by-path] [--may-exit] -- COMMAND [ARGS...]
#
# It starts COMMAND in a real terminal of the given size (a detached tmux), waits, optionally
# presses keys (one --keys per step, each given time to settle), then reads the screen back. It prints what it read and exits 1 when the screen
# is blank, shows a startup error, closed by itself, or lacks an --expect text.
#
# COMMAND must be the name typed at a prompt, found through PATH. A tool that works from its
# source folder and breaks once installed is the failure this exists to catch, so a path is
# refused unless --by-path says the path really is how it is run.
#
# Run it bare for this help. Guide: ~/.claude/conventions/tui-handbook.md §5.
set -u

size=150x44 wait=2 by_path=0 may_exit=0
keys=()
expects=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --size) size="$2"; shift 2 ;;
    --keys) keys+=("$2"); shift 2 ;;
    --expect) expects+=("$2"); shift 2 ;;
    --wait) wait="$2"; shift 2 ;;
    --by-path) by_path=1; shift ;;
    --may-exit) may_exit=1; shift ;;
    --) shift; break ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) printf 'smoke: unknown option %s (the command goes after --)\n' "$1" >&2; exit 2 ;;
  esac
done
[ "$#" -ge 1 ] || { sed -n '2,15p' "$0"; exit 2; }

command -v tmux >/dev/null 2>&1 || { printf 'smoke: needs tmux (brew install tmux)\n' >&2; exit 2; }
case "$1" in
  */*) [ "$by_path" -eq 1 ] || { printf 'smoke: %s is a path. Run the tool by the name its owner types, or pass --by-path.\n' "$1" >&2; exit 2; } ;;
  *) command -v "$1" >/dev/null 2>&1 || { printf 'smoke: %s is not on PATH, so its owner cannot run it either.\n' "$1" >&2; exit 1; } ;;
esac

cols=${size%x*} rows=${size#*x}
sock="tui-smoke-$$"
quoted=""
for word in "$@"; do quoted="$quoted $(printf '%q' "$word")"; done
# The trailer keeps the terminal open after the command ends, so an early exit can be read and reported.
tmux -L "$sock" new-session -d -x "$cols" -y "$rows" "sh -c $(printf '%q' "$quoted; printf '\n[smoke: the command ended with status %s]\n' \$?; sleep 30")" || { printf 'smoke: could not open a terminal\n' >&2; exit 2; }
trap 'tmux -L "$sock" kill-server >/dev/null 2>&1' EXIT
sleep "$wait"
# Each --keys group is pressed, then the screen is given time to settle before the next group.
for group in ${keys[@]+"${keys[@]}"}; do
  # shellcheck disable=SC2086
  tmux -L "$sock" send-keys $group
  sleep "$wait"
done
screen=$(tmux -L "$sock" capture-pane -p)

printf '%s\n' "$screen"
printf -- '-- smoke: %s at %s --\n' "$*" "$size"

fail=0
# Letters and digits only: frame lines and spaces are what an empty screen is made of.
letters=$(printf '%s' "$screen" | tr -cd '[:alnum:]' | wc -c | tr -d ' ')
if [ "$letters" -lt 40 ]; then
  printf 'FAIL  the screen is blank: %s letters and digits on it\n' "$letters"; fail=1
fi
if printf '%s' "$screen" | grep -E -i -q "no such file or directory|command not found|can't open file|traceback \(most recent|permission denied|syntax error"; then
  printf 'FAIL  a startup error is on the screen\n'; fail=1
fi
if [ "$may_exit" -eq 0 ] && printf '%s' "$screen" | grep -q '\[smoke: the command ended'; then
  printf 'FAIL  the command ended by itself, so there is no screen to use\n'; fail=1
fi
for text in ${expects[@]+"${expects[@]}"}; do
  printf '%s' "$screen" | grep -F -q -- "$text" || { printf 'FAIL  the screen does not show: %s\n' "$text"; fail=1; }
done
[ "$fail" -eq 0 ] && printf 'PASS  %s letters and digits, no startup error\n' "$letters"
exit "$fail"
