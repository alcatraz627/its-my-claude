---
brief: The owner comments on markdown files in better-file-browser (bfb), like a Google Doc. Agents read and answer those threads from any terminal with `bfb-docs comments` (inbox, list, show, reply, done, new, suggest). Threads live in a `<file>.md.bfb.json` companion next to the document; change it only through bfb-docs.
triggers:
  - tool:bfb-docs
  - topic:bfb
  - topic:markdown-comments
  - phrase:"comment on md"
  - phrase:"review in bfb"
  - phrase:"comments in bfb"
related:
  - ~/Code/better-file-browser/docs/comments-for-agents.md
---

# Comments on markdown, from bfb

The owner reviews plans, reports and notes by commenting on them in
better-file-browser, the Chrome extension that renders local files. Those
comments are for agents to answer, wherever the agent runs.

- **Where they live:** `plan.md` keeps its threads in `plan.md.bfb.json` beside
  it. Never edit that file by hand: `bfb-docs` locks, merges and keeps every
  thread. A comment never changes the document itself.
- **What to run:**
  ```
  bfb-docs comments inbox                         # threads waiting on you, every folder
  bfb-docs comments list plan.md                  # open threads in one file
  bfb-docs comments reply plan.md <thread> "..."  # #tag, @mention, @due, /done work in the text
  bfb-docs comments done plan.md <thread> "what you did"
  bfb-docs comments new plan.md --quote "exact words" "your comment"
  bfb-docs comments suggest plan.md --quote "exact words" --replace "new words" "why"
  ```
  Add `--json` for machine output. `bfb-docs whoami` shows who you write as.
- **When to check:** asked to "review comments", "see my comments", or handed a
  document the owner said they commented on, run `inbox` first.

The full contract (moving quoted text, suggestions, the companion format) is
`~/Code/better-file-browser/docs/comments-for-agents.md`.
