---
brief: NEVER set/modify/rotate/unset the Anthropic API key or any global-blast-radius credential — a bad value crashes EVERY Claude instance at once. Stop and ask the user to do it by hand.
triggers:
  - topic:api-key
  - topic:credentials
  - phrase:"ANTHROPIC_API_KEY"
  - phrase:"api key"
  - phrase:"rotate token"
  - tool:Bash
related:
  - rules/shell.md
tier: 0
category: rules
updated: 2026-05-25
stale_after_days: 365
---

# NEVER modify the Anthropic API key or global-blast-radius credentials

Do not set, change, export, unset, rotate, or "fix" the Anthropic API key — or
any credential/env that every Claude Code instance reads — in ANY file, env, or
keychain. If a task seems to require it, **STOP and ask the user to do it
manually.**

Graduated immediately from a 2026-05-24 incident: an agent action changed the
Anthropic API key; **every Claude instance on the machine crashed at once**, and
the user had to find and remove the bad value by hand. (The mac-migration agent
diagnosed it after the fact but did not add a guard — this rule + its hook is
that guard.)

## Why this is a hard rule (not a nudge)

The blast radius is the whole machine, and recovery is self-defeating: the agent
that breaks the key kills its own runtime — and every sibling session — the
instant the change takes effect, so it cannot undo it. Only the human can. There
is no "I'll fix it after." This is the rare case where the correct action is
*always* to hand it to the user.

## The forbidden surfaces

NEVER write/modify the key (or `ANTHROPIC_AUTH_TOKEN`, `CLAUDE_API_KEY`,
`ANTHROPIC_BASE_URL`) in:
- shell env files: `~/.zshenv` `~/.zshrc` `~/.zprofile` `~/.zenv` `~/.bashrc` `~/.profile`
- `~/.claude.json` (auth/account fields), `~/.claude/settings.json` `env` block
- `launchctl setenv` / `setx` / system env
- macOS keychain (`security add-generic-password` for anthropic)
- `claude config set` of any auth/key field
- any `export ANTHROPIC_API_KEY=...` in a script the user runs

## What to do instead

> "This needs the Anthropic API key set/changed at `<surface>`. I won't touch it
> — a bad value crashes every Claude instance and only you can recover it.
> Please set it yourself: `<exact command/edit>`, then tell me to continue."

Give the exact value/command for the user to run; never run it for them.

## What this rule does NOT forbid

- **Detecting** the key (secret-scan guards, `rg "ANTHROPIC_API_KEY"`, cli-gating,
  sync-all's `secret_guard`) — those read/match, they don't set.
- Reading docs, or telling the user how to set it.
The line is **set/modify vs read/mention.**

## Diagnostic signal

You're about to run/edit anything that ASSIGNS a value to an Anthropic auth var,
or writes auth into `~/.claude.json` / a shell profile / keychain. Stop — hand it
to the user.

## Enforcement

Mechanical, not just advisory (advisory rules don't bind in-flight agents):
`scripts/hooks/guard-anthropic-credentials.sh` (PreToolUse) hard-blocks the
forbidden writes. Mute (you almost never should): `touch ~/.claude/.allow-cred-write`.

## Related
- `rules/shell.md` · the cli-gating secrets guard · MANIFEST §8 (secrets are MANUAL + rotate)
- Incident provenance: atone `mist-20260525-080503-e9` (`bulk-sync-without-secret-scan`) — the migration's secret-scan slip that surfaced this leaked key. The key-*change* that crashed all instances traces to the same migration surface (token-rotation scope), not to a session that read/mentioned the key.
