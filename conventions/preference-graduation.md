---
brief: How recurring preference + vocabulary signals graduate from post-insight streams (i-dream, atone/affirm, core-dump, runtime-notes) into durable homes (GLOSSARY, memory, rules).
triggers:
  - topic:preferences
  - topic:workflow-vocabulary
  - phrase:"bake this in"
  - phrase:"remember how I work"
  - skill:atone
related: [GLOSSARY.md, features/memory.md, rules/corrections.md, features/atone.md, features/proposals.md]
tier: 2
category: conventions
updated: 2026-06-19
stale_after_days: 120
---

# Preference graduation — harvesting how-the-user-works into durable config

The user's working vocabulary and preferences ("efficacy not speed", "one-shotting
is a fantasy", "just use chatgpt", "maximalist ≠ ambitious") accrete *implicitly*
across sessions — in dream insights, atone/affirm events, core-dump checkpoints,
and runtime-notes. **Preference graduation** is the deliberate pass that mines
those streams for recurring preference/terminology signals and promotes them into
the durable homes where future agents will actually load them.

It is the preference-side sibling of the existing promotion paths: `atone → rules`
(corrections graduate to mandates) and `proposals → canon`. Same shape, different
payload — here the payload is *how the user likes to work and the words they use
for it*, not a bug pattern.

## The source streams (where signals come from)

| Stream | Path | Signal to look for |
|---|---|---|
| i-dream / subconscious | `~/.claude/subconscious/dreams/`, pins via `pin-for-dream` | recurring observations about user workflow/preferences |
| atone / affirm | `~/.claude/atone/events.jsonl`, `~/.claude/affirm/events.jsonl` | corrections + affirmed-good calls that imply a standing preference |
| core-dump | `~/.claude/checkpoints/`, `subconscious/dreams/pending-todos.jsonl` | repeated framing/vocabulary in goals & pending items |
| runtime-notes | `<project>/.claude/skills/runtime-notes.md` | post-session insights naming a user preference |

## The routing (which durable home each signal goes to)

| Signal kind | Durable home |
|---|---|
| A **word/shorthand** the user adopts | `GLOSSARY.md` (User Shorthand / Concepts) |
| A **standing preference** ("I prefer X over Y") | `memory/global/feedback_*.md` (+ MEMORY.md index) |
| Who-the-user-is fact | `memory/global/user_*.md` |
| A **how-Claude-MUST-work** mandate (repeat-confirmed) | `rules/*.md` (+ CLAUDE.md brief per PLACEMENT.md) |
| Project-scoped preference | that project's `.claude/` memory or rules |

## The write-bar (don't over-bake)

Graduate a signal only when it is **recurring or user-confirmed** — the same bar as
atone (a one-off observation is not a preference). A single offhand remark goes in
a memory at most; promotion to a *rule* requires repeat occurrence or an explicit
"bake this in". Over-baking pollutes the always-loaded budget (see PLACEMENT.md):
every promoted rule competes for the model's instruction-following capacity.

## The manual pass

When the user asks "remember how I work" / "bake this in", or at a periodic review:

1. Scan the source streams for preference/vocabulary signals (grep the JSONL +
   recent runtime-notes/checkpoints).
2. Dedupe against what GLOSSARY + memory already hold.
3. Route each fresh signal to its durable home (table above); cross-link.
4. Update the relevant index (`MEMORY.md`, GLOSSARY tables) and, if a rule was
   added, its CLAUDE.md brief.

## The automated surfacing (extension to an existing mechanism)

A scheduled pass surfaces *candidates* for the manual pass — it never auto-writes
to GLOSSARY/memory/rules (those require judgment). The harvester
`scripts/preference-harvest.sh` scans the source streams and writes a dated
candidate list to `~/.claude/topics/preference-candidates-YYYY-MM-DD.md`. It is
wired into an existing scheduled mechanism (the atone-consolidate / i-dream review
cadence) rather than a standalone daemon, and — like every scheduled job here —
carries an `Automations` calendar companion (see `rules/cron-calendar-companion.md`).
The human reviews the candidate list and runs the manual pass for anything real.

## Related

- `rules/corrections.md` — the atone→rules promotion path this mirrors
- `features/proposals.md` — the proposals→canon sibling
- `features/memory.md` — memory tiers + format
- `PLACEMENT.md` — where a graduated rule/term/feature actually goes
