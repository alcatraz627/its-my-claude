#!/usr/bin/env bun
// The kanban hub server. Sole writer of notes.json (POST /api/note); everything
// else read-only. Localhost-only tier-2 pm2 service, port via ports.sh (D1a).

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import {
  KROOT, SERVER_INFO, LANES, atomicWrite, registry, loadBoard, loadNotes, saveNotes,
  loadAck, parseNoteTags,
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

// Hand-rolled markdown→html for the doc viewer — zero dependencies, not full CommonMark.
function renderMd(src: string): string {
  const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const inline = (s: string) =>
    s.replace(/`([^`]+)`/g, "<code>$1</code>")
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/\[([^\]]+)\]\((https?:[^)]+)\)/g, `<a href="$2" rel="noopener">$1</a>`);
  const out: string[] = [];
  src.replace(/<!--[\s\S]*?-->/g, "").split(/```/).forEach((block, i) => {
    if (i % 2 === 1) { out.push(`<pre><code>${esc(block.replace(/^[a-z]*\n/, ""))}</code></pre>`); return; }
    const lines = esc(block).split("\n");
    let para: string[] = [];
    let list: { tag: "ul" | "ol"; items: string[] } | null = null;
    let table: string[][] | null = null;
    const flushPara = () => { if (para.length) { out.push(`<p>${inline(para.join(" "))}</p>`); para = []; } };
    const flushList = () => {
      if (list) { out.push(`<${list.tag}>` + list.items.map((x) => `<li>${inline(x)}</li>`).join("") + `</${list.tag}>`); list = null; }
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
    for (const l of lines) {
      const h = l.match(/^(#{1,6}) (.*)$/);
      if (h) { flushAll(); out.push(`<h${h[1].length}>${inline(h[2])}</h${h[1].length}>`); continue; }
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

function docResponse(reqPath: string): Response {
  // Owner-ratified scope (F6a): board projects + reports + scratchpad — never
  // the whole ~/.claude, which holds private ledgers.
  const roots = [
    ...Object.values(registry().boards).map((b) => b.root),
    path.join(os.homedir(), ".claude", "assets", "reports"),
    path.join(os.homedir(), ".claude", "scratchpad"),
  ];
  let real: string;
  try { real = fs.realpathSync(path.resolve(reqPath)); } catch { return json({ error: `no such file: ${reqPath}` }, 404); }
  const allowed = roots.some((r) => { try { const rr = fs.realpathSync(r); return real === rr || real.startsWith(rr + path.sep); } catch { return false; } });
  if (!allowed) return json({ error: `path outside allowlisted roots (board projects + ~/.claude/assets/reports + ~/.claude/scratchpad)` }, 403);
  if (!/\.(md|txt|markdown)$/i.test(real)) return json({ error: "doc viewer renders .md/.txt only" }, 415);
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
#theme{position:fixed;top:12px;right:12px;background:var(--surface);color:var(--text);border:1px solid var(--border);border-radius:6px;padding:4px 10px;cursor:pointer;font:inherit}
*{scrollbar-width:thin;scrollbar-color:var(--border) transparent}</style>
<button id="theme" title="toggle theme">◐</button>
<p style="color:var(--dim)">${real} · read-only</p>${body}
<script>const applyTheme=t=>{document.documentElement.dataset.theme=t;localStorage.setItem("kanban-theme",t)};
applyTheme(localStorage.getItem("kanban-theme")||"dark");
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
      if (p === "/api/boards") {
        const reg = registry();
        return json({
          boards: Object.entries(reg.boards).map(([slug, b]) => {
            const bdir = path.join(KROOT, "boards", slug);
            const board = loadBoard(bdir);
            const counts = Object.fromEntries(LANES.map((l) => [l, board.cards.filter((c) => c.lane === l).length]));
            // hub attention-weighting (M1): agent-relevant unread (@me excluded,
            // same definition as cli notes --unread) + cards the human flagged
            const notes = Object.values(loadNotes(bdir)).filter((n) => n.note);
            const ackTs = loadAck(bdir).lastAckTs;
            const unread = notes.filter((n) => Date.parse(n.updatedAt) > ackTs && !parseNoteTags(n.note).me).length;
            const reviewMe = notes.filter((n) => parseNoteTags(n.note).review).length;
            return { slug, name: b.name, root: b.root, counts, unread, reviewMe, syncedAt: board.syncedAt };
          }),
        });
      }
      if (p === "/api/board") {
        const slug = url.searchParams.get("slug") ?? "";
        const dir = boardDirOf(slug);
        if (!dir) return json({ error: `unknown board ${slug}` }, 404);
        const reg = registry().boards[slug];
        return json({ slug, name: reg.name, root: reg.root, board: loadBoard(dir), notes: loadNotes(dir) });
      }
      if (p === "/doc") return docResponse(url.searchParams.get("path") ?? "");
      return json({ error: `no route ${p}` }, 404);
    }

    if (req.method === "POST" && p === "/api/note") {
      const body = (await req.json().catch(() => null)) as { slug?: string; cardId?: string; note?: string } | null;
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
      await enqueueNote(() => {
        const notes = loadNotes(dir);
        if (body.note!.trim() === "") delete notes[body.cardId!];
        else notes[body.cardId!] = { note: body.note!, updatedAt: new Date().toISOString() };
        saveNotes(dir, notes, `note:${body.cardId}`);
      });
      return json({ ok: true, savedAt: new Date().toISOString() });
    }

    return json({ error: `method ${req.method} not supported on ${p}` }, 405);
  },
});

// Startup self-config: record where we live so the CLI's open/check find us.
// This file is server-owned (single-writer split), written once per boot.
atomicWrite(SERVER_INFO, { port: server.port, pid: process.pid, startedAt: new Date().toISOString() }, "server-boot");
console.log(`[kanban] serving on http://127.0.0.1:${server.port} (boards: ${Object.keys(registry().boards).length})`);
