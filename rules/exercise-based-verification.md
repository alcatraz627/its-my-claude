---
brief: Run the code in the state that matters before declaring done — collecting/compiling/linting is not running. Enforced by the declared-ready Stop hook.
triggers:
  - topic:verification
  - topic:declared-ready
  - phrase:"all tests passing"
  - phrase:"it works now"
  - tool:guard-declared-ready
related:
  - rules/testing.md
  - features/declared-ready-stop-hook.md
  - scripts/hooks/declared-ready-stop.sh
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 365
---
# Run the change in the state that matters before calling it done

Before writing done · works · fixed · passing · verified · shipped:

1. **Run it.** Execute the changed path and read the pass/fail line.
2. **Collect ≠ run.** `pytest --collect-only`, `tsc --noEmit`, an import check, a lint, a compile execute no assertion. Never call a suite green off a collect.
3. **A cached re-run is one run.** Bust the cache or vary the key before counting a repeat.
4. **Induce the state that matters** (empty list, fault, pressure, cold vs warm) rather than inferring from the happy path.
5. **A guard needs the opposite proof.** Break the thing it protects, watch its test go red, restore, watch it go green. A mutation that stays green means the test is the bug.
6. **Mark the un-exercisable honestly:** `UNCONFIRMED — <reason>`, never a checkmark.

Scale the run to the change (typo → syntax check; transform → smoke test with real data). Enforcement: `declared-ready-stop.sh`, currently muted by `~/.claude/.no-declared-ready-gate`, so this binds as text; the SessionStart brief lists muted gates.

Diagnostic: about to type "done" and the last thing you ran was a collect, a compile, a lint, or nothing.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/exercise-based-verification.md`
