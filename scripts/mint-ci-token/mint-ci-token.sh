#!/bin/bash
# mint-ci-token.sh — mint a Claude Code OAuth token for a DIFFERENT account than
# the one this machine is logged into, without touching this machine's login.
#
# The problem it solves: `claude setup-token` mints for whoever the local CLI is
# authenticated as, and on macOS that credential lives in the login Keychain
# (service "Claude Code-credentials"), not in a config file. CLAUDE_CONFIG_DIR
# isolates the config but its effect on the Keychain write is unverified, so
# minting for a second account risks signing every local session out. A throwaway
# Linux box has no Keychain at all, so the blast radius is zero by construction.
#
# The token never appears on screen, in shell history, or in a command line: it
# is piped from the remote box straight into `gh secret set`. That also dodges
# the failure this script was written after, where a hand-pasted token carried a
# line break at character 101 and one CI lane accepted it while another died on
# an illegal Authorization header.
#
# Usage: mint-ci-token.sh --repo OWNER/REPO [--org ORG] [--secret NAME] [--keep]
#   --repo    repo to attach the codespace to (a testbed, not production)
#   --org     set the token as this org's Actions secret (omit to save to a file)
#   --secret  secret name (default CLAUDE_CODE_OAUTH_TOKEN)
#   --keep    do not delete the codespace on exit (debugging only)

set -uo pipefail

for f in colors tty require pick; do
  # shellcheck source=/dev/null
  [ -f "$HOME/.claude/scripts/tui/$f.sh" ] && . "$HOME/.claude/scripts/tui/$f.sh"
done
command -v tui_colors_init >/dev/null && tui_colors_init
: "${B:=}" "${Y:=}" "${C:=}" "${D:=}" "${R:=}" "${G:=}" "${RED:=}"

STATE="$HOME/.claude/scripts/mint-ci-token/.last-codespace"
# A run killed between create and cleanup leaks a billed box, and the trap can
# lose that race (a TERM arriving while gh ssh holds the foreground). The name is
# recorded the moment it exists, so the next run can see what was left behind.
if [ -s "$STATE" ]; then
  PREV=$(cat "$STATE")
  if gh codespace list --json name --jq '.[].name' 2>/dev/null | grep -qx "$PREV"; then
    printf '%swarning:%s a codespace from an earlier run is still alive: %s\n' "$Y" "$R" "$PREV" >&2
    printf '%s        it bills until deleted:%s gh codespace delete -c %s --force\n' "$D" "$R" "$PREV" >&2
  else
    rm -f "$STATE"
  fi
fi

REPO=""; ORG=""; SECRET="CLAUDE_CODE_OAUTH_TOKEN"; KEEP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --org) ORG="${2:-}"; shift 2 ;;
    --secret) SECRET="${2:-}"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf '%serror:%s unknown flag %s\n' "$RED" "$R" "$1" >&2; exit 2 ;;
  esac
done

die() { printf '%serror:%s %s\n' "$RED" "$R" "$1" >&2; [ -n "${2:-}" ] && printf '%sfix:%s   %s\n' "$Y" "$R" "$2" >&2; exit 1; }
say() { printf '%s==>%s %s\n' "$C" "$R" "$1"; }

[ -n "$REPO" ] || die "--repo is required" "mint-ci-token.sh --repo versable-git/pr-claude-testbed --org versable-git"
command -v gh >/dev/null || die "gh not found" "brew install gh"
gh auth status >/dev/null 2>&1 || die "gh is not logged in" "gh auth login"
gh codespace list >/dev/null 2>&1 || die "gh lacks the codespace scope" "gh auth refresh -h github.com -s codespace"
# gh generates this on its first INTERACTIVE ssh and cannot in a piped shell.
[ -f "$HOME/.ssh/codespaces.auto" ] || die "no codespaces ssh key" \
  "ssh-keygen -t ed25519 -f ~/.ssh/codespaces.auto -N '' -C codespaces.auto"

CS=""
cleanup() {
  [ -n "$CS" ] && [ -z "$KEEP" ] && { say "deleting codespace"; gh codespace delete -c "$CS" --force >/dev/null 2>&1; rm -f "$STATE"; }
}
trap cleanup EXIT INT TERM


rsh() { gh codespace ssh -c "$CS" -- "$@"; }

say "creating a throwaway codespace on $REPO"
CS=$(gh codespace create -R "$REPO" -m basicLinux32gb --idle-timeout 30m 2>/dev/null | tail -1)
[ -n "$CS" ] || die "codespace create failed"
printf '%s' "$CS" > "$STATE"
say "codespace: $CS"

