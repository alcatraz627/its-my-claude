---
name: pin-for-dream
description: Pin a meaningful Codex-session insight for i-dream's next cycle when a repeated pattern or cross-project tradeoff deserves examination.
---

# Pin for dream in Codex

Read `/Users/alcatraz627/.claude/skills/pin-for-dream/SKILL.md` for the relevance bar. Prefer a specific insight with absolute source pointers, not a to-do or one-off question. Frame it as `investigate` by default; use `monitor`, `graduate`, or `note` only when the owner asks for that meaning.

Use `bash /Users/alcatraz627/.claude/adapters/codex/bin/gcc pin add "<insight>" --file /absolute/path:lineA-lineB --framing investigate`. Repeat `--file` for relevant evidence. The bridge stamps this Codex session ID and current directory and queues if sandboxed. Do not call `i-dream pin` directly. The CLI flags preserve source paths without piping JSON, which a queued call cannot carry. Report an assigned pin ID only after a live receipt; otherwise say queued.
