# `~/.claude/conventions/`: output and authoring standards

> Conventions govern **how artifacts look**: file naming, HTML output, CLI help formats, asset placement.

## When to write here

- A format spec for an output type (HTML reports, CLI help screens)
- A naming or layout convention (asset paths, doc-naming)
- A reusable authoring standard cited by multiple skills or scripts

## When NOT to write here

- A behavioral mandate or what Claude must do goes in `~/.claude/rules/`
- How a tool works goes in `~/.claude/features/`
- A one-off styling note goes inline in the relevant skill or feature doc

## File shape

YAML frontmatter required (`brief`, `triggers:`, `related`, `tier`, `category`, `updated`, `stale_after_days`).

Body: state the convention up front, and show good vs bad examples when the failure mode isn't obvious. Keep it under 100 lines, and split longer pieces into multiple conventions.

## Cross-system contracts

Some conventions are contracts other systems rely on (for example, `asset-management.md` is consumed by `asset.sh` and `assets/MANIFEST.md`). Breaking-change edits to those files must update the consumer in the same commit.

## See also

- `conventions/asset-management.md`: the assets/scratchpad/tmp three-way placement rule
- `conventions/doc-naming.md`: the `YYYYMMDD-` prefix policy and session-tag headers
- `conventions/html-output.md`: the mandatory dark/light toggle in generated HTML
- `PLACEMENT.md`: placement rules
