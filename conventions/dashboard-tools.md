---
brief: Implementation template for small single-user dashboard tools — Node/HTTP/watcher/JSON-state architecture, mutex discipline, hot-path rules, recoverable destructive ops, dashboard UX
triggers:
  - topic:dashboard-tool
  - topic:small-tool
  - topic:internal-dashboard
  - phrase:"build a dashboard"
  - phrase:"single-page tool"
  - phrase:"file watcher dashboard"
  - phrase:"local dev tool"
related:
  - conventions/html-output.md
  - mistake-patterns/2026-04-28-sherpa-data-loss-rca.md
tier: 2
category: conventions
updated: 2026-04-28
stale_after_days: 180
---

# Dashboard Tools

How to build small single-user dashboard tools (Node + Express + chokidar + JSON state file + vanilla-JS dashboard) without the data-loss class of bugs.

This document was forged in the wreckage of Screenshot Sherpa, where ignoring every rule below cost the user a deadline. **Apply these rules from line 1 of any new tool — retrofitting is hard.**

---

## Architecture defaults

```
┌──────────────────┐  loadManifest      ┌────────────────┐
│  Express server  │ ◀──────────────────│  state.json    │
│   (mutating      │ ──────────────────▶│  (atomic       │
│    requests      │  saveManifest      │   write+rename)│
│    serialized)   │                    └────────────────┘
└──────┬───────────┘                            ▲
       │ broadcast SSE                          │
       ▼                                        │
┌──────────────────┐                            │
│  Browser         │                            │
│   dashboard.html │                            │
│   (vanilla JS)   │                            │
└──────────────────┘                            │
                                                │
┌──────────────────┐  loadManifest              │
│  chokidar        │ ───────────────────────────┤
│  watcher (in     │ ◀──────────────────────────┘
│  same process)   │   saveManifest
└──────────────────┘
```

Single process, single state file, multiple writers — and they all need to coordinate.

## The non-negotiables

These are listed first because every one of them was violated in the Sherpa data-loss incident, and each violation contributed to data loss.

### 1. One mutex per state file. Wrap the entire load-mutate-save cycle.

```ts
// state.ts — the only safe API
const sessionLocks = new Map<string, Promise<unknown>>();

export async function withStateLock<T>(
  key: string,
  fn: () => Promise<T>,
): Promise<T> {
  const prev = sessionLocks.get(key) || Promise.resolve();
  const run = prev.then(() => fn());
  // Swallow rejections in the chain link only — the original caller still
  // sees its rejection — so one failing mutator doesn't poison the queue.
  sessionLocks.set(
    key,
    run.catch(() => undefined),
  );
  return run;
}

export async function updateState<T>(
  key: string,
  fn: (s: State) => Promise<T> | T,
): Promise<T> {
  return withStateLock(key, async () => {
    const s = await loadState(key);
    const out = await fn(s);
    await saveState(s);
    return out;
  });
}
```

Rules:

- The lock scopes `load → mutate → save`, NOT just `save`. Wrapping only `save` serializes writes but each handler still loaded a stale snapshot.
- Every writer uses the same lock. HTTP handlers, watcher events, background jobs, startup tasks. If any path skips the lock, you lose the guarantee.
- Prefer making the unsafe pattern impossible to express — e.g. expose only `updateState(fn)`, keep `load` + `save` as internal primitives.

### 2. GETs MUST NOT WRITE.

A GET handler that mutates state turns every dashboard auto-refresh into a writer that races every other writer.

- "Self-heal", "lazy-init", "fix-up if broken" patterns belong in startup OR a dedicated POST endpoint, never in a GET.
- Same rule for any HTTP method whose semantic is read-only. PUT/POST/DELETE = writes; everything else = no state mutation.
- The dashboard SSE broadcasting the new state is fine — that's the response side, not a mutation.

### 3. Atomic file writes only.

```ts
const tmp = filePath + ".tmp";
await fs.writeFile(tmp, JSON.stringify(state, null, 2), "utf-8");
await fs.rename(tmp, filePath); // POSIX-atomic on same filesystem
```

Never write directly to the target. A crash mid-write leaves an invalid JSON file, which loadState parses as garbage and self-heal "recovers" by wiping it. (Yes, this happened.)

### 4. Destructive ops rotate, don't unlink.

When "redo"/"replace" semantics overwrite a user file, rotate the previous version with a timestamp:

