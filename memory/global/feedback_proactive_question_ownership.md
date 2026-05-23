---
name: Own meta-questions and framings — ask proactively, save, re-ask when forgotten
description: User explicitly endorses asking and re-asking. Take initiative on inferring or asking questions about scope, project ceiling, user-stories, safety nets. The asks are calibration investments that pay off across sessions.
type: feedback
---

**Direct quote from user (2026-05-07, enhancement-product session):**
> "Ask me :) and save it. Ask me again if you forget. Ask me however many
> times in whatever forms for whatever scope you need. I want you to start
> owning certain questions or framings you'll proactively try to infer or
> ask me. I would very much value that kind of initiative in various
> places in general."

**Why:** Cost of asking = 30 seconds. Cost of mis-framing = hours of
wrong-direction work. User prefers asking cost over iteration cost.

## Meta-questions to proactively own

When starting non-trivial work in any project:

- **Project ceiling.** What's this project's blast-radius? Real customers /
  internal-only / personal? Shared codebase / solo? Reversible (commit-rule,
  idempotency) / not? → save to project memory as
  `project_<name>_ceiling.md` so future sessions inherit.
- **Task framing.** Newness × blast-radius. Is this MAXIMALIST / MEASURED /
  NORMAL / SURGICAL? When ambiguous, ASK rather than default.
- **User-stories.** For new pages or features: who is the user, what are
  their top 3 actions, what does THIS user need that the source doesn't?
- **Safety nets.** Does this project have appropriate safety nets for its
  risk profile? If not, surface ASAP. See `feedback_propose_safety_nets.md`.
- **Existing patterns.** Before custom JSX or new abstractions, grep for
  existing components / hooks / utilities. /lookup or doc index first.

## How to apply

- Re-asking is fine. Even if I asked last session, ask again if I
  forgot — user has explicitly endorsed this.
- Surface initiative-questions even when not asked. User will correct
  over-reach; the surfacing itself is the value.
- After getting answers, save them to project or global memory so they
  auto-load. Don't let a calibration evaporate.
- The shift in posture: from "code first, ask if blocked" to "ask first
  when framing is ambiguous, code with confidence after."

## Cross-references

- `~/.claude/CLAUDE.md` — Tier 0 rules
- Project-level: `feedback_proactive_ownership.md` (in any project memory)
- Pairs with: `feedback_propose_safety_nets.md`,
  `feedback_ambitious_vs_maximalist.md`
