---
brief: "The owner's agent policy: one store (~/.claude/policy) of allow/block switches, choices and thresholds for what agents may do as the owner (GitHub, Slack, Linear, commits, pushes, deploys, model seats), global with per-repo overrides and timed flips. Set in the menu bar policy panel; read live by hooks through pol.sh. Agents read it, never write it."
triggers:
  - tool:pol.sh
  - tool:guard-policy.sh
  - topic:agent-policy
  - topic:permissions
  - topic:policy-panel
  - phrase:"agent policy"
  - phrase:"allowed to push"
  - phrase:"allowed to comment"
related: [macos-menubar-widget, git, model-tier-routing]
tier: 2
category: features
updated: 2026-09-25
stale_after_days: 60
---

# Agent policy

The owner decides what agents may do on their behalf, and flips it with one click.
Every decision lives in one store, applies to every running session at once, and
covers every route to the action: an agent pushing through `git` or through the
GitHub MCP meets the same switch.

```
  menu bar ── [faders icon] ──▶ panel (PolicyPanel.swift)
                  │ clicks run pol.sh set|snooze|clear
                  ▼
  ~/.claude/policy/registry.json   which policies exist, their type and default
  ~/.claude/policy/policy.json     values: global, plus projects{<repo root>}
                  ▲ pol.sh get, on every relevant tool call
  guard-policy.sh · guard-git-push.sh · guard-user-commit.sh · guard-model-tier.sh
  guard-secret-file-read.sh · guard-system-dir-writes.sh · guard-artifact-unasked.sh
  render-mcp-gate.py · prose-smell-stop.sh · usage-gate.sh · policy.sh
  codex adapter (session-start.sh, pre-tool-bash.sh)
```

## What an agent should do with it

- **Allowed means do it.** A policy that allows an action needs no approval
  request. Asking out of real caution is still fine; asking because a hook
  might block is not.
- **Blocked means say so.** A block message names the key (`slack.post = block`).
  Tell the owner the action is switched off and carry on with the rest. Never ask
  them to approve a blocked action; the switch is the approval.
- **Ask means one typed OK per call.** A block at `ask` prints a line such as
  `approve slack.post 3f9a01c2`. Print it to the owner bare on its own line and
  keep working; never call AskUserQuestion for it. When a `[policy-ask]` note says
  it is approved, retry the same call; the approval covers that one call. The
  owner can type `deny <key>` instead. `guard-policy.sh` issues the token and
  consumes the approval; `policy-ask-prompt.sh` (UserPromptSubmit) turns the
  typed line into it. Tokens are per session and per key, kept in
  `~/.claude/.policy-ask/`. A session started before 2026-09-29 lacks the prompt
  hook and cannot receive an approval: restart it.
- **Read, never write.** `pol.sh get <key> --cwd <dir>` answers what applies
  here. `set`, `snooze`, `unsnooze` and `clear` refuse to run from an agent shell,
  and `guard-policy-store.sh` blocks edits to `policy.json` by any route.

Every session gets a one-line summary at start (`pol.sh inject`, in the
synchronous SessionStart lane) listing values changed from their defaults.

## Changing a policy (the owner)

Click the faders icon in the menu bar to open the Switchboard, its own app since
2026-09-28 (`~/Code/Claude/switchboard-mac`, installed at
`~/Applications/Switchboard.app`). Its **Agents** tab lists every policy by
group, each with the control its type calls for. Its **Machine** tab carries
the machine switches (guards, services, schedules, Keep Awake, board sync,
wake-on-LAN). Any switch takes a timer: flip it now and back at a time, kept
across restarts (`Switchboard --probe-timers` tests the engine on the real
Keep Awake switch).
The panel opens on cached values and refreshes underneath.

- **Scope** (top right): Everywhere, or one repository. A repo scope shows only
  policies that take a per-repo override; a row with no override says "Follows
  Everywhere". Worktrees share their main checkout's override.
- **Timed flip** (the clock on each row): switch to another value in 1 hour,
  4 hours, at the end of today, in 1 day or in 7 days. The current value holds
  until then. The row shows the countdown and a cancel button.
- **Reset** (the ↶ next to a changed row): back to the default, or, in a repo
  scope, remove that repo's override.

From your own terminal the same verbs work:
`bash ~/.claude/scripts/pol/pol.sh set slack.post block`, `… snooze git.push --for 4h --then block --project ~/Code/x`,
`… list --cwd ~/Code/x`. A script can open or close the panel by posting the
distributed notification `dev.switchboard.toggle`.

## The policies

