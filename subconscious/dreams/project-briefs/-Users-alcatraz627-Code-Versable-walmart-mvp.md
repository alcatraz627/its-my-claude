<!-- i-dream project brief · 2026-07-02T23:56:32.792149+00:00 · 6 patterns / 0 insights -->
## What this project is about
Walmart MVP feature work inside the Versable monorepo — retail/e-commerce domain. Working style is minimal-blast-radius: surgical changes, no speculative abstractions, strict git discipline enforced via repo CLAUDE.md.

## Things to do (or keep doing)
- **Read the repo's CLAUDE.md before any git operation** — it overrides default behavior; hand the user exact commands rather than running them yourself.
- **Inline simple data at the callsite** — when asked to expose a value or add a field, pass it directly; do not invent wrapper functions, status-derivation helpers, or intermediate types unless the user names them.
- **Verify `/atone` events landed on disk** after invoking the skill — confirm the write before moving on; a non-confirmed `/atone` is a no-op.
- **Surface uncertainty early** — this user judges reliability and judgment-under-ambiguity above all; asking a clarifying question is strictly better than guessing and producing plausible-but-wrong output.

## Things to avoid
- **Don't remove a working solution and re-present it as new** — if you rewrite the user's existing code to fix a problem, say so explicitly; presenting the same fix as novel after silently destroying the original is a trust-killer.
- **Don't add abstractions the user didn't request** — no status-derivation logic, no wrapper layers, no "helper for future use" on a simple component addition.
- **Don't treat a skill invocation as complete without disk confirmation** — `/atone`, `/affirm`, and similar write-to-disk skills must be verified before the turn closes.

## Open questions / known gaps
- Git push discipline has recurring violations in this repo — the CLAUDE.md gate exists for a reason; always re-read it rather than inferring from prior-session behavior.
