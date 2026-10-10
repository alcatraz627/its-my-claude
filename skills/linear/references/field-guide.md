# Linear field guide

How Linear behaves through the API, what the `/linear` tool does about it, and what to watch for. Read this once per session before the first write. The workspace's own names (states, labels, projects, cycles) are in `versable.md` beside this file.

The tool is `python3 ~/.claude/scripts/linear/linear.py`. Run it with `-h` for every verb. Examples below drop the `python3 …/linear.py` prefix.

## The one check-in

The owner usually asks for Linear help on a deadline. The aim is one exchange, not a conversation.

**Reads never need asking.** Look things up, list, search, report points. Do it and answer.

**Writes get one check-in per task, not per call.** Run every change you intend without `--yes` first. Each prints exactly what it would send, with names resolved ("state: In Review", "cycle: 97 (2026-10-05 to 2026-10-12)"). Collect those previews into one short block, show it, and ask once: "Send these?" On a yes, re-run the same commands with `--yes`. Do not ask field by field.

**Ask before, even mid-task, when:**

- A name is ambiguous or missing. The tool stops and lists the closest matches; pick only if one is obviously meant, otherwise ask with the candidates.
- The change touches more than about ten issues at once.
- It replaces text someone wrote: an issue description, a project's body (`--content-file`), a document that was edited in Linear, a comment you did not write.
- It moves or archives something: `issue archive`, `doc archive`, a document re-parented to another issue.
- It posts something other people will read as the owner: a comment, a project status update.

**Never ask about:** which command to use, how to format output, whether to read something first. Those are yours.

Show the result as links (every write prints the URL), not a narration of what you did.

## Recipes

| The owner says                              | Run                                                                                                                            |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| "What's on my plate this cycle?"            | `issues --cycle current --mine`                                                                                                |
| "How's the sprint going?"                   | `cycle current` (add `--list` for the issues)                                                                                  |
| "Points left on V6 / on the SoR milestone?" | `points --project V6 [--milestone "V6: SoR"]`                                                                                  |
| "Which of these aren't estimated?"          | `issues --cycle current --unestimated`                                                                                         |
| "Make a ticket for X"                       | `issue create --title "X" [--body-file x.md] [--project ...] [--milestone ...] [--cycle current] [--estimate 3] [--label ...]` |
| "Make it from the Bug template"             | `issue create --template Bug --title "..."`                                                                                    |
| "Break VER-986 into sub-tasks"              | one `issue create --parent VER-986 --title ...` per sub-task                                                                   |
| "Move these to next cycle / to In Review"   | `issue update VER-n --cycle next` / `--state "In Review"`                                                                      |
| "Tag it"                                    | `issue update VER-n --add-label Speedway` (`--label` replaces all labels)                                                      |
| "Link the PR / doc"                         | `link VER-n <url> --title "PR #12"`                                                                                            |
| "VER-1 blocks VER-2"                        | `relate VER-1 blocks VER-2` (also `blocked-by`, `related`, `duplicate`, `similar`)                                             |
| "Reply on the ticket"                       | `comment add VER-n --body "..."`; threads: `--parent <commentId>` from `comments VER-n`                                        |
| "Add a milestone / set its date"            | `milestone create V6 "Name" --target 2026-10-31` / `milestone update V6 "Name" --target ...`                                   |
| "Post a project update"                     | `project post V6 --health atRisk --body-file update.md`                                                                        |
| "Find the ticket about X"                   | `search "X"`; documents: `search "X" --docs`                                                                                   |
| "Show the Next Sprint Board"                | `view run "Next Sprint Board"`                                                                                                 |
| "Put these docs on the ticket"              | a `linear.json` (below), `docs publish linear.json`, then `--yes`                                                              |
| Anything the verbs don't cover              | `query '{ … }'` runs any read-only GraphQL; writes go through a new verb, not raw mutations                                    |

Add `--json` before the verb for machine-readable output.

## How each part works

### Issues and sub-issues

- An issue belongs to one team (`VER`). A sub-issue is an issue with `--parent`; nesting has no fixed depth, but keep it to one level unless asked.
- `--label` **replaces** the whole label set. Use `--add-label` and `--remove-label` to change one.
- `--body-file` / `--description` **replaces** the description. To add to it, read it first (`issue show`), edit, and send the whole thing.
- Priority: urgent, high, medium, low, none (Linear stores 1 to 4, and 0 for none).
- `issue archive` hides the issue; it can be restored in Linear. The tool has no hard delete.

