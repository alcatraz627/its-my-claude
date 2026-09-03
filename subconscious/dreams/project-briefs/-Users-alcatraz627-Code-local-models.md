<!-- i-dream project brief · 2026-09-02T05:45:59.651609+00:00 · 20 patterns / 2 insights -->
## What this project is about
Local model suite (`q`/`see`/`imagine`/`lm`) — a CLI harness for running local LLMs and image-gen on this machine. Work style is autonomous, multi-agent, and high-iteration; sessions frequently fan out sub-agents for research, auditing, and adversarial review.

## Things to do (or keep doing)
- **Dispatch an adversarial reviewer sub-agent immediately after implementing any complex feature** — it reliably catches HIGH-severity bugs the main agent misses.
- **TaskStop every sub-agent the turn its output is verified** — idle seats get commandeered by board auto-dispatchers; close the loop in the same turn.
- **Proceed autonomously through obvious sequential steps** — pause only at genuine decision forks (identity, project scope, irreversible ops); never checkpoint between steps the user can predict.
- **Re-ground synthesis against the human-authored upstream source** before writing any multi-agent research output — not against downstream agent docs.

## Things to avoid
- **Don't claim work complete without executing the changed code path** — the declared-ready gate fires on inspection claims; run the path, read the result.
- **Don't silently pick a branch on a bare "yes"** — confirm which branch the affirmative resolves before proceeding.
- **Don't let agent-generated docs become the spec** for audits or gap analyses — authority contamination flows downstream and corrupts scoped synthesis.
- **Don't mix planned and done work in a status answer** — three separate flat lists (done / in-flight / planned), not a timeline narrative.

## Open questions / known gaps
- **Scope leakage in multi-agent fan-outs** — sibling-project findings repeatedly bleed into scoped syntheses; no mechanical guard exists yet beyond re-grounding at write time.
