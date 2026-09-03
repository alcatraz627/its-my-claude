/**
 * PARKED, NOT ACTIVE. Kept to reuse, not to run in a gate.
 *
 * Owner ruling 2026-09-01: keep this as something to reuse later. It came from
 * a reading of #455 he overturned (U4b): that row asked for an INDEPENDENT
 * AUDIT by a lane that did not build the panel, and a script is not that. It
 * has never been run. It lives here rather than in scripts/ so nobody mistakes
 * it for part of the checked-in gate chain, which is presentation-audit.mjs.
 *
 * What is worth reusing is the SHAPE: turning a ledger of the owner's own
 * sentences into checks that fail by themselves. If that idea is ever wanted
 * across projects, this is the working sketch of it.
 */

/**
 * The owner's admin-panel call-outs, as checks a machine runs.
 *
 * Every rule below is one of his sentences from
 * `.claude/callouts.jsonl`, turned into something that fails on its own
 * rather than waiting for him to notice it again. The ledger holds the words
 * and a prose `check`; this holds the subset of those checks a DOM can settle.
 *
 * It deliberately does NOT judge whether a surface is good. It judges whether
 * the specific things he already objected to have come back, which is the one
 * question a script can answer honestly about work it did not do.
 *
 * Run: node scripts/admin-callout-gate.mjs [--self-test]
 * Sign-in and the browser resolution are the same as presentation-audit.mjs.
 */
import { existsSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";

let chromium = null;
for (const c of ["playwright", `${process.env.HOME}/.claude/tools/browser-test/node_modules/playwright/index.js`]) {
  try { ({ chromium } = createRequire(import.meta.url)(c)); break; } catch { /* next */ }
}
if (!chromium) { console.error("playwright is not installed anywhere this script can reach."); process.exit(2); }

const CACHED = [
  `${process.env.HOME}/Library/Caches/ms-playwright/chromium-1193/chrome-mac/Chromium.app/Contents/MacOS/Chromium`,
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
].find((p) => existsSync(p));

const BASE = process.env.FORGE_URL || "http://127.0.0.1:5109";
const FILE_ENV = (() => {
  for (const f of [".env.local", ".env"]) {
    if (!existsSync(f)) continue;
    const out = {};
    for (const line of readFileSync(f, "utf8").split("\n")) {
      const m = line.match(/^([A-Z_]+)\s*=\s*(.*)$/);
      if (m) out[m[1]] = m[2].trim().replace(/^["']|["']$/g, "");
    }
    return out;
  }
  return {};
})();
const USER = process.env.FORGE_LOGIN_USER || FILE_ENV.FORGE_LOGIN_USER || "dev";
const PASS = process.env.FORGE_LOGIN_PASSWORD || FILE_ENV.FORGE_LOGIN_PASSWORD || "dev";

/**
 * One probe per call-out clause. Each returns [] when the rule holds, or a
 * list of sentences naming what came back. They run inside the page.
 */
const PROBE = () => {
  const seen = (el) => {
    if (el.offsetParent === null && getComputedStyle(el).position !== "fixed") return false;
    if (el.closest("details:not([open])")) return false;
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0;
  };
  const out = {};

  // co-20260831-220833-24: "the outline chip at xs size looks horrible. Do not use it."
  out.xsOutlineChip = [...document.querySelectorAll(".badge")]
    .filter((e) => seen(e) && e.className.includes("badge-outline") && e.className.includes("badge-xs"))
    .map((e) => `xs outline chip: "${(e.textContent || "").trim().slice(0, 24)}"`);

  // co-20260831-220818-b3: "Set the default page size to 10 items EVERYWHERE in admin panel."
  out.pageSize = [...document.querySelectorAll("select, .select, [class*=pager] select")]
    .filter((e) => seen(e) && /rows/i.test(e.closest("*")?.textContent || ""))
    .filter((e) => e.value && e.value !== "10")
    .map((e) => `pager defaults to ${e.value}, not 10`);

  // co-20260831-220818-26: "why can't I click the chips to toggle the filter?"
  // A chip inside a table cell should be a real control, not inert text.
  out.inertChip = [...document.querySelectorAll("td .badge, td button .badge")]
    .filter((e) => seen(e))
    .filter((e) => {
      const btn = e.closest("button");
      return !btn || btn.disabled;
    })
    .map((e) => `chip in a cell is not clickable: "${(e.textContent || "").trim().slice(0, 24)}"`);

  // co-20260831-220818-26: "hovering it doesn't show cursor:pointer (did you hand-roll this)?"
  out.noPointer = [...document.querySelectorAll("td button:not([disabled]), td a")]
    .filter((e) => seen(e) && getComputedStyle(e).cursor !== "pointer")
    .map((e) => `interactive cell element without cursor:pointer: ${e.tagName.toLowerCase()}`);

  // co-20260831-220818-26: "Why is there just ONE item in the row dropdown"
  out.singleItemMenu = [...document.querySelectorAll("[class*=dropdown] [role=menu], .menu")]
    .filter((e) => seen(e) && e.querySelectorAll("li, [role=menuitem]").length === 1)
    .map(() => "a row menu holding exactly one action");

  return out;
};

const RULES = {
  xsOutlineChip: "co-20260831-220833-24 — the xs outline chip is banned",
  pageSize: "co-20260831-220818-b3 — every admin table defaults to 10 rows",
  inertChip: "co-20260831-220818-26 — a chip in a cell toggles its filter",
  noPointer: "co-20260831-220818-26 — interactive elements show cursor:pointer",
  singleItemMenu: "co-20260831-220818-26 — no row menu holds only one action",
};

const ROUTES = [
  "/admin/auth",
  "/admin/auth?tab=keys",
  "/admin/auth/forge/local",
  "/admin/auth/forge/local?tab=invites",
  "/admin/auth/forge/local?tab=audit",
];

const ctx = await chromium.launchPersistentContext(`${process.env.HOME}/.cache/admin-callout-gate`, {
  headless: true, ...(CACHED ? { executablePath: CACHED } : {}), viewport: { width: 1440, height: 900 },
});
const page = ctx.pages()[0] || (await ctx.newPage());

await page.goto(`${BASE}/login`, { waitUntil: "domcontentloaded", timeout: 15000 });
if (page.url().includes("/login")) {
  const boxes = page.locator("input");
  await boxes.nth(0).fill(USER);
  await boxes.nth(1).fill(PASS);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForTimeout(3000);
}
if (page.url().includes("/login")) {
  console.error("signed out — every route would redirect and this gate would report clean.");
  await ctx.close(); process.exit(2);
}

// A check nobody has watched fail is not a check. --self-test plants each
// banned thing and asserts its rule fires, so a rule that has quietly stopped
// matching cannot pass as a clean run.
if (process.argv.includes("--self-test")) {
  await page.goto(`${BASE}/admin/auth`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(2000);
  const base = await page.evaluate(PROBE);
  const cases = [
    ["xs outline chip fires", "xsOutlineChip", `<div id=FX><span class="badge badge-outline badge-xs">planted</span></div>`],
    ["inert chip in a cell fires", "inertChip", `<div id=FX><table><tr><td><span class="badge">planted</span></td></tr></table></div>`],
    ["cell control without pointer fires", "noPointer", `<div id=FX><table><tr><td><button style="cursor:default;width:80px;height:20px">planted</button></td></tr></table></div>`],
  ];
  let pass = 0, fail = 0;
  for (const [label, bucket, html] of cases) {
    await page.evaluate((h) => { document.getElementById("FX")?.remove(); document.body.insertAdjacentHTML("beforeend", h); }, html);
    await page.waitForTimeout(120);
    const got = await page.evaluate(PROBE);
    const fired = got[bucket].length > base[bucket].length;
    console.log(`${fired ? "pass" : "FAIL"}  ${label}`);
    fired ? pass++ : fail++;
  }
  await page.evaluate(() => document.getElementById("FX")?.remove());
  console.log(`\n${pass} passed, ${fail} failed`);
  await ctx.close(); process.exit(fail === 0 ? 0 : 1);
}

let total = 0;
for (const r of ROUTES) {
  await page.goto(`${BASE}${r}`, { waitUntil: "domcontentloaded", timeout: 15000 });
  await page.waitForTimeout(2200);
  const found = await page.evaluate(PROBE);
  const hits = Object.entries(found).filter(([, v]) => v.length);
  if (!hits.length) { console.log(`ok   ${r}`); continue; }
  console.log(`FAIL ${r}`);
  for (const [k, v] of hits) {
    total += v.length;
    console.log(`       ${RULES[k]}`);
    for (const line of [...new Set(v)].slice(0, 3)) console.log(`         ${line}`);
  }
}
console.log(`\n${total} call-out regression(s). Ledger: .claude/callouts.jsonl`);
await ctx.close();
process.exit(total === 0 ? 0 : 1);
