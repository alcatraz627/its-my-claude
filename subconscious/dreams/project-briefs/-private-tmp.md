<!-- i-dream project brief · 2026-05-13T11:30:38.582271+00:00 · 3 patterns / 0 insights -->
## What this project is about
A scratch/exploration workspace (`/private/tmp`) used for ad-hoc integrations and sync scripts, primarily around Notion-based data pipelines. Work style is iterative and diagnostic.

## Things to do (or keep doing)
- Add defensive logging at **every stage** of sync/integration pipelines — log inputs, outputs, and intermediate state so failures are immediately locatable without a second run
- Define test fixtures **explicitly and statically**; never rely on generated, inferred, or dynamic fixtures that can silently produce wrong data
- Before patching a failing script, **stop and state the root cause** in one sentence — if you can't, investigate further before touching code

## Things to avoid
- Don't apply repeated patches to the same sync failure without first confirming the actual root cause; re-editing the same function 3+ times signals you don't understand it yet (`[re-edit-thrash]`)
- Don't assume a fix "worked" because no error was thrown — sync scripts can silently succeed while producing wrong state; verify the output artifact directly

## Open questions / known gaps
- Root-cause discipline is flagged as weak here — the pattern of patching without diagnosing has recurred; consider whether the sync logic needs a structured debug mode (dry-run + verbose) before the next iteration
