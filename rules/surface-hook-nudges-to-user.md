---
brief: When a PreToolUse hook injects an advisory nudge (additionalContext), surface it to the user in your reply as a bordered callout — it's invisible to them otherwise
triggers:
  - topic:hook-nudge
  - phrase:"hook additional context"
  - phrase:"PreToolUse"
related:
  - conventions/hook-authoring-and-review.md
  - features/hooks-tui-limits.md
tier: 1
category: rules
updated: 2026-06-01
stale_after_days: 365
---

# Surface hook nudges to the user

A PreToolUse hook's `additionalContext` reaches **you (the agent) only** — the
user never sees it. There is NO non-blocking channel that puts it in their
transcript mechanically (stderr, systemMessage, and `/dev/tty` are all
invisible/clobbered — see `features/hooks-tui-limits.md`). So if a hook nudge is
worth acting on, it's worth telling the human about: **you are the only path to
their transcript.**

## The rule

When a `PreToolUse:… hook additional context:` reminder arrives, **surface it in
your reply** as a bordered callout, then say what you're doing about it. Don't
silently absorb it — the user asked to see these.

Render it as box-drawing in a markdown code block (NOT the `gum` binary — gum's
terminal output is clobbered by the TUI; box-drawing in your reply renders
reliably):

```
┌─ ⚠ hook · <hook-name> ───────────────────────
│ <the nudge, in your own words, 1–2 lines>
│ → <what you're doing: complying / why not>
└───────────────────────────────────────────────
```

## When NOT to

- The nudge is a clear false positive → still surface it (one line) + say you're
  dismissing it and why. Visibility over silent judgment.
- Repeated identical nudge within the same turn → surface once.

## Why agent-mediated (not mechanical)

The platform has no non-blocking hook→user-transcript channel (verified 2026-06-01
across stderr / systemMessage / /dev/tty). Agent-surfacing is the only way to get
a per-incident nudge into the transcript. It's ~reliable, not 100% mechanical —
the cost the platform forces. Hooks fire rarely (only on their specific
patterns), so surfacing each is low-volume, not noise.
