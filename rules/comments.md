# Comments

**The one rule:** Comments are for humans first, AI agents second,
machines never. Code is read by humans first, AI agents second, and
machines just care about correctness — they don't care about the
prose at all. Every comment-style decision follows from this.

## What this means in practice

1. **First sentence of every non-trivial module/function docstring
   is code-agnostic** — explains what the thing IS at the system
   level. A non-engineer should roughly understand it. Mechanism
   comes after.

2. **Speak from the human perspective**, not the machine's.
   - Bad: "Sets `_draining=True` so the main loop breaks before
     claiming new work."
   - Good: "Ask the worker to stop. Safe to call from a signal
     handler — the actual shutdown work happens in `drain()`."

3. **Plan-reference noise rots — strip it.** The following ALWAYS
   become obsolete the moment the work ships and confuse later
   readers:
   - `Tier 1 v1 Track H`, `Phase 2.B8`, `Round 3 #N.M` plan refs
   - `Pre-fix: ...` / `Post-fix: ...` / "this used to be X" history
   - TODO markers for work that has already shipped
   - "See PR #1234" / "as discussed on YYYY-MM-DD"

   Historical context belongs in commit messages, PR descriptions, or
   design docs — never in source.

4. **`[claude@<ts>]` tags are allowed BUT MUST BE SEPARATE from
   human-readable comments.** Two distinct comment audiences in
   source:
   - **Human comments** — doc-style WHY/WHAT/HOW/WHERE, long-term
     relevant. NEVER carry `[claude@]` tags or plan references.
   - **Agent-note comments** — agent-specific technical detail
     needed for future Claude work (load-bearing for a plan or
     ongoing refactor). Marked with `[claude@<ts>]`, kept as a
     SEPARATE block from any human comment, dense / technical.

   Don't mix them. A human comment with a claude-tag suffix or
   embedded planning narrative is the failure mode this rule
   exists to prevent.

   **Pattern when both are needed:**

   ```python
   # The breaker bucket is resolved at call time so per-customer
   # scoping works without re-decorating. Bucket = module in global
   # mode; module:team_id in per-customer mode.

   # [claude@2026-05-11] When the consensus PR lands, audit ALL
   # callsites for the resolve_bucket pattern — anywhere still
   # caching breaker instance at decoration time will skip per-customer.
   def resilient(name: str, ...):
       ...
   ```

4. **Docstrings >8 lines are essays** — break out to a doc and link.
   Per-field comments stay one line each.

5. **Inline comments explain WHY, not WHAT.** Self-documenting code
   makes most WHAT-comments redundant. Use inline comments for
   non-obvious constraints, workarounds, deliberate surprises.

6. **Stale comments are worse than missing ones.** After modifying
   code, scan nearby comments and delete or update — TODOs that
   shipped, "currently X" claims when X changed, references to
   deleted symbols. When in doubt: delete.

7. **Major entrypoints get a 2–3 sentence orientation** ("the worker
   process entrypoint" / "the request handler for X") so a reader
   landing there knows where they are without reading the whole file.

## The structure for a non-trivial docstring

Three paragraphs, in order, skip any you don't need:

1. **Code-agnostic purpose** — what this does in the system, no
   jargon, no code refs.
2. **Runtime contract** — inputs, outputs, side effects.
3. **Technical caveats** — race conditions, gotchas, why-not-the-
   obvious-thing. Can be dense.

A simple helper gets para 1 alone. Most things need para 1 + 2.
Para 3 is rare and load-bearing when present.

## When in doubt, link

If the same context appears in ≥3 places, write it ONCE in a doc and
link from the code. Copy-pasted context creates drift.

## Project-specific elaborations

Repos in this account have a longer rubric with worked before/after
examples — read it when a project's CLAUDE.md links to it. The local
doc supersedes anything here that conflicts; defer to it.

For Versable enhancement-product specifically:
`frontend/docs/boring-technical-stuff/comment-style.md`.
