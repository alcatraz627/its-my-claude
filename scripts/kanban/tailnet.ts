// Serves decision pages, and nothing else, at this Mac's tailnet address, so
// another of the owner's devices on the tailnet can open and answer a page.
//
// The main server stays on loopback. This second listener answers only the
// decision-page routes and returns 404 for everything else, because the rest of
// the server (the doc viewer, sends, board writes) must never be reachable off
// this machine. Every POST must come from a page this listener served: its
// Origin and Host must both be the tailnet address, which also defeats DNS
// rebinding. Design: assets/reports/20261024-bfb-hub/bfb-synthesis.md, G8.

import * as fs from "node:fs";
import * as path from "node:path";
import { execFileSync } from "node:child_process";

const POST_ROUTES = ["/api/dp-submit/", "/api/dp-seen/", "/api/dp-compose/", "/api/dp-parse/"];

function tailnetIp(): { ip: string | null; why: string } {
  for (const bin of ["/opt/homebrew/bin/tailscale", "/usr/local/bin/tailscale",
                     "/Applications/Tailscale.app/Contents/MacOS/Tailscale", "tailscale"]) {
    try {
      // `ip -4` keeps printing the last address after Tailscale stops, so the
      // backend state decides whether that address is actually on this Mac.
      const st = JSON.parse(execFileSync(bin, ["status", "--json", "--peers=false"],
        { encoding: "utf8", timeout: 3000, stdio: ["ignore", "pipe", "ignore"] }));
      if (st.BackendState !== "Running") return { ip: null, why: `Tailscale is ${String(st.BackendState ?? "not running").toLowerCase()}` };
      const ip = (st.TailscaleIPs ?? st.Self?.TailscaleIPs ?? []).find((a: string) => /^100\.\d+\.\d+\.\d+$/.test(a));
      if (ip) return { ip, why: "" };
      return { ip: null, why: "Tailscale is running but has no IPv4 tailnet address" };
    } catch { /* try the next install location */ }
  }
  return { ip: null, why: "Tailscale is not installed or not answering" };
}

const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]!));

// The page list a phone sees at /dp/: every page, pending first, newest next,
// linked by the tailnet address so a tap stays on the tailnet.
function listing(dpRoot: string, base: string): Response {
  let pending = new Set<string>();
  try {
    pending = new Set(fs.readFileSync(path.join(dpRoot, ".pending.txt"), "utf8").split("\n").map((x) => x.trim()).filter(Boolean));
  } catch { /* no ledger means nothing is pending */ }
  const pages: { slug: string; title: string; pending: boolean; mtime: number }[] = [];
  for (const slug of fs.readdirSync(dpRoot)) {
    const cfg = path.join(dpRoot, slug, "config.json");
    if (!/^[a-z0-9][a-z0-9._-]*$/.test(slug) || !fs.existsSync(cfg)) continue;
    let title = slug;
    try { title = JSON.parse(fs.readFileSync(cfg, "utf8")).title || slug; } catch {}
    pages.push({ slug, title, pending: pending.has(slug), mtime: fs.statSync(cfg).mtimeMs });
  }
  pages.sort((a, b) => Number(b.pending) - Number(a.pending) || b.mtime - a.mtime);
  const rows = pages.map((p) => `<li${p.pending ? ' class="pending"' : ""}><a href="${base}/dp/${encodeURIComponent(p.slug)}/?view=bfb">${esc(p.title)}</a>` +
    `${p.pending ? " <span>waiting on you</span>" : ""}</li>`).join("\n");
  return new Response(`<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Decision pages</title>
<style>body{font:16px/1.5 system-ui,sans-serif;margin:0 auto;max-width:40rem;padding:1rem;background:#fff;color:#111}
@media (prefers-color-scheme:dark){body{background:#111;color:#eee}a{color:#8ab4ff}}
ul{list-style:none;padding:0}li{padding:.6rem 0;border-bottom:1px solid #8884}span{font-size:.8rem;color:#c80}</style>
<h1>Decision pages</h1><ul>
${rows || "<li>No decision pages.</li>"}
</ul>`, { headers: { "content-type": "text/html; charset=utf-8" } });
}

const RETRY_MS = 60_000;

// Tries now, then once a minute until it binds, so starting Tailscale later
// needs no server restart. It logs only when the reason changes.
export function startTailnetListener(main: { fetch(req: Request): Response | Promise<Response> }, port: number, dpRoot: string): void {
  let last = "";
  const attempt = (): boolean => {
    const why = bindTailnet(main, port, dpRoot);
    if (why === null) return true;
    if (why !== last) console.log(`[kanban] tailnet listener not up: ${why}. Retrying every minute.`);
    last = why;
    return false;
  };
  if (attempt()) return;
  const t = setInterval(() => { if (attempt()) clearInterval(t); }, RETRY_MS);
}

// Binds the listener; null on success, else why it could not.
function bindTailnet(main: { fetch(req: Request): Response | Promise<Response> }, port: number, dpRoot: string): string | null {
  const { ip, why } = tailnetIp();
  if (!ip) return why;
  const origin = `http://${ip}:${port}`;
  const host = `${ip}:${port}`;
  try {
    Bun.serve({
      hostname: ip, port,
      fetch(req) {
        const p = new URL(req.url).pathname;
        if (req.method === "POST") {
          if (!POST_ROUTES.some((r) => p.startsWith(r))) return new Response("not found", { status: 404 });
          if (req.headers.get("origin") !== origin || req.headers.get("host") !== host)
            return new Response("refused: this page was not served by this address", { status: 403 });
          return main.fetch(req);
        }
        if (req.method !== "GET" && req.method !== "HEAD") return new Response("not found", { status: 404 });
        if (p === "/dp" || p === "/dp/") return listing(dpRoot, origin);
        if (p.startsWith("/dp/") || p.startsWith("/dp-assets/") || p === "/favicon.ico" || p === "/favicon.svg")
          return main.fetch(req);
        return new Response("not found", { status: 404 });
      },
    });
    console.log(`[kanban] decision pages on the tailnet at ${origin}/dp/`);
    return null;
  } catch (e: any) {
    return `could not bind ${host} (${e?.message ?? e})`;
  }
}
