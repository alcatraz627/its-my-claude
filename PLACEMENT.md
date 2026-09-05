# PLACEMENT.md — Where Does New Config Go?

> **Read this before adding any rule, feature doc, or convention to `~/.claude/`.**
> This rule is the anchor. CLAUDE.md length will rot without it.

<!-- sessions: impr-cfg-7a@2026-04-24 -->

## The problem this solves

Frontier LLMs reliably follow ~150–200 instructions. Claude Code burns ~50 on its own system prompt. A CLAUDE.md past ~200 lines degrades adherence — rules in the tail get quietly ignored, not merely loaded at token cost. This rule keeps always-loaded content in the zone the model can actually follow.

**Adherence, not token cost, is the forcing function.** Prompt caching makes bloat cheap, but uncached OR not, a 600-line instruction set produces measurably worse rule-following than a 200-line one.

---

## First: which MECHANISM? (situation → extension)

Before the two-axis rule (which decides *where a doc goes*), decide *what kind of
thing to build at all*. Each mechanism has a recognizable trigger moment — build it
when the moment arrives, not preemptively. (Adapted from Anthropic's official
"build your setup over time" guidance; the enforcement column is this account's
own doctrine.)

| The moment you notice… | Build a… | Because |
|---|---|---|
| Claude got a convention wrong **twice** | CLAUDE.md line / `rules/` entry | Prose is advisory — fine for a preference, but only ~70% adhered |
| A rule **must hold every time, zero exceptions** | **hook** (PreToolUse/Stop) | Hooks are deterministic; prose is a request, a hook is a guarantee ([[features/hook-design.md]]) |
| You typed the same multi-step prompt a **third** time | user-invocable **skill** | Captures the playbook; loads on demand, near-zero always-on cost |
| A side task floods the conversation with output | **sub-agent** | Isolated context; returns a distilled summary ([[rules/sub-agent-outputs.md]]) |
| You keep copying data from a browser tab / external system | **MCP server** | A tool beats manual paste; deferred-loaded so cheap |
| A second repo needs the same setup | **plugin** | Portable across repos |

Key line: **if it must hold every time, make it a hook, not a prompt instruction.**
A rule in prose that silently gets skipped 30% of the time is the exact failure the
hook layer exists to close ([[rules/skill-spec-update-not-honored-by-running-session.md]]).
Only once you've chosen "a rule/feature/convention doc" do the two axes below apply.

## The two-axis rule

Every piece of config answers BOTH axes.

### Axis 1 — Category (what is it?)

| Category | Holds | Example |
|---|---|---|
| `rules/` | Behavioral/process rules — **what Claude MUST do** | `rules/testing.md`, `rules/git.md` |
| `features/` | Tool/subsystem/integration docs — **how a thing works** | `features/llm-mini.md`, `features/claudew.md` |
| `conventions/` | Output/authoring standards — **how artifacts look** | `conventions/html-output.md`, `conventions/cli-help-design.md` |
| *(root)* | Indices + session-critical state + memory | `LOOKUP.md`, `mistake-patterns.md` (DERIVED, see `features/atone.md`), `compliments.md` (DERIVED), `memory/global/` |

Sub-categorization uses naming only (no deeper directories). E.g. `conventions/html-*` groups all HTML rules.

### Axis 2 — Tier (how often does it apply?)

| Tier | Activation condition | Placement |
|---|---|---|
| **0** | Every session, OR silent-failure catastrophic if missed | **Full content inline** in CLAUDE.md §Always-load core |
| **1** | Most sessions, but detail is long | **One-paragraph summary inline** + pointer to sub-file |
| **2** | Specific domain/tool/task type | **Pointer line with triggers** in CLAUDE.md §On-demand pointers |
| **3** | Rare, reference-only | **LOOKUP.md only**, no CLAUDE.md mention |

### Loading reality: `tier:` does not control loading for `rules/`

The tier column above describes intent, not mechanism. Claude Code natively
auto-loads every file under `~/.claude/rules/*.md` (and project `.claude/rules/`)
in full at session start, regardless of `tier:`. A rule marked Tier 2 still loads
every session. `tier:` and `triggers:` are advisory metadata: they guide agent
self-selection and how large a CLAUDE.md brief to write, and do not gate loading.

The platform's actual lazy-load lever is a `paths:` frontmatter field. A rule with
`paths:` globs loads only when Claude touches a matching file; a rule without it
loads unconditionally. Use `paths:` to scope project- or language-specific rules so
they stop paying always-on budget.

`features/` and `conventions/` are genuinely on-demand (the loader never pulls them
until an agent opens the file), so the tier model works as intended there; the
special case is `rules/`. Measured cost and the full picture live in
`assets/reports/20260905-gcc-structure-map/MAP.md` (v4, 2026-09-05; v3 of 2026-07-04 sits beside it as the baseline it diffs against).

### Decision heuristics

1. **80%-skip test:** if an agent would skip reading this in 80%+ of sessions → Tier 2 or lower
2. **Silent-failure bump:** if the failure mode is silent (wrong behavior, no error) → bump up one tier
3. **15-line rule:** content >15 lines MUST have a sub-file, regardless of tier (tier determines the inline summary size)
4. **3-line rule:** content <3 lines stays inline regardless of category
5. **Deduplication:** if a dedicated file already exists under `shared/*.md` or `features/*.md`, CLAUDE.md MUST link, not restate

---

## Sub-file frontmatter (mandatory)

Every file under `rules/`, `features/`, `conventions/` opens with this YAML block:

