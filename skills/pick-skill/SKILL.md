---
name: pick-skill
description: The front door when the right instrument is not obvious. Two jobs. Retrieval, for "I half-remember a skill exists", answered with a ranked shortlist you pick from by number, never a single guess. Routing, for work of a known shape, answered from the chain map (plan, build, validate, experience) and the domain fronts (/ui, /plan, /validate, /magi). Every run ends with a summary block whose "next time" row teaches the direct one-hop query. Use when the user says "pick a skill", "is there a skill for", "what do we have for", or describes work without naming an instrument.
allowed-tools: Read, Bash, Glob, Grep, Skill
argument-hint: "[what you want done, or the half-remembered thing]"
user-invocable: true
---

## Brief

Answers "which instrument?" in the two shapes that question actually arrives.
A recall-shaped ask (a faint memory that something exists) gets a ranked
shortlist to eyeball, because for fuzzy queries a single confident pick is
wrong even when it is right. A known-shape ask (the work's stage is clear)
gets routed through the chain map. It routes and retrieves; it never does the
task itself.

## Step 0: Load shared guidelines

Read `~/.claude/skills/GUIDELINES.md` and apply it for the run.

## Phase 1: Classify the ask

Three cases, checked in order:

1. **Already named.** The user typed or named a specific skill. Run it via the
   `Skill` tool and stop. This router exists to remove a recall tax, never to
   add a hop.
2. **Recall-shaped.** The ask sounds like "is there a skill for X", "we had
   something that does Y", "pick something relevant", or a `/pick-skill` with a
   vague argument. Go to Phase 2A.
3. **Known-shape work.** The ask describes work to do (build this, check this,
   write this, decide this) without naming an instrument. Go to Phase 2B.

Before classifying, run the goal-versus-wording precheck: the words are a
sample of the intent, not its boundary (`rules/literal-request-over-intent.md`,
the account's most recurrent blind spot, and a router is where it does the
most damage). Name the goal in one line first; route the goal.

## Phase 2A: Retrieval, the shortlist contract

1. **Regenerate, then read the index.** Always regenerate first; it is under a
   second, and staleness is what makes a search lie:
   ```bash
   bash ~/.claude/scripts/skills-index.sh
   ```
   Then search `~/.claude/skills/00-index.md` with `rg` on the user's terms AND
   your own synonyms for them. Plugin skills are not in the index; check the
   session skill roster for those before declaring absence.

   **Sources beyond the index, when the index alone is thin.** The subsystems
   already carry routing signal. Three more surfaces, in order, stopping when
   the shortlist is full:
   - the `triggers:` frontmatter across `rules/`, `features/`, and
     `conventions/`. Those `topic:` and `phrase:` triggers exist precisely to
     match asks to files.
   - `~/.claude/personas/README.md` for working-mode routes.
   - `bash ~/.claude/scripts/skill-log.sh summary`, which breaks shortlist ties
     by historical acceptance instead of by vibe.

   When a session-start dream lesson (`[L:...]` tag) names a pattern relevant
   to the route, honor it and cite its tag. The citation is what reinforces
   the i-dream loop.
2. **Build the shortlist.** 3 to 7 candidates, each with its one-line gist from
   the index. Fewer than 3 only when the catalogue genuinely holds fewer
   plausible matches; never exactly 1 unless the match is literal.
3. **Present as a plain numbered menu.** Mark your top pick with a one-line
   reason. Numbered plain text only: the inputs dialogs and AskUserQuestion are
   unusable in the owner's fullscreen TUI
   (`memory: feedback_askuserquestion_tui_fullscreen`).
4. **The user picks a number, says go (accept the marked pick), or says none.**
   On none: name the 2 or 3 closest partials and offer `/create-skill`. Stop
   there; do not improvise the task without a skill.

5. **A miss feeds the improvement loop.** A retrieval that found nothing, or a
   shortlist the user rejected outright, is a catalogue gap, not just a failed
   run. File it before stopping: `bash ~/.claude/scripts/propose.sh add` for a
   concrete missing skill, or `/pin-for-dream` when the gap is a pattern worth
   the dream cycle's attention. One filing, not both.

## Phase 2B: Known-shape work, the chain map

The chain is the spine: intent, then plan, then code, then validation, then
experience. Ask "where in the chain is this ask?" and route the stage. Running
the whole chain end to end with gates is `/bloop`.

| Stage | The ask sounds like | Instrument |
|---|---|---|
| intent, unsettled | "should we", "which approach", "I don't know what I want" | `/magi` for contested calls; `/ui-direction` for visual taste |
| plan | "how would we build this", "spec this out" | `/plan` (routes on six needs); `/build-change` for non-UI changes; `/build-ui` for pages |
| code | "do it", "implement the plan" | main agent inline; `/bloop` when it should carry its own gates |
| validate | "is this right", "check it", "review my work" | `/validate` (routes on seven questions); `/skeptical-review` for adversarial audit |
| experience | "this feels wrong", "is the screen done" | `/ui` front door; `/ui-gripe` confusion; `/ui-categorical-check` bug classes |
| research | "what's true about X", "find sources" | `/deep-research` heavy report; `/cogitate` topic file |
| prose, docs, comments | "write it up", "de-slop this", "document X", "clean the comments" | `/write-docs` docs; `/ste-writing` plain rewrites; `/cleanup-comments` comment passes; `python3 ~/.claude/scripts/style/prose-lint.py` for a lint verdict |

**The writing lane crosses every stage.** Nearly every stage emits prose, and
the slop problem is fought by standing overwatch (the prose-smell stop gate,
prose-lint, the style watchers) regardless of what this router picks. Route to
the prose row for deliberate writing work; never treat routing as the slop
defense. That defense is the hooks'.

When a stage's instrument is genuinely ambiguous inside one row, apply the
shortlist contract from 2A to just that row instead of guessing.

## Phase 3: Hand off

Invoke exactly one skill via the `Skill` tool, carrying: the user's verbatim
ask, the named goal from Phase 1, and (retrieval path) which shortlist entry
they picked. Confirm once before invoking only when the user has not already
signaled execute; a terse "go" or a numbered pick IS the confirmation.

Do not assert what the receiving skill does internally (what it reads, what it
runs, what it produces). Describe only what you hand it. Asserting a receiving
skill's behavior is the defect shape indicted twice in the router-plan reviews.

Before invoking, emit the machine-consumable line:

```
ROUTE: /<skill> — mode: retrieval|chain|named — <one-line why> — confidence: high|medium|low
```

On the no-match path emit instead:

```
ROUTE: none — closest: /<a>, /<b> — suggest: /create-skill
```

## Phase 4: Record the run

```bash
bash ~/.claude/scripts/skill-log.sh record pick-skill \
  --task "<the ask, trimmed to a line>" \
  --outcome unknown \
  --corrections 0 \
  --note "mode=<retrieval|chain|named> routed=<skill> shortlist=<picked n of k | n/a>"
```

`--outcome unknown` is the honest default; this skill stops at the hand-off.
Use `revised` with `--corrections 1` when the user rejected the shortlist or
overrode the route, because a wrong pick is exactly the rework this exists to
prevent. Read the trend with
`bash ~/.claude/scripts/skill-log.sh summary --skill pick-skill`; the signal is
the shortlist rejection rate.

## Phase 5: Close the run, and teach the direct path

After the invoked skill finishes, always end with this block, so the owner
learns the direct query instead of staying reliant on routing:

```
── pick-skill run summary ──────────────────────────
ran:        <every skill/process in order, one line>
procedure:  <the overall approach devised for the ask, 1-2 lines>
next time:  <the direct query that skips this router, e.g.
            "/generate-pdf notes.md" or "/ui fix the settings page">
────────────────────────────────────────────────────
```

The `next time` row is the point: name the most direct phrasing that would
have reached the same result in one hop. When the routing hop was genuinely
necessary (the ask was truly ambiguous), say that instead; do not invent false
directness. If the run surfaced anything the subsystems should keep (a
recurring gap, a mis-route pattern), it was already filed in 2A.5 or Phase 4;
this block only reports, never files.

## When NOT to use

- The instrument is already named. Type it or run it.
- A one-line fix or a pure conversation. Just answer.
- A UI ask where `/ui` obviously applies. Go straight there; this router
  defers to the domain fronts, it does not wrap them.

## Done-condition

- [ ] Goal named in one line before classifying
- [ ] Mode named: retrieval, chain, or named
- [ ] Retrieval: index regenerated, shortlist of 3 to 7 shown as a numbered
      menu, user picked
- [ ] Exactly one skill invoked, verbatim ask carried, no receiving-skill
      internals asserted
- [ ] `ROUTE:` line emitted; run recorded via `skill-log.sh`
- [ ] Retrieval miss or rejected shortlist filed (propose.sh or /pin-for-dream)
- [ ] Run closed with the summary block, including the `next time` direct query

## See also

- `~/.claude/skills/00-index.md` the retrieval surface, regenerated by
  `~/.claude/scripts/skills-index.sh`
- `/ui`, `/plan`, `/validate` the domain fronts this defers to
- `/bloop` the whole chain with gates; `/magi` contested decisions
- `/create-skill` the no-match fallback
- `rules/literal-request-over-intent.md` the precheck this applies at the door