```ts
// Bad — unlink is unrecoverable:
try {
  await fs.unlink(dest);
} catch {}
await fs.rename(src, dest);

// Good — rotate the existing file out of the way:
try {
  await fs.access(dest);
  await fs.rename(dest, `${dest}.prev-${Date.now()}.bak`);
} catch {
  /* no prior file */
}
await fs.rename(src, dest);
```

Disk space is cheap; user data is not. Add a sweeper if rotated files accumulate, but never lose them by default.

### 5. Log every state-file write with caller + diff summary.

```ts
async function saveState(s: State, caller: string): Promise<void> {
  console.log(
    `[state] save by=${caller} at=${new Date().toISOString()} ` +
      `entries=${s.entries.length} captured=${s.entries.filter((e) => e.captured).length}`,
  );
  // ... atomic write ...
}
```

With 5+ writers and no audit trail, you cannot diagnose lost-update races. With one log line per save you see the race in the log immediately. Cheap. Mandatory.

### 6. Reject self-heal as a primary repair mechanism.

If you find yourself writing a function that detects and "fixes" corrupt state on every read, the better fix is to make the corruption impossible at the source — usually with the mutex in rule #1. Self-heal is a band-aid that adds complexity, hides bugs, and (as the Sherpa RCA shows) becomes its own bug source.

When self-heal is genuinely needed (e.g., recover from a previous-version data format), it goes at startup, runs once, and is loud about what it changed.

### 7. Test concurrency before shipping.

A 10-line test script that fires 5 concurrent POSTs + a watcher event reveals lost-update bugs in seconds:

```bash
for i in 1 2 3 4 5; do
  curl -X POST http://localhost:PORT/api/foo -d '{...}' &
done
touch watch-dir/test.png &
wait

# Verify: state.json is valid JSON, expected mutations are present, no field is null that shouldn't be
```

If this test produces inconsistent state, you have the bug. Don't ship until it passes 10 times in a row.

### 8. Env-mutating tools save the prior value, restore on stop, never restore to factory defaults.

If your tool changes a global system setting (`defaults write com.apple.screencapture location`, env vars exported into shell rc, system PATH entries, MCP `.mcp.json` injection, etc.), the lifecycle is **strictly**:

1. **On start**: read the current value, persist it to a sidecar file (`.saved-<setting-name>` in your session dir), then apply your override.
2. **On graceful stop**: read the sidecar and restore the user's saved value, then delete the sidecar.
3. **Detect self-capture on start**: if the current value already points at _your tool_ (e.g., a previous sherpa pending dir), do NOT save it as the prior value — that bakes in your override and the user can never get back to their real setting. Instead: try a previous saved sidecar from any session, falling back only to a sensible user-default (e.g. `~/Pictures/Screenshots`), NEVER to "the system factory default" (which on older macOS is `~/Desktop` and is not what most users expect).
4. **Crash recovery**: provide a standalone `restore` subcommand that reads the saved-value file independently of the main process so the user can recover from a `kill -9`.
5. **Don't use `kill -9` to stop the tool**: SIGKILL skips the shutdown handler, leaves the override in place, leaves the sidecar stale, and is what causes the self-capture-on-restart bug. Always SIGTERM.

Apply this to every global mutation: macOS `defaults`, env exports written to `~/.zenv` / `~/.zshrc`, `.mcp.json` injection, dock pinning, file-association changes, login items, anything `launchctl`-loaded.

```ts
// Sherpa-shaped pattern (cli.ts on start)
const SHERPA_HOME =
  process.env.SHERPA_HOME || path.join(HOME, "Code/Claude/screenshot-sherpa");
const PICTURES_DEFAULT = path.join(HOME, "Pictures", "Screenshots");
const sidecar = path.join(sessionDir, ".saved-location");

const current = await getCurrentLocation();
const isSelfCapture = current.startsWith(SHERPA_HOME + path.sep);

let saved: string;
if (isSelfCapture) {
  // Either prior sidecar (if it has a non-self value), or PICTURES_DEFAULT.
  const prior = await tryRead(sidecar);
  saved =
    prior && !prior.startsWith(SHERPA_HOME + path.sep)
      ? prior
      : PICTURES_DEFAULT;
  console.log(`WARN: previous run not cleaned up; using prior=${saved}`);
} else {
  saved = current;
}
await fs.writeFile(sidecar, saved, "utf-8");
await setLocation(myToolPendingDir);
```

---

## Process / scaffolding rules

### Bootstrap order — write infrastructure before features

