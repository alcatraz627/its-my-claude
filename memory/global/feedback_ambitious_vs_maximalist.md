---
name: Maximalist ≠ ambitious — agents fail at "tower without a spine"
description: Maximalist scope (wide but flat — many parallel small things) works for agents. Ambitious scope (tall stack of dependent layers) doesn't, because hallucination compounds across levels.
type: feedback
---

**Direct quote from user (2026-05-07):**
> "Maximalist is different from ambitious, yes. In my experience, ambitious
> does not work with agents since there's hallucination and a tower without
> a spine."

## The distinction

| | MAXIMALIST | AMBITIOUS |
|---|---|---|
| Shape | Wide, flat — many parallel small things | Tall, stacked — each layer depends on the last |
| Verifiability | Each piece independently checkable | Layer N+1 only verifies if layer N is correct |
| Failure mode | One piece wrong, others still useful | Compounding error → "tower without a spine" |
| Agent fit | ✓ Works | ✗ Fails |

## Examples

**Maximalist (works for agents):**
- Add 5 admin filters to a list page (each filter independently testable)
- Wire up cross-links to 4 related admin pages
- Add row-menu with 6 actions (each action invokable + checkable independently)
- Generate 10 different config presets

**Ambitious (does not work — request human design first):**
- "Build a new IA based on a workflow you infer from the code"
- "Design a state machine that orchestrates these 4 systems"
- "Refactor the data model and propagate the change through 8 layers"
- "Architect a plugin system from scratch with extension points"

## How to apply

- When tempted toward an "ambitious" framing, decompose to MAXIMALIST: find
  a way to make each piece verifiable independently.
- If decomposition isn't possible, the task isn't agent-shaped → flag this
  to the user, request human design or a smaller-scope mandate.
- For new pages or features in MAXIMALIST mode, build "many small,
  well-defined pieces" not "one architectural masterpiece."
- "Use as a canary" / "go YOLO" / "no harm if it breaks" usually means
  MAXIMALIST license, NOT ambitious license.

**Test for spine:** can each piece of the work be verified, rolled back,
or reasoned about WITHOUT depending on the others being correct? If yes →
MAXIMALIST-safe. If no → it's a tower; ask for human design first.

## Cross-references

- `~/.claude/CLAUDE.md` — Tier 0 rules
- Project-level: `feedback_ambitious_vs_maximalist.md` (in project memory)
- Pairs with: `feedback_proactive_question_ownership.md`,
  `feedback_propose_safety_nets.md`
