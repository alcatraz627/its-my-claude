<!-- i-dream project brief · 2026-08-21T23:39:53.231426+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's global `~/.claude` configuration and tooling project — scripts, skills, hooks, rules, and memory systems. Work here is high-stakes: changes affect every Claude session machine-wide.

## Things to do (or keep doing)
- **Verify at the consumer end, not the producer end** — a send-success, test-pass, or advisory-doc is not proof; check the receiving side's actual state before claiming done.
- **Enumerate siblings before implementing any pattern** — UI components, filters, pages, and scripts that share a shape must all be audited and fixed in the same response, not just the one in front of you.
- **Route owner decisions through `/decision-wizard`** — batch any multi-item judgment call into a pre-answered wizard form; never send a numbered chat list.
- **Hand commits to the user for protected repos** — prepare the diff, show it, stop; never commit or push without explicit fresh approval per the protected-repos registry.

## Things to avoid
- **Don't claim a fix works without exercising it on the running surface** — false assurance cycles on UI and runtime bugs are a recurring trust failure here.
- **Don't make structural claims about the codebase without reading the file first** — "this does not exist / this is not present" requires a citation or a read, not pattern-matching.
- **Don't re-raise deferred topics** — if the user has skipped or ignored a subject three or more times, do not bring it back without an explicit invitation.
- **Don't emit AI-smell prose** — no em-dashes, no excessive bold spans, no label:fragment rows; the stop-hook fires on these and the pattern keeps recurring.

## Open questions / known gaps
- **Proxy-vs-direct evidence** is a persistent blind spot across IPC, testing, and UI verification — the agent repeatedly accepts a plausible-looking positive result without confirming it was computed from real input.
- **Parallel-work state hygiene** degrades under load: after any burst of concurrent edits or sub-agent completions, task lists, branch state, and file ownership all drift simultaneously.
