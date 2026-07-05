---
brief: Design doctrine for tools Claude writes that Claude itself will drive — telemetry ladder, ref contracts, digest deltas, errors-that-propose-fixes; distilled from the fiber-snatcher V2 build + 6-source research panel
triggers:
  - topic:agent-first-tools
  - topic:tools-for-claude
  - phrase:"tool for an agent"
  - phrase:"agent will use this"
  - topic:cli-for-agents
related:
  - conventions/cli-help-design.md
  - conventions/tui-design.md
  - rules/sub-agent-outputs.md
tier: 2
category: conventions
updated: 2026-07-04
stale_after_days: 180
---

# Agent-first tools — design doctrine

When building a tool whose PRIMARY user is Claude (a CLI another session will
drive, a daemon an agent queries, a debug surface for agent-led work), the
user is not a human with eyes and patience — it is blind-but-fast,
mechanical-but-diligent, paying attention-cost for every output byte, and
needing next-step discovery built into every response. Design for that user.

Provenance: the fiber-snatcher V2 rebuild (2026-07, ~/Code/Claude/
invasion-of-the-fiber-snatchers, branch v2) — full research with sources in
its `.claude/output/20260703-v2-plan/agent-first-research.md`, usage evidence
in `usage-mining.md` (205 real invocations analyzed: 18% of calls died on
ambiguity errors with no fix proposal, 106 manual sleeps, 28 screenshots as
the only observation channel).

## The five obligations (map the agent's handicaps to tool duties)

| Agent property | Tool obligation |
|---|---|
| Blind but fast | Every action returns a compact state delta; observation never costs a second call |
| Mechanical but diligent | Waits, retries, verification live inside actions, not in agent judgment |
| Attention opportunity-cost | Budget every output: scope, truncate, paginate, rank; heavy payloads go to files |
| Needs next-step discovery | Every response carries affordances; errors PROPOSE the fix (candidates, hints) |
| Expresses ambiguity while blind | Accept intent, return ranked candidates in ONE round trip; never "narrow it" without the list |

## The 15 principles (each earned its place; sources in the research doc)

1. Observe as structured semantic text; screenshot only to verify.
2. Mint short refs in observations; actions take refs, never raw selectors.
3. Staleness is an explicit contract — a dead ref says so and says what to do.
4. Budget every observation (the 114K-token snapshot is the canonical failure).
5. Every action returns a post-action delta ("what changed because of me").
6. Never return silence — confirm empty results explicitly.
7. Errors propose the fix (ranked candidates, the exact next command).
8. Reject invalid input at submit time; don't repair after.
9. Auto-wait inside every action; tiny named wait vocabulary; no agent sleeps.
10. Offer framework-level settledness (query-idle, not text-appeared proxies).
11. Ship composite actions for known multi-step patterns.
12. Macros first-class: NL-authored once, cached resolution, deterministic replay.
13. Fuzzy targeting = ranked candidates from deterministic tiers, never open generation.
14. One actor per shared surface — serialize mutations or deltas corrupt.
15. Journal everything (including failures); the journal seeds macros and post-hoc debug.

## Lived additions the research didn't predict

- **Don't assume the app describes itself.** Principle 1 ("observe as structured
  semantic text") silently assumes the app HAS structured semantics — aria roles,
  labels, text. A driver for arbitrary apps meets low-accessibility pages where
  every DOM rung fails and the tool degrades to a useless component name. Fall
  through to structural inference and, when even that is ambiguous, hand the agent
  the raw evidence (icon, handler source, nearby text) — never a dead label. This
  is principle 13 applied to identity, not just to ambiguity.
- **The framework holds what the DOM doesn't.** A fiber-attached tool's real edge:
  a control's label often lives in a React PROP, not the DOM — a closed dropdown's
  menu items, an un-rendered tooltip's text. React builds those elements at the
  parent's render and hands them to the mounted trigger as prop VALUES; a
  conditional `{open && children}` gates MOUNTING, not the value's existence. So
  the content of an un-opened overlay is readable from the trigger's ancestor
  fiber props with no interaction — no sourcemap, no bundle, no mounting. Read the
  fiber for meaning, not just the DOM. (fiber-snatcher WP9.)
- **Honest unknowns beat fabricated calm**: when observation is impossible
  (document died mid-read), report `unknown`, never a value that implies
  "nothing happened".
- **The tool's own instrumentation must not pollute its telemetry** (ref
  minting tripping the mutation observer = false activity signals).
- **Identity needs a generation tag**: same-named things across document
  reloads silently alias without one.
- **Behavioral tests through the real entry path** (CLI → daemon → browser)
  catch what unit tests structurally cannot; the V2 checkpoint review found
  four load-bearing signal corruptions this way, all invisible to tsc and
  unit suites.

## When this applies

Building or reworking any tool Claude drives: local CLIs, daemons, MCP-ish
services, debug bridges. It does NOT mandate this shape for human-first tools
(a TUI for the user follows `conventions/tui-design.md` instead). When one
tool serves both, design the machine surface first and render the human view
from it.