### States

- Each team has its own states. Every state has a type: backlog, unstarted, started, completed, canceled (and duplicate, triage). Reports and filters group by type.
- In Versable, **"Reference" is a canceled-type state and "Merged" and "Deployed" are both completed**. A points report counts Merged and Deployed as done and Reference as not.
- `issues` hides completed, canceled and duplicate states unless `--state` or `--include-done` is given.

### Labels

- Versable encodes kinds in label names, not in Linear label groups: `/backend` and friends for area, `:documentation` for topic, `@URGENT` and `@Release` for flags, `_Idea` and `_Tech Debt` for kind, `I. Bug` to `IV. Story` for issue type. Follow the prefix when creating a label.
- Labels can be team or workspace wide. `label create` makes a team label unless `--workspace`.
- Project labels (Internal, App, Customer) are a separate list from issue labels.

### Points (estimates)

- The scale is a team setting. VER is Fibonacci with 0 allowed and the extended values: 0, 1, 2, 3, 5, 8, 13, 21. The tool refuses anything else before sending.
- An issue with no estimate is not zero. `points` reports "unestimated" separately; many issues in a cycle are usually unestimated, so a points total understates the work.
- Linear's own cycle "progress" gives partial credit to started work, so it will not match "points done", which counts completed issues only. Quote both when asked how a cycle is going.

### Cycles

- VER runs one-week cycles starting Tuesday, with two future cycles created ahead. `current`, `next`, `previous` or a number all work.
- `--cycle none` takes an issue out of its cycle.
- When a cycle closes, Linear normally moves unfinished issues to the next one (a team setting; not checked for VER).

### Projects, statuses and milestones

- Projects have their own status list (Cyclic, Planned, In Progress, Review / Testing, Deployed, Completed, Canceled, Backlog in Versable), separate from issue states.
- Milestones live inside one project. An issue's milestone must belong to the issue's project; `--milestone` uses `--project` or the issue's current project.
- Most Versable milestones have no target date, so "what's due" is usually answered by cycles, not milestones.
- `project update --content-file` replaces the project's long body; `--description` is the one-line summary.

### Project updates

- A project update is a posted status note with a health (onTrack, atRisk, offTrack) and a markdown body. It is visible to everyone on the project and may notify them. None has been posted in Versable yet, so the first one is visible and new; check in before posting.

### Relations, comments and links

- Relations: blocks, related, duplicate, similar. `blocked-by` is `blocks` in reverse.
- Comments are markdown, threaded by `--parent`. `comment resolve` closes a thread. Comments post as the owner; edits show as edited.
- `link` adds a URL attachment on the issue (a PR, the artifact, a Google Doc). It is not the same as a Linear document.

### Documents

- A document has exactly one parent: an issue, a project, an initiative, a team or a cycle. Setting `issueId` on an existing document **moves** it.
- `docs publish <config>` is the markdown-to-Linear path. Config:

  ```json
  {
    "issue": "VER-986",
    "docs": ["00-README.md", "01-problem-and-thesis.md"],
    "title": "filename"
  }
  ```

  `title` is `filename` (the default, matching documents uploaded by hand, like VER-986's) or `heading` (the file's first `# ` line). It matches existing documents on the issue by title, updates them in place, creates only the missing ones, and rewrites links between the files to point at their Linear documents.

- After every write it reads the document back and fails if Linear stored nothing or far less than was sent.
- It stores a hash of what Linear returned, and next time refuses to overwrite a document whose content changed in Linear since, or that has unresolved inline comments, unless `--force`. Pull the Linear version first with `doc pull <id> -o file.md` and merge by hand.
- `--dry-run` writes the converted markdown to `.linear-preview/` next to the config without touching Linear.

### Templates, views, initiatives, search

- `issue create --template Bug` applies a team template. Whether explicit flags override the template's own values is untested; check the preview and `issue show` after.
- `views` lists saved views; `view run "<name>"` returns that view's issues, using the view's own filters.
- Initiatives group projects. Versable has none yet; `initiative create/update` work, `status` is one of Proposed, Planned, Active, Completed, Canceled.
- `search` uses Linear's full-text and semantic search over issues (`--comments` to include comment text), documents (`--docs`) or projects (`--projects`).

