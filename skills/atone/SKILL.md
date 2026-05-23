---
name: atone
description: Records a mistake — gathers context, classifies severity (S1/S2/S3), and writes a structured entry to ~/.claude/atone/events.jsonl. For S3 events, also drafts an RCA file with a runnable procedure. Invoke after a user correction or when the atone-nudge hint fires.
allowed-tools: Read, Edit, Write, Bash, Grep
user-invokable: true
argument-hint: "[brief description of the mistake]"
---

## Brief

Logs a mistake to the global event log, classifies its severity, and (for S3) writes a post-mortem with a one-line procedure to prevent recurrence. The event becomes immutable after write — kernel append-only flag — so accuracy at write time matters.

# Atone — Record a mistake

## Step 0: Load shared guidelines

Read `~/.claude/CLAUDE.md` Tier-0 sections on **corrections** and **mistake-patterns**. Apply the corrections ritual — state the mistake, identify the pattern, write the entry, fix it.

## Phase 1 — Gather context

Collect:

1. **The user's correction text** (or your own self-diagnosis if you noticed the mistake yourself).
2. **Recently-touched files** (last ~10 tool calls). Use `cat ~/.claude/wal.jsonl 2>/dev/null | tail -20 | jq -r '.target // empty' | sort -u` if available.
3. **Session id** from `$CLAUDE_SESSION_ID` env, or derive from `wal.jsonl`.

## Phase 2 — Search for an existing slug (REUSE before INVENT)

```bash
bash ~/.claude/scripts/atone.sh slugs | head -30
# OR target a specific keyword:
bash ~/.claude/scripts/atone.sh slugs | rg -i "<keyword from the mistake>"
```

If a slug matches the pattern of THIS mistake, **reuse it**. Recurrences are how the system learns severity — every new line with the same slug bumps recurrence count. If no slug matches, justify why this is a genuinely new pattern (not a re-phrasing of an existing one) before inventing.

**Same-session-repeat detection:** if the slug appears in `events.jsonl` from earlier in THIS session, the recurrence is in-session. Bump severity by one tier (S1→S2, S2→S3, S3 stays S3) and add tag `same-session-repeat`.

## Phase 2.5 — Defend + dispatch the juror

**This phase exists to catch the second failure mode**: the agent over-capitulates, records an /atone for something it was actually right about. The first failure mode (skipping /atone when it should record) is caught by the regular flow + the Stop hook. This phase catches the inverse.

### 2.5.1 — Write a 1-paragraph defense

In your own voice, write 4-6 sentences answering: *what did I do, and why was it the right action given what I knew?* Be honest. Don't pre-emptively concede if you actually believe you were right.

### 2.5.2 — Assemble the juror prompt

Required fields:

| Field | What goes in it |
|-------|-----------------|
| `user_callout` | The user's exact correction text — VERBATIM, not paraphrased |
| `agent_did` | 1-2 sentences: what specific action the agent took |
| `agent_defense` | The 1-paragraph defense from 2.5.1 |
| `context_summary` | ≤500 chars: codebase area + task + scope. Keep tight. |

### 2.5.3 — Dispatch the juror sub-agent

Read the persona at `~/.claude/personas/juror.md`, then dispatch via the Agent tool:

- `subagent_type`: `general-purpose`
- `prompt`: `<persona contents>` + `\n\n---\n\nCASE TO EVALUATE:\n` + `user_callout`, `agent_did`, `agent_defense`, `context_summary` (clearly labeled)
- `description`: "Juror verdict on /atone"

The juror has Bash access and is instructed to look up prior atone events + prior judgments before rendering its verdict. Wait for it to return — typically 30-90s.

### 2.5.4 — Parse the verdict

The juror returns JSON with shape:

```json
{
  "verdict": "very-wrong | understandably-wrong | ambiguous | probably-right | reasonably-right",
  "confidence": "low | medium | high",
  "reasoning": "...",
  "slips_identified": [...],
  "constraints_considered": [...],
  "should_have_done": "...",
  "related_atone_slugs": [...],
  "scope_note": "..."
}
```

If parsing fails (malformed JSON, timeout, dispatch error): default `verdict = ambiguous`, record this in `reasoning` ("juror dispatch failed — proceeding"), and continue to Phase 3.

