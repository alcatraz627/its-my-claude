<!-- i-dream project brief · 2026-05-13T11:28:32.465948+00:00 · 9 patterns / 10 insights -->
## What this project is about
Backend for a B2B SaaS product ("enhancement-product") with complex multi-session workflows; dominant style is high-tool-count implementation sessions with heavy state serialization discipline.

## Things to do (or keep doing)
- Run `/core-dump` proactively at session milestones and before risky ops — not only when asked; absence of a recent checkpoint after 30+ tools is a defect
- After any `/catchup` or session handoff, re-read key files before acting — treat recalled state as unverified until confirmed against disk
- Design logging/cost-tracking as first-class schema requirements from the start, not retrofitted additions
- Keep responses between tool calls ≤15 words in high-tool-count sessions (40+) — verbose narration accelerates context compaction

## Things to avoid
- Don't assume text renders correctly in dashboard widgets — always verify full text display, not just that data loaded (truncation bugs recur)
- Don't start a task estimated >30 tools without planning intermediate checkpoints and sub-task splits
- Don't treat a prior session's state summary as ground truth — files, branches, and process state can diverge; verify before side-effects
- Don't let tool count exceed 40 without switching to batch reads and compact WAL entries

## Open questions / known gaps
- Session continuity is still fragile at scale: projects with >3 prior continuations need a persistent project-state manifest (key files, services, branches) that survives `/clear`
- Context limit hits and data hallucination share the same root cause (incomplete context → gap-filling) — no systematic guardrail exists yet beyond manual `/catchup`
