---
name: magi
description: Multi-agent supervisor-led deliberation. DEFAULTS TO --mode lite (3 voters, no personas/jester/voting, ~$3-8/run with research on) for routine tradeoffs. Opt into --mode full (5 voters + jester + personas + voting + thorough rubric, ~$6-12/run) for architecture / design / "should we" / rewrite decisions. Sonnet downgrade cuts cost ~5x. Use when multiple perspectives + reasoned dismissal of dissent are valuable. Archive at ~/.claude/assets/magi/<task>/ for review. Token-aware. Per design doc 20260518-magi-design.md.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, Agent, mcp__inputs__form
argument-hint: "<task> [--voters N] [--model M] [--personas] [--jester] [--no-voting] [--temp-mode auto|shared|spread] [--no-research] [--validation light|thorough]"
user-invokable: true
---

## Brief

You are the supervisor. You design the prompt, spawn voter sub-agents in parallel, collect their proposals, run a voting round, write your own independent nomination, and produce a final artifact + report. This SKILL.md is the orchestration script — the numbered flow below is what you execute.

The full design — parameters, schemas, the validation DSL, jester mechanics, override rules — lives in `~/.claude/assets/docs/20260518-magi-design.md`. Read it once per session before running. Two migrations record the gates this skill enforces: `migrations/0020` (conformance gate) and `migrations/0021` (setup-independence + evidence partitioning).

## When to use

- User asks "should we X" / "X or Y" / "what's the best approach for Z"
- Architecture decisions, framework choices, rewrite-or-not, scope debates
- Anywhere multiple legitimate perspectives exist and you'd benefit from seeing them surfaced

## When NOT to use

- Pure correctness tasks with one right answer (bug fix, syntax error, schema mismatch) — single-agent does fine
- Throwaway questions; cost vs value won't justify N voters
- Tasks where the user wants you to reason directly, not delegate

---

## Phase 0 — Read design doc + parse args

Read `~/.claude/assets/docs/20260518-magi-design.md` once (especially § 1-9, 17). Then parse args:

```
/magi "<task>" [--mode lite|full] [other flags]
```

### Modes

The default mode is `lite` — it keeps the floor low so /magi stays reachable for routine tradeoffs. Use `--mode full` when you want the heavy ceremony (personas, jester, voting, thorough rubric).

| | `--mode lite` (DEFAULT) | `--mode full` (opt-in) |
|---|---|---|
| voters | 3 (no jester) | 5 (4 main + jester) or 7 (6+1) |
| model | opus (default), sonnet/haiku for cheaper | opus all |
| personas | OFF | auto-on for design tasks |
| jester | OFF | auto-on per § 2 markers |
| voting | OFF (supervisor picks directly) | ON (single round) |
| validation | light | thorough |
| research | ON (min **1** search) | ON (min 2 searches) |
| temp_mode | spread (auto-since-no-personas) | shared (since personas) |
| typical cost (Opus, research on) | **$3–8** | $6–12 |
| typical cost (Sonnet downgrade) | $0.30–1 | $1–3 |
| use for | routine tradeoff, "X or Y", well-documented decisions | architecture, rewrite, design, "should we", consequential |

Cost estimates were revised 2026-05-19 after first wild-run data: the earlier "$0.15–0.50" figure ignored web-search token cost (6-7 searches per voter × 60K tokens each was real). Lite defaults to `min-searches=1` to keep the floor low; pass `--min-searches 2` for stronger grounding at higher cost. Full mode retains min-searches=2 since the ceremony already implies investment.

Individual flags override mode defaults: `--voters N`, `--model M`, `--personas` / `--no-personas`, `--jester` / `--no-jester`, `--no-voting`, `--temp-mode auto|shared|spread`, `--no-research`, `--min-searches N`, `--validation light|thorough`.

Two extra knobs (added 2026-05-17):
- `--diverse` — opt-in mixed-model main pool (rotate Opus/Sonnet/Haiku per voter; random persona↔model assignment to avoid confounding). Defaults off; same-model pool is the default. Use for genuinely-consequential decisions where same-model blind spots are likely load-bearing.
- `--blind-vote` — skip Phase 5 supervisor independent nomination. Voters vote first; supervisor reads votes + proposals together and writes one rationale. One fewer phase, no pre-commitment ritual; loses the pre-vote-vs-actual comparison signal.

### Mode auto-escalation hint

If you classify the task as HIGH complexity AND the user passed no explicit `--mode`, suggest:
> "This task looks consequential (design / architecture / rewrite). Default `--mode lite` may underdeliver. Switch to `--mode full`? [y/N]"

