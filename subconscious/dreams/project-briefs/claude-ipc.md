<!-- i-dream project brief · 2026-07-23T00:58:16.447772+00:00 · 20 patterns / 8 insights -->
## What this project is about
`claude-ipc` is an inter-process communication broker between Claude Code sessions. Work is coordination-heavy: message routing, delivery verification, ownership negotiation, and multi-agent task handoff.

## Things to do (or keep doing)
- Verify from the **consumer's** perspective — check delivery not send-success, observe in the user's mode not dev mode, run the path not the suite.
- Emit explicit `UNCERTAIN`/`DENY` when input is absent; never zero-default or default-ALLOW a missing lookup — absence must propagate, not collapse to a plausible value.
- Dispatch a fresh adversarial reviewer sub-agent immediately after implementing any complex feature; it reliably catches HIGH-severity bugs the main agent misses.
- When a complaint says "too noisy / too aggressive," tune intensity — don't disable; reconstruct original intent before sizing the correction.

## Things to avoid
- Don't treat proxy evidence (send-success log, test exit code, single-mode screenshot) as verification — proxy confirms the action was performed, not that the consumer experienced the outcome.
- Don't commit or push — this is a protected repo; prepare the change, show the diff, hand it to the user.
- Don't apply a partial fix when told a component must be global — audit the full codebase and fix ALL instances in the same response.
- Don't let task lists drift silently across many turns; reconcile completed/dropped items before stopping.

## Open questions / known gaps
- Multi-agent ownership negotiation has no authoritative single source — parallel agents make conflicting assumptions about who owns which task; this manifests repeatedly.
- Test pipeline caches produce false-positive verification; busting caches explicitly before claiming a code change is confirmed is not yet habitual.
