---
name: apple
description: Router for Apple platform development skills — iOS, macOS, watchOS, visionOS, SwiftUI, Swift, App Store, design (Liquid Glass), generators, testing, and more. Dispatches to 23 specialized sub-skill categories.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebFetch
user-invokable: true
argument-hint: "<category> [sub-skill] [options] | list | search <query>"
---

## Brief

Gateway to 140+ Apple platform development skills covering the full lifecycle: design,
code generation, testing, App Store optimization, product planning, and platform-specific
APIs (iOS, macOS, watchOS, visionOS). Dispatches to the right sub-skill based on the
user's request.

## Step 0: Load Shared Guidelines and Runtime Context

Read `~/.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `~/.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

---

## Usage

```
/apple list                          # Show all categories
/apple search <query>                # Find the right skill for a task
/apple <category>                    # Load the category's SKILL.md
/apple <category> <sub-skill>        # Load a specific sub-skill
```

### Examples

```
/apple design liquid-glass           # Liquid Glass implementation guide
/apple macos                         # macOS development (Tahoe, SwiftData, AppKit)
/apple gen auth-flow                 # Generate authentication flow code
/apple ios ui-review                 # Review iOS UI against HIG
/apple app-store keyword-optimizer   # ASO keyword optimization
/apple swift                         # Swift 6+ best practices
/apple search "navigation patterns"  # Find skills matching a query
```

---

## Categories

| Category | Skills | Description |
| -------- | ------ | ----------- |
| `design` | 3 | Liquid Glass, animation patterns, visual design systems |
| `macos` | 8 | Tahoe APIs, SwiftData, AppKit bridge, concurrency |
| `ios` | 7 | Code review, UI review, navigation, iPad, migration |
| `swift` | 5 | Language patterns, concurrency, error handling, protocols |
| `swiftui` | 5 | Toolbars, text editing, containers, modifiers |
| `swiftdata` | 2 | Persistence, inheritance, migration |
| `generators` | 52 | Production-ready code for auth, networking, UI, data, etc. |
| `testing` | 8 | TDD workflows, test infrastructure, snapshot tests |
| `app-store` | 7 | ASO, descriptions, keywords, reviews, search ads, marketing |
| `product` | 13 | Idea discovery, architecture, market research, release specs |
| `apple-intelligence` | 4 | Foundation models, App Intents, visual intelligence |
| `core-ml` | 3 | On-device ML, model optimization, inference |
| `security` | 2 | Privacy manifests, data protection, Keychain |
| `legal` | 1 | Privacy, EULA, compliance |
| `performance` | 3 | Instruments, memory, launch time, energy |
| `growth` | 2 | User acquisition, retention, analytics |
| `monetization` | 2 | StoreKit 2, subscriptions, in-app purchases |
| `release-review` | 1 | Pre-submission checklist, App Review guidelines |
| `mapkit` | 1 | MapKit, annotations, overlays, Look Around |
| `visionos` | 1 | visionOS development, spatial computing |
| `watchos` | 1 | watchOS development, complications, widgets |
| `foundation` | 1 | AttributedString, Foundation APIs |

---

## Subcommand: `list`

Print the categories table above. For each category, also print its sub-skills:

```
Read ~/.claude/skills/apple/SKILLS_INDEX.md
```

Print the full index in a readable format.

---

## Subcommand: `search <query>`

1. Read `~/.claude/skills/apple/SKILLS_INDEX.md`
2. Match the query against skill names, descriptions, and "Need" entries
3. Return the top 3-5 matching skills with their paths
4. Print: category, skill name, path, and a one-line description

---

## Subcommand: `<category>` (no sub-skill)

1. Read `~/.claude/skills/apple/<category>/SKILL.md`
2. Follow that SKILL.md's instructions — it acts as a router within its domain
3. If the category has sub-skills listed, present them to the user

---

## Subcommand: `<category> <sub-skill>`

1. Read `~/.claude/skills/apple/<category>/<sub-skill>/SKILL.md`
2. If that path doesn't exist, try:
   - `~/.claude/skills/apple/<category>/<sub-skill>.md` (flat file)
   - Grep for the sub-skill name in the category's SKILL.md
3. Follow the loaded skill's instructions

---

## Generator Shortcuts

The `generators` category has 52 code generators. Common shortcuts:

| Shortcut | Full path |
| -------- | --------- |
| `gen auth` | `generators/auth-flow-generator` |
| `gen network` | `generators/networking-layer-generator` |
| `gen coredata-to-swiftdata` | `generators/coredata-to-swiftdata` |
| `gen accessibility` | `generators/accessibility-generator` |
| `gen widget` | `generators/widget-generator` |
| `gen settings` | `generators/settings-screen-generator` |

When the user says `/apple gen <name>`, search the generators directory for a matching sub-skill.

---

## Provenance

These skills are copied from `~/Code/Claude/claude-code-apple-skills/skills/`.
The source repo is the upstream reference. This copy at `~/.claude/skills/apple/`
is the working version used by Claude Code.

To update: re-copy from source after pulling upstream changes.

---

## Notes

- All sub-skills were originally designed for standalone use — each has its own SKILL.md with full instructions
- The `shared/` subdirectory contains Apple-specific shared utilities (not to be confused with `~/.claude/skills/shared/` which is the global std::claude shared library)
- Sub-skills may reference `skills/` paths relative to the Apple skills root — mentally prefix with `~/.claude/skills/apple/`
- Some generators produce complete, production-ready code files — review before adding to a project
- The SKILLS_INDEX.md file is a comprehensive lookup table organized by task type — read it for the fastest path to the right skill
