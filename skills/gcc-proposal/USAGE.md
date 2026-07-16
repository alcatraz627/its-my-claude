# /gcc-proposal — Usage Guide

## What it does

Files a `~/.claude` improvement proposal into the backlog via `propose.sh`, deriving the
title, category, effort, and cross-links from a rough description (or from the current
conversation), so you never have to remember the script or its flags.

## Usage

```
/gcc-proposal [rough description of the improvement]
```

| Argument            | Type     | Description                                                    |
| ------------------- | -------- | -------------------------------------------------------------- |
| `rough description` | optional | The idea, however rough. Omit to derive from the conversation. |

## Examples

### Example 1: explicit idea

```
/gcc-proposal the statusline should show when the broker is down
```

Formalizes to a titled, categorized proposal and files it immediately. Prints
`✓ filed prop-20260715-...` with the title.

### Example 2: bare invocation after a friction moment

```
/gcc-proposal
```

Right after something went sideways in the session. The skill derives the proposal from
the recent friction, shows the formalized title + body one-liner, asks a single
"File this?", then files.

### Example 3: cross-linked to an atone slug

```
/gcc-proposal mutation-test restores keep using git checkout, hook-block it
```

If the conversation references an atone slug or prior proposal, the filed entry carries
`link:atone:<slug>` / `link:prop:<id>` tags so triage sees the corroboration.

## Caveats

- Filing only — reviewing, promoting, and dropping proposals is `/backlog-triage`'s job.
- Refuses non-gcc ideas (project-local fixes, one-off tasks) rather than polluting the
  backlog.
- Never sets value/priority (computed at triage) and never edits `proposals.jsonl` by
  hand.
- One proposal per invocation.

## Dependencies

| Dependency                     | Type         | Notes                                  |
| ------------------------------ | ------------ | -------------------------------------- |
| `~/.claude/scripts/propose.sh` | Script       | The only writer to the backlog         |
| GUIDELINES.md                  | Shared rules | Read at start of every run             |
| `/backlog-triage`              | Skill        | Downstream consumer of filed proposals |

## Tips

- Invoke it the moment friction happens — the conversation context makes the derived
  proposal sharper than a reconstructed one later.
- Agents mid-task should call `propose.sh` directly; this skill is the human-ergonomics
  wrapper.
