#!/usr/bin/env bun
// State layer for the kanban board: the registry of boards and each board's
// three state files. Ownership is split one-writer-per-file so the CLI and the
// server never contend: board.json is written only by CLI processes (guarded by
// a directory lock), notes.json only by the server, ack.json only by the CLI.
// All writes are atomic (tmp + rename); notes.json rotates backups because it
// holds the only human-authored data in the system.

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import * as crypto from "node:crypto";
import { execFileSync } from "node:child_process";

export const KROOT = path.join(os.homedir(), ".claude", "kanban");
export const REGISTRY = path.join(KROOT, "registry.json");
export const SERVER_INFO = path.join(KROOT, "server.json");

export const LANES = ["inbox", "backlog", "active", "blocked", "done", "stale"] as const;
export type Lane = (typeof LANES)[number];

// Every user-facing refusal travels as a CliError so the CLI's single catch can
// print the kanban:/fix: contract; a raw throw means a genuinely unexpected bug.
export class CliError extends Error {
  constructor(msg: string, public fix: string) { super(msg); }
}

export interface CardSource {
  path: string;          // repo-relative source file, or "manual"
  line?: number;
  kind: "checkbox" | "checkpoint" | "session-notes" | "manual";
}
export interface Card {
  id: string;
  title: string;
  tag?: string;          // "(#7)" / "OWNER REMINDER" style prefix, surfaced as a badge
  subs?: { title: string; done: boolean }[]; // nested checkboxes under the card's line
  lane: Lane;
  source: CardSource;
  docs: string[];        // repo-relative linked docs
  heading?: string;      // section context at harvest time
  staleReason?: string;
  // How trustworthy is this card's claimed state — agent-set via `verify` verb,
  // survives sync. Grades reuse the adversarial-review evidence vocabulary.
  verify?: { grade: "executed" | "cited" | "reasoned"; needsHuman?: boolean; note?: string; at: string };
  via?: string;          // session id (8 chars) whose workspace the card was harvested from
  createdAt: string;
  updatedAt: string;
}
export interface Board {
  cards: Card[];
  overrides: Record<string, { lane: Lane }>; // agent `move` verdicts, survive sync
  tombstones?: Record<string, string>;       // dropped doc-sourced ids → drop ts; sync won't resurrect
  syncedAt: string | null;
}
// A card holds many notes. `note` stays populated as a derived join so every
// legacy reader keeps working, and it EXCLUDES @me bodies: @me suppresses, so
// joining one in would silence the unread signal for every other note here.
export interface Note { id: string; title?: string; body: string; updatedAt: string }
export interface NoteEntry { note: string; updatedAt: string; notes?: Note[]; activeId?: string }
export type Notes = Record<string, NoteEntry>;

export const noteId = (): string => Math.random().toString(36).slice(2, 10);

// One note per legacy string, so nothing on disk is rewritten to be readable.
export function notesOf(e: NoteEntry | undefined): Note[] {
  if (!e) return [];
  // shape, not truthiness: a string has .length too, and hand-edited data does
  // reach here. A note missing its id or timestamp is repaired, never dropped.
  if (Array.isArray(e.notes) && e.notes.length) {
    const seen = new Set<string>();
    return e.notes
      .filter((n): n is Note => !!n && typeof n.body === "string")
      .map((n, i) => {
        let id = typeof n.id === "string" && n.id ? n.id : `n${i}`;
        while (seen.has(id)) id = `${id}-${i}`;
        seen.add(id);
        return { ...n, id, updatedAt: typeof n.updatedAt === "string" ? n.updatedAt : (e.updatedAt ?? new Date(0).toISOString()) };
      });
  }
  return e.note ? [{ id: "legacy", body: e.note, updatedAt: e.updatedAt }] : [];
}

// Rebuild the legacy view from the array. Callers write this on every mutation.
export function deriveEntry(list: Note[], activeId?: string): NoteEntry | null {
  const kept = list.filter((n) => n.body.trim());
  if (!kept.length) return null;
  const visible = kept.filter((n) => !parseNoteTags(n.body).me);
  const newest = kept.reduce((a, b) => (a.updatedAt > b.updatedAt ? a : b));
  return {
    note: (visible.length ? visible : kept).map((n) => n.body).join("\n\n"),
    updatedAt: newest.updatedAt,
    notes: kept,
    activeId: activeId && kept.some((n) => n.id === activeId) ? activeId : kept[0].id,
  };
}
export interface RegistryFile {
  boards: Record<string, { root: string; name: string; createdAt: string }>;
}
export interface SyncDelta { new: number; moved: number; gone: number; stale: number; kept: number }

