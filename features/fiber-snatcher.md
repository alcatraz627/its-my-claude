---
brief: React/Next.js dev-app debugging: state reads, dispatch, screenshots, error digests via local daemon
triggers:
  - tool:fiber-snatcher
  - topic:react-debugging
  - topic:nextjs-debugging
  - topic:component-state-inspection
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Fiber Snatcher
fiber-snatcher (repo: `~/Code/Claude/invasion-of-the-fiber-snatchers`, binary: `~/.local/bin/fiber-snatcher`) gives Claude deterministic inspect/drive/assert access to a local React or Next.js dev app: read component state by selector, dispatch store actions, capture unified error digests, take predictable screenshots.

## When to use

Any task that touches a local React/Next.js dev app *and* needs to read state, drive UI, or diagnose console/network errors. **Default preference** over hand-rolled `mcp__playwright__browser_evaluate` or `evaluate_script` for state reads.

## Detect setup

```bash
test -f .fiber-snatcher/config.json
```

If absent and the task needs inspection, ask the user: *"This project doesn't have Fiber Snatcher set up. Want me to run `fiber-snatcher init` and wire it per USAGE.md?"* Don't install unprompted.

## Lifecycle

```bash
fiber-snatcher status        # is the daemon up?
fiber-snatcher start         # ~1.5s cold start; keep running across tool calls
fiber-snatcher doctor        # end-to-end health probes

fiber-snatcher state '[data-testid="cart"]'      # read state/props/hooks
echo '{"type":"X"}' | fiber-snatcher dispatch    # push action through registered adapter
fiber-snatcher shoot --name after-fix            # PNG to .fiber-snatcher/shots/
fiber-snatcher errors --since 5m                 # grouped digest
fiber-snatcher logs -f --level warn              # tail unified JSONL

fiber-snatcher stop          # at end of session, or let user keep it open
```

## Rules

- Start the daemon once, reuse for many commands — **never re-start per tool call**
- Every command supports `--json` for machine-parseable output
- All results persist to `.fiber-snatcher/last-run.json`
- Failure codes (`E_NOT_INITIALIZED`, `E_DEV_SERVER_DOWN`, `E_STATE_FAILED`, …) carry actionable `next_steps`

## Do NOT use Fiber Snatcher for

- Cross-browser testing (use Playwright MCP)
- Performance traces (Chrome DevTools MCP `performance_*`)
- Route/server-action discovery (next-devtools-mcp)
- Production/staging targets

## Full docs

`~/Code/Claude/invasion-of-the-fiber-snatchers/CLAUDE.md` (operating instructions), `USAGE.md` (target-project setup including auth-bypass patterns for NextAuth / proxy.ts / custom middleware).
