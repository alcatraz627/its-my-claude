---
brief: Writing is a UI surface with an audience. Identify the reader (human for comments/docs/PRs, agent for internal notes) and write meaning-first, never default-LLM register.
triggers:
  - topic:docs-work
  - topic:pr-description
  - topic:writing
  - phrase:"PR description"
  - phrase:"commit message"
  - skill:commit
  - skill:readme
  - skill:write-docs
related: [rules/comments.md, rules/pushback-and-self-criticism.md, conventions/doc-writing.md, rules/machine-token-where-human-words-belong.md]
tier: 2
category: rules
updated: 2026-09-01
stale_after_days: 120
---

# Audience-aware writing: identify the reader, write meaning-first

Writing is a UI surface, not a transport for facts. Before writing any prose, name
the reader and write so they derive MEANING first and facts second. The failure
this prevents: treating writing as a dump of correct facts, so structure and
decoration substitute for plain human phrasing (default-LLM register).

Graduated from atone `ai-smell-prose-against-stored-voice` (S3, `mist-20260619-194539-c9`);
RCA at `~/.claude/atone/rca/mist-20260619-194539-c9.md` carries the full pattern
catalog (verbatim examples plus human-voice rewrites).

## Identify the audience first

- **Human reader** (comments, docs, READMEs, PR descriptions, commit messages, any
  user-facing message). A PR description counts as docs. Write in a human voice:
  plain sentences, the point first, value before mechanism. This is where AI-smell
  does the most damage, because the user reads tone as a UI surface.
- **Agent reader** (internal gcc/claude notes, RCAs, runtime-notes, WAL,
  checkpoints). Dry and factual is fine, but it is still a surface a future agent
  reads to derive meaning first and facts second. Lead with the takeaway, then the
  detail. Terse is not structureless.

Both audiences want meaning-first. The variable is register, not whether meaning
leads. And "human" is not one register: a developer skimming a PR or changelog
wants dense, code-referenced, scannable text (file:line, flags, numbers, commit
names), while a non-engineer reading a guide wants prose. Match the register to the
specific reader. Two overcorrections fail the same way: a warm narrative essay
(it reads as feelings, not engineering) and telegraphic Label:fragment prose. Aim
for plain writing at the reader's altitude.

## Put it into action (the human-reader checklist)

Scan a draft for a human and cut these tells before sending:

- **Em-dashes.** Budget zero. Use commas, periods, parentheses, or "and".
- **Label:fragment rows** ("Must change: nothing required"). A human writes a
  sentence; reserve `Label:` for genuine key/value data.
- **Over-bulleting and bold-spam.** If every line is a bolded bullet, nothing is
  emphasized. Prefer prose; cap bold near one phrase per message.
- **Decoration as rigor.** No star insight boxes, traffic-light or section emoji to
  perform thoroughness. (The Explanatory output style's ★ blocks are exempt when
  they carry something not already in the reply or a file written this turn —
  the same boundary `dense-briefing-direct-answer.md` draws.) See [[pushback-and-self-criticism]].
- **Distrust after a settled decision.** If the user explicitly confirmed a call, do
  not re-file it as a "blocker" or "confirm this". Say it once if a doc needs the
  update, then drop it.
- **Headlining a self-introduced fix.** A problem this same session created and then
  fixed is a side-effect found during development, not a trophy. Fold it in low.
  The stronger form: a self-correction that consumes the reply while the actual
  question goes unanswered. Correcting yourself is more comfortable than answering
  and looks like diligence; finishing the correction is not finishing the answer.
  Re-read the question after the correction and answer it
  (mist-20260820-191945-b3).
- **Dry tech instead of value.** Say what a tool does for the reader and why they
  would want it, not its module list ("composable measure/drive/logs primitives").
- **Flattery or unrequested agenda.** No "you're absolutely right" without evidence,
  no option-menus the user did not ask for. Answer and stop. See
  [[pushback-and-self-criticism]].

## Situate a status answer, not just ground it