Order matters. Write in this sequence, get each working before moving to the next:

1. **State file + atomic save + load.** Lowest layer. Test by writing/reading concurrently.
2. **Mutex.** Wrap state save behind a `withStateLock` API. Test with concurrent calls.
3. **HTTP server with one read endpoint + one write endpoint.** Wire write through mutex. Test.
4. **Filesystem watcher.** Wire its mutations through the same mutex. Test concurrent watcher + HTTP.
5. **Dashboard HTML.** Polling first, SSE later if needed. Static page from `/`.
6. **SSE broadcast.** Push state changes to dashboard. Verify dashboard auto-refresh doesn't loop-trigger writes (rule #2).
7. **First feature.**

If you skip step 2 ("I'll add the mutex later"), you'll spend 10× the time debugging races that step 2 would have prevented.

### State shape — keep it boring

- One JSON file per session. Flat-ish; deep nesting is harder to merge correctly.
- Every entry has a stable `id` (hash of content), not an array index. Reordering must not break references.
- User-edited fields and system-derived fields live side-by-side but the merge algorithm must explicitly preserve user fields when re-deriving from source.
- Status is an enum string (`"pending" | "captured" | "applied"`), not a boolean — you'll need a third state by week 2.
- Always include `createdAt` / `updatedAt` ISO timestamps. They cost nothing and save you in debugging.

### Dashboard rules — vanilla JS, single page, no framework

