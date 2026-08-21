# Apple Skills — Agent Index

Quick-lookup index for agents. Read this file first to find the right skill for a task, then read that skill's `SKILL.md` for full instructions. Skills are organized by task type.

---

## How to Use This Index

1. Find your task type below (UI, macOS, code gen, etc.)
2. Pick the matching skill path
3. Read that skill's `SKILL.md` before doing any work
4. Cross-references are listed where skills overlap

---

## UI / UX / Design

### Visual Design & Materials

| Need | Skill path |
|------|-----------|
| Liquid Glass effects — SwiftUI `.glassEffect()`, morphing, containers | `skills/design/liquid-glass/SKILL.md` |
| Liquid Glass in UIKit — `UIGlassEffect`, `UIGlassContainerEffect` | `skills/design/liquid-glass/SKILL.md` |
| Liquid Glass in AppKit — `NSGlassEffectView` | `skills/design/liquid-glass/SKILL.md` |
| Liquid Glass in WidgetKit — rendering modes, accented content | `skills/design/liquid-glass/SKILL.md` |
| General design system overview (entry point) | `skills/design/SKILL.md` |

### Animation

| Need | Skill path |
|------|-----------|
| Spring, bouncy, snappy animations — correct API generation | `skills/design/animation-patterns/SKILL.md` |
| `PhaseAnimator` / `KeyframeAnimator` (iOS 17+) | `skills/design/animation-patterns/SKILL.md` |
| View transitions — insertion/removal, hero, zoom | `skills/design/animation-patterns/SKILL.md` |
| SF Symbol effects — bounce, pulse, wiggle, breathe | `skills/design/animation-patterns/SKILL.md` |
| `withAnimation` completions, transactions | `skills/design/animation-patterns/SKILL.md` |
| Matched geometry / `matchedTransitionSource` (iOS 18+) | `skills/design/animation-patterns/SKILL.md` |

> The animation skill contains sub-files: `core-animations.md`, `phase-keyframe-animators.md`, `transitions.md`, `symbol-effects.md`. Read the SKILL.md for the decision tree first.

### Navigation Patterns

| Need | Skill path |
|------|-----------|
| NavigationStack, NavigationLink, navigationDestination | `skills/ios/navigation-patterns/SKILL.md` |
| NavigationSplitView — two/three column layouts | `skills/ios/navigation-patterns/SKILL.md` |
| TabView — iOS 18 customizable tabs, sidebar mode | `skills/ios/navigation-patterns/SKILL.md` |
| Programmatic navigation — NavigationPath, pop-to-root | `skills/ios/navigation-patterns/SKILL.md` |
| Zoom navigation transitions (iOS 18+) | `skills/ios/navigation-patterns/SKILL.md` |

### Toolbars

| Need | Skill path |
|------|-----------|
| Customizable toolbars (user-configurable items) | `skills/swiftui/toolbars/SKILL.md` |
| Search field in toolbar, minimized search | `skills/swiftui/toolbars/SKILL.md` |
| Toolbar item transitions, glass background control | `skills/swiftui/toolbars/SKILL.md` |
| `DefaultToolbarItem` — repositioning system items | `skills/swiftui/toolbars/SKILL.md` |
| `.largeSubtitle` placement | `skills/swiftui/toolbars/SKILL.md` |

### Text & Typography

| Need | Skill path |
|------|-----------|
| Styled text display — `AttributedString`, `Text` modifiers | `skills/swiftui/text-editing/SKILL.md` |
| Rich text editing — `TextEditor` with `AttributedString` (iOS 18+) | `skills/swiftui/text-editing/SKILL.md` |
| Markdown rendering in `Text` views | `skills/swiftui/text-editing/SKILL.md` |
| Custom formatting constraints — `AttributedTextFormattingDefinition` | `skills/swiftui/text-editing/SKILL.md` |
| `AttributedString` in foundation contexts | `skills/foundation/attributed-string/SKILL.md` |

### HIG / Accessibility Review

| Need | Skill path |
|------|-----------|
| UI review against iOS HIG — spacing, colors, tap targets | `skills/ios/ui-review/SKILL.md` |
| Dynamic Type / font usage audit | `skills/ios/ui-review/SKILL.md` |
| VoiceOver, accessibility labels, traits audit | `skills/ios/ui-review/SKILL.md` |
| Assistive Access scene — cognitive accessibility (iOS 17+) | `skills/ios/assistive-access/SKILL.md` |
| Accessibility code generators (labels, hints, reduce motion) | `skills/generators/accessibility-generator/SKILL.md` |

