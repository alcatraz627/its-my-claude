# Small single-user dashboard tools

A template for small local tools of the shape: a Node HTTP server, a
filesystem watcher, one JSON state file, and a vanilla-JS dashboard page.
Capture, review, triage, tracking and audit tools all fit it.

Every rule here was broken at once in one screenshot-capture tool, and the
result was lost user data the night before a deadline. Apply them from the
first line. Retrofitting is hard.

## Architecture

```
┌──────────────────┐   load / save     ┌──────────────────┐
│ HTTP server      │ ◀───────────────▶ │ state.json       │
│ (mutations run   │   under one lock  │ (atomic write    │
│  serialized)     │                   │  then rename)    │
└───────┬──────────┘                   └──────────────────┘
        │ push state (SSE) or poll               ▲
        ▼                                        │ same lock
┌──────────────────┐                   ┌─────────┴────────┐
│ dashboard.html   │                   │ file watcher     │
│ (vanilla JS)     │                   │ (same process)   │
└──────────────────┘                   └──────────────────┘
```

One process, one state file, several writers. They all coordinate through one
lock.

## The non-negotiables

**1. One lock per state file, around the whole load, mutate, save cycle.**

```ts
const locks = new Map<string, Promise<unknown>>();

export function withStateLock<T>(key: string, fn: () => Promise<T>): Promise<T> {
  const run = (locks.get(key) ?? Promise.resolve()).then(fn);
  locks.set(key, run.catch(() => undefined)); // one failure does not poison the queue
  return run;
}

export function updateState<T>(key: string, caller: string, fn: (s: State) => T | Promise<T>) {
  return withStateLock(key, async () => {
    const s = await loadState(key);
    const out = await fn(s);
    await saveState(s, caller);
    return out;
  });
}
```

Locking only the save serializes writes, but every handler still loaded a
stale copy. Every writer uses the same lock: HTTP handlers, watcher events,
background jobs, startup tasks. Best of all, export only `updateState` so the
unsafe pattern cannot be written.

**2. GET handlers never write.** A GET that mutates turns every dashboard
refresh into a writer racing all the others. "Self-heal" and "lazy init"
belong at startup or behind an explicit POST.

**3. Atomic writes only.** Write to `file.tmp`, then `rename` onto the target,
which is atomic on one filesystem. A crash mid-write otherwise leaves broken
JSON, which a self-heal then "recovers" by wiping. That happened.

**4. Destructive operations rotate, never unlink.** When a redo or replace
overwrites a user file, move the old one to `dest.prev-<timestamp>.bak` first.
Disk is cheap and user data is not. Add a sweeper if backups pile up.

**5. Log every state write with its caller and a summary.**
`[state] save by=watcher-add at=<iso> entries=42 captured=17`. With five
writers and no trail, a lost update cannot be diagnosed. With one line per
save, the race is visible in the log.

**6. Self-heal is not a repair strategy.** Make corruption impossible instead,
usually with rule 1. A needed migration runs once at startup and says loudly
what it changed.

**7. Test concurrency before shipping.** Fire five concurrent POSTs and a
watcher event, check the state file is valid and every mutation landed, and
pass ten runs in a row.

```bash
for i in 1 2 3 4 5; do curl -s -X POST localhost:$PORT/api/item -d "{\"n\":$i}" & done
touch watch-dir/probe.png & wait
```

**8. A tool that changes a global setting saves and restores it.** On start,
save the current value to a sidecar file, then apply the override. On a clean
stop, restore it and delete the sidecar. If the current value already points
at this tool, a past run did not clean up: restore from an older sidecar or a
sensible user default, never the factory default. Ship a standalone `restore`
command for recovery after a hard kill, and stop with SIGTERM, never SIGKILL.
This covers OS preferences, shell rc exports, config-file injection and login
items.

## Build order: infrastructure before features

1. State file with atomic save and load. Test concurrent reads and writes.
2. The lock. Test with concurrent calls.
3. HTTP server with one read and one write endpoint, the write through the lock.
4. The watcher, through the same lock. Test watcher and HTTP together.
5. The dashboard page, polling first.
6. Server push if needed. Confirm a refresh never triggers a write.
7. The first feature.

Skipping step 2 "for now" costs ten times as long in race debugging later.

## State shape: boring on purpose

- One JSON file per session, kept fairly flat.
- Every entry has a stable `id` (a content hash), never an array index.
- User-edited fields sit beside derived ones, and re-deriving preserves the
  user's fields explicitly.
- Status is an enum string (`"pending" | "captured" | "applied"`), not a
  boolean. A third state arrives by week two.
- `createdAt` and `updatedAt` on everything.

## The dashboard page

- One `dashboard.html` served from `/`, no build step, readable source. Theme
  and toggle rules are in the `design-reference` skill.
- Refresh by server push or a 5-second poll, never both. Polling is simpler.
- Browser storage holds UI state only (open tab, filter, theme). Server state
  belongs to the server.
- Destructive actions get a styled confirm popover, never `window.confirm`.
- No optimistic UI until the lock is proven, or racing state shows phantom
  items.
- Errors show their real reason in the page, never "something went wrong".
- A `catch {}` with no log is a silent-failure factory. A missing file
  (ENOENT) may be expected. Any other error is a bug.
- The state file is the one source of truth. An in-memory copy, if any, is a
  read-through cache invalidated on every write, never edited directly.

## Anti-patterns beyond the rules above

| Anti-pattern | Why it hurts | Instead |
|---|---|---|
| Watcher in a separate process | Needs a cross-process lock | Same process, shared lock |
| State file inside the watched folder | The watcher fires on its own writes | Keep it outside, or filter |
| A "recovery" function that grew callers | Safe at startup, unsafe on every read | Restrict and review its call sites |
| Push triggers a re-fetch of a mutating GET | Every push causes a write | Read-only GET, or send state in the push |
| Dismissing a reported symptom after a partial check | Misses the real bug, loses trust | Reproduce the user's exact path first |

## When this template does not fit

- **Several users:** the promise lock is per process. Use a real lock or a database.
- **High throughput:** the lock serializes everything. Fine for one person clicking.
- **State across machines:** use a real database. SQLite is enough to start.