// Worktree-aware project identity: branch/worktree swaps must all resolve to
// one board (owner decision D3c), so the canonical root is the MAIN repo root.
export function canonicalRoot(dir: string): string {
  const abs = fs.realpathSync(path.resolve(dir));
  try {
    const common = execFileSync("git", ["-C", abs, "rev-parse", "--git-common-dir"], {
      encoding: "utf8", stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    const commonAbs = path.resolve(abs, common);
    if (path.basename(commonAbs) === ".git") return path.dirname(commonAbs);
    return abs; // bare/odd layouts: fall back to the given dir
  } catch {
    return abs; // not a git repo
  }
}

export function slugFor(root: string): string {
  const h = crypto.createHash("sha1").update(root).digest("hex").slice(0, 6);
  return `${path.basename(root).toLowerCase().replace(/[^a-z0-9-]+/g, "-")}-${h}`;
}

export function cardId(sourcePath: string, title: string): string {
  const norm = title.toLowerCase().replace(/\(#\d+\)/g, "").replace(/\s+/g, " ").trim();
  return crypto.createHash("sha1").update(`${sourcePath}#${norm}`).digest("hex").slice(0, 12);
}

export function readJson<T>(file: string, fallback: T): T {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8")) as T;
  } catch (e: any) {
    if (e.code === "ENOENT") return fallback;
    throw new Error(`${file} is unreadable/corrupt (${e.message}) — fix or trash it; refusing to guess`);
  }
}

export function atomicWrite(file: string, obj: unknown, by: string, extra = ""): void {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  // pid-unique: two servers across a pm2 restart would race one fixed path
  const tmp = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, JSON.stringify(obj, null, 2) + "\n", "utf8");
  fs.renameSync(tmp, file);
  // stderr: stdout belongs to the human-facing digest (UX-sim finding F6)
  console.error(`[state] save file=${path.basename(file)} by=${by} at=${new Date().toISOString()} ${extra}`);
}

// notes.json is the human lane: rotate a backup before every overwrite. This
// data is gitignored, so these copies plus any notes.json.premigrate-* are the
// whole recovery surface. 20 is roughly a week of use; 5 was about two days.
export function saveNotes(boardDir: string, notes: Notes, by: string): void {
  const file = path.join(boardDir, "notes.json");
  if (fs.existsSync(file)) {
    fs.copyFileSync(file, `${file}.prev-${Date.now()}.bak`);
    const baks = fs.readdirSync(boardDir).filter((f) => f.startsWith("notes.json.prev-")).sort();
    for (const old of baks.slice(0, Math.max(0, baks.length - 20))) fs.unlinkSync(path.join(boardDir, old));
  }
  atomicWrite(file, notes, by, `notes=${Object.keys(notes).length}`);
}

// Cross-process lock for board.json writers (two CLI invocations can race).
// mkdir is atomic. A healthy writer holds the lock for milliseconds, so a
// lock older than 10s is a crashed writer and gets swept; the acquire window
// (15s) exceeds the sweep age so waiters always outlive a stale lock.
export function withBoardLock<T>(boardDir: string, fn: () => T): T {
  const lock = path.join(boardDir, ".lock-board");
  fs.mkdirSync(boardDir, { recursive: true });
  for (let i = 0; i < 150; i++) {
    try {
      fs.mkdirSync(lock);
    } catch (e: any) {
      if (e.code !== "EEXIST") throw e;
      let age = 0;
      try { age = Date.now() - fs.statSync(lock).mtimeMs; } catch { continue; } // sibling swept it first
      if (age > 10_000) { try { fs.rmdirSync(lock); } catch {} continue; }
      Bun.sleepSync(100);
      continue;
    }
    try {
      return fn();
    } finally {
      fs.rmdirSync(lock);
    }
  }
  throw new CliError(`board lock at ${lock} held >15s — a writer is genuinely stuck`, `inspect the lock dir, then remove it if its owner crashed: ${lock}`);
}

export const registry = (): RegistryFile => readJson<RegistryFile>(REGISTRY, { boards: {} });

export function registerBoard(dir: string): { slug: string; root: string; boardDir: string } {
  const root = canonicalRoot(dir);
  const slug = slugFor(root);
  const reg = registry();
  if (!reg.boards[slug]) {
    reg.boards[slug] = { root, name: path.basename(root), createdAt: new Date().toISOString() };
    atomicWrite(REGISTRY, reg, "register", `boards=${Object.keys(reg.boards).length}`);
  }
  return { slug, root, boardDir: path.join(KROOT, "boards", slug) };
}

export const loadBoard = (boardDir: string): Board =>
  readJson<Board>(path.join(boardDir, "board.json"), { cards: [], overrides: {}, tombstones: {}, syncedAt: null });
export const loadNotes = (boardDir: string): Notes => readJson<Notes>(path.join(boardDir, "notes.json"), {});
// Per-note pickup lives here, not in notes.json: ack is a CLI verb and notes
// are server-owned, so routing ack through the server would break when it is down.
export interface Ack { lastAckTs: number; notes?: Record<string, number> }
export const loadAck = (boardDir: string): Ack =>
  readJson<Ack>(path.join(boardDir, "ack.json"), { lastAckTs: 0 });

export const ackKey = (cardId: string, n: Note): string => `${cardId}#${n.id}`;

// lastAckTs stays the floor for any note the map has never seen.
export function noteSeen(ack: Ack, cardId: string, n: Note): boolean {
  const at = ack.notes?.[ackKey(cardId, n)];
  if (at !== undefined) return at >= Date.parse(n.updatedAt);
  return ack.lastAckTs >= Date.parse(n.updatedAt);
}

// Tagged notes v1 (design: assets/reports/20260727-kanban-ui-stories/STORIES.md).
// Tags live inside free-form note text, parsed at read time — notes.json keeps
// its shape and stays the only human-authored surface. The human REQUESTS via
// tags; the agent APPLIES via CLI verbs. Mirrored by parseTags() in board.html
// and the minimal @me/!now grep in session-start-line.sh — keep all three in sync.
export type NoteTags = {
  me: boolean; act: boolean; review: boolean; defer: boolean;
  skills: string[]; moves: string[]; free: string[];
};
export function parseNoteTags(text: string | undefined): NoteTags {
  const t: NoteTags = { me: false, act: false, review: false, defer: false, skills: [], moves: [], free: [] };
  if (!text) return t;
  for (const m of text.matchAll(/(^|[\s(])(@me|@agent|!now|#[a-z][\w-]*|>[a-z]+|\/[a-z][a-z0-9-]{2,})(?=[\s).,;:]|$)/gim)) {
    const tok = m[2].toLowerCase();
    if (tok === "@me") t.me = true;
    else if (tok === "!now") t.act = true;
    else if (tok === "#review-me") t.review = true;
    else if (tok === "#defer") t.defer = true;
    else if (tok.startsWith("#")) t.free.push(tok);
    else if (tok.startsWith(">")) { if ((LANES as readonly string[]).includes(tok.slice(1))) t.moves.push(tok.slice(1)); }
    else if (tok.startsWith("/")) t.skills.push(tok);
  }
  return t;
}
// Printed WITH the data (notes verb output) so a running session that cached its
// skill specs still gets the contract — see rules/skill-spec-update-not-honored.
export const TAG_LEGEND =
  "tags: @me self-note (not agent-nagged) · !now act on pickup · /skill run it against the card · >lane apply the move via `kanban.sh move` · #review-me human's own queue (don't act) · other #word free";

export type HarvestedCard = Omit<Card, "createdAt" | "updatedAt">;

// Merge a fresh harvest into the existing board. Machine lane only: harvest
// decides lanes, overrides (agent `move`) win, manual cards persist, and a
// vanished card with a human note is kept as stale instead of deleted.
export function mergeSync(boardDir: string, harvested: HarvestedCard[], by: string) {
  return withBoardLock(boardDir, () => {
    const prev = loadBoard(boardDir);
    const notes = loadNotes(boardDir);
    const prevById = new Map(prev.cards.map((c) => [c.id, c]));
    const now = new Date().toISOString();
    const delta: SyncDelta = { new: 0, moved: 0, gone: 0, stale: 0, kept: 0 };
    const tombstones = prev.tombstones ?? {};
    let overridesHeld = 0;

    const cards: Card[] = harvested.filter((h) => !tombstones[h.id]).map((h) => {
      const old = prevById.get(h.id);
      const ov = prev.overrides[h.id]?.lane;
      if (ov) overridesHeld++; // doc-sourced only: manual lanes are never recomputed, nothing is "held"
      const lane: Lane = ov ?? h.lane;
      if (!old) delta.new++;
      else if (old.lane !== lane) delta.moved++;
      else delta.kept++;
      return {
        ...h, lane,
        // Agent-set state must survive the rebuild-from-harvest: linked docs
        // union in (harvest only knows doc-inline links), verify carries over.
        docs: old ? [...new Set([...h.docs, ...old.docs])] : h.docs,
        verify: old?.verify,
        createdAt: old?.createdAt ?? now,
        updatedAt: old && old.lane === lane ? old.updatedAt : now,
      };
    });

    const seen = new Set(cards.map((c) => c.id));
    for (const old of prev.cards) {
      if (seen.has(old.id)) continue;
      if (old.source.kind === "manual") { cards.push(old); continue; }
      if (notes[old.id]?.note) {
        cards.push({ ...old, lane: "stale", staleReason: "source item no longer found", updatedAt: now });
        delta.stale++;
      } else {
        delta.gone++;
        // GC the override with the card: ids are content hashes, so a later
        // identical re-add would silently inherit a stale lane otherwise.
        delete prev.overrides[old.id];
      }
    }

    const board: Board = { cards, overrides: prev.overrides, tombstones, syncedAt: now };
    atomicWrite(path.join(boardDir, "board.json"), board, by, `cards=${cards.length}`);
    return { board, delta, overridesHeld, notesPreserved: Object.keys(notes).filter((id) => notes[id]?.note).length };
  });
}
