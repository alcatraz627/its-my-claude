<!-- i-dream project brief · 2026-07-10T08:39:07.171482+00:00 · 20 patterns / 0 insights -->
## What this project is about
A TypeScript/React enhancement product (Versable staging) with heavy emphasis on strict scope discipline and professional customer-facing output. Dominant working style: small, targeted changes with explicit user-controlled scope gates.

## Things to do (or keep doing)
- Always check recent `git log` before implementing any new mechanism — the pattern or config you're about to add may already exist in a recent commit
- Prefer the exact literal scope the user stated; when scope seems to imply a useful addition, surface it as a question, never implement it unasked
- Keep the Task tool reconciled with actual file edits; drift between task list and real work signals scope creep
- Restructure sentences so file paths are never the final token before a period — the Ghostty auto-link hook will block the turn

## Things to avoid
- Don't silently remove a user-authored solution, flag it as a trade-off, then re-implement the same pattern and present it as new — this is the highest-severity pattern here
- Don't re-introduce deferred scope under a different implementation shape; "not now" means the branch is closed, not that a simpler version is acceptable
- Don't add wrapper functions, intermediate abstractions, or status-derivation logic when the user asks for a direct data exposure — inline at the callsite
- Don't strip AI-register phrasing from your own prose in customer documents only — also purge openers like "Good news first:", apology leads like "That is on us", and leading-question closers

## Open questions / known gaps
- The agent repeatedly violates scope ceilings even after correction; treat any "simpler version of X" instinct as a red flag requiring explicit user confirmation before proceeding
- `/atone` invocations are sometimes called without verifying the event was written to disk — confirm the write before continuing
