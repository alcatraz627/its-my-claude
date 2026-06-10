#!/usr/bin/env bash
# Open a Ghostty window that resumes a Claude Code session — safely, from a
# scheduled (launchd) context.
#
# Why this wrapper exists: a launchd job runs with a bare PATH, and a login
# shell (`zsh -l -c`) does NOT source ~/.zshrc — which is the only place
# ~/.local/bin (the home of the `claude` binary) is added to PATH. A scheduled
# `claude --resume` launched the naive way therefore dies with
# "command not found: claude". This wrapper sources the path env, then runs
# claude by absolute path with permissions pre-skipped (an unattended window
# has nobody to answer a permission prompt) — so any cron can launch a resume
# by calling this one audited script instead of re-inventing the quoting.
#
# Usage:  launch-claude-resume.sh <session-uuid> [first-turn-prompt] [workdir]
# Set DRYRUN=1 to print the composed launch command instead of opening Ghostty.
set -uo pipefail

UUID="${1:?usage: launch-claude-resume.sh <session-uuid> [prompt] [workdir]}"
PROMPT="${2:-}"
WORKDIR="${3:-$HOME/.claude}"
CLAUDE="$HOME/.local/bin/claude"

# When run from a gcc-schedule job, $GCC_SCHED_META names a file the scheduler
# reads to classify the fire. `open` exits 0 the instant Ghostty appears, so a
# bare exit code can't tell "claude launched" from "claude was missing". We
# write the honest outcome here: a confirmed preflight failure, or `unknown`
# once we hand off (we can't see whether claude stays up past exec). No-ops when
# run by hand (variable unset).
write_meta() { [[ -n "${GCC_SCHED_META:-}" ]] && printf '%s\n' "$@" > "$GCC_SCHED_META"; return 0; }

if [[ ! -x "$CLAUDE" ]]; then
  write_meta "outcome=failed" "reason=claude_missing" "stage=preflight"
  echo "launch-claude-resume: claude not executable at $CLAUDE" >&2
  exit 1
fi
if ! { [[ -d /Applications/Ghostty.app ]] || [[ -d "$HOME/Applications/Ghostty.app" ]]; }; then
  write_meta "outcome=failed" "reason=ghostty_missing" "stage=preflight"
  echo "launch-claude-resume: Ghostty.app not found" >&2
  exit 1
fi

# The command the new window's login shell runs: put ~/.local/bin on PATH (the
# bit ~/.zshrc normally does, which a non-interactive login shell skips), then
# exec claude by absolute path. printf %q keeps every argument a single token
# when zsh re-parses the string.
inner=". \"\$HOME/.local/bin/env\" 2>/dev/null; cd $(printf %q "$WORKDIR") && exec $(printf %q "$CLAUDE") --allow-dangerously-skip-permissions --resume $(printf %q "$UUID")"
[[ -n "$PROMPT" ]] && inner+=" $(printf %q "$PROMPT")"

if [[ -n "${DRYRUN:-}" ]]; then
  printf 'open -na Ghostty.app --args -e zsh -lc %q\n' "$inner"
  exit 0
fi

# Preflight passed: the launch attempt is good, but past this `open` the
# scheduler is blind (claude may boot, crash, or be closed) — so `unknown`.
write_meta "outcome=unknown" "reason=post_handoff" "stage=handoff"
if open -na 'Ghostty.app' --args -e zsh -lc "$inner"; then
  exit 0
else
  write_meta "outcome=failed" "reason=open_failed" "stage=open"
  exit 1
fi
