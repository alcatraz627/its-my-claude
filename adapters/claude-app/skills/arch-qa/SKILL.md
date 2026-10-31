---
name: arch-qa
description: Answers how a feature, data flow or auth path works by tracing the actual code the user shares or a connector exposes, with file:line for each step. Not for changes or reviews.
---

# Architecture Q&A

Answer "how does X work" by tracing the real code path, from the entry point
down to storage and back. Every step in the answer points at a file and a line.
The common failure is answering from the pattern you expect ("route, then
service, then database") instead of the code in front of you. Trace it even
when you think you know.

## Get the code

The code arrives one of three ways: pasted, uploaded as files or an archive,
or read through a GitHub connector. With a connector, search the repo for the
feature's terms, then open the files. With an archive, unpack it in the code
sandbox and search it there.

If the material does not reach far enough to answer, say which hop is missing
("the handler calls `billing.charge()`, which is not in what you shared") and
ask for that file. Never fill a missing hop with a guess presented as fact.

## 1. Pin the question

Name three things before reading anything:

- **The subject**: which feature or system
- **The kind of question**: how a feature works, how data moves from A to B,
  how auth is checked, how an integration talks to a service, or how state is
  held and updated
- **The scope**: front end, back end, or the full path

If the question is too broad to trace ("how does the app work"), propose two
or three narrower questions and ask which one.

## 2. Find the entry points

Start where the action begins: the page or component the user touches, the API
route, the job handler, the CLI command. Search by the feature's name and its
synonyms across the whole tree, not only the folder where it ought to live.
For auth, search for login, session, token, middleware and permission checks.
For data flow, search for the fetch calls, the queries and the writes.

## 3. Trace the path

From each entry point, follow the calls one hop at a time. For every file on
the path, note:

- what it receives
- what it does to the data
- what it returns or calls next
- what side effects it has: writes, sends, cache updates
- what it depends on that is configured elsewhere

Read the relevant functions, not whole files. Follow imports when the next hop
lives in another module. Read the tests for the area, because they show the
intended behavior and the edge cases the author thought about.

## 4. Check configuration and guards

Find the environment variables, config files and feature flags the path reads.
Find where auth and validation happen, and note where they do not. A path with
no permission check is a finding worth stating, but only after you searched
for one across the whole path.

## 5. Answer

Lead with a one or two sentence answer. Then a flow diagram when there are
three or more hops, followed by the detail.

```
Upload button (UploadForm.tsx:42)
  -> POST /api/files (routes/files.ts:18)
    -> FileService.store() (services/file.ts:67)
      -> S3 putObject + files table insert
  <- 201 with file id, UI shows thumbnail
```

Then, keeping only the sections that have content:

- **Key components**: each file on the path, its role, and the function that
  matters, with `file:line`
- **Data**: tables, collections or stores touched, and which code reads or
  writes them
- **Configuration**: variables and files that change the behavior
- **Security**: where auth and validation happen, and any gap
- **Errors**: how failures are caught and what the user sees
- **Gotchas**: surprising behavior, dead branches, comments the code
  contradicts

## Marking certainty

Each claim in the answer is one of three kinds, and the reader should be able
to tell which:

- **Traced**: you read the line. Cite it.
- **Inferred**: you reasoned from names or patterns. Say "likely" and why.
- **Not seen**: the code was not available. Name the missing file.

"This is the source of truth" or "only this function writes the table" needs a
search of the whole available tree behind it. If you searched only part of it,
say which part.

## Not for

- Changing the code. Plan a change with `change-plan`.
- Reviewing whether the code is right. That is `skeptical-review`.
- Questions with no code behind them, such as general framework behavior.
  Answer those from documentation and say that is the source.
