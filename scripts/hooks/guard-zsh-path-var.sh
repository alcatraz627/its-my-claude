#!/usr/bin/env bash
# guard-zsh-path-var.sh — PreToolUse[Bash], SYNCHRONOUS.
#
# Stops the single most expensive silent footgun in this account's shell history.
# Inline Bash-tool commands run zsh, and zsh binds the scalar $PATH to an array
# named $path. So `while read path` or `for path in …` overwrites PATH with a
# filename, and every command after it in that same call dies with
# "(eval):3: command not found: sed". It reads like a broken machine rather than
# a naming collision, and the blast radius is one Bash call, so the next call
# looks healthy and the bug seems intermittent.
#
# Measured 2026-08-11: sed, tr and basename carry ~175 combined "command not
# found" hits across the transcript corpus despite all three being installed;
# sampled cases trace here. Verified live: `printf 'a/b/c\n' | while read path;
# do echo "$PATH"; done` prints a/b/c.
#
# Why this BLOCKS rather than nudges, given hook-design.md reserves blocking for
# irreversible actions: the asymmetry is unusual. A false block costs one rename
# (path → p), which is harmless in every context. A miss costs a cascade of
# misleading not-found errors, and worse, can hand the agent empty output that
# reads like a real "no results" answer. Wrong-pass far exceeds wrong-stop.
#
# Precision comes from blanking quoted spans BEFORE matching, so another
# language's `for path in` (python, awk, a jq filter) is invisible here, and from
# skipping heredocs, where the text being written is usually a #!/bin/bash script
# in which `path` is perfectly safe.
#
# Mute: ZSH_PATH_GUARD_OFF=1 (this process) · touch ~/.claude/.no-zsh-path-guard
# (MACHINE-WIDE, every concurrent and future session, until removed).

set -euo pipefail
[ -n "${ZSH_PATH_GUARD_OFF:-}" ] && exit 0
[ -f "$HOME/.claude/.no-zsh-path-guard" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool_name" = "Bash" ] || exit 0
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$command" ] || exit 0

# A heredoc is usually authoring a script that will run under its own shebang,
# where `path` is safe. Under-firing is the correct direction for a block.
case "$command" in *'<<'*) exit 0 ;; esac

# Quoted spans are data, not shell syntax. Blanking them first is what keeps
# `python3 -c "for path in xs"` and `rg 'path=[^&]*'` from ever reaching a match.
blank_quotes() { printf '%s' "$1" | sed "s/'[^']*'/''/g; s/\"[^\"]*\"/\"\"/g"; }
scan=$(blank_quotes "$command")

hit=""
while IFS= read -r seg; do
  s="${seg#"${seg%%[![:space:]]*}"}"                       # ltrim
  # Peel the loop/conditional keywords that can lead a segment, so the shapes
  # below only have to describe the statement itself.
  while [[ "$s" =~ ^(while|until|do|then|else|if|elif)[[:space:]]+(.*)$ ]]; do
    s="${BASH_REMATCH[2]}"
  done

  # for path in …
  if [[ "$s" =~ ^for[[:space:]]+path([[:space:]]|$) ]]; then
    hit="for path in …"; break
  fi
  # read [-r] [-d x] … path …   (path anywhere in the variable list)
  if [[ "$s" =~ ^read([[:space:]]+-[^[:space:]]+)*[[:space:]]+(.*)$ ]]; then
    vars=" ${BASH_REMATCH[2]} "
    if [[ "$vars" == *" path "* ]]; then hit="read … path"; break; fi
  fi
  # path=… , export/local/declare/typeset path=…
  if [[ "$s" =~ ^(export|local|declare|typeset)?[[:space:]]*path= ]]; then
    hit="path=…"; break
  fi
done < <(printf '%s\n' "$scan" | tr ';|&' '\n')

[ -n "$hit" ] || exit 0

reason="⚡ \`path\` is bound to \$PATH in zsh, and this Bash tool runs zsh.

Detected: ${hit}

Assigning to \`path\` overwrites your PATH with that value. Every command later in
THIS call then fails with \"(eval):N: command not found: sed\" — which looks like a
broken machine, not a naming collision. The next Bash call is unaffected, so the
bug reads as intermittent.

Blocked command:
  ${command}

Fix: rename the variable. \`p\`, \`f\`, \`file\`, \`dir\`, \`line\`, \`item\` and \`target\` are
all safe. Nothing else about the command needs to change.

  while read p; do … done          for f in …; do … done

Note: \`status\`, \`history\`, \`modules\`, \`functions\`, \`commands\`, \`aliases\` and
\`options\` are reserved in zsh too, but they fail loudly, so they need no guard.

Mute: ZSH_PATH_GUARD_OFF=1 (this process) · touch ~/.claude/.no-zsh-path-guard (machine-wide)"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-zsh-path-var --action block --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
