<!-- i-dream project brief · 2026-07-29T00:35:25.595771+00:00 · 20 patterns / 7 insights -->
## What this project is about
Cross-session IPC broker for Claude Code — routes messages between live and dead sessions, manages peer discovery, and enforces delivery guarantees. Primary working style: correctness-first CLI tooling with strong gate/deny semantics.

## Things to do (or keep doing)
- **Treat send-success as proxy evidence only** — always verify the message was actually received, not just enqueued or accepted by the broker
- **Emit DENY/UNCERTAIN on absent input** — when a peer is unknown, a session is dead, or a lookup returns empty, the gate must deny/flag, never default-allow or synthesize a zero-equivalent
- **Dogfood live** — the 99+ test suite misses delivery bugs that exercising the actual IPC path catches; run it against real sessions before claiming a fix works
- **When a sub-agent hits an auth or credential block, surface the exact command** and hold — never attempt self-rescue or silently skip

## Things to avoid
- **Don't treat absence of a session as ALLOW** — missing, unrecognized, or timed-out peers must be flagged, not routed through with a permissive default
- **Don't fix one instance of a class-level bug** — if a gate, a naming scheme, or a delivery path has the same flaw in multiple places, fix all of them in one pass or explicitly enumerate what was left
- **Don't commit or push without user hand-off** — this repo is in the protected registry; prepare the diff and stop
- **Don't tune a noisy behavior to zero** — "too aggressive" means reduce intensity, not disable

## Open questions / known gaps
- Delivery confirmation channel is structurally ambiguous — send-success and actual receipt conflated in at least one recurring pattern; needs explicit receipt-ACK or dead-letter path
- Stale session detection relies on heartbeat recency, but old mail in dead sessions (32+ orphans noted) suggests the reap/revive boundary isn't consistently enforced
