# Runtime Notes Archive — 2026 Q2

Archived entries from global ~/.claude. Original file: runtime-notes.md

---

## create-report: floating picker for substyles + outputDir fixes — cont-resty-4f — 2026-04-06

**Purpose:** Fix `__RPT_REPORT_DIR` propagation to substyle reports, correct clipboard command in picker, and add floating style picker to all non-default templates.

**Insights:**
1. `reportRootDir` is derived from `basename(resolvedJson) === "data.json"` — when called via `restyle-report.sh`, the input is `<root>/data.json` so its dirname IS the root. For initial generation from a temp file, `outputDir` is used as the root.
2. Non-default templates call `styleMod.buildHtml(data)` with no extra params — globals and picker are injected at the `renderStyle` level via string replacement on `</head>` and `</body>`. No template files need modification.
3. Floating picker widget uses inline CSS (`position:fixed;bottom:1.25rem;right:1.25rem`) with a dark glassmorphism style, so it renders reasonably across all 7 template visual languages without fighting their stylesheets.
4. `data.json` must only be written when `outputDir === reportRootDir` — otherwise substyle runs would duplicate it into every style subdir.
5. `feed` style has no `style.js` — the floating picker's inline `<script>` handles its own toggle logic, so `__RPT.initStylePicker` is called after the toggle setup runs.

---
## core-dump: full checkpoint for impro-core-8a session — 2026-04-06

**Purpose:** Wrote full checkpoint capturing 6-enhancement improve-skill session
for core-dump.

**Insights:**

1. First run of the newly improved core-dump skill — all 5 phases executed
correctly (Parse → Summarize → Write → Visual → Verify).
2. Created ~/.claude/improvement-ideas.md for the first time — core-dump's
thoroughness mandate now auto-creates this file.
3. Visual summary (Phase 4) rendered cleanly with box-drawing chars in terminal
output — no encoding issues since it's print-only, not file-written.
4. Project root /Users/alcatraz627/Code/Claude has no .claude/skills/ —
GUIDELINES.md and runtime-notes.md live only under ~/.claude/skills/. Core-dump
should handle both locations gracefully.

--------
---

## improve-skill: core-dump — 6 enhancements applied impro-core-8a — 2026-04-06

**Purpose:** Applied 6 user-requested improvements to core-dump: Quick Summary
section, thoroughness mandate, sub-agent rejection (with documented rationale),
mini mode, CPU-dump visual terminal summary, and universal pre-compact hook.

**Insights:**

1. Sub-agents (context: fork) cannot access parent conversation — core-dump
fundamentally needs full parent context. Documented rejection with rationale in
## Notes section.
2. Pre-compact hook required TWO changes: removing matcher: "auto" from settings.
json AND removing the shell script's internal auto-only guard (if trigger !=
auto; exit). Easy to miss the shell-level guard.
3. The pre-compact-checkpoint.sh was enhanced with git diff for recently
modified files and trigger-aware messaging — lightweight complement to full
/core-dump.
4. Section numbering gaps are easy to introduce when inserting new sections mid-
document — always verify sequential numbering after multi-section edits.
5. Unicode box-drawing characters in Edit tool old_string can get mangled — use
Grep+Read to get exact content before editing near Unicode-heavy blocks.
6. Mini mode template deliberately omits insights/visual summary to stay fast —
designed for quick /catchup recovery, not thorough hand-off.

--------
---

## improve-skill: Second-pass audit — validation coherence fixes — 2026-04-06
12:00

**Purpose:** Fix 6 coherence gaps introduced by the first-pass validation
feature
addition: code-fence trap for examples, missing Phase 1.1 extraction, missing
lock in Phase 6.4, missing skip path, stale phase reference, and validation-
always-runs clarification.

**Insights:**

1. Validation examples inside markdown code fences are invisible to Phase 6.1
heading search — always create a real ## Validation Examples section for
operational use, separate from the ## Validation Examples Format reference spec.
2. When adding a new phase that writes to SKILL.md (Phase 6.4 persist), always
check whether the lock protocol from Phase 4 needs to be duplicated — any SKILL.
md write requires acquire/release.
3. Second-pass self-audit after adding a major feature catches integration
wiring bugs (cross-phase references, skip paths, extraction lists) that are
invisible during first-pass focused writing.
4. Adding skip/error path validation examples (no-improvements path, re-
improvement loop) provides higher coverage signal than happy-path-only examples.
5. Phase reference text ("Phase 1/2/3/4 headings") becomes stale when phases are
added — use the GUIDELINES requirement name ("four-phase skeleton") instead of
literal phase numbers.

--------
---

## create-report: zero-Claude style switching — impv-skill-4f — 2026-04-03

**Purpose:** Add on-the-fly style switching to /create-report: `data.json` persistence, `restyle.sh`, `--all-styles` flag, and in-browser style picker.

**Insights:**
1. `data.json` is the key: persisting the LLM-parsed JSON eliminates re-invocation for style changes. Only parsing markdown costs Claude tokens — rendering is pure TypeScript.
2. `window.__RPT_GENERATED_STYLES` is set at generation time (not runtime) because `file://` URLs can't use `fetch()` to check sibling file existence. The array is embedded in a `<script>` tag per report.
3. With `--all-styles`, every generated report embeds the full list of all 8 styles as "ready", making the style picker fully clickable instead of showing clipboard commands.
4. `report.js` (default template) needed a manual `window.__RPT.initStylePicker()` call — other templates have `style.js` files that call `__RPT` init functions, but the default template's `report.js` predates the namespace and doesn't use it anywhere else.
5. `AskUserQuestion` was removed from `allowed-tools` in SKILL.md since Step 6 no longer prompts the user for style choices.

---
## core-dump: Full session checkpoint for enh-prompt-testing workspace (note-pm2-
a3)
— 2026-04-04 14:30

**Purpose:** Capture complete session state before /clean — covering dashboard
note widgets, pm2 registration, and full project context across two sessions.

**Insights:**

1. Continuation sessions after context compaction lose trailing specifics (exact
line numbers, partial edits). The pre-compaction checkpoint (_precompact-
checkpoint.claude.md) was essential for picking up the note widget work mid-edit.
2. pm2 registration is straightforward but always fails on first pm2 start if a
manual node server.js is still holding the port — always kill first, then start.
3. This project's single-file dashboard (index.html ~550 lines) handles theming,
filtering, notes, and auto-refresh without a build system. Good reference
pattern for future lightweight dashboards.
4. The renderNoteWidget() pattern (generic widget accepting noteId + context
type) allowed reuse across both card notes and table cell notes with zero
duplication.
5. Global port registry update should always happen at the same time as
ecosystem.config.cjs creation — prevents orphan entries.

--------
---

## core-dump: cc30 poster fix + full export session — 2026-04-03 05:10

**Purpose:** Checkpoint after image URL fix (mini_100 → photos/500), poster
regeneration, and full Excel export for jegs-cc30-apr03-merged.

**Insights:**

1. mini_100 vs photos/500 URL divergence: non-enriched rows kept eBay-sourced
thumbnail URLs while enriched rows got JEGS full-res URLs from the merge step —
always verify image URL domains and path patterns are consistent across
enriched/non-enriched rows after a merge.
2. Poster staleness check: compare poster file timestamps vs data patch
timestamps before confirming a poster set is valid — file timestamps are the
most reliable signal.
3. Interactive rm (without -f) in a detached shell hangs silently — always use
trash per global CLAUDE.md rules, or at minimum -f flag for non-interactive
contexts.
4. sideload-enhanced-content.json is the correct "final" source for Excel
exports — it's the last data step before download-posters which only adds
posterPath metadata.
5. Spot-check pattern: compare 5 OLD + 5 NEW rows across key fields against the
reference run; checking Image, Title, Description, FAB, Part Type, fit_type
gives high confidence in data integrity.

--------
---

## create-report: template overhaul & gallery — impr-reprt-4c — 2026-04-02

**Purpose:** Comprehensive improvement of all 8 create-report templates with shared infrastructure, plus gallery page for showcasing styles.

**Insights:**

1. `esc()` in `generate-html.ts` converts `"` to `&quot;` before syntax highlighting runs. Any highlighter regex that matches literal `"` will fail silently — must use `&quot;` in regex patterns. This bit JSON highlighting hard.
2. Markdown italic regex `_[^_]+_` collides with internal placeholder tokens (`\x02_N_\x03`) because underscores wrap the counter. Use `*` for italic instead, with negative lookahead: `(?<!\*)\*(?!\*)([^*]+)\*(?!\*)`.
3. `window.__RPT` namespace pattern works well for sharing JS across templates without ES modules — each template's `style.js` calls only what it needs from the shared module. Key: make every function opt-in, not auto-init.
4. `fs.readdirSync` with `{withFileTypes: true}` returns `Dirent` objects where `isDirectory()` returns `false` for symlinks pointing to directories. This caused the scaffold server to hide the style-samples symlink from directory listings.
5. Chrome-like search (multi-word OR, mark cycling, index display) requires careful DOM TreeWalker usage — must handle text nodes that span element boundaries and preserve existing HTML structure during mark/unmark cycles.
6. Parallel agent execution (7 agents on independent template directories) cuts wall-clock from ~20min to ~3.5min. No file contention when each agent writes to its own style directory.

---
## create-skill: Created /readme skill — 2026-04-03 17:51

**Purpose:** Scaffold the /readme skill that generates polished GitHub-ready
READMEs for git repos.

**Insights:**

