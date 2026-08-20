<!-- i-dream project brief · 2026-08-18T06:11:16.101818+00:00 · 20 patterns / 0 insights -->
## What this project is about
GCP infrastructure tooling (`gcp-bin`) with heavy use of multi-agent orchestration, adversarial review panels (magi/jester), and automated `gcloud` pipelines. Sessions alternate between mechanical batch work and high-judgment synthesis calls.

## Things to do (or keep doing)
- Always verify sub-agent completion against output files on disk — idle notifications are unreliable and may be stale/repeated; dismiss stopped-agent notifications without re-dispatching.
- Include a maximally adversarial "jester" seat in review panels — one that challenges the core product premise, not just surface quality; it surfaces gaps the polite seats miss.
- Filter review findings by value-to-effort before presenting; exhaustive adherence to every panel finding is not the expected default.
- Pass `--quiet` to every `gcloud` command in automated/pipeline contexts to prevent interactive API-enable prompts from blocking execution.

## Things to avoid
- Don't show a task list without verifying it belongs to this session; wrong-session task lists cause strong frustration.
- Don't resurface deferred work (work the user has explicitly parked or made conditional on a trigger) unless that trigger fires this session.
- Don't scope a magi/review panel to the session's presentation goal — scope it to real usability gaps.
- Don't use escaped dots inside `gcloud --format` projection field paths; use an alternative syntax or output format.

## Open questions / known gaps
- GCP `PERMISSION_DENIED` conflates disabled-API and missing-IAM failures; these need separate remediation paths that aren't consistently distinguished in this codebase yet.
- Concurrent multi-agent edits to shared contract/doc files risk acting on stale reads — re-read immediately before write, but no automated guard enforces this yet.
