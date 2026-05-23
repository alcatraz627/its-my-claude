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
Disabled plugins registry + plugin-vs-custom-skill preference rule.

## Disabled plugins

8 plugins disabled. Registry: `~/.claude/disabled-plugins.json`. Vercel MCP server kept in `.mcp.json` (hooks removed for false-positive skill injection). Sentry denied globally, allowed only in enhancement-product via project settings. Notion denied globally.

Re-enable in `settings.json` → `enabledPlugins`.

## Plugin vs custom skill — preference rule

When a marketplace plugin and a custom skill in `~/.claude/skills/` cover overlapping ground:

- **Prefer the plugin** for broad, general-purpose tasks (e.g. `code-review@claude-plugins-official` for PR reviews, `skill-creator@claude-plugins-official` for skill scaffolding) — plugins get upstream updates automatically.
- **Prefer the custom skill** when project-specific context, custom GUIDELINES rules, or local tooling integration is needed (e.g. `/arch-qa` knows local conventions; `/sync-api-types` is repo-specific).
- **When in doubt:** check if the custom skill has a richer SKILL.md than the plugin. If the plugin is a thin wrapper and the local skill has more depth, use the local skill.
