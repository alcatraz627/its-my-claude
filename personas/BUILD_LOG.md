# Designer-Reviewer Persona — Build Log

> This file documents every sub-agent call used to construct and iterate
> on the `designer-reviewer` persona. Future agents (and the user) can
> reuse this pattern to create similar expert personas.

**Session:** `mobi-dash-a4` — 2026-04-09
**Target output:** `~/.claude/personas/designer-reviewer.md`

---

## Sub-agent Call Ledger

Each entry: **ID → type → model → purpose → prompt file → output file**.

| ID | Agent Type | Model | Purpose | Input | Output |
|----|-----------|-------|---------|-------|--------|
| A0 | Explore | sonnet | Gather UI fingerprints across projects | (inline prompt) | `/tmp/claude-ui-fingerprints.md` |
| A1 | general-purpose | opus | Write persona v1 | `/tmp/claude-ui-fingerprints.md` | `/tmp/designer-persona-v1.md` |
| A2 | general-purpose | opus | Validate persona v1 | `/tmp/designer-persona-v1.md` | `/tmp/designer-persona-v1-review.md` |
| A3 | general-purpose | opus | Write persona v2 | v1 + v1-review | `/tmp/designer-persona-v2.md` |
| A4 | general-purpose | opus | Validate persona v2 | v2 | `/tmp/designer-persona-v2-review.md` |
| A5 | general-purpose | opus | Write persona v3 (final) | v2 + v2-review | `~/.claude/personas/designer-reviewer.md` |
| A6 | general-purpose | opus | Validate persona v3 (sanity pass) | final persona | `/tmp/designer-persona-v3-review.md` |

Phase C (screenshot reviews) — 8 calls, one per screenshot, using the
`designer-reviewer` persona as a system-prompt prelude. See
`~/.claude/assets/screenshots/pm2-manage-review/REVIEW_LOG.md`.

---

## Iteration Protocol

1. **Writer prompt (A1, A3, A5):**
   - Receives: brief + project UI fingerprints + (on iteration 2+) prior
     version + critique
   - Writes a complete, standalone persona file (not a diff)
   - Must end with a self-evaluation: "what I improved this round"

2. **Validator prompt (A2, A4, A6):**
   - Receives: persona file only (no prior context)
   - Critiques on 4 axes: concreteness, calibration to user's taste,
     actionability for screenshot review, coverage gaps
   - Outputs a numbered issue list with severity + suggested fix

3. **Rule:** writer never sees its own previous version's critique until
   a fresh validator call — keeps validation independent.

---

## Reuse Instructions

To reuse this persona for a new design review:

```
Read ~/.claude/personas/designer-reviewer.md
Then review [screenshot/URL] using the persona's review protocol.
```

To build a *different* expert persona (e.g. "security-reviewer",
"API-reviewer"), copy this build log structure, swap the domain prompts,
and run the same 3-iteration write/validate loop.

---

## Call Transcripts

_Populated below as each sub-agent completes._