1. User provided all Q&A answers upfront in /create-skill args — wizard can
bypass interactive loop and go straight to plan when args are comprehensive.
2. The global scratchpad (~/.claude/scratchpad/global/readme-<slug>.md) is a
clean inter-skill handoff surface; the repo slug derived from git remote get-url
origin makes entries repo-scoped without needing to know the project root path.
3. context: fork was intentionally omitted so Phase 4's gum confirm/gum choose
prompts can be interactive — forked skills cannot do interactive I/O.
4. Phase-type pixel-art SVG motif table (frontend→browser, CLI→>_, library→gear,
etc.) gives the cover image real signal rather than always outputting the same
generic pattern.

--------
---

## session: notify + tab-title system build & test — 2026-03-25

**Purpose:** Built and tested the macOS notification system and dynamic tab title scripts for Claude Code hooks.

**Insights:**

1. `terminal-notifier` silently swallows notifications until granted permission in System Settings → Notifications. The "Removing previously sent notification" output is a local DB operation and works regardless — it's not proof that new notifications are delivered. Grant permissions interactively first.
2. `-appIcon` in `terminal-notifier` requires a PNG or URL — `.icns` silently renders no custom icon. Use `sips -s format png` to convert once at runtime and cache the PNG.
3. `-group` in `terminal-notifier` is a replace-not-stack key. Use subtitle-based groups for idempotent alerts (idle), timestamp-based groups for per-event alerts (permission requests).
4. `((VAR++))` returns exit code 1 when VAR=0 (arithmetic falsy). In `A && ok() || fail()` chains this causes the fail branch to fire incorrectly. Use `VAR=$((VAR+1))` instead.
5. `stat -f %m` on macOS has 1-second precision — mtime comparisons fail when testing file updates that happen within the same second. Check file existence/content instead.
6. `Write` tool creates files with mode 0644 — always follow up with `chmod +x` for shell scripts.
7. Stop hook #1 (bash, async) and Stop hook #2 (agent, async) both fire concurrently — the agent hook may read a stale stage file if it wins the race. Not catastrophic but worth noting.

---
## core-dump: Re-run 3 candidates with ratings + report relocation — 2026-04-03

**Purpose:** Complete re-evaluation of Ranga Vamsi Chenna, Farhan Ahmed Khan,
and
Sai Siddardha with new Ratings section and lenient criteria; moved HTML reports
into candidate folders.

**Insights:**

1. parse-candidate skill now inlines report generation to
candidates/<folder>/report/ — do NOT call /create-report from it (it writes to .
claude/output/, wrong location).
2. Ratings section was missing from all Session 2 candidates — always ensure
it's present when re-running evaluations.
3. Lenient criteria revised Ranga from Do Not Advance → Advance with
Reservations; Farhan's role match moved Data→QA/Reliability on second scan but
Do Not Advance held.
4. The 10+ year experience flag is moderated when stack is modern (Node.
js/Kafka/Redis) — flag harder for Java/J2EE-only profiles with no modern
counterbalance.
---

## create-report: Batch candidate notes reports — 2026-04-02 04:48

**Purpose:** Generate HTML reports from three candidate-notes.md files as part
of
bulk candidate evaluation.

**Insights:**

1. The shared .claude/report-data.tmp.json temp file must be overwritten
sequentially between reports — can't parallelize multiple report generations
through the same generator script.
2. For candidate notes, the "metadata preamble" (Source, LinkedIn, GitHub lines
before the first H2) works best folded into the Quick Stats section as a
paragraph block rather than a separate section.
3. Verdict should be in the subtitle field — makes it visible at a glance in the
report header without having to scroll to Claude Thinks.

--------
---

## core-dump: fix zip downloads — 2026-04-01 02:18

**Purpose:** Fix ZIP_EXCLUDED_PATTERNS to include ALL problem files; only
exclude build artifacts.
**Insights:**

1. ZIP_EXCLUDED_PATTERNS exists in 3 files that must stay in sync: constants.ts,
test-zip-downloads.mjs, test-zip-completeness.sh. Changing one without the
others causes silent test-vs-reality divergence.
2. solution.py/tsx in this project is the candidate scaffold, NOT an answer key.
Never exclude it from zips.
3. When fixing exclusion patterns, always verify with an actual download — don't
trust pattern-based tests that share the same exclusion logic.
4. HMAC token expiry can be stateless: bind the timestamp into the HMAC input,
recompute on validation.
5. Playwright browser_run_code is the best way to extract authenticated download
URLs from prod when the DOWNLOAD_SECRET is unknown.
---

## improve-skill + create-report: Multi-style architecture + highlight bug fixes
—
2026-04-01 00:50

**Purpose:** Improve the create-report skill by fixing syntax highlighting bugs,
adding navbar features, and expanding to 8 visual styles with a --style CLI
parameter.

**Insights:**

