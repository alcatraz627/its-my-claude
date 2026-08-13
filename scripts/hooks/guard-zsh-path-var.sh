#!/usr/bin/env bash
# guard-zsh-path-var.sh — PreToolUse[Bash], SYNCHRONOUS, WARN tier.
#
# Inline Bash-tool commands run zsh, and zsh binds the scalar $PATH to an array
# named $path. So `while read path` or `for path in …` overwrites PATH with a
# filename, and every command after it in that same call dies with
# "(eval):3: command not found: sed". It reads like a broken machine rather than
# a naming collision, and the blast radius is one Bash call, so the next call
# looks healthy and the bug seems intermittent.
#
# Evidence, re-derived from the full transcript corpus 2026-08-13: TWO organic
# incidents in two months (2026-06-19, a `find | while read ts path` loop; and
# 2026-07-07, a `local path=` function). An earlier version of this header cited
# ~175 "hits", which counted matching strings rather than incidents and inflated
# the real figure roughly 90x. The string count is self-inflating, because this
# hook's own message contains the error text it counts.
#
# WARN, not block. It shipped as a block on 2026-08-11 arguing that a false fire
# "costs one rename, harmless in every context". That argument was wrong, and an
# adversarial review proved it: the first organic fire, one day later, blocked a
# legitimate `rg -n "path=\"/|path='/"` in a Versable session. That command never
# assigned anything, so there was no rename available; the agent's only outs were
# to contort a correct command or mute the guard machine-wide. A block whose only
# real-world fire is a false positive is worse than no guard, and two incidents in
# two months does not clear the cost-of-miss bar that features/hook-design.md
# reserves blocking for.
#
# Matching lives in zsh-path-scan.py, because this cannot be done correctly in
# sed. See that file's docstring for why.
#
# Mute: ZSH_PATH_GUARD_OFF=1 (this process) · touch ~/.claude/.no-zsh-path-guard
# (MACHINE-WIDE, every concurrent and future session, until removed).

set -uo pipefail
[ -n "${ZSH_PATH_GUARD_OFF:-}" ] && exit 0
[ -f "$HOME/.claude/.no-zsh-path-guard" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool_name" = "Bash" ] || exit 0
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$command" ] || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)

SCAN="$HOME/.claude/scripts/hooks/zsh-path-scan.py"
hit=$(printf '%s' "$command" | python3 "$SCAN" 2>/dev/null)
rc=$?
if [ "$rc" -ne 0 ]; then
  # Fail-open must not be silent: a missing or broken scanner makes the guard a
  # no-op, so record that once per day instead of never.
  marker="${TMPDIR:-/tmp}/zsh-path-guard-scanfail-$(date +%Y%m%d)"
  if [ ! -f "$marker" ]; then
    : > "$marker"
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-zsh-path-var --action muted \
      --detail "scanner failed rc=$rc; guard inactive" --heeded unknown >/dev/null 2>&1 || true
  fi
  exit 0
fi
[ -n "$hit" ] || exit 0

msg="[zsh-path] Detected ${hit}. In zsh, which is what this Bash tool runs, \`path\` is bound to \$PATH, so assigning to it overwrites your PATH with that value. Every later command in THIS call will fail with \"command not found\" against tools that are installed; the next Bash call is unaffected, so it reads as intermittent. Rename the variable: p, f, file, dir, line, item and target are all safe, and nothing else needs to change. Reserved in zsh but harmless because they fail loudly: status, history, modules, functions, commands, aliases, options. Mute: ZSH_PATH_GUARD_OFF=1 (process) or touch ~/.claude/.no-zsh-path-guard (machine-wide)."

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-zsh-path-var --action nudge \
  --cwd "$cwd" --detail "$hit" --heeded unknown >/dev/null 2>&1 || true
jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}' 2>/dev/null || true
exit 0
