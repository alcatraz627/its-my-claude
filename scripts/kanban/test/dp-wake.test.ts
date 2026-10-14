// The decision-page wake path, five origin shapes, driven through wakeOrigin with
// a fake sender so no real ipc bus is touched.
//   bun test ~/.claude/scripts/kanban/test/dp-wake.test.ts
import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { wakeOrigin, type Sender } from "../dp-wake.ts";

let root: string;
beforeEach(() => { root = fs.mkdtempSync(path.join(os.tmpdir(), "dpwake-")); });
afterEach(() => { fs.rmSync(root, { recursive: true, force: true }); });

function page(slug: string, origin: Record<string, string>): string {
  const dir = path.join(root, slug);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, "config.json"), JSON.stringify({ origin }));
  return dir;
}
const notify = (dir: string) => JSON.parse(fs.readFileSync(path.join(dir, ".notify.json"), "utf8"));

// A bus that accepts mail for the aliases and projects it knows and refuses the rest.
function bus(known: { aliases?: string[]; projects?: string[]; down?: boolean }) {
  const calls: string[][] = [];
  const send: Sender = async (argv) => {
    calls.push(argv);
    if (known.down) return { code: 1, out: "", err: "error: Failed to connect" };
    const to = argv[argv.indexOf("--to") + 1];
    const proj = argv.indexOf("--to-project") >= 0 ? argv[argv.indexOf("--to-project") + 1] : null;
    if (proj !== null) return known.projects?.includes(proj)
      ? { code: 0, out: "msg-p", err: "" } : { code: 1, out: "", err: "no such project" };
    return known.aliases?.includes(to)
      ? { code: 0, out: "msg-a", err: "" } : { code: 1, out: "", err: `unknown alias ${to}` };
  };
  return { calls, send };
}

describe("an answered page tells its origin", () => {
  test("idle live origin: a wake-capable request goes to the alias", async () => {
    const dir = page("p1", { session: "gcc-a", project: "/proj" });
    const b = bus({ aliases: ["gcc-a"], projects: ["/proj"] });
    const r = await wakeOrigin({ slug: "p1", dir, reachState: "hot", send: b.send });
    expect(r.state).toBe("requested");
    expect(b.calls).toHaveLength(1);
    // The ipc watcher wakes an idle session for query/request/response only.
    expect(b.calls[0]).toContain("request");
    expect(b.calls[0][b.calls[0].indexOf("--kind") + 1]).toBe("request");
    expect(notify(dir).state).toBe("requested");
  });

  test("dead origin: still mailed, also dropped in the project box, reported as queued", async () => {
    const dir = page("p2", { session: "gcc-gone", project: "/proj" });
    const b = bus({ aliases: ["gcc-gone"], projects: ["/proj"] });
    const r = await wakeOrigin({ slug: "p2", dir, reachState: "cold", send: b.send });
    expect(r.state).toBe("queued");
    expect(r.via).toEqual(["alias:gcc-gone", "project:/proj"]);
    expect(notify(dir).state).toBe("queued");
  });

  test("never-registered origin: the alias send fails, the project box catches it", async () => {
    const dir = page("p3", { session: "ghost", project: "/proj" });
    const b = bus({ aliases: [], projects: ["/proj"] });
    const r = await wakeOrigin({ slug: "p3", dir, reachState: "absent", send: b.send });
    expect(r.state).toBe("queued");
    expect(r.via).toEqual(["project:/proj"]);
    expect(r.reason).toContain("unknown alias ghost");
  });

  test("broker down: nothing is sent, and the failure is written down, not swallowed", async () => {
    const dir = page("p4", { session: "gcc-a", project: "/proj" });
    const b = bus({ down: true });
    const r = await wakeOrigin({ slug: "p4", dir, reachState: "unknown", send: b.send });
    expect(r.state).toBe("undelivered");
    expect(r.reason).toContain("Failed to connect");
    expect(notify(dir).state).toBe("undelivered");
  });

  test("two pages answered at once: separate messages, separate records", async () => {
    const d1 = page("pa", { session: "gcc-a" });
    const d2 = page("pb", { session: "gcc-b" });
    const b = bus({ aliases: ["gcc-a", "gcc-b"] });
    const [r1, r2] = await Promise.all([
      wakeOrigin({ slug: "pa", dir: d1, reachState: "hot", send: b.send }),
      wakeOrigin({ slug: "pb", dir: d2, reachState: "hot", send: b.send }),
    ]);
    expect([r1.state, r2.state]).toEqual(["requested", "requested"]);
    const ops = b.calls.map((c) => c[c.indexOf("--operation-id") + 1]).sort();
    expect(ops).toEqual(["dp-answered-pa", "dp-answered-pb"]);
    expect(notify(d1).via).toEqual(["alias:gcc-a"]);
    expect(notify(d2).via).toEqual(["alias:gcc-b"]);
  });

  test("a page with no origin is recorded as such", async () => {
    const dir = page("p5", {});
    const b = bus({});
    const r = await wakeOrigin({ slug: "p5", dir, send: b.send });
    expect(r.state).toBe("no-origin");
    expect(b.calls).toHaveLength(0);
    expect(notify(dir).state).toBe("no-origin");
  });
});

// Reads the other side: the wake kind must be one the real watcher wakes for. A
// constant pinned against a literal in this same file would only agree with itself.
describe("the kind sent is one the ipc watcher wakes for", () => {
  const watcher = path.join(os.homedir(), "Code/Claude/claude-ipc/plugin/scripts/watch-inbox.sh");
  test.skipIf(!fs.existsSync(watcher))("watch-inbox.sh lists request as waking and inform as not", () => {
    const src = fs.readFileSync(watcher, "utf8");
    expect(src).toContain('("query", "request", "response")');
    expect(src).not.toMatch(/\("[a-z", ]*inform[a-z", ]*\)/);
  });
});
