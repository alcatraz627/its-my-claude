---
name: atone
description: Records a mistake — gathers context, classifies severity (S1/S2/S3), and writes a structured entry to ~/.claude/atone/events.jsonl. For S3 events, also drafts an RCA file with a runnable procedure. Invoke after a user correction or when the atone-nudge hint fires.
allowed-tools: Read, Edit, Write, Bash, Grep
user-invokable: true
argument-hint: "[brief description of the mistake]"
---

## Brief

Logs a mistake to the global event log, classifies its severity, and (for S3) writes a post-mortem with a one-line procedure to prevent recurrence. The log is **append-only and kernel-locked** — once `atone.sh add` runs, the event is immutable, so accuracy at write time matters.

# Atone — Record a mistake

## Step 0: Load shared guidelines

Read `~/.claude/CLAUDE.md` Tier-0 sections on **corrections** and **mistake-patterns**. Apply the corrections ritual — state the mistake, identify the pattern, write the entry, fix it.

## Phase 1 — Gather context

Collect:

1. **The user's correction text** (or your own self-diagnosis if you noticed the mistake yourself).
2. **Recently-touched files** (last ~10 tool calls). Use `cat ~/.claude/wal.jsonl 2>/dev/null | tail -20 | jq -r '.target // empty' | sort -u` if available.
3. **Session id** from `$CLAUDE_SESSION_ID` env, or derive from `wal.jsonl`.

## Phase 2 — Search for an existing slug (reuse before invent)

```bash
bash ~/.claude/scripts/atone.sh slugs | head -30
# OR target a specific keyword:
bash ~/.claude/scripts/atone.sh slugs | rg -i "<keyword from the mistake>"
```

If a slug matches the pattern of this mistake, reuse it. Recurrences are how the system learns severity — every new line with the same slug bumps the recurrence count. If no slug matches, justify why this is a genuinely new pattern (not a re-phrasing of an existing one) before inventing.

**Same-session-repeat detection:** if the slug appears in `events.jsonl` from earlier in this session, the recurrence is in-session. Bump severity by one tier (S1→S2, S2→S3, S3 stays S3) and add tag `same-session-repeat`.

## Phase 2.5 — Defend, then let atone dispatch the juror

This phase catches the second failure mode: the agent over-capitulates and records an /atone for something it was actually right about. (The first failure mode — skipping /atone when it should record — is caught by the regular flow plus the Stop hook. This phase catches the inverse.)

### 2.5.1 — Write a 1-paragraph defense

In your own voice, write 4-6 sentences answering: *what did I do, and why was it the right action given what I knew?* Be honest. Don't pre-emptively concede if you actually believe you were right.

### 2.5.2 — Write the case file

Assemble the case as JSON and let `atone add --case-file` run the juror for you. You do not dispatch a juror sub-agent or call `atone juror` by hand on this path. As of 2026-05-29 `atone.sh add` owns the juror dispatch: you write a case file, pass `--case-file`, and atone runs the juror via `claude -p`, persists the verdict to disk, records the judgment, and gates — all in one call. This keeps you out of verdict composition (you cannot fabricate or misplace the verdict), and the verdict survives on disk so a lost context never forces a juror re-run.

