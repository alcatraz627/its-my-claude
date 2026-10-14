---
brief: Disabled plugins registry; plugin vs custom-skill preference rule
triggers:
  - topic:plugins
  - topic:skill-selection
  - phrase:"marketplace plugin"
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Plugins
The disabled-plugins registry and the plugin-vs-custom-skill preference rule.

## Disabled plugins

8 plugins are disabled. Registry: `~/.claude/disabled-plugins.json`. The Vercel MCP server stays in `.mcp.json` (its hooks were removed for false-positive skill injection). Sentry is denied globally and allowed only in enhancement-product via project settings. Notion is denied globally.

Re-enable in `settings.json` under `enabledPlugins`.

## Plugin vs custom skill: preference rule

When a marketplace plugin and a custom skill in `~/.claude/skills/` cover overlapping ground:

- **Prefer the plugin** for broad, general-purpose tasks (e.g. `code-review@claude-plugins-official` for PR reviews, `skill-creator@claude-plugins-official` for skill scaffolding), because plugins get upstream updates automatically.
- **Prefer the custom skill** when you need project-specific context, custom GUIDELINES rules, or local tooling integration (e.g. `/arch-qa` knows local conventions, and `/sync-api-types` is repo-specific).
- **When in doubt,** check whether the custom skill has a richer SKILL.md than the plugin. If the plugin is a thin wrapper and the local skill has more depth, use the local skill.
