<!-- i-dream project brief · 2026-06-18T22:49:28.840773+00:00 · 19 patterns / 0 insights -->
## What this project is about
A Chrome extension providing a better file browser UI, likely with a model-availability status layer (warm/cold toggle). Work style is feature-implementation with emphasis on correctness over speed.

## Things to do (or keep doing)
- **Plan before implementing** any hand-rolled UI component; review existing design patterns first, never one-shot non-trivial custom UI
- **Render-check all markdown tables** before presenting for review; format issues are common and invisible until rendered
- **Write guideline updates back to their canonical file** immediately — leaving convention changes only in conversation loses them on `/clear`
- **Deliver the primary goal first**; surface bonus work only after the stated deliverable is complete

## Things to avoid
- **Don't cache model availability with a TTL** — the warm/cold state is externally mutable (`lm warm on`), so any TTL produces stale UI; read it live instead
- **Don't place scratch or checkpoint files in the project root** — Chrome extension loads the directory as a package; stray files cause load failures
- **Don't use flowery, promotional, or marketing-style prose in docs** — the user explicitly rejects "why this matters" framing, hyperbolic adjectives, and pitch-style language; use formal, direct, plain sentences
- **Don't skip or defer `/atone` when invoked** — execute immediately and in full; RCA files must start with `---` YAML frontmatter on line 1 or the gate rejects the event silently

## Open questions / known gaps
- Recurring documentation tone violations suggest the agent defaults to a promotional voice under pressure to explain value — may need explicit tone check before finalizing any doc
