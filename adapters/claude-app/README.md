# gcc-chat: this config for claude.ai chat

A plugin carrying the parts of this config that work without local scripts,
for claude.ai on the web, the desktop app's chat, and Claude Code. It holds
skills only. Claude loads each skill when a conversation matches its
description, or you pick one from the `/` menu.

| Skill | Loads when | Source in this repo |
|---|---|---|
| `house-rules` | Claiming how something works, calling work done, claiming absence, sizing a change, pushing back | `rules/` (11 rules, condensed) |
| `plain-writing` | Drafting or cleaning up docs, READMEs, reports, PR text, emails | `conventions/doc-writing.md`, `skills/ste-writing/` |
| `intake` | Before non-trivial work, or when the last answer missed | `skills/intake/` |
| `probe` | A fix did not work or a cause is a guess | `skills/probe/` |
| `decision-bundle` | Work is blocked on the user's decisions | `skills/gated-plan/` |
| `recommend` | "What now", "what do you need from me" | `skills/recommend/` |

Rules about how answers are shaped (answer first, intent over wording, no
needless halts) are not here. They live in the claude.ai profile Instructions,
which load into every conversation already.

## Install

1. Open [claude.ai/customize/plugins](https://claude.ai/customize/plugins).
2. Select **Add**, then **Add marketplace**, and enter `alcatraz627/its-my-claude`.
3. Find `gcc-chat` in the list and select **Add**.
4. Turn on **Sync automatically** for the marketplace, so pushes to `main`
   reach your account without another step.

To check it worked, start a new chat, type `/`, then `gcc-chat`. The six
skills should be listed.

## Turn it off

**Customize > Plugins > gcc-chat**, then the **Disable plugin** toggle. That
applies to your whole account, not one surface.

## Change it

Edit a `SKILL.md` here and push to `main`. Keep each `description` at 200
characters or fewer, because claude.ai cuts longer ones. Check the plugin
before pushing:

```bash
claude plugin validate .
```

Run that from the repo root. A skill that needs `~/.claude/scripts/`, a local
port or a Mac-only tool does not belong here, because chat cannot run it.
