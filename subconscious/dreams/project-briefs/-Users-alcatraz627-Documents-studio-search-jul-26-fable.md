<!-- i-dream project brief · 2026-08-19T22:33:53.882060+00:00 · 20 patterns / 7 insights -->
## What this project is about
A multi-source job/talent search aggregation platform with filtering UI and data pipelines. Working style is adversarial peer-review: two agents produce independent plans, then grade each other — convergence comes after, not before.

## Things to do (or keep doing)
- Always present parallel plans or options at equal depth side-by-side before any merge or synthesis step; the user needs the full option space first
- Always annotate assessments (gap tables, filter reports, pipeline results) with the exact observation boundary — which files read, which modes tested, which endpoints hit
- Always enumerate other consumers before claiming or modifying any shared resource (browser session, UI component, codebase region, established pattern)
- When blocked by an external constraint (auth wall, harness guard, credential scope), surface the exact unblocking action for the owner — never attempt workarounds

## Things to avoid
- Don't re-raise topics the user has deferred or skipped more than twice without explicit invitation; three skips is a final no
- Don't sub-agent output to a file named `report.md` — the harness blocks this write; always use a non-reserved name
- Don't substitute a curated subset in your reply when the user asked for the full result set
- Don't claim done without exercising the changed path; the declared-ready hook fires repeatedly here — treat every firing as a real block

## Open questions / known gaps
- Prose-smell correction is not durable: em-dashes and bold spans re-emerge in the very next reply after hook correction; needs a mechanical post-generation check, not just intent
- Deferred-review queue accumulates across turns and is lost on session end; no durable persistence exists for it yet
