---
name: past-sessions
description: Browse, search, and summarize past Claude Code conversation transcripts from ~/.claude/projects/. Use when the user asks "what did we do last time", "find the session where we…", "when did we fix X", or wants context from a prior conversation that wasn't captured in WAL/runtime-notes.
---

# Past Sessions

Every Claude Code conversation is written to a JSONL transcript at
`~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl`. This skill indexes
those transcripts so you can answer retrospective questions without re-reading
multi-MB files by hand.

## When to use

| User says… | Action |
|---|---|
| "What did we work on last week?" | `list-sessions.sh --since 2026-04-10` |
| "Find the session where we fixed the SSE race condition" | `list-sessions.sh --grep "SSE race"` |
| "Recap session `867071c7`" | Summarize that single transcript |
| "What was the first prompt when we debugged the auth hook?" | grep + show first prompt |

## Transcript schema (reference)

Each line is a JSON object with top-level fields:

- `type`: `user` \| `assistant` \| `system` \| `last-prompt` \| `queue-operation` \| `file-history-snapshot`
- `message.role`: `user` \| `assistant`
- `message.content`: **string** (simple prompt) OR **array** of `{type, text}` / `{type: "tool_use", …}` blocks
- `timestamp`: ISO-8601 UTC
- `sessionId`, `cwd`, `gitBranch`, `version`
- `uuid`, `parentUuid`, `isSidechain`, `toolUseID`

Project directories encode the cwd: `/Users/alcatraz627/.claude` → `-Users-alcatraz627--claude`.

## Step 1: List sessions

Run the helper script. It outputs TSV: `session_id<TAB>start_ts<TAB>end_ts<TAB>msg_count<TAB>first_prompt_preview`.

```bash
# Current project (derived from $PWD)
bash ~/.claude/skills/past-sessions/scripts/list-sessions.sh

# Specific project
bash ~/.claude/skills/past-sessions/scripts/list-sessions.sh --project -Users-alcatraz627-Code-myapp

# All projects
bash ~/.claude/skills/past-sessions/scripts/list-sessions.sh --all

# Filter by date
bash ~/.claude/skills/past-sessions/scripts/list-sessions.sh --since 2026-04-01

# Filter by keyword (case-insensitive, matches any message)
bash ~/.claude/skills/past-sessions/scripts/list-sessions.sh --grep "auth middleware"

# Combine
bash ~/.claude/skills/past-sessions/scripts/list-sessions.sh --since 2026-04-01 --grep "SSE"
```

Render the TSV as a table for the user (use `gum` if available, else a plain markdown table).

## Step 2: Summarize a specific session

Given a `session_id`, read its transcript and produce a narrative summary.

```bash
SESSION_ID="867071c7-fbda-4044-aef3-fe69f068ef16"
PROJECT_DIR=$(echo "$PWD" | sed 's|/|-|g')
FILE="$HOME/.claude/projects/$PROJECT_DIR/$SESSION_ID.jsonl"
```

Extract the essentials via jq rather than slurping the whole file (they can be >10MB):

```bash
# Count user turns
jq -r 'select(.type == "user" and (.message.content | type == "string")) | .message.content' "$FILE" \
  | grep -vE '^<command-|^\[Request interrupted' | wc -l

# First 5 user prompts
jq -r 'select(.type == "user" and (.message.content | type == "string")) | .message.content' "$FILE" \
  | grep -vE '^<command-|^\[Request interrupted' | head -5

# Tool calls by name (top 10)
jq -r '
  select(.type == "assistant" and (.message.content | type == "array"))
  | .message.content[] | select(.type == "tool_use") | .name
' "$FILE" | sort | uniq -c | sort -rn | head -10

# Files touched (via Edit/Write tool uses)
jq -r '
  select(.type == "assistant" and (.message.content | type == "array"))
  | .message.content[]
  | select(.type == "tool_use" and (.name == "Edit" or .name == "Write"))
  | .input.file_path
' "$FILE" | sort -u
```

Then synthesize: goal of the session, what got done, files changed, tools used most, final state.

## Step 3: Search across all sessions

```bash
# Find every session that mentions a keyword
bash ~/.claude/skills/past-sessions/scripts/list-sessions.sh --all --grep "<keyword>"

# Find the exact line containing the match (useful for "when did we decide X")
grep -l "<keyword>" ~/.claude/projects/*/*.jsonl \
  | while read -r f; do
      echo "=== $(basename "$f" .jsonl) ==="
      grep -oE '"timestamp":"[^"]*"|"content":"[^"]{0,200}"' "$f" \
        | grep -B1 "<keyword>" | head -4
    done
```

## Complement: events.jsonl

For **cross-project** questions ("when did I last run /commit?"), the event log
is faster than transcripts:

```bash
LOG=$(bash ~/.claude/scripts/find-events-log.sh)
jq -c 'select(.event == "UserPromptSubmit")' "$LOG" | grep commit | tail -10
```

Events log = lightweight metadata timeline. Transcripts = full conversation content.
Use the log to narrow; use transcripts to read the details.

## Notes & gotchas

- **Content is sometimes a string, sometimes an array.** User prompts are usually strings; assistant replies are always arrays (text + tool_use blocks). Always guard with `if type == "string" then . else …`.
- **Command wrappers pollute "first prompt".** Skip lines starting with `<command-` (slash commands the user ran) to surface the actual user text.
- **Sidechain messages.** `isSidechain: true` = agent-spawned subagent turns. Filter them out when counting "user turns" to get the human message count.
- **Sessions can span days.** `start_ts` vs `end_ts` can differ; a single transcript may contain several `/clear` events (signaled by a fresh system message + new first-prompt in the same file).
- **Read only, never mutate.** This skill must never edit or delete transcripts.
- **Don't cat whole files.** Even short sessions are ~100KB of JSONL; long ones are 10MB+. Always go through jq filters.

## Related

- `/catchup` — restores session state from a checkpoint file (in-session recovery; different scope)
- `/session-stats` — analytics for the **current** session, not past ones
- `~/.claude/events.jsonl` — metadata log for every event (complement to full transcripts)
