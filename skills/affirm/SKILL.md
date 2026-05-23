---
name: affirm
description: Records an affirmed-good behavior — non-obvious approach the user explicitly approved. Sibling of /atone. Higher write bar than atone (only fires for genuinely surprising/load-bearing good calls). Writes to ~/.claude/affirm/events.jsonl.
allowed-tools: Read, Edit, Write, Bash, Grep
user-invokable: true
argument-hint: "[brief description of the good behavior]"
---

## Brief

Logs a non-obvious good call to the affirm event log so the system can later inject the trigger condition + instruction as a periodic-refresh hint. Higher bar than /atone — only fire when the user EXPLICITLY affirmed the approach AND the approach is non-obvious enough that future-you might not repeat it without prompting.

# Affirm — Record an affirmed-good behavior

## Step 0: Decide if this is /affirm-worthy

Use this skill ONLY when ALL three are true:

1. **The user explicitly affirmed the choice** ("good call", "smart move", "right call", "yes exactly", "perfect, keep doing that") — not just "ok" or "thanks".
2. **The choice was non-obvious** — surprising, load-bearing, or counter to what a default agent would do.
3. **Future-you might not repeat it** without an external nudge.

If any are false, skip /affirm. Affirm fatigue (over-claiming) makes the periodic-refresh injection useless.

## Phase 1 — Gather context

- The exact text of the user's affirmation
- What you (the agent) actually did
- Why it was the right call (what default would have failed)
- The session id and recently-touched files

## Phase 2 — Search for an existing slug

```bash
bash ~/.claude/scripts/affirm.sh slugs
```

Reuse if a match exists; recurrence increases weight in `triggers.json`.

## Phase 3 — Draft the six required fields

| Field | What goes here |
|-------|---------------|
| `slug` | kebab-case pattern name |
| `title` | ≤80-char summary |
| `behavior` | What was done well, 2-3 sentences |
| `why_good` | What bad outcome was avoided / what about the obvious default would have failed |
| `trigger_condition` | When this approach should fire (the action-shape) |
| `instruction` | The at-action-time check, ≤2 sentences. Same shape as atone's `precheck` field. |

## Phase 4 — Write

```bash
bash ~/.claude/scripts/affirm.sh add \
  --slug "<existing-or-new-kebab>" \
  --title "..." --behavior "..." \
  --why-good "..." --trigger-condition "..." --instruction "..." \
  --tags "<space-separated>" \
  --cluster "F-J or empty" \
  --files "..." --project "$(pwd)"
```

Cluster letters for affirm (F-J, distinct from atone's A-E):

- **F — audit-before-action** (audit file character / existing call sites / project conventions before applying a generic rule)
- **G — character-aware-refactor** (preserves single-purpose file boundaries, respects the existing organization)
- **H — ask-when-ambiguous** (paused to clarify with the user instead of guessing)
- **I — verify-before-claim** (rendered/exercised before declaring done)
- **J — convention-following** (used the project's helper instead of reaching for stdlib)

## Phase 5 — Refresh triggers + report

```bash
bash ~/.claude/scripts/atone-consolidate.sh --triggers-only
```

Then report:

```
Affirmed <id>. Trigger added to triggers.json: "<instruction-summary>"
```

## Notes

- **Append-only.** Once written, the line cannot be edited. If the affirmation turns out to be wrong, file a NEW entry with the correction context.
- **No severity.** Affirm has no severity dimension — affirmations are all equal-weight; recency × frequency only.
- **No RCA.** Affirm has no post-mortem path; the entry IS the artifact.
- **Hook actions.** When triggers.json drives a hook for an affirm pattern, the action is always SUGGEST (gentle hint), never BLOCK. Affirms reinforce, they don't gate.

## Related

- CLI: `bash ~/.claude/scripts/affirm.sh help`
- Sibling: `/atone` for mistakes
- Compliments view (auto-generated): `~/.claude/compliments.md` (after consolidate runs)
- Full log: `~/.claude/affirm/events.jsonl`