## Limits and caveats

| What                                            | Detail                                                                                                                                                           | What to do                                                                                                                                |
| ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Rate limits                                     | 2,500 requests and 3,000,000 complexity points per hour for this key                                                                                             | `whoami` shows what is left; a 429 means wait for the reset                                                                               |
| One query's cost                                | A single query is capped at 10,000 complexity points. Nested lists multiply (100 documents × 100 comments fails)                                                 | Ask for fewer nested items, or split into several queries                                                                                 |
| Pagination                                      | Lists default to 50 per page; the tool follows pages up to each verb's `--limit`                                                                                 | Raise `--limit` when a list looks short                                                                                                   |
| Customer requests                               | Not available in this workspace: the API answers 403                                                                                                             | No verbs for customers or customer needs                                                                                                  |
| Roadmaps                                        | Internal or deprecated; replaced by initiatives                                                                                                                  | Use initiatives                                                                                                                           |
| "Last edited by"                                | Everything the tool writes is attributed to the owner, same as the owner's own edits                                                                             | Never use `updatedBy` to decide whether the owner changed something; compare content                                                      |
| Raw HTML in markdown                            | Linear stores it as visible text (VER-986's docs show `<!-- sessions -->` as a paragraph)                                                                        | The publish path strips comments and turns `<br>` cells into `•`; do the same in any description or comment                               |
| Heading links                                   | Headings get ids, but a full rewrite of a document very likely gives them new ids                                                                                | Links between documents point at the document, not a heading                                                                              |
| Mermaid, `<br>`, image handling through the API | Not yet tested                                                                                                                                                   | Treat as unknown; a test document settles each                                                                                            |
| Empty documents                                 | VER-986's 03-architecture.md was uploaded by hand and stored no content at all; the cause is unknown                                                             | The publish path reads back every write; for anything else, `doc pull` after writing a document                                           |
| Bot and odd users                               | The user list includes a "Linear" bot and a bare email user                                                                                                      | Resolve people by name or email, and read back the resolved name in the preview                                                           |
| 401                                             | The key is wrong, expired, or was revoked by an admin                                                                                                            | Tell the owner; do not retry                                                                                                              |
| `Invalid scope: write required`                 | Personal keys are created with scopes; a read-only key reads everything and refuses every change. Every read verb works, so this only shows on the first `--yes` | The owner makes a key with Read and Write (in Linear's settings, under personal API keys) and replaces `LINEAR_API_KEY`; nothing was sent |

## Things that have gone wrong before

- **Duplicates.** A first draft of the publish script titled documents differently from the ones already on VER-986 and would have created nine duplicates. Always match what exists; `docs list VER-n` first.
- **Silent empty content.** A document existed with no body and nobody noticed. Read back after writing.
- **Overwriting someone's edit.** One-way publishing overwrites edits made in Linear. The stored read-back hash catches it; do not `--force` past it without the owner.
- **Guessing names.** The tool matches case-insensitively, then by unique prefix, then by unique substring, and stops on a tie. Do not paper over a tie by picking one.

## Troubleshooting

| Symptom                                                                     | Cause                                                                                                                    | Fix                                                                                   |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| `no API key`                                                                | `LINEAR_API_KEY` not in this shell                                                                                       | It lives in `~/.zshenv`; a new shell picks it up                                      |
| `Invalid scope` on a `--yes`                                                | The key is read-only                                                                                                     | See the limits table; ask the owner for a Read and Write key                          |
| `several teams`                                                             | The workspace gained a second team                                                                                       | `--team KEY` or `LINEAR_TEAM`                                                         |
| `The query is too complex`                                                  | Nested lists too large                                                                                                   | Lower the nested `first:` values                                                      |
| A name "matches several"                                                    | Prefix or substring tie                                                                                                  | Use the full name from the listed candidates                                          |
| `doc history` or a raw `documentContentHistory` query returns an empty list | It is keyed by the document's `documentContentId`, not its id; given the wrong id Linear answers success with no entries | `doc history` looks up the content id; in raw queries, read `documentContentId` first |

## Tests

`bash ~/.claude/scripts/linear/linear.test.sh` runs the offline checks; `--live` adds every read verb against the workspace and previews of writes (nothing is sent). Run it after changing the script.
