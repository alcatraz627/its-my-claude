#!/usr/bin/env bash
# guard-git-push.sh — HARD push gate for main/master + protected repos (PreToolUse:Bash).
#
# Pushing to a shared branch is a fresh-approval action every single time — "one
# approval is not blanket." The problem this closes: a context compaction silently
# strips the "not yet approved to push" state while preserving task momentum, so a
# resumed session pushes to main believing it was cleared. Advisory rules don't
# survive that; a gate does. Sibling of guard-user-commit.sh (which gates commit
# creation — push was deliberately left untouched there; this fills that gap).
#
# WHAT IS GATED (any one):
#   - the push targets main / master (explicit refspec token, --all/--mirror, or the
#     current checkout is main/master), OR
#   - the repo is protected (same surface as guard-user-commit: a git-common-dir in
#     ~/.claude/protected-repos.list, or a tracked .claude/require-user-commit marker).
# Feature-branch pushes in unprotected repos pass freely — no friction on normal work.
#
# APPROVAL has two user-owned channels, both single-use per push:
#   1. Native macOS dialog (GUI sessions): the gate pops an osascript modal
#      (Cancel default, 30s timeout = cancel) that only the human at the screen
#      can click — it works even under skip-permissions where the harness
#      ask-path is inert. A decline is remembered per session so retries don't
#      re-pop the modal.
#   2. Sentinel fallback (headless/SSH/declined): ~/.claude/.push-approved-<session_id>
# The block message prints the exact command. It MUST be run by the user with the
# `! ` prefix (which runs in the user's own shell and bypasses PreToolUse hooks) —
# NOT by the agent. The gate consumes (deletes) the sentinel on the allowed push,
# so every gated push needs a fresh approval. That single-use property is also what
# makes it survive compaction correctly: a stale approval can authorise at most one
# push, never a blanket session. (Dialogs are single-use by construction — each
# push re-enters the hook.)
#
# DELIBERATE DEVIATION (mirrors guard-user-commit): NO self-liftable mute file. A
# `touch ~/.claude/.no-*-gate` a would let the very agent this gate exists to stop
# lift it. To disable, the USER removes the repo from the protected list / stops
# pushing to main. This hook ALSO blocks the agent from creating the sentinel itself
# (anti-self-lift) — only the user's out-of-band `! touch` can.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# session_id sanitised to a safe filename fragment (UUIDs are alnum+dash already).
sid_safe=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9._-' '_')
[ -n "$sid_safe" ] || sid_safe="nosession"
SENTINEL="$HOME/.claude/.push-approved-${sid_safe}"

blockjson() { jq -cn --arg r "$1" '{decision:"block", reason:$r}' 2>/dev/null || true; exit 0; }

# No anti-self-lift string-scan. An earlier version blocked any command that
# merely NAMED the sentinel path alongside "touch"/">"/"tee" — which false-fired
# on existence checks and on any command that just DISPLAYS the approval
# instructions (they contain "touch <sentinel>"). Raw-string scanning of the
# command can't tell a write from a mention (see command-scanning-guards-state),
# and by the hook-design cost-of-false-fire test that guard was a bad bet: high
# FP cost, low marginal benefit. The real protection is the push gate below plus
# the block message telling the agent not to self-approve — the same trust model
# guard-user-commit.sh uses for its protection config.

# ── Is this a git push at all? ───────────────────────────────────────────────
GIT_PUSH_RE='(^|[;&|[:space:](])git([[:space:]]+-C[[:space:]]+[^[:space:]]+|[[:space:]]+-c[[:space:]]+[^[:space:]]+|[[:space:]]+--[[:alnum:]-]+(=[^[:space:]]*)?)*[[:space:]]+push([[:space:]]|$|")'
printf '%s' "$cmd" | grep -qE "$GIT_PUSH_RE" || exit 0

# ── Resolve the repo the push runs in (git -C > last `cd` > cwd) ──────────────
expand_tilde() { case "$1" in "~"|"~/"*) printf '%s%s' "$HOME" "${1#\~}";; *) printf '%s' "$1";; esac; }
target="$cwd"; seg_cd=""; push_seg=""
while IFS= read -r seg; do
  if printf '%s' "$seg" | grep -qE "$GIT_PUSH_RE"; then
    push_seg="$seg"
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
[ -n "$target" ] || target="$cwd"

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
[ -n "$tgt_common" ] || exit 0   # not a git repo → nothing to gate

# ── Decide whether this push is gated ────────────────────────────────────────
gated=0; why=""

