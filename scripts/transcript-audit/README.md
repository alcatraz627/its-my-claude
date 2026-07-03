# transcript-audit (`ta`)

A reusable way for Claude to query, mine, and tag its own transcript corpus, so
the recurring forensic digs (session reviews, hook-fire replays, false-positive
classification, N-day sweeps) become one tool instead of ad-hoc one-offs.

The corpus is `~/.claude/projects/`: 100 primary session transcripts (the main
conversations, ~350MB) plus ~830 nested sub-agent transcripts. `ta` reads them,
finds the turns matching a set of content filters, and gets out of the way. A
full-corpus content query runs in about 2 seconds.

## Subcommands

```
ta query   content query over turns (the load-bearing surface)
ta tag     bookmark a (transcript, turn) into the bookmarks ledger
ta tags    list those bookmarks
ta mine    emit ready-to-paste sub-agent mining prompts over matched turns
ta help    usage
```

### `ta query`

```
ta query [scope] [turn filters] [--format jsonl|table|count|files]
```

Scope (which transcripts):

| flag | meaning |
|---|---|
| `--project PATH\|SUBSTR` | substring matched against the encoded project-dir name |
| `--within DAYS` | transcripts modified within N days (default 30) |
| `--since ISO` | transcripts since an ISO date |
| `--all` | the whole corpus, no date bound |
| `--include-subagents` | also scan sub-agent transcripts (default: primary only) |

Turn filters (AND together):

| flag | meaning |
|---|---|
| `--role user\|assistant\|any` | which side `--match` applies to (default any) |
| `--tool NAME` | turns that invoked a tool_use of NAME (e.g. `Bash`, `Edit`) |
| `--match REGEX` | regex over the role-scoped text |
| `--user-match REGEX` | regex over the user text only |
| `--assistant-match REGEX` | regex over the assistant text only |
| `--no-prefilter` | skip the ripgrep pre-filter (see "Correctness" below) |
| `--limit N` | cap rows returned (0 = no cap) |

Each match row carries `{project, transcript_path, session_id, turn_index, ts,
role, snippet}`, where `snippet` is up to 200 chars of context around the hit.

Examples:

```bash
ta query --project enhancement-product --within 30 --user-match 'comment|prune' --format table
ta query --tool Bash --match 'rg -r' --within 14 --format count
ta query --all --assistant-match 'declared-ready' --format files
```

### `ta tag` / `ta tags`

The accumulation layer, so audits build on each other instead of restarting.
`ta tag` records that one turn is worth remembering; `ta tags` lists what's been
recorded.

```bash
ta tag --transcript /path/to/x.jsonl --turn 12 --label hook-feedback --note "muted the gate"
ta tags --label hook-feedback
```

Labels are free slugs (`hook-feedback`, `correction`, `prune-request`,
`over-comment`, ...). Bookmarks are written as ledger events to
`~/.claude/ledger/bookmarks.jsonl` and are equally readable through the shared
ledger reader:

```bash
ledger list --src bookmarks
ledger show bkmk-YYYYMMDD-HHMMSS-XX
ledger search hook-feedback
```

### `ta mine`

A scaffold for the "dispatch agents over the transcripts" pattern. It runs a
query, chunks the matched turns into batches, and prints one ready-to-paste
sub-agent prompt per batch. It does NOT dispatch; the parent agent or a Workflow
pastes each block into an `Agent` call.

```bash
ta mine --preset hook-feedback --within 7 --assistant-match 'hook|nudge|gate'
ta mine --preset corrections --project enhancement-product --within 30
```

Pair a preset with scoping flags. A bare `ta mine --preset X --within 7` matches
every turn in the window, which is usually more than you want. Options:
`--batch-size N` (turns per batch, default 30), `--snippet-len N` (context chars
per turn in the prompt, default 800), `--out-dir DIR` (base for the suggested
per-batch output paths).

Presets live in `presets/*.md`, one file per mining question. Each carries the
mining question plus the JSON output schema the sub-agent should return. Shipped
presets: `hook-feedback`, `corrections`.

## How a Workflow consumes `ta mine`

1. `ta mine --preset hook-feedback --within 7 --assistant-match 'hook|nudge|gate' > /tmp/mine.txt`
2. Each `### BATCH i/N` block is a self-contained agent prompt. It names the
   turns to inspect, embeds a snippet per turn, and specifies a distinct output
   path (`.../batch-0i.md`) so parallel agents don't collide.
3. Dispatch one `Agent` per batch (or feed the blocks to the `Workflow` tool,
   which caps concurrency). Each agent writes its findings to its output path and
   returns a 5-bullet abstract, per `rules/sub-agent-outputs.md`.
4. Consolidate the per-batch output files.

## The bookmark event schema

One JSON object per line in `~/.claude/ledger/bookmarks.jsonl`, following
`skills/shared/ledger-format.md` (required `id`/`ts` + a domain classifier;
empty fields omitted):

```json
{
  "id": "bkmk-20260703-150924-56",
  "ts": "2026-07-03T15:09:24Z",
  "kind": "bookmark",
  "project": "/Users/alcatraz627/.claude",
  "session_id": "69aeb3ea-...",
  "transcript": "/Users/.../projects/-Users-alcatraz627--claude/69aeb3ea-....jsonl",
  "turn_index": 3,
  "label": "hook-feedback",
  "note": "muted the gate"
}
```

`label` is the classifier, `note` is the summary. The stream is registered in
`scripts/ledger/ledger.sh` `_streams()`, so it joins the ledger family for free.

## Reuse map (what this does NOT re-implement)

| Concern | Owner |
|---|---|
| The turn model (what a turn is; its user text, assistant text, tools, session id, timestamp) | `scripts/hooks/replay/replay_lib.py` |
| Discovery + date-filter + checkpoint-join (which transcripts) | `scripts/checkpoint/list-transcripts.sh` |
| The bookmark ledger writer (id/ts/append) | `scripts/ledger/ledger-common.sh` |
| The bookmark ledger reader (list/show/search) | `scripts/ledger/ledger.sh` |

`ta` adds only the middle: a ripgrep pre-filter that narrows the file set, and a
precise per-turn match over the survivors. The turn accessors it needed and
`replay_lib` lacked (`turn_session_id`, `turn_ts`, `turn_user_text`,
`turn_assistant_text`, `turn_tool_names`) were added to `replay_lib` itself,
since that module owns the shared turn model.

## Correctness and speed

`ta query` streams one transcript at a time; it never loads the corpus into
memory at once. For any query with a text or tool filter, it first runs
ripgrep over the raw files to find the few that could match, then parses only
those and checks each turn precisely.

The ripgrep pre-filter matches raw (JSON-escaped) text. A regex whose match
depends on an escaped control character (a newline or tab that spans a JSON
string boundary) could be missed by the pre-filter. This is rare for word- and
phrase-oriented queries. When it matters, pass `--no-prefilter` to force a full
parse of every discovered transcript (still about 2 seconds over the primary
corpus). The pre-filter is sound in the other direction: it only ever shrinks
the file set on a clean ripgrep match, and falls back to "parse everything" when
ripgrep is unavailable or the regex is one it cannot evaluate.

Date filtering is at transcript-mtime granularity (it comes from
`list-transcripts.sh`). A long session whose file was touched recently can still
contain older turns; each row carries the turn's own `ts` if you need to
post-filter by turn time.
