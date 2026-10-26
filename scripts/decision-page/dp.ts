// The decision-page verbs an agent, wizard.sh or bfb's native host calls:
// compose and parse an answer, report reach, submit an answer, mark a page seen.
// decision-page.sh routes these verbs here; call that, not this file.
//
//   compose <slug>            state JSON on stdin (empty = the page as drawn) -> answer string
//   parse <slug>              answer on stdin -> state JSON
//   reach                     {slug: hot|cold|absent|unknown} for every pending page
//   submit <slug> [--replace] [--via chat]  answer on stdin -> the server writes it and
//                             wakes the asker; --via records how it arrived (default cli)
//   seen <slug>               first open of the page
//
// Exit codes: 0 ok, 1 bad input or unknown page, 3 already answered (submit
// without --replace), 4 page server unreachable (nothing was written).

import * as fs from "node:fs";
import * as path from "node:path";
import { compose, parse, reachAll, configOf, DP_ROOT } from "./dp-core.ts";

const BASE = "http://127.0.0.1:5106";
const [verb, slug, ...rest] = process.argv.slice(2);
const stdin = async () => (process.stdin.isTTY ? "" : await Bun.stdin.text());
const fail = (code: number, msg: string): never => { console.error(`decision-page ${verb}: ${msg}`); process.exit(code); };

function needConfig() {
  if (!slug) fail(1, "needs a page slug");
  return configOf(slug) ?? fail(1, `no page '${slug}' (looked in ${DP_ROOT})`);
}

async function post(route: string, body: unknown) {
  try {
    return await fetch(`${BASE}${route}`, {
      method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body),
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    return fail(4, `the page server on ${BASE} is not answering; nothing was written`);
  }
}

switch (verb) {
  case "compose": {
    const cfg = needConfig();
    const raw = (await stdin()).trim();
    let state = null;
    try { state = raw ? JSON.parse(raw) : null; } catch { fail(1, "stdin is not JSON state"); }
    process.stdout.write(compose(cfg, state) + "\n");
    break;
  }
  case "parse": {
    const cfg = needConfig();
    console.log(JSON.stringify(parse(await stdin(), cfg)));
    break;
  }
  case "reach":
    console.log(JSON.stringify(reachAll()));
    break;
  case "submit": {
    needConfig();
    const answer = (await stdin()).replace(/\n$/, "");
    if (!answer.trim()) fail(1, "no answer on stdin");
    const t0 = Date.now() - 1000;
    const vi = rest.indexOf("--via");
    const via = vi >= 0 ? rest[vi + 1] : "cli";
    const r = await post(`/api/dp-submit/${encodeURIComponent(slug)}`, { answer, replace: rest.includes("--replace"), via });
    const body: any = await r.json().catch(() => ({}));
    if (r.status === 409) { console.log(JSON.stringify(body)); process.exit(3); }
    if (!r.ok) fail(1, `the server refused it (HTTP ${r.status}): ${body.error ?? ""}`);
    // The wake runs after the server replies, and its send can take up to ten
    // seconds, so wait for a .notify.json written by THIS submit, not an older one.
    let notify: any = null;
    for (let t = 0; t < 120 && !notify; t++) {
      try {
        const n = JSON.parse(fs.readFileSync(path.join(DP_ROOT, slug, ".notify.json"), "utf8"));
        if (Date.parse(n.at) >= t0) notify = n;
      } catch {}
      if (!notify) await Bun.sleep(100);
    }
    console.log(JSON.stringify({ ...body, notify }));
    break;
  }
  case "seen": {
    needConfig();
    const r = await post(`/api/dp-seen/${encodeURIComponent(slug)}`, {});
    console.log(JSON.stringify(await r.json().catch(() => ({ ok: r.ok }))));
    if (!r.ok) process.exit(1);
    break;
  }
  default:
    fail(1, "verbs: compose, parse, reach, submit, seen");
}