If the user accepts → full. If they decline → proceed with lite. Don't auto-escalate silently.

## Phase 1 — Classify task, derive params, confirm with user

Classify the task:
- Complexity: LOW / MEDIUM / HIGH (design doc § 2 heuristic)
- Type: creative / convergent / analysis / mixed
- Persona-need: yes/no
- Jester-need: detect status-quo-risk markers (design, architect, rewrite, refactor, should-we, switch-to, replace, introduce). Exclusion (added 2026-05-17 per test data): skip jester for "compare-known-tools" patterns — task names 3+ specific competing tools (`X vs Y vs Z`), or phrasing like "choose between A, B, and C". These are well-trodden discourse where convergence is high and the jester adds framing but not outcome (the Turborepo/Nx/pnpm test case). An explicit `--jester` is still honored; this only affects auto-on detection.

Derive params per design doc § 2-6. Present via `mcp__inputs__form` for confirmation (pre-filled with defaults):

| Field | `lite` default | `full` default | User can override |
|---|---|---|---|
| `mode` | lite | full | ✓ |
| `voters` | 3 | 5 (or 7 high-complex) | ✓ |
| `model` | opus | opus | ✓ |
| `personas` | OFF | auto (on for design tasks) | ✓ |
| `jester` | OFF | auto (per § 2 markers) | ✓ |
| `voting` | OFF | ON | ✓ |
| `temp_mode` | spread | shared (with personas) | ✓ |
| `validation` | light | thorough | ✓ |
| `min_searches` | 1 | 2 | ✓ |

If the user cancels the form or accepts defaults, proceed.

Output a clear status line, e.g. — `Proceeding [--mode lite]: N=3 Opus voters, no personas/jester/voting, light validation, research=on (min 1 search). Est cost: $3–8.`

Or for full mode: `Proceeding [--mode full]: N=5 (4 Opus main + 1 Sonnet jester), personas=[architect, qa-lead, ux-eng, dev-velocity], voting=on, thorough rubric. Est cost: $6–12.`

To propose a model downgrade, use the exact format from design § 3:

```
PROPOSED DOWNGRADE: Sonnet for 7 voters (cost N=7 × Opus is ~$X;
Sonnet would save Y% with expected quality cost: <description>)
Proceed with Sonnet, or override to keep Opus?
```

Wait for the response. Default = stay with Opus.

## Phase 2 — Initialize archive (record params + the evidence manifest up front)

Pass resolved params to `init-archive` via `--params` so they're written atomically at creation — not in a later python step (that step was skipped in 3 of 4 audited runs, leaving `params:{}`; the Phase-11 conformance check now flags an empty params). The params must include **`voter_evidence`** — the per-voter distinct evidence slice (D1). This is the load-bearing field: it is what makes convergence *discovered* rather than *manufactured*, and `setup-check.sh` reads it.

```bash
PARAMS='{"mode":"full","voters":5,"model_main":"opus","model_jester":"sonnet",
  "personas":[...],"jester":true,"voting":true,"research":"thorough",
  "task_breadth":true,
  "voter_evidence":[
    {"voter":1,"slice":"<distinct primary source for v1>","model":"opus"},
    {"voter":2,"slice":"<a DIFFERENT source>","model":"opus"},
    {"voter":3,"slice":"<raw source, blind to any summary>","model":"opus"},
    {"voter":4,"slice":"<another distinct base>","model":"opus"},
    {"voter":5,"slice":"<external / best-practice>","model":"sonnet"}
  ]}'
ARCHIVE=$(bash ~/.claude/scripts/magi/init-archive.sh \
  --slug "<short-slug-from-task>" --prompt "<full-user-prompt>" --params "$PARAMS")
```

For a **breadth / "gather varied findings"** task the slices must differ (one voter the tests, one the reviews, one the raw transcript *blind to any digest*, one the canon, one external). Don't hand all voters the same corpus, and don't pre-write a supervisor *interpretive* baseline as the shared substrate — that is the manufactured-convergence conduit (a shared *factual* base is fine). For a convergent task (one right answer) partition by **sub-question/stance** instead of withholding shared facts. The full partitioning rules are in design § (evidence partitioning) / migration 0021. The script returns the archive root; all artifacts go inside.

## Phase 3 — Build voter prompts

For each voter:
1. Read the prompt template (design § 13)
2. Substitute task, persona-block (if any), validation criteria
3. Compute per-voter output path: `$ARCHIVE/03-voter-proposals/voter-<N>.md`
4. Write the prompt to `$ARCHIVE/02-voter-prompts/voter-<N>.md` (for audit)

