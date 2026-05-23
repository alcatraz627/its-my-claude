---
brief: UserPromptSubmit hint injector; active hinters (autocorrect); dictionaries and correction log
triggers:
  - tool:hint-injector
  - skill:autocorrect
  - topic:typo-correction
  - phrase:"autocorrect"
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Hinter Pipeline
User prompts pass through `~/.claude/scripts/hint-injector.sh` (UserPromptSubmit hook) before Claude sees them. Hinters in `~/.claude/hinters/` run in sort order, each emitting optional hints as `additionalContext`.

**Prompts are never rewritten — hinters only add context.**

## Active hinters

| Hinter | Purpose | Latency |
|--------|---------|---------|
| `00-autocorrect.sh` | Detects typos via custom-terms whitelist + known-typo map | ~34ms |

## Autocorrect dictionaries (`~/.claude/assets/autocorrect/`)

- `custom-terms.txt` — 118 known-good terms
- `typo-map.txt` — 213 mappings
- `blacklist.txt` — 3 never-correct entries

Manage via `/autocorrect` skill.

## Correction log

`~/.claude/.autocorrect-log.jsonl` — every correction logged with timestamp, session ID, original word, corrected form.

## Autocorrect rules

Never touches: backtick code spans, paths, ALL_CAPS constants, function calls, flags, dotted identifiers.

When you see `[autocorrect] Detected likely typos:` in context, treat corrections as suggestions — use the corrected form if it fits, ignore if the original was intentional.
