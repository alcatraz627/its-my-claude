# Title brief: name a pull request

The input below describes one pull request from git alone: the repo, every commit subject, every file it changed with line counts, and its diff (cut short on very large changes). Write the title.

The reader is an engineer scanning a list of pull requests. The title tells them how the system behaves differently after this change.

## Shape

`type(scope): what the system now does`

- `type` is one of feat, fix, docs, refactor, test, ci, deploy, chore, security, perf.
- `scope` is the part of the system the change touches, one lower-case word in the repo's own vocabulary: `fix(templates):`, `fix(llm):`, `deploy(git):`. Never the repo's own name: in the vg repo, `fix(vg):` says nothing. Leave the scope out only when the change has no single home: `feat: ...`.
- After the colon: lower case, imperative verb first, at most 60 characters, no trailing period. The whole title stays under 72 characters.

## What the text after the colon must do

1. **State the behaviour change, not the bug report.** "support old .xls uploads", not ".xls uploads fail at Create job".
2. **Say the general effect, not the story behind it.** Leave out why it was needed, who hit it, and which incident prompted it.
3. **Cover the whole change.** Read the commit subjects and the full file list, not only the diff. A change across six dealer sites is not "read Ford parts list pages".
4. **Usually active voice.** "host change-map pages via pr-board's domain", not "change maps are published". Passive is acceptable when the actor would be filler ("let scheduled runs read vendor keys from the Keychain").
4a. **Name the new behaviour, not one constraint of it.** "use Vercel roles for S3 and email", not "read S3 without a stored AWS key".
4b. **Specific nouns over generic ones.** "reach Postgres from Vercel through a token-checked relay" beats "route database calls through an authenticated relay": "authenticated" makes the reader open the PR to learn how.
4c. **Describe the system, never address the reader.** "direct engineers to Open Swagger" confuses; "use Open Swagger, not the /docs proxy, for API docs" does not.
4d. **Spend the character budget well.** Short words ("infra pages", not "infrastructure docs"). Join two facets with "and" or "+", never ", plus": "ask before secret creation + update docs". A useful terse title beats a perfect long one.
5. **Be specific enough that two different changes could not share the title.** "update database connection options" fails this.
6. **Do not explain what a tool or feature is.** That belongs in the description.
7. **Keep literal names literal.** A check on `[tags]` is about `[tags]`, with the brackets.
8. **A list of three or more takes a comma before "and".** "cost, secrets, watch, and alerts".
9. **Plain words.** No slogans, no wordplay, no sales tone, and never the word "legacy". Avoid "the same way as" unless the change really is a like-for-like port.
10. **One clause.** No semicolon, no second colon, no bracket tags, no ticket or series numbers. A "+" joining two short facets is allowed (rule 4d).

## Examples the owner wrote

- `fix(templates): admins can now use customer's enhancement templates`
- `fix(excel): support old .xls uploads`
- `fix(llm): add model id to the cache key`
- `feat: host change-map pages via pr-board's domain`

## Output

Reply with the title alone on one line: no quotes, no explanation. Work only from the input. Do not guess at intent it does not show.
