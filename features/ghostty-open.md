---
brief: How agents and scheduled jobs open a terminal. ghostty-open adds a background tab to the owner's window; a guard blocks stray Ghostty copies and any kill of the owner's Ghostty.
triggers:
  - topic:ghostty
  - phrase:"open -na"
  - phrase:"ghostty-open"
tier: 2
category: features
updated: 2026-11-02
stale_after_days: 180
---

# Opening a terminal from an agent

Use `~/.claude/scripts/ghostty/ghostty-open --cwd DIR -- COMMAND`. It adds a tab to
the owner's front Ghostty window and leaves the tab they were on selected. With no
command, the tab is an ordinary shell in that folder.

**Why not `open -na Ghostty`.** It starts a second copy of the whole app, with its
own Dock icon. With `window-save-state = always` in the owner's config, that copy
also restores a duplicate of their tabs and folders.

**If scripting fails**, for example a background job without Automation access, the
opener falls back to one separate copy with restore turned off. It refuses to start
a third. It also refuses past 6 opens in 10 minutes, because that is a loop.
`--bulk` lifts the rate limit for a restore the owner asked for (`zrecover restore`).

**The guard.** `hooks/guard-ghostty.sh` blocks agent commands that start a Ghostty
copy, or that kill, quit or close Ghostty, including `kill` of its bare pid. Mute it
with `touch ~/.claude/.no-ghostty-gate`.

**Not covered:** Claude Code's own deep-link launcher runs `open -na` from inside the
app, with restore off, so neither the guard nor the opener can reach it.

Log: `~/.claude/logs/ghostty-open.jsonl`. Tests:
`bash ~/.claude/scripts/hooks/guard-ghostty.test.sh`.