For the jester: append the jester-block from design § 6, with a different model and opposite web access. Name its proposal `voter-jester.md` (not a number) — the Phase-11 conformance gate uses that filename (plus `params.jester:true`) to detect a full-mode panel, so an unnamed/numeric jester can let a skipped vote slip through.

If personas: look up existing ones in `~/.claude/personas/`. If missing, draft inline AND save to `~/.claude/personas/_proposed/<slug>-<sid>.md` per design § 5.

## Phase 4 — Dispatch voters in parallel

**Gate the setup before the spend (the deep companion to the voting gate):**

```bash
bash ~/.claude/scripts/magi/setup-check.sh "$ARCHIVE"   # exit 2 = echo-prone → STOP
```

An **exit-2 / CRITICAL** verdict (all voters share one slice, or a supervisor digest is the shared substrate) means the run is *structurally incapable* of distributed consensus — redesign the `voter_evidence` partition before dispatching. Don't spend Opus voters on an echo. Independence is created here, in setup; voting (Phase 6) merely *measures* it. A WARN (no different-model seat, `research:minimal` on breadth) should be fixed but doesn't hard-stop.

Then dispatch:

```
Single message, multiple Agent tool calls (one per voter).
Each agent gets:
  - The voter prompt — scoped to that voter's assigned evidence slice (Phase 2
    voter_evidence); tell it which source is ITS primary base and to ground there
  - The output path: $ARCHIVE/03-voter-proposals/voter-<N>.md
  - Instruction: "write before returning" + 5-8 bullet abstract format
  - allowed_tools: Read, Glob, Grep, WebSearch, WebFetch
  - `model` parameter (e.g., "opus" / "sonnet" / "haiku" per voter)
```

### 4.1 — Model selection per voter

- Default (no `--diverse`): all voters use `--model` (default opus). Jester opposite.
- With `--diverse`: rotate Opus / Sonnet / Haiku per voter index. Randomize persona→model mapping per session to avoid confounding (record the permutation in meta.json `voters[].model`).

### 4.2 — Capture cost

Each sub-agent response ends with a `<usage>total_tokens: N tool_uses: M duration_ms: T</usage>` block. After each agent returns, parse it and append to `meta.json` `voters[].tokens`. Only `total_tokens` is guaranteed present; the Agent tool's `<usage>` block exposes no separate input/output split (surfaced by the first wild run, 2026-05-18). If the block is missing/malformed, record `{"total_tokens": null, "note": "usage block missing/malformed"}`. Downstream cost computation (`cost-estimate.sh`) handles the missing split with a blended-rate heuristic (default 70% input / 30% output; override with `--io-split A/B`). The exact parsing snippet is in design § 13. Apply the same parsing in Phase 6.

### 4.3 — Verify

Per `rules/sub-agent-outputs.md`, each dispatch includes an absolute output path + "write before returning." After all return, verify the files exist:

```bash
for i in 1..N; do test -f "$ARCHIVE/03-voter-proposals/voter-$i.md" || echo "MISSING voter-$i"; done
```

If any failed, log to meta.json and proceed with N-1. Don't retry at proposal stage. (Retry is in scope at voting stage — see Phase 6.2.)

## Phase 5 — Write supervisor independent nomination first

Skip this phase entirely if `--blind-vote` is set. In blind-vote mode, the supervisor reads votes + proposals together in Phase 8 and writes one rationale — no pre-vote nomination file.

This is the audit trail. Before seeing votes, you read all proposals yourself and write your pick.

```
Read each $ARCHIVE/03-voter-proposals/voter-*.md
Pick the proposal you (the supervisor) consider best.
Write to: $ARCHIVE/05-supervisor-nomination.md
```

Format:

```markdown
# Supervisor's independent nomination

**Picked:** voter-N
**Read at:** <timestamp>
**Reasoning (before seeing votes):**

[Your honest read of why this proposal is strongest. ≥150 words.
Cite specific sections of the proposal. This will be compared to
the vote winner later; if you change your mind after seeing votes,
that's documented in the override section.]
```

## Phase 6 — Dispatch voting round (same voters, Round 2)

### 6.0 — Build anonymization map

A random per-session label remap breaks persona/name deference bias: shuffle `voter-A`..`voter-E` onto the true voter ids, write the permutation to `$ARCHIVE/04-voting/_anon-map.json` for audit, and have voters see anonymized labels in their voting prompt. The aggregator un-maps before writing the matrix; personas are revealed only in the final report (Phase 10). The exact shuffle snippet is in design § 13.

### 6.1 — Per-voter randomized proposal order

