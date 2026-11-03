---
name: feedback_internal-tools-get-real-ui
description: "Small internal tools get a full UI design pass, not just the page kit; passing the page check is not enough"
metadata:
  node_type: memory
  type: feedback
  originSessionId: e3b8781b-a139-41f0-bfe5-576acd262cce
  modified: 2026-11-03T06:30:00.000Z
---

A local tool, hub or one-file page gets the same UI care as a product page. Owner, 2026-11-01, on the service hub: "needs a much better UI, the html and ui best practices for various aspects. Sigh, I have to keep repeating this feedback".

**Why:** the first hub was a kit table with a blue button and a dropdown on every row. It passed the page check and a functional walk and was rejected on sight. This note lived in one project's memory until 2026-11-03, so sessions in the repos that build these tools never saw it.

**How to apply:** start from `~/.claude/conventions/ui-brief.md`, which a hook now injects on the first UI edit. Do not bring back a blue button and a boxed dropdown on every row.
