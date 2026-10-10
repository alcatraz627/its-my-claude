---
name: linear
description: Reads and changes the owner's Linear workspace through one tested script, previewing every change: issues, comments, labels, links, relations, cycles, points, projects, milestones, docs. Use when the owner mentions Linear, a VER- ticket, a sprint, or wants work filed, tagged, moved or reported.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
user-invocable: true
argument-hint: "<what you need from Linear, e.g. 'my issues this cycle' or 'move VER-12 to review'>"
---

## Brief

`/linear` is the owner's Linear desk: one script, `~/.claude/scripts/linear/linear.py`, that
reads anything in the workspace and makes changes only after showing them resolved, plus two
references that say how Linear behaves and what this workspace holds. Asks arrive
spontaneously and against a clock, so the skill is built for one exchange: read what is
needed, preview the change, confirm once, send, answer with links. The claude.ai Linear
connector is blocked by org policy; this talks to the API with the owner's key.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and the `## linear:` entries in
`~/.claude/skills/runtime-notes.md`. Read `~/.claude/skills/linear/references/field-guide.md`
once per session before the first change; open `~/.claude/skills/linear/references/versable.md`
when the ask names a state, label, project, milestone or person. Then run
`python3 ~/.claude/scripts/linear/linear.py whoami`: it proves the key works and shows the
rate-limit headroom.

## Usage

```
/linear <what is needed, in the owner's words>
```

The script is the only way this skill touches Linear. Run `linear.py -h` for every verb; the
map, with `L` standing for `python3 ~/.claude/scripts/linear/linear.py`:

| Need          | Verbs                                                                                                                                                                        |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Orient        | `L whoami`, `L states`, `L labels`, `L users`, `L templates`, `L views`                                                                                                      |
| Find          | `L issues [--cycle current] [--mine] [--state …] [--label …] [--project …] [--milestone …] [--unestimated]`, `L search "<term>" [--docs\|--projects]`, `L view run "<view>"` |
| Inspect       | `L issue show VER-n [--comments]`, `L comments VER-n`, `L project show <name>`, `L milestones <project>`, `L docs list VER-n`, `L doc pull <id>`, `L doc history <id>`       |
| Report        | `L cycle [current\|next\|previous\|N] [--list]`, `L points --cycle … \| --project … [--milestone …] \| --assignee …`                                                         |
| Change issues | `L issue create …`, `L issue update VER-n …`, `L issue archive VER-n`, `L comment add\|edit\|resolve`, `L link`, `L relate`                                                  |
| Change plans  | `L milestone create\|update`, `L project update`, `L project post`, `L label create`, `L initiative create\|update`                                                          |
| Documents     | `L docs publish <linear.json> [--dry-run]`, `L doc archive <id>`                                                                                                             |
| Anything else | `L query '{ … }'` for any read                                                                                                                                               |

Add `--json` before the verb when the output feeds a later step.

## Reading

Reads never need the owner's permission and never change Linear: the client refuses any
mutation on its read path. Resolve before answering: a vague ask ("the sync ticket") is a
`search`, a name is matched case-insensitively, then by unique prefix, then by substring, and a
tie stops with the candidates listed. Answer with the data (a short table, the links), not an
account of the commands run. Quote both Linear's cycle progress and points completed when
asked how a cycle is going; they measure different things.

## Changing

Every write verb, new or old, behaves the same way, and the documents path follows it too.

1. **Preview.** Run the change without `--yes`. It prints what it would send with every name
   resolved to what Linear has ("state: In Review", "cycle: 97 (…)", "labels add: Speedway")
   and sends nothing. A name that does not resolve, or an estimate off the team's scale, stops
   here with the valid options.
2. **Check in once.** Put every preview the task needs into one block and ask the owner one
   question. The field guide lists the only reasons for a second question: a bulk change,
   replacing text someone wrote, archiving or moving, posting as the owner, an ambiguous name.
3. **Send.** On a yes, re-run the same commands with `--yes`. Each prints the URL of what
   changed.
4. **Report.** The links, and anything the preview could not show (a template's own values, a
   notification the change triggers).

A write the script has no verb for gets a verb added to the script, with a preview, rather
than a raw mutation sent by hand.

## Publishing documents

`L docs publish <config>` puts a markdown set on an issue as Linear documents, the Linear
counterpart of `/gdoc`. The config sits next to the files:

```json
{
  "issue": "VER-986",
  "docs": ["00-README.md", "01-problem-and-thesis.md"],
  "title": "filename"
}
```

It follows the same preview, check-in and `--yes` as every other change, and adds what a
document needs:

- Existing documents on the issue are matched by title and updated in place; only the missing
  ones are created. `title` is `filename` (matching hand-uploaded documents) or `heading`.
- Links between the files become links to their Linear documents; section anchors are dropped.
- Frontmatter and HTML comments are stripped and `<br>` table cells become `•`, because
  Linear shows raw HTML as text.
- Every written document is read back; empty or truncated content fails the run.
- A document changed in Linear since the last publish, or holding unresolved inline comments,
  stops the publish before anything is sent. `--force` overrides it only when the owner has
  said so for that document; otherwise `L doc pull <id> -o file.md` and merge by hand.
- `--dry-run` writes the converted files to `.linear-preview/` and touches nothing.

## Keeping the snapshot fresh

`versable.md` is data generated from the workspace. When it disagrees with what a command
returns (a new state, project, label or person), regenerate it:
`python3 ~/.claude/scripts/linear/linear.py snapshot -o ~/.claude/skills/linear/references/versable.md`.

## Auth

`LINEAR_API_KEY` (exported in `~/.zshenv`) or the keychain service `linear-api`. The key needs Read
and Write access: a read-only key passes every read and fails the first `--yes` with "Invalid scope",
sending nothing. A 401 means the key is wrong or revoked. Either way, tell the owner and stop.

## Boundaries

- Never prints, creates, stores or changes the API key.
- Never sends a mutation outside a script verb, and never without the owner's yes for that task.
- Never `--force`s past a document changed in Linear without the owner naming that document.
- No verbs for admin surfaces: integrations, OAuth apps, SSO, audit log, webhooks, email intake.
  Customer requests are off in this workspace (the API answers 403); roadmaps are replaced by
  initiatives.
- No hooks, no scheduled jobs: the skill acts when asked.

## Validation

Efficacy is the right change on the first try with a single check-in, and reads that answer the
question without a second lookup. Checks an agent can run:

1. `bash ~/.claude/scripts/linear/linear.test.sh --live` ends `0 failed`; run it after any change
   to the script.
2. For a task that wrote: the previews shown to the owner match the `Done:` lines and URLs
   printed with `--yes`, one question was asked (or a field-guide reason for a second is named),
   and nothing needed undoing.
3. For a publish: `L docs list <issue>` shows one document per file and no duplicate titles, and
   `L doc pull <id>` returns content for every one.

## Runtime notes and ledger

Prepend a `## linear:` entry via `bash ~/.claude/skills/shared/prepend-runtime-note.sh linear <entry.md>`
when a run taught something, and move durable lessons into
`~/.claude/skills/linear/references/field-guide.md`. Then
`bash ~/.claude/scripts/skill-log.sh record linear --task "<gist>" --outcome unknown --corrections 0 --note "<verbs used; writes sent; check-ins asked>"`.
