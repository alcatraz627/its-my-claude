---
brief: A pick-from palette of mobile todo/notes UX patterns — workflow blocks (two-speed capture, triage gesture economy, overdue rituals, trust signaling), display patterns, interaction patterns, and anti-patterns — mined from Notion/Todoist/Google Tasks/Keep/Obsidian/TickTick/Capacities dossiers (2026-07). Consult when designing or reviewing any notes/tasks/mobile-first UI.
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

A reusable menu of patterns mined from seven leading mobile todo/note apps
(Notion, Todoist, Google Tasks, Google Keep, Obsidian, TickTick, Capacities)
in July 2026. Each pattern names the visible mechanic and the workflow it
exists to enable. Evidence dossiers + a worked example of judging these
against one product's identity: `~/Code/Claude/data-forge/.claude/output/
20260713-app-ux-research/` (and `docs/ux-pattern-palette.md` there for the
verdict-annotated edition).

Use it two ways: as a build menu when designing a capture/list/task surface,
and as a review checklist when auditing one. Judge every pick against the
product's own identity contracts first — the worked example shows several
famous patterns correctly REFUSED because they fought the host identity.

## Workflow blocks (the layer above components)

1. **Two-speed data entry.** Split "capture fast, structure later" from
   "edit precisely" into visibly different modes. Natural-language parsing
   (dates, tags, priority) lives ONLY in the fast lane, rendered as visible
   tokens the user can tap to un-parse; the full editor uses pickers. Never
   put a required decision in the fast lane; default everything, file later.
2. **Triage as a gesture economy.** The two or three highest-frequency
   decisions (done, tomorrow, later) get single-motion gestures — swipe
   with preset shortcuts baked into the revealed action — while the long
   tail keeps pickers. Pair every gesture with an undo net, never a confirm
   dialog. Configurability of the gesture map is the power-user extension;
   two well-chosen fixed verbs serve most products better.
3. **Overdue as a designed ritual.** A named, guided one-at-a-time walk
   (reschedule / do / drop) over the overdue pile beats an ashamed scroll.
   Bulk "spread these across coming days" is the batch variant. Overdue
   recurring items never stack — advance-one or catch-up-all, chosen once.
4. **Capture from anywhere.** Thought-saving must not require app launch:
   share targets, home/lock widgets, quick-settings tiles, assistant verbs,
   even messaging-channel inboxes. The app is where organizing happens.
5. **The trust spine.** Sync/offline state either invisible-until-broken
   (feels magic, fails undiagnosable) or always-visible and *named* —
   choose deliberately. Offline capture must be indistinguishable from
   online. Conflicts deserve a preview and a copy-out escape hatch;
   never destroy silently.
6. **Bursty capture.** Quick-add stays open after save (confirm-flash,
   clear, keep focus): capture sessions are bursts, not single thoughts.
7. **Batch is a mode.** Long-press → multi-select → a contextual command
   bar. Bulk operations get their own chrome, not a per-item loop.

## Display patterns

- **State rides the action affordance** — color/status on the checkbox or
  complete-control itself, not a separate badge column.
- **Previews render state, not text** — checklist glyphs (☐/☑), done items
  struck and demoted, attachments/canvases summarized by size — the list
  communicates without opening anything.
- **Done is a counted, collapsed receipt** — a demoted expandable group
  with a count, not interleaved noise and not deletion.
- **One color, one alarm** — the fewer hues that speak, the louder the
  alarm hue reads. Color scarcity IS hierarchy.
- **The clock outranks importance in day views** — timed items sort above
  high-priority undated ones inside "today" surfaces.
- **Views are cheap, chrome is expensive** — saved queries as first-class
  nav chips, with show-if-not-empty visibility rules keeping the bar honest.
- **Kind shows as a mark** — a glyph + word (not a color, not a schema)
  distinguishes item kinds in a uniform list.

## Interaction patterns

- **Completion is a micro-moment** — check-draw animation + haptic
  (+ optional sound). The most-repeated interaction deserves the most
  feeling; everything else stays still.
- **Slash/trigger-char insertion survives touch** — `/` block menus and
  link syntax belong on mobile too, surfaced via the toolbar.
- **Keyboard-adjacent toolbar is mobile's command palette** — and its
  slots deserve user remapping in power tools.
- **Caret-line raw reveal** — rendered-always editing where only the
  cursor's line shows raw syntax: one continuous mode, no edit/preview
  toggle (Obsidian Live Preview's defining feel).
- **Second tap deepens** — re-tapping the active tab performs the tab's
  "go deeper" verb (today, top, inbox).
- **Home surface is a setting** — which screen cold-launch opens is user
  business, decoupled from tab order, synced across devices.
- **Edge-swipe overlays beat docked panels** on phones — summon, act,
  vanish.
- **Recurrence needs two anchors** — schedule-anchored ("every Friday")
  and completion-anchored ("N days after I actually did it") serve
  different real habits; shipping only one mis-serves half.
- **"Won't do" is a real ending** — a cancelled terminal status distinct
  from done keeps completion honest.
- **Checklist ≠ subtask** — lightweight steps-within vs children with
  their own metadata are two primitives; collapsing them loses one.
- **Plan-date ≠ deadline** — "when I'll work on it" and "when it's due"
  are separate fields (see anti-pattern: no noun without its verbs).

## Anti-patterns (observed failures, not hypotheticals)

- **Full-parity webview mobile** — desktop parity bought with cold-launch
  seconds is the most-complained-about trait of the biggest app studied.
- **Buried first-class structures** — an organization primitive that needs
  manual favoriting to reach navigation decays into disuse.
- **Sort modes that silently drop structure** — hierarchy visible only
  under one sort order breaks the mental model exactly when triaging.
- **Backend swaps under a stable UI** — migrating a feature's system of
  record while the chip looks unchanged (and silently dropping
  capabilities) is the deepest trust breach observed.
- **A field without a lifecycle** — shipping a noun (e.g. "deadline")
  without its verbs (row display, notification, day-view presence) reads
  as half-baked and earns reviews saying so.
- **Gamification as ambient scorekeeping** — points/decay/confetti are an
  engagement tax on tools whose identity is calm density; adopt only where
  the product's voice genuinely wants it.
