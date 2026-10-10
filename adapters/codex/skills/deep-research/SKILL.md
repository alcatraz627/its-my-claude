---
name: deep-research
description: Research a consequential external question by testing its load-bearing claims against primary evidence, independent sources, and a hostile verification pass. Use when one lookup cannot settle the question.
---

# Deep research in Codex

Read `/Users/alcatraz627/.claude/skills/deep-research/SKILL.md` for the maintained contract. Use Codex web tools in place of Claude WebSearch/WebFetch. Source claims near each assertion and keep publish dates separate from event dates.

Frame the question as testable claims. Name scope: quick for a narrow question, standard for several consequential claims, exhaustive only when a second evidence round can change the answer. Decline this workflow for one source lookup, local code inspection, or pure taste.

At standard or exhaustive scope, use independent research seats only when parallel investigation will save work. Pin their model, prohibit nested delegation, require an absolute persisted finding path, and tell each to stop when its claim is done. Verify load-bearing claims against an independent primary source or a separate hostile seat; report contradictions and unverified claims. The main Codex agent writes the synthesis and a timestamped report in the current project's `.claude/output/`. Do not import the Claude skill's model names or run `skill-log.sh` directly from Codex.
