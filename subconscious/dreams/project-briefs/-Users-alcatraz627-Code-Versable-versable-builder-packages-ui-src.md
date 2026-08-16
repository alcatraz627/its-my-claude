<!-- i-dream project brief · 2026-08-13T00:28:09.037096+00:00 · 8 patterns / 0 insights -->
## What this project is about
UI package work (`packages/ui/src`) inside a monorepo (versable-builder). Work style is iterative, review-heavy, and cost-conscious — the user scrutinizes output volume and agent overhead closely.

## Things to do (or keep doing)
- **Right-size findings and sub-agents** to the question asked; one targeted answer beats an enumerated process with 8 bullets.
- **State the point first** — lead every reply with the direct answer, not preamble or context-setting.
- **Split model tiers on multi-stage pipelines** — cheaper models for bulk/collection steps, capable models only for analysis.
- **Run skeptical/adversarial review passes** when given latitude; concrete bug catches build trust and earn repeat requests.

## Things to avoid
- **Don't regenerate AI-smell prose after a hook fires** — em-dashes and bold-spam in a rewrite are a repeat offense, not a fix.
- **Don't produce structured self-critical replies under pushback** — a numbered RCA without running the checks first reads as performance, not correction.
- **Don't fan out agents without a cost estimate** when the user has flagged a remaining quota; offer an explicit go/no-go instead.
- **Don't treat zero pipeline output as success** — investigate filter/source misconfiguration before moving to the next stage.

## Open questions / known gaps
- Token budget awareness is inconsistent: the user has flagged quota concerns but the agent hasn't reliably surfaced cost estimates before fan-outs.
