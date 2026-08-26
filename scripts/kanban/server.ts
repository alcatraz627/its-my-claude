#!/usr/bin/env bun
// The kanban hub server. Sole writer of notes.json (POST /api/note); everything
// else read-only. Localhost-only tier-2 pm2 service, port via ports.sh (D1a).

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import { execFileSync } from "node:child_process";
import {
  KROOT, SERVER_INFO, LANES, PINS, atomicWrite, registry, loadBoard, loadNotes, saveNotes,
  loadAck, parseNoteTags, notesOf, deriveEntry, noteId, noteSeen,
  loadItems, saveItems, loadLandings, loadPins, isArchived, displayScope, visibleOn,
  loadDrafts, saveDrafts, loadPulls, loadSelection, saveSelection, emptySelection, noteKey, renderSelection, type Selection,
  recipientsOf, isPulled,
  loadPlan, savePlan, findTag, tagKey, TAG_PRESETS, presetFor, askState,
  recordChange, loadChanges, sinceMsOf, milestonesOf, withBoardLock,
  TAG_HUES, tagColourKey, loadTagColours, saveTagColours, loadPlans,
  VIEW_LIMITS, isKnownClause, isOperator, matchView, type Plan, type TagKind,
  type Item, type Pin, type Draft,
} from "./lib.ts";

const portArg = process.argv.indexOf("--port");
const PORT = portArg >= 0 ? Number(process.argv[portArg + 1]) : NaN;
if (!Number.isInteger(PORT)) {
  console.error("server: --port <claimed-port> is required — fix: ports.sh claim kanban --tier 2, then pass the printed port");
  process.exit(1);
}

const HERE = import.meta.dir;
const html = (name: string) => new Response(fs.readFileSync(path.join(HERE, name)), { headers: { "content-type": "text/html; charset=utf-8" } });
// The shared look and behaviour, served once rather than pasted into each page.
// No cache header on purpose: this is a localhost tool someone is editing.
const asset = (name: string, type: string) =>
  new Response(fs.readFileSync(path.join(HERE, name)), { headers: { "content-type": `${type}; charset=utf-8`, "cache-control": "no-store" } });
const json = (obj: unknown, status = 200) => Response.json(obj, { status });

// The only writer of notes.json is this chain — POSTs serialize through it so
// load-mutate-save never interleaves (dashboard-tools non-negotiable #1).
let notesChain: Promise<unknown> = Promise.resolve();
function enqueueNote(fn: () => unknown): Promise<unknown> {
  const run = notesChain.then(() => fn());
  notesChain = run.catch(() => undefined);
  return run;
}