## Phase 3 — Classify severity

| Tier | Trigger conditions |
|------|--------------------|
| **S3** | Destroyed user work · broke prod/deploy · lied to user · violated explicit policy · pushed broken code a 30-second check would have caught · same-session repeat of an assume-without-reading-code |
| **S2** | User had to correct your output · debug-time waste · no irreversible damage |
| **S1** | Cosmetic / re-work caught early · no downstream cost |

**When ambiguous between two tiers, pick the higher one.** Better to over-record than under-record.

## Phase 3.5 — Branch on the juror's verdict

The verdict determines what happens next. Do NOT skip this branching — it's the load-bearing piece of the anti-sycophancy layer.

> **Hardened 2026-05-17 — the CLI now enforces this branching at the data layer.**
> `atone add` will refuse with exit 4 if no judgment in the last 15 min has the
> event's slug in `related_atone_slugs` (strict match — the old OR-bypass via
> `linked_atone_event_id` was a hole). It will refuse with exit 5 if the matched
> verdict is `probably-right` or `reasonably-right` unless `ATONE_OVERRIDE_VERDICT=
> "<reason>"` is set in the env. A <10s juror→atone gap is marked as
> `suspect_fields: [synthetic-juror-suspected:gap_Xs]` on the event row. Passing
> `ATONE_NO_JUROR=1` is allowed but writes `juror_bypassed:true` on the event so
> the bypass is auditable, not silent. **Composing a fake juror line via
> `atone juror` in the same context as the atoning agent defeats the purpose** —
> the juror must be a dispatched sub-agent (Agent tool, fresh context).

### Branch A — `very-wrong` / `understandably-wrong` / `ambiguous`

Proceed to Phase 4 (draft fields). Use the juror's `reasoning` to inform the `cause` field — cite `slips_identified` and `constraints_considered`. After writing the event, record the judgment with `--outcome atoned` and `--linked-event-id <new-event-id>`.

### Branch B — `probably-right` / `reasonably-right`

**Stop. Do NOT auto-proceed to /atone.** Push back to the user with the juror's reasoning, then wait for the user's response.

Format your pushback like this:

```
Before I /atone — the juror flagged this as <verdict> (confidence: <X>).

Juror's reasoning: <reasoning>

Slips it found:        <slips_identified or "none">
Constraints considered: <constraints_considered or "none">
Related atone slugs:    <related_atone_slugs or "none">

I think I was right because: <my defense>.

Want me to /atone anyway, or reconsider the correction?
```

Then wait for the user's actual response. Do not assume the answer.

**If user overrules** (says: yes still atone, you are wrong, etc): proceed to Phase 4 normally. Severity may stay or drop one tier — your judgment. Record the judgment with `--outcome pushed-back-then-atoned`.

