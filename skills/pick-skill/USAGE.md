# /pick-skill — Usage Guide

## What it does

Routes a raw user prompt to the most appropriate skill in the `.claude/skills/` catalogue.
Asks clarifying questions to resolve ambiguity, confirms the match with the user, then
executes the skill end-to-end and optionally generates an HTML report from the output.

## Usage

```
/pick-skill [prompt]
```

| Argument | Type     | Description                                                            |
| -------- | -------- | ---------------------------------------------------------------------- |
| `prompt` | optional | Raw intent in plain language. If omitted, an interactive prompt opens. |

## Examples

### Example 1: Clear intent

```
/pick-skill "my api types feel out of sync with the backend"
```

Identifies `/sync-api-types` as best match, confirms with `gum confirm`, then runs it end-to-end.

### Example 2: Ambiguous intent — clarifying question

```
/pick-skill "something feels off with my react query setup"
```

Asks: "Is the problem stale data after mutations, or a missing query key?" — user selects,
skill identifies `/invalidate-audit`, confirms, executes.

### Example 3: Architecture question

```
/pick-skill "I want to document how auth works in this project"
```

Matches `/arch-qa` with query `"how does authentication work?"`, confirms, runs it, and
offers `/create-report` on the output markdown.

## Caveats

- Always requires a `gum confirm` before executing — never auto-dispatches
- No-match path surfaces 3 closest partial matches before suggesting `/create-skill`
- Post-run `/create-report` is offered only if the invoked skill produced a markdown file
- Re-matching is attempted up to 2 times if the user declines the first suggestion

## Dependencies

| Dependency              | Type         | Notes                                                 |
| ----------------------- | ------------ | ----------------------------------------------------- |
| `GUIDELINES.md`         | Shared rules | Read at start of every run                            |
| `runtime-notes.md`      | Context      | Past run history for smarter matching                 |
| All `skills/*/SKILL.md` | Catalogue    | Scanned to build the match list                       |
| `/create-skill`         | Skill        | Suggested when no existing skill matches              |
| `/create-report`        | Skill        | Offered post-run when markdown output was produced    |
| `gum`                   | CLI tool     | Required for interactive prompts (`brew install gum`) |

## Tips

- Pass the prompt inline for faster routing: `/pick-skill "audit my route handlers for missing auth"`
- If pick-skill matches the wrong skill, say "no" at the confirm gate — it will re-match
- Use `/user-config` to browse the full skill catalogue before invoking if you already know which skill you want
