# `~/.claude/conventions/` — Output & authoring standards

> Conventions govern **how artifacts look**: file naming, HTML output, CLI help formats, asset placement.

## When to write here

- A format spec for an output type (HTML reports, CLI help screens)
- A naming or layout convention (asset paths, doc-naming)
- A reusable authoring standard cited by multiple skills/scripts

## When NOT to write here

- A behavioral mandate / what Claude must do → `~/.claude/rules/`
- How a tool works → `~/.claude/features/`
- A one-off styling note → inline in the relevant skill/feature doc

## File shape

YAML frontmatter required (`brief`, `triggers:`, `related`, `tier`, `category`, `updated`, `stale_after_days`).

Body: state the convention up front; show good vs bad examples when the failure mode isn't obvious. Keep <100 lines — longer pieces probably split into multiple conventions.

## Cross-system contracts

Some conventions are contracts other systems rely on (e.g., `asset-management.md` is consumed by `asset.sh` + `assets/MANIFEST.md`). Breaking-change edits to those files must update the consumer in the same commit.

## See also

- `conventions/asset-management.md` — the assets/scratchpad/tmp three-way placement rule
- `conventions/doc-naming.md` — `YYYYMMDD-` prefix policy + session-tag headers
- `conventions/html-output.md` — mandatory dark/light toggle in generated HTML
- `PLACEMENT.md` — placement rules
