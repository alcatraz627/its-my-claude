---
brief: Code marked NOTE(by human), HACK, or IMPORTANT is a deliberate, tested choice: never override it silently; ask first with reasoning, then verify the result. Looking wrong without context is not evidence it is wrong.
triggers:
  - topic:comments
  - phrase:"NOTE(by human)"
  - phrase:"HACK"
related:
  - rules/testing.md
  - rules/comments.md
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 180
---

# Don't override `NOTE(by human)` preferences silently

Code with `NOTE(by human)`, `HACK`, `IMPORTANT`, or similar human-attribution comments marks a deliberate, tested choice. **Never override silently.** Ask first with reasoning, get approval, then verify the result visually/functionally. The fact that the code "looks wrong" without context is not evidence it's actually wrong — the comment is the context. Graduated from atone `overriding-user-commented-preferences` (S3). See also `rules/testing.md` § "Human-commented values".

A halt under this rule needs a genuinely missing thing — information no derivation supplies, or authority not yet granted. Holding both, the rule does not apply: act (`never-halt-on-authority-you-hold.md`).