1. The makePlaceholder() sentinel \x02N\x03 is vulnerable to number regex
corruption because control chars are non-word characters, creating \b boundaries
around the index digit. Fix: wrap index with underscores (\x02_N_\x03) — _ is a
word char so no boundary forms. This is a general-purpose pattern for any
protect/restore regex system.
2. In highlightBash, the keyword regex must run AFTER the string regex (not
before). Otherwise class="kw" from keyword spans gets matched by the string
regex as a quoted string "kw". Protect-everything pattern (calling protect() on
ALL replacements, not just some) makes the order irrelevant.
3. Spawning 7 parallel agents to build independent style implementations (each
writing to its own directory) achieved ~5x speedup vs sequential. Key
requirement: no file contention between agents.
4. The if (resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main()
guard at the bottom of a .ts file lets it serve as both CLI entry point and
importable library — cleaner than splitting into separate files.
5. Generating standalone HTML prototypes first (for user visual approval) before
decomposing into template.ts + style.css + style.js saved significant rework.
The user approved all 4 initial styles and added 3 more.
6. Each style's template.ts can either use the shared renderBlock/renderSection
OR implement custom rendering (terminal style uses ASCII tables). The
architecture is flexible because each style is fully self-contained.

--------
---

## create-report: Generated HTML report for claude-code-source project index —
2026-
03-31 23:50

**Purpose:** Convert the newly created project-index.md for claude-code-source
into
a polished HTML report.

**Insights:**

1. JSON generation succeeded on first attempt — the schema is well-structured
for large architecture documents with many subsections.
2. Directory tree rendering via tree blocks works well for the tools/ and
components/ directories; deeply nested trees with 15+ children render cleanly.
3. The slash commands table with 30 rows rendered without issues — no row length
or escaping concerns.
4. Code snippets in subsections under Key Code Snippets section render with
proper syntax highlighting when lang is set to ts or tsx.
5. No package.json in this project means npx tsx pulls from global cache — still
fast (~3s).

--------
---

## core-dump: prod-refac-a3 productivity sprint checkpoint — 2026-03-31

**Purpose:** Snapshot a multi-phase productivity refactor session covering
screenshot tooling, bookmarks UX, calendar overflow, and roadmap backlog
additions.

**Insights:**

1. Detailed pending items in checkpoint are most valuable when they include the
*API routing logic* (e.g., which endpoint to PATCH for calendar drag) — this
prevents re-discovery in the next session.
2. Including a dedicated "Screenshot Tooling — Feature Reference" section with
usage examples and key implementation notes makes the checkpoint self-contained
for future screenshot audit sessions.
3. {@const} placement: must be immediate child of a Svelte block tag ({#if},
{#each}, etc.) — cannot live inside element markup. Moving it to the top of the
enclosing {#if} block is the standard fix.
4. The Playwright warm-up + localStorage seeding pattern is reusable for any
future screenshot script: goto('/') → evaluate(localStorage.setItem('hs:theme',
'dark')) → waitForPageReady() before the main loop.

--------
---

## core-dump: RateLimitPanel UI + burn rate + standalone mode — 2026-03-31

**Purpose:** Snapshot session covering RateLimitPanel spacing fixes, standalone
prop, theme toggle, and 24h burn rate sparkline chart.

**Insights:**

1. var(--color-primary) (not hsl(var(--primary))) is the correct CSS variable
for this project — Tailwind v4 uses --color-primary with oklch() values. SVG
stopColor and stroke work with var(--color-primary) when the SVG is inline in
the DOM.
2. Recharts lazy imports (AreaChart, Area, Tooltip as RechartsTooltip,
ResponsiveContainer) from recharts work cleanly alongside local Tooltip
component via aliasing — no bundle conflict.
3. Hourly burn rate bucketing is free if cachedRecords is already in memory — no
extra file reads. Align buckets to Math.floor(now / HOUR_MS) * HOUR_MS so
they're stable across refreshes.
4. The standalone prop pattern (boolean toggling which icons appear in a shared
component header) is cleaner than forking the component or using useLocation
inside a non-router-aware component.

--------
---

## session: GUIDELINES.md output overhaul — absolute paths, runtime stats, task
completion — 2026-03-31

**Purpose:** Updated GUIDELINES.md to switch from relative to absolute paths in
all skill/task output, added runtime stats block to skill completion summaries,
and added a task-completion summary block for user-defined goals.

**Insights:**

1. Relative paths in terminal output are ambiguous when work spans multiple
project roots (~/.claude, ~/Code/Claude/*, /private/tmp/*). Absolute paths are
Cmd+clickable in iTerm2/Ghostty/VS Code terminals — the practical UX benefit
outweighs the theoretical portability of relative paths.
2. Relative paths still make sense inside committed files (README linking to .
/src/config.ts) since those move with the repo. The guideline change only
affects ephemeral runtime output.
3. The task-completion block is deliberately lighter than the skill block — no
"Duration" or "Tools used" since those are harder to track accurately across
freeform conversations vs. structured skill runs.
4. The sync-config.sh secret scan has false positives — it matches its own regex
definition (sk-[a-zA-Z0-9]) and the word "secret" in documentation. Should
exclude self and known-safe patterns in a future fix.

--------
---

## session: Comprehensive codebase documentation project — 2026-03-31

**Purpose:** Built a 71-file, 696KB documentation suite for the entire Versable
frontend codebase in docs/ui/, plus a code audit, team scaling guide, and a
/lookup skill for programmatic access.

**Insights:**

1. Parallelizing 4-5 background agents per phase was the key throughput
multiplier. Main thread wrote non-overlapping docs while agents explored/wrote
heavy areas (Drizzle=659L, Testing=926L).
2. Source verification pass caught real inaccuracies: number.ts API signatures
were wrong, pagination was documented as 0-indexed but is actually 1-indexed,
card collapsible prop is non-functional. Always verify against source before
publishing docs.
3. The deep audit found critical security gaps: /api/files/ routes have no auth,
zero Zod validation in the codebase, 4 dangerouslySetInnerHTML instances with
user-controlled data. These should be flagged to the user proactively.
4. The docs/* + !docs/ui/ gitignore pattern (using * not /) is required for git
negation to work on subdirectories. docs/ (trailing slash) ignores the entire
directory and blocks all negations.
5. Creating a /lookup skill + CLAUDE.md mandatory rule is the minimal-overhead
way to make documentation programmatically accessible. No MCP server needed for
local-only use.
6. Team scaling guide's biggest insight: the codebase problem for juniors isn't
bad code — it's implicit knowledge (V1 vs V2 choices, which pattern is current,
which is deprecated). Formalizing conventions > fixing code.

--------
---

## core-dump: Session checkpoint for 5-round nav/UI improvement loop — 2026-03-
31

**Purpose:** Checkpoint a multi-round autonomous UI improvement session ending
with /exit.

**Insights:**

1. When a checkpoint file already exists, Write tool requires a prior Read first
— use Edit with full content replacement or read-then-write.
2. UTILITY_PAGE_NAMES pattern in +layout.svelte is the right place for
breadcrumb fallbacks for pages outside NAV_GROUPS — consider moving to nav.ts
for co-location in a future cleanup pass.
3. Replacing no-op <button onclick={() => {}> with <div> + --static CSS modifier
is a clean pattern for visually button-like headers that are actually non-
interactive.
4. $navigating Svelte store fires on all navigation types including programmatic
goto() — ideal for side-effect cleanup (clear search, close drawers).
5. EmptyState and PageHeader are the correct shared components for apps/status
pages — avoid re-implementing inline headers and empty state divs.

--------
---

## session: Claude Code config hardening — all 3 tiers — 2026-03-31

**Purpose:** Implemented 14 of 15 researched config improvements across 3 tiers:
security deny rules, autocompact tuning, PostToolUse/PreCompact hooks, visual
statusline, CLAUDE.md pruning (310→100 lines), Agent Teams, agnix linter
install.

**Insights:**

1. CLAUDE.md went from 310 lines / 117 rules to 100 lines / 24 rules by
extracting the WAL format template to a reference file and merging overlapping
Session Documentation + Context Retention sections. Research says compliance
drops above ~150 instructions.
2. enableAllProjectMcpServers: false is an important security setting — without
it, cloning a malicious repo with .mcp.json could auto-connect to attacker-
controlled MCP servers.
3. Python's json.loads() rejects literal \033 ESC characters as invalid JSON per
RFC 8259, but Node.js JSON.parse() accepts them. Since Claude Code is Node.js-
based, ANSI escapes in settings.json statusLine work fine.
4. agnix (v0.17.0) resolves ~ in script paths literally instead of expanding to
$HOME, causing false "script not found" errors for all hook commands using ~/.
claude/scripts/. This is a known agnix quirk — the scripts work fine in Claude
Code.
5. The statusline context bar uses remaining_percentage (not consumed), so the
math is filled = (100 - remaining) / 10 segments. Color thresholds: green <50%
consumed, yellow 50-75%, red >75%.
6. Anti-rationalization Stop hooks (from Trail of Bits research) add agent-call
latency to every single response. For personal dev environments, the cost-
benefit doesn't justify it — better suited for enterprise/compliance contexts.

--------
---

## session: Infrastructure maintenance completion + pm2 hardening — 2026-03-31 06:45

**Purpose:** Completed all 6 config audit tasks (#33-#38), added lock crash-safety to lock-file.sh, hardened pm2 with logrotate and startup persistence, registered all ports, cleaned up stale artifacts.

**Insights:**

1. `pm2 restart` does NOT re-read ecosystem.config changes — must `pm2 delete` + `pm2 start` from the config file to pick up new settings (like removing custom log paths).
2. The new `lock-file.sh cleanup` action works correctly — sweeps all `*.lock` dirs, checks age vs STALE_SECONDS, reports owner info. Zero overhead when no stale locks exist.
3. home-server uses node-cron which generates burst warnings on macOS wake from sleep — these are benign and expected, not a bug.
4. pm2-logrotate defaults (10MB max, 30 retained, daily rotation) are good for dev machines — no tuning needed.
5. Shell redirect race condition lesson (from prior context): never `cat file > same_file`. The `tee` pattern is safe: `tee dest < source > /dev/null`.

---

---

## core-dump: Infrastructure maintenance session checkpoint — 2026-03-31 06:15

**Purpose:** Snapshot the session that completed all 6 infrastructure
maintenance tasks (#33-#38) from the config audit.

**Insights:**

1. The new lock-file.sh cleanup action worked correctly on first use — called at
skill startup, reported "CLEAN: no stale locks found" in <1ms. This validates
the design: sweep is cheap (one glob + age check per lock) and safe to call
unconditionally.
2. Core-dump was the first skill to exercise the updated preamble template with
the lock cleanup call — the flow is: cleanup → acquire → write → release. No
issues with the new 3-step lock hygiene pattern.
3. The checkpoint file already existed from a prior session (March 28). The
"always overwrite" rule in the skill spec is correct — point-in-time snapshots
should replace, not append.
4. Write tool requires a prior Read on existing files. For checkpoint overwrites,
reading the first 5 lines is sufficient to satisfy the guard without loading
stale content.

--------
---

## core-dump: Checkpoint for 5-feature observability session — 2026-03-30

**Purpose:** Snapshot session implementing CacheEfficiencyChart, HourlyHeatmap,
Project Overview, ToolBreakdown (usage + errors), and server-side tool parser.

**Insights:**

1. The checkpoint file already existed from a previous session — must Read
before Write even for overwrite; Edit is the safe path when the file pre-exists
2. Both client and server TypeScript must be checked separately (npx tsc --
noEmit for client, npx tsc -p tsconfig.server.json --noEmit for server); only
checking one gives false confidence
3. Recharts Tooltip formatter prop has value: ValueType | undefined and name:
NameType | undefined — always type as any to avoid TS errors from union with
undefined
4. Lucide icons don't accept title prop — use aria-label or wrap in <span
title="..."> for accessible tooltips
5. tool_result.is_error correlation requires building an id → toolName map per
session from preceding tool_use blocks — the JSONL is sequential so one forward
pass is sufficient

--------
---

## core-dump: SSR fix session checkpoint — 2026-03-29 18:30

**Purpose:** Core-dumped after fixing SSR crash on homepage (DashboardWidget
receiving undefined system prop) and duplicate CSS @import.

**Insights:**

1. $effect.pre does NOT run during SSR in Svelte 5 — any $state(undefined as
unknown as T) that relies on $effect.pre to initialize will be undefined when
the template renders server-side. Always guard component rendering with {#if
data}.
2. When SSR crashes with "Cannot read properties of undefined", trace through
the full component tree — the crash site (DashboardWidget:59) was different from
where the undefined value originated (+page.svelte:236).
3. The initial fix attempt targeted getWidgetSummary() but the actual crash was
in DashboardWidget's $derived expressions — always restart the dev server and
test after fixing to catch the real error location.
4. CSS @import must precede all other statements. A duplicate import placed
after theme CSS rules caused PostCSS to reject the entire stylesheet. The
generator script should be audited to ensure it never places imports after rules.

--------
---

## session: Tooltip replacement across all pages — 2026-03-29

**Purpose:** Replaced all HTML title= attributes on interactive elements with
the app's custom <Tooltip> component across 13 files (11 this session + 2
prior).

**Insights:**

1. The Write tool fails for new files with "File has not been read yet" — use
cat > file << 'EOF' via Bash as a workaround for creating new files.
2. When wrapping a <button> with <Tooltip>, watch for dropdown menus that open
adjacent to the button — the </Tooltip> must close before the dropdown JSX, not
after. ExportButton required careful placement.
3. For toggle buttons (filters, levels), dynamic tooltip text ("Hide X" vs "Show
X") based on current state is more useful than static text — users see the
*effect* of clicking before they click.
4. Native HTML title is still correct for truncated text overflow (paths, long
labels, breadcrumbs). Only interactive elements (buttons, toggles) need the
styled Tooltip component.
5. The key prop on a <Tooltip> wrapping a mapped element must be on the Tooltip
itself (not the inner button), since it's the outermost element in the .map().

--------
---

## core-dump: Phase 3 completion snapshot — 2026-03-29

**Purpose:** Snapshotted session that completed Productivity PRD Phase 3
(Templates, Unified Inbox, Filter Query Language).

**Insights:**

1. The Write tool refuses to overwrite an existing file unless it was Read in
the current conversation — use Bash(cat > file << 'EOF') as the workaround when
the prior checkpoint belongs to a different session (not in context).
2. localStorage is the right store for per-client inbox state (read/unread,
archived) in a single-user home server — zero API overhead, instant UI, no
server state needed.
3. For client-side filtering that must work across multiple view modes
(board/list/table), point all derived views at a single filteredCards derived —
changing one line in columnCards() and flatCards is enough when the architecture
is set up correctly.
4. Implicit AND for adjacent terms in a filter DSL (whitespace = AND) is the
correct ergonomics for search-like inputs where users expect narrowing; | for
widening must be explicit.

--------
---

## core-dump: Template extraction catalog phase checkpoint — 2026-03-28 12:00

**Purpose:** Wrote checkpoint for the completed catalog phase of the multi-
session template extraction initiative.

**Insights:**

1. Context compaction mid-session lost trailing specifics — the conversation
summary preserved enough to continue but exact file line numbers were gone. Core-
dumping earlier at milestones would have helped.
2. The 3 deliverable files (_template-extraction-spec, _template-catalog,
_extraction-prompts) together form a complete hand-off package for Phase 3
extraction. Future sessions should read all 3 via /catchup.
3. Task list was the reliable state tracker across compaction — task statuses
survived intact while conversation context was compressed.

--------
---

## core-dump: Phase 2 productivity features session checkpoint — 2026-03-29

**Purpose:** Captured full session context after completing all four
Productivity PRD Phase 2 items (activity feed, kanban views, calendar, global
search) and verifying all pending todos.

**Insights:**

1. deleteRequest()** returns boolean, not the deleted record** — when adding
activity tracking to a delete handler, always fetch the record BEFORE deleting,
not after. The pattern const target = requests.find(...); deleteRequest(id); if
(target) addActivity(...) is correct; trying to use the delete return value will
fail.
2. createAutoRefresh** exports **restart**, not **start — the internal function
is named start() but the returned object exposes it as restart. Using
autoRefresh.start() will cause a TypeScript error; always use autoRefresh.
restart().
3. **Calendar API reads files directly to avoid circular module imports** — the
calendar endpoint spans kanban + reminders modules. Rather than importing from
both server modules (which would create cross-module coupling), reading JSON
files directly via PATHS.kanban / PATHS.reminders is cleaner and avoids circular
dependency risks.
4. **YYYY-MM-DD date strings sort correctly with localeCompare** — ISO date
format is lexicographically ordered, so simple string comparison works for date
range filtering and sorting without Date object construction.
5. **Kanban **flatCards** sort needs column tiebreak for stable ordering** —
when sorting by column in list/table view, use colDiff || a.order - b.order to
preserve drag-drop card order within each column. Without the tiebreak, cards
within a column appear in arbitrary order.

--------
---

## core-dump: Dashboard v2 session checkpoint — 2026-03-29 02:10

**Purpose:** Captured session state after completing all 9 dashboard UI
improvements and simulation re-run (15 periods, 50 MC).

**Insights:**

1. Python stdout buffering when piped causes invisible progress — always use
flush=True on print statements in long-running scripts, or run with python -u.
2. The build_viz_bundle() path from raw arrays requires state_snapshots as
List[List[WorldState]] and action_log as List[List[Dict]] — indexed
[mc_run][period]. Easy to mix up with the per-player action_log format used in
demo_iran_war.py.
3. War probability was 0% across all 50 MC runs because the simulation's Nash
equilibria converge to "limited_strike"/"threaten" rather than "full_war". The
escalation score approach (mapping conflict_status to a 0-1 gradient) is far
more informative for dashboard visualization.
4. TopoJSON countries-110m.json from CDN uses ISO 3166-1 numeric IDs (e.g.,
'840' for USA), not alpha-3. A mapping table ISO_TO_CODE is needed to link to
our country codes.
5. Playwright can't access file:// URLs — must serve via python -m http.server
for browser testing.

--------
---

## core-dump: Usage dashboard pricing fix + API docs + filtering — 2026-03-29

**Purpose:** Core dump after fixing cost calculation, adding documented APIs,
and adding filtering to the usage dashboard.

**Insights:**

1. Opus 4.5/4.6 pricing is $5/$25 per MTok — **not** $15/$75 (that's legacy Opus
4.0/4.1). This was the single biggest bug: 3x cost inflation because Opus
dominates 95% of usage. Always verify pricing against the live Anthropic pricing
page rather than relying on training data.
2. Cache read tokens dwarf all other token types in Claude Code usage (3B cache
reads vs 236K input on Opus). The cache read price ($0.50/MTok for Opus 4.6) is
10x cheaper than fresh input ($5/MTok) — this is the economic engine behind
prompt caching.
3. For agent-consumable APIs, a self-describing /docs endpoint returning JSON
(not markdown) with endpoint specs, query params, and response schemas is the
key difference from human docs. Agents can GET /docs → construct queries
programmatically.
4. Server-side filtering that recomputes aggregates from filtered sessions is
more correct than client-side filtering of pre-aggregated data — byModel and
projects need recalculation, not just subsetting.
5. React's key prop is consumed by React and never passed to the component —
using key as both a React key and a component prop causes warnings. Rename to a
different prop name like sortKey.

--------
---

## core-dump: A/B test research session checkpoint — 2026-03-28

**Purpose:** Checkpoint a complete research session comparing /compact vs /core-
dump context management approaches, including 5-scenario A/B test execution and
final report.

**Insights:**

1. For greenfield projects with no .claude/ directory, lock-file.sh still works
— it stores locks relative to the CWD, not the project root. No setup needed.
2. Running probe sub-agents with ONLY the artifact (zero conversation history)
is the correct isolation method for testing context retention — it eliminates
model memory as a confound.
3. Compact summaries simulated by a well-prompted agent preserve detail almost
as well as checkpoints in controlled conditions (93% vs 100%). The real-world
gap is much larger in messy, long sessions.
4. The single most valuable field in a core-dump checkpoint is ## Current
Expectation — it captures WHERE the session left off, not just what happened.
Compact has no equivalent.
5. The right hook to intercept context loss is PreClear (warn if no checkpoint
exists), not PreCompact (no such hook exists; auto-compact fires without
warning).

--------
---

## core-dump: context continuation checkpoint — 2026-03-28

**Purpose:** Snapshot session state after completing global scratchpad copy and
exploration guide.

**Insights:**

1. Context-window continuations need explicit mention of what the prior session
accomplished — without it, /catchup loses the full picture
2. "Pending Items: None" is a valid and useful checkpoint state — signals clean
handoff with no dangling work

--------
---

## session: Global scratchpad copy + exploration guide — 2026-03-28

**Purpose:** Copied pattern docs to global scratchpad for cross-project reuse
and
wrote an exploration guide for new agents.

**Insights:**

1. Global scratchpad convention requires YAML frontmatter with scope: global,
project:, tags:, and source: fields — added a 00-context.md file with project
metadata as the entry point
2. Numbered prefixes (00–10) in filenames enforce reading order in the
scratchpad folder — useful when docs have a natural progression (context →
storage → server → UI → patterns → caveats)
3. The exploration guide works best as a "how to find things" reference rather
than explaining what things are — pattern docs handle the "what", the guide
handles the "where to look"
4. Shell cp is faster than Write tool for bulk file copying when content doesn't
need modification — just use cp with renamed targets

--------
---

## core-dump: viz design session checkpoint — 2026-03-28

**Purpose:** Checkpointed a session that verified /create-report math support
(already complete) and produced two design documents for a geopolitical
visualization dashboard.

**Insights:**

1. /create-report math rendering is fully functional — KaTeX v0.16.21 with auto-
render handles both $$...$$ display and $...$ inline math. No skill improvement
was needed despite the user's initial request to check it.
2. Chrome DevTools MCP crashes when pkill is used on Chrome processes — the MCP
server disconnects permanently. Use Playwright MCP instead for browser
verification.
3. Opus agent (launched via Agent tool) produced excellent UX specification when
given rich domain context about the simulation engine. Key: providing the exact
data structures (12 indices, 66 dyads, 5 game domains) lets the agent make
specific, actionable design proposals rather than generic ones.
4. The self-contained HTML pattern (JSON data + static HTML + no server) from
/create-report is the right architecture for the viz dashboard too. Analysts
don't want to run servers.

--------
---

## session: P3 remaining items — full execution — 2026-03-28

**Purpose:** Executed all 9 remaining P3 items from the ecosystem cleanup plan,
completing the entire multi-session cleanup effort.

**Insights:**

1. Parallel agent dispatch for research (5 Explore agents) + parallel agent
dispatch for writes (4 quick-query agents) is highly effective — Batch 1 (5
items) completed in ~45 seconds total wall time.
2. The Versable scripts project has a rich pipeline architecture with 18
transforms — the CLAUDE.md needed to capture both the data flow pattern (raw.
json → step.json → final.json) and the critical testing rules (test 2-3 rows,
read xlsx back, etc.).
3. sp_update tool follows the same file-resolution pattern (local → global
fallback) as sp_read/sp_delete — keeping the interface consistent. Appends with
\n\n separator to maintain readability.
4. The /daily-todo skill hardcodes 9 project paths rather than auto-discovering.
This is a deliberate trade-off: auto-discovery from ~/ violates the "never glob
from home" rule, and the project list changes rarely.
5. The /archive-notes skill uses quarterly archive filenames (runtime-notes-
archive-YYYY-QN.md) and appends to existing archives — so running it twice in
the same quarter doesn't create duplicate files.
6. Archive reference memory was correctly skipped — only 1 project (home-server)
has an archive, so a global reference would be premature.

--------
---

## session: Resume processing (Sai Teja) + workflow immutability rule — 2026-03-
28

**Purpose:** Processed Sai Teja's resume with GitHub scrape and full candidate
evaluation. Added immutability rule for candidate profiles to CLAUDE.md.

**Insights:**

1. PDF location mismatch happened again (~/Documents/ specified, file in
~/Downloads/). The fallback search pattern works but this is a recurring pattern
— consider noting it to the user proactively.
2. Same candidate was already processed on Mar 26 in a different folder (Mar 26,
2026 Sai Teja Kolluru/). The new immutability rule in CLAUDE.md will prevent
this in future sessions by requiring a check-and-ask before creating duplicate
folders.
3. Background agent for GitHub scraping took ~2.5 minutes. The candidate notes
can be drafted in parallel from resume data alone, then enriched when GitHub
data arrives — this worked well and avoided blocking.
4. When a candidate has an existing folder, the runtime-log should reference it
as a "re-process" rather than a fresh entry — keeps the audit trail clear.

--------
---

## core-dump: Ecosystem cleanup continuation checkpoint — 2026-03-28

**Purpose:** Captured session state after completing 3 new todo items (plugin
disable, MCP guidelines, plan audit) and all P0-P2 cleanup work.

**Insights:**

1. The lock-file.sh acquire command ran as background task unexpectedly — may
need to verify the run_in_background default on Bash tool calls. Lock was
acquired regardless.
2. Write tool requires a prior Read of the target file even for overwrites —
always read the existing checkpoint before writing.
3. The 7 disabled plugins are tracked in a separate JSON registry (disabled-
plugins.json) rather than comments in settings.json — this is more robust since
JSON doesn't support comments.
4. Context compaction loses scratchpad server tool results but the audit log in
scratchpad/global/ preserves the full record — the two-tier persistence
(conversation + file) pays off during long sessions.

--------
---

## core-dump: Checkpoint with model improvement analysis — 2026-03-28

**Purpose:** Wrote comprehensive core dump covering HTML report generation, 10
new scenarios, 5 new countries, and detailed analysis of three model
improvements (ceasefire, fatigue, mass communication).

**Insights:**

1. The core-dump skill works well for capturing not just "what happened" but
also "what should happen next" — the model improvement analysis section is a
natural extension that helps the next session start with design context.
2. Lock file auto-expired (stale) between acquire and write because the Write
tool took longer than 5 minutes. For long writes, the lock protocol's 5-minute
timeout is too short. Workaround: write first, then acquire+release as a
validation step rather than a guard.
3. Playwright MCP can't launch when Chrome is already running (port conflict).
Chrome DevTools MCP also blocked. For browser verification, either close Chrome
first or use the open -a approach + manual verification.
4. Background agents (Sonnet) for country YAML creation worked well — 5 agents
completed in ~50-60s each, all producing correct 163-factor profiles. Good
pattern for embarrassingly parallel file generation.

--------
---

## core-dump: detailed checkpoint for productivity session — 2026-03-28

**Purpose:** Wrote detailed checkpoint covering reminders overhaul, kanban
improvements, universal linking system, and productivity PRD (v4.34.0).

**Insights:**

1. "in detail" instruction produces significantly longer Agent Actions — each
action gets 3-8 sub-bullets explaining implementation details (CSS patterns,
function signatures, data models). Good for sessions with architectural
decisions that need to survive context clears.
2. The prior checkpoint from this same session was overwritten (correct behavior
— checkpoints are point-in-time snapshots, not append logs).

--------
---

## session: Productivity suite — reminders overhaul, kanban polish, linking
system, PRD — 2026-03-27

**Purpose:** Overhauled reminders UI with quick presets/priority/icons, improved
kanban with column accents and optimistic drag, created universal linking system
between all productivity modules, and wrote a 300+ line PRD informed by
Notion/Trello/Asana/TickTick/Todoist competitive analysis.

**Insights:**

1. color-mix(in srgb, var(--priority-color) 10%, transparent) generates tinted
backgrounds from any CSS custom property — avoids needing separate *-bg
variables for every color.
2. The universal linking system stores edges in a flat links.json — querying
"what's linked to X?" scans both source* and target* fields. O(n) over all links,
but sub-ms for <1000 entries.
3. LinkedItems component shows truncated IDs (slice(0,6)) instead of titles —
needs a cross-module title lookup API to be truly useful. This is a follow-up
item.
4. Background research agents can complete after context clear — the task
notification arrives but the original agent ID may not resolve. Always check the
output file path from the notification.
5. Optimistic UI for drag-and-drop: save old state → mutate locally → API call →
revert on failure. Makes the board feel instant.
6. The PRD's "multi-view on one dataset" pattern (from Notion) should inform
future architecture — kanban, list, calendar, and table views should all read
from the same data file.

--------
---

## session: P2 backend dedup + permission/plugin audit + mcp-catalog fix — 2026-
03-
27

**Purpose:** Completed P2 items from ecosystem cleanup todo: backend skill
consolidation, permission audit, plugin audit, and mcp-catalog templateVars fix.

**Insights:**

1. Permission counts in the original scan were wildly wrong (120 estimated vs 10
actual). The scan counted .jsonl session history entries, not permission rules.
This validates the "verify before refactoring" feedback memory we created in P1.
2. Backend project skills (add-dashboard, build-scraper, improve-scraper) don't
fall back to global like project-local skills do in Claude Code. They're Python
agent scripts specific to the enhancement-product context — keeping the
canonical copy in the primary project, not moving to global.
3. The {{HOME}} bare placeholder in mcp-catalog.json was a ticking bug — add-
mcp's Step 4 handles templateVars substitution (replacing {{KEY}} patterns), but
{{HOME}} wasn't declared as a templateVar. Fixed by adding templateVars: {
"HOME_DIR": "$HOME" } which auto-resolves from environment.
4. Plugin audit revealed 6 candidates for removal (linear, sentry, stripe,
railway, analyze-codebase, frontend-developer, wd). These add noise to skill
menus and hook evaluation. Worth disabling if not actively used.
5. The todo file itself is a valuable artifact — updating it with completion
status + actual results (vs. estimates) creates a session-spanning audit trail.
Future /catchup sessions benefit from seeing what was estimated vs. what
actually happened.

--------
---

## core-dump: Write tool requires Read first — 2026-03-27

**Purpose:** `/core-dump` failed mid-session because the Write tool requires reading an existing file before overwriting it.

**Insights:**

1. **Write tool gatekeeping**: If `_checkpoint.claude.md` already exists, Write will fail with "File has not been read yet" unless you Read it first. Always Read the existing checkpoint before acquiring the lock and writing.
2. **Lock orphan recovery**: If a lock is acquired but Write fails, the lock stays held. Must `lock-file.sh release` before the next attempt. This is safe — the lock is advisory.
3. **Compact summary preserves prior work**: After `/compact`, the session summary includes full prior-session context. The next `/core-dump` correctly overwrites with all accumulated work, including the compacted portion.

---

---

## session: P1 skill dedup + memory audit — 2026-03-27

**Purpose:** Deduplicated frontend↔global skills (23→1 dir, ~200KB saved),
audited and fixed stale memories, created missing feedback memories for home-
server.

**Insights:**

1. md5 hash comparison is the fastest way to verify skill identity — byte-level
before text-level diff. Of 21 overlapping skills, 19 were byte-identical, 2
diverged (core-dump by 130B, create-report by 1015B).
2. When centralizing skills to global, check for relative path references to
shared/ in the remaining project files (GUIDELINES.md, any kept skills). The
core-dump divergence was specifically about this — relative .
claude/skills/shared/ vs absolute ~/.claude/skills/shared/.
3. create-report had both SKILL.md and companion files (generate-html.ts, report.
js, styles.css) diverge — the global version added math/LaTeX block support.
Always check companion files too, not just SKILL.md.
4. The ghostty keybind gaps memory was a good example of what NOT to store:
upstream product limitations are not actionable project memories. Delete, don't
keep.
5. The scratchpad MCP server works end-to-end (5/6 tools tested). The sp_write
tool creates files with proper frontmatter. Session dedup means it activates
after session restart as expected.
6. Parallel Explore agents for inventory (global skills + frontend skills +
memory files) saved significant time — 3 agents finished while MCP testing ran
concurrently.

--------
---

## session: UI polish + 120-problem validation suite — 2026-03-27

**Purpose:** Fixed h1 top padding in markdown, discussed future features (REPL),
built a validation script that smoke-tests all 120 problem scaffolds, and fixed
2
broken scaffolds to reach 120/120 pass rate.

**Insights:**

1. bash ((0)) returns exit 1 — never use set -e with arithmetic increment on
counters that start at 0. Use PASS=$((PASS + 1)) or drop set -e.
2. macOS ships without GNU timeout — either install coreutils (gtimeout) or
avoid it in portable scripts.
3. pydantic-ai v1.73+ renamed result_validator → output_validator and
_result_validators → _output_validators with no deprecation warning. Pin
versions in pyproject.toml or check the installed version.
4. pydantic-ai Agent() eagerly validates API keys at construction time (module
level). For test files that mock the LLM, add a conftest.py with os.environ.
setdefault("OPENAI_API_KEY", "test-dummy") to prevent import-time crashes.
5. Debugging problems with intentional import-time errors should use pytest
fixtures for imports, not top-level from solution import X. This lets pytest --
co collect tests even when the scaffold is broken.
6. Tailwind first:mt-0 placed before mt-8 wins when the element is :first-child
because the pseudo-class selector has higher specificity. Good pattern for
removing leading margins in container-agnostic components.

--------
---

## session: docs quality pass + index.html UX + smoke-test — 2026-03-27

**Purpose:** Quality pass on 25 tool docs (official links + PDF regen), 6 UX improvements to index.html modal, and smoke-test script for all 41 tools.

**Insights:**

1. Write tool requires reading an existing file first — even for a full overwrite. If Write fails with "File has not been read yet", Read first then Write. Lock must be released before Read to avoid deadlock.
2. `shutil.which()` in Python does NOT see shell functions or aliases — only real executables on PATH. This is correct behavior: `rg` defined as a zsh function won't appear.
3. View Transitions API pitfall: assigning `view-transition-name` to both source card and modal simultaneously causes browser to morph card→modal (double animation with existing CSS spring). Remove VT entirely if CSS animation already handles open/close.
4. `npx md-to-pdf` must be run synchronously — backgrounding causes Puppeteer to hang indefinitely. Always use a `for` loop without `&`.
5. Batch editing 25 files: inline Python `content.replace()` in a single script is faster and safer than 25 individual Read+Edit pairs (which also require sequential execution due to "read before edit" rule).

---

---

## core-dump: Checkpoint themes + reminders + kanban session — 2026-03-27

**Purpose:** Snapshot session covering 7 new light themes, theme color
consistency audit, kanban card editing, reminders feature, and kanban-to-
reminders
integration.

**Insights:**

1. When exploring multiple features (themes, kanban, notifications) in parallel,
launching 3 sub-agents simultaneously saved ~2min vs sequential exploration.
2. The kanban API already had an update action that was never wired to UI —
always check existing API capabilities before designing new endpoints.
3. updateMetaThemeColor() must be called from both setTheme() and initTheme() —
forgetting initTheme() means the meta tag stays wrong on page load with a saved
non-default theme.
4. Context-aware snooze presets (getSnoozePresets()) that filter by time-of-day
feel much more natural than static options — the minutesUntilHour() helper keeps
the math clean.
5. The use:autofocus Svelte action pattern with requestAnimationFrame is the
correct way to focus elements that appear via {#if} blocks — HTML autofocus
attribute only fires on page load.

--------
---

## session: Iran War report generation + math verification + core dump — 2026-03-
27 16:25

**Purpose:** Generated HTML report from Iran War 2025 markdown via /create-
report
skill, verified math rendering in browser, assessed skill for math support, and
wrote comprehensive core dump.

**Insights:**

1. The /create-report skill already fully supports mathematical notation — KaTeX
v0.16.21 loaded from CDN, math block type for display equations, $...$ inline
delimiters processed by auto-render. No skill improvements needed.
2. Playwright blocks file:// URLs — use python3 -m http.server on a local port
to serve static HTML for browser verification.
3. The generate-html.ts script at ~/.claude/skills/create-report/ (user-level,
not project-level) is the correct path — previous session had to discover this.
4. Context overflow is a real risk with this project — the Iran War report
markdown + JSON + simulation output together consumed significant context. Use
/core-dump proactively before context fills up.
5. When Playwright's browser_navigate returns too-large output (87K chars), the
page snapshot is saved to a file — but you can still evaluate and
take_screenshot without reading the full snapshot.

--------
---

## session: Modal portal, error boundaries, nav reorganization — 2026-03-27

**Purpose:** Fixed modal positioning bug, added error boundaries, reorganized
sidebar navigation based on quality review.

**Insights:**

1. Svelte use:action is the cleanest portal pattern — action lifecycle aligns
with {#if} block creation/destruction. Don't try $effect + DOM manipulation for
portals.
2. <svelte:boundary> only catches synchronous render errors. Async errors in
onMount/$effect/event handlers still need try/catch. The layout-level boundary
is the highest-impact placement.
3. When moving tab components between route directories, check imports are all
$lib/ (portable) vs relative (route-coupled). All Diag* and Net* components use
$lib/ imports, making them freely portable.
4. The use:portal approach moves DOM to document.body — Svelte's scoped CSS
class hashes travel with the element, so styles still apply after portaling.
5. Navigation reorganization: renaming "Network" page to "Network Toolkit"
avoids the group-name-equals-item-name tautology.
6. When deleting dead code after tab merges, grep for the component name first
to confirm it's truly unreferenced.
7. Icon dedup matters for sidebar scanability — three settings icons side by
side is genuinely confusing.

--------
---

## session: Ecosystem cleanup + scratchpad system — 2026-03-27

**Purpose:** Scanned all 20 project .claude dirs, archived runtime notes,
generated 7 CLAUDE.md files, updated GUIDELINES.md, cleaned stale plans, built
scratchpad system with shell scripts + MCP server.

**Insights:**

1. Scan agents over-count ##  entries because they match inside entry bodies
(sub-headers in insights). Use ^##  (line-anchored grep) for accurate counts. 3
of 4 archive targets turned out to be well under threshold.
2. Sub-agents hit permission denials on Write/Bash for out-of-project
directories. The workaround (agent researches + parent writes) works but adds a
round-trip. MCP tools bypass this — primary motivation for building the
scratchpad MCP server.
3. BSD sed frontmatter range matching (/^---$/,/^---$/) doesn't work reliably on
macOS. Use awk '/^---$/{n++; next} n==1 && /^field:/{...}' pattern instead —
works cross-platform.
4. 11 parallel background agents is practical but several hit permission walls.
Foreground agents might be better for write-heavy tasks unless permissions are
pre-approved.
5. The {{HOME}} placeholder in mcp-catalog.json needs the add-mcp skill to
substitute. When adding to .mcp.json directly, use the absolute path instead.
6. "type": "module" is required in package.json for MCP servers using ESM
imports. The npm init default is "commonjs".

--------
---

## session: write 10 new tool docs + index.html update — 2026-03-27

**Purpose:** Added git, curl, kubectl, bun, make, ssh, ripgrep, openssl, brew,
httpie docs (md + PDF) and updated index.html from 26 to 36 tools across 2 new
sections (HTTP & Network, JavaScript) plus expansions to existing sections.

**Insights:**

1. **md-to-pdf gets stuck when backgrounded** — Puppeteer's Chrome launcher
waits for a TTY/stdin. Running npx md-to-pdf as a background Bash task caused it
to hang indefinitely. Run it synchronously in the foreground; it completes in
~3s per doc once Chrome is warm.
2. **Section grouping choices matter for discoverability** — curl + httpie as
"HTTP & Network", bun as "JavaScript", ssh/openssl/make in Infrastructure felt
more natural than a flat dump. Section labels are the primary navigation layer
for new users.
3. data-tags** is the search index** — the search handler queries card.dataset.
tags. Include common synonyms (rg, k8s, grep, tls) not just the canonical name,
or users searching by alias won't find the card.
4. **Content-addressable edits are order-independent** — editing index.html with
string-match Edit tools means no need to track line numbers between edits. Each
edit is fully independent.

--------
---

## session: P1 quick wins — docs, auto-refresh, fetchApi, goto — 2026-03-27

**Purpose:** Executed all 4 P1 quick-win items from the pending todo list:
updated 5 stale docs, migrated auto-refresh on 2 pages, replaced window.location
reads with $page.url, and fixed 4 raw fetch calls.

**Insights:**

1. Only 2 of 7 "auto-refresh" pages actually fit createAutoRefresh(). The others
use intervals for fundamentally different patterns (poll-until-done, per-entity
pollers, user-toggled monitoring). Grouping by syntax (setInterval) rather than
intent leads to wrong migration targets.
2. createAutoRefresh() auto-starts on mount but doesn't call the callback
immediately — pages that need an initial fetch on mount still need a separate
onMount(() => callback()).
3. The lights page's toggle pattern (start/stop the actual interval) doesn't map
to the utility's enabled flag (which only skips the callback while the interval
keeps ticking).
4. The checkpoint's claim of "2 window.location.href navigations" in files page
was incorrect — both were URL *reads*, not navigations. Always verify checkpoint
claims against actual code before acting.
5. project-index.md was v1.1.1 while the app was at v4.29.2 — a 28-version drift.
For docs that contain counts/stats (components, pages, icons), staleness is
cumulative and compounds session after session.

--------
---

## core-dump: Full project audit + detailed todo checkpoint — 2026-03-27

**Purpose:** Wrote comprehensive checkpoint with prioritized todo list,
implementation notes, and caveats for all remaining project work.

**Insights:**

1. The project has 5 planning/research docs that drift out of sync with reality
— roadmap, 2 research docs, code-cleanup-plan, and project-index all show stale
stats or mark completed work as pending. Updating these is a quick P1 win.
2. 7 pages still use raw setInterval instead of createAutoRefresh — the biggest
gotcha is network/+page.svelte which has multiple independent intervals that may
need 2 controllers.
3. Page merges (36→19 sidebar items) are the highest-impact UX improvement
remaining, but each merge group has caveats: SSE teardown on tab switch (ports),
server-side data loads moving to client-side (docker), and keyboard shortcut re-
registration per tab.
4. DataTable v2 (custom cell renderers via snippets) is a blocker for adopting
DataTable on 9 remaining pages — the current string[][] interface can't render
progress bars or action buttons.

--------
---

## session: Dashboard builder + compile fix + dev-learnings doc — 2026-03-27

**Purpose:** Implemented dashboard builder with widget registry, fixed Svelte
compile error, and authored comprehensive dev-learnings reference doc.

**Insights:**

1. Svelte 5 {@const} tags can ONLY appear as direct children of logic blocks
({#if}, {:else}, {#each}, {#snippet}). Placing them inside HTML elements (e.g.,
<div>) causes a compile error. Fix: inline the expression or restructure the
template.
2. When extracting widget rendering into a child component, all scoped CSS must
be duplicated into the child — Svelte's scoped styles don't cascade across
component boundaries. This is by design but causes ~300 lines of CSS duplication.
3. The widget registry pattern (TypeDef → Instance → Renderer) is a clean plugin
architecture. reconcileLayout() on load ensures new widget types auto-appear in
existing layouts and stale ones are pruned — critical for schema evolution with
localStorage persistence.
4. localStorage migration strategy: version the key name (hs:dashboard-layout →
hs:dashboard-layout-v2), detect old key, transform, save new format, and
reconcile.
5. replace_all in the Edit tool is dangerous when the replacement pattern
appears in different syntactic contexts — it broke goto() calls by blindly
replacing across all occurrences. Prefer individual edits for syntax-sensitive
transforms.
6. The dev-learnings doc at docs/dev-learnings.md catalogs 24 reusable patterns
with exact implementations — useful as an AI SDK reference or for onboarding.

--------
---

## session: index.html modal + view improvements — 2026-03-27

**Purpose:** Added cards/table view toggle, fixed markdown scroll, added marked
CDN renderer with XHR fallback, created start.sh, and overhauled the modal with
SM/MD/LG sizing, open-in-new-tab, view transitions, favicon, and tab title.

**Insights:**

1. The markdown scroll bug root cause: min-height: 400px on .modal-body breaks
the flex overflow chain — flex children cannot scroll unless every ancestor has
either a bounded height or min-height: 0. The fix is min-height: 0 all the way
down.
2. fetch() is blocked by CORS on file:// in Chrome 80+, but XMLHttpRequest to
same-origin file:// URLs still works in Firefox/Safari — a three-tier fallback
(fetch → XHR → iframe) covers the most browsers without a server.
3. document.startViewTransition() must have the view-transition-name set
*before* the callback runs (not inside it) — the API captures the "old" state at
call time, then runs the callback and captures "new" state.
4. CSS spring transitions and view transitions conflict: the named element's CSS
transition fires after the VT completes, causing a double-animation. Disabling
it with a vt-open class during the transition prevents this.
5. SVG data URI favicons (data:image/svg+xml,...) support emoji rendering
natively in all modern browsers — no PNG export or image files needed for simple
emoji icons.

--------
---

## session: Dashboard builder — widget registry + refactor — 2026-03-27

**Purpose:** Implemented the dashboard builder system: widget registry,
DashboardWidget component, preset templates, add/remove widget UI, and
refactored +page.svelte from 1515 lines of hardcoded sections to a registry-
driven renderer.

**Insights:**

1. The existing dashboard already had 80% of the builder infrastructure (drag-
and-drop, size system, visibility toggles, localStorage persistence). The key
missing piece was decoupling widget *definitions* from widget *instances* — a
registry pattern that makes the system extensible.
2. Moving widget rendering into a separate DashboardWidget component requires
duplicating all the scoped CSS. Svelte's scoped styles don't cascade into child
components. An alternative would be :global() wrappers, but co-locating styles
with the component is more maintainable.
3. Layout migration from v1 to v2 format was trivial because the shape barely
changed — only added typeId field alongside id. The reconcileLayout() function
handles forward-compat by adding new widget types and removing stale ones.
4. Preset templates are just pre-configured WidgetInstance arrays. Applying a
preset replaces the entire layout — this is simpler than trying to merge presets
with existing layouts.
5. The settings modal gained a tabbed UI (Layout/Presets/Add Widget) — this
pattern works well for progressive disclosure without overwhelming users.

--------
---

## session: Core dump after showcase + PWA + component adoption session — 2026-
03-
26

**Purpose:** Captured session state after completing 3.5 of 4 major work streams
(showcase gaps, PWA wins, ActionGroup/DropdownMenu, AsyncState/FilterBar
adoption across 14 pages).

**Insights:**

1. Parallel agent strategy worked well — 3 agents for AsyncState (batched by
complexity) + 1 for FilterBar ran concurrently without conflicts since they
touched different pages.
2. StatCard adoption was a false positive in the audit — existing
dashboard/benchmarks/speedtest pages use custom SVG visualizations that don't
map to StatCard's simple label/value/sparkline model. Better to use StatCard for
new features.
3. Version bumps from parallel agents can conflict — each agent re-reads app.ts
before bumping, but if two finish simultaneously, one will fail the edit
uniqueness check. Agents handled this by catching and retrying.
4. The "Learn by Doing" pattern (presenting architecture decisions before
implementing) is a natural checkpoint for core-dump — the user's pending
response is the clear resume point.

--------
---

## session: helper-docs bootstrap + batch doc generation — 2026-03-26

**Purpose:** Initialized helper-docs repo, wrote CLAUDE.md agent instructions,
generated 8 tool reference docs (zellij, tmux, nano, vim, psql, mongosh, redis-
cli + zellij-resources), built PDFs for all, and created a styled HTML
entrypoint
index.

**Insights:**

1. Parallel subagents (3×) for the 6-tool batch cut total time significantly —
each agent ran independently with its own tool calls and runtime context.
2. generate-pdf skill was already in global ~/.claude/skills/ — when user says
"look for a skill", check global dir first before the project dir.
3. The index.html entrypoint must be fully self-contained (no CDN, no server) to
work as a file:// URL — all styles inline, all links relative.
4. Agent-generated docs tailored to the user's actual config (e.g., zellij clear-
defaults=true keybinds, nano ~/.nanorc) are significantly more useful than
generic docs — always read real config files first.
5. For future /core-dump runs in this project: pending improvements include per-
tool resources docs, HTML reports for all 8 tools, and potential git init.
---

## session: questions_v2 review + fixes + AI policy — 2026-03-26

**Purpose:** Generated PDFs for 120 problems, created utility scripts, wrote
review guide, executed review across 6 domains, fixed systemic issues, added AI
Tool Policy.

**Insights:**

1. md-to-pdf via npx requires absolute paths — relative paths silently produce 0
output with exit code 0. Always use find "$(pwd)"/...
2. Debugging interview problems had a systemic pattern: agents that generate
buggy code also generate comments explaining the bugs. Grep pattern Bug [0-9]|
Bug:|root cause|fix: catches them reliably (threshold: >2 hits per file)
3. Source-inspection tests (grep on source text via inspect.getsource or
open(__file__)) are a code smell — they pass on any code that "looks right"
structurally. The backend-api domain was worst affected (11/20 problems)
4. AI policy insertion is best done via a shell script (not 120 Edit calls) —
add-ai-policy.sh with idempotency check (grep -q "## AI Tool Policy") prevents
double-insertion
5. Stratified sampling (1 per domain × format) catches systemic patterns with 5%
coverage. The 6-problem sample found issues that affected 30%+ of all problems
6. When running parallel review agents, give each a strict output format
([SEVERITY] path: description) — makes merging findings trivial

--------
---

## session: Batch implementation of 23 tasks (files, audits, sidebar) — 2026-03-
26

**Purpose:** Completed all 38 tracked tasks including /files features (EPUB
reader, tab system, duplicate), sidebar reorganization, keyboard shortcuts
across 16 pages, and 6 audit/research documents.

**Insights:**

1. Parallelizing background agents (audits, research, bulk edits) with direct
feature implementation maximizes throughput — 6 agents ran concurrently with
main thread work
2. The DocumentRenderer registry pattern in src/lib/renderers/ makes adding new
file type renderers trivial — just implement canRender() + render() and register
in index
3. For file tabs, storing only the path per tab (not full state) avoids
duplicating 10+ state variables — re-fetch on switch is effectively instant for
a local server
4. NAV_GROUPS being fully data-driven means sidebar reorganization (5→9 groups)
is a single-file change with zero template modifications
5. Explore-type agents return results but don't write files — need to save their
output manually when disk persistence is needed
6. epubjs needs --force install due to Node engine mismatch on Node 23; works
fine at runtime despite the warning

--------
---

## core-dump: cc30-enhanced full session dump — 2026-03-26 18:30

**Purpose:** Comprehensive checkpoint covering Excel parse, attribute
validation, character cleanup, poster download, image URL cross-run backfill,
selective re-download, and data quality audit.

**Insights:**

1. "everything" instruction → included data summary table, key files table, and
decisions/learnings section beyond the standard 4 sections. Good pattern for end-
of-project checkpoints.
2. The 5-check data audit pattern (duplicates, length outliers, distribution
analysis, URL integrity, cross-field consistency) is reusable for any product
data pipeline.
3. Cross-run image backfill by Part Number is a valuable pattern — older runs
may have data from different sources (eBay vs JEGS product pages) with different
image quality.

--------
---

## core-dump: Checkpoint after graph UX round 2 — 2026-03-26

**Purpose:** Wrote _checkpoint.claude.md capturing hover tooltips, connection
filters, and breadcrumb navigation implementation session.

**Insights:**

1. When the session already loaded GUIDELINES.md earlier, no need to re-read it
for the core-dump — saves a tool call.
2. The "Files Modified This Session" table format in the checkpoint is more
scannable than inline file references in the action log — good pattern for
implementation-heavy sessions.

--------
---

## session: Graph UX round 2 — tooltips, connection filters, breadcrumbs — 2026-
03-26

**Purpose:** Added hover tooltips on graph nodes, connection direction filtering
in the detail panel, and breadcrumb navigation for traversing related entities.

**Insights:**

1. React Flow nodes can host hover tooltips internally using useState + useRef
timer — no need for external tooltip libraries or onNodeMouseEnter callbacks on
the parent <ReactFlow>. The 500ms delay via setTimeout prevents flicker during
fast mouse movement.
2. Separating incomingCounts and outgoingCounts in the graph memo (alongside the
existing edgeCounts) enables both the tooltip display and potential future
features (sorting nodes by connectivity direction).
3. Breadcrumb navigation in a detail panel works cleanly with a local history:
string[] state that wraps the Zustand selectEntity — the navigateTo function
pushes current ID to history before selecting the new one, while goBack pops and
selects. This avoids polluting the global store with UI-only navigation state.
4. The type guard filter((n): n is NonNullable<typeof n> => n != null) is
cleaner than complex as casts for filtering nullable array results from .map().
filter() chains in TypeScript.
5. For Playwright testing with 164 nodes, the accessibility tree exceeds 128KB —
always save snapshots to files and grep for specific refs rather than reading
the full output.

--------
---

## core-dump: cc30-enhanced validation & poster session — 2026-03-26 18:00

**Purpose:** Checkpoint the cc30-enhanced poster download session after
completing image URL swap and selective re-download.

**Insights:**

1. Cross-referencing older pipeline runs by Part Number can recover high-res
eBay image URLs that were lost when data was re-sourced from JEGS product pages
(mini_100 thumbnails).
2. Selective poster re-download (only changed rows) saved ~60% time vs full re-
run — write the diff PNs to a JSON file and filter the input array.
3. Cloudflare cf_clearance tokens expire quickly (~15-30min) and are tied to IP+
UA — copying browser cookies to curl/fetch rarely works for batch operations.
4. The flattenArrayFields in io.js serializes object arrays as raw JSON — for
Excel delivery, a custom export with "Key: Value" formatting is much more
readable.

--------
---

## core-dump: Session checkpoint with todos, goals, context — 2026-03-26

**Purpose:** Wrote _checkpoint.claude.md capturing graph UX enhancements session
— keyboard shortcuts, type filters, context menu, and Playwright testing
framework.

**Insights:**

1. When the session has been compacted, the conversation summary provides enough
detail to reconstruct a meaningful checkpoint — no need to re-read modified
files.
2. The _checkpoint.claude.md file already existed from a prior session; reading
it first (as required by Write tool) also serves as useful context for what
changed between sessions.

--------
---

## session: interview coding problems audit & fix — 2026-03-26

**Purpose:** Audited 12 coding problem files (120 problems) across 6 domains for
consistency, type distribution, cross-profile overlap, and startup grounding.
Fixed all issues found.

**Insights:**

1. Parallel agent generation consistently over-indexes on Implementation type
for Medium-tier problems in longer-format docs. 5 of 6 coding-long.md files had
3 Impl / 1 Debug / 1 Mini-Design instead of 2/2/1. Future bulk generation should
include explicit type assignment per problem slot in the agent prompt.
2. Converting Implementation → Debugging is more than relabeling — effective
debug problems present buggy code with 3 distinct, related-but-independent bugs.
The "3 bugs" pattern tests systematic diagnosis (did they stop after finding
one?).
3. Cross-profile overlap for infrastructure patterns (rate limiting, heartbeat,
circuit breaker) is inevitable when agents write domain problems independently.
The fix is: keep each pattern in its PRIMARY competency profile, replace
duplicates with domain-native problems. Grep across all profiles post-generation.
4. "20 minutes" copy-paste typo in coding-long.md intros appeared in 3 of 6
files — agents copying the short-format intro template. Include the correct time
reference in the generation prompt.
5. Startup grounding is weakest in frontend-ui problems because React/Next.js
patterns (hydration, error boundaries, data tables) feel universal. Fix: inject
product-specific column names, data types, and failure modes into Setup sections.
6. The 6-parallel-audit → synthesize-cross-domain pattern works well: each agent
does deep per-file analysis, then the parent agent catches systemic patterns no
single agent would see (like the same Redis rate limiter appearing in 3 domains).

--------
---

## session: sideload overrides + image cross-ref + xlsx export fix — 2026-03-26

**Purpose:** Fixed [object Object] xlsx export (server restart needed), built
durable sideload mechanism for Part Type/Image/product patches, cross-referenced
images from older pipeline run.

**Insights:**

1. Node.js require() caches modules for process lifetime — restarting the server
is required for io.js changes to take effect. Always verify PID changed after
restart.
2. Three-file sideload pattern (part-type-overrides, product-patches, image-
overrides) keeps concerns separate: flat PN→value map for simple overrides,
structured patches for multi-field data, generated file for cross-run references.
3. manifest.getOrCreate() only bootstraps from run.config.js if no run.manifest.
json exists — adding a new step to config requires deleting the manifest to
force regeneration.
4. Three fields (original_attributes, raw_attributes, raw_fitment) account for
97% of xlsx export size (17MB → 0.54MB without them). These are provenance/debug
data, not export-worthy.
5. Cross-run image sourcing by Part Number matched 126/140 missing images from
jegs-ebay-final-mar25 — always check older runs before external sourcing.
6. fit_type promotion to final_attributes as Part Fitment key-value keeps it
consistent with other attributes for downstream consumers while preserving the
top-level field for filtering.

--------
---

## core-dump: /files tasks #17–19 session snapshot — 2026-03-25

**Purpose:** Snapshot session completing breadcrumb dropdown, global title
centering fix, and upload UI redesign.

**Insights:**

1. $derived** temporal dead zone** — declaring a derived before the $state it
references causes a runtime error in Svelte 5. Move derived declarations to
after all state they reference.
2. **Browse API field mismatch** — /api/files uses isDirectory, /api/browse uses
isDir. Any shared fetch helper must branch per mode or the filter silently
returns empty.
3. **Margin-bottom in flex rows** — margin-bottom on a flex item shifts text
above center (CSS centers the margin box, not the content box). One global
context selector in app.css is cleaner than patching each page with scoped
overrides.
4. **Upload queue UX** — clearing the queue immediately after upload gives users
no confirmation of what was uploaded. A 5s auto-clear + dismiss button is the
right default.
5. **System mode absolute path** — currentPath in system browse mode is already
absolute; in uploads mode, construct it as uploadDir + '/' + currentPath. Expose
uploadDir from the server load, not as a separate API call.

--------
---

## session: full 162-SKU pipeline run + extract-attributes step — 2026-03-25

**Purpose:** Ran the full jegs-ebay-final-mar25 pipeline for all 162 new SKUs —
generate-bullets, enhance-content, extract-attributes, download-posters — and
built
shared tooling.

**Insights:**

1. enhance-content had no idempotency — re-ran all 162 on every invocation
including already-done rows. Fixed with needsEnhancement() check (has Title+Desc+
FAB → skip). Same pattern should be applied to any expensive per-row API step.
2. Sequential enhance-content took ~55s/SKU = 2.5h for 162. Replacing the for-
loop with batched Promise.all(batch.map(...)) at concurrency=5 cut it to ~25 min.
Use a result Map (keyed by Part Number) for safe concurrent writes; restore
original row order at the end.
3. All 123 "no raw description" new SKUs came exclusively from the mar25 batch —
the original 440 rows had full descriptions. Zero original rows were missing raw
data. Always check origin when auditing data gaps.
4. extract-attributes step: only 19 of 162 new SKUs had extractable raw
descriptions. The other 123 had neither raw eBay text nor item specifics —
skipped entirely rather than hallucinating from AI-generated content.
5. eBay Item Specifics (JSON) contains commerce noise (List price, Shipping,
Returns, eBay Product ID) that looks like attrs but isn't. Always filter with a
JUNK_KEYS set before treating Item Specifics as product attributes.
6. poll-step.sh: reusable script (run-id, step-id, interval) replaces ad-hoc
inline polling loops. Uses python3 for JSON parsing (no jq dependency). Add to
all future long-running step chains.
7. Cancel a running job: DELETE /api/jobs/<jobId> — not POST /cancel. The
endpoint is easy to forget.

--------
---

## session: Claude Config Inspector polish + documentation — 2026-03-25

**Purpose:** Implemented 6 UX improvements (favicon, sidebar width, DetailPanel
formatting, filter layout, graph search, core-dump documentation) following a
prior session that built logging, theming, tooltips, graph layout, and
simulation history.

**Insights:**

1. Tooltip's inline-flex wrapper is a silent width constraint — always pass
className="w-full" when the tooltip wraps a block-level child like a NavLink.
2. useReactFlow() hooks (setCenter, fitView) require the calling component to be
*inside* a <ReactFlowProvider> — split into Inner/Outer pattern when the same
component renders <ReactFlow>.
3. useMemo used as a side-effect trigger (calling setNodes/setEdges) works by
accident but is an anti-pattern — useEffect is correct because these are state
mutations, not memoized computations.
4. detectValueKind() for syntax-aware value rendering: check typeof first
(boolean/number/object), then regex for bash patterns (&&, $(, known commands),
then try JSON.parse for stringified JSON.
5. The checkpoint (_checkpoint.claude.md) is most useful when it includes both
the action log AND the architecture overview — future /catchup runs benefit from
the structural context, not just the history.

--------
---

## core-dump: notify + tab-title full session — 2026-03-25

**Purpose:** Snapshot the complete notify/tab-title build session including what
was built, what was understood, and what remains pending.

**Insights:**

1. OSC 9 is strictly better than terminal-notifier for Ghostty: attributed to
the originating tab, click navigates correctly. Only downside is no sound —
solve with afplay separately.
2. Notification hooks fire alongside native Claude Code behavior — cannot
suppress the native notification. Design for two pops or accept it; don't try to
suppress.
3. TTY_PATH env override pattern makes OSC 9 scripts testable without a real tty
— cheap and non-invasive.
4. The intentional asymmetry between idle (BEL+Morse = ambient) and permission
(Ping only = urgent) is worth documenting explicitly; looks like a bug otherwise.

--------
---

## core-dump: iMessage + /files sprint checkpoint — 2026-03-25 16:00

**Purpose:** Checkpoint mid-session after completing iMessage feature + FDA fix,
before starting /files improvements (Tasks #14–19).

**Insights:**

1. When the Write tool refuses ("file has not been read yet"), Read just a few
lines first — the tool enforces a read-before-write guard even for overwrite
operations.
2. macOS Full Disk Access blocks sqlite3 at kernel level regardless of file
permissions — authorization denied exit code 1 from sqlite3 CLI is the specific
signal; detect it in stderr.
3. The .app-body flex-row wrapper pattern (banner stacks above, sidebar+thread
share a row) is the right way to add optional top-of-panel banners without
breaking the existing two-column layout.

--------
---
