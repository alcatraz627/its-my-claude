# /improve-skill — Usage Guide

## What it does

Reads one or more skill definitions alongside their runtime notes and
GUIDELINES, identifies improvements (stale descriptions, missing
instructions, recurring bugs), asks for user input, then applies
approved changes directly to the skill files.

## Usage

```
/improve-skill [skill-name | skill-name,skill-name | all]
```

| Argument                | Type     | Description                              |
| ----------------------- | -------- | ---------------------------------------- |
| _(none)_ or `all`       | optional | Improve all skills in `.claude/skills/`  |
| `skill-name`            | optional | Improve a single named skill             |
| `skill-name,skill-name` | optional | Improve a comma-separated list of skills |

## Examples

### Example 1: Improve all skills

```
/improve-skill
```

Audits every skill, prints an analysis per skill, asks for specific
focus, shows a change list, and applies approved changes.

### Example 2: Improve one skill

```
/improve-skill project-index
```

Reads `project-index/SKILL.md` and all related runtime notes. Reports
findings, asks if there's a specific focus, then applies approved
improvements.

### Example 3: Improve a subset

```
/improve-skill create-report,arch-qa
```

Runs the full audit loop for each named skill in sequence.

## Validation & Scoring

After applying improvements, the skill validates the updated SKILL.md:

1. **Checks for `## Validation Examples`** in the target skill's SKILL.md
2. If none exist, **auto-generates 3–5 examples** from the skill's description and workflow
3. **Scores the skill 0–100** against each criterion (0 = missing, 5 = partial, 10 = fully covered)
4. If the score is **below 75**, offers to run another improvement loop targeting the gaps
5. **Maximum 2 re-improvement loops** — prevents infinite cycling

### Adding Validation Examples to your skill

Add a `## Validation Examples` section to any SKILL.md:

```markdown
## Validation Examples

### Example: Skill with no runtime notes

**Scenario:** User runs the skill on a target that has no entries in runtime-notes.md.
**Expected behavior:**

- [ ] Handles empty runtime notes gracefully (no crash)
- [ ] Analysis proceeds with structural compliance checks only
- [ ] Summary accurately reports "0 runtime insights"
```

When `/improve-skill` finds this section, it uses your criteria instead of auto-generating.

## Caveats

- Changes are never applied without your approval. The skill prints a
  change list and asks before writing anything.
- Code file edits (`.ts`, `.sh`) are conservative — only applied for
  clear, low-risk bugs identified in runtime notes. Complex redesigns
  are flagged as recommendations, not applied automatically.
- When running on `all`, the per-skill focus question can be skipped
  by pressing enter to proceed with the proposed list.
- If a skill has no runtime note history, analysis is based on the
  SKILL.md content and GUIDELINES compliance only.
- Validation scoring is heuristic — it checks whether the SKILL.md
  _instructions_ cover each criterion, not whether the skill _executes_
  correctly at runtime. It's a static analysis of instruction coverage.

## Dependencies

| Dependency         | Type         | Notes                       |
| ------------------ | ------------ | --------------------------- |
| `GUIDELINES.md`    | Shared rules | Read to check compliance    |
| `runtime-notes.md` | Run log      | Source of recurring issues  |
| `*/SKILL.md`       | Target files | The files being improved    |
| `prettier`         | CLI tool     | Formats files after changes |

## Tips

- Run `/improve-skill` after updating GUIDELINES.md to propagate new
  conventions to all existing skills.
- The "specific focus" prompt is the best place to mention bugs you've
  noticed personally (e.g., "the retry logic doesn't reset the counter").
- Pair with `/user-config edit → simplify` to reduce verbosity after
  improve-skill adds new instructions.
- Check `runtime-notes.md` manually first if you want to understand
  what patterns the skill will find.