Grounding a claim (cite the file and line, read do not recall) is covered
everywhere; situating one is not, and an answer can be entirely grounded and
still useless because it describes a plan in a vacuum. Two duties for any answer
about queued or planned work, both from mist-20260820-191945-b3, where a correct,
quoted, checked answer still failed and the owner had to come back with the
question the answer should have made unnecessary:

- **Name the constraint in force.** One line: what governs this work today, and
  is it buildable under that. A wave of planned work whose runner was ruled off
  an hour ago is not "specified in doc 71", it is "specified in doc 71 and
  currently cannot run, because the seats it runs on are off for the week".
- **A ruling made this session is the frame, not background.** Recent decisions
  feel like shared context because you were there for them; the reader has no
  such feeling. If a ruling made this session changes the answer, that change IS
  the answer. Lead with it, never bury it as preamble.

## You cannot see your own AI-smell; route the final voice pass to a fresh reviewer

The most reliable finding about AI-smell is that the author is blind to their own:
the same agent that knows every tell writes them into its own prose and does not
notice. So for any non-trivial human-facing prose (a PR description, a doc, a
changelog), after your own edit, route the final voice pass to a fresh reviewer
that did not write it (a sub-agent, or `personas/doc-writer.md`). Trust your
self-review for facts; route it for style. This is the "You cannot see your own
voice" rule in `conventions/doc-writing.md`.

Two cheap gates come first, but neither replaces the fresh read:

- Run the mechanical find-and-flag (`conventions/doc-writing.md` §4 `rg`) plus an
  em-dash scan. Necessary, not sufficient: in the session that graduated this rule,
  a draft passed both clean while still reading as an essay, which is exactly why
  the fresh-reviewer step stays required.
- The §3 catalog there (~30 named tells: em-dash splicing, rule-of-three triads,
  bold-phrase-colon bullet armies, over-bolding, precision theater, defensive
  meta-framing) is the detailed version of the checklist above; read it for docs.

## Enforcement (mechanical, since 2026-07-10 — measure-first dry-run)

`scripts/hooks/prose-smell-stop.sh` (Stop hook) scans the final assistant message
(fenced code, inline code, blockquotes, and table rows stripped; <200-char
messages skipped). Two or more high-signal tells co-occurring (em-dash,
decoration-emoji headers, ≥3 Label:fragment rows, >5 bold spans, praise opener)
raise a visible WOULD-BLOCK note and a `block-dry` telemetry record; a real
`decision:block` fires only with `PROSE_SMELL_ENFORCE=1`. Both source RCAs asked
to "flag", and hook-design doctrine reserves blocking for high cost-of-miss, so
promotion to enforcement waits on fire-rate telemetry (review:
`assets/reports/20260710-queue-reviews/1.5a-prose-smell.md`). Single tells get a
plain note; ★ boxes and option-menu closers are warn-tier only (the Explanatory
output style and genuine forks are legitimate). Loop-safe and heed-tracked: an
identical message never re-fires, and a cleaned message records `heeded:true`.
Mute: `PROSE_SMELL_OFF=1` (process) · `touch ~/.claude/.no-prose-smell-gate`
(machine-wide until removed).

## The data half of this doctrine lives next door

This rule governs the prose YOU write. Its sibling,
[[machine-token-where-human-words-belong]], governs the values a MACHINE emits
that reach a person: a code, a raw scalar, a value's type, a sentinel rendered
as a name. Same principle, other direction, and the second one is easier to miss
because nothing in it reads as writing at all.

## Same root cause, other atones (reuse their notes)

- [[comments.md]]: comments are for humans first; the first sentence is
  code-agnostic. Same "name the reader" move at the function level.
- `conventions/doc-writing.md`: read the doc-writing guidelines before authoring
  docs. The "ChatGPT voice throughout" slip happened when they were skipped.
- `ascii-art-tables-instead-of-gum-tools`: write source, not rendered output. Another
  wrong-surface-for-the-reader slip.
- `literal-request-over-intent`: serve the intent (meaning), not the literal text.

## Diagnostic signal

You are about to send prose to a human and it contains an em-dash, a Label:fragment
row, a star or emoji decoration, a re-raised settled decision, or a tool described
by its architecture. Rewrite it plain first.
