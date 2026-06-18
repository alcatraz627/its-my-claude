---
brief: How personas get picked up (the trigger) and how each usage is logged for later efficacy review — persona-log.sh + the dispatch-mechanical / working-mode-convention + nudge split.
triggers:
  - topic:personas
  - topic:persona-efficacy
  - tool:persona-log
  - phrase:which persona
  - phrase:persona usage
related:
  - personas/README.md
  - scripts/persona-log.sh
  - features/hinter-pipeline.md
tier: 2
category: features
updated: 2026-06-18
stale_after_days: 120
---

# Persona activation & efficacy logging

Two coupled questions about `~/.claude/personas/`: **when does a persona get picked up
(the trigger)**, and **how do we know afterward whether it helped (the residue trail)**.
Both hinge on the same fact — there is no central persona-activation event today — so they
share one mechanism.

## The activation asymmetry (the load-bearing fact)

`rg "personas/" skills/ scripts/ hooks/` returns only two mechanical consumers:
`atone-juror-dispatch.sh` (juror) and `skills/magi/SKILL.md` (the strategic triad). Every
other persona is **adopted implicitly** when the main agent reads the file after "use the X
persona" or after matching a README trigger condition. That splits activation into two
regimes, and each regime gets a different logging strategy:

| Regime | Personas | Activation | Logging |
|--------|----------|------------|---------|
| **Dispatch** | juror, skeptical-reviewer, greybeard/translator/pager-holder, doc-writer | a script/skill spawns a sub-agent | **mechanical** — the dispatch script calls `persona-log.sh` |
| **Working-mode** | planner, technical-doc-writer, web-researcher, researcher, data/fullstack-engineer, closer/platform-builder/pragmatist, art-director | main agent reads the file and adopts it | **convention + nudge** — the agent calls `persona-log.sh` at end of the work; a hook nudges if it forgets |

## The trigger (P4) — make pickup reliable, two layers

1. **Action-oriented frontmatter (done).** The `role:` line of each rewritten persona reads
   as a job + trigger ("inspect a change-set and surface every weakness", not "grizzled
   engineer"). Per Anthropic's subagent routing, the `description`/`role` field is what drives
   delegation — generic identities route worse. Each persona also carries a crisp **"When to
   adopt"** section (observable cues, not intent-guessing).
2. **A persona-suggest hint (proposed, P4 mechanism).** A `UserPromptSubmit` hinter (same
   pipeline as `features/hinter-pipeline.md`) that matches the prompt against each persona's
   trigger keywords and, on a strong match, injects one line: *"This looks like X — consider
   adopting `~/.claude/personas/X.md`."* Advisory, deduped per session, muteable. This is the
   only way a working-mode persona gets picked up *proactively* rather than on explicit ask.

## The residue trail (P5) — `persona-log.sh`

`scripts/persona-log.sh` appends one JSON event per invocation to
`personas/usage/events.jsonl` (append-only, mirrors atone/affirm). Success is not knowable at
write time, so an event stores **proxies + a self-assessment + a free-text note**, never a
fabricated success bit.

**Event schema** (empty/null fields omitted):

```json
{ "id":"puse-<ts>-<rand>", "ts":"<iso>", "persona":"skeptical-reviewer",
  "session":"<id>", "mode":"adopted|dispatched", "depth":"L1|L2|L3",
  "task":"<1-line>", "outcome":"accepted|revised|discarded|unknown",
  "loop":"converged|partial|skipped", "iterations":N, "corrections":N,
  "cost_tokens":N, "note":"what worked / what the persona missed" }
```

**Why these fields:** `outcome` + `corrections` are the strongest cheap proxies for "did it
help" (did the user keep the output; how many corrections/atone events followed); `loop`
tells whether the persona's refinement loop actually closed; `note` is the human-rateable
seed. The `summary` view aggregates per persona so trends surface despite per-row noise:

```bash
persona-log.sh summary                 # per-persona: outcome/loop/mode dist, avg corrections, last notes
persona-log.sh summary --persona juror --since 2026-06-01
persona-log.sh list --limit 20
```

### Recording — where the calls live

- **Dispatch (mechanical):** the dispatch script logs. `atone-juror-dispatch.sh` records
  `juror` after persisting the verdict (best-effort, never touches stdout). The
  `/skeptical-review` skill records `skeptical-reviewer` at its coverage-marker step.
- **Working-mode (convention):** the adopting agent runs one `persona-log.sh record <persona>
  --mode adopted ...` at the end of the persona's work. A single call (not start/stop) because
  a convention followed once is far more reliable than twice.
- **The nudge (proposed enforcement):** a `Stop` hook that fires when a `personas/*.md` was
  `Read` this session but no matching `record` event was appended — nudging the agent to log.
  Advisory + muteable (`touch ~/.claude/personas/usage/.nudge-off`), mirroring `no-task-nudge`
  / `atone-nudge`. Without it, working-mode logging is advisory-only and will be skipped (the
  `skill-spec-update-not-honored` lesson: a mandate with no data-path gate is opt-in).

### The efficacy review (the point of all this)

After a few weeks, `persona-log.sh summary` answers "which personas earn their keep": a
persona with mostly `discarded`/`revised` outcomes and high `corrections` is miscalibrated or
mis-triggered; one with `converged` loops and `accepted` outcomes is working. A later retro
pass can add a human rating per persona (affirm-style higher bar) on top of the proxies.

## Status (2026-06-18)

- ✅ `persona-log.sh` recorder + summarizer (built, tested)
- ✅ juror dispatch mechanical logging (wired, verified)
- ◑ `/skeptical-review` skill logging step
- ▢ persona-suggest hint (P4 mechanism)
- ▢ Stop nudge hook (working-mode enforcement)
- ▢ working-mode convention line in each persona / README

## See Also

- `scripts/persona-log.sh` — the recorder/summarizer (`persona-log.sh help`)
- `personas/README.md` — the persona catalog + trigger conditions
- `features/hinter-pipeline.md` — the hint pipeline the persona-suggest hint plugs into
- `rules/skill-spec-update-not-honored-by-running-session.md` — why the nudge gate matters
