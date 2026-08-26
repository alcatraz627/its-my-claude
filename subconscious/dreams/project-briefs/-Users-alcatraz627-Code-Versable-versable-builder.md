<!-- i-dream project brief · 2026-08-21T19:17:22.734876+00:00 · 20 patterns / 10 insights -->
## What this project is about
A multi-agent SaaS builder (versable-builder) with heavy UI work, parallel sub-agent coordination, and external stakeholder-facing output. Work style mixes high-velocity parallel edits with protected-repo discipline.

## Things to do (or keep doing)
- **Audit every page** before implementing any shared UI shell (sidebar, drawer, modal) — enumerate all instances first, implement globally in one pass, never per-page
- **Verify on the running dev server** before claiming a UI or IPC fix is done — proxy evidence (send-success, test-pass, code looks right) is not direct evidence
- **Pre-negotiate task ownership via IPC** before parallel sub-agents touch the same files — post-burst, treat all cached state (tasks, git, file contents) as stale and re-sync
- **Collect multiple owner decisions through `/decision-wizard`**, never as a numbered chat list

## Things to avoid
- **Don't commit or push** — this is a protected repo; prepare the diff, show it, hand the commit to the user
- **Don't emit em-dashes or excessive bold spans** in any prose, even after a stop-hook fires and demands re-emission — treat the hook as a hard gate, not an advisory
- **Don't raise a deferred topic again** once the user has skipped it three or more times — if it resurfaces, wait for their explicit invitation
- **Don't post to shared platforms (GitHub, etc.) under the user's account** without an explicit "posted by agent" marker in the message body

## Open questions / known gaps
- **Absence-as-default trap is recurring**: gates default ALLOW on unknown inputs, lookups return zero instead of UNCERTAIN — every new gate or extraction needs an explicit unknown/deny path wired at creation time
- **External-document hygiene**: docs drafted here sometimes contain internal commentary that must be stripped before any stakeholder share — no automated gate exists for this
