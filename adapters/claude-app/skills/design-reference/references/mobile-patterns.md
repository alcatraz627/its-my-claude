# Mobile UX pattern palette (todo and notes apps)

A menu of patterns mined from seven leading mobile todo and note apps (Notion,
Todoist, Google Tasks, Google Keep, Obsidian, TickTick, Capacities) in mid
2026. Each pattern names the visible mechanic and the workflow it exists to
enable.

Use it two ways: as a build menu when designing a capture, list or task
surface, and as a review checklist when auditing one. Judge every pick against
the product's own identity first. In the worked study, several famous patterns
were correctly refused because they fought the host product's identity.

## Workflow blocks (the layer above components)

1. **Two-speed data entry.** Split "capture fast, structure later" from "edit
   precisely" into visibly different modes. Natural-language parsing (dates,
   tags, priority) lives only in the fast lane, rendered as visible tokens the
   user can tap to un-parse. The full editor uses pickers. Never put a required
   decision in the fast lane. Default everything and file later.
2. **Triage as a gesture economy.** The two or three most frequent decisions
   (done, tomorrow, later) get single-motion gestures, such as a swipe with
   preset shortcuts in the revealed action. The long tail keeps pickers. Pair
   every gesture with an undo, never a confirm dialog. A configurable gesture
   map is the power-user extension, and two well-chosen fixed verbs serve most
   products better.
3. **Overdue as a designed ritual.** A named, guided one-at-a-time walk
   (reschedule, do or drop) over the overdue pile beats an ashamed scroll. Bulk
   "spread these across coming days" is the batch variant. Overdue recurring
   items never stack: choose once between advance-one and catch-up-all.
4. **Capture from anywhere.** Saving a thought must not require launching the
   app. Offer share targets, home and lock widgets, quick-settings tiles,
   assistant verbs, even messaging-channel inboxes. The app is where organizing
   happens.
5. **The trust spine.** Sync and offline state is either invisible until broken
   (feels magic, fails undiagnosable) or always visible and *named*. Choose
   deliberately. Offline capture must be indistinguishable from online.
   Conflicts get a preview and a copy-out escape hatch, and nothing is
   destroyed silently.
6. **Bursty capture.** Quick-add stays open after save (confirm flash, clear,
   keep focus), because capture comes in bursts, not single thoughts.
7. **Batch is a mode.** Long-press, multi-select, then a contextual command bar.
   Bulk operations get their own chrome, not a per-item loop.

## Display patterns

- **State rides the action affordance.** Color or status sits on the checkbox
  or complete control itself. A separate badge column is wrong.
- **Previews render state, not text.** Checklist glyphs (☐ ☑), struck and
  demoted done items, attachments and canvases summarized by size, so the list
  communicates without opening anything.
- **Done is a counted, collapsed receipt.** A demoted expandable group with a
  count, neither interleaved noise nor deletion.
- **One color, one alarm.** The fewer hues that speak, the louder the alarm hue
  reads. Color scarcity is hierarchy.
- **The clock outranks importance in day views.** Timed items sort above
  high-priority undated ones inside "today" surfaces.
- **Views are cheap, chrome is expensive.** Saved queries become first-class nav
  chips, with show-if-not-empty rules keeping the bar honest.
- **Kind shows as a mark.** A glyph plus a word (not a color, not a schema)
  distinguishes item kinds in a uniform list.

## Interaction patterns

- **Completion is a micro-moment.** A check-draw animation plus haptic, and an
  optional sound. The most repeated interaction deserves the most feeling, and
  everything else stays still.
- **Slash and trigger-character insertion survives touch.** `/` block menus and
  link syntax belong on mobile too, surfaced through the toolbar.
- **The keyboard-adjacent toolbar is mobile's command palette**, and its slots
  deserve user remapping in power tools.
- **Caret-line raw reveal.** Rendered-always editing where only the cursor's
  line shows raw syntax gives one continuous mode with no edit and preview
  toggle (Obsidian Live Preview's defining feel).
- **Second tap deepens.** Re-tapping the active tab performs that tab's "go
  deeper" verb (today, top, inbox).
- **Home surface is a setting.** Which screen a cold launch opens is the user's
  business, decoupled from tab order, and synced across devices.
- **Edge-swipe overlays beat docked panels** on phones: summon, act, vanish.
- **Recurrence needs two anchors.** Schedule-anchored ("every Friday") and
  completion-anchored ("N days after I actually did it") serve different
  habits. Shipping only one mis-serves half.
- **"Won't do" is a real ending.** A cancelled terminal status distinct from
  done keeps completion honest.
- **Checklist and subtask are different things.** Lightweight steps inside an
  item and children with their own metadata are two primitives. Collapsing them
  loses one.
- **Plan date and deadline are different things.** "When I'll work on it" and
  "when it's due" are separate fields.

## Anti-patterns (observed failures, not hypotheticals)

- **Full-parity webview mobile.** Desktop parity bought with seconds of cold
  launch is the most complained-about trait of the biggest app studied.
- **Buried first-class structures.** An organizing primitive that needs manual
  favoriting to reach navigation decays into disuse.
- **Sort modes that silently drop structure.** Hierarchy visible under only one
  sort order breaks the mental model exactly when triaging.
- **Backend swaps under a stable UI.** Moving a feature's system of record while
  the chip looks unchanged, and silently dropping capabilities, is the deepest
  trust breach observed.
- **A field without a lifecycle.** Shipping a noun (for example "deadline")
  without its verbs (row display, notification, day-view presence) reads as
  half-built and earns reviews saying so.
- **Gamification as ambient scorekeeping.** Points, decay and confetti are an
  engagement tax on tools whose identity is calm density. Adopt them only where
  the product's voice wants them.
