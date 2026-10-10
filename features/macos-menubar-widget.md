---
brief: How to build a macOS menu-bar app here. Copy the design kit and packaging from switchboard-mac, add headless checks, then the AppKit patterns (settings window, live-propagation, composited badge, hover popover).
triggers:
  - topic:macos-menubar
  - topic:appkit
  - topic:swift-app
  - tool:claude-instances
  - tool:switchboard
  - phrase:"menu bar widget"
  - phrase:"menu bar app"
  - phrase:"settings window"
related:
  - conventions/visual-design.md
  - features/desktop-automation.md
tier: 3
category: features
updated: 2026-09-29
stale_after_days: 180
---

# macOS menu-bar widget patterns (AppKit)

Distilled, reusable patterns for building an `.accessory`-policy macOS menu-bar
app (an `NSStatusItem` dropdown + optional panels/windows). Extracted from three
real apps in this account: **`~/Code/Claude/switchboard-mac/`** (the one to copy
from: packaged, headless-checkable, documented), **`~/.claude/widgets/claude-instances/native/`**
(the richest dropdown) and **`~/Code/Claude/sys-monitor/`**. It captures the
cross-project scaffolding and the non-obvious gotchas that cost real debugging time.

## 0. Starting a new app: copy these, in this order

1. **The design kit.** Copy `switchboard-mac/Sources/DesignKit.swift` and
   `Sources/Palette.swift` (AppKit/SwiftUI only, no other deps), and `PT` from
   `Sources/PolicyPanel.swift` if the app has a SwiftUI panel. Trim
   `PaletteToken` to what you use; keep the severity three. Copying is the
   ruled approach (owner, 2026-09-28): no shared package, drift between apps is
   acceptable. The rules the kit encodes, and why, are in
   `switchboard-mac/docs/design-kit.md`; read it before adding any colour or size.
2. **The packaging.** Copy `scripts/build.sh`: it globs `Sources/*.swift` (no
   hand-kept source list to drift), builds a real `.app` bundle with
   `LSUIElement`, ad-hoc signs it, installs to `~/Applications` and registers a
   LaunchAgent. See §6.
3. **The headless flags.** Add `--dump` and `--snapshot out.png [--light]` in
   `main.swift` before the UI grows (§7). Copy `scripts/snapshots.sh`.
4. **The tests.** Copy the shape of `tests/run-tests.sh` (bash + swiftc +
   python3, no framework) and one probe from `tests/fixtures/`.

## 1. A standalone Settings window (the scaffold)

An `.accessory` app has no Dock icon and no key window by default, so a Settings
window needs an explicit activation dance. Use a plain owner class (NOT an
`NSWindowController` subclass, and NOT `@MainActor` unless the whole codebase is —
menu actions already run on main) that hosts an existing SwiftUI view via
`NSHostingController`, so the dashboard tab and the window render one implementation.

```swift
final class SettingsWindowController {
    private var window: NSWindow?
    private let onWillOpen: () -> Void          // owner closes any open menu/popover
    init(onWillOpen: @escaping () -> Void) { self.onWillOpen = onWillOpen }
    func show() {
        onWillOpen()
        if window == nil {
            let host = NSHostingController(rootView: SettingsView())   // reuse the existing view
            let w = NSWindow(contentViewController: host)
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false      // keep + reuse; don't rebuild each open
            w.setContentSize(NSSize(width: 600, height: 680))
            window = w
        }
        // Open on the screen UNDER THE CURSOR, not NSScreen.main — main can be an
        // asleep/secondary display, and the window then opens invisibly there.
        if let w = window {
            let scr = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
            if let vf = scr?.visibleFrame {
                w.setFrameOrigin(NSPoint(x: vf.midX - w.frame.width/2, y: vf.midY - w.frame.height/2))
            } else { w.center() }
        }
        NSApp.activate(ignoringOtherApps: true)   // the accessory activation dance
        window?.makeKeyAndOrderFront(nil)
    }
}
```

