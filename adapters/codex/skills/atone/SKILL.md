---
name: atone
description: Record a real corrected mistake in the owner's atone ledger with cause, completed fix, and a future precheck. Use only after a correction or material rework.
---

# Atone in Codex

Read `/Users/alcatraz627/.claude/skills/atone/SKILL.md` for the severity and RCA bar. Search existing slugs before adding a new one. Fix the actual issue first, then file with `bash /Users/alcatraz627/.claude/adapters/codex/bin/gcc atone add ...`; never call `atone.sh` directly. The gcc bridge stamps Codex attribution and queues sandboxed writes. Inspect the receipt. Do not record a hypothetical mistake or call a queued event complete before its receipt lands.
