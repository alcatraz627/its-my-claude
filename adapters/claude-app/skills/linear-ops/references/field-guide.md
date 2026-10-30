# Linear field guide

How Linear behaves through the connector, what to watch for, and the user's
team conventions. Read once per chat before the first change.

## Recipes

| The user says | Do |
|---|---|
| "What is on my plate this cycle?" | List issues: current cycle, assignee me |
| "How is the sprint going?" | Get the current cycle, then its issues. Quote progress and points done |
| "Points left on project X or milestone Y?" | List the project's issues, sum estimates by state type, report unestimated separately |
| "Which of these are not estimated?" | List the cycle's issues, filter to no estimate |
| "Make a ticket for X" | Preview a new issue: team, title, description, project, cycle, estimate, labels |
| "Make it from the Bug template" | Preview with the template named. Check the result after, since template values may differ from the preview |
| "Break ABC-1 into sub-tasks" | One new issue per sub-task with ABC-1 as parent |
| "Move these to next cycle / to In Review" | Update cycle or state |
| "Tag it" | Add the label. Do not replace the label set |
| "Link the PR" | Add a link attachment with a title |
| "ABC-1 blocks ABC-2" | Add the relation on ABC-1 |
| "Reply on the ticket" | Preview the comment. It posts as the user |
| "Post a project update" | Preview health and body. It is visible and may notify people |

## How each part behaves

**Issues.** One issue belongs to one team. A sub-issue is an issue with a
parent. Keep nesting to one level unless asked. Priority runs 1 urgent, 2
high, 3 medium, 4 low, 0 none.

**Fields that replace.** The full label list replaces every label on the
issue. A full description replaces the whole description. Use the add and
remove label fields, and a patch edit for descriptions, so nothing someone
else wrote is lost. Relations and links are append-only.

**States.** Each team has its own states, and each state has a type:
backlog, unstarted, started, completed, canceled, plus duplicate and triage.
Reports group by type, not by name. Lists usually hide completed and
canceled issues unless asked.

**Estimates.** The scale is a team setting. Send only values on the team's
scale. Linear's own cycle progress gives partial credit to started work, so
it will not match points done, which counts completed issues only.

**Cycles.** "Current", "next", "previous" or a number. Removing an issue's
cycle takes it out. When a cycle closes, Linear usually rolls unfinished
issues forward (a team setting).

**Projects and milestones.** Projects have their own status list, separate
from issue states. A milestone lives in one project, and an issue's milestone
must belong to the issue's project.

**Documents.** A document has exactly one parent: an issue, project,
initiative, team or cycle. Re-parenting moves it. Heading links break on a
full rewrite, so link to documents, not headings.

**Attribution.** Everything sent through the connector shows as the user.
"Last edited by" cannot tell the user's edits from Claude's. Compare content
instead.

## Things that have gone wrong before

- **Duplicates.** Creating documents under titles that differ from the ones
  already on an issue. List first, match titles.
- **Silent empty content.** A document existed with no body and nobody
  noticed. Read back after writing.
- **Overwriting an edit.** Publishing over a document someone changed in
  Linear. Compare before writing.
- **Guessing names.** Picking one of several matches. Show the candidates.

## The user's team conventions

These are from the user's team setup at the time this skill was written.
Check them against the live lists before relying on them.

- **Labels encode kind by prefix**, not by Linear label groups. `/area` for
  the code area (`/backend`, `/frontend`), `:topic` for a topic
  (`:documentation`, `:infra`), `@flag` for flags (`@URGENT`, `@Release`),
  `_kind` for the kind of work (`_Idea`, `_Tech Debt`), and Roman-numeral
  labels for issue type (`I. Bug`, `II. Improvement`, `III. Feature`,
  `IV. Story`). Follow the prefix when proposing a new label.
- **Estimates** are Fibonacci with zero allowed: 0, 1, 2, 3, 5, 8, 13, 21.
- **Cycles** are one week long, with two future cycles created ahead.
- **States** include a canceled-type "Reference" state for issues kept as
  reference, and two completed-type states, "Merged" and "Deployed". A points
  report counts both as done and "Reference" as not.
- **Milestones** mostly have no target date, so "what is due" is usually
  answered by cycles, not milestones.
- **Project updates** are rare on the team. A first one is visible and new,
  so always check in before posting.
