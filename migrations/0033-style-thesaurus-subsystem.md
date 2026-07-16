# 0033 — style/ subsystem: thesaurus ledger, scope map, glossary activation

## Summary

New top-level dir `~/.claude/style/` holding the qualitative-writing control
plane: `thesaurus.jsonl` (the user's verdicts on how Claude writes; CLI at
`scripts/style/thesaurus.sh`), capped derived digests (`style/derived/`),
`scope-map.json` (which artifacts get how much tone enforcement — the user's
verbatim tier matrix), and `glossary-hints.tsv` (per-prompt steering-term
activation, consumed by the new `hinters/01-glossary.sh`). Capture skill:
`/thesaurus`. Five steering terms baked into GLOSSARY §User Shorthand
(overindex, pragmatic, intent, stupid-as-feedback, waste-my-time).

## Why

Audit `assets/reports/20260716-gcc-structural-audit/REPORT.md` (P7, P8, P20 +
in-conversation extensions): the vocabulary pipeline had two dead segments —
detection blind to the user's actual steering words (fixed-allowlist harvest
over post-insight streams only) and zero activation at prompt time (GLOSSARY
read-on-demand; one hinter total). The thesaurus is the consolidated affordance
the user asked for: style feedback lands in one ledger, consumers read capped
digests, the weekly review prunes/promotes, and agent-filed entries are FORCED
to candidate status so taste enters the active set only through the human.

## Scope

Additive. New dir + scripts + skill + hinter; one GLOSSARY table extended; no
existing consumer changes (those land with the critic persona and watcher,
migrations pending in batches 3-4 of the same plan).

## Label changes

New namespace label: `std::claude::style` (ledger + scope map + digests +
hinter data; two-artifact threshold met).

## Path moves

None (all files new).

## Files affected

| File | Change |
|---|---|
| `style/thesaurus.jsonl` | NEW — ledger, seeded with 11 canon/user verdicts |
| `style/scope-map.json` | NEW — user's enforcement-tier matrix (verbatim notes) |
| `style/glossary-hints.tsv` | NEW — term → meaning → pointer, hinter data |
| `style/derived/*.md` | NEW — capped digests (machine-written, never hand-edit) |
| `scripts/style/thesaurus.sh` | NEW — add/list/digest/hit/review CLI |
| `skills/thesaurus/SKILL.md` | NEW — /thesaurus capture + review skill |
| `hinters/01-glossary.sh` | NEW — steering-term activation (tested: 7ms) |
| `GLOSSARY.md` | +5 User Shorthand rows |
| `FOLDERS.md` | Regenerated (new top-level dir) |
| `NAMESPACE.md` | +`std::claude::style` row |

## Phases

1. ✅ 2026-07-16 — everything above.
2. ⏳ Consumers: readers-advocate critic persona (batch 3) and style-watch
   stack (batch 4) load `style/derived/` digests + `scope-map.json` and call
   `thesaurus.sh hit` for telemetry.
3. ⏳ Optional enforcement rung: compile mechanizable active entries into
   `cleanup-comments/detect.py` patterns at weekly review ("graduate to regex").

## Recovery

`trash ~/.claude/style ~/.claude/scripts/style ~/.claude/skills/thesaurus ~/.claude/hinters/01-glossary.sh`, revert the GLOSSARY/FOLDERS/NAMESPACE edits (single commit). No other surface depends on it until phase 2 lands.

## Cross-references

- `assets/reports/20260716-gcc-structural-audit/REPORT.md` — the audit
- `conventions/preference-graduation.md` — the storage-half pipeline this
  activates; `scripts/preference-harvest.sh` remains the candidate miner
- mig 0032 — sibling batch (Resume Contract conservative fields)
