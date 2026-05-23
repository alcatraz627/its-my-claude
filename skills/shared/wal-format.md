# WAL Format Reference

Write-Ahead Log captures the agent's actions in near-real-time so a future
agent (human-invoked or after `/clear`) can resume without losing context.

Since 2026-04-17 the canonical format is **JSONL** — one event per line, ideal
for piping through `jq`. The legacy **markdown** format is retained so that
older `.claude/wal.md` files continue to work; new sessions default to `.claude/wal.jsonl`.

---

## Default: `.claude/wal.jsonl`

### Schema

One JSON object per line. All entries share these fields:

| Field | Type | Description |
|---|---|---|
| `ts` | ISO-8601 string | UTC timestamp (e.g. `2026-04-17T14:05:22Z`) |
| `kind` | string | `session_start` \| `action` \| `decision` \| `agent_start` \| `agent_done` \| `checkpoint` \| `session_end` |
| `session_id` | string | `<keyword>-<keyword>-<2hex>` (from `shared/doc-naming.md`) |

Kind-specific fields below. Omit empty fields — JSONL compresses well when sparse.

### `session_start`

```json
{"ts":"2026-04-17T14:05:22Z","kind":"session_start","session_id":"fix-auth-3b","user":"Add an auth guard to /api/users","intent":"Implement auth middleware for the users route"}
```

### `action`

```json
{"ts":"2026-04-17T14:06:10Z","kind":"action","session_id":"fix-auth-3b","verb":"read","target":"src/api/route.ts","outcome":"found auth middleware at L42"}
{"ts":"2026-04-17T14:07:03Z","kind":"action","session_id":"fix-auth-3b","verb":"edit","target":"src/lib/db.ts","lines":"L15-20","outcome":"added connection pooling"}
{"ts":"2026-04-17T14:08:41Z","kind":"action","session_id":"fix-auth-3b","verb":"bash","target":"npm test","outcome":"14 pass, 0 fail"}
```

`verb` values: `read` | `write` | `edit` | `bash` | `commit` | `glob` | `grep`

### `decision`

```json
{"ts":"2026-04-17T14:10:00Z","kind":"decision","session_id":"fix-auth-3b","choice":"Zod over yup","why":"smaller bundle, better TS inference"}
```

### `agent_start` / `agent_done`

```json
{"ts":"2026-04-17T14:12:00Z","kind":"agent_start","session_id":"fix-auth-3b","agent":"explore","task":"find all AuthContext usages"}
{"ts":"2026-04-17T14:13:45Z","kind":"agent_done","session_id":"fix-auth-3b","agent":"explore","result":"7 files returned"}
```

### `checkpoint`

```json
{"ts":"2026-04-17T14:20:00Z","kind":"checkpoint","session_id":"fix-auth-3b","goal":"Add auth guard to /api/users","done":["Read route.ts","Wrote middleware","Added tests"],"current":"Wiring middleware in route handler","next":"Run full test suite","blockers":[],"learnings":["Zod's inference saved the custom type definition we had planned"]}
```

Keep checkpoints to one line. If `done`/`next` lists grow huge, truncate — the WAL is not an audit log.

### `session_end`

```json
{"ts":"2026-04-17T14:45:00Z","kind":"session_end","session_id":"fix-auth-3b"}
```

### Reading with jq

```bash
WAL=.claude/wal.jsonl

# Last checkpoint for resuming
jq -c 'select(.kind == "checkpoint")' "$WAL" | tail -1

# All decisions in this session
jq -c 'select(.kind == "decision" and .session_id == "fix-auth-3b")' "$WAL"

# Files touched
jq -r 'select(.kind == "action" and (.verb == "edit" or .verb == "write")) | .target' "$WAL" | sort -u

# Session durations
jq -c 'select(.kind == "session_start" or .kind == "session_end") | {ts, kind, session_id}' "$WAL"
```

### Writing with the helper (preferred)

`~/.claude/scripts/wal/wal.sh` wraps `jq -cn` so escaping is always correct. Never
hand-compose JSON in a WAL line — use the helper:

```bash
# Auto-detects ./.claude/wal.jsonl when CWD has a .claude/ subdir,
# otherwise writes to ~/.claude/wal.jsonl.
wal=~/.claude/scripts/wal/wal.sh

bash $wal session_start fix-auth-3b "Add auth guard" "Implement mw for /api/users"
bash $wal action        fix-auth-3b read src/api/route.ts "found mw at L42"
bash $wal decision      fix-auth-3b "Zod over yup" "smaller bundle"
bash $wal agent_start   fix-auth-3b explore "find AuthContext usages"
bash $wal agent_done    fix-auth-3b explore "7 files returned"
# Arrays use pipe-separated values: "a|b|c"
bash $wal checkpoint    fix-auth-3b "Add guard" "Read route|Wrote mw|Tests pass" "Wiring mw" "Run suite" "" "Zod saved the custom type"
bash $wal session_end   fix-auth-3b
```

Override the target file with `WAL_FILE=<path> wal.sh ...` if auto-detection is wrong.

### When to write (JSONL)

| Trigger | Line to append |
|---|---|
| Session start | `session_start` |
| Every non-trivial tool call | `action` |
| Every deliberate choice with reasoning | `decision` |
| Sub-agent dispatch / return | `agent_start` / `agent_done` |
| Every ~15-20 actions, or before risky ops | `checkpoint` |
| Session end | Final `checkpoint`, then `session_end` |

Keep only the last 2 sessions in the file. Prune older entries when starting a new session (or let a Stop hook rotate them).

---

## Legacy: `.claude/wal.md`

Still honored by `/catchup` if `wal.jsonl` is missing. Format spec kept below for
reference — do NOT use for new WALs.

### File Header

```markdown
# WAL — [project name]
<!-- Auto-maintained by Claude. Read by /catchup for session resumption. -->
```

### Session Block

```markdown
## Session: YYYY-MM-DD HH:MM [session-id]
> User: [verbatim first user message, max 300 chars]
> Intent: [agent's one-line interpretation]
```

### Action Log (one line each)

```markdown
[HH:MM] READ src/api/route.ts — found auth middleware at L42
[HH:MM] WRITE src/api/users/route.ts — new GET handler for user list
[HH:MM] EDIT src/lib/db.ts L15-20 — added connection pooling config
[HH:MM] BASH npm test — 14 pass, 0 fail
[HH:MM] AGENT(explore) "find all AuthContext usages" — 7 files returned
[HH:MM] AGENT_DONE(explore) — 7 files returned
[HH:MM] DECISION: Zod over yup for validation (smaller bundle, better TS inference)
[HH:MM] COMMIT "Add user list endpoint with auth guard"
```

### Checkpoint Block

```markdown
=== CHECKPOINT [HH:MM] ===
Goal: [overall goal, one line]
Done: [completed items, bullet list]
Current: [what's in progress right now]
Next: [what comes after current]
Blockers: [any issues, or "None"]
Learnings: [1-2 surprising discoveries, if any]
===
```

Same triggers apply as the JSONL table above — but written as markdown blocks.

---

## Migration notes

- **No one-shot migration.** Old markdown WALs keep working; new sessions start JSONL.
- **`/catchup` is dual-mode.** It tries `.claude/wal.jsonl` first, falls back to `.claude/wal.md`. See `skills/catchup/SKILL.md` Phase 0.5.
- **Mixing in one project is fine.** If you like, delete `wal.md` once you've confirmed `wal.jsonl` works — never required.
- **Parsers beware.** Old skills that `grep -B2 "^=== CHECKPOINT"` will only hit markdown files. Update them to detect the `.jsonl` suffix and `jq` it instead.
