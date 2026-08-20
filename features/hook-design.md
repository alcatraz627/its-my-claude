---
brief: When designing a hook, weight its false positives by cost-of-false-fire, not raw FP rate — then match the consequence (block vs warn vs nudge) to that cost. A cheap-to-dismiss false fire on a high-value guard is worth keeping; a costly one on a low-value guard gets muted on sight.
triggers:
  - topic:hook-design
  - topic:false-positives
  - phrase:"build a hook"
  - phrase:"hook false positive"
  - phrase:"should this hook block"
related:
  - features/declared-ready-stop-hook.md
  - features/hooks-tui-limits.md
  - rules/surface-hook-nudges-to-user.md
tier: 2
category: features
updated: 2026-07-05
stale_after_days: 180
---

# Hook design — price false fires by cost, then match the consequence

A hook is a bet: it fires on a pattern in exchange for some rate of false fires.
Whether that bet is worth making is **not** a function of the false-positive rate
alone — it is the FP rate times the cost of each false fire, weighed against the
value of each true fire. A guard that false-fires often but costs nearly nothing
to dismiss, on a failure that is expensive when it slips through, is a good bet
even at a high FP rate. The reflex to "disable the noisy hook" reads raw
frequency and misses this.

## The two questions, in order

1. **What does one false fire cost the agent?** A block on `git push` costs a
   full stop plus a re-approval round — expensive. A one-line nudge the agent
   dismisses with "wiring it next edit" costs almost nothing. An extra `Read`
   that forces filesystem grounding costs one cheap tool call — and may be
   *valuable* even when it "false"-fires, because it corrects an ungrounded
   claim.
2. **Match the consequence to that cost.** Three tiers:
   - **block (exit 2 / `decision:block`)** — only for catastrophic, irreversible,
     or shared-state actions where a wrong pass is far worse than a wrong stop
     (credential writes, `git push`, `rm`, prod deploys). Reserve blocking for
     high cost-of-*miss*.
   - **warn (additionalContext nudge)** — for frequent-but-recoverable patterns
     where a false fire is cheap to ignore (speculative-export, prefer-rg). The
     agent self-corrects or dismisses in one line.
   - **nudge / log-only** — for signals you want to measure before you trust,
     or that are advisory by nature.

## The third question: what does the reader get when you DO block?

Both questions above price the wrong-fire. This one prices the right one, and it
is what decides whether the same defect should block on one surface and only
advise on another.

**Ask whether a fallback floor exists.** When the gate stops an artifact, does
the reader still get something true, or do they get nothing?

- **A floor exists, so blocking is cheap.** The CI PR-body path discards a bad
  body and ships the previous good prose, or the mechanical commit summary. The
  reviewer still gets a true, structured document. Blocking there costs a draft.
- **No floor, so blocking is expensive.** A code review discarded for a style
  violation loses a FINDING. There is no second copy and no degraded version,
  nobody learns it existed, and a false negative in a defect report is invisible
  by construction. Never block a review.

The tempting formulation is content-type, that shape may block while judgment may
not. That is not the line. The line is the floor. Two surfaces can carry the same
check and correctly reach opposite answers because one degrades to something and
the other degrades to silence.

Corollary, and it is what makes the rule usable: a gate you want but cannot
afford becomes affordable the moment you build a floor under it. Reach for the
fallback before you weaken the check.

Provenance: worked out with the CI PR-bot operator over IPC, 2026-08-15, after I
argued never-block for reviews and they ruled block-on-both-missing for bodies.
Neither of us had named the asymmetry until they did.

## Worked examples from this machine

- `guard-structural-claim` measured **~98% FP** over 959 transcripts and was
  headed for disable. The right call was to keep it: each false fire costs one
  cheap `Read` that forces the agent to ground an authority claim in a file:line,
  which the user explicitly values. Only the *ungroundable* fire classes
  (meta-claims, person-owns, already-cited) were cut. Source affirm:
  `aff-20260702-121112-21`.
- `guard-speculative-export.sh` sits at a **~35% FP floor** and is deliberately
  **warn-only** — its header notes a block at that floor "would be muted on
  sight." A cheap-to-dismiss nudge at 35% FP is a good bet; a block at 35% FP is
  a self-inflicted mute.
- `guard-user-commit.sh` **blocks** with no self-liftable mute — because the
  cost-of-*miss* (an agent committing in a user-owned repo) is high and the true
  fire is exactly the thing being prevented. High cost-of-miss earns the block.

## The trap

Ranking hooks by raw FP rate and disabling the top of the list. That optimizes
the wrong quantity. A 40%-FP warn-nudge that catches a costly slip beats a
2%-FP block that mutes the whole hook the first time it false-fires on a push.
Weigh FP by cost-of-false-fire; design the consequence to the cost tolerance.

## A gate's number is only as true as the field it reads

Worked incident, 2026-08-20 (automation's session; the goal Stop hook, owned by
gcc-work, defect report in their mailbox; docs half relayed to docs-skill). The
hook blocked FOURTEEN consecutive stops on an armed "finish all" goal. Three
lessons for any hook that measures progress or demands output:

1. **A progress count reads a field, not the truth.** The hook counted tasks
   whose `blocked_on` FIELD was empty, while about two dozen stated their
   blocker in PROSE. 48 of 53 remaining tasks needed the owner, credentials, a
   usage-limit reset, or repos the agent cannot write to, and the count saw
   none of it. The only way to make the number fall was to build work the owner
   had explicitly reserved. A gate whose measure diverges from the record's
   real semantics creates pressure to violate the rulings it exists to serve.
2. **A gate that can state the reason it should stand down, and blocks anyway,
   has stopped measuring.** The hook's own message conceded, verbatim: "48 of
   the 53 remaining tasks cannot be finished by the assistant". It said that
   and blocked. If the message text can articulate the stand-down condition,
   the condition belongs in the code as an exit path.
3. **A hook that forces re-emission raises the load on every style gate
   downstream.** Each fire demanded a fresh summary; each summary grew; the
   prose-smell gate then fired on the drifted register (em-dashes, bold spam,
   emoji headers). Two gates in a feedback loop: one demanding output every
   turn, one punishing what repeated output drifts into. When a hook demands
   text, budget for what the demanded text does to the other gates.

The /wake CLEAN-HALT reconciliation (skills/wake/SKILL.md, same day, task #25)
carries the countermeasure for lesson 1: it classifies open task rows by
reading both the field and the prose, and treats a row whose stated blocker has
since cleared as agent-ready whatever its field says.

## Mute scope — file mutes are MACHINE-WIDE, not per-session

Every mute file in the hook set (`~/.claude/.no-<gate>`, `.model-tier-off`,
`.allow-cred-write`, `.no-postcompact-check`, `.no-sessionstart-inject`, …) is a
bare global path with no session or PID component (confirmed across 20+ hooks,
2026-07-09 multi-agent audit). Touching one
silences that hook for **every concurrent and future session on the machine**
until the file is removed — a session that mutes a gate for one gnarly edge case
and forgets to clean up strips the safety net from unrelated sessions with no
visible signal. Design and usage consequences:

- Prefer an env-var mute (`MODEL_TIER_OFF=1`-style, process-local) for one-shot
  needs when the hook offers one; reach for the file mute only when you really
  mean "off everywhere".
- If you touch a mute file, remove it in the same session — treat it like a held
  lock, not a setting.
- When building a new hook, offer both: an env var for process-scope and the
  file for machine-scope. A session-scoped file variant
  (`.no-<gate>.$SESSION_ID` checked before the global) is a filed proposal, not
  yet standard.
