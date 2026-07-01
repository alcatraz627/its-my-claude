#!/usr/bin/env bash
# tty.sh — honest interactivity probe + a bounded terminal read for std::claude::tui.
#
# Why this exists: `[ -r /dev/tty ]` LIES on macOS. When a tool runs with no
# controlling terminal (a launchd job, a sub-agent, `cmd </dev/null`), the path
# `/dev/tty` still stat-reads as present, so `[ -r /dev/tty ]` says "yes" and the
# following `read </dev/tty` then fails noisily or hangs. The only honest test is
# to actually open it. This module promotes `download`'s correct subshell probe and
# its bounded read, and retires the four weaker/absent variants.
#
# Sourced library. Functions return status; tui_read_tty assigns into a named var.
#
# Under `set -e`: GUARD the call — `if tui_have_tty; then …`, `tui_read_tty v ||
# v=default`. A bare `tui_read_tty v` that returns non-zero (no tty / EOF) aborts a
# set -e caller. That's standard bash for a non-zero return in an unguarded spot,
# not a bug in this lib — the lib returns status precisely so you can branch on it.

# tui_have_tty — return 0 iff /dev/tty is genuinely openable (not just present).
# Opens fd 3 in a throwaway subshell; if there is no controlling terminal the
# `exec` fails and the subshell exits non-zero. No output, no args.
tui_have_tty() {
  ( exec 3</dev/tty ) 2>/dev/null
}

# tui_read_tty [-t SECS] [-p PROMPT] VARNAME
# Read one line from the real terminal into VARNAME. The prompt is written to
# /dev/tty (never stdout), so a tool that pipes its data still keeps a clean
# stdout. Returns:
#   0  a line was read
#   1  no usable tty / timed out / EOF  → the caller takes its default (never hangs)
#   2  misuse (no VARNAME given)
# bash 3.2: `-t` is whole-seconds only; fractional timeouts are unreliable and refused.
tui_read_tty() {
  # Internal locals use obscure names + assign back via `printf -v`, so a caller
  # passing a VARNAME of `timeout`/`prompt`/`var` can't have its value silently
  # captured into one of our locals (the bug this avoids: rc=0 but the caller's
  # variable never changes).
  local __tui_to="" __tui_pr="" __tui_dst="" __tui_line=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -t) __tui_to="$2"; shift 2 ;;
      -p) __tui_pr="$2"; shift 2 ;;
      *)  __tui_dst="$1"; shift ;;
    esac
  done
  [ -n "$__tui_dst" ] || return 2
  # bash 3.2 has no sub-second read timeout; round a fractional value UP to 1s (a
  # real bounded wait) rather than truncating to 0 — `-t 0` is an instant poll.
  case "$__tui_to" in *.*) __tui_to="${__tui_to%%.*}"; [ "${__tui_to:-0}" = 0 ] && __tui_to=1 ;; esac
  tui_have_tty || return 1                                    # no tty → return now, don't block
  [ -n "$__tui_pr" ] && printf '%s' "$__tui_pr" > /dev/tty
  if [ -n "$__tui_to" ]; then
    IFS= read -r -t "$__tui_to" __tui_line < /dev/tty || return 1
  else
    IFS= read -r __tui_line < /dev/tty || return 1
  fi
  printf -v "$__tui_dst" '%s' "$__tui_line"                   # assign to the CALLER's var
}
