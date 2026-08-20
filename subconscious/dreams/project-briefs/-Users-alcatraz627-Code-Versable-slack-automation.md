<!-- i-dream project brief · 2026-08-18T17:46:54.540198+00:00 · 20 patterns / 0 insights -->
## What this project is about
Slack automation tooling for Versable, worked primarily through multi-agent orchestration sessions: adversarial review panels, IPC-coordinated peer agents, and CI-triggered deployment flows.

## Things to do (or keep doing)
- After any sub-agent or magi seat completes, verify the output file on disk before treating findings as usable — idle notifications are pointers, not artifacts.
- Filter adversarial review findings by value-to-effort before presenting as action items; the user does not want exhaustive adherence to every finding.
- Route mechanical documentation and low-judgment tasks to sub-agents; reserve main/opus capacity for synthesis and user-facing decisions.
- Before a multi-voter review, explicitly confirm scope and target with the user — default framing drifts narrow.

## Things to avoid
- Don't show a task list from the wrong session context; verify scope before rendering — a wrong list triggers strong frustration.
- Don't surface deferred work (apps or artifacts the user has parked pending a concrete trigger like customer demand) unless that trigger has been met.
- Don't stop after naming tasks as "unblocked" or "next" — execute them in the same turn or explicitly hand off.
- Don't post content to shared external surfaces (GitHub PR comments, channels) without an agent-identity disclosure in the message body.

## Open questions / known gaps
- Multi-agent sessions concurrently editing shared contract/doc files risk stale-read races; no consistent re-read-before-write discipline yet.
- Peer IPC queries sometimes go unanswered before turn end; the contract with peer agents is broken when this happens.
