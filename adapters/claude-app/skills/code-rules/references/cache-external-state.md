# Do not cache state that someone else can change

A cache is safe only when you control every writer of the cached value. If
anything outside your process can change it (another CLI, a daemon, a sibling
service, the user), then any TTL longer than "right now" is a staleness bug.
It shows up as a value that is plausible but wrong, the hardest kind to
debug.

## Example

A browser extension cached a local model server's availability for 30
seconds. A separate command-line tool switched the model between warm and
cold out of band. So the extension showed "cold" for up to 30 seconds after
the model went warm. The fix was to delete the cache. A shorter TTL would
not have helped. The status call took about 40ms, so the cache bought nothing
and cost correctness.

## The rule

Before adding any cache, memo or TTL, ask who can write the underlying value.

1. **Only this process, deterministically.** Caching is safe. Pick a TTL.
2. **Anything else.** Do not cache with a TTL. In order of preference:
   - read it live every time (measure first, the call is often cheap)
   - subscribe to a change event and cache only between events
   - cache with invalidation that every writer triggers, which works only if
     you truly control all the writers, and you usually do not

## The smell

`if (now - cachedAt < TTL) return cached;` for a value that reflects
something you do not exclusively own: availability, warmth, connection
status, a remote's health, a file another tool rewrites. That TTL is a bet
that nothing changed in the window, and you lose it silently.

## What this does not mean

- Caching a pure computation (a hash, a parse, a format) is fine. You own the
  inputs, and they fully determine the output.
- Caching immutable remote data (a content-addressed blob, a versioned
  artifact) is fine. It cannot change under a fixed key.
- The rule covers externally mutable state, not all I/O.

## Diagnostic

The cached thing is a status, availability or liveness value, and some actor
other than you changes it. Read it live, or invalidate on the real event.
