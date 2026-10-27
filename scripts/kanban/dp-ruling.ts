// Writes an answered decision page's ruling into the work it decides.
//
// A page names that work in its config: origin.goal is a goal id (12 hex) and
// origin.row, when set, the goal row it settles. On submit the answer is noted
// on that row (or on the goal) with `gs note`, so the ruling sits next to the
// work and not only in the page's .answer file. What happened is kept in
// <page>/.ruling.json, so a write that failed shows on the page instead of
// passing silently. A page whose goal is free text, or that names no goal,
// records "no-target" and writes nothing.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export interface RunResult { code: number; out: string; err: string }
export type Runner = (argv: string[]) => Promise<RunResult>;
export type RulingState = "written" | "failed" | "no-target";
export interface RulingResult { state: RulingState; target: string; reason: string }

const GS = path.join(os.homedir(), ".claude/scripts/goals/gs");
const RUN_TIMEOUT_MS = 10_000;
const MAX_TEXT = 600;

export const gsRunner: Runner = async (argv) => {
  const proc = Bun.spawn([GS, ...argv], { stdout: "pipe", stderr: "pipe" });
  const timer = setTimeout(() => proc.kill(), RUN_TIMEOUT_MS);
  try {
    const [out, err, code] = await Promise.all([
      new Response(proc.stdout).text(), new Response(proc.stderr).text(), proc.exited]);
    return { code, out: out.trim(), err: err.trim() };
  } catch (e: any) {
    return { code: 1, out: "", err: String(e?.message ?? e) };
  } finally { clearTimeout(timer); }
};

/** The note a ruling leaves on its row: the page, then the answer, cut to a readable length. */
export function rulingText(slug: string, answer: string): string {
  const body = answer.trim().replace(/\s+\n/g, "\n");
  const cut = body.length > MAX_TEXT ? body.slice(0, MAX_TEXT - 1) + "…" : body;
  return `Ruling from decision page ${slug}:\n${cut}`;
}

export async function recordRuling(opts: {
  slug: string; dir: string; answer: string; run?: Runner; now?: () => string;
}): Promise<RulingResult> {
  const run = opts.run ?? gsRunner;
  const now = opts.now ?? (() => new Date().toISOString());
  let goal = "", row = "";
  try {
    const cfg = JSON.parse(fs.readFileSync(path.join(opts.dir, "config.json"), "utf8"));
    goal = String(cfg?.origin?.goal ?? "").trim();
    row = String(cfg?.origin?.row ?? "").trim().replace(/^#/, "");
  } catch { /* an unreadable config names no target */ }

  let res: RulingResult;
  if (!/^[0-9a-f]{12}$/.test(goal)) {
    res = { state: "no-target", target: "", reason: goal ? `origin.goal "${goal}" is not a goal id` : "the page names no goal" };
  } else {
    const on = /^\d+$/.test(row) ? row : "goal";
    const target = on === "goal" ? goal : `${goal} #${on}`;
    const r = await run(["note", goal, on, rulingText(opts.slug, opts.answer)]);
    res = r.code === 0 ? { state: "written", target, reason: "" }
      : { state: "failed", target, reason: r.err || r.out || `gs exited ${r.code}` };
  }
  try { fs.writeFileSync(path.join(opts.dir, ".ruling.json"), JSON.stringify({ ...res, at: now() }, null, 2)); } catch { /* the page dir went away */ }
  return res;
}
