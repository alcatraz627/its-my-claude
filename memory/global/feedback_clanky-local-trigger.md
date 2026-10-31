---
name: clanky-local-trigger
description: Start Clanky PR reviews with the local clanky-review.py, not a /claude-bot review PR comment (discouraged, not banned)
metadata:
  type: feedback
---

Start a Clanky review locally: `python3 ~/Code/Versable/slack-automation/scripts/clanky-review.py versable-git/<repo>#<n> --notify <ipc alias>`, then `python3 ~/.claude/scripts/hooks/pr-review-gate.py wait <repo>#<n>`. Posting a `/claude-bot review` (or `/clanky review`) comment on the PR is discouraged, not banned.

**Why:** owner, 2026-10-30: "commenting on the PR for a review trigger needs to be discouraged in favor of the local toolkit". Comments add noise to the PR thread under the owner's account; the local run posts nothing.

**How to apply:** after any push that needs a review, run the local script. Fall back to the comment only when the script cannot run (no gcloud), and say so. The pr-review-gate retrigger message now prints the local command. See [[feedback_background-review-waits]].