say "installing the Claude CLI and tmux"
rsh 'npm i -g @anthropic-ai/claude-code >/dev/null 2>&1; sudo apt-get update -qq >/dev/null 2>&1; sudo apt-get install -y -qq tmux >/dev/null 2>&1; command -v claude >/dev/null && command -v tmux >/dev/null' \
  || die "install failed in the codespace"

# Isolation proof: the box must start with NO login. If this ever reports true,
# something is carrying credentials in and the whole premise is wrong.
rsh 'claude auth status' 2>/dev/null | grep -q '"loggedIn": false' \
  || die "the fresh box reports a login; refusing to continue"
say "box is logged out, as expected"

# One OAuth round. tmux keeps the TUI alive between ssh calls, and pipe-pane
# persists its output to a file so a process that exits does not take the answer
# with it (learned the hard way: the pane died holding the minted token).
oauth_round() { # $1=session $2=command $3=human label
  local sess="$1" cmd="$2" label="$3" url code
  rsh "rm -f /tmp/$sess.log; tmux kill-session -t $sess 2>/dev/null; tmux new-session -d -s $sess -x 200 -y 50 '$cmd'; sleep 2; tmux pipe-pane -o -t $sess 'cat >> /tmp/$sess.log'" >/dev/null 2>&1
  local i url=""
  for i in 1 2 3 4 5 6 7 8; do
    url=$(rsh "grep -ao 'https://claude.com/cai/oauth/authorize[^ ]*' /tmp/$sess.log | tail -1" 2>/dev/null | tr -d '\r')
    [ -n "$url" ] && break
    sleep 5
  done
  [ -n "$url" ] || die "no OAuth URL appeared for $label"

  printf '\n%s%s%s\n' "$B" "$label" "$R"
  printf '%sOpen in a PRIVATE window and sign in as the target account.%s\n' "$Y" "$R"
  printf '%sA normal window reuses your own session and mints the wrong account.%s\n\n' "$D" "$R"
  printf '%s\n\n' "$url"

  if command -v tui_read_tty >/dev/null && tui_have_tty; then
    tui_read_tty -p "paste the code here > " code
  else
    printf 'paste the code here > '; read -r code
  fi
  [ -n "$code" ] || die "no code entered"

  # The TUI sometimes takes the text and not the Enter, so Enter is sent alone.
  rsh "tmux send-keys -t $sess \"$code\"; sleep 1; tmux send-keys -t $sess Enter" >/dev/null 2>&1
  sleep 20
}

oauth_round auth "claude auth login --claudeai" "STEP 1 of 2 — sign the box in"
ACCT=$(rsh 'claude auth status' 2>/dev/null | grep '"email"' | cut -d'"' -f4)
[ -n "$ACCT" ] || die "sign-in did not complete"
say "signed in as: ${B}${ACCT}${R}"

oauth_round tok "claude setup-token" "STEP 2 of 2 — mint the 1-year token"

# Extract, strip EVERY whitespace character, and never echo it. The line break a
# human paste introduced at character 101 is precisely what `tr -d` removes here.
rsh "grep -ao 'sk-ant-[A-Za-z0-9_-]*' /tmp/tok.log | head -1 | tr -d '[:space:]' > /tmp/token.txt; wc -c < /tmp/token.txt" >/dev/null 2>&1
LEN=$(rsh "wc -c < /tmp/token.txt" 2>/dev/null | tr -d '[:space:]')
[ "${LEN:-0}" -gt 50 ] || die "no token found in the pane log" "re-run with --keep and inspect /tmp/tok.log in the box"
say "token minted for $ACCT (${LEN} chars, never displayed)"

if [ -n "$ORG" ]; then
  say "setting $SECRET on org $ORG"
  rsh "cat /tmp/token.txt" 2>/dev/null | tr -d '[:space:]' \
    | gh secret set "$SECRET" --org "$ORG" --visibility all \
    || die "gh secret set failed"
  printf '%s✓%s %s set on %s from %s\n' "$G" "$R" "$SECRET" "$ORG" "$ACCT"
else
  OUT="${TMPDIR:-/tmp}/claude-ci-token.txt"
  rsh "cat /tmp/token.txt" 2>/dev/null | tr -d '[:space:]' > "$OUT"
  chmod 600 "$OUT"
  printf '%s✓%s token written to %s (mode 600) — set it, then delete it\n' "$G" "$R" "$OUT"
fi

# Prove the local login was never touched. This is the whole point of the script.
LOCAL=$(claude auth status 2>/dev/null | grep '"email"' | cut -d'"' -f4)
printf '%slocal login still: %s%s\n' "$D" "${LOCAL:-unknown}" "$R"