```yaml
---
brief: One-line semantic summary (< 120 chars). PRIMARY selection signal.
triggers:
  - tool:<name>                 # literal tool/CLI/binary name
  - topic:<slug>                # task domain: github-repos, docs-work, macos-windows, html-output
  - phrase:"<exact string>"     # exact phrase match
  - skill:<name>                # Claude skill invocation
  - mcp:<name>                  # MCP server name
paths:                          # OPTIONAL, rules/ only: the native lazy-load lever.
  - "src/**/*.ts"               #   rule loads ONLY when Claude opens a match;
  - "**/*.test.*"               #   omit paths: entirely to load every session.
related: [path/to/other.md]
tier: 0|1|2|3
category: rules|features|conventions
updated: YYYY-MM-DD
stale_after_days: 90
---
```

### Trigger taxonomy (prefix-namespaced)

| Prefix | Meaning | Example |
|---|---|---|
| `tool:` | Literal tool/binary/CLI name | `tool:claudew`, `tool:fiber-snatcher` |
| `topic:` | Task domain or category | `topic:github-repos`, `topic:docs-work`, `topic:macos-windows`, `topic:html-output` |
| `phrase:` | Exact user-prompt phrase | `phrase:"auto-checkpoint"`, `phrase:"session start"` |
| `skill:` | Claude skill name | `skill:create-skill`, `skill:doctor` |
| `mcp:` | MCP server name | `mcp:mongodb`, `mcp:vercel` |

Triggers are **advisory** — they guide agent self-selection when scanning LOOKUP.md + CLAUDE.md pointers at session start. No hook auto-loads files *based on triggers* today (the `rules/` directory auto-load is a separate native mechanism; see "Loading reality" above); triggers document intent so an upgrade path exists.

**Rule:** `brief` must be sufficient on its own for the agent to decide "load or skip." `triggers` are secondary hints for literal/domain matching.

### Staleness

- `stale_after_days: 90` default
- `/doctor` flags sub-files where `updated + stale_after_days < today`
- A stale flag is a review prompt, not an auto-delete — content may be stable

---

## How to decide where new content goes — flowchart

```
┌─────────────────────────────────────────────────────────────────────┐
│ New rule/feature/convention to add                                  │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
              ┌────────────────▼────────────────┐
              │ Does a sub-file already exist   │
              │ for this topic?                 │
              └────┬───────────────────────┬────┘
                 YES                       NO
                   │                       │
                   ▼                       ▼
       Append to existing sub-file   ┌──────────────────────┐
       Update `updated:`             │ Is it <3 lines?      │
       Add trigger if new axis       └──┬────────────────┬──┘
                                      YES              NO
                                       │                │
                                       ▼                ▼
                               Inline in CLAUDE.md  ┌───────────────┐
                               (pick tier)          │ Apply in 80%+ │
                                                    │ sessions?     │
                                                    └─┬───────────┬─┘
                                                     YES         NO
                                                      │           │
                                                      ▼           ▼
                                               Tier 0 or 1    Tier 2
                                               (inline+stub   (stub + pointer)
                                                or summary+
                                                stub)
```

---

## Anti-patterns (grep-checkable)

**Never do these when adding to ~/.claude/:**

1. **Duplicate content already in `shared/*.md` or a sub-file.** CLAUDE.md links; it does not restate. Example violation: the pre-2026-04-24 CLAUDE.md §Desktop Automation duplicated `shared/desktop-automation.md`.

2. **Store dated or fast-changing facts in Tier 0.** ("8 plugins disabled on 2026-03-27" is a stale magnet.) Dated facts go in a registry file (e.g. `disabled-plugins.json`) that CLAUDE.md links to.

3. **Put MANDATORY rules in Tier 2.** If it's MANDATORY, it's Tier 0 or Tier 1. Burying a MANDATORY rule behind a pointer guarantees it gets missed.

4. **Use un-namespaced triggers.** `triggers: [claudew, github]` is illegal. Must be `tool:claudew`, `topic:github-repos`.

5. **Create sub-categories as nested directories.** No `features/mcp/catalog.md` — use `features/mcp-catalog.md`. The tree stays flat for `grep`-ability.

6. **Copy rules across sub-files.** If two sub-files need the same rule, it lives in `rules/*.md` and both use `related:` to link.

7. **Omit frontmatter.** A sub-file without frontmatter is invisible to `validate-triggers.sh` and can't be selected systematically.

---

## For future agents working on this config

- **Every addition** follows the flowchart above
- **Every sub-file** carries full frontmatter (no exceptions)
- **CLAUDE.md never exceeds 200 lines** — if an edit would push past, something else must move out first
- **Validator:** run `bash ~/.claude/scripts/validate-triggers.sh` after any sub-file add/rename
- **Rules index:** after adding/renaming/removing a `rules/*.md` file, regenerate the always-on menu with `bash ~/.claude/scripts/rules-index.sh` (it derives from each rule's `brief:`; if a similar rule exists, refine it instead of duplicating)
- **Folders census:** after creating, renaming, or removing a top-level directory under `~/.claude/`, regenerate the census with `bash ~/.claude/scripts/folders-index.sh` AND add the directory's Intent row to the hand-written table above the marker in `FOLDERS.md`. The census went 51 days without a run once (2026-07-16 to 2026-09-05) and its own heuristic then condemned fourteen live directories as debris. Note the script takes no `-h`: any argument other than `--stdout` regenerates in place
- **When in doubt:** read this file, read LOOKUP.md, pick the most conservative tier, ask the user
- **Prior art:** Anthropic Agent Skills (description-based triggering), Cline `.clinerules/` directory. [web reference: `~/.claude/assets/research/20260424-agent-instructions-best-practices.md`]
