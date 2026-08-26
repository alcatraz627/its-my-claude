---
brief: Mint a Claude Code OAuth token for a DIFFERENT Anthropic account than this machine is logged into, using a throwaway Linux codespace so the local login is never at risk. Covers the CI auth model (subscription OAuth vs Console API key vs federation), the script, and the traps that cost a night.
triggers:
  - tool:mint-ci-token.sh
  - topic:ci-auth
  - topic:claude-code-oauth-token
  - topic:setup-token
  - phrase:"change the claude account in CI"
  - phrase:"CLAUDE_CODE_OAUTH_TOKEN"
related:
  - rules/never-modify-anthropic-credentials.md
  - features/dev-servers.md
tier: 2
category: features
updated: 2026-08-26
stale_after_days: 180
---

# Minting a CI token for an account that is not yours

## The three ways CI can authenticate

`anthropics/claude-code-action` accepts exactly three credentials, and they come
from different places that do not overlap.

| input | comes from | billing | notes |
|---|---|---|---|
| `claude_code_oauth_token` | `claude setup-token` on a machine logged into a **subscription** | that person's subscription limits | 1-year token. No web console page mints this. |
| `anthropic_api_key` | console.anthropic.com | per token, to the Console org | subscriptions have no API keys at all |
| federation (`anthropic_federation_rule_id` + org + service account) | GitHub OIDC exchanged per run | Console org | no long-lived secret in GitHub; needs `id-token: write` |

The first row is the one people reach for and the one that bites: a CI seat on a
personal subscription burns that person's quota, and when it runs dry every
review in the org silently degrades.

**If you cannot find an API key in the account CI uses, that is expected.** The
secret is named `CLAUDE_CODE_OAUTH_TOKEN` for a reason. Look for the subscription,
not the console.

## Why a throwaway Linux box

`claude setup-token` mints for whoever the local CLI is authenticated as, and the
CLI holds one login at a time. Switching it means `claude auth logout`, which
signs out every Claude Code session on the machine.

`CLAUDE_CONFIG_DIR` isolates the config (verified: an isolated dir reports
`loggedIn: false` while the host reports `true`), but on macOS the credential is
**not in that directory**. There is no `~/.claude/.credentials.json`; it lives in
the login Keychain under service `Claude Code-credentials`. Whether a login under
an isolated config dir writes to that same Keychain item is unverified, so the
downside is signing the whole machine out.

Linux has no Keychain. Credentials land in a file inside the box, so a codespace
cannot touch the host login by construction. That is the entire argument.

## The script

```
~/.claude/scripts/mint-ci-token/mint-ci-token.sh --repo OWNER/REPO --org ORG
```

It creates a 2-core codespace, installs the CLI, proves the box starts logged
out, walks the two OAuth rounds (sign-in, then token mint), pipes the token
straight into `gh secret set`, and deletes the box. The token never reaches a
screen, a shell history, or a command line.

Preconditions it checks and names the fix for: `gh` logged in, the `codespace`
scope (`gh auth refresh -h github.com -s codespace`), and `~/.ssh/codespaces.auto`
(`gh` only generates that on its first **interactive** ssh, so a piped shell
cannot bootstrap it; `ssh-keygen -t ed25519 -f ~/.ssh/codespaces.auto -N ''`).

## Traps, each one paid for

**Two OAuth rounds, not one.** `claude auth login` signs the box in; `claude
setup-token` then runs its own separate flow with a narrower scope
(`user:inference`) for the 1-year token. Two URLs, two codes.

**The browser decides the account, not the terminal.** The flow authorizes
whichever account the completing browser session holds. `--email` only
pre-populates the field. Use a private window or you will mint a second token for
the account you already have.

**A hand-copied token can carry a line break.** A token copied out of a wrapped
terminal pane arrived with a newline at character 101. What made it expensive is
that the lanes disagreed: `claude-code-action` normalized it and produced a full
review, while the ask lane put it straight into an `Authorization` header and died
in 179ms with `Invalid Authorization header value`. One green lane is not proof
the secret is clean. The script pipes and `tr -d '[:space:]'` for this reason.

**tmux, with `pipe-pane`.** Driving the interactive TUI over non-interactive ssh
needs tmux. Log the pane to a file: when `setup-token` exits it takes the tmux
server with it, and an unlogged pane takes the freshly minted token too.

**Send the text and the Enter separately.** The Ink TUI repeatedly accepted a
`send-keys` payload while ignoring the trailing `Enter` in the same call.

**An interrupted run leaks a billed box.** The EXIT trap loses the race when a
TERM arrives while `gh codespace ssh` holds the foreground. The script records the
name at creation and warns on the next run. To check by hand:
`gh codespace list`.

## Verifying the token actually works

Do not trust "secret updated". Trigger a real run and read which step executed:

```
gh run view <id> --repo <repo> --json jobs \
  --jq '.jobs[] | .name, (.steps[] | "  \(.name) [\(.conclusion)]")'
```

A working Claude seat shows **"Review the pull request" success** and **"Review
with Gemini" skipped**. The inverse means the org's `PR_AGENT` variable is set to
`gemini`, or Claude had no usage left. Both produce a green check and no review.
