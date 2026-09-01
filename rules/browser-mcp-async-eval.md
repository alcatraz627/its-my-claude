---
brief: Browser-MCP eval returns immediately — never put a polling/wait loop inside browser_evaluate (it hangs the MCP server); poll state from the shell between calls, and let the page settle after navigate before acting.
triggers:
  - topic:browser-automation
  - topic:playwright
  - topic:browser-mcp
  - tool:browser_evaluate
  - tool:evaluate_script
  - phrase:"browser_evaluate"
related:
  - features/fiber-snatcher.md
  - rules/testing.md
paths:
  # autoload opt-out: browser-MCP work is <20% of sessions, so this is on-demand
  # (Tier 2) — read from rules/00-index.md when driving a browser MCP. Sentinel
  # never matches a real file; revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-07-16
stale_after_days: 365
---

# Browser-MCP: async eval returns immediately, poll from the shell

A browser-automation MCP (Playwright, chrome-devtools) runs each tool call as a
single round-trip. Work you kick off inside the page — a wait, a retry, a poll —
does not belong inside the eval: the eval call blocks until the loop finishes, and
a long loop can hang the MCP server itself.

Graduated from the JEGS lab sessions (2026-07-14/15): a 180s polling loop placed
inside `browser_evaluate` blocked the tool call for minutes and hung the
Playwright server, requiring a reset. Separately, clicking immediately after
`browser_navigate` aborted the first action client-side (`net::ERR_ABORTED`) and
looked exactly like a real pipeline failure.

## The rule

1. **Never put a polling / wait / retry loop inside `browser_evaluate` /
   `evaluate_script`.** The eval should read state and return immediately. Do the
   waiting between tool calls — from the shell, or with the MCP's own wait tool —
   not inside the page.
2. **Let the page settle after navigation before acting.** A click or read fired
   the instant after `browser_navigate` can abort client-side. Allow a settle
   delay and poll for a ready signal rather than assuming.
3. **A browser abort/timeout is environmental until proven otherwise** (see
   `rules/testing-patterns.md` `[root-cause]`). `net::ERR_ABORTED` / `ECONNABORTED` right
   after navigate is usually a timing artifact, not a product bug.

## What this rule does NOT mean

- Not general async advice, and not about non-browser MCPs.
- The exact settle delay is situational — the rule is "settle, then poll from
  outside", not a fixed number of seconds.

## Diagnostic signal

You're about to write a `while` / `setTimeout` loop inside a `browser_evaluate`
body, or act on the page in the same breath as navigating to it. Stop — return
immediately and poll from the shell.
