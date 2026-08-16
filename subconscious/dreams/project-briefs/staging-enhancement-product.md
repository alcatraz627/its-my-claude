<!-- i-dream project brief · 2026-08-15T03:46:52.102203+00:00 · 20 patterns / 8 insights -->
## What this project is about
Enhancement-product is a multi-agent web application with coordinated IPC sessions, list/detail UI pages, and parallel sub-agent workstreams. The dominant working style is high-velocity parallel execution with tight user-feedback loops.

## Things to do (or keep doing)
- **Batch sequential mechanical work autonomously**; halt only at genuine product decisions or critical reviews — terse user continuations ("yes", "go") are authorization to proceed, not prompts to checkpoint
- **Apply component fixes globally**: when one page's sidebar/drawer/modal shell is wrong, fix every page using that component in the same pass
- **Confirm IPC delivery via round-trip reply** from the peer; send-success in your own logs is never evidence of delivery
- **Include tradeoffs and prior constraints in every decision question**; questions that omit context force a follow-up and waste a turn

## Things to avoid
- **Don't treat proxy signals as direct evidence**: send-success ≠ delivered, test-pass ≠ behavior correct, notification ≠ artifact exists — verify at the receiver's end
- **Don't synthesize defaults from empty results**: when a lookup returns nothing, emit UNCERTAIN or DENY, never a fabricated zero/false/ALLOW
- **Don't write AI-smell prose** (em-dashes, bold-spam, Label:fragment rows, performative self-critical tables) — the stop hook fires and the correction must be real, not structural
- **Don't strip context from external documents silently**; internal critique and stakeholder framing must be removed before writing the final artifact, but confirm scope first

## Open questions / known gaps
- The declared-ready hook fires repeatedly in the same session despite prior blocks — the habit of claiming success without exercising the code path is persistent and needs a per-turn precheck, not just a session reminder
- State coordination (task lists, branch state, file contents) degrades specifically under parallel bursts — sync frequency must increase as parallelism increases, not decrease
