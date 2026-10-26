// Records what today's decision page composes, so a replacement composer can be
// held to it byte for byte after the old page is gone.
//
// Each answered page is re-composed in headless Chrome from its parsed answer;
// synthetic configs cover the paths no real page used. Seen and submit calls are
// blocked, so a capture never marks a real page. Writes golden.json (synthetic)
// beside this file and .golden-real.json in the registry; exits 1 if any real
// page fails to reproduce.
//   bun ~/.claude/scripts/decision-page/golden/capture.ts

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const HOME = os.homedir();
const DP_ROOT = path.join(HOME, ".claude/assets/decision-pages");
const HERE = path.dirname(new URL(import.meta.url).pathname);
const BASE = "http://127.0.0.1:5106";
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

type Cfg = { title?: string; copyHeader?: string; decisions?: any[]; sections?: any[]; notes?: boolean; storageKey?: string };
type State = { d: Record<string, string>; dnotes: Record<string, string>;
  screens: Record<string, { agree: boolean; note: string }>; endnotes: string };

// The inverse of the page's answerString(): turn a stored answer back into the
// picks and notes that produce it. Multi-line notes continue until the next
// line that starts a known item.
export function parseAnswer(answer: string, cfg: Cfg): State {
  const decisions = cfg.decisions || [], sections = cfg.sections || [];
  const st: State = { d: {}, dnotes: {}, screens: {}, endnotes: "" };
  for (const d of decisions) st.dnotes[d.id] = "";
  for (const s of sections) st.screens[s.id] = { agree: true, note: "" };
  const lines = answer.split("\n");
  let i = 1;
  if (decisions.length) {
    const toks = (lines[1] || "").split(" ");
    decisions.forEach((d, k) => { const t = toks[k] || ""; if (t.startsWith(d.id)) st.d[d.id] = t.slice(d.id.length); });
    i = 2;
  }
  const secIds = sections.map((s) => s.id).sort((a, b) => b.length - a.length);
  let cur: ((more: string) => void) | null = null;
  for (; i < lines.length; i++) {
    const ln = lines[i];
    if (ln === "notes:") { st.endnotes = lines.slice(i + 1).join("\n"); break; }
    if (ln === "all items: agree as drafted") { cur = null; continue; }
    const dn = decisions.find((d) => ln.startsWith(`${d.id} note — `));
    if (dn) {
      st.dnotes[dn.id] = ln.slice(`${dn.id} note — `.length);
      cur = (m) => { st.dnotes[dn.id] += "\n" + m; };
      continue;
    }
    const sid = secIds.find((id) => ln.startsWith(`${id}: agree`) || ln.startsWith(`${id}: DISAGREE`));
    if (sid) {
      const rest = ln.slice(sid.length + 2);
      const agree = rest.startsWith("agree");
      const after = rest.slice(agree ? 5 : 8);
      st.screens[sid] = { agree, note: after.startsWith(" — ") ? after.slice(3) : "" };
      cur = (m) => { st.screens[sid].note += "\n" + m; };
      continue;
    }
    if (cur) cur(ln);
  }
  return st;
}

// A minimal Chrome DevTools Protocol client: one page, request and reply by id.
async function chrome() {
  const prof = fs.mkdtempSync(path.join(os.tmpdir(), "dp-golden-"));
  const proc = Bun.spawn([CHROME, "--headless=new", "--remote-debugging-port=0", `--user-data-dir=${prof}`,
    "--no-first-run", "--no-default-browser-check", "about:blank"], { stdout: "ignore", stderr: "ignore" });
  const portFile = path.join(prof, "DevToolsActivePort");
  for (let t = 0; t < 100 && !fs.existsSync(portFile); t++) await Bun.sleep(100);
  const port = fs.readFileSync(portFile, "utf8").split("\n")[0];
  let pages: any[] = [];
  for (let t = 0; t < 50 && !pages.length; t++) {
    pages = ((await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()) as any[]).filter((p) => p.type === "page");
    if (!pages.length) await Bun.sleep(100);
  }
  const ws = new WebSocket(pages[0].webSocketDebuggerUrl);
  await new Promise((r) => (ws.onopen = r));
  let id = 0;
  const waiting = new Map<number, (v: any) => void>();
  ws.onmessage = (e) => { const m = JSON.parse(String(e.data)); if (m.id && waiting.has(m.id)) { waiting.get(m.id)!(m); waiting.delete(m.id); } };
  const send = (method: string, params: any = {}) => new Promise<any>((r) => { const n = ++id; waiting.set(n, r); ws.send(JSON.stringify({ id: n, method, params })); });
  const evaluate = async (expr: string) => {
    const r = await send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true });
    if (r.result?.exceptionDetails) throw new Error(r.result.exceptionDetails.exception?.description || expr);
    return r.result?.result?.value;
  };
  const close = () => { ws.close(); proc.kill(); fs.rmSync(prof, { recursive: true, force: true }); };
  return { send, evaluate, close };
}