- One `dashboard.html` served from `/`. No build step. View-source readable. (See `conventions/html-output.md` for theme/toggle requirements.)
- Auto-refresh via SSE OR a 5s poll, never both. SSE only if you have a real reason; polling is simpler and cannot loop-trigger races as easily.
- localStorage for UI-only state (which tab is open, which filter is applied, theme). Server state is server-owned.
- Explicit confirm popovers for destructive ops, never `window.confirm` (jarring + can't be styled).
- Optimistic UI is forbidden until rule #1 (mutex) is verified — racy state will produce phantom items.

### Error handling — never silent

- Any path that swallows an error MUST log it with enough context to diagnose. `try { ... } catch {}` without a log is a silent failure factory.
- Distinguish ENOENT from other errors. ENOENT is often expected (file moved by another path); other errors are bugs.
- Surface user-visible errors in the dashboard with the actual reason, not "something went wrong". A user reading the error can often diagnose it themselves.

### Single source of truth — pick one

- The state file is authoritative. Don't mirror it in an in-memory cache that needs syncing.
- If you need an in-memory copy for performance, make it strictly a read-through cache that's invalidated on every write. Do not let handlers mutate the cached object directly — that becomes a second source of truth that drifts.

---

## Anti-patterns (i.e. what NOT to do)

| Anti-pattern                                                    | Why it's bad                                                 | What to do instead                                                                 |
| --------------------------------------------------------------- | ------------------------------------------------------------ | ---------------------------------------------------------------------------------- |
| `loadManifest → mutate → saveManifest` outside a lock           | Lost updates, silently                                       | `withStateLock(() => updateState(fn))`                                             |
| Self-heal called from a GET endpoint                            | Reads become writes; race every other writer                 | Self-heal at startup, optionally on explicit `/api/rescan`                         |
| `fs.unlink(target)` before `fs.rename(src, target)` for redo    | Unrecoverable; one stray click loses user data               | Rotate to `target.prev-<ts>.bak` then rename                                       |
| Watcher runs in a separate process                              | Cross-process mutex needed; complex                          | Same-process watcher; share the mutex                                              |
| State file in a directory the watcher watches                   | Watcher fires on its own state writes; recursive event loops | Place state file outside watch dir, or filter writes                               |
| In-memory state cache hand-synced with file                     | Two sources of truth drift; bug source                       | Single source: file. Re-load each handler under lock.                              |
| "Recovery" function that grew callers over time                 | Original safe site (startup) → unsafe sites (every read)     | Comment-locked allowed call sites; review every new caller                         |
| `window.confirm` / `window.alert`                               | Unstyled, blocks UI thread, no animation                     | Soft popover with confirm button                                                   |
| SSE broadcast → dashboard re-fetches `/api/state`               | If GET mutates, every push triggers a write                  | Either GET is read-only (rule #2), OR push the new state in the SSE payload itself |
| Dismissing user-reported symptoms based on partial verification | Loses trust + misses real bug                                | Reproduce user's exact path before contradicting                                   |

---

## Concrete example — Screenshot Sherpa skeleton (the right way)

```ts
// state.ts
import fs from "node:fs/promises";

export interface State {
  sessionId: string;
  entries: Entry[];
  // ...
}

const locks = new Map<string, Promise<unknown>>();

async function loadState(key: string): Promise<State> {
  const raw = await fs.readFile(pathFor(key), "utf-8");
  return JSON.parse(raw);
}

async function saveState(s: State, caller: string): Promise<void> {
  console.log(`[state] save by=${caller} entries=${s.entries.length}`);
  const p = pathFor(s.sessionId);
  const tmp = p + ".tmp";
  await fs.writeFile(tmp, JSON.stringify(s, null, 2), "utf-8");
  await fs.rename(tmp, p);
}

export async function withStateLock<T>(
  key: string,
  fn: () => Promise<T>,
): Promise<T> {
  const prev = locks.get(key) || Promise.resolve();
  const run = prev.then(() => fn());
  locks.set(
    key,
    run.catch(() => undefined),
  );
  return run;
}

export async function updateState<T>(
  key: string,
  caller: string,
  fn: (s: State) => Promise<T> | T,
): Promise<T> {
  return withStateLock(key, async () => {
    const s = await loadState(key);
    const out = await fn(s);
    await saveState(s, caller);
    return out;
  });
}

// Read-only — does NOT acquire the lock; loadState alone is safe for reads.
export const readState = loadState;
```

```ts
// server.ts
import express from "express";
import { readState, updateState, withStateLock } from "./state.js";

const app = express();
app.use(express.json());

// Mutating-request serializer — every POST/PUT/DELETE under /api/* runs
// end-to-end under the same per-session mutex the watcher uses.
app.use((req, res, next) => {
  if (req.method === "GET" || req.method === "HEAD") return next();
  if (!req.path.startsWith("/api/")) return next();
  withStateLock(
    SESSION_KEY,
    () =>
      new Promise<void>((resolve) => {
        res.on("finish", resolve);
        res.on("close", resolve);
        next();
      }),
  );
});

// READ-ONLY. Does not mutate. Self-heal lives at startup, not here.
app.get("/api/state", async (_req, res) => {
  res.json(await readState(SESSION_KEY));
});

app.post("/api/entries/:id/select", async (req, res) => {
  // The middleware already holds the lock — handlers can load+save freely.
  await updateState(SESSION_KEY, "select-entry", async (s) => {
    const e = s.entries.find((x) => x.id === req.params.id);
    if (e) e.selected = true;
  });
  res.json({ ok: true });
});

// Startup self-heal (if needed) — runs once, under the lock, before listen().
await withStateLock(SESSION_KEY, async () => {
  const s = await readState(SESSION_KEY);
  if (selfHeal(s)) await saveState(s, "startup-self-heal");
});

app.listen(PORT);
```

```ts
// watcher.ts
import chokidar from "chokidar";
import { withStateLock, updateState } from "./state.js";

chokidar
  .watch(WATCH_DIR, { ignoreInitial: true })
  .on("add", async (filePath) => {
    // Acquires the SAME lock the HTTP middleware uses — watcher and HTTP
    // never interleave their mutations.
    await updateState(SESSION_KEY, "watcher-add", async (s) => {
      // ...mutate s based on the new file...
      // Rotate any existing destination instead of unlinking.
      try {
        await fs.access(dest);
        await fs.rename(dest, `${dest}.prev-${Date.now()}.bak`);
      } catch {}
      await fs.rename(filePath, dest);
    });
  });
```

That skeleton, deployed in this order from day one, would have prevented the entire Sherpa data-loss incident.

---

## When this template does NOT apply

- **Multi-user tools**: a Map<key, Promise> mutex is per-process; for multi-user you need a real lock service (Redis, file lock with `proper-lockfile`, etc.).
- **High-throughput**: the chained-promise mutex serializes everything per session. Fine for a single user clicking around; not fine for 1000 req/s.
- **Distributed state**: if state lives across machines, you need a real database (SQLite even; not JSON).

For all small single-user dashboard tools — capture/edit/review/track/audit/triage tools — this template is the right starting point.

---

## Reference

- Full RCA of what happens when these rules are violated: [`mistake-patterns/2026-04-28-sherpa-data-loss-rca.md`](../mistake-patterns/2026-04-28-sherpa-data-loss-rca.md)
- HTML/theme/toggle rules for the dashboard page itself: [`conventions/html-output.md`](html-output.md)
