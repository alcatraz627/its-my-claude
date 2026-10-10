---
name: gcc-proposal
description: File a reusable improvement to the owner's gcc backlog from a rough idea or observed friction.
---

# GCC proposal in Codex

Read `/Users/alcatraz627/.claude/skills/gcc-proposal/SKILL.md` for scope and formatting. Keep only reusable improvements to `/Users/alcatraz627/.claude`. Write a concrete title (imperative, at most 80 characters), a two-to-four-sentence body with observed friction and evidence, category, and effort. Include absolute paths when citing files.

File through `bash /Users/alcatraz627/.claude/adapters/codex/bin/gcc propose add --title "..." --body "..." --category hooks|scripts|skills|config|docs|other --effort small|medium|large`. The bridge stamps Codex attribution and either writes or queues with a receipt. Do not run `propose.sh` directly. Verify the receipt; a queued receipt means pending until a later hook confirms it. Never write the backlog file yourself.
