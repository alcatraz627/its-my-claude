---
brief: Before adding a raw env var read, grep how existing vars are read in the project — route through the central config module/schema if one exists, don't scatter raw reads
triggers:
  - topic:env-var
  - topic:configuration
  - phrase:"process.env"
  - phrase:"os.getenv"
  - phrase:"os.environ"
related:
  - rules/grep-scope-before-claiming-absence.md
tier: 1
category: rules
updated: 2026-05-30
stale_after_days: 90
---

# Check the project's env var pattern before adding a new read

Every project centralizes env var access in its own way: a config module, a
validated schema (zod, pydantic), or a typed wrapper. Before adding a raw env
read, grep how existing vars are read.

```bash
rg -n 'process\.env\.|os\.getenv|os\.environ' src/
```

If a central config module exists, route through it. Raw reads scattered
through modules create drift and bypass validation.

## This is usually a project-local convention

The *specific* config module is per-project — the universal part is "find the
project's pattern and follow it" rather than introducing a new access style.
When a project's `.claude/rules/` documents its own config module, that local
rule supersedes this one.

Graduated from atone slug `adding-env-var-reads-without-checking-the-project-s-config-pattern` (S3, 2×).
