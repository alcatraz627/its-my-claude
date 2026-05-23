# `~/.claude/skills/` — Global skill definitions

> Skills are user-invokable `/command` entrypoints. Each lives in its own subdir with a `SKILL.md`.

## When to add a skill here

- The workflow is broadly useful across most projects
- The skill has a clear `/name` and one-line trigger description
- The prompt + code together fit the skill envelope (`SKILL.md` + optional companion files)

## When NOT to add here

- Project-specific workflow → that project's `.claude/skills/`
- Prototype not yet trusted → `~/.claude/scratchpad/` first, graduate here later
- One-off task → just run it; don't formalize a skill

## Folder shape

```
skills/<skill-name>/
  SKILL.md          # frontmatter + prompt
  USAGE.md          # optional; deep usage doc
  <scripts/>        # optional helper scripts
```

`SKILL.md` requires frontmatter: `name`, `description` (used by router agents to pick skills), `tools` (optional restrictions). The description is **load-bearing** — it's how `pick-skill` and similar selectors decide what fits.

## Discoverability

Claude Code surfaces every `SKILL.md` it finds under this tree flat in the per-session skill list — there is no nested-routing benefit to filesystem groups (with rare exceptions like `apple/` which uses a router skill internally).

For scoping which skills appear in a given project, use that project's `.claude/settings.json` (mechanism TBD — see follow-up audit task).

## See also

- `~/.claude/skills/GUIDELINES.md` — authoring rubric
- `/create-skill` — interactive new-skill wizard
- `/improve-skill` — audit / refresh an existing skill
