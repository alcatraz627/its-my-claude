---
brief: A browser MCP shares one profile across every agent AND across sessions — give each sub-agent an isolated context/profile, or logins, cookies and navigations bleed between them; screenshots need absolute paths or they vanish.
triggers:
  - topic:browser-automation
  - topic:playwright
  - topic:browser-mcp
  - topic:concurrent-validators
  - phrase:"isolatedContext"
  - phrase:"browser profile"
related:
  - rules/browser-mcp-async-eval.md
  - rules/contain-subagent-token-sprawl.md
  - features/dev-servers.md
paths:
  # autoload opt-out: browser-MCP work is <20% of sessions, so this is on-demand
  # (Tier 2) — read from rules/00-index.md when dispatching agents at a browser.
  # Sentinel never matches a real file; revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-07-16
stale_after_days: 365
---

# Browser MCP: one profile, many agents — isolate or it bleeds

A browser MCP server hands every caller the same browser with the same profile.
That profile is shared **on two axes**, and both have drawn blood:

- **Across concurrent agents.** Two validators plus a main session sharing one
  Playwright instance cross-contaminated: a validator observed foreign
  theme-change navigations in its own sandbox history, and the instance later
  wedged with navigations timing out for hours (ghostty-themes m6-validator,
  2026-07-12).
- **Across sessions, over time.** A session's first `navigate` arrived at a page
  **already logged in as a test account from a previous session's run** — no
  concurrency involved at all, just a profile that never got cleaned
  (vb-fable, 2026-07-16). Logins and cookies time-travel.

A fix that only isolates concurrent contexts leaves the second axis open, and the
symptom (state you did not create) looks identical from inside.

## The rule

1. **Any sub-agent driving a browser MCP gets its own isolated context** —
   `isolatedContext`, a per-agent profile dir, or a separate CDP target. Never let
   two agents share one profile because "they run at different times."
2. **Treat the profile as shared mutable state with a lifetime**, not as scratch.
   If a run's state must not leak into the next one, the profile is per-run, not
   per-machine.
3. **Screenshots take absolute paths.** A relative filename resolves against the
   MCP server's cwd, not yours: the file lands somewhere you are not looking and
   the call still reports success. Silent, and it has cost two debugging rounds.
4. **A wedged instance is expected, not exceptional.** Validator prompt
   boilerplate should say what to do: close the page, restart the MCP server, and
   if navigations still time out, clear the profile dir. Do not spend an hour
   treating a wedge as a product bug.

## In the dispatch prompt

Same boilerplate slot as the scope-close clause in [[contain-subagent-token-sprawl]]
and the nesting-leak clause in [[model-tier-routing]] — one sentence each, write
them together:

> "Use an isolated browser context (or your own profile dir). Screenshots: absolute
> paths only. If navigations start timing out, the instance is wedged — close the
> page and restart the MCP rather than debugging the app."

## The proven local pattern

Per-agent isolation of shared mutable state is already how this account fixed the
same class of bug elsewhere: two agents' dev servers racing **one** vite optimizer
cache wedged browsers with `504 Outdated Optimize Dep` until each server got its
own cache dir (`SPEEDWAY_VITE_CACHE_DIR`). Browser profiles are the same shape —
one mutable store, several writers, no arbitration. Reach for the same fix.

## What this rule does NOT mean

- Not "never share a browser". One agent driving one browser serially is fine —
  that configuration produced no wedges in a full day of heavy use.
- Not a mandate to isolate every MCP. This is about servers holding **persistent
  mutable state** (a profile, a cache, a session). A stateless MCP has no bleed.
- Not the timing rule. Blocking evals and post-navigate races are
  [[browser-mcp-async-eval]] — different failure, different fix.

## Diagnostic signal

You are about to dispatch more than one agent at a browser MCP without naming an
isolation mechanism; or you are looking at page state (a login, a navigation, a
cookie) that nothing in this session created and reaching for a product
explanation. Suspect the profile first.

## Provenance

`prop-20260713-080337-05` (m6-validator cross-contamination + wedge), widened by
vb-fable's field report 2026-07-16 (cross-session profile bleed, the vite-cache
precedent, and the absolute-path screenshot trap). Serial-use evidence from the
same report supports attributing the wedge to concurrency.
