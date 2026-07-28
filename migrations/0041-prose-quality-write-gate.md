# 0041: prose-quality write gate blocks banned tells at the artifact layer

## Summary

New PreToolUse guard on Write/Edit
(`~/.claude/scripts/hooks/guard-prose-quality.sh`, registered in
settings.json): a prose file (.md/.html/.txt) cannot be written with earnest
connective em/en-dashes (owner budget: zero), a verdict-first opener, or a
prose-lint score above 8 per 100 words. The block message names the counts and
quotes the offending spans. Scoring runs through
`scripts/style/prose-lint.py`, which strips code fences, inline code,
blockquotes, and table rows first, so quoted defect examples never count.
Style-system paths that quote banned material by design (style/, atone/,
i-dream/, sweep dirs, the taxonomy and ste-writing docs, derived digests) are
exempt.

## Why

The prose-smell Stop hook guards only the final chat message. The 2026-07-28
banner incident (atone `ai-smell-prose-against-stored-voice`, verdict
very-wrong) shipped padded-explainer prose with em-dashes into a deployed UI
through Write, a layer with no gate. Same lesson as migrations 0039/0040:
rules enforced at an advisory or wrong layer lose. The gate belongs where the
violation ships.

## Behavior notes

- Seven-case battery, 2026-07-28: dirty .md blocked with span, clean .md
  passes, .py out of scope, style-path exempt, Edit new_string blocked,
  blockquote-only dashes pass, verdict opener blocked naming the line.
- First live catch: this migration file's own draft, blocked for a dash-form
  H1 title and one two-split sentence. Both rewritten instead of exempting
  the migrations dir. Future migration H1s use the colon form.
- Known scope gap, stated: prose inside code files (JSX/TSX string literals,
  HTML templates in .ts) is not scanned, and that is likely where the banner
  lived. Extending to string-literal extraction in code files is a follow-up
  decision, not silently included, because the false-positive surface is much
  larger there.
- The guard proved active in the SAME session that registered it, so hook
  config is read per call, not only at session start.

## Rollback

Remove the guard entry from settings.json. A machine-wide mute without
unregistering: `touch ~/.claude/.no-prose-quality-gate`
