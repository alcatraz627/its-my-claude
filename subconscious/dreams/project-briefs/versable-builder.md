<!-- i-dream project brief · 2026-08-19T19:55:08.889453+00:00 · 20 patterns / 10 insights -->
## What this project is about
A full-stack product builder (versable-builder) with heavy UI work across multiple pages, design-mock-driven development, and frequent multi-agent/parallel execution patterns.

## Things to do (or keep doing)
- Consult design mocks before writing any UI labels, page names, or creation flows — never derive from code conventions alone
- Audit ALL pages using a shared component (sidebar, drawer, modal) before touching any one instance; implement consistently in a single pass
- Verify from the consumer's perspective: exercise the fix in the running dev server, not by reading the code change
- After any parallel burst (sub-agent completions, concurrent edits), re-sync task lists and git state before continuing — treat all cached state as stale

## Things to avoid
- Don't claim a UI or bug fix is done without rendering and visually inspecting the affected surface in a browser; copy changes and element-level fixes both require full visual confirmation
- Don't regenerate AI-smell prose tells (em-dashes, excessive bold spans) after a stop-hook flags them — treat the hook firing as a class fix, grep for siblings, then rewrite clean
- Don't treat agent-generated documents (formalizations, naming conventions) as authoritative sources; verify provenance before citing anything as canonical
- Don't post to GitHub or any shared surface under the user's account without an explicit agent-attribution marker in the message body

## Open questions / known gaps
- Parallel sub-agent work consistently degrades bookkeeping (task drift, stale branch state, ownership ambiguity) — no structural solution is in place yet; high-velocity sessions require manual sync discipline
- Context-capacity assessment is unreliable without a hook firing; agent repeatedly mis-estimates fullness mid-session
