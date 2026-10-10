#!/usr/bin/env bash
# guard-policy-store.sh — agents read the owner's policy; they never change it.
#
# The policy store is how the owner tells agents what they may do, so an agent
# that could edit it could grant itself anything. This hook refuses agent
# writes to ~/.claude/policy/policy.json (and its backups, lock and temp file)
# through Write, Edit or Bash, and refuses the mutating pol.sh verbs. pol.sh
# refuses those verbs from an agent shell too; this is the second layer, and
# the one that also covers a hand-rolled jq > policy.json.
#
# registry.json is deliberately NOT guarded: it declares which policies exist,
# the way code does, and changes to it go through commit review like code.
#
# The owner is never blocked: the menu bar panel and the owner's own terminal
# do not run through Claude Code hooks.
#
# Known limit, accepted: this reads the command line, so a script written
# elsewhere and then run can still edit the file from inside. The agent and the
# owner are the same Unix user, so no hook can close that; the same trust model
# guard-git-push.sh states for its approval sentinel. What this stops is the
# ordinary slip: a redirect, a Write, a jq > policy.json, a File Tools write.
#
# Runtime contract: PreToolUse on Write|Edit|MultiEdit|NotebookEdit|Bash and the
# File Tools MCP write verbs.
# Exit 2 with the reason on stderr to block; exit 0 otherwise. No mute file, on
# purpose: a mute the agent could create is the bypass this hook exists to close.
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
POLDIR="$HOME/.claude/policy"

STORE_RE='(\.claude/policy/(policy\.json|\.policy\.json|\.lock)|(\$HOME|~|'"$HOME"')/\.claude/policy/?([[:space:]"'"'"']|$))'
# A command run from inside ~/.claude can name the store relatively
# (policy/policy.json), and one run from the policy dir needs no directory at all.
case "$cwd" in
  "$POLDIR"|"$POLDIR"/*) STORE_RE="$STORE_RE"'|(^|[^[:alnum:]_.-])\.?/?(policy\.json|\.policy\.json|\.lock)([^[:alnum:]_.-]|$)|(^|[[:space:]])\.{1,2}/?([[:space:]]|$)';;
  "$HOME/.claude"|"$HOME/.claude"/*) STORE_RE="$STORE_RE"'|(^|[^[:alnum:]_])(\./)?policy/(policy\.json|\.policy\.json|\.lock)|(^|[[:space:]])(\./)?policy/([[:space:]]|$)';;
esac

block() {
  printf '⛔ The policy store is owner-set only. Agents may read it (pol.sh get|json|list) but never change it. If a policy is in your way, tell the owner which key and why; they flip it in the menu bar policy panel.\n' >&2
  exit 2
}

# Is this path the store (or its lock, temp file, backups)? Relative paths
# resolve against the call's cwd, "~" against HOME.
is_store_path() {
  local p="$1"
  [ -n "$p" ] || return 1
  case "$p" in "~"/*) p="$HOME/${p#\~/}";; /*) ;; *) p="${cwd:-$PWD}/$p";; esac
  # Collapse ./ and ../ without touching the filesystem.
  p=$(python3 -c 'import os,sys; print(os.path.normpath(sys.argv[1]))' "$p" 2>/dev/null || printf '%s' "$p")
  case "$p" in
    "$POLDIR"|"$POLDIR"/policy.json*|"$POLDIR"/.policy.json*|"$POLDIR"/.lock*) return 0;;
    # Any home's store, so a symlinked or differently spelled home still matches.
    */.claude/policy|*/.claude/policy/policy.json*|*/.claude/policy/.policy.json*|*/.claude/policy/.lock*) return 0;;
  esac
  return 1
}

case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
    is_store_path "$fp" && block
    exit 0;;
  mcp__file-tools__write_structured|mcp__file-tools__write_tabular|mcp__file-tools__convert|mcp__file-tools__http_download)
    # Every File Tools verb that writes a file names its target as path or dest.
    fp=$(printf '%s' "$input" | jq -r '.tool_input.path // .tool_input.dest // empty' 2>/dev/null)
    is_store_path "$fp" && block
    exit 0;;
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
    [ -n "$cmd" ] || exit 0
    # Fast exit for the common case: nothing here names pol.sh or the store.
    [[ "$cmd" =~ (pol\.sh|policy|\.lock) ]] || exit 0
    # Mutating pol.sh verbs, however pol.sh is spelled.
    if printf '%s' "$cmd" | grep -qE 'pol\.sh"?[[:space:]]+(set|snooze|unsnooze|clear)([[:space:]]|$)'; then
      # A sandboxed store (tests) is fine: POL_ROOT pointing anywhere but the real one.
      if printf '%s' "$cmd" | grep -qE 'POL_ROOT=' && ! printf '%s' "$cmd" | grep -qE 'POL_ROOT=("|'"'"')?('"$HOME"'|~|\$HOME)/\.claude/policy'; then
        exit 0
      fi
      block
    fi
    # Any write-shaped command that names the store file or the policy dir.
    if printf '%s' "$cmd" | grep -qE "$STORE_RE"; then
      if printf '%s' "$cmd" | grep -qE '(>|\btee\b|\bmv\b|\bcp\b|\brm\b|\btrash\b|\btouch\b|\bln\b|\bchmod\b|\btruncate\b|\bdd\b|\brsync\b|\binstall\b|sed[[:space:]]+-i|perl[[:space:]]+-[a-z]*i|\bpython[0-9.]*\b|\bnode\b|\bsponge\b|\bmkdir\b|\brmdir\b)'; then
        block
      fi
    fi
    exit 0;;
esac
exit 0
