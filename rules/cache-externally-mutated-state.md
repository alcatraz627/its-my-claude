---
brief: Never cache or TTL a status, availability or liveness value that an external writer (another CLI, daemon, sibling service, the user) can change. Read it live or invalidate on the real event, because a TTL on externally-mutated state is a plausible-but-wrong staleness bug. Read this rule before adding any cache, memoization or TTL.
triggers:
  - topic:caching
  - topic:stale-state
  - phrase:"availability cache"
  - phrase:"cache the status"
related:
  - rules/testing.md
  - rules/error-classification.md
paths:
  # autoload opt-out (2026-07-09 demotion pass): only fires when writing caching/TTL
  # logic; failure mode is a testable correctness bug, not irreversible. Read on
  # demand from rules/00-index.md. Sentinel never matches a real file; revert by
  # deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-07-09
stale_after_days: 365
---

# Don't cache state an external writer can mutate

A cache is only safe when **you control every writer** of the cached value. If
something outside your process can change the underlying state (another CLI, a
daemon, a sibling service, the user), then any TTL longer than "right now" is a
**staleness bug waiting to surface**. It will surface as a value that is
*plausible but wrong*, the worst kind to debug.

Graduated from the better-file-browser incident (2026-06-13). A Chrome extension
cached `lm` availability for 30s. `lm warm on` is an **invisible external
writer** that flips warm and cold out of band, so the cache showed "cold" seconds
after the model went warm. The fix was to **delete the
cache**, and a shorter TTL would not have helped. The status call took about 40ms, so the cache "bought nothing and cost
correctness".

## The rule

Before adding any cache, memoization or TTL, ask: **who can write the underlying
value?**

1. **Only this process, deterministically.** Caching is safe, so pick a TTL.
2. **Anything else can change it** (another process, a daemon, a remote, the
   user, a `warm on`-style side-channel). **Do not cache with a TTL.** Options,
   in order of preference:
   - read it live each time (often the call is cheap, so measure before assuming
     it is worth caching);
   - subscribe to a change event or invalidation signal and cache only between
     signals;
   - cache with explicit invalidation that *every* writer triggers (viable only
     if you genuinely control all writers, which you usually don't).

## The smell

You wrote `if (now - cachedAt < TTL) return cached;` for a value that reflects
**the state of something you don't exclusively own**: availability, warmth,
connection status, a remote's health, or a file another tool rewrites. That TTL is
a bet that nothing external changed in the window, and you will lose it silently.

## What this rule does NOT mean

- Caching pure or derived computation (hash, parse, format) is fine, because the inputs
  fully determine the output and you own them.
- Caching genuinely immutable remote data (a content-addressed blob, a versioned
  artifact) is fine, because it can't change under a fixed key.
- The rule is about **externally-mutable** state and does not cover all I/O.

## Diagnostic signal

The cached thing is a *status, availability or liveness* value, and a command or actor other than you
changes it. Read it live, or invalidate on
the actual event, and don't TTL it.