---

## macOS-Specific

| Need | Skill path |
|------|-----------|
| macOS development overview — Swift 6+, SwiftUI, AppKit bridge | `skills/macos/SKILL.md` |
| macOS 26 Tahoe APIs — new features, Apple Intelligence, MLX | `skills/macos/SKILL.md` → `macos-tahoe-apis/` |
| SwiftData on macOS — schema, queries, performance | `skills/macos/SKILL.md` → `swiftdata-architecture/` |
| AppKit + SwiftUI bridge — `NSViewRepresentable` | `skills/macos/SKILL.md` → `appkit-swiftui-bridge/` |
| macOS sandboxing / entitlements | `skills/macos/SKILL.md` → `macos-capabilities/` |
| macOS HIG / UI review (Tahoe design system) | `skills/macos/SKILL.md` → `ui-review-tahoe/` |
| Architecture patterns (SOLID, design patterns, modular) | `skills/macos/SKILL.md` → `architecture-patterns/` |

> The macOS skill is a router — it points to sub-modules. Read `skills/macos/SKILL.md` first, then read the specific sub-module file.

---

## SwiftUI-Specific Components

| Need | Skill path |
|------|-----------|
| 3D charts — `Chart3D`, `SurfacePlot`, interactive pose | `skills/swiftui/charts-3d/SKILL.md` |
| AlarmKit — scheduling alarms, Dynamic Island, Live Activities | `skills/swiftui/alarmkit/SKILL.md` |
| Toolbars (customizable, search, transitions) | `skills/swiftui/toolbars/SKILL.md` |
| Rich text editing / styled text | `skills/swiftui/text-editing/SKILL.md` |
| WebKit integration in SwiftUI | `skills/swiftui/webkit/SKILL.md` |

---

## iPad-Specific Patterns

| Need | Skill path |
|------|-----------|
| Stage Manager, multi-window, UIScene lifecycle | `skills/ios/ipad-patterns/SKILL.md` → `multitasking.md` |
| Drag and drop — Transferable, NSItemProvider | `skills/ios/ipad-patterns/SKILL.md` → `drag-drop.md` |
| Keyboard shortcuts, pointer / trackpad interactions | `skills/ios/ipad-patterns/SKILL.md` → `input-methods.md` |
| Apple Pencil, PencilKit | `skills/ios/ipad-patterns/SKILL.md` → `input-methods.md` |
| Hover effects, size class adaptation | `skills/ios/ipad-patterns/SKILL.md` |

---

## Code Generators (Produce Working Swift)

All generators are under `skills/generators/`. The generators overview lives at `skills/generators/SKILL.md`.

### UI / UX Generators

| What to generate | Skill path |
|-----------------|-----------|
| Onboarding flow — paged or stepped, with persistence | `skills/generators/onboarding-generator/SKILL.md` |
| Paywall — StoreKit 2, modern SwiftUI, `SubscriptionOfferView` | `skills/generators/paywall-generator/SKILL.md` |
| Settings screen — iOS/macOS, modular sections, `@AppStorage` | `skills/generators/settings-screen/SKILL.md` |
| What's New screen — shown after app updates | `skills/generators/whats-new/SKILL.md` |
| Announcement banners — priority-based, remote config | `skills/generators/announcement-banner/SKILL.md` |
| Permission priming screens — higher grant rates | `skills/generators/permission-priming/SKILL.md` |
| Milestone celebrations — confetti, badges, haptics | `skills/generators/milestone-celebration/SKILL.md` |
| Quick win / first-action guided flows | `skills/generators/quick-win-session/SKILL.md` |
| TipKit tips — inline, popover, rules, testing | `skills/generators/tipkit-generator/SKILL.md` |
| Feedback form — screenshot capture, smart routing | `skills/generators/feedback-form/SKILL.md` |
| Share card — ImageRenderer-based social cards | `skills/generators/share-card/SKILL.md` |
| Social export — Instagram/TikTok/X format handling | `skills/generators/social-export/SKILL.md` |
| Watermark engine — subscription-gated, CoreGraphics | `skills/generators/watermark-engine/SKILL.md` |