For each voter, randomly permute the order in which proposals are presented in the voting prompt. Record each per-voter permutation in `_anon-map.json`. This addresses documented position bias in the LLM-as-judge literature.

### 6.2 — Dispatch with retry-on-malformed

```
Single message, N parallel Agent tool calls.
Each voter gets the Round 2 prompt (design § 13) with:
  - Anonymized labels (per 6.0)
  - Their personal proposal-path permutation (per 6.1)
  - The rubric (light or thorough)
  - Output path: $ARCHIVE/04-voting/voter-<N>-scores.json
  - JSON format spec (strict — schema in design § 13)
```

After all return, attempt to parse each JSON. If voter-N returns malformed JSON:
- Retry once with an explicit prompt: "Your previous output had format errors at <line/issue>. Rewrite exactly per this schema: <schema>. Do not include markdown fences or commentary outside the JSON."
- If the second attempt also fails: log to meta.json `voters_dropped += 1` and continue with N-1.
- Per design § 15 + user feedback: malformed isn't grounds for instant drop — retry first.

### 6.3 — Verify + report

```bash
RESULT=$(bash ~/.claude/scripts/magi/aggregate-votes.sh "$ARCHIVE")
echo "$RESULT" | jq '.voters_scored, .voters_dropped, .warnings'
```

If `voters_dropped > 0`, surface the count + which voters in the final report.

## Phase 7 — Aggregate votes

```bash
RESULT=$(bash ~/.claude/scripts/magi/aggregate-votes.sh "$ARCHIVE")
echo "$RESULT" | jq
```

Returns: winner, winner_score, scope_axis_pstdev, scope_dissent_flagged.

Read the matrix + bias-matrix:
- `$ARCHIVE/04-voting/matrix.md`
- `$ARCHIVE/04-voting/bias-matrix.md`

Note any HIGH self-bias (Δ > 1.5), scope dissent (pstdev > 1.5), or a voter who scored 0/low from all peers (a groupthink-defense signal).

## Phase 8 — Supervisor decision

