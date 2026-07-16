---
brief: Dispatch prompts for material sub-agent work (research/analysis/audit/design) MUST pin an absolute output path AND how it gets persisted — either the sub-agent writes before returning (write-capable agent types only; never a file literally named report.md, the harness blocks it), or the sub-agent returns full text and the PARENT writes it. Parent MUST verify the file exists before using the findings — the return abstract is a pointer, not the artifact. Mechanically enforced by the subagent-output guard hook; Read this rule when designing multi-agent output flows or when the guard fires.
triggers:
  - tool:Agent
  - phrase:dispatch sub-agent
  - phrase:research agent
  - phrase:opus sub-agent
  - phrase:parallel agents
related:
  - features/context-retention.md
  - features/wal.md
paths:
  # autoload opt-out (2026-07-09 demotion pass): only fires when dispatching material
  # sub-agent work, and the directive already lives in CLAUDE.md's Tier-0 brief plus
  # the PreToolUse guard hook that blocks persistence-free material dispatches. This
  # file is the depth (incident history, path schemes, sub-agent-side contract) —
  # Read it on demand from rules/00-index.md. Sentinel never matches a real file;
  # revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-07-11
stale_after_days: 365
---

# Sub-Agent Outputs Must Be Persisted

When the parent agent dispatches a sub-agent (`Agent` tool, any `subagent_type`)
that produces **material content** — research synthesis, analysis report, audit
findings, design proposal, code-walkthrough, plan with sections, anything the
parent would later cite by section number — the sub-agent's output **must be
written to a file on disk before it returns**, and the parent **must verify the
file exists** before relying on it for subsequent rounds.

The sub-agent's return summary is a **pointer + abstract**, not the artifact.
Treat the abstract as ephemeral. Treat the file as the source of truth.

## Why this rule exists

On 2026-05-06, in the Versable worker-overhaul session, three Opus research
agents produced a consolidated 3-agent synthesis with numbered sections (1–10).
Only the **abstract** of the synthesis came back into the parent's context. The
abstract was load-bearing for the user's feedback file — which referenced
"Section 7", "Section 8", "Section 9" by number. The parent then `/core-dump`ed
and the user `/clear`ed.

After `/clear`, the parent (this session) had:
- ✅ The user's feedback file referring to numbered sections
- ✅ A meta-plan that said "Section 7 per-item deliberation (12 structural changes)"
- ❌ The actual contents of those sections — gone with the conversation

The "12 structural changes" became a **phantom artifact** — load-bearing in the
plan, irrecoverable from disk. Round 2 of the overhaul started by reconstructing
the list from the user's feedback (n=18 candidate items, conservatively a
superset). That reconstruction is now the de-facto canonical list, not because
it's correct, but because it's all that survives.

The ~30 seconds of writing the synthesis to a file would have prevented
this entirely.

## What "material content" means

A sub-agent's output is material if **any** of these are true:
- It will be cited by section/heading later
- It contains structured findings the parent will reflow into a plan/doc
- The user will read it directly (a report, a write-up, a deliverable)
- Subsequent rounds depend on it for grounding
- It took >5 minutes of agent work to produce

NOT material:
- A "find me the file path of X" lookup
- A "is X true?" yes/no verification
- A grep result that the parent immediately consumes and forgets

When in doubt, write it.

## How to apply (for the PARENT agent)

### Pre-dispatch gate (30 seconds, before writing the Agent prompt)

1. Is the output material? (will be cited later, user-facing, or took >5 min
   to produce)
   - YES → assign an absolute output path now, before writing the dispatch prompt
   - NO → proceed without the path requirement
2. Pick the persistence mode, gated on the agent type:
   - **Write-capable agent** (general-purpose, claude, custom types with Write):
     instruct "write your full output to `<path>` BEFORE returning".
   - **Read-only agent** (Explore, Plan — no Write tool): the sub-agent CANNOT
     persist. Instruct "return your FULL findings as text; I will persist them
     to `<path>`" — then the parent writes the file itself. Do not tell a
     read-only agent to write; it fails after the substantive work is done.
3. Have you written the path and the chosen persistence instruction into the
   Agent prompt? If no — stop and add them.
4. Have you added `test -f <path> && wc -l <path>` as a verification step after
   the dispatch (it runs after PARENT-persist too)? If no — add it.
5. Is the output a REPORT (findings, audit, RCA, analysis for a reader)? Then
   the dispatch prompt also carries one line: "Follow
   `~/.claude/conventions/report-writing.md`: per finding symptom → impact →
   path → detail; caveats carry verbatim." Reports inherit the genre contract
   at birth, not at review time.

Do not write the dispatch prompt until all five pass.

When dispatching a sub-agent that will produce material content, the dispatch
prompt **must include**:

