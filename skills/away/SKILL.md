---
name: away
description: The owner says when they expect to be back, roughly or exactly, so keep-warm holds this session for about that long or dumps it. Never stops work in progress. Use for /away, or when the owner mentions stepping away ("back in 2h", "done for today", "back after dinner, maybe").
allowed-tools: Bash
user-invocable: true
argument-hint: "[3h | 90m | 21:30 | tonight | done | soon | free text]"
---

# /away: tell this session when you expect to be back

**Do not stop what you are doing.** Record the time in one command and carry on with
the work exactly as before. If the session was idle, reply in one line. The hold only
takes effect once the session goes idle, and the owner's next message clears it.

Turn what the owner said into one of these:

| They said | Run |
|---|---|
| A time they stated plainly: "3h", "90m", "21:30" | `python3 ~/.claude/scripts/keepwarm/keepwarm.py away 3h "why"` |
| Something vague: "back after dinner, maybe", "tonight" | Pick a time, and add `--soft`: `... away 2h --soft "after dinner"` |
| "done", "that's it for today", "not coming back to this" | `... away done "why"` |
| "soon", or no real idea | `... away soon` |

If the command reports a cost, repeat that line to the owner once. Their choice stands.

`done` means finish the work here first, then dump and stop. It never skips the dump.

`python3 ~/.claude/scripts/keepwarm/keepwarm.py plan` prints what the next keep-warm
fire would do and why. How it all fits together: `~/.claude/features/keepwarm.md`.