async function compose(cdp: Awaited<ReturnType<typeof chrome>>, slug: string, state: State | null): Promise<string> {
  const ready = `typeof CFG !== "undefined" && CFG && !!document.querySelector("#main section")`;
  const open = async () => {
    await cdp.send("Page.navigate", { url: `${BASE}/dp/${slug}/` });
    for (let t = 0; t < 100; t++) { if (await cdp.evaluate(ready).catch(() => false)) return; await Bun.sleep(100); }
    throw new Error(`page ${slug} never rendered`);
  };
  await open();
  await cdp.evaluate(state ? `localStorage.setItem(KEY(), ${JSON.stringify(JSON.stringify(state))}), 1`
                           : `localStorage.removeItem(KEY()), 1`);
  await open();
  return cdp.evaluate("answerString()");
}

const synth = JSON.parse(fs.readFileSync(path.join(HERE, "synthetic.json"), "utf8"));
const made: string[] = [];
for (const [slug, cfg] of Object.entries(synth.configs)) {
  const dir = path.join(DP_ROOT, slug);
  if (fs.existsSync(dir)) throw new Error(`${dir} exists; refusing to overwrite a page this run did not make`);
  fs.mkdirSync(dir); fs.writeFileSync(path.join(dir, "config.json"), JSON.stringify(cfg, null, 2)); made.push(dir);
}

const cdp = await chrome();
const out: any = { captured_at: new Date().toISOString(), source: "scripts/kanban/decision.html", real: [], synthetic: [] };
let bad = 0;
try {
  await cdp.send("Network.enable");
  await cdp.send("Network.setBlockedURLs", { urls: ["*/api/dp-seen/*", "*/api/dp-submit/*"] });
  for (const slug of fs.readdirSync(DP_ROOT).sort()) {
    const af = path.join(DP_ROOT, slug, ".answer.json"), cf = path.join(DP_ROOT, slug, "config.json");
    if (!fs.existsSync(af) || !fs.existsSync(cf)) continue;
    const cfg = JSON.parse(fs.readFileSync(cf, "utf8"));
    const want: string = JSON.parse(fs.readFileSync(af, "utf8")).answer;
    const state = parseAnswer(want, cfg);
    // An answer without the page's header line was posted to the submit route
    // by something other than the page or wizard.sh. Parsers must still accept
    // it, but no composer is expected to produce it.
    const header = (cfg.copyHeader || cfg.title || "answers") + ":";
    if (want.split("\n")[0] !== header) {
      out.real.push({ slug, config: cfg, state, expected: want, kind: "parse-only" });
      console.log(`skip real ${slug} (no page header; parse-only)`);
      continue;
    }
    const got = await compose(cdp, slug, state);
    const ok = got === want;
    if (!ok) bad++;
    out.real.push({ slug, config: cfg, state, expected: want, kind: "compose", reproduced: ok, ...(ok ? {} : { composed: got }) });
    console.log(`${ok ? "ok  " : "DIFF"} real ${slug}`);
  }
  for (const c of synth.cases) {
    const got = await compose(cdp, c.slug, c.state);
    out.synthetic.push({ name: c.name, slug: c.slug, config: synth.configs[c.slug], state: c.state, expected: got });
    console.log(`rec  synthetic ${c.name}`);
  }
} finally {
  cdp.close();
  for (const d of made) fs.rmSync(d, { recursive: true, force: true });
}
// The real answers are the owner's own words, and this repo is public, so they
// stay beside the pages in the gitignored registry. Only the synthetic half is
// committed.
const REAL = path.join(DP_ROOT, ".golden-real.json");
fs.writeFileSync(REAL, JSON.stringify({ captured_at: out.captured_at, source: out.source, real: out.real }, null, 1) + "\n");
fs.writeFileSync(path.join(HERE, "golden.json"), JSON.stringify({ captured_at: out.captured_at, source: out.source, synthetic: out.synthetic }, null, 1) + "\n");
const composed = out.real.filter((r: any) => r.kind === "compose").length;
console.log(`${composed - bad}/${composed} page-composed answers reproduced, ${out.real.length - composed} parse-only, ${out.synthetic.length} synthetic strings recorded -> ${path.join(HERE, "golden.json")} and ${REAL}`);
process.exit(bad ? 1 : 0);
