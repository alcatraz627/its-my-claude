---
name: pick-skill
description: Reads user intent, names the single best-matching skill from the catalogue, confirms once, then invokes it end-to-end.
allowed-tools: Read, Bash, Glob, Grep, Skill, mcp__inputs__confirm, mcp__inputs__text_input
argument-hint: "[prompt]"
user-invokable: true
---

## Brief

Routes a raw user prompt to the one skill (or dispatch agent) that best fits the intent,
confirms the choice once, then hands off. This is a thin heuristic router — you read the
catalogue, name the best match, and invoke it. The matching is your native judgment, not a
scoring algorithm you hand-roll.

## When to use

The user describes what they want in plain language and either doesn't know which skill fits,
or asks you to "find the right skill / command for this." If they already named a skill, just
run that one — no routing needed.

## The routing loop

1. **Read the intent.** Take `[prompt]` if passed, else ask once what they want to do
   (`mcp__inputs__text_input` or a plain question — not a gum prompt).

2. **Consult the catalogue.** Two sources, in order:
   - `~/.claude/personas/README.md` — the persona table (working-mode + dispatch roles) and
     which subsystem each routes toward.
   - The skill list already in your context (every `SKILL.md` description). If you need the
     full set, `Glob` `~/.claude/skills/*/SKILL.md` and read each frontmatter `description`.
   - For routing *between subsystems* (a heavy orchestrator vs a single skill), the map is
     `assets/reports/20260618-persona-dogfood/subsystem-inventory.md` (Layer 1 is the
     dispatch orchestrators).

3. **Name the single best match.** Pick the one skill whose purpose most directly serves the
   intent. Trust your read of the descriptions — you match intent to capability natively, so
   don't enumerate scores or rank every candidate. If two genuinely fit, name the closer one
   and say what would change the call.

4. **Confirm once.** State the chosen skill + a one-line why, then confirm with a single
   `mcp__inputs__confirm` (or accept a terse "yes/go" if the user already signaled execute).
   Do not gate each step behind a prompt — one confirm, then run.

5. **Invoke it.** Run the chosen skill via the `Skill` tool, passing the user's original
   prompt as context. The invoked skill owns the task from there — its workflow, tools, and
   output. Don't constrain it.

### When nothing fits

If no skill covers the intent, say so plainly, name the 2–3 closest partial matches with their
one-line purpose, and suggest `/create-skill` to build one. Stop there — don't improvise the
task without a skill.

## Heuristics for the common forks

- **Heavy, multi-perspective, or "should we" decision** → a Layer-1 orchestrator, not a single
  skill: `/magi` (deliberation on architecture / tradeoffs), `/skeptical-review` (adversarial
  code audit before "done"), `/deep-research` (cited multi-source report).
- **"Document / write up X"** → `/write-docs` (and adopt the `technical-doc-writer` persona to
  author it).
- **"Review my work / is this right"** → `/skeptical-review`.
- **"Research / what's true about X"** → `/deep-research` for a heavy report, `/cogitate` for a
  topic file.
- **A specific narrow op** (commit, report, scaffold, audit) → the matching single skill.

When the fork is between a single skill and an orchestrator, prefer the orchestrator only when
the intent is genuinely multi-step or contested — otherwise the single skill is cheaper.

## Output contract

Before invoking, emit one machine-consumable line so the parent agent (or a log) can read the
decision without parsing prose:

```
ROUTE: /<skill> — <one-line why> — confidence: high|medium|low
```

On the no-match path, emit instead:

```
ROUTE: none — closest: /<a>, /<b>, /<c> — suggest: /create-skill
```

After the invoked skill finishes, if it produced a markdown file, offer `/create-report` once
(don't force it). Then record a runtime-notes entry naming the prompt, the chosen skill, and
whether the match was right:

```bash
cat > /tmp/runtime-note-entry.md << 'ENTRY'
## pick-skill: routed to /<name> — [YYYY-MM-DD HH:MM]
**Purpose:** [what the prompt was trying to do]
**Insights:**
1. [what intent-keyword made the match]
2. [match accuracy — accepted / re-routed]
---
ENTRY
bash ~/.claude/skills/shared/prepend-runtime-note.sh "pick-skill" /tmp/runtime-note-entry.md
```

## Anti-patterns

- Gating each step behind `gum write` / `gum choose` / `gum confirm` — it stalls non-TTY and
  forked runs. One `mcp__inputs__confirm`, then run.
- Hand-rolling a scoring table that ranks every skill. You match intent to capability
  natively; the list is noise the parent must wade through.
- Running the task yourself instead of routing to a skill. If nothing fits, say so and stop.
- Invoking the chosen skill without the one confirm (unless the user already said go).

## See Also

- `~/.claude/personas/README.md` — the persona library this routes into (working-mode +
  dispatch roles).
- Layer-1 dispatch orchestrators: `/magi`, `/skeptical-review`, `/deep-research`, `/cogitate`,
  `/write-docs` — reach for these when a task exceeds one skill's scope.
- `assets/reports/20260618-persona-dogfood/subsystem-inventory.md` — full subsystem map for
  cross-routing.
- `/create-skill` — the no-match fallback.
