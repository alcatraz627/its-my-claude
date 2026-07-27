<!-- i-dream project brief · 2026-07-23T00:56:56.270278+00:00 · 8 patterns / 1 insights -->
## What this project is about
Versable enhancement-product: a deployed web app with ongoing feature work, runtime config, UI logging, and third-party service integrations. Work style is iterative with explicit stash-based pivots and a deferred-review queue.

## Things to do (or keep doing)
- **Always deliver runtime config as a pair**: storage/retrieval mechanism + frontend admin UI in the same change — user treats these as one unit.
- **Verify third-party integrations via the vendor's own dashboard**, not internal admin tabs or agent-built check pages — that's the evidence that counts.
- **Park completed non-critical work in the "to be reviewed later" queue** rather than requesting immediate review; only surface it when the user explicitly asks.
- **Use `git stash` for mid-session pivots** away from partially-staged work — never commit or discard it.

## Things to avoid
- **Don't conflate runtime config with env config** — feature flags / runtime-adjustable globals belong in a separate runtime config system, not backend env.
- **Don't write AI-register commit messages or PR descriptions** — user audits these with a style tool; keep them concise and human-sounding.
- **Don't log PII in UI-side events** — structural-event-only logging is a hard constraint, not a default.
- **Don't overshoot corrections** — reconstruct the original intent before applying a fix; the complaint names the symptom, not the blast radius.

## Open questions / known gaps
- No established signal yet on how the GitHub Actions workflows in this directory relate to the main app delivery loop — clarify before touching `.github/workflows/`.
