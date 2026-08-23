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
  loadPlan, savePlan, findTag, tagKey, TAG_PRESETS, presetFor, type Plan, type TagKind,
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

// Hand-rolled markdown→html for the doc viewer — zero dependencies, not full CommonMark.
function renderMd(input: string): string {
  // \r is a line terminator in JS, so `.` never matches it: without this every
  // heading, list and table in a CRLF file falls through to a paragraph.
  const src = input.replace(/\r\n?/g, "\n");
  const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  // GFM, kept incremental on the owner's own fence ("I don't want to overcomplicate
  // just incrementally improv"): strikethrough, emphasis, bare-URL autolinks.
  //
  // Code spans are lifted OUT first and put back LAST. Replacing them in place is
  // not enough, and that is the whole reason for the detour: every later pass
  // still walks the produced string, so `~~x~~` inside backticks came back struck
  // through. Markup inside code must stay literal, or code cannot quote markup.
  const inline = (s: string) => {
    const spans: string[] = [];
    let out = s.replace(/`([^`]+)`/g, (_m, code) => `\u0000${spans.push(code) - 1}\u0000`);
    out = out
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/~~([^~]+)~~/g, "<del>$1</del>")
      .replace(/(^|[\s(])\*([^*\s][^*]*)\*(?=[\s).,;:!?]|$)/g, "$1<em>$2</em>")
      .replace(/\[([^\]]+)\]\((https?:[^)]+)\)/g, `<a href="$2" rel="noopener">$1</a>`)
      .replace(/(^|[\s(])(https?:\/\/[^\s<)]+)/g, `$1<a href="$2" rel="noopener">$2</a>`);
    return out.replace(/\u0000(\d+)\u0000/g, (_m, n) => `<code>${spans[Number(n)]}</code>`);
  };
  const out: string[] = [];
  // Blocks carry the source line they started on, so /doc?line=N can scroll to
  // the place a card was harvested from. The fence split eats one line per ```.
  let srcLine = 1;
  const anchor = (n: number) => ` id="L${n}"`;
  // split on line-initial fences only: a ``` inside inline code is not a fence,
  // and treating it as one swallowed the rest of the document into a <pre>
  src.replace(/<!--[\s\S]*?-->/g, "").split(/^[ \t]*```[^\n]*$/m).forEach((block, i) => {
    const blockStart = srcLine;
    srcLine += block.split("\n").length - 1;
    if (i % 2 === 1) { out.push(`<pre${anchor(blockStart)}><code>${esc(block.replace(/^[a-z]*\n/, ""))}</code></pre>`); return; }
    const lines = esc(block).split("\n");
    let para: string[] = [];
    let paraLine = blockStart;
    let listLine = blockStart;
    let list: { tag: "ul" | "ol"; items: string[] } | null = null;
    let table: string[][] | null = null;
    const flushPara = () => { if (para.length) { out.push(`<p${anchor(paraLine)}>${inline(para.join(" "))}</p>`); para = []; } };
    const flushList = () => {
      if (list) { out.push(`<${list.tag}${anchor(listLine)}>` + list.items.map((x) => `<li>${inline(x)}</li>`).join("") + `</${list.tag}>`); list = null; }
    };
    const flushTable = () => {
      if (!table) return;
      const [head, ...rows] = table;
      out.push(
        "<table><thead><tr>" + head.map((c) => `<th>${inline(c)}</th>`).join("") + "</tr></thead><tbody>" +
        rows.map((r) => "<tr>" + r.map((c) => `<td>${inline(c)}</td>`).join("") + "</tr>").join("") + "</tbody></table>",
      );
      table = null;
    };
    const flushAll = () => { flushPara(); flushList(); flushTable(); };
    for (const [idx, l] of lines.entries()) {
      const here = blockStart + idx;
      if (!para.length) paraLine = here;
      if (!list) listLine = here;
      const h = l.match(/^(#{1,6}) (.*)$/);
      if (h) { flushAll(); out.push(`<h${h[1].length}${anchor(here)}>${inline(h[2])}</h${h[1].length}>`); continue; }
      if (/^\s*\|.*\|\s*$/.test(l)) {
        flushPara(); flushList();
        const cells = l.trim().replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
        if (cells.every((c) => /^:?-{2,}:?$/.test(c))) continue; // separator row
        (table ??= []).push(cells);
        continue;
      }
      flushTable();
      const ol = l.match(/^\s*\d+\.\s+(.*)$/);
      const ul = l.match(/^\s*[-*]\s+(.*)$/);
      // A checkbox is what the harvester reads to mint a card, so a doc full of
      // them rendering as literal "[ ]" was the one gap worth closing here.
      const box = ul && ul[1].match(/^\[([ xX])\]\s+(.*)$/);
      if (ol || ul) {
        flushPara();
        const tag: "ul" | "ol" = ol ? "ol" : "ul";
        if (!list || list.tag !== tag) { flushList(); list = { tag, items: [] }; }
        list.items.push(box
          ? `<span class="tbox${box[1] === " " ? "" : " on"}">${box[1] === " " ? "" : "\u2713"}</span>${inline(box[2])}`
          : (ol ?? ul)![1]);
        continue;
      }
      if (/^---+$/.test(l.trim())) { flushAll(); out.push("<hr>"); continue; }
      if (!l.trim()) { flushAll(); continue; }
      // A hard-wrapped list item continues on the following line; markdown calls
      // this a lazy continuation. Without it any wrapped bullet ENDED its list and
      // the rest of the sentence became a paragraph outside it, so a hard-wrapped
      // ordered list rendered as a run of one-item lists each numbered "1." with
      // its second half adrift. Every doc in this repo is wrapped at ~80 columns,
      // so this was the common case rather than an edge one.
      if (list && list.items.length) { list.items[list.items.length - 1] += " " + l.trim(); continue; }
      flushList();
      para.push(l.trim());
    }
    flushAll();
  });
  return out.join("\n");
}

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
  let real: string;
  try { real = fs.realpathSync(path.resolve(reqPath)); } catch { return { error: `no such file: ${reqPath}`, status: 404 }; }
  const allowed = roots.some((r) => { try { const rr = fs.realpathSync(r); return real === rr || real.startsWith(rr + path.sep); } catch { return false; } });
  if (!allowed) return { error: `path outside allowlisted roots (board projects + ~/.claude/assets/reports + ~/.claude/scratchpad)`, status: 403 };
  if (!/\.(md|txt|markdown)$/i.test(real)) return { error: "doc viewer renders .md/.txt only", status: 415 };
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
function docResponse(reqPath: string, line = 0, embed = false,
                     back: { slug: string; card: string } = { slug: "", card: "" }): Response {
  const r = resolveDocPath(reqPath);
  if ("error" in r) {
    if (r.status !== 404) return json({ error: r.error }, r.status);
    // a human lands here from a stale card link; JSON is the wrong shape
    return new Response(
      `<!doctype html><meta charset="utf-8"><link rel="icon" href="/favicon.svg"><title>doc not found</title>
<style>body{background:#14161a;color:#d8dde4;font:15px/1.6 -apple-system,sans-serif;max-width:640px;margin:18vh auto;padding:0 1rem}
code{background:#1b1e24;border:1px solid #2a2f37;border-radius:4px;padding:1px 5px}p{color:#8a93a0}</style>
<h2>This document is gone</h2>
<p><code>${reqPath.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c] ?? c))}</code></p>
<p>The board is a mirror of your docs at sync time; this source file has since moved
or been deleted. Re-sync the board to drop stale cards: <code>kanban.sh sync</code></p>`,
      { status: 404, headers: { "content-type": "text/html; charset=utf-8" } },
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
body{background:var(--canvas);color:var(--text);font:15px/1.68 var(--sans);margin:0}
.docwrap{max-width:860px;margin:26px auto;padding:0 20px}
code,pre{background:var(--well);border:1px solid var(--border);border-radius:4px;padding:1px 4px}
pre{padding:10px;overflow-x:auto}h1,h2,h3{line-height:1.3}a{color:var(--blue)}hr{border:0;border-top:1px solid var(--border)}
table{border-collapse:collapse;margin:10px 0;display:block;overflow-x:auto;max-width:100%}
th,td{border:1px solid var(--border);padding:5px 10px;text-align:left;vertical-align:top}th{background:var(--well)}
.hit{background:var(--well);outline:2px dotted var(--blue);outline-offset:6px;border-radius:3px}
.docmeta{display:flex;align-items:center;gap:9px;font:11.5px/1.5 var(--mono);color:var(--text-3);
         padding:9px 11px;border:1px solid var(--border);border-radius:8px;background:var(--well);margin-bottom:20px}
.docmeta .dsp{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.docmeta .ro{flex:none}
*{scrollbar-width:thin;scrollbar-color:var(--border) transparent}</style>
${embed ? "" : `<header id="phead"></header>`}
${embed ? body : `<div class="docwrap"><div class="docmeta">
  ${back.slug ? `<a href="/b/${back.slug}${back.card ? `?card=${back.card}` : ""}" data-tip="Back to the card that linked this">&larr; back to the board</a>` : ""}
  <span class="dsp">${real}</span><span class="ro">read-only mirror</span></div>${body}</div>`}
${embed ? "" : `<script src="/shared.js"></script>`}
<script>${embed ? `const applyTheme=t=>{document.documentElement.dataset.theme=t;localStorage.setItem("kanban-theme",t)};
applyTheme(localStorage.getItem("kanban-theme")||"dark");` : `pageHead({ mount: "#phead", active: "boards",
  title: ${JSON.stringify(path.basename(real))}, sub: "a document the board reads, shown read-only" });`}
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
      if (p === "/") return html("hub.html");
      // A destination, not a mode: its own data model and its own canvas, so it
      // earns a URL you could send someone (v2-plan.md:151).
      if (p === "/drafts") return html("drafts.html");
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
              stack: b.stack ?? [], branch: b.branch ?? null };
            } catch {
              // unreadable board data: say so in place rather than 500 the fleet
              return { slug, name: b.name, root: b.root, broken: true,
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
        return json({ slug, name: reg.name, root: reg.root, board: bd,
          notes: loadNotes(dir), ackTs: loadAck(dir).lastAckTs, live: livePeers(reg.root),
          selection: loadSelection(dir), plan, presets: TAG_PRESETS });
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
        const f = path.join(HERE, "UI-CHARTER.md");
        if (!fs.existsSync(f)) return json({ error: "UI-CHARTER.md is not beside the server" }, 404);
        const src = fs.readFileSync(f, "utf8");
        return json({ html: renderMd(src), bytes: src.length,
                      mtime: fs.statSync(f).mtime.toISOString() });
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
