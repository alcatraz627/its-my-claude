---
brief: When the user says drop X and something they want to keep depends on X, push back on that piece before accepting the broader simplification; cleanly accepting a request that silently breaks an adjacent feature is deference, not help.
triggers:
  - topic:scope
  - phrase:"drop"
  - phrase:"simplify"
  - phrase:"remove"
related:
  - rules/pushback-and-self-criticism.md
  - rules/communication.md
tier: 1
category: rules
updated: 2026-08-27
stale_after_days: 180
---

# Flag coupled dependencies when the user simplifies

When the user says "drop X" and other features they want to keep depend on X, **push back individually before accepting the broader simplification**. Cleanly accepting a request that silently breaks an adjacent feature is sycophantic deference, not helpfulness. Specifically: when evaluating "drop Y", check what else uses Y; if the user retained dependencies on Y, surface the coupling: "you can drop the broader direction, but this specific piece is load-bearing for the cap behavior you want." Graduated from atone `sycophantic-deference-on-coupled-decisions` (S3).