Phase 8 is post-voting. It is not a license to skip Phase 6. "Pick directly" below means the vote was clear and you agree with the winner — it presupposes Phase 6 ran and produced a matrix. The only sanctioned way to skip voting is the `--no-voting` flag set **at dispatch** (design §8). Do not skip Phase 6 mid-run and cite "pick directly / Phase-8 merge / convergence was obvious" — that is the exact rationalization voting exists to test, it discards the bias-matrix + scope-dissent signal, and the Phase-11 conformance gate (`conformance-check.sh`) will flag it as CRITICAL. If you believe the panel has genuinely converged, run the vote to prove it (it's cheap once proposals exist) — manufactured convergence (all voters fed one shared corpus) is exactly what a real scored, anonymized round catches.

Now compare your independent nomination (Phase 5) against the vote winner (Phase 7):
- Match → low-friction confirm
- Mismatch → override with a reasoned dismissal (RFC 7282 + design § 9)

Decision options:
- **Pick directly** — voting clear, supervisor agrees, no scope dissent
- **Pick + borrow** — pick X but borrow a specific point from Y
- **Merge** — synthesize from multiple
- **Use as reference, write fresh** — proposals all flawed but informed a better answer
- **Override winner** — supervisor disagrees with the vote; write ≥50 words rationale

Apply the minority-scope-dissent rule (design § 7): if scope std-dev > 1.5, the dissenting voter's argument gets explicit address in the rationale.

## Phase 9 — Write final artifact

```
$ARCHIVE/06-final-artifact.md
```

This is THE ANSWER to the user's question. Markdown. Self-contained. May reference voter proposals for detail but stands alone.

## Phase 10 — Write final report

```
$ARCHIVE/07-final-report.md
```

Human-readable summary. Sections:

```markdown
# MAGI report — <task title>

## Decision
[1-3 sentence outcome]

## Process
- Voters: N (M main + jester if applicable)
- Model: opus / sonnet
- Personas: [if any]
- Voting: on/off
- Cost: $X.XX (Y tokens, Z cache reads)

## Supervisor's pre-vote nomination vs voted winner
- Nomination: voter-X
- Voted winner: voter-Y
- Match? yes / no
- If no: [override rationale ≥50 words]

## Proposals (one-line summaries)
- voter-1 (persona): [short summary, link]
- voter-2 (persona): [short summary, link]
- ...
- voter-jester: [contrarian summary, link]

## Vote matrix
[link to matrix.md]

## Self-bias matrix
[link to bias-matrix.md]

## Dissenting concerns addressed
- voter-X raised [concern]. Addressed by [...] / Acknowledged as followup
- jester argued [view]. [rejected because / incorporated as / preserved as note]

## Followups
[any items spun out for later]

## Archive
$ARCHIVE
```

## Phase 11 — Cost + meta finalization (runs every run)

```bash
bash ~/.claude/scripts/magi/cost-estimate.sh "$ARCHIVE"
```

This updates meta.json totals from the per-voter `tokens` blocks captured in Phase 4.2 / 6 (real numbers, not estimates).

**Conformance gate (rides on this mandatory step).** `cost-estimate.sh` also runs `conformance-check.sh` and prints its verdict after the cost block. A **CRITICAL** verdict — most commonly *full-mode voting skipped without `--no-voting`* — makes the step exit non-zero. Do not declare the run done while a CRITICAL stands: either run the skipped phase, or (if a skip was genuinely intended) re-dispatch with `--no-voting` so the intent is recorded. WARN-level items (params/prompts/cost not persisted) should be fixed but don't block. This gate exists because the spec's voting mandate used to be advisory and four full-mode runs silently skipped voting on 2026-06-13 (see migration 0020 / the magi-audit report).

Then finalize meta.json's `finished_at` + `duration_seconds`:

```bash
python3 -c "
import json
from datetime import datetime, timezone
with open('$ARCHIVE/meta.json') as f: m = json.load(f)
m['finished_at'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
start = datetime.strptime(m['started_at'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)
end = datetime.strptime(m['finished_at'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)
m['duration_seconds'] = int((end-start).total_seconds())
with open('$ARCHIVE/meta.json', 'w') as f: json.dump(m, f, indent=2)
"
```

### End-of-run cost summary

Print this block to the user every run, regardless of mode (added 2026-05-17 per user feedback):

```
─────────────────────────────────────────────────────
  /magi cost — <slug>
─────────────────────────────────────────────────────
  Mode:           <lite | full>
  Voters:         N (M main + jester if applicable)
  Models used:    {opus: K, sonnet: L, haiku: P}
  Duration:       <wall seconds>
  Tokens:         <input> in / <output> out / <cache_read> cache
  Per voter:
    voter-1 (opus):     <input> in / <output> out  →  $X.XX
    voter-2 (opus):     ...                         →  $X.XX
    voter-jester (sonnet): ...                      →  $X.XX
  Total:          $X.XX
  % weekly limit: <pct if available, else "n/a">
─────────────────────────────────────────────────────
```

For `% weekly limit`: check env `CLAUDE_CODE_USAGE_WEEKLY_REMAINING_USD` or similar (Anthropic exposes session-stats via the `/session-stats` skill — call it or inspect its data). If unavailable, print "n/a" — don't speculate.

Print the final report path to the user + the archive root.

---

## Sub-skill flags (one-liner reference)

| Flag | Meaning |
|---|---|
| `--voters N` | Override voter count |
| `--model M` | opus / sonnet for main pool |
| `--personas` / `--no-personas` | Force on / off |
| `--jester` / `--no-jester` | Force on / off |
| `--no-voting` | Skip voting round |
| `--temp-mode shared\|spread\|auto` | Temperature policy |
| `--no-research` | Disable web search |
| `--min-searches N` | Require N citations |
| `--validation light\|thorough` | Rubric depth |
| `--debate-rounds N` | (not in MVP) |

---

## Notes for the supervisor (you)

- The sub-agent output rule (`rules/sub-agent-outputs.md`) applies: always give the voter an absolute output path + "write before returning" + verify with `test -f` before the voting round.
- Write the supervisor's independent nomination before voting aggregation. This is the audit trail proving you weren't anchored on the vote.
- Per RFC 7282, every dismissed objection gets a reasoned dismissal — not just when overriding.
- Per design § 7, scope dissents (high std-dev on the scope-alignment axis) get explicit treatment.
- The jester's argument is always addressed, even when rejected (design § 6).
- Honest disagreement is the design intent. If voters all agree completely, that's suspicious — note it.
- Cost is reported, not capped (in MVP).

## See also

- Design doc: `~/.claude/assets/docs/20260518-magi-design.md`
- Research foundation: `~/.claude/assets/docs/20260518-magi-research.md`
- Conformance gate: `migrations/0020` · setup-independence + evidence partitioning: `migrations/0021`
- Sub-agent output rule: `~/.claude/rules/sub-agent-outputs.md`
- Adjacent personas: `skeptical-reviewer` (scoped review) + `/arch-qa` (ground structural claims); `platform-builder` for design tradeoffs
- Affirm event for intelligent-disobedience over sycophancy: `aff-20260517-082422-d5`
