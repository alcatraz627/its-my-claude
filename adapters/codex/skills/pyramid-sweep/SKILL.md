---
name: pyramid-sweep
description: Mine a large local corpus for a small set of valuable survivors with cheap extraction, calibrated broad classification, independent sampling, and a human decision surface. Use only when breadth is the real bottleneck.
---

# Pyramid sweep in Codex

Read `/Users/alcatraz627/.claude/skills/pyramid-sweep/SKILL.md` for its phase gates and the measured failure of the warm classifier. The source skill's vocabulary labels and scripts are specific to that prior run; select extraction, labels, and success criteria for the current corpus.

Before a run, record corpus size, expected survivor count, spend ceiling, known positives and negatives, sample size, and stop rule. Inventory and extract mechanically. Use `lm gemini` only for a broad, low-judgment, context-heavy pass whose output can be checked cheaply. Give it a bounded prompt and output schema, then inspect a stratified sample and all consequential survivors against the source. A clean planted control set alone does not qualify the lane. Escalate only the survivors requiring judgment. Persist the manifest, prompts, samples, gate results, and decisions under the project. The main agent owns final synthesis and any canonical write.
