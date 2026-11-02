---
brief: When a PreToolUse hook injects an advisory nudge (additionalContext), surface it to the user in your reply as a bordered callout, because it is invisible to them otherwise
triggers:
  - topic:hook-nudge
  - phrase:"hook additional context"
  - phrase:"PreToolUse"
related:
  - conventions/hook-authoring-and-review.md
  - features/hooks-tui-limits.md
paths:
  # autoload opt-out (prime-demotion-0901, owner D1a + card agreed, 2026-09-01):
  # disclosed on demand, not always-on. Gist stays in rules/00-index.md; newer hooks carry the surface instruction in their own message.
  # Sentinel below never matches a real file. Revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 365
---

# Surface hook nudges to the user

A PreToolUse hook's `additionalContext` reaches **you (the agent) only**, and the
user never sees it. A hook that wants the owner to see something should send
`systemMessage`, which shows on their screen with no model turn (see the channel rule in
`conventions/hook-authoring-and-review.md`). So this rule covers the nudges that still come
as `additionalContext`: if one is worth acting on, it is worth telling the human about.

## The rule

When a `PreToolUse:… hook additional context:` reminder arrives, **surface it in
your reply** as a bordered callout, then say what you are doing about it. Don't
silently absorb it, because the user asked to see these.

Render it as box-drawing in a markdown code block (NOT the `gum` binary, since gum's
terminal output is clobbered by the TUI and box-drawing in your reply renders
reliably):

```
┌─ ⚠ hook · <hook-name> ───────────────────────
│ <the nudge, in your own words, 1–2 lines>
│ → <what you're doing: complying / why not>
└───────────────────────────────────────────────
```

## When NOT to

- If the nudge is a clear false positive, still surface it (one line) and say you are
  dismissing it and why. Visibility beats silent judgment.
- If an identical nudge repeats within the same turn, surface it once.

## Why agent-mediated (not mechanical)

A nudge sent as `additionalContext` reaches only the model, so the model has to pass it
on. A new hook meant for the owner should use `systemMessage` instead. Hooks fire rarely
(only on their specific patterns), so surfacing each one is low-volume and adds little noise.
