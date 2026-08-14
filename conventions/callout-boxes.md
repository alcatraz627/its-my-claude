---
brief: One anatomy for every inline callout box (hook nudges, gate blocks, subagent dispatch/landing), with the glyph vocabulary, the arrow action line, width and dedup rules, and the box-versus-line-tag boundary.
triggers:
  - topic:callout-boxes
  - topic:hook-output
  - phrase:"pretty box"
  - phrase:"surface this box"
  - tool:hook_box
related:
  - rules/surface-hook-nudges-to-user.md
  - features/hooks-tui-limits.md
  - features/hook-design.md
tier: 2
category: conventions
updated: 2026-08-14
stale_after_days: 180
---

# Callout boxes, one dialect

Every inline callout the owner sees, whether a hook composed it or the agent
did, wears the same anatomy. Before this spec the account ran five dialects
for one job (agent hook-callouts, hook_box blocks, subagent boxes, boxless
gate prose, ambient tags); the reader paid the translation tax each time.

## The anatomy

```
┌─ <glyph> <kind> · <name> ──────────────────────────
│ <body: what happened, wrapped, 1-4 lines>
│ → <the action: complying / dismissing + why / what happens next>
└─────────────────────────────────────────────────────
```

Four rules carry the whole spec:

1. **The `→` line is the point.** A box exists because someone must act or
   decide; the arrow line says who is doing what. A box without an action line
   is ambient context wearing a costume, and belongs in a line-tag instead.
2. **Glyphs are a closed set.** `⚠` advisory (act or dismiss) · `⛔` block
   (the turn cannot proceed as-is) · `⇢` dispatch (something was sent out) ·
   `⇠` landing (something came back, verify before trusting). A new glyph
   means editing this spec first.
3. **Kind names the emitter class, name the instance:** `hook ·
   guard-zsh-path-var`, `gate · prose-smell`, `subagent · box-probe-2`,
   `ipc · enh-credits`. Lowercase, one word for kind.
4. **Width 72, one box per event, dedup at the source.** Repeats of an
   identical nudge in one turn surface once (rules/surface-hook-nudges). An
   emitter that can re-fire carries its own parked-once marker, the way
   subagent-box.sh absorbs SubagentStop re-fires.

## Who renders what

- **Hook-side:** compose through `hook_box()` in
  `scripts/hooks/hook-common.sh`; never hand-roll the rails. The box travels
  as additionalContext with a surface-verbatim instruction, because no hook
  channel reaches the transcript directly (features/hooks-tui-limits.md).
- **Agent-side:** reproduce the box verbatim inside a fenced code block, then
  continue. When the agent composes its own (a hook sent plain text), it uses
  this anatomy, not an improvised one.
- **Box or tag?** Needs an action or a decision: box. Ambient context the
  reader may ignore (ctx-pressure, style-watch, dream lessons, ipc informs
  with no reply owed): line-tag, exactly as today. Tags never grow rails.

## Out of scope

The ceremonial records (trace.sh dump/catchup renders) are their own
owner-ruled design and never use this anatomy. gum-tui skill panels are
interactive TUI output, also separate.

## Migration notes

prose-smell's block box already routes through hook_box; its heavy-caps title
becomes `⛔ gate · prose-smell` on next touch. Boxless gate prose (rg-replace
guard, review-gate, declared-ready Stop feedback) adopts the anatomy
opportunistically, when each file is next edited for cause; no sweep commit.
