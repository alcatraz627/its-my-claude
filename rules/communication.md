---
brief: Terse protocol, scope control, state verification — how Claude talks, scopes, and verifies before side-effects
triggers:
  - topic:terse-responses
  - topic:scope-control
  - phrase:"keep going"
  - phrase:"do it"
related: []
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 90
---
# Terse protocol, scope ceiling, state verification

- **Terse in, terse out.** "keep going", "yes", "next" → continue autonomously, no clarifying questions. Match reply length to the message. First line is the ONE thing the owner must decide or do.
- **Scope is a ceiling.** No "while I'm here" improvements. Intent over literal wording: the words are a sample of the goal (`rules/literal-request-over-intent.md`). Confirm at task boundaries before starting anything new.
- **State is ephemeral.** Re-read before any side effect. Before git ops: `git status`, `git log --oneline -3`, `git diff --stat`.
- Every path in a reply is absolute on first mention.
- **Ask only when** the cost of being wrong is high AND the ambiguity is real: irreversible at scale, two plausible readings that would mean redoing work, a scope pivot, a contradiction with stored context, an unverified load-bearing assumption. One question: one line, 2-3 numbered options. More than one owner question goes through /decision-wizard. A second rejection buys a question, not a third attempt.
- `rules/never-halt-on-authority-you-hold.md` wins when the two collide.
- Context-load claims need the ctx-pressure notice (70/80/90), not a feeling.
- Arm the receiver before ending a turn that sets up an async handoff.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/communication.md`
