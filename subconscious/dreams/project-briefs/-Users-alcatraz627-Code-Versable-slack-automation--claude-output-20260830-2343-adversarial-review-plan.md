<!-- i-dream project brief · 2026-08-30T20:50:11.368628+00:00 · 7 patterns / 0 insights -->
## What this project is about
Slack automation tooling for a Versable developer context; work centers on adversarial review plans, production incident RCAs, and multi-agent research synthesis with strict output hygiene.

## Things to do (or keep doing)
- **TaskStop verified seats immediately** — once a sub-agent output file is confirmed on disk, stop the seat in the same turn; idle seats get commandeered
- **Read prior output files before re-dispatching** — if research landed on disk earlier this session, read it first; re-running completed work wastes tokens and confuses synthesis
- **Run adversarial review before defending a plan** — when the user signals doubt about whether a plan will help, review it adversarially rather than justify it
- **Execute obvious continuation steps without confirmation** — once the user signals they don't want to approve each next step, treat clearly-next actions as pre-approved within scope

## Things to avoid
- **Don't mix planned vs. done work in status answers** — the user wants three flat lists (done / in-progress / planned), not a timeline narrative with task IDs in prose
- **Don't synthesize across projects** — when writing a multi-agent findings synthesis, verify you are writing about the project the user asked about, not a neighbor project
- **Don't write word-salad RCAs** — incident post-mortems must be terse plain prose with meaningful context before any code or PR references; reject structured noise

## Open questions / known gaps
- **Status reporting format is repeatedly wrong** — the correct shape (three flat lists) keeps not landing; future sessions should render status in that format by default without waiting for correction
