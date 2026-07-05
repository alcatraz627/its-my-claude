---
brief: Agent-first driver for a local React/Next.js dev app — intent-targeted clicks, digests, fiber state, closed-overlay signal reads, via the `fs` daemon (V2)
triggers:
  - tool:fiber-snatcher
  - tool:fs
  - topic:react-debugging
  - topic:nextjs-debugging
  - topic:component-state-inspection
related: []
tier: 2
category: features
updated: 2026-07-05
stale_after_days: 90
---

# Fiber Snatcher (V2)

fiber-snatcher (repo: `~/Code/Claude/invasion-of-the-fiber-snatchers`, branch
`v2`) gives Claude deterministic drive/inspect/assert access to a local React or
Next.js dev app. V2 is the current version (CLI `fs`, `~/.local/bin/fs`); the old
`fiber-snatcher` CLI is frozen for un-migrated V1 projects. Design + full rules:
the repo's `CLAUDE.md`.

It is built to be driven by an agent: one action pipeline (resolve → wait → act →
settle → digest → journal), every verb auto-waits and returns a digest, and a
per-project daemon holds the browser across calls (~30ms warm vs a fresh launch).

## When to use

Any task touching a local React/Next.js dev app that needs to drive UI, read
component state, or diagnose behavior. **Default preference** over hand-rolled
`browser_evaluate` / Playwright MCP for state reads and intent-based clicks.

## Detect setup

```bash
test -f .fiber-snatcher/config.json   # if absent: offer `fs init`, don't install unprompted
```

## Core loop (V2 `fs`)

```bash
fs doctor                       # end-to-end health
fs page                         # semantic snapshot: route + interactables with refs
fs click "Export All Sheets"    # intent target; auto-waits; returns a mutation/surface digest
fs why <ref>                    # every identity signal for an unlabeled icon — incl. what a
                                #   CLOSED dropdown/tooltip opens, read from fiber props (no click)
fs state <ref|css>              # fiber state/props/hooks of the nearest stateful ancestor
fs wait --settled|--url /re/|--gone <t>   # explicit waits when a verb's auto-wait isn't enough
fs navigate /path · fs fill · fs hover · fs macro · fs watch console|route|network
fs stop                         # at session end (see the daemon-stop caveat below)
```

Per-project **adaptation** (`.fiber-snatcher/config.json` `adapt` block:
`surfaceSelectors`, `overlayComponents`, `contentPropKeys`) teaches the tool a
codebase's non-ARIA overlays and prop conventions.

## Rules

- Start the daemon once, reuse across calls — never re-launch per tool call.
- Every command supports `--json`; results also persist to `.fiber-snatcher/last-run.json`.
- Failure codes carry actionable `next_steps`; refs are generation-stamped (stale refs fail loudly).
- **Session caveat (auth apps):** the login session lives in the running browser
  and dies on a daemon restart. For an app behind auth, drive the already-running
  logged-in daemon in place; don't `fs stop` mid-flow expecting the session to survive.

## Testing it

- Fixture e2e/unit/protocol: `bun test tests/e2e/<wpN>.test.ts` (run per-file; the
  full fan has a load-sensitive boot flake).
- Live-app integration: `tests/integration/versable.test.ts` drives a real running
  dev app through its authenticated session (optional hands-free auto-login via a
  gitignored creds file / env). See `tests/integration/README.md`.

## Do NOT use for

- Cross-browser testing (Playwright MCP) · perf traces (Chrome DevTools MCP) ·
  production/staging targets.

## Full docs

`~/Code/Claude/invasion-of-the-fiber-snatchers/CLAUDE.md` (V2 operating
instructions), `docs/DRIVING.md` (owner quickstart), `USAGE.md` (target-project
setup + auth-bypass patterns), `CHANGELOG.md` (2.1.0 is current on `v2`).
