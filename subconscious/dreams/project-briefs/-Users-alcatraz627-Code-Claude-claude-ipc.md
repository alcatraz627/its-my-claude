<!-- i-dream project brief · 2026-07-15T18:49:24.612415+00:00 · 20 patterns / 4 insights -->
## What this project is about
A cross-session IPC broker for Claude Code agents, enabling message-passing and coordination between parallel agent instances. Dominant style: systems/infrastructure work with tight multi-agent coordination concerns.

## Things to do (or keep doing)
- **Prefer explicit DENY over plausible defaults** for unknown commands/inputs — unrecognized CLIs must fail loud, never silently ALLOW
- **Confirm IPC delivery via round-trip reply**, not by inspecting sender-side logs — log presence ≠ delivery
- **Breadth-first sweep first**: wire all surfaces to a working v1 before polishing any single area
- **Batch sequential work** and only halt at genuine decision points — not every minor step

## Things to avoid
- **Don't assume parallel agents are coordinated** — they must pre-negotiate task ownership via IPC before touching shared code; uncoordinated edits produce conflicting changes
- **Don't use `rg -rn`** — `-r` is `--replace`, silently mangles output; use `rg -n` for line numbers in recursive searches
- **Don't quote special characters carelessly in IPC message bodies** — backticks get shell-consumed and produce zero-byte or corrupted messages; always use heredoc or single-quote wrapping
- **Don't patch the specific instance** (add one CLI to a fallback) without fixing the structural class (the default-allow policy itself)

## Open questions / known gaps
- **Stop hooks fire repeatedly for unreplied IPC messages** — no clear ownership protocol for who must reply before session end; a reply discipline needs to be defined and enforced at the broker layer, not just advisory
- **Enforcement is advisory-layer only** — behavioral constraints in SKILL.md or mute files are bypassable by any agent that doesn't read them; safe gates belong at the data-write CLI, not in spec text
