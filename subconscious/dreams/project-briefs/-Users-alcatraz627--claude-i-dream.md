<!-- i-dream project brief · 2026-07-13T00:45:42.626513+00:00 · 20 patterns / 0 insights -->
## What this project is about
Dream-tracking dashboard and developer tooling project (`i-dream`), mixing web UI work with shell/agent tool authoring. Working style is iterative and verification-heavy — the user catches shallow "done" claims hard.

## Things to do (or keep doing)
- **Verify runtime before claiming working**: navigate to the actual URL and exercise the primary flow; `lsof` the port; don't report success off a compile or collect.
- **Check git log before implementing**: scan recent commits for version decisions and already-landed mechanisms before reinventing them.
- **Read existing scripts before writing new ones**: prior design decisions and removal history directly constrain what to build.
- **Sequence edits to the same file**: parallel Edit calls silently clobber each other — only one survives despite both returning success.

## Things to avoid
- **Don't auto-apply on selection in picker UIs**: selection must preview; an explicit save/apply action is required to commit state changes.
- **Don't put a file path immediately before a sentence-ending period**: Ghostty auto-links paths and swallows the trailing dot, breaking the link — follow every path with a space, word, or comma.
- **Don't fabricate content in stub docs**: write only the goal statement and `TODO(human)` placeholders — never fill sections structurally.
- **Don't suggest version changes without checking git history**: a recent deliberate revert is a hard veto.

## Open questions / known gaps
- "Runtime variables" is ambiguous here — always clarify whether the user means deploy-time env vars or on-the-fly app globals before proceeding.
- UI reskins need end-to-end UX validation (scroll, backgrounds, responsive, nav flow) — mechanical style application alone is not releasable.