The case file carries these JSON keys (use `jq -n` so it's always valid):

| Key | What goes in it |
|-----|-----------------|
| `slug` | The slug you'll use in the `add` |
| `user_callout` | The user's exact correction text — verbatim, not paraphrased |
| `agent_did` | 1-2 sentences: what specific action the agent took |
| `agent_defense` | The 1-paragraph defense from 2.5.1 |
| `context` | ≤500 chars: codebase area + task + scope |

```bash
jq -n \
  --arg uc "<user's exact correction text, VERBATIM>" \
  --arg ad "<what you did, 1-2 sentences>" \
  --arg adf "<your 1-paragraph defense from 2.5.1>" \
  --arg ctx "<codebase area + task + scope, ≤500 chars>" \
  --arg slug "<the slug you'll use in the add>" \
  '{slug:$slug, user_callout:$uc, agent_did:$ad, agent_defense:$adf, context:$ctx}' \
  > /tmp/atone-case-$$.json
```

If you ran `/skeptical-review` this session and its report is relevant, note its path — you'll pass it as `--review-report <path>` so the juror reads the grounded findings (otherwise the juror re-derives blind).

### 2.5.3 — The verdict is produced inside `atone add`

You do not parse a verdict in this phase. In Phase 4 you call:

```bash
bash ~/.claude/scripts/atone.sh add ... --severity S3 \
  --case-file /tmp/atone-case-$$.json [--review-report <skeptical-review path>]
```

atone then dispatches the juror (~20-40s), writes the verdict to `atone/verdicts/<session>-<slug>-<ts>.json`, records the judgment linked to the new event, and applies the verdict-threshold gate itself:

- `very-wrong` / `understandably-wrong` / `ambiguous` → the event is written.
- `probably-right` / `reasonably-right` → `add` refuses with **exit 5** (the juror cleared you). Surface the verdict to the user; retry with `ATONE_OVERRIDE_VERDICT="<why the user overrules>"` only if they do.
- juror unavailable (`claude -p` failed) → event written with `suspect_fields:[juror-unavailable:...]`, audited, not blocked.

## Phase 3 — Classify severity

| Tier | Trigger conditions |
|------|--------------------|
| **S3** | Destroyed user work · broke prod/deploy · lied to user · violated explicit policy · pushed broken code a 30-second check would have caught · same-session repeat of an assume-without-reading-code |
| **S2** | User had to correct your output · debug-time waste · no irreversible damage |
| **S1** | Cosmetic / re-work caught early · no downstream cost |

When ambiguous between two tiers, pick the higher one. Better to over-record than under-record.

## Phase 3.5 — How the juror verdict gates the write

The verdict determines what happens next, and the CLI enforces this at the data layer so a stale-spec session can't skip it silently. On the `--case-file` path, atone dispatches the juror itself (claude -p, fresh context), persists the verdict, records the judgment stamped `dispatched_by:atone`, and gates. You never compose or relay the verdict.

The two load-bearing gates:

- **exit 4** — no judgment within 15 min has this slug in `related_atone_slugs` (strict provenance).
- **exit 5** — the verdict is `probably-right` / `reasonably-right`, unless `ATONE_OVERRIDE_VERDICT="<reason>"` is set.

Two more conditions are auditable but not blocking: a matched judgment *without* `dispatched_by:atone` (a hand-recorded legacy verdict) flags the event `unverified-juror-provenance`; `ATONE_NO_JUROR=1` writes `juror_bypassed:true`. If the juror dispatch fails, the event records `juror-unavailable:<reason>` (fail-open) and the re-juror sweep (`atone resweep`) back-fills the verdict later.

### Default (`--case-file`) flow: atone branches for you

On the `--case-file` path you do not branch on the verdict or record the judgment yourself — `atone add` does both:

- **`very-wrong` / `understandably-wrong` / `ambiguous`** → the event is written; the judgment is recorded (`outcome:atoned`, linked to the event) and the verdict persisted to `atone/verdicts/`. Nothing more for you to do.
- **`probably-right` / `reasonably-right`** → `add` exits 5 ("juror cleared the agent"), records the judgment truthfully (`outcome:pending`, no event), and removes the draft RCA. This is the user-pushback signal. Surface the verdict to the user (the exit-5 message has it) and wait. If the user overrules, retry the same `add` with `ATONE_OVERRIDE_VERDICT="<reason>"` — the event is then written with `outcome:pushed-back-then-atoned`. If the user accepts the clear, do nothing — the judgment is already preserved for measurement.
- **juror unavailable** → event written with `suspect_fields:[juror-unavailable]`.

You never call `atone juror` by hand on this path, and you never re-record the judgment — doing so double-records.

<details>
<summary>Legacy manual flow (only when NOT using <code>--case-file</code>)</summary>

If you are recording without a case file (user-driven, or a verdict produced out-of-band), dispatch a juror sub-agent yourself, branch on its verdict, then record the judgment by hand:

- **Branch A** (`very-wrong` / `understandably-wrong` / `ambiguous`) → Phase 4, then `atone juror ... --outcome atoned --linked-event-id <new-event-id>`.
- **Branch B** (`probably-right` / `reasonably-right`) → push back to the user with the juror's reasoning and wait. Overruled → Phase 4 + `--outcome pushed-back-then-atoned`. Accepted → skip Phase 4–6, record `--outcome pushed-back-then-accepted`, tell the user the judgment is preserved for measurement.

```bash
bash ~/.claude/scripts/atone.sh juror \
  --user-callout "<verbatim>" --agent-did "<...>" --agent-defense "<your defense>" \
  --context "<codebase summary>" --verdict "<v>" --confidence "<c>" --reasoning "<r>" \
  --slips "<slip1|slip2>" --constraints "<c1|c2>" --should-have-done "<...>" \
  --related-slugs "<atone-slug-you-are-about-to-add> <other-related-slugs>" \
  --outcome "<atoned|pushed-back-then-atoned|pushed-back-then-accepted>" \
  --linked-event-id "<event-id-if-atoned-or-empty>"
```

</details>

Either way the judgment record is what makes the juror measurable — `bash ~/.claude/scripts/atone.sh judgments stats` shows the verdict distribution over time.

## Phase 4 — Draft the four required fields

| Field | What goes here |
|-------|---------------|
| `issue` | One paragraph — what happened, with file:line if applicable. |
| `cause` | Why it happened — the false assumption, the skipped step, the misread. |
| `fix` | What was done to repair it (in past tense). |
| `what_not_to_do` | Future-self instruction. Imperative. ≤2 sentences. |
| `precheck` (optional) | A yes/no check that resolves at draft time. *Required for S3.* |

The `precheck` is the highest-leverage field — it's the thing a future hinter can read and inject as an at-action-time check. Phrase it as:

> "Before X, run/check/grep Y. If Y returns Z, the right answer is W."

If you can't formulate a runnable precheck, leave it null and explain in `cause` why this pattern isn't yet preventable. That's useful data — it tells the consolidate cron not to draft a hook for this slug.

## Phase 5 — Write the event

For RCA content (S3 events), write source markdown only. Don't pipe a draft through `gum_table` / `gum_panel` / any TTY renderer before writing — renderer output is for terminals, not source files. Markdown tables use `| col | col |\n|---|---|\n| val | val |`, not column-aligned ASCII. `atone-rca-lint.sh` catches ASCII-render-as-source patterns at write time (exit 2 with specific reasons + a list of fixable issues), but it's easier to avoid the problem upstream.

The RCA file structure the lint enforces:
- YAML frontmatter at top (`---` ... `---` with id/date/severity/slug/project)
- Single-line H1 (`# title-on-one-line`)
- Required sections: `## TL;DR`, `## Procedure`
- `## Procedure` has the single at-action-time check, not 4 numbered steps
- No `…` characters in tables (signature of pre-rendered output)
- No 50%+ leading-indent on content lines

### Always assign a `--cluster` — do not leave it empty

The cluster letter lets recurrence be measured at the **family** level (several different slugs, one root cause) instead of per-slug. Leaving it empty is what made the 2026-05-19/20 code slips invisible as a family until the user noticed by hand. Pick from:

| Cluster | Family | Example slugs |
|---------|--------|---------------|
| A | Ungrounded assertion | claimed authority / structure / effort without reading code — `infra-before-grep`, `structural-claim-without-reading-code` |
| B | Claim-ready-before-runtime | declared "done / works" before exercising it |
| C | Literal-list-as-action | followed a list literally instead of the intent |
| D | Output-shape laziness | wrong or ungenerated output shape |
| E | Convention-blind code | ignored a sibling / existing pattern — `added-scope-without-checking-siblings`, `feature-built-without-precondition-guard` |

If the slug is already in `~/.claude/atone/cluster-map.tsv`, use that letter. If it's a new slug that fits a family, add it to the map too (one line) so the consolidation overlay and write-time assignment stay in sync. Leave `--cluster` empty only when the mistake genuinely fits no family.

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

For S3, also build the RCA content and pass `--rca-content`:

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

**If a hinter trigger fired earlier in this session for this same slug** (you saw `[atone-refresh]` or `[atone-nudge]` injection mentioning this slug, then the mistake happened anyway):

```bash
bash ~/.claude/scripts/atone.sh feedback \
  --kind fired-and-ignored \
  --slug <slug> \
  --event-id <the-id-from-add> \
  --notes "trigger fired N turns ago, didn't apply it"
```

**If a trigger fired and you did act on it** (avoided a mistake because of the trigger):

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

A failure mode observed 2026-05-15 (see `assets/reports/20260515-backend-session-tone-investigation/`): the user invited debate ("debate me, make your case if you disagree"); the agent responded with capitulation dressed up in self-critical atone-vocabulary. The user's clarifying correction: they want the agent to debate; they do not want flattery; "you're absolutely right" without evidence is suspicious.

When the user explicitly invites disagreement, the agent's job is to actually disagree if there's a case to make — not to agree quickly with self-critical framing. Agreement is fine only when it survives a real check; agreement-by-default under pressure is the failure mode, not the fix.

- ✓ Use atone-vocabulary self-reference when it's load-bearing: "Last week's atone on X applies here because <specific reason>. Here's where you're wrong and where I am: …"
- ✓ Capitulation is appropriate only when evidence supports the user's position. State the evidence.
- ✗ "You're absolutely right" without a justification chain is sycophancy. Treat it as a red flag in your own output.
- ✗ Citing a prior atone slug to perform self-criticism without engaging the disagreement is theatre. Drop the theatre.

If genuinely unsure whether you agree, say so plainly ("I'm not sure I disagree; let me check X first") instead of pre-emptively capitulating.

The earlier "don't critique the user's framing" guardrail was wrong — it pushed toward more sycophancy, not less. Removed and logged as atone slug `prescribed-flattery-as-fix-for-pushback` (S3, 2026-05-15).

## Notes

- **The skill writes immutable data.** Once `atone.sh add` runs, the event is git-committed and the file stays kernel append-only flagged. No edits afterward.
- **If you misclassify severity:** add a follow-up event with the same slug and a note in `cause` saying "(prior event #<id> mis-classified as Sx; correct severity should be Sy)". The system learns from new lines, not from edits.
- **For "I don't know what slug to use" cases:** invent one in kebab-case; the cron will surface duplicates during consolidation and propose a merge.
- **Read your own log periodically:** `bash ~/.claude/scripts/atone.sh slugs | head -10` shows the most-recurrent patterns. If you find yourself adding a slug similar to one near the top, use the existing one.

## Related

- CLI reference: `bash ~/.claude/scripts/atone.sh help`
- Curated view (auto-generated): `~/.claude/mistake-patterns.md`
- Full event log: `~/.claude/atone/events.jsonl` (read-only via `atone.sh list`)
- RCAs: `~/.claude/atone/rca/<id>.md`
- Recovery (escape hatch): `~/.claude/scripts/atone-unsafe-unlock.sh` (phrase-gated)