// the decision-pages registry lives beside kanban's root, unchanged
const DP_ROOT = path.join(path.dirname(KROOT), "assets", "decision-pages");
function dpDirOf(slug: string): string | null {
  if (!/^[a-z0-9][a-z0-9._-]*$/.test(slug)) return null;
  const dir = path.join(DP_ROOT, slug);
  return fs.existsSync(path.join(dir, "config.json")) ? dir : null;
}
function dpClearPending(slug: string): void {
  try {
    const pend = path.join(DP_ROOT, ".pending.txt");
    if (!fs.existsSync(pend)) return;
    const keep = fs.readFileSync(pend, "utf8").split("\n").filter((l) => l.trim() && l.trim() !== slug);
    const tmp = pend + ".srv.tmp";
    fs.writeFileSync(tmp, keep.join("\n") + (keep.length ? "\n" : ""), "utf8");
    fs.renameSync(tmp, pend);
  } catch { /* best-effort, the answer file is the load-bearing signal */ }
}
// D9a: every decision that belongs to a board, in one list, whatever its shape.
// Two sources. A decision PAGE names its board in origin.board. A decision an
// agent simply TOOK to the owner has no page and lives in the board's own plan,
// because the owner asked for "the decided ones stored here too".
function dpPending(): Set<string> {
  try {
    return new Set(fs.readFileSync(path.join(DP_ROOT, ".pending.txt"), "utf8")
      .split("\n").map((x) => x.trim()).filter(Boolean));
  } catch { return new Set(); }
}
// How long ago a named session was last seen, or null. The registry's `status`
// column is not the liveness test (it read "live" for 21-hour-dead sessions,
// measured 2026-08-22); last_seen is. Asked per alias rather than per cwd,
// because the question here is "can this answer still reach the session that
// raised it", not "who works on this board".
// Returns the readings AND whether the lookup itself worked, because those are
// different facts and the caller needs both. It used to return only the map, so
// four unrelated situations produced an identical empty result: no broker
// installed, the sqlite file missing, the open or query throwing, and the alias
// genuinely not being there. Only the last one means "this session is not
// around"; the other three mean "I could not find out". SYSTEM.md law 1 — an
// unloadable list is not an empty one.
function seenAgoByAlias(): Map<string, number> & { ok?: boolean } {
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
    // Set only after the query returns: reaching here means the registry was
    // read, so an alias missing from the map is genuinely absent rather than
    // unlooked-up.
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
const HOT_S = 1800;
function reachOf(session: string | null | undefined, seen: Map<string, number>): any {
  if (!session) return { state: "unknown", seenAgo: null };
  const ago = seen.get(session);
  // "cold" is a claim about the session ("it has gone away, so an answer can
  // wait"). Making that claim on the strength of a lookup that failed is the
  // same overclaim as saying "live", pointed the other way, and this surface was
  // guarded against only one direction. When the registry could not be read, the
  // honest answer is the unknown state that already exists.
  if (ago == null) return (seen as any).ok
    // The registry was read and this alias is not in it. That is not "gone
    // cold": cold is a claim that a session was once reachable and has since
    // drifted out, and it carries "answering costs it a re-brief". An alias
    // that never registered was never warm, and there may be no session behind
    // it at all. Different fact, different word.
    ? { state: "absent", seenAgo: null }
    // The registry could not be read at all — no broker, missing sqlite file,
    // or a throwing open/query. Claiming anything about the session here is the
    // same overclaim as asserting "live", pointed the other way.
    : { state: "unknown", seenAgo: null };
  return { state: ago <= HOT_S ? "hot" : "cold", seenAgo: ago };
}

function boardDecisions(slug: string, plan: any): any[] {
  const out: any[] = [];
  const pending = dpPending();
  const seen = seenAgoByAlias();
  try {
    for (const s of fs.readdirSync(DP_ROOT)) {
      const dir = path.join(DP_ROOT, s);
      let cfg: any = null;
      try { cfg = JSON.parse(fs.readFileSync(path.join(dir, "config.json"), "utf8")); } catch { continue; }
      if ((cfg.origin?.board ?? "") !== slug) continue;
      let answer: any = null;
      try { answer = JSON.parse(fs.readFileSync(path.join(dir, ".answer.json"), "utf8")); } catch {}
      let at: string | null = null;
      try { at = new Date(fs.statSync(path.join(dir, "config.json")).mtimeMs).toISOString(); } catch {}
      out.push({ kind: "page", id: s, title: cfg.title ?? s,
        href: `/dp/${s}/`, card: cfg.origin?.card ?? null,
        pending: pending.has(s), seen: fs.existsSync(path.join(dir, ".seen.json")),
        session: cfg.origin?.session ?? null,
        reach: reachOf(cfg.origin?.session, seen),
        answer: answer?.answer ?? null, answeredAt: answer?.submitted_at ?? null, at });
    }
  } catch { /* no registry is not an error */ }
  // recorded decisions: no page, the agent wrote them down where the work is
  for (const d of (plan?.decisions ?? [])) {
    // seen used to be hardcoded true here, which is the whole reason the red
    // "unseen" state had never once rendered: a page-backed decision is unseen
    // until the owner opens its page and writes .seen.json, and a recorded one
    // claimed to have been seen the instant an agent wrote it. Now it is stamped
    // when the owner opens the row on the board (op: "seen"), so a decision an
    // agent raised while they were away reads as unseen until they look at it.
    out.push({ kind: "recorded", id: d.id, title: d.question, href: null,
      card: d.card ?? null, pending: !d.answer, seen: !!d.seenAt,
      answer: d.answer ?? null, answeredAt: d.answeredAt ?? null, at: d.at ?? null,
      session: d.by ?? null, reach: reachOf(d.by, seen), deferUntil: d.deferUntil ?? null,
      why: d.why ?? null, notes: d.notes ?? [] });
  }
  // Needs-the-owner first, then answer-while-hot: among pending rows, one that
  // still reaches a live session outranks one whose asker has gone cold, because
  // the same minute of the owner's time is worth more there. Newest breaks ties.
  const hot = (x: any) => Number(x.pending && x.reach?.state === "hot");
  out.sort((a, b) => Number(b.pending) - Number(a.pending) || hot(b) - hot(a) ||
    String(b.at ?? "").localeCompare(String(a.at ?? "")));
  return out;
}

function dpNotifyOrigin(slug: string, dir: string): void {
  try {
    const cfg = JSON.parse(fs.readFileSync(path.join(dir, "config.json"), "utf8"));
    const origin = cfg?.origin?.session ?? "";
    if (!origin) return;
    Bun.spawn(["claude-ipc", "send", "--from", "dp-server", "--to", origin,
      `decision page ${slug} answered — read it: bash ~/.claude/scripts/decision-page/decision-page.sh answer ${slug}`],
      { stdout: "ignore", stderr: "ignore" });
  } catch { /* best-effort */ }
}

function boardDirOf(slug: string): string | null {
  if (!/^[a-z0-9-]+$/.test(slug)) return null;
  return registry().boards[slug] ? path.join(KROOT, "boards", slug) : null;
}

// items.json and pins.json share notes.json's discipline: one writer, and every
// POST serializes through a chain so load-mutate-save never interleaves.
let itemChain: Promise<unknown> = Promise.resolve();
function enqueueItem(fn: () => unknown): Promise<unknown> {
  const run = itemChain.then(() => fn());
  itemChain = run.catch(() => undefined);
  return run;
}

import { renderMd } from "./render-md.ts";

// Which agent sessions are working in a board's project right now, from the
// claude-ipc registry. A stale "live" is worse than no badge, so nothing caches.
const IPC_DB = path.join(os.homedir(), ".claude-ipc", "data", "ipc.sqlite");
let ipcMissing = false;

// The same file and the same 300s staleness window the statusline reads
// (statusline.sh:374-384), so the board and the status line never disagree
// about how many sub-agents a session has.
const SUBAGENT_STALE_S = 300;
function subagentsOf(sessionId: string | undefined): number {
  if (!sessionId) return 0;
  try {
    const f = `/tmp/claude-agents-${sessionId.slice(0, 8)}`;
    if (!fs.existsSync(f)) return 0;
    const now = Date.now() / 1000;
    return fs.readFileSync(f, "utf8").split("\n").filter((l) => {
      const ts = Number(l.split("|")[2]);
      return l.trim() && Number.isFinite(ts) && now - ts <= SUBAGENT_STALE_S;
    }).length;
  } catch { return 0; }
}

// The board's own ipc identity. Registered lazily right before a send rather
// than at boot, because the broker prunes idle aliases and a name registered
// hours ago may be gone by the time the human clicks the button.
const IPC_ALIAS = "kanban-board";
function ipcRegister(bin: string): void {
  try { execFileSync(bin, ["register", IPC_ALIAS], { stdio: ["ignore", "ignore", "ignore"], timeout: 5000 }); }
  catch { /* a down broker is reported by the send itself, not here */ }
}

// Is this named alias live right now? Same table and same window as livePeers,
// asked by name instead of by directory, because a draft addressed to an agent
// names one and a board does not.
export function aliasIsLive(alias: string): boolean {
  if (ipcMissing) return false;
  let db: any = null;
  try {
    if (!fs.existsSync(IPC_DB)) { ipcMissing = true; return false; }
    const { Database } = require("bun:sqlite");
    db = new Database(IPC_DB, { readonly: true });
    const row = db.query(
      "select 1 from registry_snapshot where alias = ?1 and status in ('live','idle') and last_seen > ?2 limit 1",
    ).get(alias, Date.now() / 1000 - 1800);
    return !!row;
  } catch { return false; }
  finally { try { db?.close(); } catch { /* nothing to do */ } }
}

export interface LivePeer { alias: string; subagents: number }
function livePeers(root: string): LivePeer[] {
  if (ipcMissing) return [];
  let db: any = null;
  try {
    if (!fs.existsSync(IPC_DB)) { ipcMissing = true; return []; }
    // lazy: a machine with no ipc broker never pays for the sqlite driver
    const { Database } = require("bun:sqlite");
    // opened per call on purpose: a kept handle pins a WAL snapshot, so
    // last_seen freezes while the clock moves and every peer ages out to dead.
    db = new Database(IPC_DB, { readonly: true });
    // last_seen is the liveness test. The status column is NOT: measured
    // 2026-08-22, it reads "live" for sessions last seen 19 and 21 hours ago, so
    // 172 of 266 rows claim to be live. An earlier comment here called status
    // authoritative and treated this window as a mere dead-broker backstop; the
    // table disagrees, and trusting it surfaced seven peers on one board of which
    // one was real.
    //
    // 15 minutes was too tight for the case the nudge exists for. A session
    // waiting on the owner heartbeats rarely: gcp-fable and this board's own
    // gcc-kanban were both genuinely alive at 1086s and 1258s, past the old
    // cutoff, so a nudge could not reach the only sessions worth nudging. 30
    // minutes covers an idle-but-live session and still drops the 11-hour ones.
    const cutoff = Date.now() / 1000 - 1800;
    const rows = db.query(
      "select alias, cwd, session_id from registry_snapshot where status in ('live','idle') and last_seen > ?1",
    ).all(cutoff) as { alias: string; cwd: string; session_id: string }[];
    const real = fs.realpathSync(root);
    const named = rows
      .filter((r) => r.cwd === real || r.cwd?.startsWith(real + path.sep))
      // drop only auto-generated aliases: a bare uuid, or <project>-<8 hex>
      // where the project half matches this board. "sprint-deadbeef" survives.
      // the board's own ipc identity is not an agent working here
      .filter((r) => r.alias !== IPC_ALIAS)
      .filter((r) => !/^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(r.alias))
      .filter((r) => !new RegExp(`^${path.basename(real).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}-[0-9a-f]{8}$`, "i").test(r.alias));
    const seen = new Set<string>();
    return named
      .filter((r) => (seen.has(r.alias) ? false : (seen.add(r.alias), true)))
      .map((r) => ({ alias: r.alias, subagents: subagentsOf(r.session_id) }))
      .sort((a, b) => (a.alias < b.alias ? -1 : 1));
  } catch { return []; }
  finally { try { db?.close(); } catch { /* nothing to do */ } }
}

// Doc routes serve only board projects, ~/.claude/assets/reports and scratchpad,
// never all of ~/.claude (F6a). Every doc-reading route goes through here.
function resolveDocPath(reqPath: string): { real: string } | { error: string; status: number } {
  const roots = [
    ...Object.values(registry().boards).map((b) => b.root),
    path.join(os.homedir(), ".claude", "assets", "reports"),
    path.join(os.homedir(), ".claude", "scratchpad"),
  ];
  // The checks below run in order and return on the first failure, which means
  // the LAST one inherits every problem the earlier ones did not name. It used
  // to be the extension test, so a request with no path at all — which resolves
  // to the process CWD, itself inside a board root, and so passes both earlier
  // gates — came back "doc viewer renders .md/.txt only". A confident, specific
  // sentence about a file type, for a request that named no file. The two cases
  // that were being swallowed now answer for themselves, first.
  if (!reqPath.trim()) return { error: "no document asked for — /doc needs ?path=<file>", status: 400 };
  // ~ is how a path is written everywhere else in this app — in card bodies, in
  // decision why fields, in notes, in the docs themselves. path.resolve does not
  // expand it, so every one of those was unopenable until now. rootMissing has
  // expanded it for board roots since the beginning; this is the same rule.
  reqPath = reqPath.replace(/^~(?=$|\/)/, os.homedir());
  let real: string;
  try { real = fs.realpathSync(path.resolve(reqPath)); } catch { return { error: `no such file: ${reqPath}`, status: 404 }; }
  const allowed = roots.some((r) => { try { const rr = fs.realpathSync(r); return real === rr || real.startsWith(rr + path.sep); } catch { return false; } });
  if (!allowed) return { error: `path outside allowlisted roots (board projects + ~/.claude/assets/reports + ~/.claude/scratchpad)`, status: 403 };
  // A directory was the only non-file case checked, and the check was about
  // giving a good message. This one is about staying alive: every read below is
  // synchronous, and a synchronous open() on a NAMED PIPE with no writer blocks
  // forever. Bun runs one JS thread, so that is not a slow request — it is the
  // whole server, every board, every endpoint, until someone notices and
  // restarts it. Deleting the pipe afterwards does not help; the fd is already
  // open. The validator did exactly this to the live instance on 2026-08-26.
  //
  // Any board root and ~/.claude/scratchpad are writable by any local agent, so
  // a pipe, a socket or a device node can land in one deliberately or as a
  // build artifact. realpathSync above already resolved any symlink without
  // opening anything, so this stats the true target either way.
  let st: fs.Stats;
  try { st = fs.lstatSync(real); } catch { return { error: `no such file: ${reqPath}`, status: 404 }; }
  if (st.isDirectory()) return { error: `that is a folder, not a document: ${real}`, status: 400 };
  if (!st.isFile()) return { error: `that is not a regular file, so it cannot be read as a document`, status: 400 };
  if (!/\.(md|txt|markdown)$/i.test(real)) return { error: `the doc viewer renders .md and .txt; this is ${path.extname(real) || "extensionless"}`, status: 415 };
  return { real };
}

// A few lines of a source doc around the harvested line, for the drawer's
// inline preview. Same allowlist as /doc; JSON because the board consumes it.
function docSegment(reqPath: string, line: number): Response {
  const r = resolveDocPath(reqPath);
  if ("error" in r) return json({ error: r.error }, r.status);
  const all = fs.readFileSync(r.real, "utf8").split("\n");
  const center = line >= 1 && line <= all.length ? line : 1;
  const start = Math.max(1, center - 2);
  const lines = all.slice(start - 1, Math.min(all.length, start + 10));
  return json({ path: r.real, start, total: all.length, lines });
}

// embed=1 is the in-drawer modal, which already has the board's chrome around
// it: a second theme toggle inside the document reads as a document action.
// Owner, 2026-08-25: "If a dir doesn't exist then that needs to be flagged as an
// alert in the card in general." A board whose project has been deleted or moved
// keeps serving its last harvest and looks healthy, which is how kanban-fixture
// sat registered against a dead scratchpad without anyone noticing.
function rootMissing(root?: string | null): boolean {
  if (!root) return false;
  try { return !fs.existsSync(root.replace(/^~(?=$|\/)/, os.homedir())); } catch { return false; }
}

function docResponse(reqPath: string, line = 0, embed = false,
                     back: { slug: string; card: string } = { slug: "", card: "" }): Response {
  const esc = (s: string) => s.replace(/[&<>"]/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c] ?? c));
  const r = resolveDocPath(reqPath);
  if ("error" in r) {
    // Every doc error is a page, not only the 404. A 403 and a 415 used to
    // return bare JSON in a chrome-less document, so the two failures a person
    // is most likely to reach by typing a URL were the two with no way out of
    // them. An error page is still a page: it wears the bar (charter §18c) so a
    // dead link is a place you can leave rather than a dead end (charter U4).
    const said: Record<number, { head: string; hint: string }> = {
      400: { head: "That is not a document",
             hint: "The doc viewer takes one file. Open a card's source from the board, or pass <code>?path=</code> a markdown file." },
      403: { head: "That file is outside the boards",
             hint: "The viewer reads a board's own project, <code>~/.claude/assets/reports</code> and <code>~/.claude/scratchpad</code>. Anything else is off limits, deliberately." },
      404: { head: "This document is gone",
             hint: "The board is a mirror of your docs at sync time; this source file has since moved or been deleted. Re-sync the board to drop stale cards: <code>kanban.sh sync</code>" },
      415: { head: "The viewer cannot render that file",
             hint: "It renders <code>.md</code> and <code>.txt</code>. Source files open in your editor, not here." },
    };
    const say = said[r.status] ?? { head: "That document could not be opened", hint: "" };
    return new Response(
      `<!doctype html><meta charset="utf-8"><link rel="icon" href="/favicon.svg"><title>${esc(say.head.toLowerCase())}</title>
<link rel="stylesheet" href="/shared.css">
<style>body{background:var(--canvas);color:var(--text);font:15px/1.7 var(--sans);margin:0}
.gone{width:min(60ch,calc(100% - 44px));margin:16vh auto}
.gone h2{font-size:1.5em;margin:0 0 .6em}
.gone p{color:var(--text-2);margin:0 0 1em}
code{background:var(--well);border:1px solid var(--border);border-radius:4px;padding:.08em .38em;font:.87em var(--mono)}</style>
<header id="phead"></header>
<div class="gone">
<h2>${esc(say.head)}</h2>
<p><code>${esc(reqPath || "(no path given)")}</code></p>
<p>${esc(r.error)}</p>
${say.hint ? `<p>${say.hint}</p>` : ""}
</div>
<script src="/kinds.js"></script><script src="/shared.js"></script>
<script>navbar({ mount: "#phead", active: "boards",
  identity: crumbFor("boards", ${JSON.stringify(say.head.toLowerCase())}) });</script>`,
      { status: r.status, headers: { "content-type": "text/html; charset=utf-8" } },
    );
  }
  const real = r.real;
  const body = renderMd(fs.readFileSync(real, "utf8"));
  return new Response(
    `<!doctype html><meta charset="utf-8"><link rel="icon" href="/favicon.svg"><title>${path.basename(real)}</title>
<link rel="stylesheet" href="/shared.css">
<style>
/* the document reads on the same tokens as everything else; it used to carry a
   fourth private palette that agreed with the others by hand */
body{background:var(--canvas);color:var(--text);font:15px/1.7 var(--sans);margin:0}
/* Prose wants a measure, not the window. */
.docwrap{width:min(78ch,calc(100% - 44px));margin:30px auto 96px}
.docwrap > :first-child{margin-top:0}

/* More room above a heading than below it, so a section reads as attached to
   its own title rather than floating between two. */
h1,h2,h3,h4,h5,h6{line-height:1.25;font-weight:650;color:var(--text);
                  margin:0 0 .5em;letter-spacing:-.01em}
h1{font-size:1.85em;margin-top:1.6em;letter-spacing:-.02em}
h2{font-size:1.38em;margin-top:2.1em;padding-bottom:.34em;border-bottom:1px solid var(--border)}
h3{font-size:1.13em;margin-top:1.7em}
h4{font-size:1em;margin-top:1.4em;color:var(--text-2)}
h5,h6{font-size:.92em;margin-top:1.3em;color:var(--text-3);
      text-transform:uppercase;letter-spacing:.06em}

p{margin:0 0 1.05em}
strong{font-weight:640;color:var(--text)}
em{color:var(--text-2)}
a{color:var(--blue);text-decoration:underline;text-underline-offset:2px;
  text-decoration-color:var(--blue-br)}
a:hover{text-decoration-color:var(--blue)}

/* The UA's 40px indent reads as a gutter at this body size, and gapless items
   read as one paragraph. */
ul,ol{margin:0 0 1.05em;padding-left:1.5em}
li{margin:.3em 0}
li > ul,li > ol{margin:.35em 0 .1em}
li::marker{color:var(--text-3)}
ul ul,ol ol,ul ol,ol ul{font-size:.98em}

blockquote{margin:1.1em 0;padding:.15em 0 .15em 1.05em;color:var(--text-2);
           border-left:2px solid var(--border-2)}
blockquote > :last-child{margin-bottom:0}

code{background:var(--well);border:1px solid var(--border);border-radius:4px;
     padding:.08em .38em;font:.87em/1.4 var(--mono);color:var(--text-2);
     overflow-wrap:break-word}
pre{background:var(--well);border:1px solid var(--border);border-radius:var(--r-panel);
    padding:12px 14px;overflow-x:auto;margin:0 0 1.15em;line-height:1.55}
pre code{background:none;border:0;padding:0;font-size:.86em;color:var(--text)}

hr{border:0;border-top:1px solid var(--border);margin:2.2em 0}

/* A table is its own scroller so a wide one never widens the page. */
table{border-collapse:collapse;margin:0 0 1.2em;display:block;overflow-x:auto;
      max-width:100%;font-size:.94em}
th,td{border:1px solid var(--border);padding:7px 11px;text-align:left;vertical-align:top}
th{background:var(--well);font-weight:620;color:var(--text);white-space:nowrap}
tbody tr:nth-child(even) td{background:rgb(255 255 255/.014)}

img{max-width:100%;height:auto;border-radius:var(--r-panel)}

.hit{background:var(--well);outline:2px dotted var(--blue);outline-offset:6px;border-radius:3px}
*{scrollbar-width:thin;scrollbar-color:var(--border) transparent}</style>
${embed ? "" : `<header id="phead"></header>`}
${embed ? body : `<div class="docwrap">${body}</div>`}
${embed ? "" : `<script src="/kinds.js"></script><script src="/shared.js"></script>`}
<script>${embed ? `const applyTheme=t=>{document.documentElement.dataset.theme=t;localStorage.setItem("kanban-theme",t)};
applyTheme(localStorage.getItem("kanban-theme")||"dark");` : `
/* The same bar every other page wears. This called the navbar by its old name
   until 2026-08-25, threw, and rendered bare for a day; a name inside a server
   template literal is invisible to every check the repo has. */
navbar({ mount: "#phead", active: "boards",
  identity: crumbFor("boards", ${JSON.stringify(path.basename(real))}) });
/* The doc's own small items go in the bar's status slot rather than a second
   strip below it (owner ruling, 2026-08-25). */
{
  const band = document.createElement("span");
  band.className = "sband";
  band.innerHTML = ${JSON.stringify(
    (back.slug
      ? `<a class="stat-chip" href="/b/${esc(encodeURIComponent(back.slug))}${back.card ? `?card=${esc(encodeURIComponent(back.card))}` : ""}"` +
        ` data-tip="Back to the card that linked this">&larr; the board</a>`
      : "") +
    `<span class="bpath" data-tip="The file this mirrors">${esc(real)}</span>` +
    `<span class="stat-chip mute" data-tip="The board mirrors your docs; edit the file itself">read-only</span>`,
  )};
  document.getElementById("nbStatus")?.append(...band.childNodes);
}`}
const want=${line || 0};
if(want){const els=[...document.querySelectorAll("[id^=L]")].filter(e=>/^L\\d+$/.test(e.id));
 const hit=els.filter(e=>+e.id.slice(1)<=want).pop()||els[0];
 if(hit){hit.classList.add("hit");hit.scrollIntoView({block:"center"});}}
</script>`,
    { headers: { "content-type": "text/html; charset=utf-8" } },
  );
}

const server = Bun.serve({
  hostname: "127.0.0.1",
  port: PORT,
  async fetch(req) {
    const url = new URL(req.url);
    const p = url.pathname;

    if (req.method === "GET" || req.method === "HEAD") {
      // a favicon 404 on every page is noise in every console, and the mark is
      // the same one the page chrome wears
      if (p === "/favicon.ico" || p === "/favicon.svg") {
        return new Response(
          `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="none">` +
          `<rect width="16" height="16" rx="3.5" fill="#5b9dff"/>` +
          `<rect x="3.4" y="3.6" width="3.4" height="8.8" rx="1.1" stroke="#111318" stroke-width="1.3"/>` +
          `<rect x="8.6" y="3.6" width="3.4" height="5.4" rx="1.1" stroke="#111318" stroke-width="1.3"/></svg>`,
          { headers: { "content-type": "image/svg+xml", "cache-control": "max-age=86400" } });
      }
      if (p === "/shared.css") return asset("shared.css", "text/css");
      if (p === "/shared.js") return asset("shared.js", "text/javascript");
      if (p === "/match.js") return asset("match.js", "text/javascript");
      if (p === "/kinds.js") return asset("kinds.js", "text/javascript");
      if (p === "/editor.js") return asset("editor.js", "text/javascript");
      if (p === "/") return html("hub.html");
      // A destination, not a mode: its own data model and its own canvas, so it
      // earns a URL you could send someone (v2-plan.md:151).
      if (p === "/drafts") return html("drafts.html");
      // Decision pages, adopted (DECISION-PAGES-ADOPTION.md). Kanban serves
      // the SAME registry the old :5197 server served, read-only for GETs, with
      // ONE dynamic template instead of a per-page copy of template.html.
      // The old server is retired (owner, 2026-08-25); this is the only one.
      if (p.startsWith("/dp/")) {
        const parts = p.slice(4).split("/").filter(Boolean).map((x) => decodeURIComponent(x));
        const slug = parts[0] ?? "";
        const dir = dpDirOf(slug);
        if (!dir) return json({ error: `unknown decision page ${slug}` }, 404);
        // Reached without its trailing slash, every relative fetch on the page
        // resolves one directory up: config.json becomes /dp/config.json, which
        // answers 404 with a JSON error body that parses fine. Send the browser
        // to the directory URL the way any file server would.
        if (parts.length <= 1) {
          if (!p.endsWith("/"))
            return new Response(null, { status: 301,
              headers: { location: `/dp/${encodeURIComponent(slug)}/${url.search}` } });
          return html("decision.html");
        }
        // an asset inside the page dir (config.json, images) — no traversal
        const rel = parts.slice(1).join("/");
        const real = path.resolve(dir, rel);
        if (!real.startsWith(path.resolve(dir) + path.sep)) return json({ error: "bad path" }, 400);
        if (!fs.existsSync(real) || !fs.statSync(real).isFile()) return json({ error: `no ${rel} in ${slug}` }, 404);
        const type = rel.endsWith(".json") ? "application/json"
          : rel.endsWith(".png") ? "image/png" : rel.endsWith(".jpg") || rel.endsWith(".jpeg") ? "image/jpeg"
          : rel.endsWith(".svg") ? "image/svg+xml" : rel.endsWith(".webp") ? "image/webp"
          : rel.endsWith(".html") ? "text/html; charset=utf-8" : "application/octet-stream";
        return new Response(fs.readFileSync(real), { headers: { "content-type": type, "cache-control": "no-store" } });
      }
      if (p.startsWith("/b/")) return boardDirOf(p.slice(3)) ? html("board.html") : json({ error: `unknown board ${p.slice(3)} — kanban.sh status lists boards` }, 404);
      // every note on every board, so the hub can answer "what did I ask for"
      if (p === "/api/notes") {
        const reg = registry();
        // one unreadable board must not blank the fleet view, so it degrades to
        // a row that names itself broken
        const broken: string[] = [];
        const rows = Object.entries(reg.boards).flatMap(([slug, b]) => {
          try {
          const bdir = path.join(KROOT, "boards", slug);
          const titles = new Map(loadBoard(bdir).cards.map((c) => [c.id, { title: c.title, lane: c.lane }]));
          const ack = loadAck(bdir);
          return Object.entries(loadNotes(bdir)).flatMap(([cardId, e]) =>
            notesOf(e).map((n) => ({
              board: b.name, slug, cardId, noteId: n.id,
              card: titles.get(cardId)?.title ?? null,
              lane: titles.get(cardId)?.lane ?? null,
              body: n.body, updatedAt: n.updatedAt,
              tags: parseNoteTags(n.body),
              pickedUp: noteSeen(ack, cardId, n),
            })));
          } catch { broken.push(b.name || slug); return []; }
        });
        rows.sort((a, b) => (a.updatedAt < b.updatedAt ? 1 : -1));
        return json({ notes: rows, broken });
      }
      // P1.1: one list of what awaits the owner, across kinds. Four surfaces
      // answer this partially today (the hub's tiers, the tab counts, the nudge,
      // the session line); this is the one derivation they should all read.
      // Derived at read time, never stored, the same way session lists are.
      if (p === "/api/owed") {
        const only = url.searchParams.get("slug") ?? "";
        const now = Date.now();
        const rows: any[] = [];
        const reg = registry();
        const seen = seenAgoByAlias();
        for (const [slug, b] of Object.entries(reg.boards) as any) {
          if (only && slug !== only) continue;
          const dir = boardDirOf(slug);
          if (!dir) continue;
          let plan: any = {}, bd: any = { cards: [] }, notes: any = {}, ack: any = {};
          try { plan = loadPlan(dir); bd = loadBoard(dir); notes = loadNotes(dir); ack = loadAck(dir); } catch { continue; }
          const push = (o: any) => rows.push({ board: slug, boardName: b.name ?? slug, ...o });

          for (const d of boardDecisions(slug, plan)) {
            if (!d.pending) continue;
            // P1.3: a deferral with a horizon leaves the list and comes back at
            // it. Without one, "later" means forever and the list silts up.
            if (d.deferUntil && Date.parse(d.deferUntil) > now) continue;
            push({ kind: "decision", id: d.id, title: d.title, since: d.at,
                   href: d.href, reach: d.reach, seen: d.seen,
                   why: d.pending && !d.seen ? "you have not opened it" : "waiting on your word" });
          }
          for (const c of bd.cards ?? []) {
            if (!c.verify?.needsHuman) continue;
            push({ kind: "card", id: c.id, title: c.titleBrief || c.title,
                   since: c.updatedAt ?? c.createdAt, href: `/b/${slug}?card=${c.id}`,
                   reach: { state: "unknown", seenAgo: null },
                   why: "the agent cannot close it alone" });
          }
          const flat = Object.entries(notes).flatMap(([cid, e]: any) =>
            notesOf(e).map((n: any) => ({ cid, n, t: parseNoteTags(n.body) })));
          for (const x of flat) {
            if (x.t.me || noteSeen(ack, x.cid, x.n)) continue;
            push({ kind: "note", id: x.n.id ?? x.cid, title: String(x.n.body).split("\n")[0].slice(0, 90),
                   since: x.n.updatedAt ?? x.n.at, href: `/b/${slug}?card=${x.cid}`,
                   reach: { state: "unknown", seenAgo: null },
                   why: "an agent has not picked this up" });
          }
        }
        // hot first among equals: the same minute is worth more where the asker
        // is still around. Then oldest, because waiting longer is its own claim.
        const hot = (x: any) => Number(x.reach?.state === "hot");
        rows.sort((a, b2) => hot(b2) - hot(a) ||
          String(a.since ?? "").localeCompare(String(b2.since ?? "")));
        return json({ owed: rows, counts: {
          total: rows.length,
          hot: rows.filter((r) => r.reach?.state === "hot").length,
          decision: rows.filter((r) => r.kind === "decision").length,
          card: rows.filter((r) => r.kind === "card").length,
          note: rows.filter((r) => r.kind === "note").length } });
      }

      // Every surface the owner has, in one list (#56, phase 1). Colocation, not
      // migration: boards stay where they are, decision pages are served here, and
      // this only answers "what is there". A hub tab reads it; nothing moves.
      if (p === "/api/surfaces") {
        const out: any = { boards: [], decisions: [], previews: [] };
        try {
          out.boards = Object.entries(registry().boards).map(([slug, b]: any) => ({
            kind: "board", slug, name: b.name ?? slug, root: b.root,
            href: `/b/${slug}`, at: b.syncedAt ?? null }));
        } catch (e: any) { out.boardsError = String(e?.message ?? e); }

        // decision pages live beside the other server; read them, never move them
        // KROOT is ~/.claude/kanban, and these live beside it under ~/.claude
      const CROOT = path.dirname(KROOT);
      const dpRoot = path.join(CROOT, "assets", "decision-pages");
      let pendingSlugs = new Set<string>();
      try { pendingSlugs = new Set(fs.readFileSync(path.join(dpRoot, ".pending.txt"), "utf8")
        .split("\n").map((x) => x.trim()).filter(Boolean)); } catch { /* none pending */ }
        try {
          for (const slug of fs.readdirSync(dpRoot)) {
            const dir = path.join(dpRoot, slug);
            let cfg: any = null;
            try { cfg = JSON.parse(fs.readFileSync(path.join(dir, "config.json"), "utf8")); } catch { continue; }
            // pending is ONE file at the registry root with a slug per line, not a
          // marker inside each page. Read from decision-page.sh rather than guessed.
            let st: any = null;
            try { st = fs.statSync(path.join(dir, "config.json")); } catch {}
            out.decisions.push({
              kind: "decision", slug,
              name: cfg.title ?? slug,
              href: `/dp/${slug}/`,   // adopted: served by this server now
              origin: cfg.origin?.project ?? null,
              // what this ruling belongs to, so the hub can link an answer back
              // to the work rather than only naming the project it came from
              board: cfg.origin?.board ?? null,
              card: cfg.origin?.card ?? null,
              session: cfg.origin?.session ?? null,
              goal: cfg.origin?.goal ?? null,
              milestone: cfg.origin?.milestone ?? null,
              items: (cfg.decisions?.length ?? 0) + (cfg.sections?.length ?? 0),
              pending: pendingSlugs.has(slug),
              // §12: unseen is a different state from undecided, and only a
              // pending page can be unseen (an answered one was obviously read)
              seen: fs.existsSync(path.join(dir, ".seen.json")),
              at: st ? new Date(st.mtimeMs).toISOString() : null,
            });
          }
        } catch (e: any) { if ((e?.code ?? "") !== "ENOENT") out.decisionsError = String(e?.message ?? e); }
        // Recorded decisions — the ones an agent wrote down where the work is,
        // with no page behind them. They were missing here entirely, so the
        // `decide` CLI recorded into a store that only the board's own left
        // panel could read: not the hub's Decisions view, and not the navbar
        // count, which both read this endpoint. An agent could take a call to
        // the owner and the owner's front door would never mention it.
        //
        // kinds.js promises the count and the list "can never disagree about
        // what counts" because both go through one listOf. That holds only if
        // this list is complete, so completeness is this endpoint's job.
        try {
          const seenLive = seenAgoByAlias();
          for (const [slug, b] of Object.entries(registry().boards) as any) {
            const dir = path.join(KROOT, "boards", slug);
            let plan: any = null;
            try { plan = loadPlan(dir); } catch { continue; }
            for (const d of (plan?.decisions ?? [])) {
              out.decisions.push({
                kind: "recorded", slug, name: d.question,
                // no page to open; the row links to the board that holds it
                href: `/b/${slug}`,
                board: slug, boardName: b.name ?? slug, card: d.card ?? null,
                session: d.by ?? null, reach: reachOf(d.by, seenLive),
                why: d.why ?? null, items: 1,
                // Same rule /api/owed uses at :561 — a deferred decision is not
                // pending until its horizon passes. Inlined rather than a shared
                // helper for one more caller; two callsites is where one earns.
                pending: !d.answer && !(d.deferUntil && Date.parse(d.deferUntil) > Date.now()),
                seen: !!d.seenAt,
                at: d.at ?? null,
              });
            }
          }
        } catch (e: any) { out.recordedError = String(e?.message ?? e); }

        // pending first: a page waiting on the owner outranks one they answered
        out.decisions.sort((a: any, b: any) =>
          Number(b.pending) - Number(a.pending) || String(b.at ?? "").localeCompare(String(a.at ?? "")));

        // plans: markdown docs registered to a board with a state (#58 phase 3)
        try {
          out.plans = loadPlans().map((pl) => ({
            kind: "plan", id: pl.id, name: pl.title, board: pl.board, state: pl.state,
            href: `/doc?path=${encodeURIComponent(pl.path)}`, at: pl.ruledAt ?? pl.at }));
          out.plans.sort((a: any, b: any) =>
            Number(a.state !== "draft") - Number(b.state !== "draft") || String(b.at ?? "").localeCompare(String(a.at ?? "")));
        } catch (e: any) { out.plansError = String(e?.message ?? e); }

        // previews arrive with preview.sh (not built): an empty list is the
        // honest answer, not a missing key the hub would have to guess about
        const man = path.join(CROOT, "assets", "previews", "manifest.jsonl");
        try {
          out.previews = fs.readFileSync(man, "utf8").split("\n").filter(Boolean)
            .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
        } catch { /* no manifest yet */ }

        return json({ ...out,
          counts: { boards: out.boards.length, decisions: out.decisions.length,
                    decisionsPending: out.decisions.filter((d: any) => d.pending).length,
                    plans: (out.plans ?? []).length, previews: out.previews.length } });
      }

      if (p === "/api/boards") {
        const reg = registry();
        return json({
          boards: Object.entries(reg.boards).map(([slug, b]) => {
            try {
            const bdir = path.join(KROOT, "boards", slug);
            const board = loadBoard(bdir);
            const counts = Object.fromEntries(LANES.map((l) => [l, board.cards.filter((c) => c.lane === l).length]));
            // hub attention-weighting (M1): agent-relevant unread (@me excluded,
            // same definition as cli notes --unread) + cards the human flagged
            // counted per note, not per card: one card can hold several asks
            const ack = loadAck(bdir);
            const ackTs = ack.lastAckTs;
            const flat = Object.entries(loadNotes(bdir))
              .flatMap(([cid, e]) => notesOf(e).map((n) => ({ cid, n, t: parseNoteTags(n.body) })));
            const unread = flat.filter((x) => !x.t.me && !noteSeen(ack, x.cid, x.n)).length;
            const reviewMe = flat.filter((x) => x.t.review).length;
            const verify = board.cards.reduce((a, c) => {
              if (c.verify?.needsHuman) a.needsHuman++;
              else if (c.verify?.grade) a.graded++;
              return a;
            }, { graded: 0, needsHuman: 0 });
            return { slug, name: b.name, root: b.root, counts, unread, reviewMe, verify, ackTs,
              live: livePeers(b.root), syncedAt: board.syncedAt,
              rootGone: rootMissing(b.root),
              stack: b.stack ?? [], branch: b.branch ?? null };
            } catch {
              // unreadable board data: say so in place rather than 500 the fleet
              return { slug, name: b.name, root: b.root, broken: true,
                rootGone: rootMissing(b.root),
                counts: Object.fromEntries(LANES.map((l) => [l, 0])),
                unread: 0, reviewMe: 0, verify: { graded: 0, needsHuman: 0 },
                ackTs: 0, live: [], syncedAt: null };
            }
          }),
        });
      }
      if (p === "/api/board") {
        const slug = url.searchParams.get("slug") ?? "";
        const dir = boardDirOf(slug);
        if (!dir) return json({ error: `unknown board ${slug}` }, 404);
        const reg = registry().boards[slug];
        // ackTs closes the note loop in the UI: it is when an agent last ran
        // `notes --ack`, so a note newer than it has not been picked up yet.
        const bd = loadBoard(dir);
        // A dropped card leaves its tag row behind in plan.json, so a tag count
        // taken from the raw store promises cards the filter cannot produce. The
        // membership map is served against the LIVE board, which keeps every
        // reader agreeing about what a tag is worth. The orphan rows stay on
        // disk and are simply never served; clearing them belongs on the drop
        // path, which cannot reach plan.json without going through here.
        const rawPlan = loadPlan(dir);
        const alive = new Set(bd.cards.map((c) => c.id));
        const plan = { ...rawPlan,
          on: Object.fromEntries(Object.entries(rawPlan.on).filter(([cid]) => alive.has(cid))),
          goals: Object.fromEntries(Object.entries(rawPlan.goals ?? {}).filter(([cid]) => alive.has(cid))),
          seq: Object.fromEntries(Object.entries(rawPlan.seq ?? {}).filter(([cid]) => alive.has(cid))
            .map(([cid, ids]) => [cid, ids.filter((x) => alive.has(x))])) };
        // rootGone was computed for the hub's list and nowhere else, so a board
        // whose project directory has been deleted showed a red pill on the hub
        // and, once opened, said only "synced 32d ago" — which reads as a stale
        // mirror rather than a project that no longer exists. Same fact, and the
        // page a person actually works in was the one that did not carry it.
        return json({ slug, name: reg.name, root: reg.root, board: bd,
          rootGone: rootMissing(reg.root),
          notes: loadNotes(dir), ackTs: loadAck(dir).lastAckTs, live: livePeers(reg.root),
          selection: loadSelection(dir), plan, presets: TAG_PRESETS,
          tagColours: loadTagColours(),
          decisions: boardDecisions(slug, plan),
          planDocs: loadPlans().filter((pl) => pl.board === slug) });
      }
      // The owner's own lane. `slug` scopes to one board and always keeps the
      // unassigned ones, because an unassigned item is routable to any board.
      if (p === "/api/items") {
        const want = url.searchParams.get("slug") || null;
        // The owner's own files get the degradation the boards already get
        // (see the two catches below): a broken store must name itself broken,
        // never read as an empty queue. Silence here is indistinguishable from
        // "nothing to do", and this is the feature's only pickup signal.
        let items, landings, pinRows;
        try {
          ({ items } = loadItems());
          ({ landings } = loadLandings());
          pinRows = loadPins().pins;
        } catch (e: any) {
          return json({ items: [], pins: [], broken: `${e.message}`.slice(0, 300) }, 200);
        }
        const names = Object.fromEntries(Object.entries(registry().boards).map(([s, b]) => [s, b.name]));
        const cardTitles = new Map<string, string>();
        for (const [s] of Object.entries(registry().boards)) {
          if (want && s !== want) continue;
          try { for (const c of loadBoard(path.join(KROOT, "boards", s)).cards) cardTitles.set(c.id, c.title); }
          catch { /* an unreadable board must not blank the owner's own writing */ }
        }
        const rows = items
          .filter((i) => !want || visibleOn(i, want))
          .map((i) => ({
            ...i,
            boardName: i.slug ? names[i.slug] ?? null : null,
            // the owner's display tags, named, so the agent reading an ask sees
            // where it was scoped and not just an opaque slug list
            shownOn: (displayScope(i) ?? []).map((s) => ({ slug: s, name: names[s] ?? s })),
            everywhere: displayScope(i) === null,
            landing: landings[i.id] ?? null,
            landedCard: landings[i.id]?.cardId ? cardTitles.get(landings[i.id]!.cardId!) ?? null : null,
            archived: isArchived({ landings }, i.id),
          }))
          .sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
        return json({ items: rows, pins: pinRows });
      }
      // Drafts, the rung above an ask (D5). Same degradation contract as
      // /api/items: a broken store says so rather than reading as an empty desk.
      if (p === "/api/drafts") {
        let drafts, pulls;
        try {
          ({ drafts } = loadDrafts());
          ({ pulls } = loadPulls());
        } catch (e: any) {
          return json({ drafts: [], broken: `${e.message}`.slice(0, 300) }, 200);
        }
        const names = Object.fromEntries(Object.entries(registry().boards).map(([s, b]) => [s, b.name]));
        const rows = drafts
          .map((d) => ({
            ...d,
            boardName: d.slug ? names[d.slug] ?? null : null,
            pull: pulls[d.id] ?? null,
            // A pull RECORD and a consumed DRAFT are different questions: once
            // the owner revises a pulled draft it is waiting again. The page
            // grouped on the record and so filed revised drafts under Pulled
            // while the CLI listed them as waiting. One rule, asked here.
            consumed: isPulled({ pulls }, d),
          }))
          .sort((a, b) => (a.updatedAt < b.updatedAt ? 1 : -1));
        return json({ drafts: rows });
      }
      if (p === "/doc") {
        return docResponse(url.searchParams.get("path") ?? "", Number(url.searchParams.get("line") ?? 0),
          url.searchParams.get("embed") === "1",
          { slug: url.searchParams.get("from") ?? "", card: url.searchParams.get("card") ?? "" });
      }
      if (p === "/api/docseg") return docSegment(url.searchParams.get("path") ?? "", Number(url.searchParams.get("line") ?? 0));
      // The charter, rendered from the file rather than copied into the help
      // modal. A hand-kept copy would be the charter's own anti-pattern, "a
      // second list of what the first list already says", and it would go stale
      // the first time a ruling landed.
      if (p === "/api/charter") {
        const f = path.join(HERE, "docs", "UI-CHARTER.md");
        if (!fs.existsSync(f)) return json({ error: "docs/UI-CHARTER.md is missing" }, 404);
        const src = fs.readFileSync(f, "utf8");
        return json({ html: renderMd(src), bytes: src.length,
                      mtime: fs.statSync(f).mtime.toISOString() });
      }
      // Every milestone the owner has, across boards. The kind's index, which is
      // what makes it a registry kind rather than a per-board feature: kinds.js
      // reads this for the tab count and the hub reads it for the list, so the
      // two cannot disagree about what a milestone is.
      if (req.method === "GET" && p === "/api/milestones") {
        const out: any[] = [];
        try {
          for (const [slug, b] of Object.entries(registry().boards) as any) {
            const dir = path.join(KROOT, "boards", slug);
            let plan: any = null, bd: any = null;
            try { plan = loadPlan(dir); bd = loadBoard(dir); } catch { continue; }
            const live = new Set(bd.cards.map((c: any) => c.id));
            for (const m of milestonesOf(plan)) {
              const t = findTag(plan, "milestone", m.name);
              const ids = t ? Object.entries(plan.on ?? {})
                .filter(([cid, tids]: any) => live.has(cid) && tids.includes(t.id))
                .map(([cid]) => cid) : [];
              const done = ids.filter((cid) =>
                bd.cards.find((c: any) => c.id === cid)?.lane === "done").length;
              out.push({ kind: "milestone", id: m.id, name: m.name, goal: m.goal ?? null,
                order: m.order, docs: m.docs ?? [], doneAt: m.doneAt ?? null,
                board: slug, boardName: b.name ?? slug, href: `/b/${slug}`,
                cards: ids.length, done, at: m.at });
            }
          }
        } catch (e: any) { return json({ error: String(e?.message ?? e) }, 500); }
        // Open first, because a milestone you have shipped is not one you are
        // steering by. Then by the order the board declared.
        out.sort((a, b) => Number(!!a.doneAt) - Number(!!b.doneAt) ||
          a.order - b.order || a.name.localeCompare(b.name));
        return json({ milestones: out, counts: { total: out.length,
          open: out.filter((m) => !m.doneAt).length } });
      }

      // What changed on a board, newest first. The transitions, not the state.
      if (req.method === "GET" && p === "/api/changes") {
        const slug = url.searchParams.get("slug") ?? "";
        const dir = boardDirOf(slug);
        if (!dir) return json({ error: `unknown board ${slug}` }, 404);
        const since = sinceMsOf(url.searchParams.get("since") ?? "7d");
        const rows = loadChanges(dir, since, Number(url.searchParams.get("limit") ?? 200));
        return json({ slug, since: since ? new Date(since).toISOString() : null,
                      count: rows.length, changes: rows });
      }
      return json({ error: `no route ${p}` }, 404);
    }

    if (req.method === "POST" && p === "/api/note") {
      const body = (await req.json().catch(() => null)) as
        { slug?: string; cardId?: string; note?: string; noteId?: string; title?: string; all?: boolean } | null;
      if (!body?.slug || !body.cardId || typeof body.note !== "string") {
        return json({ error: "need {slug, cardId, note} — empty note deletes" }, 400);
      }
      const dir = boardDirOf(body.slug);
      if (!dir) return json({ error: `unknown board ${body.slug}` }, 404);
      if (!/^[a-f0-9]{12}$/.test(body.cardId)) return json({ error: "cardId must be the 12-hex card id" }, 400);
      if (!loadBoard(dir).cards.some((c) => c.id === body.cardId)) {
        return json({ error: `card ${body.cardId} is not on board ${body.slug}` }, 404);
      }
      if (body.note.length > 10_000) return json({ error: "note over 10k chars" }, 413);
      // A client that sends no noteId is pre-multi-note. It seeded its textarea
      // from the derived join, so honouring it would write the join into one
      // note and lose the rest. Refuse instead of corrupting; a reload fixes it.
      const existing = notesOf(loadNotes(dir)[body.cardId]);
      // A blank save used to share its wire shape with "wipe the card", so a
      // stale page that cleared its box deleted every note. Wiping is now an
      // explicit `all`, which only `drop` sends.
      if (!body.noteId && existing.length > 1 && !body.all) {
        return json({ error: "this card has several notes and your page is out of date; reload and try again" }, 409);
      }
      // creating an empty note does nothing, so do not pretend it worked
      if (body.noteId === "new" && body.note.trim() === "") {
        return json({ error: "an empty note is not saved; write something first" }, 400);
      }
      // an id that is not on the card means the note was deleted under the
      // client. Appending a duplicate would hide that; say so instead.
      if (body.noteId && body.noteId !== "new" && !existing.some((n) => n.id === body.noteId)) {
        return json({ error: "that note is no longer on this card; reload to see the current ones" }, 409);
      }
      let result: { ok: true; savedAt: string; noteId?: string } | { error: string; status?: number } = { error: "unwritten" };
      await enqueueNote(() => {
        const all = loadNotes(dir);
        const list = notesOf(all[body.cardId!]).map((n) => ({ ...n }));
        const now = new Date().toISOString();
        const blank = body.note!.trim() === "";
        let active = body.noteId;
        if (blank && !body.noteId) {
          delete all[body.cardId!];                       // legacy clear, drop --force relies on it
        } else {
          // noteId "new" appends. A missing noteId keeps the legacy meaning,
          // which is to edit the card's one note, and is refused above when the
          // card has several.
          const target = body.noteId === "new"
            ? undefined
            : body.noteId
              ? list.find((n) => n.id === body.noteId)
              : list[0];
          if (blank && target) {
            list.splice(list.indexOf(target), 1);
            active = list[0]?.id;
          } else if (target) {
            target.body = body.note!; target.updatedAt = now;
            if (body.title !== undefined) target.title = body.title;
            active = target.id;
          } else if (blank) {
            active = list[0]?.id;   // nothing to create, so report no id
          } else {
            const fresh = { id: noteId(), body: body.note!, updatedAt: now, ...(body.title ? { title: body.title } : {}) };
            list.push(fresh);
            active = fresh.id;
          }
          const entry = deriveEntry(list, active);
          if (entry) all[body.cardId!] = entry; else delete all[body.cardId!];
        }
        saveNotes(dir, all, `note:${body.cardId}`);
        result = { ok: true, savedAt: now, noteId: active };
      });
      if ("error" in result) return json(result, 500);
      return json(result);
    }

    // The owner writes from anywhere and never classifies. A missing slug is a
    // deliberate state (unassigned, routable later), not a missing argument.
    if (req.method === "POST" && p === "/api/item") {
      const body = (await req.json().catch(() => null)) as
        { id?: string; body?: string; slug?: string; boards?: string[] | null;
          star?: boolean; trigger?: boolean } | null;
      if (!body) return json({ error: "need a JSON body" }, 400);
      if (body.slug && !registry().boards[body.slug]) return json({ error: `unknown board ${body.slug}` }, 404);
      // A display tag naming a board that does not exist would hide the ask
      // from every rail, which is the opposite of what tagging is for.
      if (Array.isArray(body.boards)) {
        const reg = registry().boards;
        const bad = body.boards.filter((s) => !reg[s]);
        if (bad.length) return json({ error: `unknown board(s): ${bad.join(", ")}` }, 404);
      }
      if (typeof body.body === "string" && body.body.length > 10_000) return json({ error: "item over 10k chars" }, 413);
      const isNew = !body.id;
      if (isNew && (typeof body.body !== "string" || !body.body.trim())) {
        return json({ error: "an empty item is not saved; write something first" }, 400);
      }
      let out: { ok: true; id: string; deleted?: boolean } | { error: string } = { error: "unwritten" };
      await enqueueItem(() => {
        const file = loadItems();
        const now = new Date().toISOString();
        if (isNew) {
          const fresh: Item = { id: noteId(), body: body.body!.trim(), createdAt: now, updatedAt: now,
            ...(body.slug ? { slug: body.slug } : {}), ...(body.star ? { starred: true } : {}) };
          file.items.push(fresh);
          saveItems(file, `item:new`);
          out = { ok: true, id: fresh.id };
          return;
        }
        const it = file.items.find((x) => x.id === body.id);
        if (!it) { out = { error: "that item is gone; reload to see the current ones" }; return; }
        // An empty body deletes, matching the note composer's existing grammar.
        if (typeof body.body === "string" && !body.body.trim()) {
          file.items = file.items.filter((x) => x.id !== body.id);
          saveItems(file, `item:del`);
          // Take the pin with it, the way mergeSync GCs an override with its
          // card. The landing is CLI-owned, so the CLI sweeps that one instead.
          const pf = loadPins();
          const kept = pf.pins.filter((x) => !(x.kind === "item" && x.ref === body.id));
          if (kept.length !== pf.pins.length) atomicWrite(PINS, { pins: kept }, "pin-gc", `pins=${kept.length}`);
          out = { ok: true, id: body.id!, deleted: true };
          return;
        }
        if (typeof body.body === "string") { it.body = body.body.trim(); it.updatedAt = now; }
        // null clears the tags back to "shows everywhere"; an empty array means
        // the same, so both spellings land on the same state rather than one of
        // them producing an ask visible on no rail at all.
        if (body.boards !== undefined) {
          if (body.boards === null || body.boards.length === 0) delete it.boards;
          else it.boards = [...new Set(body.boards)];
        }
        if (body.star !== undefined) { if (body.star) it.starred = true; else delete it.starred; }
        if (body.trigger !== undefined) { if (body.trigger) it.triggered = now; else delete it.triggered; }
        saveItems(file, `item:${body.id}`);
        out = { ok: true, id: body.id! };
      });
      if ("error" in out) return json(out, out.error.includes("gone") ? 409 : 500);
      return json(out);
    }

    // A draft is a document the owner authors, so it takes a title and a much
    // larger body than an ask. Marking one as a template makes it reusable
    // instead of consumable (D5); nothing else about it changes.
    if (req.method === "POST" && p === "/api/draft") {
      const body = (await req.json().catch(() => null)) as
        { id?: string; title?: string; body?: string; slug?: string | null;
          template?: boolean; trigger?: boolean; to?: string[] | null } | null;
      if (!body) return json({ error: "need a JSON body" }, 400);
      if (body.slug && !registry().boards[body.slug]) return json({ error: `unknown board ${body.slug}` }, 404);
      if ((body.title?.length ?? 0) > 200) return json({ error: "draft title over 200 chars" }, 413);
      // Two orders of magnitude above the ask cap, because the point of the rung
      // is that the thought was too big for the ask box.
      if (typeof body.body === "string" && body.body.length > 200_000) {
        return json({ error: "draft over 200k chars" }, 413);
      }
      const isNew = !body.id;
      if (isNew && (typeof body.body !== "string" || !body.body.trim()) && !body.title?.trim()) {
        return json({ error: "an empty draft is not saved; write something first" }, 400);
      }
      let out: { ok: true; id: string; deleted?: boolean } | { error: string } = { error: "unwritten" };
      // Catch, so a corrupt store names itself here too. Uncaught, loadDrafts
      // throwing reaches the browser as a bare 500 with no reason in it.
      await enqueueItem(() => {
       try {
        const file = loadDrafts();
        const now = new Date().toISOString();
        if (isNew) {
          const fresh: Draft = { id: noteId(), body: (body.body ?? "").trim(), createdAt: now, updatedAt: now,
            ...(body.title?.trim() ? { title: body.title.trim() } : {}),
            ...(body.slug ? { slug: body.slug } : {}),
            ...(body.template ? { isTemplate: true } : {}) };
          file.drafts.push(fresh);
          saveDrafts(file, "draft:new");
          out = { ok: true, id: fresh.id };
          return;
        }
        const d = file.drafts.find((x) => x.id === body.id);
        if (!d) { out = { error: "that draft is gone; reload to see the current ones" }; return; }
        // A blank body deletes only when the draft has no title either, so
        // clearing the editor to restructure a titled draft does not bin it.
        if (typeof body.body === "string" && !body.body.trim() && !(body.title ?? d.title ?? "").trim()) {
          file.drafts = file.drafts.filter((x) => x.id !== body.id);
          saveDrafts(file, "draft:del");
          out = { ok: true, id: body.id!, deleted: true };
          return;
        }
        if (typeof body.body === "string") { d.body = body.body; d.updatedAt = now; }
        if (body.title !== undefined) {
          if (body.title.trim()) d.title = body.title.trim(); else delete d.title;
          d.updatedAt = now;
        }
        if (body.slug !== undefined) {
          if (body.slug) d.slug = body.slug; else delete d.slug;
          d.updatedAt = now;
        }
        // Who it is for. Same refusal the CLI verb makes: a recipient pointing at
        // nothing is a draft addressed to a place that does not exist, which
        // reads as delivered.
        if (body.to !== undefined) {
          if (!body.to || !body.to.length) delete d.to;
          else {
            const bad = body.to.find((t) => !/^(agent|board):.+$/.test(t)
              || (t.startsWith("board:") && !registry().boards[t.slice(6)]));
            if (bad) { out = { error: `"${bad}" is not a recipient — use agent:<alias> or board:<slug>` }; return; }
            d.to = [...new Set(body.to)];
          }
          d.updatedAt = now;
        }
        if (body.template !== undefined) { if (body.template) d.isTemplate = true; else delete d.isTemplate; }
        if (body.trigger !== undefined) { if (body.trigger) d.triggered = now; else delete d.triggered; }
        saveDrafts(file, `draft:${body.id}`);
        out = { ok: true, id: body.id! };
       } catch (e: any) { out = { error: `${e.message}`.slice(0, 300) }; }
      });
      if ("error" in out) return json(out, out.error.includes("gone") ? 409
        : out.error.includes("not a recipient") ? 400 : 500);
      return json(out);
    }

    // The editor's preview pane. renderMd already backs the doc viewer, so the
    // alternative was a second markdown implementation in the browser.
    if (req.method === "POST" && p === "/api/mdpreview") {
      const body = (await req.json().catch(() => null)) as { body?: string } | null;
      if (typeof body?.body !== "string") return json({ error: "need {body}" }, 400);
      if (body.body.length > 200_000) return json({ error: "over 200k chars" }, 413);
      return json({ html: renderMd(body.body) });
    }

    // A pin is owner-only and read-side; no agent reads this file. Posting an
    // existing ref removes it, so the star and pin controls both toggle.
    // Tags and goals. One route for the whole vocabulary because the operations
    // are the same shape: name a tag, then say what it applies to.
    if (req.method === "POST" && p === "/api/tag") {
      const body = (await req.json().catch(() => null)) as {
        slug?: string; op?: "apply" | "unapply" | "create" | "rename" | "delete" | "forget";
        cardId?: string; kind?: TagKind; name?: string; tagId?: string; note?: string;
      } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir) return json({ error: `unknown board ${body?.slug ?? ""}` }, 404);
      if ((body!.name?.length ?? 0) > 40) return json({ error: "a tag name over 40 chars is a sentence, not a tag" }, 413);
      if (body!.kind && !TAG_PRESETS.some((t) => t.kind === body!.kind)) {
        return json({ error: `unknown tag kind ${body!.kind}` }, 400);
      }
      let out: any = { error: "unwritten" };
      await enqueueItem(() => {
        const plan = loadPlan(dir);
        const op = body!.op ?? "apply";
        // create-on-use: a vocabulary you must define before using is one nobody
        // uses. The first application of a name is what mints it.
        const mint = () => {
          const kind = (body!.kind ?? "plain") as TagKind;
          const name = String(body!.name ?? "").trim();
          if (!name) return null;
          const found = findTag(plan, kind, name);
          if (found) return found;
          const t = { id: noteId(), name, kind, createdAt: new Date().toISOString() };
          plan.tags.push(t);
          return t;
        };
        if (op === "create") { const t = mint(); out = t ? { ok: true, tag: t } : { error: "a tag needs a name" }; }
        else if (op === "apply" || op === "unapply") {
          const card = String(body!.cardId ?? "");
          if (!card) { out = { error: "apply needs a cardId" }; return; }
          const t = body!.tagId ? plan.tags.find((x) => x.id === body!.tagId) : mint();
          if (!t) { out = { error: "no such tag" }; return; }
          const list = plan.on[card] ?? (plan.on[card] = []);
          const at = list.indexOf(t.id);
          if (op === "apply" && at < 0) list.push(t.id);
          if (op === "unapply" && at >= 0) list.splice(at, 1);
          if (!list.length) delete plan.on[card];
          out = { ok: true, tag: t };
        } else if (op === "rename") {
          const t = plan.tags.find((x) => x.id === body!.tagId);
          if (!t) { out = { error: "no such tag" }; return; }
          const name = String(body!.name ?? "").trim();
          if (!name) { out = { error: "a tag needs a name" }; return; }
          // a rename that collides would fork the filter in two
          if (findTag(plan, body!.kind ?? t.kind, name) && tagKey(t.kind, t.name) !== tagKey(body!.kind ?? t.kind, name)) {
            out = { error: `${name} already exists in ${body!.kind ?? t.kind}` }; return;
          }
          t.name = name;
          if (body!.kind) t.kind = body!.kind;
          if (body!.note !== undefined) t.note = body!.note || undefined;
          out = { ok: true, tag: t };
        } else if (op === "delete") {
          const at = plan.tags.findIndex((x) => x.id === body!.tagId);
          if (at < 0) { out = { error: "no such tag" }; return; }
          plan.tags.splice(at, 1);
          for (const [card, list] of Object.entries(plan.on)) {
            const i = list.indexOf(body!.tagId!);
            if (i >= 0) list.splice(i, 1);
            if (!list.length) delete plan.on[card];
          }
          out = { ok: true };
        } else if (op === "forget") {
          // A dropped card takes its tag rows and its goal with it. The serving
          // side already filters orphans; this is what stops them accumulating.
          const card = String(body!.cardId ?? "");
          if (!card) { out = { error: "forget needs a cardId" }; return; }
          const had = (plan.on[card]?.length ?? 0) + (plan.goals[card] ? 1 : 0);
          delete plan.on[card];
          delete plan.goals[card];
          out = { ok: true, removed: had };
        } else { out = { error: `unknown op ${op}` }; return; }
        if (!out.error) savePlan(dir, plan, `tag:${op}`);
      });
      return json(out, out.error ? 400 : 200);
    }

    // The card's own "why". One line, and empty deletes it.
    if (req.method === "POST" && p === "/api/goal") {
      const body = (await req.json().catch(() => null)) as { slug?: string; cardId?: string; goal?: string } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir || !body?.cardId) return json({ error: "need {slug, cardId, goal}" }, 400);
      if ((body.goal?.length ?? 0) > 400) return json({ error: "a goal over 400 chars belongs in a note" }, 413);
      let out: any = { error: "unwritten" };
      await enqueueItem(() => {
        const plan = loadPlan(dir);
        const g = String(body.goal ?? "").trim();
        if (g) plan.goals[body.cardId!] = g; else delete plan.goals[body.cardId!];
        savePlan(dir, plan, `goal:${body.cardId}`);
        out = { ok: true, goal: g };
      });
      return json(out, out.error ? 400 : 200);
    }

    // Execution order. "After" is a fact about the plan, not the card, so it
    // lives beside goals and tags and survives sync the same way. Empty clears.
    // Views, the owner's path (#39). Same store as the agent's CLI verbs, so
    // "the for-me view" means one list no matter who says it.
    if (req.method === "POST" && p === "/api/view") {
      const body = (await req.json().catch(() => null)) as
        { slug?: string; op?: string; id?: string; name?: string; clauses?: string[]; note?: string } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir || !body?.op) return json({ error: "need {slug, op: add|rename|rm, …}" }, 400);
      let out: any = { error: "unwritten" };
      await enqueueItem(() => {
        const plan = loadPlan(dir);
        plan.views = plan.views ?? [];
        const dup = (n: string, notId?: string) =>
          plan.views!.some((v) => v.name.toLowerCase() === n.trim().toLowerCase() && v.id !== notId);
        const now = new Date().toISOString();
        if (body!.op === "add") {
          const name = (body!.name ?? "").trim();
          const clauses = (body!.clauses ?? []).map((c) => String(c).trim()).filter(Boolean);
          if (name.length < VIEW_LIMITS.nameMin || name.length > VIEW_LIMITS.nameMax)
            { out = { error: `a view name is ${VIEW_LIMITS.nameMin} to ${VIEW_LIMITS.nameMax} characters` }; return; }
          if (!clauses.length) { out = { error: "a view needs at least one clause" }; return; }
          // `or` and `not` are grammar, not clauses, so they never count against
          // the cap: "a or b or c or d" is four clauses, not seven.
          const real = clauses.filter((c) => !isOperator(c));
          if (real.length > VIEW_LIMITS.maxClauses)
            { out = { error: `at most ${VIEW_LIMITS.maxClauses} clauses; more than that is a search` }; return; }
          const bad = real.filter((c) => !isKnownClause(c));
          if (bad.length) { out = { error: `unknown clause: ${bad.join(", ")}` }; return; }
          // the tag rule: unique per board, case-insensitively
          if (dup(name)) { out = { error: `a view called "${name}" already exists here` }; return; }
          const noteIn = typeof body!.note === "string" ? body!.note.trim() : "";
          const v = { id: noteId(), name, clauses, ...(noteIn ? { note: noteIn } : {}),
                      by: "owner" as const, createdAt: now, updatedAt: now };
          plan.views!.push(v);
          savePlan(dir, plan, "view:add");
          out = { ok: true, view: v };
          return;
        }
        const v = plan.views!.find((x) => x.id === body!.id);
        if (!v) { out = { error: `no view ${body!.id}` }; return; }
        if (body!.op === "note") {
          // An empty note clears it, the same grammar an empty body uses to
          // delete an ask. Optional in, optional out.
          const t = typeof body!.note === "string" ? body!.note.trim() : "";
          if (t) v.note = t; else delete v.note;
          v.updatedAt = now;
          savePlan(dir, plan, "view:note");
          out = { ok: true, view: v };
          return;
        }
        if (body!.op === "rm") {
          plan.views = plan.views!.filter((x) => x.id !== v.id);
          savePlan(dir, plan, "view:rm");
          out = { ok: true, removed: v.name };
          return;
        }
        if (body!.op === "rename") {
          const name = (body!.name ?? "").trim();
          if (name.length < VIEW_LIMITS.nameMin || name.length > VIEW_LIMITS.nameMax)
            { out = { error: `a view name is ${VIEW_LIMITS.nameMin} to ${VIEW_LIMITS.nameMax} characters` }; return; }
          if (dup(name, v.id)) { out = { error: `a view called "${name}" already exists here` }; return; }
          v.name = name; v.updatedAt = now;
          savePlan(dir, plan, "view:rename");
          out = { ok: true, view: v };
          return;
        }
        out = { error: `unknown op ${body!.op}` };
      });
      return json(out, out.error ? 400 : 200);
    }

    // A decision page's Submit, byte-compatible with the retired :5197 server:
    // same .answer.json shape, same pending clear, same origin ipc notify.
    // An agent watching .answer.json cannot tell which server took it.
    if (req.method === "POST" && p.startsWith("/api/dp-submit/")) {
      const slug = decodeURIComponent(p.slice("/api/dp-submit/".length)).replace(/\/+$/, "");
      const dir = dpDirOf(slug);
      if (!dir) return json({ error: "unknown slug" }, 404);
      const body = (await req.json().catch(() => null)) as { answer?: string; replace?: boolean } | null;
      // An answered page used to accept a second submit unconditionally. Reloading
      // one reset every radio to the agent's RECOMMENDATION and left the primary
      // button enabled, so a single press replaced the owner's real rulings with
      // the agent's suggestions, cleared pending, and told the origin session the
      // owner had spoken. The ruling it would have destroyed on kanban-six-calls
      // is the one that produced charter §18c.
      //
      // The answer file is the load-bearing signal, so the guard lives here rather
      // than only in the page: a stale tab, a re-POST, or a script hits this too.
      // Replacing a ruling stays possible and now has to say so.
      const answerFile = path.join(dir, ".answer.json");
      // `=== true`, never truthiness. The first version of this guard read
      // `!body?.replace`, so `replace: "false"`, `replace: []`, `replace: {}`
      // and any non-empty string all sailed through and destroyed the ruling
      // with a 200 — the exact bug this guard was written to close, wearing a
      // different input. A guard on a destructive path takes the literal true
      // and nothing else.
      if (fs.existsSync(answerFile) && body?.replace !== true) {
        let had = "";
        try { had = JSON.parse(fs.readFileSync(answerFile, "utf8")).answer ?? ""; } catch {}
        return json({ error: "this page is already answered; send replace:true to overwrite it",
                      answered: true, existing: had }, 409);
      }
      const rec = { answer: body?.answer ?? "", submitted_at: Math.floor(Date.now() / 1000) };
      const tmp = path.join(dir, ".answer.json.tmp");
      fs.writeFileSync(tmp, JSON.stringify(rec, null, 1), "utf8");
      fs.renameSync(tmp, path.join(dir, ".answer.json"));
      dpClearPending(slug);
      dpNotifyOrigin(slug, dir);
      return json({ ok: true, slug });
    }

    // Milestones. plan.json, like tags and views, because it is the shared
    // vocabulary file and the CLI is not the only writer of it. Membership is
    // never touched here: a card belongs to a milestone by wearing its tag, and
    // this endpoint owns only the order, the goal, the docs and the done state.
    if (req.method === "POST" && p === "/api/milestone") {
      const body = (await req.json().catch(() => null)) as
        { slug?: string; op?: string; name?: string; value?: string;
          goal?: string; order?: string; moveCards?: boolean } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir || !body?.op || !body.name) return json({ error: "need {slug, op, name}" }, 400);
      let out: any = { error: "unwritten" };
      await enqueueItem(() => {
        const plan = loadPlan(dir) as any;
        plan.milestones = plan.milestones ?? [];
        const now = new Date().toISOString();
        const key = (n: string) => tagKey("milestone", n);
        const found = plan.milestones.find((m: any) => key(m.name) === key(body!.name!));

        if (body!.op === "add") {
          if (found) { out = { error: `${body!.name} already exists on this board` }; return; }
          const order = body!.order != null && body!.order !== ""
            ? Number(body!.order)
            : (plan.milestones.reduce((a: number, m: any) => Math.max(a, m.order), 0) + 1);
          if (!Number.isFinite(order)) { out = { error: `order must be a number, got "${body!.order}"` }; return; }
          const m = { id: noteId(), name: body!.name!.trim(), order,
                      goal: (body!.goal ?? "").trim() || undefined, docs: [], at: now };
          plan.milestones.push(m);
          savePlan(dir, plan, "milestone:add");
          recordChange(dir, { kind: "milestone", by: "board", what: `milestone ${m.name} added`, to: m.name });
          out = { ok: true, milestone: m };
          return;
        }
        if (!found) { out = { error: `no milestone ${body!.name} on this board` }; return; }

        if (body!.op === "goal") { found.goal = (body!.value ?? "").trim() || undefined; }
        else if (body!.op === "doc") { (found.docs = found.docs ?? []).push(String(body!.value)); }
        else if (body!.op === "order") {
          const n = Number(body!.value);
          if (!Number.isFinite(n)) { out = { error: `order must be a number, got "${body!.value}"` }; return; }
          found.order = n;
        }
        else if (body!.op === "done" || body!.op === "reopen") {
          found.doneAt = body!.op === "done" ? now : null;
        }
        else if (body!.op === "rm") {
          plan.milestones = plan.milestones.filter((m: any) => m.id !== found.id);
        }
        else { out = { error: `unknown op ${body!.op}` }; return; }

        // Shipping a milestone moves its cards with it. board.json has one
        // writer and it is the CLI (charter §11) — except that the same
        // exception the answers map already takes applies here, and it takes it
        // through the same lock, because the alternative is the owner moving
        // seven cards by hand which is the complaint that produced this object.
        let moved = 0;
        // The cards to move are DERIVED here, from the milestone's own tag, and
        // never taken from the caller. The first version trusted a `cards` array
        // in the request body, which meant any caller could hand this endpoint
        // arbitrary ids and have them moved to done under a milestone's name.
        // The CLI happened to compute the right list, and the CLI being the only
        // caller I pictured is exactly why I did not see it.
        //
        // It also keeps the promise the design makes: a card belongs to a
        // milestone by wearing its tag, and nothing else keeps a membership
        // list, so the two can never disagree. `moveCards: false` (the CLI's
        // --no-cards) is the only thing a caller may say about this.
        if (body!.op === "done" && body!.moveCards !== false) {
          const tag = findTag(plan, "milestone", found.name);
          withBoardLock(dir, () => {
            const bd = loadBoard(dir);
            const live = new Set(bd.cards.map((c: any) => c.id));
            const mine = tag ? Object.entries(plan.on ?? {})
              .filter(([cid, ids]: any) => live.has(cid) && ids.includes(tag.id))
              .map(([cid]) => cid) : [];
            for (const cid of mine) {
              const c = bd.cards.find((x) => x.id === cid);
              if (!c || c.lane === "done") continue;
              c.lane = "done"; c.updatedAt = now;
              bd.overrides[cid] = { lane: "done" };
              moved++;
            }
            if (moved) atomicWrite(path.join(dir, "board.json"), bd, "milestone:done", `cards=${moved}`);
          });
        }
        savePlan(dir, plan, `milestone:${body!.op}`);
        if (body!.op === "done")
          recordChange(dir, { kind: "milestone", by: "board",
            what: `milestone ${found.name} shipped${moved ? `, ${moved} card(s) moved to done` : ""}`,
            to: found.name, counts: { moved } });
        out = { ok: true, milestone: found, moved };
      });
      return json(out, out.error ? 400 : 200);
    }

    // D9a: a decision an agent took to the owner, recorded where the work is
    // rather than as a page. add records it, answer rules it, note is the
    // owner's comment on any decision including a page-backed one.
    if (req.method === "POST" && p === "/api/decide") {
      const body = (await req.json().catch(() => null)) as
        { slug?: string; op?: string; id?: string; question?: string;
          why?: string; card?: string; answer?: string; note?: string; by?: string; until?: string } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir || !body?.op) return json({ error: "need {slug, op: add|answer|note|defer|seen|rm, …}" }, 400);
      let out: any = { error: "unwritten" };
      await enqueueItem(() => {
        const plan = loadPlan(dir) as any;
        plan.decisions = plan.decisions ?? [];
        const now = new Date().toISOString();
        if (body.op === "add") {
          const q = (body.question ?? "").trim();
          if (!q) { out = { error: "a decision needs a question" }; return; }
          const d: any = { id: noteId(), question: q, at: now };
          if (body.by) d.by = String(body.by);
          if (body.why) d.why = body.why.trim();
          if (body.card) d.card = body.card;
          plan.decisions.push(d);
          savePlan(dir, plan, "decide:add");
          out = { ok: true, decision: d };
          return;
        }
        const d = plan.decisions.find((x: any) => x.id === body.id);
        if (!d) { out = { error: `no decision ${body.id}` }; return; }
        if (body.op === "answer") {
          const a = (body.answer ?? "").trim();
          if (a) { d.answer = a; d.answeredAt = now; } else { delete d.answer; delete d.answeredAt; }
          savePlan(dir, plan, "decide:answer");
          // A ruling nobody hears about is a ruling that changes nothing. A
          // decision PAGE already notifies its origin session on submit
          // (dpNotifyOrigin); a recorded decision had no equivalent, so the
          // owner ruled on the board and the session that asked went on waiting.
          // Opt-in via `notify` so the CLI's own `decide answer` stays quiet
          // unless it asks — an agent recording its own answer should not ping
          // itself.
          let told: string | null = null;
          if (a && body.notify && d.by) {
            told = String(d.by);
            recordChange(dir, { kind: "decision", by: "owner",
              what: `ruled: ${d.question}`, to: a.split("\n")[0].slice(0, 80) });
            try {
              Bun.spawn(["claude-ipc", "send", "--from", "kanban-board", "--to", told,
                `[kanban] the owner ruled on a decision you raised on board "${body.slug}".\n\n`
                + `Q: ${d.question}\n`
                + (d.why ? `why you raised it: ${d.why}\n` : "")
                + `\nTHEIR RULING: ${a}\n\n`
                + `Act on it. If it changes work already done, say so plainly rather than quietly reworking it. `
                + `Read it in full with: kanban.sh decide list`],
                { stdout: "ignore", stderr: "ignore" });
            } catch { /* best-effort: the ruling is saved either way */ }
          }
          out = { ok: true, decision: d, told };
        } else if (body.op === "note") {
          const t = (body.note ?? "").trim();
          if (!t) { out = { error: "an empty comment is not a comment" }; return; }
          (d.notes = d.notes ?? []).push({ body: t, at: now });
          savePlan(dir, plan, "decide:note");
          out = { ok: true, decision: d };
        } else if (body.op === "seen") {
          // Idempotent and first-write-wins: the stamp records when the owner
          // FIRST looked, so re-opening a decision does not keep resetting it.
          if (!d.seenAt) { d.seenAt = now; savePlan(dir, plan, "decide:seen"); }
          out = { ok: true, decision: d };
        } else if (body.op === "defer") {
          // a horizon, not a black hole: it leaves the owed list and returns
          const u = (body.until ?? "").trim();
          if (u) { if (isNaN(Date.parse(u))) { out = { error: `until must be a date, got "${u}"` }; return; } d.deferUntil = new Date(u).toISOString(); }
          else delete d.deferUntil;
          savePlan(dir, plan, "decide:defer");
          out = { ok: true, decision: d };
        } else if (body.op === "rm") {
          plan.decisions = plan.decisions.filter((x: any) => x.id !== body.id);
          savePlan(dir, plan, "decide:rm");
          out = { ok: true, removed: d.question };
        } else out = { error: `unknown op ${body.op}` };
      });
      return json(out, out.error ? 400 : 200);
    }

    // Charter §12, phase 4: a decision the owner has not opened reads as UNSEEN,
    // never as undecided. The page pings this on load, so opening one moves it
    // out of unseen without answering it. Was gated on reaching the :5197 pages
    // across origins; that server is retired and these are served here now.
    if (req.method === "POST" && p.startsWith("/api/dp-seen/")) {
      const slug = decodeURIComponent(p.slice("/api/dp-seen/".length)).replace(/\/+$/, "");
      const dir = dpDirOf(slug);
      if (!dir) return json({ error: "unknown slug" }, 404);
      const f = path.join(dir, ".seen.json");
      // first open is the one that matters; a re-read must not restart the clock
      if (fs.existsSync(f)) return json({ ok: true, slug, already: true });
      const tmp = f + ".tmp";
      fs.writeFileSync(tmp, JSON.stringify({ seen_at: Math.floor(Date.now() / 1000) }, null, 1), "utf8");
      fs.renameSync(tmp, f);
      return json({ ok: true, slug, already: false });
    }

    // A tag's colour, held across boards (#66): global rather than per board,
    // because the same word should look the same everywhere. Empty hue clears.
    if (req.method === "POST" && p === "/api/tag-colour") {
      const body = (await req.json().catch(() => null)) as
        { kind?: string; name?: string; hue?: string | null } | null;
      if (!body?.kind || !body?.name) return json({ error: "need {kind, name, hue|null}" }, 400);
      const hue = body.hue ?? "";
      if (hue && !(TAG_HUES as readonly string[]).includes(hue))
        return json({ error: `hue must be one of ${TAG_HUES.join(", ")}` }, 400);
      let out: any = { error: "unwritten" };
      await enqueueItem(() => {
        const m = loadTagColours();
        const k = tagColourKey(body!.kind!, body!.name!);
        if (hue) m[k] = hue; else delete m[k];
        saveTagColours(m);
        out = { ok: true, tagColours: m };
      });
      return json(out, out.error ? 400 : 200);
    }

    // The board's default column view (#38). plan.json, because it is shared:
    // an agent reading the digest should get the order the owner set.
    if (req.method === "POST" && p === "/api/board-cols") {
      const body = (await req.json().catch(() => null)) as
        { slug?: string; cols?: Record<string, unknown> } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir) return json({ error: "need {slug, cols}" }, 400);
      let out: any = { error: "unwritten" };
      await enqueueItem(() => {
        const plan = loadPlan(dir);
        const c = { ...(body!.cols ?? {}) };
        for (const k of Object.keys(c)) if (c[k] == null) delete c[k];
        if (Object.keys(c).length) plan.cols = c as any; else delete plan.cols;
        savePlan(dir, plan, "board-cols");
        out = { ok: true, cols: plan.cols ?? {} };
      });
      return json(out, out.error ? 400 : 200);
    }

    // The owner's half of a verify ask (#48). Written here rather than on the
    // card because board.json has one writer and it is the CLI (charter §11);
    // askOf() puts the two halves back together for anyone reading.
    if (req.method === "POST" && p === "/api/answer") {
      const body = (await req.json().catch(() => null)) as
        { slug?: string; cardId?: string; pick?: number | null; text?: string;
          seen?: boolean; defer?: boolean } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir || !body?.cardId) return json({ error: "need {slug, cardId} plus one of {seen}, {defer}, {pick and/or text}" }, 400);
      const bd = loadBoard(dir);
      const card = bd.cards.find((c) => c.id === body.cardId);
      if (!card) return json({ error: `no card ${body.cardId}` }, 404);
      const ask = card.verify?.ask;
      if (!ask) return json({ error: `card ${body.cardId} carries no ask` }, 409);
      const answering = body.pick !== undefined || body.text !== undefined;
      if (answering && body.pick !== null && body.pick !== undefined &&
          (!Number.isInteger(body.pick) || body.pick < 0 || body.pick >= ask.options.length))
        return json({ error: `pick must be 0 to ${ask.options.length - 1}, or null for "neither"` }, 400);
      let out: any = { error: "unwritten" };
      await enqueueItem(() => {
        const plan = loadPlan(dir);
        plan.answers = plan.answers ?? {};
        const cur = plan.answers[body.cardId!] ?? {};
        const now = new Date().toISOString();
        // seen is set once and never moved: it is the timestamp of the first
        // look, not of the most recent one
        if (body.seen && !cur.seenAt) cur.seenAt = now;
        if (body.defer) { cur.deferredAt = now; cur.seenAt = cur.seenAt ?? now; }
        if (answering) {
          cur.answer = { pick: body.pick ?? null, ...(body.text ? { text: body.text } : {}), at: now };
          cur.seenAt = cur.seenAt ?? now;
        }
        plan.answers[body.cardId!] = cur;
        savePlan(dir, plan, `answer:${body.cardId}`);
        out = { ok: true, state: askState(cur), ...cur };
      });
      return json(out, out.error ? 400 : 200);
    }

    if (req.method === "POST" && p === "/api/after") {
      const body = (await req.json().catch(() => null)) as { slug?: string; cardId?: string; after?: string[] } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir || !body?.cardId) return json({ error: "need {slug, cardId, after: [ids]}" }, 400);
      const bd = loadBoard(dir);
      const alive = new Set(bd.cards.map((c) => c.id));
      if (!alive.has(body.cardId)) return json({ error: `no card ${body.cardId}` }, 404);
      const want = (body.after ?? []).filter((x) => x !== body.cardId);
      const missing = want.filter((x) => !alive.has(x));
      if (missing.length) return json({ error: `no card ${missing.join(", ")} on this board` }, 404);
      let out: any = { error: "unwritten" };
      await enqueueItem(() => {
        const plan = loadPlan(dir);
        plan.seq = plan.seq ?? {};
        if (want.length) plan.seq[body.cardId!] = want; else delete plan.seq[body.cardId!];
        savePlan(dir, plan, `after:${body.cardId}`);
        out = { ok: true, after: want };
      });
      return json(out, out.error ? 400 : 200);
    }

    // Note order is the human's, not the store's. They drag a note up because it
    // matters more, and that ranking is information an agent should see, so it
    // is persisted rather than held in the page.
    if (req.method === "POST" && p === "/api/note-order") {
      const body = (await req.json().catch(() => null)) as
        { slug?: string; cardId?: string; order?: string[] } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir || !body?.cardId || !Array.isArray(body.order)) {
        return json({ error: "need {slug, cardId, order: [noteId…]}" }, 400);
      }
      let out: { ok: true; order: string[] } | { error: string } = { error: "unwritten" };
      await enqueueNote(() => {
        const all = loadNotes(dir);
        const list = notesOf(all[body.cardId!]);
        // Reject a stale order outright rather than reconciling it: a page that
        // has the wrong set of ids also has the wrong picture of the card, and
        // silently dropping the difference would delete a note it never saw.
        const have = new Set(list.map((n) => n.id));
        const asked = new Set(body.order!);
        // Length and membership are not enough: ["a","a","b"] passes both against
        // {a,b,c} and then writes note a twice while deleting note c. The ids must
        // be a bijection onto the set, so uniqueness is checked too.
        if (body.order!.length !== list.length || asked.size !== list.length
            || !body.order!.every((id) => have.has(id))) {
          out = { error: "that ordering is out of date; reload the board" };
          return;
        }
        const byId = new Map(list.map((n) => [n.id, n]));
        const reordered = body.order!.map((id) => byId.get(id)!);
        const entry = deriveEntry(reordered, all[body.cardId!]?.activeId);
        if (entry) all[body.cardId!] = entry; else delete all[body.cardId!];
        saveNotes(dir, all, `note-order:${body.cardId}`);
        out = { ok: true, order: body.order! };
      });
      return json(out, "error" in out ? 409 : 200);
    }

    // The two selections are independent by design: a human ticking cards is
    // answering a different question from a human ticking notes, and collapsing
    // them into one list would make "send these three notes" impossible.
    if (req.method === "POST" && p === "/api/select") {
      const body = (await req.json().catch(() => null)) as
        { slug?: string; kind?: "card" | "note"; ref?: string; on?: boolean; clear?: "cards" | "notes" | "all" } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      if (!dir) return json({ error: `unknown board ${body?.slug ?? ""}` }, 404);
      let out: Selection = emptySelection();
      await enqueueItem(() => {
        const sel = loadSelection(dir);
        if (body!.clear) {
          if (body!.clear === "cards" || body!.clear === "all") sel.cards = [];
          if (body!.clear === "notes" || body!.clear === "all") sel.notes = [];
        } else {
          const list = body!.kind === "note" ? sel.notes : sel.cards;
          const ref = String(body!.ref ?? "");
          const at = list.indexOf(ref);
          if (body!.on === false || (body!.on === undefined && at >= 0)) { if (at >= 0) list.splice(at, 1); }
          else if (at < 0 && ref) list.push(ref);
        }
        sel.updatedAt = new Date().toISOString();
        saveSelection(dir, sel, "select");
        out = sel;
      });
      return json(out);
    }

    // The nudge. One press that asks whoever is working here to bring the board
    // up to date and then carry on, and that tells them what to do in each of
    // the states they might be in. The wording matters more than the plumbing:
    // an agent reading this should know what is being asked without guessing.
    if (req.method === "POST" && p === "/api/nudge") {
      const body = (await req.json().catch(() => null)) as { slug?: string } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      const reg = body?.slug ? registry().boards[body.slug] : null;
      if (!dir || !reg) return json({ error: `unknown board ${body?.slug ?? ""}` }, 404);
      const board = loadBoard(dir);
      const notes = loadNotes(dir);
      const sel = loadSelection(dir);
      const lanes = (k: string) => board.cards.filter((c) => c.lane === k).length;
      const ack = loadAck(dir);
      const unread = Object.entries(notes)
        .filter(([id, e]) => notesOf(e).some((n) => !noteSeen(ack, id, n) && !parseNoteTags(n.body).me)).length;
      const msg = [
        `[kanban] the owner pressed Nudge on board "${reg.name}".`,
        ``,
        `They are asking for two things, in this order:`,
        `1. Bring the board up to date. Run kanban.sh sync, then move/verify/brief anything`,
        `   whose real state has drifted from what the board says.`,
        `2. Carry on with what you were doing. The nudge is not a new task.`,
        ``,
        `Then, depending on where you actually are:`,
        `- Still working: say in one line what you are on, and continue. Nothing else is needed.`,
        `- Blocked: tell them WHAT is blocking you in plain direct terms, no jargon and no`,
        `  hedging, and give them your recommendation for unblocking it. If there are options,`,
        `  say which one you would pick and why. Put it on the blocked card as a note so it`,
        `  survives, and mark that card blocked if it is not already.`,
        `- Idle with a reason (waiting on them, on a review, on a deploy): name the reason and`,
        `  what would clear it.`,
        `- Idle with no reason: pick the work back up. Read the plan, the active lane and any`,
        `  unread notes, choose the next thing, say what you chose in one line, and start.`,
        `- Nothing left: say so, and suggest what you think should be next, ranked, with the`,
        `  reason for the top pick.`,
        ``,
        `Board state right now: ${lanes("active")} active, ${lanes("blocked")} blocked, `
          + `${lanes("inbox") + lanes("backlog")} waiting, ${unread} card(s) with unread notes`
          + `${sel.cards.length || sel.notes.length ? `, and ${sel.cards.length} card(s) + ${sel.notes.length} note(s) currently selected by the owner` : ""}.`,
        `Read the detail with: kanban.sh notes --unread --ack · kanban.sh selected · kanban.sh status --cards`,
      ].join("\n");
      const ipcBin = [path.join(os.homedir(), ".local", "bin", "claude-ipc"), "/usr/local/bin/claude-ipc"]
        .find((f) => fs.existsSync(f)) ?? "claude-ipc";
      ipcRegister(ipcBin);
      const peers = livePeers(reg.root).filter((x) => x.alias !== IPC_ALIAS);
      const sent: string[] = [];
      let reason = "";
      for (const peer of peers) {
        try {
          execFileSync(ipcBin, ["send", "--to", peer.alias, "--from", IPC_ALIAS, "--kind", "inform",
            "--no-reply-expected", msg], { stdio: ["ignore", "ignore", "pipe"], timeout: 8000 });
          sent.push(peer.alias);
        } catch (e: any) {
          const err = String(e?.stderr ?? "");
          reason = e?.code === "ENOENT" ? "claude-ipc is not installed where the board server can reach it"
            : err.split("\n")[0].slice(0, 140) || "the ipc broker refused the message";
        }
      }
      return json({ ok: true, sent, peers: peers.map((x) => x.alias), reason: sent.length ? "" : reason });
    }

    // Hand a draft to the agent it is addressed to. The nudge's shape with a
    // different resolver: recipients come from the draft, not from the board's
    // directory, which is the whole point of Draft.to.
    //
    // A push NEVER replaces the wait. The draft stays pending either way, so a
    // recipient who was asleep still finds it at their next sweep. Pushing is an
    // accelerator on a channel that already works, not the channel.
    if (req.method === "POST" && p === "/api/draft-send") {
      const body = (await req.json().catch(() => null)) as { id?: string } | null;
      const { drafts } = loadDrafts();
      const d = body?.id ? drafts.find((x) => x.id === body.id) : null;
      if (!d) return json({ error: `no draft ${body?.id ?? ""}` }, 404);
      const r = recipientsOf(d);
      if (!r || !r.agents.length) {
        // Refused rather than broadcast. A draft addressed to nobody in
        // particular is not a thing to shout; it is already waiting for whoever
        // sweeps, which is what "addressed to anyone" means.
        return json({ error: "this draft names no agent — address it first: kanban.sh to "
          + d.id + " agent:<alias>" }, 400);
      }
      const ipcBin = [path.join(os.homedir(), ".local", "bin", "claude-ipc"), "/usr/local/bin/claude-ipc"]
        .find((f) => fs.existsSync(f)) ?? "claude-ipc";
      ipcRegister(ipcBin);
      const head = d.title ?? d.body.split("\n").find((l) => l.trim()) ?? d.id;
      const msg = [
        `[kanban] the owner handed you a draft: "${head}".`,
        ``,
        `A draft is a document they sat down and wrote, a rung above an ask, and this`,
        `one is addressed to you by name rather than left for whoever passes.`,
        ``,
        `Read it in full, then record what you made of it:`,
        `  kanban.sh drafts ${d.id}`,
        `  kanban.sh pull ${d.id} [--card <card-id>] [--note "what you did"]`,
        ``,
        `If they revise it after you pull, it comes back to you with a diff of what`,
        `changed rather than the whole document again.`,
      ].join("\n");
      const sent: string[] = [];
      const asleep: string[] = [];
      let reason = "";
      for (const alias of r.agents) {
        if (!aliasIsLive(alias)) { asleep.push(alias); continue; }
        try {
          execFileSync(ipcBin, ["send", "--to", alias, "--from", IPC_ALIAS, "--kind", "inform",
            "--no-reply-expected", msg], { stdio: ["ignore", "ignore", "pipe"], timeout: 8000 });
          sent.push(alias);
        } catch (e: any) {
          const err = String(e?.stderr ?? "");
          reason = e?.code === "ENOENT" ? "claude-ipc is not installed where the board server can reach it"
            : err.split("\n")[0].slice(0, 140) || "the ipc broker refused the message";
        }
      }
      // Silence is the failure this reports on. "Offered" with nobody reached is
      // the exact shape that hid the owner's feedback for a day.
      return json({ ok: true, sent, asleep, addressed: r.agents,
        reason: sent.length ? "" : (reason || (asleep.length ? "nobody live — it is waiting in their inbox" : "")) });
    }

    // "Send to agent": the selection, rendered, pushed at whoever is live in
    // this project right now. It stays on disk either way — a nudge nobody was
    // around to receive must still be there at the next pickup, which is the
    // whole failure mode the pins channel has.
    if (req.method === "POST" && p === "/api/send") {
      const body = (await req.json().catch(() => null)) as { slug?: string } | null;
      const dir = body?.slug ? boardDirOf(body.slug) : null;
      const reg = body?.slug ? registry().boards[body.slug] : null;
      if (!dir || !reg) return json({ error: `unknown board ${body?.slug ?? ""}` }, 404);
      const sel = loadSelection(dir);
      if (!sel.cards.length && !sel.notes.length) return json({ error: "nothing selected" }, 400);
      const digest = renderSelection(dir, reg.name, sel);
      const peers = livePeers(reg.root);
      // pm2 inherits whatever PATH the shell that started it had, so the binary
      // is resolved explicitly. A missing binary and a down broker used to look
      // identical from the UI — both "sent nothing" — and only one of them is
      // something the human can fix.
      const ipcBin = [path.join(os.homedir(), ".local", "bin", "claude-ipc"), "/usr/local/bin/claude-ipc"]
        .find((f) => fs.existsSync(f)) ?? "claude-ipc";
      const sent: string[] = [];
      let reason = "";
      // The board is its own actor, not a session. Without --from, the broker
      // resolves the sender from the server's cwd, decides that is whichever
      // agent is working in this repo, and refuses the send as a self-send —
      // exactly the peer you most wanted to reach.
      ipcRegister(ipcBin);
      for (const peer of peers.filter((x) => x.alias !== IPC_ALIAS)) {
        try {
          execFileSync(ipcBin, ["send", "--to", peer.alias, "--from", IPC_ALIAS, "--kind", "inform",
            "--no-reply-expected", digest], { stdio: ["ignore", "ignore", "pipe"], timeout: 8000 });
          sent.push(peer.alias);
        } catch (e: any) {
          const err = String(e?.stderr ?? "");
          reason = e?.code === "ENOENT" ? "claude-ipc is not installed where the board server can reach it"
            : err.includes("not_registered") ? "the board could not register with the ipc broker"
            : err.split("\n")[0].slice(0, 140) || "the ipc broker refused the message";
        }
      }
      return json({ ok: true, sent, peers: peers.map((p) => p.alias), reason: sent.length ? "" : reason,
        cards: sel.cards.length, notes: sel.notes.length });
    }

    if (req.method === "POST" && p === "/api/pin") {
      const body = (await req.json().catch(() => null)) as
        { kind?: "card" | "item" | "board" | "archived"; ref?: string; slug?: string; label?: string } | null;
      // "archived" is a board the owner has said is not theirs right now. It rides
      // the pin store rather than a new file because a pin is already a toggle
      // and already owner-only, which is exactly what this is.
      const PIN_KINDS = ["card", "item", "board", "archived"];
      if (!body?.ref || !PIN_KINDS.includes(body.kind as string)) {
        return json({ error: `need {kind: ${PIN_KINDS.join("|")}, ref}` }, 400);
      }
      // Same refusals its siblings make: /api/item checks the board, /api/note
      // caps the size, and cli.ts refuses a card on no board because the link
      // would be dead on arrival. A pin pointing at nothing is that same defect.
      if (body.slug && !registry().boards[body.slug]) return json({ error: `unknown board ${body.slug}` }, 404);
      if ((body.label?.length ?? 0) > 200) return json({ error: "pin label over 200 chars" }, 413);
      if ((body.kind === "board" || body.kind === "archived") && !registry().boards[body.ref]) {
        return json({ error: `no board ${body.ref}` }, 404);
      }
      if (body.kind === "item" && !loadItems().items.some((i) => i.id === body.ref)) {
        return json({ error: `no ask ${body.ref}` }, 404);
      }
      if (body.kind === "card") {
        const onBoard = Object.keys(registry().boards).some((s) => {
          try { return loadBoard(path.join(KROOT, "boards", s)).cards.some((c) => c.id === body.ref); } catch { return false; }
        });
        if (!onBoard) return json({ error: `card ${body.ref} is not on any board` }, 404);
      }
      let out: { ok: true; pinned: boolean } = { ok: true, pinned: false };
      await enqueueItem(() => {
        const file = loadPins();
        const at = file.pins.findIndex((x) => x.kind === body.kind && x.ref === body.ref);
        if (at >= 0) { file.pins.splice(at, 1); out = { ok: true, pinned: false }; }
        else {
          const pin: Pin = { id: noteId(), kind: body.kind!, ref: body.ref!, at: new Date().toISOString(),
            ...(body.slug ? { slug: body.slug } : {}), ...(body.label ? { label: body.label } : {}) };
          file.pins.push(pin);
          out = { ok: true, pinned: true };
        }
        atomicWrite(PINS, file, "pin", `pins=${file.pins.length}`);
      });
      return json(out);
    }

    return json({ error: `method ${req.method} not supported on ${p}` }, 405);
  },
});

// Startup self-config: record where we live so the CLI's open/check find us.
// This file is server-owned (single-writer split), written once per boot.
atomicWrite(SERVER_INFO, { port: server.port, pid: process.pid, startedAt: new Date().toISOString() }, "server-boot");
console.log(`[kanban] serving on http://127.0.0.1:${server.port} (boards: ${Object.keys(registry().boards).length})`);
