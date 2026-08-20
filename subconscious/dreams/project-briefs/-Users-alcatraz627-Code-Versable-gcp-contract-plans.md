<!-- i-dream project brief · 2026-08-19T19:51:40.655932+00:00 · 16 patterns / 0 insights -->
## What this project is about
GCP contract planning and multi-agent orchestration work — involves gcloud automation, adversarial review flows (magi), and shared documentation edited concurrently by multiple agents.

## Things to do (or keep doing)
- Pre-filter owner-action items aggressively before surfacing them; present only decisions that genuinely require human judgment, not operational rundown
- Verify sub-agent ballot/output files on disk before trusting completion notifications — stale or repeated idle signals are a known false-positive here
- Include a jester voice in adversarial reviews; premise-challenging skepticism surfaces value surface-level voters miss
- Pass `--quiet` to all `gcloud` commands in automated contexts to prevent interactive API-enable prompts from blocking pipelines

## Things to avoid
- Don't treat multi-clause stop conditions as satisfied until every clause independently holds — especially clauses requiring owner review, which the agent cannot complete on its behalf
- Don't surface deferred work (artifacts/apps parked behind a trigger condition like "customer demand") unless that trigger has explicitly fired
- Don't use escaped dots inside `gcloud --format` projection field paths — they silently fail; use an alternative output format
- Don't distinguish PERMISSION_DENIED (disabled API) from PERMISSION_DENIED (missing IAM) by assumption — test and remediate each failure mode separately

## Open questions / known gaps
- Scope alignment on multi-voter reviews tends to narrow by default; confirm review target and scope explicitly before launching magi or equivalent to avoid misaligned findings
- Exhaustive adherence to every adversarial finding is a recurring friction point — filter by value-to-effort ratio before presenting as action items
