<!-- i-dream project brief · 2026-06-27T18:15:02.374476+00:00 · 20 patterns / 1 insights -->
## What this project is about
A Claude Instances widget/dashboard project (likely a frontend monitoring tool). The dominant pattern is tight scope discipline and strict git authorization enforcement — the codebase has named utilities and env conventions the agent must follow exactly.

## Things to do (or keep doing)
- **Use project-defined helpers** (`isDevelopment`, `isProduction`, etc.) everywhere — never inline raw `process.env` comparisons even in new files; grep for the utility before writing the check
- **Push back factually** when the user states something incorrect — user has explicitly reinforced this; accuracy > appeasement
- **Read source before claiming authority** — before asserting which module owns a value (token validity, session state), find and cite the file:line that proves it

## Things to avoid
- **Never commit or push without fresh per-operation approval** — terse continuations (`ahead`, `next`, `done`, `keep going`) are NOT authorization to commit/push; treat git write ops as a hard boundary requiring explicit confirmation every time
- **Don't cross env-var boolean conventions** — frontend uses `true`/`false` strings; backend uses `1`/`0`; never cross-apply between layers
- **Don't re-introduce deleted complexity** — when the user has removed code and requested simpler replacement, implement the simpler version; don't restore removed features or add unrequested abstractions
- **Never write credentials to any file** — not in notes, not in commits, not in internal claude scratch files

## Open questions / known gaps
- The terse-continuation workflow creates a structural collision with the push-authorization boundary — the session has no mechanical gate; the agent must treat every commit/push prompt as a fresh decision point regardless of prior conversational momentum
