#!/usr/bin/env bun
// Harvest: docs → cards, one direction (owner decisions D2a/D4a). Unrecognized
// structures are skipped; unclassifiable-but-recognized items land in inbox.

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import { execFileSync } from "node:child_process";
import { canonicalRoot, cardId, type HarvestedCard, type Lane } from "./lib.ts";

const MAX_FILES = 120; // a repo with a big docs/plan tree blew straight through 60
const MAX_CARDS = 400;

interface HarvestResult { cards: HarvestedCard[]; scanned: string[]; skipped: string[] }

const CHECKBOX = /^\s*[-*]\s*\[([ xX])\]\s+(.*)$/;
const HEADING = /^(#{1,4})\s+(.*)$/;
const MD_LINK = /\[[^\]]*\]\(([^)]+\.md)\)/g;

function laneForHeading(heading: string, checked: boolean): Lane {
  if (checked) return "done";
  if (!heading) return "backlog"; // a plain checkbox doc with no section context
  const h = heading.toLowerCase();
  if (/\b(blocked|waiting|stuck)\b/.test(h)) return "blocked";
  if (/\b(in[ -]?progress|active|doing|now|current)\b/.test(h)) return "active";
  if (/\b(backlog|later|icebox|someday|future)\b/.test(h)) return "backlog";
  return "inbox"; // unrecognized heading: never guess
}

