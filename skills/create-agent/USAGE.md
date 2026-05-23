# /create-agent — Usage Guide

## What it does

Scaffolds a new autonomous agent SKILL.md (with `context: fork`, no interactive prompts) from
user instructions, or converts an existing interactive skill to agent format. Reads all existing
skills as context and suggests a template when the intent closely matches an existing skill.

## Usage

```
/create-agent <instructions | existing-skill-name>
```

| Argument       | Type     | Description                                                                                                    |
| -------------- | -------- | -------------------------------------------------------------------------------------------------------------- |
| `instructions` | required | Natural-language description of what the agent should do, OR an existing skill name to convert to agent format |

## Examples

### Example 1: Create a new agent from instructions

```
/create-agent "scan all api routes and report missing auth guards"
```

Loads all existing skills, finds `route-audit` as a similar template, asks if you want to use
it, then scaffolds a new agent SKILL.md with `context: fork`, three autonomous phases, and a
structured error/warning/summary report.

### Example 2: Convert an existing skill to agent format

```
/create-agent arch-qa
```

Reads `arch-qa/SKILL.md`, identifies any interactive elements and self-update references to
remove, adds `context: fork`, restructures into autonomous phases, and rewrites the file.

### Example 3: New agent with template suggestion declined

```
/create-agent "diff pydantic models against typescript interfaces"
```

Suggests `sync-api-types` as a template. If declined, scaffolds from scratch based on the intent.

## Caveats

- **Overwrites on convert**: In convert mode, the existing SKILL.md is replaced. Run with a
  clean git working tree so you can revert if needed.
- **Agents cannot prompt**: The generated agent SKILL.md will have no `AskUserQuestion` calls.
  If your use case requires mid-run decisions or approval gates, use `/create-skill` instead.
- **`context: fork` scope**: Fork isolates the conversation context, not the filesystem. The
  agent still reads and writes real files — it just doesn't flood the main conversation.
- **Template suggestion is heuristic**: Always review the suggested skill's brief before
  accepting it as a structural model.

## Dependencies

| Dependency              | Type         | Notes                                              |
| ----------------------- | ------------ | -------------------------------------------------- |
| `GUIDELINES.md`         | Shared rules | Read at start of every run                         |
| All existing `SKILL.md` | Reference    | Loaded for context catalogue and template matching |
| `prettier`              | CLI tool     | Formats generated files after writing              |

## Tips

- Pass an existing skill name (e.g., `route-audit`) to convert it — don't describe what it does, just name it.
- For new agents, be specific: "scan src/app/api/ for missing auth guards and Zod validation" is
  better than "check routes".
- After creating, run `/user-config` to review the new agent definition.
- Use `/improve-skill` later if you want to refine the generated agent's workflow.
- Agents suit **read-only audits, codebase scans, and structured reports**. Scaffolding wizards
  or multi-step workflows with user decisions belong in `/create-skill`.
