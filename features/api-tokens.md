---
brief: How API tokens reach tools without reaching transcripts. Linear, Render and Slack tokens live in the macOS Keychain and the GitHub token in gh's keyring. The owner's shells export them; agent shells strip them, and an agent that needs one runs `with-token NAME -- cmd`. A PostToolUse scanner reports any token that still reaches a transcript.
triggers:
  - tool:with-token
  - tool:token-set
  - tool:secret-leak-scan
  - topic:api-token
  - topic:secrets
  - topic:credentials
  - topic:token-rotation
  - phrase:"needs the token"
  - phrase:"API key"
  - phrase:"rotate"
related:
  - local-models
tier: 2
category: features
updated: 2026-10-22
stale_after_days: 180
---

# API tokens: reachable by tools, absent from transcripts

The owner was rotating tokens after agents printed them (a test stub stored `env`, a debug
dump, a `ps e`). Blocking commands one by one never closed that class, so the tokens are no
longer in an agent's environment at all. An agent can still reach any of them in one step,
with no approval, when a command needs it.

```
 Keychain (linear-api, render-api, slack-mcp-xoxb)   gh keyring (GitHub)
        │                                                   │
        ├─► owner's shells: ~/.zshenv exports all of them ◄─┤
        │      (CLAUDECODE unset)                           │
        │                                                   │
        └─► agent shells: ~/.zshenv strips all four ────────┘
               (CLAUDECODE set)
                 │
                 └─► with-token NAME -- cmd   one command, fresh from the store
```

## For agents

- Your shell has no `LINEAR_API_KEY`, `RENDER_API_KEY`, `SLACK_MCP_XOXB_TOKEN` or
  `GITHUB_PERSONAL_ACCESS_TOKEN`. That is deliberate, not a broken setup. Do not ask the
  owner for a token.
- When a command needs one, run it through `with-token`:
  `with-token LINEAR_API_KEY -- curl -s -H "Authorization: $LINEAR_API_KEY" ...` does not
  work, because your shell expands `$LINEAR_API_KEY` before `with-token` runs. Put the
  expansion inside the command: `with-token LINEAR_API_KEY -- sh -c 'curl -s -H "Authorization: $LINEAR_API_KEY" https://api.linear.app/graphql ...'`.
  A tool that reads the variable itself needs nothing extra: `with-token RENDER_API_KEY -- <tool> <args>`.
- Several names may go before `--`. Unknown names exit 2; a token missing from the store exits 12.
- `~/.claude/scripts/linear/linear.py` reads the Keychain itself; call it directly.
- MCP servers are started by Claude Code, which inherits the owner's terminal environment,
  so they keep their tokens.
- Never print a token, not even a prefix. Check presence with `[ -n "$NAME" ] && echo set`,
  and length with `${#NAME}`.

## For the owner

- After rotating: `token-set LINEAR_API_KEY` (or `RENDER_API_KEY`, `SLACK_MCP_XOXB_TOKEN`)
  asks for the new value without echoing it and stores it in the Keychain. For GitHub run
  `gh auth refresh`. Then open a new terminal and restart Claude Code so MCP servers pick it up.
- Adding a token: add a `NAME service` pair to `_TOKEN_SERVICE` in `~/.zshenv`, the strip
  list beside it, and the scanner's patterns if it has a recognisable shape.

## The leak scanner

`~/.claude/scripts/hooks/secret-leak-scan.py` runs after every tool call (PostToolUse,
matcher `*`, 10 s timeout). It looks for token shapes (GitHub, Slack, Linear, Render,
Anthropic, OpenAI, Google, AWS, private keys) in the call's input and output. It cannot
un-print anything; its job is that no leak goes unnoticed.

- On a hit it tells the owner on screen and the agent in context, by kind and tool, never
  the value, and appends `{ts, session, tool, kind, fingerprint, cwd}` to
  `~/.claude/logs/secret-leaks.jsonl` (the fingerprint is 8 hex chars of a sha256, so repeats of one
  token can be told apart from new ones).
- Cost: about 20 ms per call, about 0.5 s on an 8 MB output.
- It never blocks work. Any internal error exits 0 with one warning per session saying the
  scanner is not checking; it never retries or prints twice.
- Masked forms (`gho_****` from `gh auth status`) do not match.
- Mute: `touch ~/.claude/.no-secret-scan`.

The command-side guard is separate: `guard-env-dump.sh` still refuses `env`, `printenv`,
`ps e`, `pm2 env` and similar before they run.
