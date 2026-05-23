---
name: Never commit unless explicitly asked
description: "Do not push" means no git operations at all — not "commit but don't push." Only commit when user says "commit."
type: feedback
---

Never commit unless the user explicitly says "commit." Phrases like "do not push," "add it to doc," or "save this" mean "make the file changes" — not "commit them to git."

**Why:** User said "add it to doc, do not push" and agent committed anyway, interpreting "do not push" as "commit but don't push." The user had already pushed the branch before realizing the unwanted commit was there.

**How to apply:** When the user gives instructions that don't include the word "commit," do not run `git add` or `git commit`. If ambiguous, ask. The global CLAUDE.md rule "NEVER commit changes unless the user explicitly asks" already covers this — follow it strictly.
