---
brief: How gcc scripts read environment variables, and why they have no central config module
triggers:
  - topic:env-access
  - phrase:"env var"
related:
  - rules/env-var-config-pattern.md
  - features/env-access-convention-hook.md
tier: 2
category: conventions
updated: 2026-11-02
stale_after_days: 180
---

# Environment variables in gcc scripts

A gcc script reads each setting directly from the environment, with its default beside it, in one block near the top of the file:

```python
KEEPWARM_DIR = os.environ.get("KEEPWARM_DIR", os.path.join(HOME, ".claude", "keepwarm"))
CADENCE_MIN = int(os.environ.get("KEEPWARM_CADENCE_MIN", "20"))
```

These scripts are small, standalone tools that hooks run in a fresh process, so a shared config module would add an import that can fail on every prompt, for no reader that needs it. About 80 Python scripts here already work this way. The variables exist mostly so a test can point a script at a throwaway folder.

- Name a variable after its tool (`KEEPWARM_`, `USAGE5H_`), so two tools never collide.
- Never read a secret this way. Tokens come through `with-token` (`rules/shell.md`).
- A project with its own config module follows that module instead (`rules/env-var-config-pattern.md`).
