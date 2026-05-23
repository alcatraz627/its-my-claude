# Grep the FULL tree before claiming a thing doesn't exist

Before stating *"there's no existing module / function / helper for X"* — or proposing to create one — grep the **entire relevant tree** for X's keywords, not just the directory where X "should" live.

Graduated from atone slug `infra-before-grep` (4× recurrence as of 2026-05-17). The pattern: agent pattern-matches a concern to its "obvious" home (e.g. database indexes → `lib/database/`), grep-scopes there, returns empty, and proposes new infrastructure. The thing actually existed in a sibling directory because the original author placed it where the **trigger** fires, not where the **catalog** semantically belongs.

## The rule

When asking "does X already exist?" or "where would X live?", the grep MUST satisfy one of these:

1. **Scope = full project root** (e.g. `rg -n "keyword" backend/` or `frontend/`), OR
2. **Scope = explicit multi-directory list with a stated justification** for excluding what's outside it

A single-directory grep (`rg -n "keyword" backend/lib/database/`) is acceptable ONLY for "find this thing I already know is here, narrow the search" — not for "does this thing exist anywhere."

## Why this gets a rule (not just an atone)

The failure mode looks innocent — narrow grep, no results, propose new module. But it leads to:

- **Duplicate modules** (the version I almost shipped on 2026-05-17 would have been an exact dup of `lib/config/app_init.py:_ensure_indexes`, including the same index declaration)
- **Wasted user time** re-explaining where things live, then watching the agent revert
- **Loss of trust** — if the agent says "no existing X" with confidence, the user assumes it grepped properly

The 30-second cost of one wider grep is always lower than the cost of building duplicate infrastructure or eating a correction round-trip.

## What this rule does NOT mean

- Don't grep-spam every question. For "where is function `foo` defined?" the narrow grep is fine — you're locating a known thing.
- Catalog-style "what already exists for the concern of X?" questions are the trigger. *Existence claims* require *existence-disproving* evidence.

## Diagnostic signal

Sentence in your output that reads: *"No existing module for X — proposing to add..."*. Before sending that sentence, check: did you grep the full tree, or just one subdir? If only one subdir, run the wider grep before you send.

## Concrete pattern

```bash
# Bad — narrow assumption
rg -n "ensure_index|create_index" backend/lib/database/

# Good — full tree
rg -n "ensure_index|create_index" backend/

# Even better when looking for a concept (not exact symbol)
rg -n "(ensure|create|init|setup)_indexe?s?" backend/
```

## Related

- Atone slug: `bash ~/.claude/scripts/atone.sh search infra-before-grep`
- `rules/structural-claim-without-reading-code.md` — the architectural-claim sibling pattern
- `rules/helper-return-type-assumption.md` — another "assume before checking" variant