# (1) protected repo — same detection as guard-user-commit
if [ -f "$HOME/.claude/protected-repos.list" ]; then
  while IFS= read -r entry; do
    entry="${entry%%#*}"; entry=$(printf '%s' "$entry" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    [ -n "$entry" ] || continue
    e_common=$(common_dir_of "$(expand_tilde "$entry")")
    if [ -n "$e_common" ] && [ "$e_common" = "$tgt_common" ]; then
      gated=1; why="protected repo (~/.claude/protected-repos.list: $entry)"; break
    fi
  done < "$HOME/.claude/protected-repos.list"
fi
if [ "$gated" = 0 ]; then
  top=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)
  [ -n "$top" ] && [ -f "$top/.claude/require-user-commit" ] && { gated=1; why="protected repo (marker $top/.claude/require-user-commit)"; }
fi

# (2) targets main/master. The gate reads the REFSPEC, not the checkout: HEAD is
# only consulted when the push names no ref at all (a bare `git push`), because a
# bare push goes to the current branch's upstream. Judging by HEAD alone blocked
# `push origin --delete canary` from main and killed compound calls whose push
# targeted a feature branch (automation-d8ff1149, 2026-08-20 — eight spent canary
# branches stranded on the remote).
if [ "$gated" = 0 ]; then
  # Non-flag tokens after `push`: first is the remote, the rest are refspecs.
  push_args=$(printf '%s' "$push_seg" | sed -E 's/.*[[:space:]]push([[:space:]]|$)/\1/' | tr ' ' '\n' | grep -vE '^-|^$' || true)
  n_args=$(printf '%s' "$push_args" | grep -c . || true)
  if printf '%s' "$push_seg" | grep -qE '(^|[[:space:]:=/])(main|master)([[:space:]]|$)'; then
    gated=1; why="push targets main/master (explicit ref)"
  elif printf '%s' "$push_seg" | grep -qE '[[:space:]]--(all|mirror)([[:space:]]|$)'; then
    gated=1; why="push --all/--mirror can update main/master"
  elif [ "${n_args:-0}" -ge 2 ]; then
    : # explicit ref named and it is not main/master → a feature push or a branch
      # delete (--delete/-d/:ref all leave the ref as a non-flag token); HEAD is irrelevant
  else
    br=$(git -C "$target" rev-parse --abbrev-ref HEAD 2>/dev/null)
    case "$br" in main|master) gated=1; why="bare push while checked out on $br (no refspec; the push goes to $br's upstream)";; esac
  fi
fi

[ "$gated" = 1 ] || exit 0   # feature-branch push in an unprotected repo → allow

# ── Gated: consume a valid approval, or ask via native dialog, or block ──────
if [ -f "$SENTINEL" ]; then
  rm -f "$SENTINEL"   # single-use: this approval authorises exactly one push
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook push-gate --action allow-approved --heeded yes >/dev/null 2>&1 || true
  exit 0
fi

# ── DISABLED: the native-dialog approval channel is NOT SAFE here ────────────
#
# Shipped 2026-07-11 (prop-20260706-070113-7d), REMOVED as an approval channel
# 2026-07-13 after it was caught failing OPEN on a live push to main.
#
# In this environment `osascript -e 'display dialog …'` returns in ~1 second with
#   button returned:Approve this push, gave up:false
# WITHOUT the dialog ever being drawn for a human. Something in the automation
# layer answers it. The gate read that as "the user approved" and let the push
# through — twice, on real pushes to main, silently.
#
# Why the tests missed it: every branch was exercised against a STUBBED osascript
# on PATH. The stub behaved as documented; the real binary does not. A security
# gate must be exercised against the real dependency, never a stub — the stub can
# only confirm the logic you already believe.
#
# The invariant this violated: an approval channel must be one the AGENT CANNOT
# ACTUATE. A dialog the agent's own process can cause to return "approved" is not
# an approval — it is a rubber stamp the agent holds. The sentinel below is safe
# precisely because the user must create it out-of-band with `! touch`, in their
# own shell, where PreToolUse hooks do not run.
#
# Do not re-enable a GUI channel without first proving, on the target machine,
# that an UNCLICKED dialog burns its full `giving up after N` timeout and returns
# `gave up:true`. If it returns instantly, it is being auto-answered and cannot
# carry authority. (`PUSHGATE_DIALOG_NOTIFY=1` may be added later for a
# notify-only dialog that grants nothing — but it must never gate the exit.)

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook push-gate --action block --heeded unknown >/dev/null 2>&1 || true
blockjson "⛔ PUSH GATE: this push needs fresh user approval ($why).

Pushing to a shared branch is a per-push approval — one approval is never blanket,
and a context compaction may have wiped an earlier one. Do NOT work around this
(no --no-verify, no editing the protection config, no creating the sentinel yourself).

Instead:
  1. Show the user what will be pushed:  git -C \"$target\" log --oneline @{u}.. 2>/dev/null || git -C \"$target\" log --oneline -3
  2. Ask them to approve THIS push by typing (in their own shell, with the ! prefix):
       ! touch ${SENTINEL}
  3. Re-run the push. The approval is single-use — it is consumed by this one push.

If you believe this repo/branch should not be gated, ASK THE USER — that call is theirs."