// "(#7) fix x" / "OWNER REMINDER: call y" carry type/priority as title prose;
// surface the prefix as a badge instead of paying title width for it.
function splitTag(title: string): { tag?: string; clean: string } {
  // Inline markdown emphasis reads as literal ** / ` noise in a card title.
  const t = title.replace(/\*\*([^*]+)\*\*/g, "$1").replace(/`([^`]+)`/g, "$1");
  const m = t.match(/^\((#\d+)\)\s+(.+)/) ?? t.match(/^([A-Z][A-Z0-9 _-]{1,15}):\s+(.+)/);
  return m ? { tag: m[1], clean: m[2] } : { clean: t };
}

function docLinks(line: string, sourceDir: string, root: string): string[] {
  const out: string[] = [];
  for (const m of line.matchAll(MD_LINK)) {
    const target = m[1];
    if (/^https?:/.test(target)) continue;
    const abs = path.resolve(sourceDir, target);
    if (abs.startsWith(root) && fs.existsSync(abs)) out.push(path.relative(root, abs));
  }
  return out;
}

// Which session's workspace fed a session-notes card: _active.md is a symlink
// to <session-uuid>.md, so the resolved basename names the author session (M1
// buddy attribution). Non-symlink or non-uuid targets just yield no via.
function viaOf(abs: string): string | undefined {
  try {
    const real = fs.realpathSync(abs);
    const base = path.basename(real, ".md");
    return /^[0-9a-f]{8}/.test(base) ? base.slice(0, 8) : undefined;
  } catch { return undefined; }
}

function parseCheckboxFile(abs: string, root: string, kind: "checkbox" | "session-notes"): HarvestedCard[] {
  const rel = path.relative(root, abs);
  const via = kind === "session-notes" ? viaOf(abs) : undefined;
  const lines = fs.readFileSync(abs, "utf8").split("\n");
  const cards: HarvestedCard[] = [];
  let heading = "";
  let inTodos = kind !== "session-notes"; // session-notes: only the "## Todos" section counts
  const stack: { indent: number; card: HarvestedCard }[] = [];

  lines.forEach((line, i) => {
    const h = line.match(HEADING);
    if (h) {
      heading = h[2].trim();
      stack.length = 0;
      if (kind === "session-notes") inTodos = /^todos\b/i.test(heading);
      return;
    }
    if (!inTodos) return;
    const m = line.match(CHECKBOX);
    if (!m) return;
    const checked = m[1] !== " ";
    // Markdown links render as raw syntax in a card title: keep the text, the
    // target still lands in docs[] via docLinks below.
    const title = m[2].trim().replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1");
    if (!title) return;
    const indent = line.match(/^\s*/)![0].length;
    while (stack.length && indent <= stack[stack.length - 1].indent) stack.pop();
    if (stack.length) {
      // A nested checkbox is a sub-item of its parent card, never its own card.
      stack[stack.length - 1].card.subs!.push({ title: splitTag(title).clean, done: checked });
      return;
    }
    const lane: Lane =
      kind === "session-notes" ? (checked ? "done" : "active") : laneForHeading(heading, checked);
    const { tag, clean } = splitTag(title);
    const card: HarvestedCard = {
      id: cardId(rel, title), title: clean, tag, subs: [], lane,
      source: { path: rel, line: i + 1, kind },
      docs: docLinks(line, path.dirname(abs), root), heading, via,
    };
    cards.push(card);
    stack.push({ indent, card });
  });
  return cards;
}

function parseCheckpointFile(abs: string, root: string): HarvestedCard[] {
  const rel = path.isAbsolute(abs) && abs.startsWith(root) ? path.relative(root, abs) : abs;
  const lines = fs.readFileSync(abs, "utf8").split("\n");
  const cards: HarvestedCard[] = [];
  let inPending = false;
  let heading = "";
  lines.forEach((line, i) => {
    const h = line.match(HEADING);
    if (h) {
      heading = h[2].trim();
      inPending = /pending|next step|open item|todo/i.test(heading);
      return;
    }
    if (!inPending) return;
    const cb = line.match(CHECKBOX);
    const plain = line.match(/^\s*[-*]\s+(.*)$/);
    const title = (cb ? cb[2] : plain?.[1])?.trim();
    if (!title) return;
    if (cb && cb[1] !== " ") return; // completed pending item: not pending anymore
    const { tag, clean } = splitTag(title);
    cards.push({
      id: cardId(rel, title), title: clean, tag, lane: "active",
      source: { path: rel, line: i + 1, kind: "checkpoint" },
      docs: [], heading,
    });
  });
  return cards;
}

function globDocs(root: string): string[] {
  const picks: string[] = [];
  const push = (p: string) => { if (fs.existsSync(p) && fs.statSync(p).isFile()) picks.push(p); };
  push(path.join(root, "TODO.md"));
  for (const dir of [path.join(root, "docs"), path.join(root, "docs", "plan")]) {
    if (!fs.existsSync(dir)) continue;
    for (const f of fs.readdirSync(dir).sort()) {
      if (f.endsWith(".md")) push(path.join(dir, f));
    }
  }
  return picks;
}

// The board must be one board across checkouts (owner decision D3c), so live
// mirrors are harvested from every linked worktree, not just the main root.
function worktreeRoots(root: string): string[] {
  try {
    const out = execFileSync("git", ["-C", root, "worktree", "list", "--porcelain"], {
      encoding: "utf8", stdio: ["ignore", "pipe", "ignore"],
    });
    return out.split("\n").filter((l) => l.startsWith("worktree ")).map((l) => l.slice(9).trim());
  } catch {
    return [root];
  }
}

export function harvest(root: string): HarvestResult {
  const scanned: string[] = [];
  const skipped: string[] = [];
  type Harvested = HarvestedCard & { _mtime?: number };
  let cards: Harvested[] = [];

  const consider = (abs: string, fn: () => HarvestedCard[]) => {
    if (scanned.length >= MAX_FILES) { skipped.push(abs); return; }
    scanned.push(abs);
    try {
      const mtime = fs.statSync(abs).mtimeMs;
      cards = cards.concat(fn().map((c) => ({ ...c, _mtime: mtime })));
    } catch (e: any) {
      skipped.push(`${abs} (${e.message})`);
    }
  };

  // ORDER IS LOAD-BEARING. The MAX_FILES budget is first-come, and the doc glob
  // is alphabetical, so scanning docs first spends the whole budget on whatever
  // sorts early — which on a big repo is prose plan docs carrying no checkboxes
  // at all. versable-builder hit exactly that on 2026-08-21: 60 docs scanned,
  // zero cards, and the live workspace mirror plus every checkpoint skipped past
  // the cap, which emptied a 71-card board in one sync. The live sources are
  // few, dense, and freshest, so they are scanned first and the docs spend
  // what's left.

  // Only live workspace mirrors. Historical per-session snapshots are frozen
  // state and were the top source of same-task-in-N-files duplicates.
  const snActive = path.join(root, ".claude", "session-notes", "_active.md");
  if (fs.existsSync(snActive)) consider(snActive, () => parseCheckboxFile(snActive, root, "session-notes"));
  for (const wt of worktreeRoots(root)) {
    if (wt === root) continue;
    const wtActive = path.join(wt, ".claude", "session-notes", "_active.md");
    if (fs.existsSync(wtActive)) consider(wtActive, () => parseCheckboxFile(wtActive, wt, "session-notes"));
  }

  const ckDir = path.join(os.homedir(), ".claude", "checkpoints");
  if (fs.existsSync(ckDir)) {
    // Many session pointers resolve to the same file (every session in a repo
    // writes _precompact-checkpoint.claude.md), and each duplicate used to cost
    // a slot of the budget and re-harvest the same cards.
    const seenCk = new Set<string>();
    for (const f of fs.readdirSync(ckDir)) {
      if (!f.endsWith(".json")) continue;
      try {
        const ptr = JSON.parse(fs.readFileSync(path.join(ckDir, f), "utf8"));
        if (!ptr.checkpoint_path || !fs.existsSync(ptr.checkpoint_path)) continue;
        // Checkpoints written inside a worktree/subdir store that path, not the
        // main root; canonicalize before matching so they reach the one board.
        let ptrRoot = String(ptr.project_root ?? "");
        try { ptrRoot = canonicalRoot(ptrRoot); } catch { continue; }
        if (ptrRoot !== root) continue;
        const real = fs.realpathSync(ptr.checkpoint_path);
        if (seenCk.has(real)) continue;
        seenCk.add(real);
        const ageDays = (Date.now() - fs.statSync(real).mtimeMs) / 86_400_000;
        if (ageDays > 14) { skipped.push(`${real} (${Math.round(ageDays)}d old, age-decayed)`); continue; }
        consider(real, () => parseCheckpointFile(real, root));
      } catch { skipped.push(path.join(ckDir, f)); }
    }
  }

  for (const doc of globDocs(root)) consider(doc, () => parseCheckboxFile(doc, root, "checkbox"));

  // Dedupe by TITLE across sources: the same task lives in plan docs,
  // checkpoints, and the workspace mirror at once, and per-source ids can't
  // see that. The freshest source file wins, so a task checked off in the
  // live mirror stops showing as active from an older snapshot. Ties: a
  // non-done lane beats done, so re-opened work resurfaces.
  const normTitle = (t: string) => t.toLowerCase().replace(/\(#\d+\)/g, "").replace(/\s+/g, " ").trim();
  const byTitle = new Map<string, Harvested>();
  for (const c of cards) {
    const k = normTitle(c.title);
    const prev = byTitle.get(k);
    if (!prev) { byTitle.set(k, c); continue; }
    const newer = (c._mtime ?? 0) > (prev._mtime ?? 0);
    const tieReopen = (c._mtime ?? 0) === (prev._mtime ?? 0) && prev.lane === "done" && c.lane !== "done";
    if (newer || tieReopen) byTitle.set(k, c);
  }
  let deduped = [...byTitle.values()].map(({ _mtime, ...c }) => c as HarvestedCard);
  if (deduped.length > MAX_CARDS) {
    skipped.push(`${deduped.length - MAX_CARDS} cards over the ${MAX_CARDS} cap (dropped)`);
    deduped = deduped.slice(0, MAX_CARDS);
  }
  return { cards: deduped, scanned, skipped };
}
