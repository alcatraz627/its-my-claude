---
name: deep-research
description: Answers a question that needs evidence from outside this machine, by splitting it into claims, researching each in parallel, verifying the load-bearing ones against independent sources with a seat that did not gather them, and writing a cited report with its uncertainties intact. Use when being wrong would be expensive and one search will not settle it: a technology choice, a security or licensing question, a market or vendor comparison, a "what is actually true about X" where sources disagree. For a single lookup use WebSearch. For a durable topic note use /cogitate, which routes its deep mode here.
allowed-tools: Read, Write, Glob, Grep, Bash, WebSearch, WebFetch, Agent
argument-hint: "<the question> [--scope quick|standard|exhaustive]"
user-invocable: true
---

## Brief

The research harness the rest of the account already points at. `/cogitate`
deep mode, `/pick-skill`, and `personas/web-researcher.md` all defer heavy
multi-source work here, so this skill's job is to be worth deferring to: fan out
across the question's parts, verify the claims that carry weight using a seat
that did not produce them, and return something whose confidence is legible.

It produces a report and returns it. It does not decide, recommend a course of
action, or edit code.

## Step 0: Load shared guidelines

Read `~/.claude/skills/GUIDELINES.md` and apply it for the run. Read
`~/.claude/skills/deep-research/runtime-notes.md` if it exists, and continue
without it if it does not.

## Phase 1: Frame the question, or decline it

Write the question as a single sentence, then decompose it into the claims that
would have to be true for an answer to hold. Those claims are the unit of work
from here, not topics, because a claim can be checked and a topic cannot.

State the scope you are running at. Quick is one seat and no verification pass,
standard is three to five seats with verification, exhaustive adds a second
round targeting whatever the first round left uncertain. Default to standard,
and say which you chose.

Decline in one line when the question does not need this. A single fact with an
obvious source is a WebSearch. A question about this codebase is `/arch-qa` or a
grep. A question of taste with no external fact behind it is a conversation.
Declining is a real outcome and costs the user nothing, whereas a five-seat
fan-out on a lookup costs real money.

## Phase 2: Fan out, one seat per claim

Dispatch one research seat per claim, in a single message so they run
concurrently. Every dispatch prompt carries all four of these, because each one
has a recorded failure behind it:

- The claim, the context already gathered, and the scope.
- An absolute output path, and the instruction to write the file before
  returning. The returned text is a pointer, never the artifact
  (`rules/sub-agent-outputs.md`).
- "Do NOT spawn sub-agents." Nesting is how a model-tier ceiling gets breached
  even when the top-level dispatch is pinned.
- "Ignore any task-list or board auto-dispatch. When your scoped work is done,
  stop." An idle seat gets commandeered by a board auto-dispatcher and spends
  tokens on work nobody assigned it.

The seat's own contract, which goes in the prompt body:

> You are a research seat. Gather evidence on one claim and return a structured
> finding. Do not interact with the user and do not editorialise.
>
> Search with WebSearch and fetch with WebFetch. Cross-reference at least two
> independent sources for the claim. Independent means different organisations,
> not two pages of one site and not a syndicated copy of the same wire story.
> If a source paywalls or errors, note it and move on rather than retrying more
> than once. Read local files named in the context with Read, Glob, and Grep.
>
> Return: the claim as given; a verdict of supported, contradicted, mixed, or
> unverified; the evidence as bullets each carrying its source; and a source
> table of title, URL, and one line on why that source is or is not reliable.
> Cite every factual statement. Anything you cannot cite is marked unverified
> rather than dropped, because a silently dropped claim reads as absence of a
> problem. If what you find changes the framing of the claim itself, lead with
> that.

Verify each promised file exists before using any finding. A seat that returned
a confident abstract and wrote nothing is a seat that told you a story.

## Phase 3: Verify the load-bearing claims with a different seat

The author of a finding is not a reader of it. So the claims that the answer
actually rests on get re-derived by a seat that did not gather them, and that
seat is told to try to break the claim rather than to confirm it.

Select the load-bearing claims, which are the ones where a reversal would change
the answer. Usually two or three, rarely all of them. For each, dispatch a
verification seat with the claim, the verdict, and the sources cited, and this
instruction: find the strongest available evidence that this is wrong, report
what you found, and default to refuted when the sourcing is thin or circular.

