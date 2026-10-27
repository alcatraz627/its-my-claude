// The ruling write-back: an answered page notes its answer on the goal row it
// names, and records what happened, driven with a fake runner so no real goal
// record is touched.
//   bun test ~/.claude/scripts/kanban/test/dp-ruling.test.ts
import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { recordRuling, rulingText, type Runner } from "../dp-ruling.ts";

let root: string;
beforeEach(() => { root = fs.mkdtempSync(path.join(os.tmpdir(), "dpruling-")); });
afterEach(() => { fs.rmSync(root, { recursive: true, force: true }); });

function page(origin: Record<string, string> | null): string {
  const dir = path.join(root, "p");
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, "config.json"), JSON.stringify(origin ? { origin } : {}));
  return dir;
}
const kept = (dir: string) => JSON.parse(fs.readFileSync(path.join(dir, ".ruling.json"), "utf8"));
function runner(code = 0) {
  const calls: string[][] = [];
  const run: Runner = async (argv) => { calls.push(argv); return code ? { code, out: "", err: "no such goal" } : { code: 0, out: "noted", err: "" }; };
  return { calls, run };
}

describe("an answered page writes its ruling where the work is", () => {
  test("a goal and row: the answer is noted on that row", async () => {
    const dir = page({ goal: "81fdf3de0595", row: "#16" });
    const r = runner();
    const res = await recordRuling({ slug: "dp1", dir, answer: "D1a D2b\nnotes: fine", run: r.run, now: () => "T" });
    expect(res).toEqual({ state: "written", target: "81fdf3de0595 #16", reason: "" });
    expect(r.calls).toEqual([["note", "81fdf3de0595", "16", "Ruling from decision page dp1:\nD1a D2b\nnotes: fine"]]);
    expect(kept(dir)).toMatchObject({ state: "written", at: "T" });
  });
  test("a goal without a row: the note goes on the goal", async () => {
    const r = runner();
    await recordRuling({ slug: "dp2", dir: page({ goal: "81fdf3de0595" }), answer: "ok", run: r.run });
    expect(r.calls[0].slice(0, 3)).toEqual(["note", "81fdf3de0595", "goal"]);
  });
  test("a failed write is recorded, not swallowed", async () => {
    const dir = page({ goal: "81fdf3de0595", row: "3" });
    const res = await recordRuling({ slug: "dp3", dir, answer: "x", run: runner(1).run });
    expect(res.state).toBe("failed");
    expect(kept(dir)).toMatchObject({ state: "failed", reason: "no such goal" });
  });
  test("free-text goal or none: nothing is written, and the page says why", async () => {
    const r = runner();
    const a = await recordRuling({ slug: "dp4", dir: page({ goal: "Ship the thing" }), answer: "x", run: r.run });
    expect(a).toMatchObject({ state: "no-target", reason: 'origin.goal "Ship the thing" is not a goal id' });
    const b = await recordRuling({ slug: "dp5", dir: page(null), answer: "x", run: r.run });
    expect(b).toMatchObject({ state: "no-target", reason: "the page names no goal" });
    expect(r.calls.length).toBe(0);
  });
  test("a long answer is cut to a readable note", () => {
    const t = rulingText("dp6", "y".repeat(2000));
    expect(t.length).toBeLessThan(700);
    expect(t.endsWith("…")).toBe(true);
  });
});
