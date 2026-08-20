<!-- i-dream project brief · 2026-08-17T18:37:52.526455+00:00 · 16 patterns / 0 insights -->
## What this project is about
Versable builder playground — a feature-dev surface with heavy multi-agent orchestration, parallel review panels, and fast-turnaround demo/presentation cycles. Working style: structured fan-out with explicit mechanical/judgment tier splits.

## Things to do (or keep doing)
- Before interpreting a diff as large or substantive, run `git diff -w` — auto-formatting hooks rewrite on write and inflate raw diff size.
- Route mechanical doc/label work to lower-tier sub-agents (sonnet-low); reserve higher-tier capacity for ideation, adversarial judgment, and synthesis.
- When orchestrating a parallel review panel, include a maximally adversarial seat that questions the product category itself — not just surface quality.
- Track sub-agent completion against output files on disk, not idle/stop notifications; stopped agents can emit stale idle signals — dismiss without re-dispatching.

## Things to avoid
- Don't declare a fix done without running the affected code path; the declared-ready hook fires repeatedly in this project — this is a standing blind spot.
- Don't show a task list without confirming it belongs to the current session; a wrong-session list triggers strong user frustration.
- Don't scope a review panel to the session's current presentation framing — scope it to real product usability gaps.
- Don't proceed on ambiguous task references (e.g., "#2") without confirming which item is meant; re-surfacing context after a direction correction wastes the turn.

## Open questions / known gaps
- Kanban board sync is never proactive — user must request it after each stage; treat board update as a milestone deliverable, not cleanup.
- Explicit parking directives ("park it as is") must be honored immediately with no wrap-up attempts — this boundary gets crossed.
