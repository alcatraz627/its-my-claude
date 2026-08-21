# Parked skills — tldr, tags, activation

Not loaded; see README.md for the two-way check. Regenerate: `bash ~/.claude/scripts/parked/parked.sh index`.

| skill | tldr | tags | copy in when |
|---|---|---|---|
| `add-mcp` | Add pre-configured MCP servers from the central catalog (~/.claude/mcp-catalog.json) into the current project's .mcp.json. Avoids re-configu | mcp,setup | a project needs an MCP server from the catalog wired into .mcp.json |
| `apple` | Router for Apple platform development skills — iOS, macOS, watchOS, visionOS, SwiftUI, Swift, App Store, design (Liquid Glass), generators,  | macos,ios,swift,swiftui,xcode | project has *.xcodeproj, Package.swift, or Info.plist; or the ask names iOS/macOS/SwiftUI |
| `clean-html` | Converts HTML files to clean, readable markdown by extracting and downloading embedded media, stripping tags while preserving document hiera | html,scrape,markdown | owner hands an HTML page to turn into readable markdown with media |
| `daily-todo` | Scans all project runtime-notes for recent entries, checks todo files for unchecked items, reads MEMORY.md indexes for activity hints — gene | todo,daily | owner asks for a daily todo file again (fell out of use 2026-Q2) |
| `dep-audit` | Runs npm audit and npm outdated, cross-references key dependencies against known breaking versions, and produces a prioritized upgrade list  | npm,security,dependencies | owner asks about outdated or vulnerable deps in a node project |
| `forgotten-todos` | Browse the cross-session backlog of unfinished todos surfaced from /core-dump checkpoints. Reads ~/.claude/subconscious/dreams/pending-todos | todo,backlog,checkpoints | owner asks "what did I forget" / cross-session backlog browse |
| `invalidate-audit` | Scans all useM and useMutation calls in src/ and reports any missing QueryKeys invalidation in their onSuccess callback — catching stale-dat | nextjs,cache,versable | same shape; cache-invalidation sweep |
| `route-audit` | Scans all Next.js App Router route files for missing auth guards, missing input validation on mutation handlers, and non-standard response s | nextjs,versable | same as type-audit; route/handler sweep |
| `scaffold` | Scaffolds new projects with opinionated defaults — wizard-based stack selection, file generation, and a post-scaffold pipeline that calls /g | new-project,bootstrap | a brand-new repo is being started from nothing |
| `sync-api-types` | Reads FastAPI Pydantic models from ../backend/ and diffs their fields against the TypeScript types used in src/ to consume those endpoints — | versable,api,codegen | the versable API repo pair; types drifted between BE and FE |
| `type-audit` | Scans the TypeScript codebase for unsafe type patterns (explicit `any`, implicit `any`, non-null assertions, unsafe casts), reports them wit | nextjs,typescript,versable | Next.js App Router project with the versable shape; owner asks for a type audit |
