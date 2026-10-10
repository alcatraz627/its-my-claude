---
name: tag
description: Place a reusable owner rule, preference, term, or tool note into the gcc canon with deduplication and index ripple review. Use when the owner asks to keep or codify something.
---

# Tag in Codex

Read `/Users/alcatraz627/.claude/skills/tag/SKILL.md` and `/Users/alcatraz627/.claude/PLACEMENT.md`. Resolve the actual item, read it, then search the full relevant gcc tree for an existing canonical home. Distinguish project-local material from global guidance. Draft the exact destination, content, frontmatter, tier, and every index or cross-link edit before writing. Never hand-edit derived views.

The source skill requires owner review of the exact placement and ripple set before writing. Once that plan is approved, create a schema-1 manifest in the current workspace: `{"schema_version":1,"changes":[{"path":"rules/example.md","expected_sha256":"<current file SHA-256, or null for a new file>","content":"<full new Markdown content>"}]}`. Paths are relative to `/Users/alcatraz627/.claude`. Include every authored index and cross-link edit in one manifest. Run `bash /Users/alcatraz627/.claude/adapters/codex/bin/gcc canon check /absolute/manifest.json` and show its exact diff. Apply the approved manifest with `gcc canon apply /absolute/manifest.json` using the tool's filesystem escalation. Canonical edits are never queued through the seat-writable outbox. The bridge locks, rechecks base and manifest hashes, restricts destination paths, backs up old files, and stamps a Codex receipt. Inspect the receipt and final files before claiming placement. Regenerate derived indexes with their own scripts and validate links and triggers. For project-local files, use normal workspace edits under that repo's rules. Do not commit or push.
