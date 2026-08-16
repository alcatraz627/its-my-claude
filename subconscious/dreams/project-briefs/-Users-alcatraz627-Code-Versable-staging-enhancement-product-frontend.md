<!-- i-dream project brief · 2026-08-15T03:47:21.015835+00:00 · 20 patterns / 7 insights -->
## What this project is about
Frontend for an enhancement product (Versable staging); dominant mode is broad multi-surface feature builds with frequent parallel sub-agent coordination, stakeholder-facing document production, and shared UI component work.

## Things to do (or keep doing)
- Sweep all surfaces breadth-first before polishing any single area; resist pausing a full-app pass to perfect one component.
- Batch sequential work autonomously; only halt the user at genuine decision forks that include prior context + ≥2 concrete options.
- When fixing any shared UI pattern (drawer, pagination, filter), enumerate every consuming page before writing the first line of code, then fix all of them in the same response.
- After any burst of parallel work, treat ALL cached state (task lists, branch state, file contents) as stale and re-read before acting.

## Things to avoid
- Don't treat send-success as delivery confirmation in IPC; wait for an actual round-trip reply before claiming a message was received.
- Don't use `rg -rn` — `-r` is `--replace` and silently mangles output; use `rg -n` for line numbers in recursive searches.
- Don't write stakeholder-facing documents with internal banter, critique of stakeholders, or conversational framing; always determine audience and lifecycle before writing.
- Don't respond to a correction with a structured self-critical reply (numbered RCA, formatted acknowledgment list) — it reads as covering tracks; state the fix and apply it.

## Open questions / known gaps
- AI-smell prose corrections (em-dashes, bold-spam) consistently re-appear in the very next reply after the stop hook fires; the correction is not landing at generation time.
- Multi-agent ownership negotiation via IPC is understood as a rule but unenforced before work starts, leading to clobbered edits under velocity.