**If user accepts the pushback** (says: ok you're right, never mind, my bad): SKIP Phase 4-6. Do NOT write an atone event. Record the judgment with `--outcome pushed-back-then-accepted`. Tell the user: "OK — no atone recorded. The juror's reasoning is preserved as judgment `<id>` for measurement."

**If user response is ambiguous or asks a clarifying question**: answer it, then wait for the actual decision before recording anything.

### After branching — always record the judgment

Whether or not /atone proceeded:

```bash
bash ~/.claude/scripts/atone.sh juror \
  --user-callout "<verbatim>" \
  --agent-did "<...>" \
  --agent-defense "<your defense>" \
  --context "<codebase summary>" \
  --verdict "<juror verdict>" \
  --confidence "<juror confidence>" \
  --reasoning "<juror reasoning>" \
  --slips "<slip1|slip2>" \
  --constraints "<c1|c2>" \
  --should-have-done "<...>" \
  --related-slugs "<atone-slug-you-are-about-to-add> <other-related-slugs>" \
  --outcome "<atoned|pushed-back-then-atoned|pushed-back-then-accepted>" \
  --linked-event-id "<event-id-if-atoned-or-empty>"
```

This record is what makes the juror measurable. Over time, `bash ~/.claude/scripts/atone.sh judgments stats` shows the verdict distribution + how often pushbacks survived. Keep the data flowing.

## Phase 4 — Draft the four required fields

| Field | What goes here |
|-------|---------------|
| `issue` | One paragraph — what happened, with file:line if applicable. |
| `cause` | Why it happened — the false assumption, the skipped step, the misread. |
| `fix` | What was done to repair it (in past tense). |
| `what_not_to_do` | Future-self instruction. Imperative. ≤2 sentences. |
| `precheck` (optional) | A yes/no check that resolves at draft time. *Required for S3.* |

The `precheck` is the most important new field — it's the thing a future hinter could read and inject as an at-action-time check. Phrase it as:

> "Before X, run/check/grep Y. If Y returns Z, the right answer is W."

If you can't formulate a runnable precheck, leave it null AND explain in `cause` why this pattern isn't yet preventable. That's important data — it tells the consolidate cron NOT to draft a hook for this slug.

## Phase 5 — Write the event

**Critical for RCA content (S3 events): write SOURCE markdown only.** Do NOT pipe a draft through `gum_table` / `gum_panel` / any TTY renderer before writing. Renderer output is for terminals, not source files. Markdown tables use `| col | col |\n|---|---|\n| val | val |` — write that, not column-aligned ASCII. `atone-rca-lint.sh` will catch ASCII-render-as-source patterns at write time (you'll see exit 2 with specific reasons + a list of fixable issues), but avoid the problem upstream.

The RCA file structure that the lint enforces:
- YAML frontmatter at top (`---` ... `---` with id/date/severity/slug/project)
- Single-line H1 (`# title-on-one-line`)
- Required sections: `## TL;DR`, `## Procedure`
- `## Procedure` has the **single at-action-time check**, not 4 numbered steps
- No `…` characters in tables (signature of pre-rendered output)
- No 50%+ leading-indent on content lines

### Always assign a `--cluster` — do not leave it empty

The cluster letter is what lets recurrence be measured at the **family** level
(several different slugs, one root cause) instead of per-slug. Leaving it empty
is exactly what made the 2026-05-19/20 code slips invisible as a family until
the user noticed by hand. Pick from:

| Cluster | Family | Example slugs |
|---------|--------|---------------|
| A | Ungrounded assertion | claimed authority / structure / effort without reading code — `infra-before-grep`, `structural-claim-without-reading-code` |
| B | Claim-ready-before-runtime | declared "done / works" before exercising it |
| C | Literal-list-as-action | followed a list literally instead of the intent |
| D | Output-shape laziness | wrong or ungenerated output shape |
| E | Convention-blind code | ignored a sibling / existing pattern — `added-scope-without-checking-siblings`, `feature-built-without-precondition-guard` |

If the slug is already in `~/.claude/atone/cluster-map.tsv`, **use that letter**.
If it's a new slug that fits a family, add it to the map too (one line) so the
consolidation overlay and write-time assignment stay in sync. Leave `--cluster`
empty only when the mistake genuinely fits no family.

For S2 / S1:

```bash
bash ~/.claude/scripts/atone.sh add \
  --slug "<chosen-or-existing-slug>" \
  --title "<≤80-char one-line summary>" \
  --issue "<...>" \
  --cause "<...>" \
  --fix "<...>" \
  --what-not "<...>" \
  --precheck "<...>" \
  --severity S2 \
  --tags "<space-separated>" \
  --cluster "<A|B|C|D|E — see cluster-map.tsv; empty only if no family fits>" \
  --files "<file1:line file2:line>" \
  --project "$(pwd)"
```

For S3, ALSO build the RCA content and pass `--rca-content`:

```bash
RCA_CONTENT=$(cat <<'RCA_EOF'
---
date: 2026-MM-DD
severity: S3
slug: <slug>
project: <path>
---

# RCA: <title>

## TL;DR
One paragraph: what happened, why, the fix.

## Symptom progression
| When | Symptom | What I assumed | What I did | Why it was wrong |
|------|---------|----------------|------------|------------------|
| t=0  | ...     | ...            | ...        | ...              |

## Root cause (numbered layers)
1. ...
2. ...

## The fix
Code/process diff. Be specific.

## What I should have done differently
- ...
- ...
- ...

## Procedure (REQUIRED — runnable at draft time)
The single at-action-time check that would have prevented this:

> Before [trigger action]: run/check [specific verification].
> If [condition], the right answer is [alternative].

## Cross-references
- Related slugs: <list>
- Possible hook: <regex on what tool>
RCA_EOF
)

bash ~/.claude/scripts/atone.sh add \
  --slug "..." --title "..." --issue "..." --cause "..." \
  --fix "..." --what-not "..." --precheck "..." \
  --severity S3 --tags "..." \
  --rca-content "$RCA_CONTENT"
```

## Phase 6 — Refresh triggers + record feedback + report

`atone.sh add` already kicks off `--triggers-only` in the background, so triggers.json refreshes within ~1s.

**If a hinter trigger DID fire earlier in this session for this same slug** (you saw `[atone-refresh]` or `[atone-nudge]` injection mentioning this slug, then the mistake happened anyway):

```bash
bash ~/.claude/scripts/atone.sh feedback \
  --kind fired-and-ignored \
  --slug <slug> \
  --event-id <the-id-from-add> \
  --notes "trigger fired N turns ago, didn't apply it"
```

**If a trigger fired and you DID act on it** (avoided a mistake because of the trigger):

```bash
bash ~/.claude/scripts/atone.sh feedback \
  --kind fired-and-useful \
  --slug <slug> \
  --notes "trigger prevented the X mistake"
```

This is the feedback loop for L2 dream integration — over time the system learns which triggers actually work vs which are noise.

**Then report to the user:**

```
Logged <id> (severity S2, slug recurrence #3).
What-not-to-do appended to top-20 curated view.
[For S3:] RCA: ~/.claude/atone/rca/<id>.md
```

## Conversational guardrail — when invited to debate, actually debate

A failure mode observed 2026-05-15 (see `assets/reports/20260515-backend-session-tone-investigation/`): the user invited debate ("debate me, make your case if you disagree"); the agent responded with capitulation dressed up in self-critical atone-vocabulary. The user's clarifying correction: **they want the agent to debate; they do not want flattery; "you're absolutely right" without evidence is suspicious.**

**Rule**: when the user explicitly invites disagreement, the agent's job is to actually disagree if there's a case to make — not to agree quickly with self-critical framing. Agreement is fine ONLY when it survives a real check; agreement-by-default under pressure is the failure mode, not the fix.

- ✓ Use atone-vocabulary self-reference when it's load-bearing: "Last week's atone on X applies here because <specific reason>. Here's where you're wrong and where I am: …"
- ✓ Capitulation is appropriate ONLY when evidence supports the user's position. State the evidence.
- ✗ "You're absolutely right" without a justification chain is sycophancy. Treat as a red flag in your own output.
- ✗ Citing a prior atone slug to perform self-criticism without actually engaging the disagreement is theatre. Drop the theatre.

If genuinely unsure whether you agree: say so plainly ("I'm not sure I disagree; let me check X first") instead of pre-emptively capitulating.

**The earlier "don't critique the user's framing" guardrail was wrong** — it pushed toward MORE sycophancy, not less. Removed and logged as atone slug `prescribed-flattery-as-fix-for-pushback` (S3, 2026-05-15).

## Notes

- **The skill writes immutable data.** Once `atone.sh add` runs, the event is git-committed and the file remains kernel append-only flagged. No edits afterward.
- **If you misclassify severity:** add a follow-up event with the same slug and a note in `cause` saying "(prior event #<id> mis-classified as Sx; correct severity should be Sy)". The system learns from new lines, not from edits.
- **For "I don't know what slug to use" cases:** invent one in kebab-case; the cron will surface duplicates during consolidation and propose a merge.
- **Read your own log periodically:** `bash ~/.claude/scripts/atone.sh slugs | head -10` shows the most-recurrent patterns. If you find yourself adding a slug that's similar to one near the top, use the existing one.

## Related

- CLI reference: `bash ~/.claude/scripts/atone.sh help`
- Curated view (auto-generated): `~/.claude/mistake-patterns.md`
- Full event log: `~/.claude/atone/events.jsonl` (read-only via `atone.sh list`)
- RCAs: `~/.claude/atone/rca/<id>.md`
- Recovery (escape hatch): `~/.claude/scripts/atone-unsafe-unlock.sh` (phrase-gated)
