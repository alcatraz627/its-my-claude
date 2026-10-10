---
name: local-transcripts
description: Find and inspect past local Codex and Claude Code conversations when the owner asks what an agent said, decided, tried, or missed. Use for cross-session recall and transcript evidence, not ChatGPT web history.
---

# Local agent transcripts

Search first with the read-only command below. It covers Codex rollout JSONL under `/Users/alcatraz627/.codex/sessions` and `/Users/alcatraz627/.codex/archived_sessions`, plus Claude Code transcripts under `/Users/alcatraz627/.claude/projects`. Claude search reuses the existing `ta` turn parser. The default searches both primary corpora, including archived Codex sessions, across all dates. Subagents are opt-in.

```sh
python3 -B /Users/alcatraz627/.claude/adapters/codex/bin/transcript-search.py 'distinct phrase' --role user --limit 20
```

Narrow with `--source codex|claude`, `--project PATH_SUBSTRING`, `--session ID_PREFIX`, or `--days N`. Use `--include-subagents` when the main sessions do not answer the question. `--format jsonl` returns the exact transcript path and either a Codex `line` or Claude `turn_index`. `--format files` returns only absolute source paths. Search is literal and case-insensitive; use a distinctive phrase or repeat with a synonym.

Read a hit without dumping a whole JSONL file:

```sh
python3 -B /Users/alcatraz627/.claude/adapters/codex/bin/transcript-search.py show /absolute/transcript.jsonl --line 123
python3 -B /Users/alcatraz627/.claude/adapters/codex/bin/transcript-search.py show /absolute/transcript.jsonl --turn 4
```

For a tool call, tool result, hook payload, or other non-message event, repeat the phrase with `--raw`. This searches all JSONL events and returns source line numbers. Open one with `show /absolute/transcript.jsonl --raw-line N`. Raw snippets can include JSON escaping; `show` prints the bounded original line. Add `--include-subagents` if the evidence came from another agent.

The source path and line or turn identify evidence; cite them in the answer. Search results are snippets, so open the relevant hit before inferring a decision or outcome. A missing hit is not proof of absence: try synonyms, the other source, `--raw`, and `--include-subagents`. This tool reads only local Codex and Claude Code transcripts. It does not search ChatGPT web chats or other agent runtimes.
