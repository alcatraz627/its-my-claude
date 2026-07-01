<!-- i-dream project brief · 2026-06-30T23:48:58.006672+00:00 · 20 patterns / 0 insights -->
## What this project is about
A product-facing enhancement layer (Versable) where sessions alternate between research/design phases and scoped implementation. Work is iterative, scope-controlled, and doc-heavy.

## Things to do (or keep doing)
- Replicate the exact existing pattern when the user says "do it the same way as X" — read that implementation before writing anything new
- Translate research/design output into a lean, behavior-focused implementation doc before implementation begins; never leave raw synthesis as the deliverable
- Check existing code for a working solution before building new infrastructure; grep first, abstract only if nothing fits
- Confirm push explicitly per push — "let's push this" is not blanket approval for subsequent pushes

## Things to avoid
- Don't invert opt-in semantics: "opt-in" means default includes everything; the opt-in signal excludes, never the reverse — verbal acknowledgment of the right polarity doesn't guarantee the code matches
- Don't re-introduce deleted or deferred complexity under a new name; if the user removed it and asked for simpler, the discarded version is off the table
- Don't add intermediate abstractions, wrapper functions, or status-derivation logic for a simple data-access or display request; users discard the entire output when scope ceiling is breached
- Don't write human-facing prose (PR descriptions, docs) with em-dashes, "Why this matters" openers, or promotional framing — formal, direct, factually grounded only

## Open questions / known gaps
- Repeated verbal-acknowledgment-but-inverted-implementation gap: the agent says the right polarity aloud then codes the opposite — a pre-write check ("what is the default state?") is not yet habitual here
- atone RCA YAML frontmatter requirement (`---` on line 1) keeps causing event-log failures; the lint gate exists but gets bypassed during rushed S3 recording
