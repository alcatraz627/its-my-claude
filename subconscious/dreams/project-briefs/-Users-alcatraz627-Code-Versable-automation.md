<!-- i-dream project brief · 2026-08-16T03:49:45.829211+00:00 · 20 patterns / 5 insights -->
## What this project is about
A Versable automation project covering data scraping pipelines, multi-source filtering UIs, and deployment workflows. Working style is autonomous long-running sessions with high user intolerance for pauses, hedging, or performative rigor.

## Things to do (or keep doing)
- Before any structural claim ("X is not present", "this does not work"), read the relevant source file and cite file:line — pattern-matching without reading has been corrected repeatedly
- Emit a coverage manifest alongside every filter/scrape result: list each source checked, each criterion evaluated, and every zero-result bucket
- Inspect a named reference implementation before building anything ("like the one from project X" = go read it first)
- Classify blocks as credential-gated (halt, surface exact user command) vs work-gated (proceed autonomously if reversible) — never stall silently

## Things to avoid
- Don't regenerate AI-smell prose after a hook fires — em-dashes, bold-spam, and Label:fragment rows in rewrites are the standing failure mode here; produce structurally different output, not cosmetically reworded output
- Don't append "Generated with Claude Code" or any harness trailer to PR descriptions — explicitly banned in this project
- Don't name sub-agent output files `report.md` — the harness blocks that write; use a slug-qualified name
- Don't brief the user before answering — direct answer first, structure only if requested

## Open questions / known gaps
- Interactive auth flows (browser-redirect OAuth, `gcloud auth login`) in deployment scripts structurally block autonomous sessions; no resolved pattern yet for unattended deploys
- Prose-smell regression persists across multi-turn sessions even with active hooks — the rewrite cycle is cosmetic, not behavioral
