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

**Prompts are never rewritten. Hinters only add context.**

## Active hinters

| Hinter | Purpose | Latency |
|--------|---------|---------|
| `00-autocorrect.sh` | Detects typos via custom-terms whitelist + known-typo map | ~34ms |

## Autocorrect dictionaries (`~/.claude/assets/autocorrect/`)

- `custom-terms.txt` holds 118 known-good terms
- `typo-map.txt` holds 213 mappings
- `blacklist.txt` holds 3 never-correct entries

Manage them via the `/autocorrect` skill.

## Correction log

`~/.claude/.autocorrect-log.jsonl` logs every correction with timestamp, session ID, original word and corrected form.

## Autocorrect rules

It never touches backtick code spans, paths, ALL_CAPS constants, function calls, flags or dotted identifiers.

When you see `[autocorrect] Detected likely typos:` in context, treat the corrections as suggestions. Use the corrected form if it fits, and ignore it if the original was intentional.