### System / Platform Generators

| What to generate | Skill path |
|-----------------|-----------|
| WidgetKit widget — static, configurable, interactive, lock screen | `skills/generators/widget-generator/SKILL.md` |
| Live Activity — Dynamic Island, lock screen, push-to-update | `skills/generators/live-activity-generator/SKILL.md` |
| Push notifications — APNs, categories, rich notifications | `skills/generators/push-notifications/SKILL.md` |
| Deep linking — URL schemes, Universal Links, App Intents | `skills/generators/deep-linking/SKILL.md` |
| App Clip — invocation URL, SKOverlay upgrade, App Group | `skills/generators/app-clip/SKILL.md` |
| Spotlight indexing — `SpotlightIndexable`, batch manager | `skills/generators/spotlight-indexing/SKILL.md` |
| App extensions — Share, Action, Keyboard, Safari | `skills/generators/app-extensions/SKILL.md` |
| Background processing — `BGTaskScheduler`, background URLSession | `skills/generators/background-processing/SKILL.md` |
| State restoration — NavigationPath, tab, scroll, form drafts | `skills/generators/state-restoration/SKILL.md` |
| Force update — remote version check, hard/soft block | `skills/generators/force-update/SKILL.md` |
| Offline queue — actor-based, file-persisted, exponential backoff | `skills/generators/offline-queue/SKILL.md` |
| App icon generator — CoreGraphics, all sizes, asset catalog | `skills/generators/app-icon-generator/SKILL.md` |
| Screenshot automation — XCUITest, locale/device matrix | `skills/generators/screenshot-automation/SKILL.md` |

### Data / Business Logic Generators

| What to generate | Skill path |
|-----------------|-----------|
| Analytics — TelemetryDeck/Firebase, protocol-based | `skills/generators/analytics-setup/SKILL.md` |
| Logging — `os.log`/Logger, audit print() usage | `skills/generators/logging-setup/SKILL.md` |
| Networking layer — async/await, type-safe endpoints | `skills/generators/networking-layer/SKILL.md` |
| Auth flow — Sign in with Apple, biometrics, Keychain | `skills/generators/auth-flow/SKILL.md` |
| Persistence — SwiftData + CloudKit sync, repositories | `skills/generators/persistence-setup/SKILL.md` |
| Error monitoring — Sentry/Crashlytics, protocol-based | `skills/generators/error-monitoring/SKILL.md` |
| Feature flags — local + remote, debug toggle menu | `skills/generators/feature-flags/SKILL.md` |
| CloudKit sync — `CKSyncEngine`, zones, sharing | `skills/generators/cloudkit-sync/SKILL.md` |
| HTTP caching — Cache-Control, ETag, stale-while-revalidate | `skills/generators/http-cache/SKILL.md` |
| Pagination — offset/cursor, state machine, infinite scroll | `skills/generators/pagination/SKILL.md` |
| Image loading — NSCache + disk LRU, `CachedAsyncImage` | `skills/generators/image-loading/SKILL.md` |
| Data export — JSON, CSV, PDF, GDPR-compliant | `skills/generators/data-export/SKILL.md` |

### Engagement / Monetization Generators

| What to generate | Skill path |
|-----------------|-----------|
| Subscription lifecycle — grace period, win-back, upgrade paths | `skills/generators/subscription-lifecycle/SKILL.md` |
| Subscription offers — promotional codes, offer codes | `skills/generators/subscription-offers/SKILL.md` |
| Win-back offers | `skills/generators/win-back-offers/SKILL.md` |
| Streak tracker — SwiftData, heat map, freeze passes | `skills/generators/streak-tracker/SKILL.md` |
| Variable rewards — gamification, spin wheel, rarity tiers | `skills/generators/variable-rewards/SKILL.md` |
| Lapsed user re-engagement — inactivity detection, win-back screen | `skills/generators/lapsed-user/SKILL.md` |
| Usage insights — Swift Charts, Spotify Wrapped-style recap | `skills/generators/usage-insights/SKILL.md` |
| Referral system — unique codes, deep link redemption | `skills/generators/referral-system/SKILL.md` |
| Review prompt — smart timing, platform detection | `skills/generators/review-prompt/SKILL.md` |
| Account deletion — Apple-compliant, multi-step, grace period | `skills/generators/account-deletion/SKILL.md` |
| Consent flow — GDPR/CCPA/DPDP, ATT integration | `skills/generators/consent-flow/SKILL.md` |
| Debug menu — flag toggles, network logger, diagnostics | `skills/generators/debug-menu/SKILL.md` |

