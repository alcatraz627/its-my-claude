<!-- i-dream project brief · 2026-07-11T18:16:06.030118+00:00 · 13 patterns / 0 insights -->
## What this project is about
Versable Builder is a professional-facing product codebase worked on with a high bar for production quality — UI changes require real browser verification, docs require human-register prose, and scope discipline is strict.

## Things to do (or keep doing)
- Always navigate to the actual URL and exercise the primary flow before claiming a UI or server-side change works — no exceptions
- Check recent git log before introducing any new mechanism for storing IDs, config values, or version pins; reinvention of recently-committed work is a critical failure
- Sequence edits to the same file serially, never in parallel — parallel Edit calls silently clobber each other
- Clarify "runtime variables" vs "deploy-time env vars" vs "on-the-fly app globals" before implementing; the user means different things

## Things to avoid
- Don't place file paths immediately before sentence-ending periods — restructure the sentence so the path is not the last token before `.`
- Don't launch expensive multi-agent workflows (magi, consensus debate) until all prerequisite research, docs, and user Q&A is complete — running them over incomplete inputs wastes tokens and produces bad output
- Don't let AI-register phrasing into customer-facing documents: no "Good news first:", no reflexive apologies, no leading-question closers, no "The User" capitalization
- Don't default to hardware/throughput metrics when the user asks for workflow-relevant augmentations — ask what utility dimension they actually care about

## Open questions / known gaps
- When doc-writing guidelines are loaded, the agent still produces AI-smell prose; the guidelines aren't reliably applied without an explicit fresh-reviewer pass
