#!/usr/bin/env bun
// The kanban hub server. Sole writer of notes.json (POST /api/note); everything
// else read-only. Localhost-only tier-2 pm2 service, port via ports.sh (D1a).

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import {
  KROOT, SERVER_INFO, LANES, PINS, atomicWrite, registry, loadBoard, loadNotes, saveNotes,
  loadAck, parseNoteTags, notesOf, deriveEntry, noteId, noteSeen,
  loadItems, saveItems, loadLandings, loadPins, isArchived, type Item, type Pin,
} from "./lib.ts";

const portArg = process.argv.indexOf("--port");
const PORT = portArg >= 0 ? Number(process.argv[portArg + 1]) : NaN;
if (!Number.isInteger(PORT)) {
  console.error("server: --port <claimed-port> is required — fix: ports.sh claim kanban --tier 2, then pass the printed port");
  process.exit(1);
}

const HERE = import.meta.dir;
const html = (name: string) => new Response(fs.readFileSync(path.join(HERE, name)), { headers: { "content-type": "text/html; charset=utf-8" } });
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
  const inline = (s: string) =>
    s.replace(/`([^`]+)`/g, "<code>$1</code>")
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/\[([^\]]+)\]\((https?:[^)]+)\)/g, `<a href="$2" rel="noopener">$1</a>`);
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
      if (ol || ul) {
        flushPara();
        const tag: "ul" | "ol" = ol ? "ol" : "ul";
        if (!list || list.tag !== tag) { flushList(); list = { tag, items: [] }; }
        list.items.push((ol ?? ul)![1]);
        continue;
      }
      if (/^---+$/.test(l.trim())) { flushAll(); out.push("<hr>"); continue; }
      if (!l.trim()) { flushAll(); continue; }
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
function livePeers(root: string): string[] {
  if (ipcMissing) return [];
  let db: any = null;
  try {
    if (!fs.existsSync(IPC_DB)) { ipcMissing = true; return []; }
    // lazy: a machine with no ipc broker never pays for the sqlite driver
    const { Database } = require("bun:sqlite");
    // opened per call on purpose: a kept handle pins a WAL snapshot, so
    // last_seen freezes while the clock moves and every peer ages out to dead.
    db = new Database(IPC_DB, { readonly: true });
    // the broker's own status is authoritative; this window only discards rows
    // a dead broker left behind. Heartbeats run every few minutes, so 15 is safe.
    const cutoff = Date.now() / 1000 - 900;
    const rows = db.query(
      "select alias, cwd from registry_snapshot where status in ('live','idle') and last_seen > ?1",
    ).all(cutoff) as { alias: string; cwd: string }[];
    const real = fs.realpathSync(root);
    const named = rows
      .filter((r) => r.cwd === real || r.cwd?.startsWith(real + path.sep))
      .map((r) => r.alias)
      // drop only auto-generated aliases: a bare uuid, or <project>-<8 hex>
      // where the project half matches this board. "sprint-deadbeef" survives.
      .filter((a) => !/^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(a))
      .filter((a) => !new RegExp(`^${path.basename(real).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}-[0-9a-f]{8}$`, "i").test(a));
    return [...new Set(named)].sort();
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
function docResponse(reqPath: string, line = 0, embed = false): Response {
  const r = resolveDocPath(reqPath);
  if ("error" in r) {
    if (r.status !== 404) return json({ error: r.error }, r.status);
    // a human lands here from a stale card link; JSON is the wrong shape
    return new Response(
      `<!doctype html><meta charset="utf-8"><title>doc not found</title>
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
    `<!doctype html><meta charset="utf-8"><title>${path.basename(real)}</title>
<style>:root{--bg:#14161a;--text:#d8dde4;--dim:#8a93a0;--border:#2a2f37;--surface:#1b1e24;--accent:#6ea8fe}
[data-theme="light"]{--bg:#faf9f7;--text:#20242a;--dim:#6b7280;--border:#e2e0dc;--surface:#fff;--accent:#2563eb}
body{background:var(--bg);color:var(--text);font:15px/1.6 -apple-system,sans-serif;max-width:860px;margin:2rem auto;padding:0 1rem}
code,pre{background:var(--surface);border:1px solid var(--border);border-radius:4px;padding:1px 4px}
pre{padding:10px;overflow-x:auto}h1,h2,h3{line-height:1.3}a{color:var(--accent)}hr{border:0;border-top:1px solid var(--border)}
table{border-collapse:collapse;margin:10px 0;display:block;overflow-x:auto;max-width:100%}
th,td{border:1px solid var(--border);padding:5px 10px;text-align:left;vertical-align:top}th{background:var(--surface)}
.hit{background:var(--surface);outline:2px solid var(--accent);outline-offset:6px;border-radius:3px}
#theme{position:fixed;top:12px;right:12px;background:var(--surface);color:var(--text);border:1px solid var(--border);border-radius:6px;padding:4px 10px;cursor:pointer;font:inherit}
*{scrollbar-width:thin;scrollbar-color:var(--border) transparent}</style>
${embed ? "" : `<button id="theme" title="toggle theme">◐</button>`}
${embed ? "" : `<p style="color:var(--dim)">${real} · read-only</p>`}${body}
<script>const applyTheme=t=>{document.documentElement.dataset.theme=t;localStorage.setItem("kanban-theme",t)};
applyTheme(localStorage.getItem("kanban-theme")||"dark");
const want=${line || 0};
if(want){const els=[...document.querySelectorAll("[id^=L]")].filter(e=>/^L\\d+$/.test(e.id));
 const hit=els.filter(e=>+e.id.slice(1)<=want).pop()||els[0];
 if(hit){hit.classList.add("hit");hit.scrollIntoView({block:"center"});}}
document.getElementById("theme").onclick=()=>applyTheme(document.documentElement.dataset.theme==="dark"?"light":"dark");</script>`,
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
      if (p === "/") return html("hub.html");
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
        return json({ slug, name: reg.name, root: reg.root, board: loadBoard(dir),
          notes: loadNotes(dir), ackTs: loadAck(dir).lastAckTs, live: livePeers(reg.root) });
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
          .filter((i) => !want || i.slug === want || !i.slug)
          .map((i) => ({
            ...i,
            boardName: i.slug ? names[i.slug] ?? null : null,
            landing: landings[i.id] ?? null,
            landedCard: landings[i.id]?.cardId ? cardTitles.get(landings[i.id]!.cardId!) ?? null : null,
            archived: isArchived({ landings }, i.id),
          }))
          .sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
        return json({ items: rows, pins: pinRows });
      }
      if (p === "/doc") {
        return docResponse(url.searchParams.get("path") ?? "", Number(url.searchParams.get("line") ?? 0),
          url.searchParams.get("embed") === "1");
      }
      if (p === "/api/docseg") return docSegment(url.searchParams.get("path") ?? "", Number(url.searchParams.get("line") ?? 0));
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
        { id?: string; body?: string; slug?: string; star?: boolean; trigger?: boolean } | null;
      if (!body) return json({ error: "need a JSON body" }, 400);
      if (body.slug && !registry().boards[body.slug]) return json({ error: `unknown board ${body.slug}` }, 404);
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
        if (body.star !== undefined) { if (body.star) it.starred = true; else delete it.starred; }
        if (body.trigger !== undefined) { if (body.trigger) it.triggered = now; else delete it.triggered; }
        saveItems(file, `item:${body.id}`);
        out = { ok: true, id: body.id! };
      });
      if ("error" in out) return json(out, out.error.includes("gone") ? 409 : 500);
      return json(out);
    }

    // A pin is owner-only and read-side; no agent reads this file. Posting an
    // existing ref removes it, so the star and pin controls both toggle.
    if (req.method === "POST" && p === "/api/pin") {
      const body = (await req.json().catch(() => null)) as
        { kind?: "card" | "item"; ref?: string; slug?: string; label?: string } | null;
      if (!body?.ref || (body.kind !== "card" && body.kind !== "item")) {
        return json({ error: "need {kind: card|item, ref}" }, 400);
      }
      // Same refusals its siblings make: /api/item checks the board, /api/note
      // caps the size, and cli.ts refuses a card on no board because the link
      // would be dead on arrival. A pin pointing at nothing is that same defect.
      if (body.slug && !registry().boards[body.slug]) return json({ error: `unknown board ${body.slug}` }, 404);
      if ((body.label?.length ?? 0) > 200) return json({ error: "pin label over 200 chars" }, 413);
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
