---
brief: A pick-from palette of mobile todo/notes UX patterns (workflow blocks such as two-speed capture, triage gesture economy, overdue rituals and trust signaling, plus display patterns, interaction patterns and anti-patterns), mined from Notion/Todoist/Google Tasks/Keep/Obsidian/TickTick/Capacities dossiers (2026-07). Consult when designing or reviewing any notes/tasks/mobile-first UI.
triggers:
  - topic:mobile-ux
  - topic:ui-patterns
  - topic:todo-app
  - topic:notes-app
  - topic:capture-flow
  - phrase:"ux pattern palette"
  - skill:web-design
related:
  - conventions/visual-design.md
  - conventions/tui-design.md
tier: 2
category: conventions
updated: 2026-07-13
stale_after_days: 365
---

# Mobile UX pattern palette (todo / notes apps)

A reusable menu of patterns mined from seven leading mobile todo and note apps
(Notion, Todoist, Google Tasks, Google Keep, Obsidian, TickTick, Capacities)
in July 2026. Each pattern names the visible mechanic and the workflow it
exists to enable. The evidence dossiers and a worked example of judging these
against one product's identity live in `~/Code/Claude/data-forge/.claude/output/
20260713-app-ux-research/` (and `docs/ux-pattern-palette.md` there for the
verdict-annotated edition).

Use it two ways: as a build menu when designing a capture, list or task surface,
and as a review checklist when auditing one. Judge every pick against the
product's own identity contracts first. The worked example shows several
famous patterns correctly REFUSED because they fought the host identity.

## Workflow blocks (the layer above components)

1. **Two-speed data entry.** Split "capture fast, structure later" from
   "edit precisely" into visibly different modes. Natural-language parsing
   (dates, tags, priority) lives ONLY in the fast lane, rendered as visible
   tokens the user can tap to un-parse, and the full editor uses pickers. Never
   put a required decision in the fast lane. Default everything and file later.
2. **Triage as a gesture economy.** The two or three highest-frequency
   decisions (done, tomorrow, later) get single-motion gestures, such as a swipe
   with preset shortcuts baked into the revealed action, while the long
   tail keeps pickers. Pair every gesture with an undo net and never a confirm
   dialog. A configurable gesture map is the power-user extension, and
   two well-chosen fixed verbs serve most products better.
3. **Overdue as a designed ritual.** A named, guided one-at-a-time walk
   (reschedule, do or drop) over the overdue pile beats an ashamed scroll.
   Bulk "spread these across coming days" is the batch variant. Overdue
   recurring items never stack: choose once between advance-one and catch-up-all.
4. **Capture from anywhere.** Thought-saving must not require app launch.
   Offer share targets, home and lock widgets, quick-settings tiles, assistant verbs,
   and even messaging-channel inboxes. The app is where organizing happens.
5. **The trust spine.** Sync and offline state is either invisible until broken
   (feels magic, fails undiagnosable) or always visible and *named*, so
   choose deliberately. Offline capture must be indistinguishable from
   online. Conflicts deserve a preview and a copy-out escape hatch, and
   nothing is destroyed silently.
6. **Bursty capture.** Quick-add stays open after save (confirm-flash,
   clear, keep focus), because capture sessions are bursts and not single thoughts.
7. **Batch is a mode.** Long-press, multi-select, then a contextual command
   bar. Bulk operations get their own chrome and no per-item loop.

## Display patterns

- **State rides the action affordance.** Color or status sits on the checkbox or
  complete-control itself, and a separate badge column is wrong.
- **Previews render state, not text.** Use checklist glyphs (☐/☑), strike and demote done items,
  and summarize attachments and canvases by size, so the list
  communicates without opening anything.
- **Done is a counted, collapsed receipt.** It is a demoted expandable group
  with a count, and it is neither interleaved noise nor deletion.
- **One color, one alarm.** The fewer hues that speak, the louder the
  alarm hue reads. Color scarcity IS hierarchy.
- **The clock outranks importance in day views.** Timed items sort above
  high-priority undated ones inside "today" surfaces.
- **Views are cheap, chrome is expensive.** Saved queries become first-class
  nav chips, with show-if-not-empty visibility rules keeping the bar honest.
- **Kind shows as a mark.** A glyph plus a word (and neither a color nor a schema)
  distinguishes item kinds in a uniform list.

## Interaction patterns

- **Completion is a micro-moment.** Use a check-draw animation plus haptic
  (and an optional sound). The most-repeated interaction deserves the most
  feeling, and everything else stays still.
- **Slash and trigger-char insertion survives touch.** `/` block menus and
  link syntax belong on mobile too, surfaced via the toolbar.
- **The keyboard-adjacent toolbar is mobile's command palette**, and its
  slots deserve user remapping in power tools.
- **Caret-line raw reveal.** Rendered-always editing where only the
  cursor's line shows raw syntax gives one continuous mode with no edit/preview
  toggle (Obsidian Live Preview's defining feel).
- **Second tap deepens.** Re-tapping the active tab performs the tab's
  "go deeper" verb (today, top, inbox).
- **Home surface is a setting.** Which screen cold-launch opens is user
  business, decoupled from tab order, and synced across devices.
- **Edge-swipe overlays beat docked panels** on phones: summon, act,
  vanish.
- **Recurrence needs two anchors.** Schedule-anchored ("every Friday")
  and completion-anchored ("N days after I actually did it") serve
  different real habits, and shipping only one mis-serves half.
- **"Won't do" is a real ending.** A cancelled terminal status distinct
  from done keeps completion honest.
- **Checklist and subtask are different things.** Lightweight steps-within and children with
  their own metadata are two primitives, and collapsing them loses one.
- **Plan-date and deadline are different things.** "When I'll work on it" and "when it's due"
  are separate fields (see anti-pattern: no noun without its verbs).

## Anti-patterns (observed failures, not hypotheticals)

- **Full-parity webview mobile.** Desktop parity bought with cold-launch
  seconds is the most-complained-about trait of the biggest app studied.
- **Buried first-class structures.** An organization primitive that needs
  manual favoriting to reach navigation decays into disuse.
- **Sort modes that silently drop structure.** Hierarchy visible only
  under one sort order breaks the mental model exactly when triaging.
- **Backend swaps under a stable UI.** Migrating a feature's system of
  record while the chip looks unchanged (and silently dropping
  capabilities) is the deepest trust breach observed.
- **A field without a lifecycle.** Shipping a noun (for example "deadline")
  without its verbs (row display, notification, day-view presence) reads
  as half-baked and earns reviews saying so.
- **Gamification as ambient scorekeeping.** Points, decay and confetti are an
  engagement tax on tools whose identity is calm density, so adopt them only where
  the product's voice genuinely wants them.