The hosted SwiftUI settings view must be self-contained (reads UserDefaults /
its own stores, no dependency on the dashboard's live data object) so it can host
in both the window and a dashboard tab with zero refactor.

## 2. Live-propagation: one broadcast, one observer

The house pattern here (claude-instances) is deliberately coarse and cheap: every
control writes a `UserDefaults` key then posts ONE `Notification` (e.g.
`.menuBehaviorDidChange`); a SINGLE observer does the union of side effects
(invalidate caches, restart timers, re-render rows, redraw the badge). Adding a
control is then mechanical: define a key, expose it (`@AppStorage` + `.onChange {
post() }`), read it via a global accessor. Prefer this over per-setting Combine
sinks unless the app already uses them (sys-monitor does) — the broadcast avoids
wiring a new sink per control.

## 3. Menu-bar badge as a composited NSImage

A status item's button is **single-line**: `attributedTitle` collapses newlines,
so a multi-row / multi-color badge (icon + count + stacked rows + colored dots)
must be drawn into ONE `NSImage`:

```swift
let img = NSImage(size: NSSize(width: totalW, height: NSStatusBar.system.thickness),
                  flipped: false) { _ in /* icon.draw / attrStr.draw(at:) / NSBezierPath dots */ true }
img.isTemplate = false          // MANDATORY for per-element color — template flattens to fg
btn.image = img; btn.imagePosition = .imageOnly; btn.title = ""
```

`.variableLength` status items auto-size to the image width, so no manual length.
The menu-bar height budget is ~22pt; auto-fit row height to the row count.

## 4. Hover popover on the status item

Two things that DON'T work, verified: an `NSTrackingArea` added to
`statusItem.button` does **not** deliver `mouseEntered/Exited` to a non-view owner
(the delegate); and a global `.mouseMoved` monitor is flaky over the menu bar. The
reliable pattern is a lightweight **poll** (a ~0.2s `Timer`) testing the cursor
against the button's live screen frame:

```swift
let rect = win.convertToScreen(btn.convert(btn.bounds, to: nil))
let inside = rect.contains(NSEvent.mouseLocation)   // enter → show NSPopover, exit → hide after grace
```

Match the dropdown's material with an `NSVisualEffectView(material: .menu)` as the
popover content; guard on "menu not open" so the hover and the click-menu don't fight.

## 5. Test-rig gotchas (multi-display Macs)

- `NSScreen.main` may be an **asleep** external/built-in display; a window centered
  there is invisible. Center on the cursor's screen (see §1).
- `cliclick` cursor positioning is **badly skewed** across a dual-display setup
  (asked-for vs landed coords differ by 40–170px) — don't trust it for pixel-precise
  automated hover tests; drive UI via a programmatic one-shot trigger + `screencapture`
  instead, and `caffeinate -u` so the display doesn't sleep mid-capture.

## 6. Ship a bundle, not a bare binary

A bare `swiftc` binary works until the app needs a version, its own
preferences domain, or files beside it. Build a `.app` from day one:

- **Helpers and assets inside the bundle** (`Contents/Resources/lib`), found
  via `Bundle.main.resourcePath`, with an env override (`<APP>_LIB`) so tests
  run them from the source tree. Never hard-code `~/.claude/widgets/<app>/…`:
  it breaks the moment the repo moves or someone clones it.
- **State in `~/Library/Application Support/<App>/`**, with an env override
  for tests. When moving state from an old location, copy (never move) on first
  read, so a rollback still finds it.
- **Preferences follow the bundle id.** A bare binary's defaults domain is its
  process name; a bundle's is its id. When an app changes identity, copy the
  known keys once from `UserDefaults(suiteName: "<old-domain>")` behind a
  `migrated…` flag (see `PreferenceMigration` in switchboard's `AppSupport.swift`).
- **Single-instance dedupe must spare headless runs.** Killing every process
  with your name at launch also kills a `--dump` running beside the new
  instance (it did, exit 143). Skip pids whose args carry a `--flag`.
- **Optional integrations hide, never break.** Anything outside the repo
  (a `~/.claude` script, pm2, a CLI) goes through one `Integrations` check;
  a missing tool hides its row or tab.

## 7. Headless checks from the first commit

Every surface should be exercisable without a screen: `--dump` prints the rows
as text, `--snapshot` renders the real SwiftUI view offscreen via
`NSHostingView` + `cacheDisplay` in a chosen `NSAppearance`. Then read the PNG
in dark and light before calling a UI change done. A headless render reports
its own process's state (e.g. a power assertion it does not hold), so check
live-only state against the running app, not the snapshot.

## 8. View-based menu items never send their action

An `NSMenuItem` with a custom `view` gets no action and no highlight: the view
owns the mouse. Use `MenuRowView` from the design kit (handles `mouseUp`,
draws its own hover) and `ClosureMenuItem` for plain closure items.

## Source of truth

- `~/Code/Claude/switchboard-mac/` (§0, §6-8): `Sources/DesignKit.swift`,
  `Sources/Palette.swift`, `Sources/AppSupport.swift`, `scripts/build.sh`,
  `docs/design-kit.md`, `docs/architecture.md`.
- `~/.claude/widgets/claude-instances/native/SettingsWindowController.swift` (§1),
  `Bar.swift` (`updateButton` §3, `checkHover`/`showUsagePopover` §4, the
  `.menuBehaviorDidChange` observer §2), `Dashboard.swift` (the SwiftUI sections).
- `~/Code/Claude/sys-monitor/Sources/sys-monitor/` — the Combine-sink variant of §2.
- Full research notes: `~/.claude/widgets/claude-instances/.claude/output/20260704-widget/`.
