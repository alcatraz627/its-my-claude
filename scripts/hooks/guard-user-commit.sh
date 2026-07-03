#!/usr/bin/env bash
# guard-user-commit.sh — HARD commit gate for protected repos (PreToolUse:Bash).
#
# In designated repos, `git commit` is the USER's action, never the agent's. This
# hook makes any agent-run `git commit` in a protected repo error unconditionally,
# telling the agent to show the user the staged files + a proposed message and ask
# THEM to commit. Born from the observation (2026-07-03) that advisory rules bind
# unevenly across models — the fix is a gate the model cannot talk itself past.
#
# DELIBERATE DEVIATION: this gate has NO mute file. Every other hook offers
# `touch ~/.claude/.no-*-gate`; a self-liftable mute is exactly the bypass this
# gate exists to close (tmp-jail precedent: off ONLY by the user). To lift
# protection the USER edits ~/.claude/protected-repos.list or removes the repo's
# tracked .claude/require-user-commit marker.
#
# A repo is protected when EITHER:
#   - its git-common-dir matches an entry in ~/.claude/protected-repos.list
#     (entries are repo paths; matching by common-dir means every WORKTREE of a
#     listed repo is covered automatically), OR
#   - the worktree's toplevel contains .claude/require-user-commit (a tracked
#     marker file — committed once, shared by all worktrees via git).
#
# Known over-block surface (accepted; the gate is meant to be hard): any Bash
# command string in a protected repo that contains a git...commit shape blocks,
# including strings that merely mention it. Staging (git add), diffing, status,
# push of existing commits are all untouched — only commit creation is gated.
set -uo pipefail

LIST="$HOME/.claude/protected-repos.list"

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# git <flags> commit — as a subcommand, tolerating -C/-c/long flags before it.
GIT_COMMIT_RE='(^|[;&|[:space:](])git([[:space:]]+-C[[:space:]]+[^[:space:]]+|[[:space:]]+-c[[:space:]]+[^[:space:]]+|[[:space:]]+--[[:alnum:]-]+(=[^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$|")'
printf '%s' "$cmd" | grep -qE "$GIT_COMMIT_RE" || exit 0

# ── Resolve the repo the commit would land in ────────────────────────────────
# Precedence: git -C <path> on the commit segment > last `cd <path>` before it
# in the same command string > the tool call's cwd.
expand_tilde() { case "$1" in "~"|"~/"*) printf '%s%s' "$HOME" "${1#\~}";; *) printf '%s' "$1";; esac; }

target="$cwd"
seg_cd=""
while IFS= read -r seg; do
  if printf '%s' "$seg" | grep -qE "$GIT_COMMIT_RE"; then
    c_opt=$(printf '%s' "$seg" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+).*/\1/p' | head -1)
    if [ -n "$c_opt" ]; then target=$(expand_tilde "$c_opt")
    elif [ -n "$seg_cd" ]; then target="$seg_cd"; fi
    break
  fi
  cd_opt=$(printf '%s' "$seg" | sed -nE 's/^[[:space:]]*cd[[:space:]]+([^[:space:]]+).*/\1/p' | head -1)
  [ -n "$cd_opt" ] && seg_cd=$(expand_tilde "$cd_opt")
done <<EOF
$(printf '%s' "$cmd" | tr ';\n' '\n\n' | sed -E 's/&&|\|\|/\n/g')
EOF
[ -n "$target" ] || exit 0

# Canonical git-common-dir of a path ("" if not a repo).
common_dir_of() {
  local p="$1" cdir
  cdir=$(git -C "$p" rev-parse --git-common-dir 2>/dev/null) || return 0
  [ -n "$cdir" ] || return 0
  case "$cdir" in
    /*) (cd "$cdir" 2>/dev/null && pwd -P) ;;
    *)  (cd "$p" 2>/dev/null && cd "$cdir" 2>/dev/null && pwd -P) ;;
  esac
}

tgt_common=$(common_dir_of "$target")
[ -n "$tgt_common" ] || exit 0   # not a git repo → nothing to protect

protected=0; why=""
# 1) central list (repo paths, matched by resolved common-dir → covers worktrees)
if [ -f "$LIST" ]; then
  while IFS= read -r entry; do
    entry="${entry%%#*}"; entry=$(printf '%s' "$entry" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    [ -n "$entry" ] || continue
    e_common=$(common_dir_of "$(expand_tilde "$entry")")
    if [ -n "$e_common" ] && [ "$e_common" = "$tgt_common" ]; then
      protected=1; why="listed in ~/.claude/protected-repos.list ($entry)"; break
    fi
  done < "$LIST"
fi
# 2) tracked marker in the worktree toplevel
if [ "$protected" = 0 ]; then
  top=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$top" ] && [ -f "$top/.claude/require-user-commit" ]; then
    protected=1; why="marker file $top/.claude/require-user-commit"
  fi
fi
[ "$protected" = 1 ] || exit 0

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook commit-gate --action block --heeded unknown >/dev/null 2>&1 || true

reason="⛔ COMMIT GATE: this repository requires USER-run commits ($why).

Do NOT commit here, and do NOT work around this (no --no-verify, no alternate
paths, no editing the protection config — it is user-owned by design).

Instead:
  1. Show the user the staged/changed files: git status --short (and git diff --stat)
  2. Show them your proposed commit message
  3. Ask them to run the commit themselves, e.g.:  ! git commit -m \"<your message>\"

If you believe this repo should not be protected, ASK THE USER to remove it from
~/.claude/protected-repos.list (or delete .claude/require-user-commit). That
decision is theirs, not yours."

jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
