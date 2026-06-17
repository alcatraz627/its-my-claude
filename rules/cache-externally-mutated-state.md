---
brief: Don't cache a value that something outside your process can change — a TTL longer than "now" on externally-mutated state is a staleness bug.
triggers:
  - topic:caching
  - topic:stale-state
  - phrase:"availability cache"
  - phrase:"cache the status"
related:
  - rules/testing.md
  - rules/error-classification.md
tier: 2
category: rules
updated: 2026-06-15
stale_after_days: 365
---

# Don't cache state an external writer can mutate

A cache is only safe when **you control every writer** of the cached value. If
something outside your process can change the underlying state — another CLI, a
daemon, a sibling service, the user — then any TTL longer than "right now" is a
**staleness bug waiting to surface**, and it will surface as a value that is
*plausible but wrong* (the worst kind to debug).

Graduated from the better-file-browser incident (2026-06-13): a Chrome extension
cached `lm` availability for 30s. `lm warm on` is an **invisible external
writer** — it flips warm/cold out of band — so the cache showed "cold" seconds
after the model went warm. The fix was not a shorter TTL; it was **deleting the
cache** (the status call was ~40ms — the cache "bought nothing and cost
correctness").

## The rule

Before adding any cache / memoization / TTL, ask: **who can write the underlying
value?**

1. **Only this process, deterministically** → caching is safe; pick a TTL.
2. **Anything else can change it** (another process, a daemon, a remote, the
   user, a `warm on`-style side-channel) → **do not cache with a TTL.** Options,
   in order of preference:
   - read it live each time (often the call is cheap — measure before assuming
     it's worth caching);
   - subscribe to a change event / invalidation signal and cache only between
     signals;
   - cache with explicit invalidation that *every* writer triggers (only viable
     if you genuinely control all writers — usually you don't).

## The smell

You wrote `if (now - cachedAt < TTL) return cached;` for a value that reflects
**the state of something you don't exclusively own** — availability, warmth,
connection status, a remote's health, a file another tool rewrites. That TTL is
a bet that nothing external changed in the window, and you will lose it silently.

## What this rule does NOT mean

- Caching pure/derived computation (hash, parse, format) is fine — the inputs
  fully determine the output and you own them.
- Caching genuinely immutable remote data (a content-addressed blob, a versioned
  artifact) is fine — it can't change under a fixed key.
- The rule is about **externally-mutable** state, not all I/O.

## Diagnostic signal

The cached thing is a *status / availability / liveness* value, and there exists
a command or actor — not you — that changes it. Read it live, or invalidate on
the actual event; don't TTL it.
