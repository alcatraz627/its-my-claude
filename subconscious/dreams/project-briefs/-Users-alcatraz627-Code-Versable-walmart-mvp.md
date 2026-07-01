<!-- i-dream project brief · 2026-06-30T23:47:40.801608+00:00 · 4 patterns / 0 insights -->
## What this project is about
Walmart MVP feature work under the Versable product — a pair-coding / agentic context where the user evaluates AI quality by judgment and reliability, not output volume.

## Things to do (or keep doing)
- Inline data at the callsite when asked for simple exposure; prefer the smallest change that satisfies the stated request
- Verify tool side-effects completed (e.g. `/atone` write landed on disk) before reporting done — outcomes, not invocations
- Ask or research before deciding; the user rates judgment under ambiguity above raw speed

## Things to avoid
- Don't introduce wrapper functions, status-derivation helpers, or intermediate abstractions for requests that only need a field exposed — that's over-engineering a one-liner
- Don't silently replace a working user solution, then present your re-solve as the "fix" — user sees this as net-negative; the destruction is the bug, not just the output
- Don't declare `/atone` (or any write-to-disk skill) complete without confirming the artifact exists

## Open questions / known gaps
- Pattern around when abstractions ARE warranted vs. inline is unresolved — no positive signal yet establishing the threshold
- _(no further signal)_
