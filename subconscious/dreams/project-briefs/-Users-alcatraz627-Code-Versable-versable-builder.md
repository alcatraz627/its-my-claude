<!-- i-dream project brief · 2026-08-19T22:34:15.491155+00:00 · 20 patterns / 10 insights -->
## What this project is about
A multi-page React/Next.js product builder (versable-builder) with complex shared UI shell components, multi-agent coordination, and external-facing documents; work style is iterative with high UI verification bar and parallel sub-agent use.

## Things to do (or keep doing)
- Before implementing any sidebar/drawer/modal, audit ALL pages that use the same component — never build per-page variants of a shared shell
- Verify fixes on the actual running dev server and read the rendered output; send-side success and test-pass are proxy signals, not confirmation
- Identify the receiver when posting to GitHub under the user's account — always mark agent-generated content explicitly
- Pre-negotiate task ownership via IPC before launching parallel agents; batch-sync state after any burst of parallel completions

## Things to avoid
- Don't claim a UI sub-issue fixed without verifying the full rendered containing element — adjacent problems survive partial fixes
- Don't re-raise topics the user has deferred or ignored three or more times without explicit re-invitation
- Don't route decisions to the user as numbered chat lists; use `/decision-wizard` for any batch of owner choices
- Don't emit em-dashes or excessive bold spans in prose — the stop-hook fires repeatedly on this and the correction doesn't stick without a mechanical re-check before sending

## Open questions / known gaps
- Generative prose priors (AI-smell tells) re-insert themselves after in-session correction; a mechanical post-generation scan is needed but not yet wired
- Parallelism degrades all bookkeeping simultaneously; no structured sync checkpoint is enforced after sub-agent bursts
