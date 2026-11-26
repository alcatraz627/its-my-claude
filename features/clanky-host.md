---
brief: Put a local screenshot on Clanky's file host and get a link that renders in a PR body, private repos included
triggers:
  - tool:clanky-host
  - topic:pr-screenshots
  - phrase:"host this image"
related: []
tier: 2
category: features
updated: 2026-11-04
stale_after_days: 180
---

# clanky-host: pictures for pull requests

GitHub cannot show a raw link to an image in a private repo to everyone, and an image has to live somewhere. This command puts it on Clanky's file host and prints markdown to paste into the PR body.

```bash
clanky-host shots/home.png shots/editor.png   # one markdown image line per file
clanky-host --url shots/home.png              # the bare link
```

- **How long it lasts:** the link holds for ten years and the file is never swept, so a merged PR keeps its pictures.
- **Who can open it:** anyone holding the link. Send only what is fine to share that way, such as staging screens with test data.
- **What it needs:** gcloud signed in with Secret Manager access in `versable-forge-v6`. The command signs each upload with the service's link key and never prints it.
- **Source:** the command is `~/.claude/scripts/clanky-host/clanky-host`. The route is `/upload` in `pr-board/filehost.py` in slack-automation.
