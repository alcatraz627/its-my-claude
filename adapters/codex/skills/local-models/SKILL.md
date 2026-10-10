---
name: local-models
description: Use this machine's lm CLI for local model answers, vision, UI evidence, code review, batch work, or Gemini broad-context sweeps.
---

# Local models for Codex

`lm` is on PATH. Read `/Users/alcatraz627/Code/local-models/docs/STATE.md` for current model state and `docs/CAPABILITIES.md` there for detailed examples. Run the relevant command's `-h` before relying on an option. Use `lm gemini`, never the bare `gemini` binary.

| Need | First command | Evidence boundary |
|---|---|---|
| Quick local answer or format | `q "question" --json` | Verify facts against source. |
| Image structure or UI inventory | `see image.png --ui --json` | Read the rendered image yourself before a UI claim; use `see --ocr` for exact text. |
| Screenshot comparison | `see diff A.png B.png --json` | The evidence pack measures differences; a human or Codex judges their meaning. |
| Enumerable UI claim | `lm ui-verify image.png "claim" --json` | `unsure` is not a pass; a screenshot is still required for visual judgment. |
| Code review lead | `review path --findings` | Verify each surviving finding at its file and line. |
| One question across many files | `lm fleet <intent> <files...> --json` | Default gate checks only a valid nonempty response. Add `--judge` or sample results against source. Qualify `-m sweep` on representative items. |
| Broad, low-judgment corpus sweep | `lm gemini --json "question"`; `ingest` then `ask` for a project session | Send a scoped corpus, precise output fields, and validation criteria. Verify a targeted sample of source-linked claims and likely omissions. Keep final judgment here. |

The owner has authorized local models and Gemini for general use. Reach for Gemini when a task needs a broad, low-judgment, context-heavy sweep that is cheaper than doing the sweep in the main agent. Prepare the prompt and validation criteria first. A path-only inventory is a good first pass; use curated files for deeper reads. Check representative outputs and likely failure cases against source. If validation would redo most of the work, use Codex or a direct sub-agent. Never send credentials or unreviewed secret-bearing inputs.

Codex's sandbox may block the wrapper's history/session writes and Gemini network access. Diagnose the returned error and use the normal approval path for an authorized outside-sandbox call. Never route around a rejection. If Gemini is unavailable, report that and use a suitable local or Codex fallback. The wrapper selects its default model; do not silently switch models.

For code changes, Codex owns edits and runtime verification. Model results, a fleet gate pass, and a static lint are each narrower than a behavior claim.