1. **A specific output path** — absolute path. The parent picks the location;
   the sub-agent does not invent one. Default scheme:
   - **Project-local research/audits:**
     `<project_root>/.claude/output/<YYYYMMDD>-<HHMM>-<slug>/<agent>.md`
   - **User-facing artifacts (will graduate to docs):**
     directly under the relevant `docs/` subdir, with a sensible filename
   - **Global (cross-project) findings:**
     `~/.claude/assets/reports/<YYYYMMDD>-<slug>/<agent>.md`

   **Filename trap:** never name the file literally `report.md`. The Claude
   Code harness blocks a sub-agent writing that exact name ("Subagents should
   return findings as text") and the work comes back as a giant inline return.
   Use a descriptive `<slug>.md` / `<agent>.md` (confirmed 2026-07-04/05, ~5
   blocked dispatches).
2. **The persistence instruction** (mode chosen in the pre-dispatch gate):
   - Write-capable agent: "Before returning, write your full output to
     `<path>`. Your return summary should be a 5-bullet abstract + the
     absolute path."
   - Read-only agent (Explore/Plan): "Return your FULL findings as text —
     do not truncate; I will persist them to `<path>`." The parent then
     writes the file before using the findings.
3. **A verification step after the sub-agent returns:** parent runs
   `test -f <path> && wc -l <path>` (or equivalent Read) before using the
   sub-agent's findings — in BOTH modes.

If multiple sub-agents run in parallel, give each a **distinct path** under the
same dated folder so their outputs are colocated and easy to consolidate.

After all sub-agents finish, the parent **links the output files into the
relevant context document** — the running checkpoint, plan, runtime-notes, or
the index doc for the effort. Unlinked files become orphan artifacts.

## How to apply (for the SUB-AGENT)

If you are a sub-agent producing material content and the parent did NOT give
you an output path, **ask for one** before doing the substantive work, OR
default to writing under `<project_root>/.claude/output/<YYYYMMDD>-<HHMM>-<slug>/`
and tell the parent the path you chose. Do not produce material content that
exists only in your return string.

If the harness **refuses your file write** (or you have no Write tool):
return your FULL content — not just the abstract — and open the return with
`WRITE-BLOCKED: <intended path>` so the parent knows to persist it verbatim.
A refused write plus an abstract-only return loses the artifact twice.

Your return summary structure:

```
WROTE: <absolute_path> (<line_count> lines)
ABSTRACT:
- <5–8 bullets summarizing key findings>
KEY POINTERS:
- <heading>: <line_or_section_anchor>
```

This shape lets the parent decide whether to read the file in full, scan
specific sections, or treat the abstract as sufficient for the next round.

## What to do when this rule was violated in a prior session

If you discover, mid-task, that prior-session sub-agent output is missing from
disk and the abstract was the only artifact:

1. **Don't pretend the data is recoverable.** Tell the user transparently —
   the abstract is what we have; the source is gone.
2. **Reconstruct from secondary sources** if possible (user feedback files
   that reference the missing artifact often paraphrase its contents).
3. **Label the reconstruction explicitly** ("provisional, n=18 reconstructed
   from feedback file") rather than presenting it as canonical.
4. **Append a note to mistake-patterns.md** with the date and incident, so
   the gap is documented even if no file is recoverable.

## Render-check your own output before declaring done

The "I wrote it" claim is not the same as "I verified it renders." After
writing any file that downstream consumers (humans, other agents, parsers)
will read as **source** — `.md`, `.html`, `.json`, `.yaml`, `.toml`, RCAs,
reports — run a quick render-check before considering the task done:

| File kind | 10-second check |
|-----------|-----------------|
| Markdown  | `glow file.md` OR `bat -l md file.md` OR scan first 20 lines |
| JSON      | `jq . file.json` (parses + reformats; failure = invalid) |
| YAML      | `python3 -c "import yaml; yaml.safe_load(open('file').read())"` |
| HTML      | `open file.html` in a browser, or `tidy -e file.html` |
| Markdown frontmatter | Confirm first line is `---`, closing `---` within first 30 lines |

The check catches: missing frontmatter, broken H1 (wrapped headings),
gum/TTY-render-saved-as-source (every line indented 2 spaces, `…` in tables,
truncated column headers), invalid JSON, malformed YAML.

This is the same principle as `render-before-judge` from the mistake-patterns
log applied to the agent's own output — not just to user-flagged values.
Added 2026-05-16 after the `mist-20260516-001122-82` incident where an RCA
file was written but never render-checked; the file turned out to be
gum-rendered ASCII saved as source markdown.

## Related

- Mistake pattern: `Sub-agent material output left in conversation only`
  (mistake-patterns.md)
- Context-retention layers: `features/context-retention.md` — WAL = what
  happened, runtime-notes = what was learned, scratchpad = what was thought.
  Sub-agent outputs slot into the **scratchpad** layer if they're working
  notes, or graduate to **published artifact** if user-facing. Either way:
  on disk, not in conversation.