| Group | Key | Values | Default | Enforced by |
|---|---|---|---|---|
| Acting as you | `github.comment` | allow, block | allow | `guard-policy.sh` (gh CLI, `gh api`, GitHub MCP) |
| | `github.write` | allow, ask, block | allow | `guard-policy.sh` |
| | `slack.post` | allow, ask, block | allow | `guard-policy.sh` (Slack connector; drafts never gated) |
| | `linear.write` | allow, ask, block | allow | `guard-policy.sh` |
| | `artifact.publish` | allow, ask, block | ask | `guard-artifact-unasked.sh` |
| Code | `git.commit` | allow, block (per repo) | allow | `guard-user-commit.sh` |
| | `git.push` | allow, block (per repo) | allow | `guard-git-push.sh`; MCP `push_files` in `guard-policy.sh` |
| | `git.push_main` | allow, ask, block (per repo) | ask | `guard-git-push.sh`; an MCP push to main at ask is refused (no approval channel) |
| Deploy | `deploy.vercel` | allow, ask, block | allow | `guard-policy.sh` (connector and `vercel` CLI) |
| | `deploy.cloudflare` | allow, ask, block | allow | `guard-policy.sh` (`wrangler` deploy, secrets, KV, R2, D1 writes) |
| | `deploy.render` | allow, ask, block | ask | `render-mcp-gate.py` (ask is its nonce) |
| Models | `model.fable` | allow, block | allow | `guard-model-tier.sh` |
| | `model.codex` | encourage, allow, block | allow | codex `session-start.sh` refuses seats at block; encourage adds a line to every session start |
| | `model.heavy_local` | allow, warn | allow | `guard-policy.sh`; warn never blocks, and tells the agent to run the model anyway when quality justifies it |
| Machine | `files.env_read` | allow, block (per repo) | block | `guard-secret-file-read.sh` |
| | `files.system_write` | allow, block | block | `guard-system-dir-writes.sh` |
| Limits | `ops.subagent_model` | haiku, sonnet, opus | sonnet | session-start line |
| | `ops.workflow_size` | small, medium, large | small | session-start line |
| | `ops.usage_gate_pct` | 50 to 100 | 90 | `cron/usage-gate.sh` (an explicit `USAGE_GATE_PCT` still wins) |
| | `ops.fable_warn_pct`, `ops.fable_strong_pct` | 50 to 100 | 80, 90 | `scripts/policy.sh fable` |
| Gates | `gates.prose_smell` | off, warn, enforce | enforce | `prose-smell-stop.sh` (replaces `PROSE_SMELL_ENFORCE`; mutes still win) |

Routes each key covers: the CLI (by bare name or any path, `/opt/homebrew/bin/gh`
included), the service's MCP connector, and a REST call through
`mcp__file-tools__http_request` to that service's API host (GitHub, Slack,
Linear mutations, Vercel, Cloudflare). Credentialed `curl` writes are already
refused outright by `block-curl-post-auth.sh`.

Every route that moves a branch on GitHub without `git` (the MCP push and file
tools, REST ref and contents writes, `gh api` on refs and contents) goes
through `git.push` / `git.push_main`, with no branch meaning the default branch.
For a repo in `protected-repos.list` (matched by its GitHub remote) those routes
are refused outright, because only `git push` can collect the per-push
approval. `gh api` counts as a write the way `gh` itself decides: an explicit
write method, or field or input flags with no `-X`; GraphQL only for a mutation.

Known limit, accepted: `guard-policy-store.sh` reads command lines and tool
paths, so it stops an agent writing the store with a redirect, `Write`, `jq >`,
a relative path from inside `~/.claude`, or a File Tools write. It cannot see
inside a script the agent wrote elsewhere and then runs, because the agent and
the owner are the same Unix user. That is the same trust model the push gate
states for its approval sentinel.

Deliberately not a policy: the Anthropic credential guard (never switchable),
effort level and main model (Claude Code keeps those), and the mute files for
individual hooks (the "Muted guards" row on the Switchboard's Machine tab).

## Adding a policy

1. Add an entry to `registry.json`: `key`, `group`, `label`, `type` (`bool`,
   `enum` with `options`, or `number` with `min`, `max`, `step`, `unit`),
   `default`, `scopes` (`["global"]` or `["global", "project"]`), `help`.
   The panel renders it with no Swift change: a switch for bool, a segmented
   control for an enum of three or fewer, a menu above that, a slider for a number.
2. Read it where the behaviour lives: `bash "${POL_SH:-$HOME/.claude/scripts/pol/pol.sh}" get <key> --cwd "$cwd"`.
   Treat an empty answer as "no opinion" and keep the hook's old behaviour, so a
   missing or broken store never blocks work.
3. Add cases to `scripts/hooks/guard-policy.test.sh`.

The registry is edited like code and reviewed in commits; only `policy.json`
is owner-only.

## The old stores, until the owner signs off

The owner asked to prove this works before retiring what it replaces. Until
then the old stores keep working, and wherever an old store has an opinion it
wins:

- `protected-repos.list` and `.claude/require-user-commit`: commits stay
  owner-only and pushes keep the per-push approval, whatever `git.commit` or
  `git.push_main` says.
- The `fable-restrict` row in `hooks/snooze.jsonl` still blocks fable seats.
- Mute files (`.no-secret-read-guard`, `.no-artifact-gate`, `.allow-system-writes`,
  `.no-prose-smell-gate`, `.no-codex-usage-gate`) still switch their hook off.

Every default equals the behaviour before this existed, so nothing changed until
the owner flipped something. Retiring the old stores is a separate change:
migrate each into `policy.json`, then remove the old reader.

## Files and tests

- Store and CLI: `~/.claude/policy/`, `scripts/pol/pol.sh`, `scripts/pol/policy-inject.sh`
- Hooks: `scripts/hooks/guard-policy.sh`, `scripts/hooks/guard-policy-store.sh`,
  and the readers listed in the diagram
- Panel: `~/Code/Claude/switchboard-mac/Sources/Policy.swift` (model and
  `pol.sh` bridge), `Sources/PolicyPanel.swift` (view, status item, snapshot)
- Tests: `scripts/pol/pol.test.sh` (store), `scripts/hooks/guard-policy.test.sh`
  (every key and route), `switchboard-mac/tests/fixtures/policy-probe.sh`
  (every write the panel makes); all three run from switchboard-mac's `tests/run-tests.sh`.
- Headless panel checks: `Switchboard --dump-policy [--scope <dir>]`,
  `--snapshot out.png --tab agents [--light] [--scope <dir>]`.
- Plan and rulings: `switchboard-mac/docs/plans/20260924-gcc-switchboard-plan.md`.
