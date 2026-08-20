<!-- i-dream project brief · 2026-08-18T06:12:14.392607+00:00 · 11 patterns / 0 insights -->
## What this project is about
GCP infrastructure planning/provisioning work with multi-agent adversarial review (magi/voter pattern). Dominant style: structured review → filtered action items → owner decision.

## Things to do (or keep doing)
- Always include a skeptical "jester" voice in adversarial reviews — challenges core premises, not just implementation details
- Verify sub-agent ballot/output files on disk after idle notifications; don't trust notification count alone
- Pass `--quiet` to all `gcloud` commands in automated contexts to avoid interactive API-enable prompts blocking pipelines
- Filter review findings by value-to-effort ratio before surfacing as action items; present only what genuinely needs owner judgment

## Things to avoid
- Don't re-surface deferred work (a specific artifact or app) the user explicitly parked behind a concrete trigger condition (e.g., customer demand)
- Don't narrow adversarial review scope to the agent's default framing without confirming target and scope with the user first
- Don't use escaped dots inside `gcloud --format` projection field paths — they fail silently; switch output format or restructure the path
- Don't conflate `PERMISSION_DENIED` (disabled API) with IAM permission errors — they require different remediation paths

## Open questions / known gaps
- Multi-agent shared-file contention: peers editing contract/doc files concurrently risk stale-read races; re-read immediately before write, but no systematic lock pattern established yet
- How many pre-filtered items cross the "genuinely needs owner judgment" threshold is still calibrated by feel, not a documented rule
