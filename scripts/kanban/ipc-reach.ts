// Whether an answer can still reach the session that asked for it, read from
// the claude-ipc registry. Shared by the kanban server and the decision-page
// command so both tell the same story about the same session.

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

export const IPC_DB = path.join(os.homedir(), ".claude-ipc", "data", "ipc.sqlite");
let ipcMissing = false;

// The registry's last_seen per alias, in seconds ago. Its `status` column is
// not the liveness test (it read "live" for 21-hour-dead sessions, measured
// 2026-08-22); last_seen is.
// Returns the readings AND whether the lookup itself worked, because those are
// different facts: no broker, a missing sqlite file and a throwing query all
// mean "I could not find out", while an alias missing from a read registry
// means "this session is not around". An unloadable list is not an empty one.
export function seenAgoByAlias(): Map<string, number> & { ok?: boolean } {
  const out: Map<string, number> & { ok?: boolean } = new Map<string, number>();
  out.ok = false;
  if (ipcMissing) return out;
  let db: any = null;
  try {
    if (!fs.existsSync(IPC_DB)) { ipcMissing = true; return out; }
    // lazy: a machine with no ipc broker never pays for the sqlite driver
    const { Database } = require("bun:sqlite");
    // opened per call, not kept: a held handle pins a WAL snapshot, so last_seen
    // freezes while the clock moves and every session ages out to cold
    db = new Database(IPC_DB, { readonly: true });
    const now = Date.now() / 1000;
    for (const r of db.query("select alias, max(last_seen) as seen from registry_snapshot group by alias")
      .all() as { alias: string; seen: number }[]) {
      if (r.alias && r.seen) out.set(r.alias, Math.max(0, Math.round(now - r.seen)));
    }
    // Set only after the query returns, so a missing alias is genuinely absent.
    out.ok = true;
  } catch { /* no broker is not an error, but it IS not an answer either */ }
  finally { try { db?.close(); } catch { /* nothing to do */ } }
  return out;
}

// An answer's value decays with the asking session's context: answering a live
// session costs it nothing, answering after its /clear costs a re-brief. So a
// pending decision carries whether it can still reach the session that raised
// it, and the sort puts hot above old-and-cold. Never asserts "live": it
// reports when the session was last seen and lets the reader judge.
export const HOT_S = 1800;
export function reachOf(session: string | null | undefined, seen: Map<string, number>): any {
  if (!session) return { state: "unknown", seenAgo: null };
  const ago = seen.get(session);
  // "cold" claims a session was once reachable and drifted out; an alias that
  // never registered is "absent", and a registry that could not be read at all
  // is "unknown". Claiming more than the lookup supports is the same overclaim
  // as asserting "live", pointed the other way.
  if (ago == null) return (seen as any).ok
    ? { state: "absent", seenAgo: null }
    : { state: "unknown", seenAgo: null };
  return { state: ago <= HOT_S ? "hot" : "cold", seenAgo: ago };
}
