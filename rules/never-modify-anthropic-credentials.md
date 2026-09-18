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
updated: 2026-09-18
stale_after_days: 365
---
# NEVER set, change, rotate or unset the Anthropic API key or any global-blast-radius credential

A bad value crashes every Claude instance on the machine at once, including the one that wrote it, so only the human can recover. If a task seems to need it, stop and hand it to the owner with the exact command or edit for them to run.

Forbidden surfaces for `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `CLAUDE_API_KEY`, `ANTHROPIC_BASE_URL`: shell env files (`~/.zshenv`, `~/.zshrc`, `~/.zprofile`, `~/.bashrc`, `~/.profile`), `~/.claude.json` auth fields, the `env` block of `~/.claude/settings.json`, `launchctl setenv`, the macOS keychain, `claude config set` of any auth field, any `export ANTHROPIC_API_KEY=` in a script the owner runs.

Detecting, reading or mentioning the key is fine; the line is set/modify versus read. Enforced by `guard-anthropic-credentials.sh`.

Diagnostic: about to run or edit anything that ASSIGNS an Anthropic auth value.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/never-modify-anthropic-credentials.md`