---

## Swift Language

| Need | Skill path |
|------|-----------|
| Swift overview — modern patterns, entry point | `skills/swift/SKILL.md` |
| Swift concurrency — async/await, actors, Sendable | `skills/swift/concurrency/SKILL.md` |
| Concurrency patterns — task groups, continuations | `skills/swift/concurrency-patterns/SKILL.md` |
| Memory management — ARC, leaks, reference cycles | `skills/swift/memory/SKILL.md` |
| SwiftData inheritance patterns | `skills/swiftdata/inheritance/SKILL.md` |

---

## Performance

| Need | Skill path |
|------|-----------|
| SwiftUI unnecessary re-renders, janky scrolling | `skills/performance/swiftui-debugging/SKILL.md` |
| View identity issues, `.id()` misuse | `skills/performance/swiftui-debugging/SKILL.md` |
| `Self._printChanges()`, Instruments SwiftUI template | `skills/performance/swiftui-debugging/SKILL.md` |
| General Instruments profiling — Time Profiler, Memory, Energy | `skills/performance/profiling/SKILL.md` |

---

## Testing

| Need | Skill path |
|------|-----------|
| Testing overview — TDD workflows, infrastructure | `skills/testing/SKILL.md` |
| TDD for new features | `skills/testing/tdd-feature/SKILL.md` |
| TDD for bug fixes | `skills/testing/tdd-bug-fix/SKILL.md` |
| TDD refactor guard — prevent regressions | `skills/testing/tdd-refactor-guard/SKILL.md` |
| Test data factories — mocks, fixtures | `skills/testing/test-data-factory/SKILL.md` |
| Test contracts — interface-level guarantees | `skills/testing/test-contract/SKILL.md` |
| Snapshot tests (visual regression) | `skills/testing/snapshot-test-setup/SKILL.md` |
| Integration test scaffold | `skills/testing/integration-test-scaffold/SKILL.md` |
| Characterization tests — lock in legacy behavior | `skills/testing/characterization-test-generator/SKILL.md` |
| Generate unit/UI test templates | `skills/generators/test-generator/SKILL.md` |

---

## Apple Intelligence / On-Device ML

| Need | Skill path |
|------|-----------|
| Foundation Models — on-device LLM, token budgeting | `skills/apple-intelligence/foundation-models/SKILL.md` |
| Visual Intelligence integration | `skills/apple-intelligence/visual-intelligence/SKILL.md` |
| App Intents — Siri, Shortcuts, Spotlight | `skills/apple-intelligence/app-intents/SKILL.md` |
| Core ML, Vision, NaturalLanguage | `skills/core-ml/SKILL.md` |
| Apple Intelligence overview | `skills/apple-intelligence/SKILL.md` |

---

## App Store & Growth

### App Store Optimization

| Need | Skill path |
|------|-----------|
| App Store overview (entry point) | `skills/app-store/SKILL.md` |
| App description copy — keyword-optimized | `skills/app-store/app-description-writer/SKILL.md` |
| Keyword research & ASO | `skills/app-store/keyword-optimizer/SKILL.md` |
| Apple Search Ads — campaigns, optimization | `skills/app-store/apple-search-ads/SKILL.md` |
| Screenshot planning — layout, devices, messaging | `skills/app-store/screenshot-planner/SKILL.md` |
| Review response writing | `skills/app-store/review-response-writer/SKILL.md` |
| Rejection handler — appeal, fix common rejections | `skills/app-store/rejection-handler/SKILL.md` |
| Marketing strategy for App Store | `skills/app-store/marketing-strategy/SKILL.md` |
| Custom product pages | `skills/generators/custom-product-pages/SKILL.md` |
| Product page optimization (A/B) | `skills/generators/product-page-optimization/SKILL.md` |
| In-app events | `skills/generators/in-app-events/SKILL.md` |
| App Store assets (screenshots, previews) | `skills/generators/app-store-assets/SKILL.md` |
| Pre-orders setup | `skills/generators/pre-orders/SKILL.md` |
| App featuring nomination | `skills/generators/featuring-nomination/SKILL.md` |
| Promoted IAP | `skills/generators/promoted-iap/SKILL.md` |

