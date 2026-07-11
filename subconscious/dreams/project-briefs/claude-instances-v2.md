<!-- i-dream project brief · 2026-07-11T18:53:06.201048+00:00 · 2 patterns / 0 insights -->
## What this project is about
A multi-instance Claude orchestration/management layer. Work style is tool-heavy and configuration-driven, with attention to precise semantics in how Claude instances are configured and run.

## Things to do (or keep doing)
- Sequence all Edit calls to the same file; never batch parallel edits targeting the same path — both return success but only one survives
- Clarify "runtime variables" before acting: ask whether the user means deploy-time env vars or on-the-fly application globals; these diverge in implementation

## Things to avoid
- Don't assume parallel Edit calls are safe to batch — they silently clobber each other with no error signal
- Don't implement a config/variable feature without first confirming the semantics (env var vs. runtime-mutable global); the wrong interpretation requires a full rewrite

## Open questions / known gaps
- Signal volume is low (2 patterns, 1× each) — treat this brief as provisional; surface new patterns to memory as the session progresses
