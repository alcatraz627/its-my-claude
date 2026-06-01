---
brief: Generalized env-access hook — establish a project's env-access convention once (ask the user, cache it), then nudge every later access to follow it
triggers:
  - tool:guard-env-access
  - topic:env-access
  - phrase:"process.env"
  - phrase:"os.getenv"
related:
  - rules/env-var-config-pattern.md
  - scripts/hooks/warn-raw-process-env.sh
tier: 2
category: features
updated: 2026-06-01
stale_after_days: 365
---

# Env-access convention hook (DESIGN — not built)

> Generalizes `warn-raw-process-env.sh` into a **run-once-and-cache-meta-code**
> pattern: the first time any session touches env vars in a project, establish
> *how this project does env access* (ask the user, persist the answer), then
> every later access is nudged to follow that one cached convention.
>
> **Status:** designed 2026-06-01, **not built.** Replaces a live wired hook —
> build deliberately, not at the tail of a long session. From the Phase-1
> hook-graduation work (atone `adding-env-var-reads-without-checking-config`, S3,
> worsening despite the narrow existing hook).

## Why the current hook fails (diagnosed)

`warn-raw-process-env.sh` is wired but the pattern keeps worsening because it is:
1. **Advisory only** (`always exits 0`) — the nudge is ignorable.
2. **TS/TSX only** — every Python `os.getenv`/`os.environ` slips through.
3. **A narrow allowlist** — matches only `process.env.(NODE_ENV|NEXT_*|VERCEL_*)`.

The reflect S3 pattern is broader: *any* language, *any* env var, the real
defect being "didn't route through the project's established config pattern."

## The design — establish-once, cache, enforce

```
  agent writes env access ──► hook (PreToolUse Edit/Write/MultiEdit)
                                │
              detect env access broadly (all langs, below)
                                │
                 ┌──────────────┴───────────────┐
        convention file exists?            does not exist?
                 │                                │
        access via the cached            NUDGE: "this project has no env-access
        accessor?  ─ yes ─► silent       convention yet. Ask the user how env
                 │ no                     vars should be accessed here (central
                 ▼                        config module? validated schema?
        nudge: "route through            direct?), then record it in
        <project>/.claude/conventions/   <project>/.claude/conventions/
        env-access.md's accessor,        env-access.md and create the accessor
        don't add a raw read"            once. Route all reads through it."
```

The **cached meta-code** is the convention file + a single accessor module the
agent creates *once* (prompted by the hook) from the user's answer. The hook
never writes code — it bootstraps the "establish once" step and then enforces
"use the established accessor," so the decision is made one time per project and
reused every time after.

## Broad detection (all languages)

```
process\.env | import\.meta\.env | Deno\.env\.get | os\.getenv | os\.environ
| ENV\[ | System\.getenv | getenv\( | \$_ENV\[ | std::env::var
```
Skip: the convention/accessor file itself, `.env*` boundary files, test files.

## Project-root + convention resolution

Walk up from `file_path` to the nearest `.git`/`.claude` dir = project root.
Convention lives at `<root>/.claude/conventions/env-access.md`. Absent → the
"establish once" nudge; present → the "follow the accessor" nudge.

## Open decisions (resolve at build time)

- **Advisory vs block?** The current advisory is ignored → escalate. Likely:
  advisory when *establishing* (asking the user can't be forced mid-write), but
  a louder/blocking nudge for raw reads *after* a convention exists (the agent
  has no excuse then). User leaned toward block for env in the Phase-1 convo.
- **Replace vs sit alongside `warn-raw-process-env.sh`?** Replace — it's a strict
  subset. Retire the old one in the same change (don't leave two env hooks).
- **Convention file schema** — freeform markdown the agent reads, or a structured
  header the hook can parse to verify the accessor name? Start freeform; the hook
  only checks *existence* + nudges, doesn't parse.

## This is one of a family — "process-adherence" hooks

`sub-agent-output` (built) and a future **WAL-adherence** hook are the same shape:
*"the agent should have followed a documented process; nudge at the trigger
point if it didn't."* They differ only in trigger (Edit content / Agent dispatch
/ session activity) and the doc they enforce. Phase 3's template should name this
family so they share structure (detect → check-state → nudge-with-the-rule-link
→ mute hatch), even though each is a distinct hook.