### Growth

| Need | Skill path |
|------|-----------|
| Growth overview | `skills/growth/SKILL.md` |
| Analytics interpretation — reading App Store Connect data | `skills/growth/analytics-interpretation/SKILL.md` |
| Community building | `skills/growth/community-building/SKILL.md` |
| Press & media outreach | `skills/growth/press-media/SKILL.md` |
| Indie business strategy | `skills/growth/indie-business/SKILL.md` |

---

## Monetization

| Need | Skill path |
|------|-----------|
| Monetization strategy overview | `skills/monetization/SKILL.md` |
| Paywall UI generation | `skills/generators/paywall-generator/SKILL.md` |
| Subscription lifecycle management | `skills/generators/subscription-lifecycle/SKILL.md` |
| Offer codes setup | `skills/generators/offer-codes-setup/SKILL.md` |

---

## Product Planning

| Need | Skill path |
|------|-----------|
| Product workflow overview | `skills/product/SKILL.md` |
| End-to-end product agent | `skills/product/product-agent/SKILL.md` |
| App idea generation | `skills/product/idea-generator/SKILL.md` |
| PRD generation | `skills/product/prd-generator/SKILL.md` |
| Architecture spec | `skills/product/architecture-spec/SKILL.md` |
| Implementation spec | `skills/product/implementation-spec/SKILL.md` |
| UX spec | `skills/product/ux-spec/SKILL.md` |
| Test spec | `skills/product/test-spec/SKILL.md` |
| Release spec | `skills/product/release-spec/SKILL.md` |
| Beta testing strategy | `skills/product/beta-testing/SKILL.md` |
| Localization strategy | `skills/product/localization-strategy/SKILL.md` |
| Competitive analysis | `skills/product/competitive-analysis/SKILL.md` |
| Market research | `skills/product/market-research/SKILL.md` |
| Implementation guide | `skills/product/implementation-guide/SKILL.md` |

---

## Legal & Security

| Need | Skill path |
|------|-----------|
| Privacy policy generation | `skills/legal/privacy-policy/SKILL.md` |
| Legal overview (EULA, terms) | `skills/legal/SKILL.md` |
| Privacy manifests — required reasons API declarations | `skills/security/privacy-manifests/SKILL.md` |
| Security overview | `skills/security/SKILL.md` |

---

## Other Platforms

| Need | Skill path |
|------|-----------|
| watchOS development | `skills/watchos/SKILL.md` |
| visionOS widgets | `skills/visionos/widgets/SKILL.md` |
| MapKit / GeoToolbox | `skills/mapkit/geotoolbox/SKILL.md` |

---

## Pre-Release

| Need | Skill path |
|------|-----------|
| Full pre-release checklist — audit before shipping | `skills/release-review/SKILL.md` |
| CI/CD setup — GitHub Actions, Xcode Cloud, fastlane | `skills/generators/ci-cd-setup/SKILL.md` |
| Localization setup — String Catalogs, L10n enum | `skills/generators/localization-setup/SKILL.md` |

---

## Skill Creation

| Need | Skill path |
|------|-----------|
| Creating a new skill | `skills/shared/skill-creator/SKILL.md` |
| Shared skill template | `skills/shared/SKILL.md` |

---

## Priority Guide for UI / Design Agents

If you are an agent focused on **UI, UX, or macOS design**, read these skills first — they cover the most commonly needed patterns and have the highest density of design-relevant content:

```
1. skills/design/liquid-glass/SKILL.md         — Liquid Glass (iOS/macOS 26)
2. skills/design/animation-patterns/SKILL.md   — All animation patterns
3. skills/ios/navigation-patterns/SKILL.md     — Modern navigation architecture
4. skills/swiftui/toolbars/SKILL.md            — Toolbar patterns
5. skills/ios/ui-review/SKILL.md               — HIG compliance review process
6. skills/macos/SKILL.md                       — macOS-specific guidance
7. skills/ios/ipad-patterns/SKILL.md           — iPad-specific patterns
8. skills/swiftui/text-editing/SKILL.md        — Text / rich text
9. skills/performance/swiftui-debugging/SKILL.md — Performance diagnosis
10. skills/ios/assistive-access/SKILL.md        — Cognitive accessibility
```