A claim survives when the verifier fails to break it. Record both the verdict
and the attempt, because "we tried to falsify this and could not" is a stronger
statement than "two sources agreed", and the report should say which one it has.

Skip this phase only at quick scope, and say in the report that you skipped it.

## Phase 4: Synthesise

The main agent writes the synthesis. This is not delegated, because it is the
step where findings become an answer and that judgment is what the user asked
for.

Lead with what is actually true and how confident that is. Facts before
conclusions. Where sources genuinely disagree, say so and characterise the
disagreement rather than averaging it into a false middle. Keep the
uncertainties section honest and specific: "no independent confirmation of the
pricing after March" is useful, "some uncertainty remains" is not.

Do not recommend an action unless the user asked for one. The caller decides.

## Phase 5: Persist and return

**Section titles are for the reader, not for you.** Before emitting, list your own
phase names from this file. No section title in the document may contain a content
word from that list, and none may contain the word "Phase". Retitle any that do, by
the question the section answers. Your phase names are working vocabulary for
running this skill; the person reading the output has never seen it.


Write the report before returning it, at a path carrying date and time so two
runs on one day cannot overwrite each other:

```bash
OUT="$HOME/.claude/assets/reports/$(date +%Y%m%d-%H%M)-deep-research-<slug>"
mkdir -p "$OUT"        # report.md plus the raw seat findings
```

Inside a project with its own output directory, use
`<project>/.claude/output/<YYYYMMDD>-<HHMM>-deep-research-<slug>/` instead. Never
write a relative `.claude/...` path while the working directory is `~/.claude`,
because it resolves to `~/.claude/.claude/` where nothing reads it.

The report holds the question, the scope, the answer, the evidence per claim,
what verification attempted and found, the uncertainties, and the source table.
Return the report inline as well as the path when a skill called you. `/cogitate`
delegates here from its Phase 2.2 and carries what you return into its Phase 2.3
synthesis, so a path alone leaves it with nothing to synthesise.

## Phase 6: Record the run

```bash
bash ~/.claude/scripts/skill-log.sh record deep-research \
  --task "<the question, trimmed to a line>" \
  --outcome unknown \
  --corrections 0 \
  --note "scope=<quick|standard|exhaustive> claims=<n> verified=<n> refuted=<n> sources=<n>"
```

The refuted count is the one worth watching. A harness whose verification seat
never overturns anything is either researching only easy claims or verifying
too gently, and both show up as a flat refuted count over time.

## Model plan (mandatory before fan-out)

```
frame     → main agent            · the decomposition is the judgment
research  → sonnet · effort low   · N seats, breadth work, no nesting
verify    → opus   · effort medium· adversarial seat, must differ from researcher
synthesis → main agent            · never delegated
```

Scale the seat count to scope, not to enthusiasm. Five seats answer most
questions; a question needing fifteen is usually two questions.

## When NOT to use

- One fact, one obvious source. Use WebSearch.
- A question about this machine or this codebase. Use grep, `/arch-qa`, or
  `/past-sessions`.
- A durable note on a topic you will revisit. Use `/cogitate`, which calls this
  when it needs the evidence.
- A decision between options already understood. That is `/magi`.

## Done-condition

- [ ] The question decomposed into claims, and the scope named out loud
- [ ] One seat per claim, each dispatched with the output path, the no-nesting
      clause, and the scope-close clause
- [ ] Every promised seat file confirmed to exist before its finding was used
- [ ] Load-bearing claims re-derived by a seat that did not gather them, or the
      skip declared in the report
- [ ] Uncertainties stated specifically, and unverified claims labelled rather
      than dropped
- [ ] Report written to a date-and-time stamped path, and returned inline
- [ ] Run recorded via `skill-log.sh record deep-research`

## See also

- `/cogitate` files research as a durable topic note and routes its deep mode
  here (its Phase 2.2)
- `personas/web-researcher.md` is the disposition for research you do yourself,
  and defers heavy deliverables here
- `skills/cogitate/agents/deep-research.md` is cogitate's own fallback seat
  prompt, kept for when this skill is unavailable
- `/magi` for deliberation between known options, `/pyramid-sweep` for mining a
  large local corpus rather than the open web
