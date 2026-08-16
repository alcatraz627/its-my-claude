<!-- i-dream project brief · 2026-08-16T03:50:11.974420+00:00 · 20 patterns / 10 insights -->
## What this project is about
Versable Builder is a full-stack web application (Next.js/React frontend, backend services) with multi-agent coordination via IPC. Work is UI-heavy with frequent parallel sub-agent sessions.

## Things to do (or keep doing)
- **Audit all pages before touching any shared UI shell component** (sidebar, drawer, modal): implement once globally, never per-page variants
- **Verify fixes on the running dev server** before claiming done — exercise the actual code path, not just the edit; "it looks right" is not verification
- **Default-DENY for all access gates**: unrecognized commands/CLIs must be blocked, never passed through
- **Show diff + plain-English effect before any permission prompt**; this is a protected repo — prepare the change, never commit or push

## Things to avoid
- **Don't emit AI-smell prose** (em-dashes, excessive bold, label:fragment rows) — the stop-hook will fire and re-emission with the same tells wastes cycles; emit mechanically different output after any prose correction
- **Don't treat send-success as delivery** in IPC flows — wait for an actual round-trip reply from the peer before claiming a message was received
- **Don't re-raise deferred topics** the user has skipped three or more times without explicit re-invitation
- **Don't include internal banter or stakeholder commentary** in any document that may be shared externally — strip it before writing the file

## Open questions / known gaps
- State-sync degrades under parallelism (task lists drift, ownership conflicts, stale branch state) — no reliable resolution pattern established yet; manual reconciliation required after burst sessions
- Proxy evidence (test-pass, class-name match, advisory doc) is repeatedly mistaken for direct verification — the gap between "check ran" and "outcome confirmed" keeps surfacing across domains
