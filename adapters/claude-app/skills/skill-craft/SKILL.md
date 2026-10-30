---
name: skill-craft
description: Writes a new skill or improves an existing one in this plugin's house style, chat-runnable and plain, and ends with the SKILL.md ready to paste into claude.ai or commit. Use for any skill work.
---

# Skill craft

Writes or improves a skill for this plugin, so it routes when it should and
runs in chat when it does. A skill here is one `SKILL.md` (plus optional
reference files) that Claude loads when a conversation matches its
description. The run ends with the full file content, ready to paste into
claude.ai under Customize > Skills or to commit to
`adapters/claude-app/skills/<name>/` in the user's config repo.

## When to use

- "Make a skill for X", "turn this workflow into a skill"
- "This skill never triggers", "it does the wrong thing", "tighten this skill"
- Porting a skill written for a local setup into a chat-runnable one

Not for a one-off task the user will not repeat. Just do the task.

## The house style

Every skill in this plugin meets these. They are the checklist for both
writing and improving.

**Frontmatter.** Only `name` and `description`. The name is lowercase with
hyphens and unique in the plugin. The description is 200 characters or
fewer, because claude.ai cuts longer ones. Count it in the code sandbox, do
not estimate.

**Description shape.** What it does, on what, and when to reach for it,
then a "Not for" clause if a neighbor skill is easily confused with it. The
description is the only part Claude sees when deciding whether to load the
skill, so routing words go here, not in the body. Every skill's name and
description share one listing budget, and when the listing overflows the
descriptions of the least used skills are dropped first. A skill with no
visible description cannot be routed to. Short and specific beats long and
complete.

**Body.** 50 to 160 lines. A title, an opening paragraph that says what the
thing is before why it exists, then "When to use" with a "Not for" line,
then the procedure, the reply shape, and boundaries. Headings name their
contents, never "Phase 1" or "Step 3". Procedure and heuristics, not an
essay.

**Chat-runnable.** Only what chat has: the code sandbox, artifacts, web
search, reading images, and the user's connectors (for example Linear,
Google Drive, Google Sheets, GitHub, Slack, Figma). No local file paths, no
local scripts, no hooks, no sub-agents, no scheduled jobs. Where the original
used a script, the skill describes the steps Claude takes instead, or says
plainly what chat cannot do and gives the fallback.

**Writes are gated.** A skill that writes to an external service shows the
exact change first and waits for the user's go-ahead.

**Plain prose.** No em-dashes, no semicolons in prose, no marketing or
filler words. Say "the user". Follow `plain-writing` for the rest.

**No duplicates.** Before writing, read the plugin's skill list (the README
table, or the skill listing in this chat). If a skill already covers most of
the ask, improve that one instead, and say so.

## Writing a new skill

### 1. Gather what the skill must answer

The user usually hands over the answers in the request, a spec or an old
skill. Read those first, and ask only for what is truly missing, in one
numbered message:

1. Name
2. What it does, for whom, and when to reach for it
3. What it must never do
4. What it produces, and in what shape
5. Which connectors or chat tools it needs
6. Which existing skills it hands off to or from

### 2. Treat the user's words as intent

The user's words name a goal. A named instance stands for its class, and an
example is one sample, not the full set. Generalize the instance, size the
skill to what a good run needs, and write in the house voice. Never paste the
user's prompt into the skill. A sentence that is a near-verbatim run of their
input longer than a clause gets rewritten or cut.

### 3. Show the plan once

One block, one ask for a yes or changes:

```
<name>
  description  <the routing sentence, with its character count>
  sections     <one line each>
  hands off to <skills>
  boundaries   <what it never does>
```

A terse "go" means write. Changes mean revise the block and show it once
more, not a question per line.

### 4. Draft, then review as a separate pass

Draft the full file. Then reread it as someone who did not write it, against
these questions, and fix what they find:

- Which sentences are the user's input pasted in?
- Does the description alone tell a reader what, on what, and when?
- Does any step need a local machine, a script or a sub-agent?
- Any em-dash, semicolon in prose, or filler word?
- Does it contradict a neighbor skill about who owns a step?

Measure the description and count the body lines in the sandbox.

## Improving an existing skill

1. **Read it in full**, plus every skill it names and every skill that names
   it.
2. **Check it against the house style** above, line by line.
3. **Check routing.** Write six to ten requests, half that should load the
   skill and half that should go to a neighbor. Read the descriptions side by
   side and say which skill each request would reach. A miss tells you what
   the description must say or stop saying.
4. **Check contradictions.** Two places in the skill that disagree, or a
   neighbor that claims the same step. Quote both sides.
5. **Check the user's evidence.** What the user said went wrong outranks any
   style finding. A defect they reported more than once is a missing or wrong
   instruction until shown otherwise.
6. **Propose** every change in one numbered list, each with the before and
   after text and why. Ask once for the whole list.
7. **Apply** what the user approves, and nothing else.

## Reply shape

1. One line: what the skill is and where it goes.
2. The description and its measured length.
3. The full `SKILL.md` in one code block, and each reference file in its own
   block with its path.
4. For an improvement, the change list with what was applied.
5. Install: paste into claude.ai under Customize > Skills, or commit to
   `adapters/claude-app/skills/<name>/SKILL.md` and add a row to the
   plugin README's skill table.

## Boundaries

- Never silently replace an existing skill. If the name exists, ask:
  overwrite, rename, or improve the existing one.
- Never claim a skill triggers correctly without the routing check. Say
  `UNCONFIRMED` until the user has tried it in a fresh chat.
- Do not add sections, options or modes for a need nobody named.
