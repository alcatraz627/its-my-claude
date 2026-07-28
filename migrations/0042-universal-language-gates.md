# 0042: language gates extended to code-file copy and PR bodies

## Summary

Two gate extensions plus the coverage map, closing the owner's "needed
everywhere" directive. First, `~/.claude/scripts/style/code-copy-lint.py`
extracts prose-reading string literals from code files (ts tsx js jsx vue
svelte py) and judges them with prose-lint's own regexes; guard-prose-quality
routes code files through it and blocks connective dashes, unverified-claim
futures, and jargon in user-facing copy. Placeholder glyphs, classNames,
URLs, comments, and test/fixture files are out of scope by construction.
Second, guard-commit-signature now also scopes `gh pr
create/edit/comment/review/merge`: a PR body with a signature footer or a
connective em-dash is blocked. The full surface-to-gate map now lives in
conventions/language-quality.md.

## Why

The banner incident (atone ai-smell-prose-against-stored-voice, 2026-07-28)
shipped through a .tsx string literal, a surface migration 0041 deliberately
excluded. The repo census then found two more live copy violations plus the
false-positive classes (glyph spans, comment dashes) that a naive gate would
have tripped on. The owner's ruling: smaller-scale language guards on every
surface, with gaps explicit.

## Behavior notes

- Ground-truth battery on real speedway files: exactly the two known copy
  violations flagged (accounts.tsx:348, modules.tsx:202), fixed job.tsx
  clean, glyphs and comments silent. Two false-negative bugs were caught and
  fixed during the battery: a three-word prose heuristic that missed
  short-word copy, and a token-soup exclusion that swallowed pure-word
  jargon strings.
- The guards blocked their own test batteries twice (fixture literals in the
  command text), which is the registration working; batteries assemble scope
  triggers at runtime.
- Still ungated, stated: JSON string copy (decision-page configs), code
  comments (unruled surface, advisory via style-watch), server-side commits.

## Rollback

Revert guard-prose-quality.sh and guard-commit-signature.sh to their 0040/0041
versions (git history); code-copy-lint.py is inert uncalled.
`touch ~/.claude/.no-prose-quality-gate` and
`~/.claude/.no-commit-signature-gate` mute machine-wide without unregistering.
