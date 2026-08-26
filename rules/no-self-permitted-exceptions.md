---
brief: When a request touches a surface an ADR or hard rule protects, never invent a test-only, temporary, or dev-convenience exception the rule does not contain; stop and ask for an explicit carve-out or a non-violating path. Self-permitted exceptions become permanent surface area.
triggers:
  - topic:adr
  - topic:exceptions
  - phrase:"just for testing"
  - phrase:"temporary"
related:
  - rules/audit-file-character-before-applying-global-rule.md
tier: 1
category: rules
updated: 2026-08-27
stale_after_days: 180
---

# Don't invent "test-only / dev-convenience" exceptions to hard rules

When the user asks for something that touches a surface an ADR or hard architectural rule says not to touch, **do NOT invent a "test-only" / "temporary" / "dev-convenience" exception** that the rule doesn't contain. Stop and ask the user for either (a) an explicit carve-out, or (b) a non-violating path. Self-permitting exceptions become permanent surface area; the next agent finds the exception and broadens it. Graduated from atone `self-permitting-exception-to-an-adr-hard-rule` (S3).
