<!-- i-dream project brief · 2026-07-02T23:57:20.630055+00:00 · 20 patterns / 0 insights -->
## What this project is about
Versable enhancement product — a full-stack web product. Work style is incremental feature development with strict scope ceilings; the user discards entire outputs when complexity exceeds what was asked.

## Things to do (or keep doing)
- **Prefer existing implementations**: before writing any new helper, data-fetch, or abstraction, grep for what already handles it and extend that
- **Match the exact pattern the user points to**: when user says "same way you do X", replicate X verbatim — do not introduce a new approach
- **Translate research/design into lean, product-focused implementation docs**: professional and behavioral, not academic or enterprise-heavy; no "Why this matters" openers
- **Confirm per-push before any `git push`**: one approval is never blanket; if CLAUDE.md says hand the user the exact commands, do exactly that

## Things to avoid
- **Don't invert opt-in semantics in code**: if the user says "opt-in", the default is include-all and exclusion requires an explicit signal — never implement the reverse even if you verbally agreed correctly
- **Stop touching adjacent code when scoped to one thing**: simplifying one component means only that component; do not reinvent neighbors or add unrequested patterns
- **Never re-introduce deferred or deleted scope**: if the user removed complexity and asked for simpler, it is gone — do not re-add it under a different implementation
- **Strip em-dashes and AI-smell from all human-facing prose**: docs, PR descriptions, commit messages — no `—`, no bold-spam bullets, no promotional framing

## Open questions / known gaps
- **Verbal acknowledgment vs implementation**: agent repeatedly says the right thing ("opt-in") then codes the inverse — treat this as a known blind spot and verify code semantics against stated intent before submitting
