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

// KANBAN_ROOT exists so a suite can exercise the global item store without
// touching the owner's real one. Unset everywhere else, which is the default.
export const KROOT = process.env.KANBAN_ROOT || path.join(os.homedir(), ".claude", "kanban");
export const REGISTRY = path.join(KROOT, "registry.json");
export const SERVER_INFO = path.join(KROOT, "server.json");

export const LANES = ["inbox", "backlog", "active", "blocked", "done", "stale"] as const;
export type Lane = (typeof LANES)[number];

// Every user-facing refusal travels as a CliError so the CLI's single catch can
// print the kanban:/fix: contract; a raw throw means a genuinely unexpected bug.
export class CliError extends Error {
  constructor(msg: string, public fix: string) { super(msg); }
}

export const BRIEF_MAX = 100; // chars; a card-face title longer than this stops being scannable

export interface CardSource {
  path: string;          // repo-relative source file, or "manual"
  line?: number;
  kind: "checkbox" | "checkpoint" | "session-notes" | "manual";
}
export interface Card {
  id: string;
  title: string;
  // What the card calls itself on the board face: a summary phrase the agent
  // writes, capped at 100 chars (BRIEF_MAX). The full `title` stays put and
  // becomes the drawer's description, so nothing is lost by summarising.
  titleBrief?: string;
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
  // compare as time, not as text: ISO strings of differing precision or offset
  // sort against real order, and hand-edited data does carry both
  const at = (n: Note) => Date.parse(n.updatedAt) || 0;
  const newest = kept.reduce((a, b) => (at(a) >= at(b) ? a : b));
  return {
    note: (visible.length ? visible : kept).map((n) => n.body).join("\n\n"),
    updatedAt: newest.updatedAt,
    notes: kept,
    activeId: activeId && kept.some((n) => n.id === activeId) ? activeId : kept[0].id,
  };
}
// The one env read in this codebase. Named here so a second one has an obvious
// home rather than scattering process.env through the modules.
export const sessionId = (): string | undefined => process.env.CLAUDE_CODE_SESSION_ID || undefined;

// This agent's own ipc alias, which is how a draft addressed to an agent finds
// its reader. Explicit env first so a test or a script can say who it is without
// a broker; then the registry, keyed by session id.
//
// Returning undefined is a real answer and not a failure: an agent that cannot
// name itself simply never matches an agent-addressed draft, per visibleTo's
// fail-closed rule. Nothing here throws, because the drafts lane's whole contract
// is that it works with no server and no broker.
export function selfAlias(): string | undefined {
  if (process.env.KANBAN_ALIAS) return process.env.KANBAN_ALIAS;
  const sid = sessionId();
  if (!sid) return undefined;
  try {
    const db = path.join(os.homedir(), ".claude-ipc", "data", "ipc.sqlite");
    if (!fs.existsSync(db)) return undefined;
    const { Database } = require("bun:sqlite");
    const h = new Database(db, { readonly: true });
    try {
      const row = h.query("select alias from registry_snapshot where session_id = ?1 order by last_seen desc limit 1")
        .get(sid) as { alias?: string } | null;
      return row?.alias || undefined;
    } finally { try { h.close(); } catch { /* nothing to do */ } }
  } catch { return undefined; }
}

export interface BoardMeta {
  root: string; name: string; createdAt: string;
  // who opened it and what the project is, so the board reads as a project's
  // own page rather than an anonymous list
  createdBy?: string;      // the Claude session that opened it
  title?: string;          // human title, defaults to the directory name
  stack?: string[];        // detected from the repo's own manifest files
  repo?: string;           // git remote, when there is one
  branch?: string;
}
export interface RegistryFile {
  boards: Record<string, BoardMeta>;
}

// What this project IS, from files it already keeps. Cheap and best-effort:
// a board with no stack line is better than an init that fails on a guess.
export function projectFacts(root: string): Pick<BoardMeta, "stack" | "repo" | "branch"> {
  const has = (f: string) => fs.existsSync(path.join(root, f));
  const stack: string[] = [];
  if (has("package.json")) stack.push("node");
  if (has("bun.lockb") || has("bun.lock")) stack.push("bun");
  if (has("pyproject.toml") || has("requirements.txt")) stack.push("python");
  if (has("Cargo.toml")) stack.push("rust");
  if (has("go.mod")) stack.push("go");
  if (has("Gemfile")) stack.push("ruby");
  if (has("Package.swift") || fs.existsSync(path.join(root, "Sources"))) stack.push("swift");
  if (has("tsconfig.json")) stack.push("typescript");
  let repo: string | undefined, branch: string | undefined;
  try {
    const head = fs.readFileSync(path.join(root, ".git", "HEAD"), "utf8").trim();
    branch = head.startsWith("ref: refs/heads/") ? head.slice(16) : undefined;
    const cfg = fs.readFileSync(path.join(root, ".git", "config"), "utf8");
    repo = cfg.match(/url\s*=\s*(\S+)/)?.[1];
  } catch { /* not a git repo, which is fine */ }
  return { ...(stack.length ? { stack } : {}), ...(repo ? { repo } : {}), ...(branch ? { branch } : {}) };
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
    reg.boards[slug] = {
      root, name: path.basename(root), createdAt: new Date().toISOString(),
      ...(sessionId() ? { createdBy: sessionId() } : {}),
      ...projectFacts(root),
    };
    atomicWrite(REGISTRY, reg, "register", `boards=${Object.keys(reg.boards).length}`);
  }
  return { slug, root, boardDir: path.join(KROOT, "boards", slug) };
}

// Boards created before facts existed have none, and a stack or branch can
// change under a board anyway. Sync refreshes them.
export function refreshFacts(slug: string): void {
  const reg = registry();
  const b = reg.boards[slug];
  if (!b) return;
  const facts = projectFacts(b.root);
  const same = JSON.stringify([b.stack, b.branch, b.repo]) === JSON.stringify([facts.stack, facts.branch, facts.repo]);
  if (same) return;
  reg.boards[slug] = { ...b, ...facts };
  atomicWrite(REGISTRY, reg, "facts", `board=${slug}`);
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

// Owner items: the human's write channel, stored apart from the agent's verdict
// on it. The server owns what the human wrote, the CLI owns what the agent
// decided, so classification still works with the server down (the same split
// that already lets note pickup work). Design: v2-plan-r2.md.

export const ITEMS = path.join(KROOT, "items.json");
export const LANDINGS = path.join(KROOT, "landings.json");
// The human's selection: which cards and which notes they have ticked as
// "this is what I mean". Board-scoped, server-owned like notes.json, and read
// by the CLI so an agent picking up work sees the same set the human is
// looking at. Empty is the resting state — a selection is an act, not a mode.
export interface Selection { cards: string[]; notes: string[]; updatedAt: string | null }
export const emptySelection = (): Selection => ({ cards: [], notes: [], updatedAt: null });
// a note's key is card:note, so one string identifies it across both stores
export const noteKey = (cardId: string, nId: string) => `${cardId}:${nId}`;
export const loadSelection = (boardDir: string): Selection =>
  readJson<Selection>(path.join(boardDir, "selection.json"), emptySelection());
export function saveSelection(boardDir: string, sel: Selection, by: string): void {
  atomicWrite(path.join(boardDir, "selection.json"), sel, by,
    `cards=${sel.cards.length} notes=${sel.notes.length}`);
}

// What the agent actually receives. Written for a reader with no board open:
// every selected card in full, every selected note verbatim, and the one line
// that says what to do with it. Kept plain text — it arrives as an ipc message.
export function renderSelection(dir: string, name: string, sel: Selection): string {
  const board = loadBoard(dir);
  const notes = loadNotes(dir);
  const plan = loadPlan(dir);
  const byId = new Map(board.cards.map((c) => [c.id, c]));
  const out: string[] = [
    `[kanban] the owner selected ${sel.cards.length} card(s) and ${sel.notes.length} note(s) on board "${name}" and sent them to you.`,
    `They are pointing at this deliberately — treat it as the working set for right now.`,
    ``,
  ];
  for (const id of sel.cards) {
    const c = byId.get(id);
    if (!c) { out.push(`- card ${id} (no longer on the board)`); continue; }
    const src = c.source.kind === "manual" ? "manual" : `${c.source.path}${c.source.line ? ":" + c.source.line : ""}`;
    out.push(`### card ${c.id} · ${c.lane} · ${src}`);
    out.push(c.title);
    if (plan.goals[c.id]) out.push(`  goal: ${plan.goals[c.id]}`);
    const tg = tagsOn(plan, c.id);
    if (tg.length) out.push(`  tags: ${tg.map((t) => `${t.kind}:${t.name}`).join(" ")}`);
    if (c.subs?.length) out.push(...c.subs.map((x) => `  - [${x.done ? "x" : " "}] ${x.title}`));
    if (c.docs?.length) out.push(`  docs: ${c.docs.join(", ")}`);
    const mine = notesOf(notes[c.id]);
    if (mine.length) out.push(...mine.map((n, i) => `  note #${i + 1}: ${n.body}`));
    out.push(``);
  }
  if (sel.notes.length) {
    out.push(`### selected notes`);
    for (const key of sel.notes) {
      const [cardId, nId] = key.split(":");
      const list = notesOf(notes[cardId]);
      const at = list.findIndex((n) => n.id === nId);
      const c = byId.get(cardId);
      if (at < 0) { out.push(`- note ${key} (deleted)`); continue; }
      out.push(`- on card ${cardId}${c ? ` (${c.lane})` : ""}, note #${at + 1}: ${list[at].body}`);
    }
    out.push(``);
  }
  out.push(`Pull the full context with: kanban.sh notes --unread --ack`);
  return out.join("\n");
}

// ---------- tags + goals (the plan store) ----------
//
// One cross-cutting primitive. A milestone is not a checklist under a card, it
// is a tag several cards share, so "what is left for M2" is a filter rather
// than a rollup — and the same machinery then carries the model lane, the
// effort, and anything else the human finds worth calling out.
//
// This is a SEPARATE store from board.json on purpose. board.json belongs to
// the CLI, the UI has to be able to set a tag, and one writer per file is the
// rule the notes and selection stores already keep. Living outside board.json
// also means a plan survives sync without mergeSync carrying it.
export type TagKind = "milestone" | "tier" | "effort" | "area" | "risk" | "plain";

// A preset is a kind with a known vocabulary and a colour. `values` seeds the
// picker; a preset never refuses an unlisted value, because a vocabulary that
// argues with the human is worse than one that suggests.
export interface TagPreset { kind: TagKind; label: string; hint: string; hue: string; values: string[] }
export const TAG_PRESETS: TagPreset[] = [
  { kind: "milestone", label: "Milestone", hue: "violet",
    hint: "A checkpoint several cards share. Filter by it to see what is left.",
    values: ["M1", "M2", "M3", "beta", "ship"] },
  // the lanes and the effort ladder are not invented here: they are the ones
  // rules/model-tier-routing.md already routes work across
  { kind: "tier", label: "Model tier", hue: "blue",
    hint: "The lane this card's work should run on. A suggestion to the agent, never a switch.",
    values: ["lm", "gemini", "haiku", "sonnet", "opus", "fable"] },
  { kind: "effort", label: "Effort", hue: "amber",
    hint: "How much reasoning the card is worth, on the same ladder the agent already uses.",
    values: ["low", "medium", "high", "xhigh"] },
  { kind: "area", label: "Area", hue: "green",
    hint: "Which part of the project it touches.", values: [] },
  { kind: "risk", label: "Risk", hue: "red",
    hint: "What could go wrong if this is done carelessly.",
    values: ["breaking", "data-loss", "security", "perf"] },
  { kind: "plain", label: "Tag", hue: "grey",
    hint: "Anything else worth grouping cards by.", values: [] },
];
export const presetFor = (kind: TagKind): TagPreset =>
  TAG_PRESETS.find((p) => p.kind === kind) ?? TAG_PRESETS[TAG_PRESETS.length - 1];

export interface Tag { id: string; name: string; kind: TagKind; note?: string; createdAt: string }
export interface Plan {
  tags: Tag[];                        // the board's vocabulary
  on: Record<string, string[]>;       // cardId → tag ids
  goals: Record<string, string>;      // cardId → why this card exists, in one line
  updatedAt: string | null;
}
export const emptyPlan = (): Plan => ({ tags: [], on: {}, goals: {}, updatedAt: null });
export const loadPlan = (boardDir: string): Plan =>
  readJson<Plan>(path.join(boardDir, "plan.json"), emptyPlan());
export function savePlan(boardDir: string, plan: Plan, by: string): void {
  plan.updatedAt = new Date().toISOString();
  atomicWrite(path.join(boardDir, "plan.json"), plan, by,
    `tags=${plan.tags.length} tagged=${Object.keys(plan.on).length} goals=${Object.keys(plan.goals).length}`);
}
// Names are matched loosely so "M2", "m2" and " M2 " are one tag; a vocabulary
// that quietly forks on case is a vocabulary nobody can filter by.
export const tagKey = (kind: string, name: string) => `${kind}:${name.trim().toLowerCase()}`;
export const findTag = (plan: Plan, kind: string, name: string): Tag | undefined =>
  plan.tags.find((t) => tagKey(t.kind, t.name) === tagKey(kind, name));
export const tagsOn = (plan: Plan, cardId: string): Tag[] =>
  (plan.on[cardId] ?? []).map((id) => plan.tags.find((t) => t.id === id)).filter((t): t is Tag => !!t);

export const PINS = path.join(KROOT, "pins.json");

export const SHAPES = ["task", "subtask", "clarification", "remark"] as const;
export type ItemShape = (typeof SHAPES)[number];

export interface Item {
  id: string;
  body: string;
  slug?: string;        // board it was written against; absent means unassigned
  boards?: string[];    // where it SHOWS, overriding slug; absent means everywhere
  starred?: boolean;    // owner asking the agent to notice this one
  triggered?: string;   // ISO ts: owner wants pickup now, not at the next sweep
  createdAt: string;
  updatedAt: string;
}

// Where an ask is SHOWN, which the owner sets independently of where they wrote
// it (ruling 2026-08-17: "more of a display rule than a data rule"). Explicit
// tags win; otherwise the origin board scopes it; otherwise it shows everywhere.
// null means everywhere.
export function displayScope(i: Item): string[] | null {
  if (i.boards?.length) return i.boards;
  return i.slug ? [i.slug] : null;
}
export function visibleOn(i: Item, slug: string): boolean {
  const scope = displayScope(i);
  return !scope || scope.includes(slug);
}
// An unsorted item has no landing at all. That absence is what the nudge counts.
export interface Landing {
  shape: ItemShape;
  cardId?: string;      // the card it became, or attached to
  note?: string;        // the agent's one-line account of what it did
  at: string;
  by?: string;          // session that classified it
}
export interface ItemsFile { items: Item[] }
export interface LandingsFile { landings: Record<string, Landing> }
// Owner-only and read-side. No agent ever reads this file, which is the whole
// difference between a pin and a star.
// "board" joins card and item so starring a board reuses the jump list rather
// than adding a fourth store for one boolean.
export interface Pin { id: string; kind: "card" | "item" | "board"; ref: string; slug?: string; label?: string; at: string }
export interface PinsFile { pins: Pin[] }

export const loadItems = (): ItemsFile => readJson<ItemsFile>(ITEMS, { items: [] });
export const loadLandings = (): LandingsFile => readJson<LandingsFile>(LANDINGS, { landings: {} });
export const loadPins = (): PinsFile => readJson<PinsFile>(PINS, { pins: [] });

// Human-authored, so it rotates backups exactly like notes.json: this data is
// gitignored and these copies are the entire recovery surface.
export function saveItems(file: ItemsFile, by: string): void {
  if (fs.existsSync(ITEMS)) {
    fs.copyFileSync(ITEMS, `${ITEMS}.prev-${Date.now()}.bak`);
    const baks = fs.readdirSync(KROOT).filter((f) => f.startsWith("items.json.prev-")).sort();
    for (const old of baks.slice(0, Math.max(0, baks.length - 20))) fs.unlinkSync(path.join(KROOT, old));
  }
  atomicWrite(ITEMS, file, by, `items=${file.items.length}`);
}

// Two CLI classifiers race the same way two board writers do. One lock covers
// all of KROOT, so items, pins, drafts and pulls serialize against each other.
export function withItemsLock<T>(fn: () => T): T {
  return withBoardLock(KROOT, fn);
}

export const isClassified = (l: LandingsFile, id: string): boolean => !!l.landings[id];

// Computed, not stored, so changing the window needs no migration and can never
// leave a half-archived set behind.
export const ARCHIVE_AFTER_MS = 7 * 864e5;
export function isArchived(l: LandingsFile, id: string, now = Date.now()): boolean {
  const at = l.landings[id]?.at;
  return !!at && now - Date.parse(at) > ARCHIVE_AFTER_MS;
}

// What an agent should look at, in the order it should look. Starred first
// because a star IS an instruction; then owner-triggered; then oldest-first so
// nothing starves at the bottom.
export function pendingItems(items: Item[], l: LandingsFile, slug?: string): Item[] {
  return items
    .filter((i) => !isClassified(l, i.id))
    .filter((i) => !slug || visibleOn(i, slug))
    .sort((a, b) =>
      Number(!!b.starred) - Number(!!a.starred) ||
      Number(!!b.triggered) - Number(!!a.triggered) ||
      Date.parse(a.createdAt) - Date.parse(b.createdAt));
}

// Drafts: the rung above an ask. An ask is a sentence the owner throws over the
// wall; a draft is a document they sit down and write. Ruling D5. Design and the
// full definition: assets/reports/20260816-kanban-corpus/v2-plan.md:119.
//
// Same writer split as items, for the same reason: the owner owns the text
// (drafts.json, server) and the agent owns what it did with the text
// (pulls.json, CLI), so a pull still records with the server down.
export const DRAFTS = path.join(KROOT, "drafts.json");
export const PULLS = path.join(KROOT, "pulls.json");

export interface Draft {
  id: string;
  title?: string;       // optional: an untitled draft is a legitimate state
  body: string;         // markdown
  isTemplate?: boolean; // reusable rather than one-off (D5)
  slug?: string;        // board affinity, optional: a draft starts uncoupled
  triggered?: string;   // ISO ts: offered to a session, the item field's twin
  // Who this is FOR: "board:<slug>" or "agent:<alias>". Absent means anyone, the
  // same default Item.boards carries, and the same default every draft written
  // before this field existed still has. `slug` is not replaced: that is the
  // draft's home, this is a statement about who should act on it, and a draft can
  // live on one board while being addressed to an agent working elsewhere.
  to?: string[];
  createdAt: string;
  updatedAt: string;
}

// A draft is consumed on pull and keeps a link to where it went (D5). Shaped
// like Landing on purpose, plus the slug Landing lacks so the link can be built
// without falling back to the source record's own board.
export interface Pull {
  cardId?: string;
  slug?: string;
  note?: string;        // the agent's one-line account of what it made
  at: string;
  by?: string;
  // The body as it stood when it was consumed. Kept so that a draft the owner
  // revises afterwards can be handed back as a DIFF rather than as 44 lines the
  // agent has to re-read to find the three that changed. Without this the pull
  // records that a read happened and nothing about what was read.
  text?: string;
}
export interface DraftsFile { drafts: Draft[] }
export interface PullsFile { pulls: Record<string, Pull> }

// A line diff, smallest thing that answers "what changed since I read this".
// LCS over lines: the table is (a x b) cells, and a draft is prose rather than a
// log, so the sizes here are hundreds of lines, not millions. Guarded anyway,
// because an unbounded table on a pasted file is a hang rather than a slow reply.
export function lineDiff(before: string, after: string, cap = 4000):
  { kind: " " | "-" | "+"; text: string }[] | null {
  const A = before.split("\n"), B = after.split("\n");
  if (A.length > cap || B.length > cap) return null;
  const L: number[][] = Array.from({ length: A.length + 1 }, () => new Array(B.length + 1).fill(0));
  for (let i = A.length - 1; i >= 0; i--) {
    for (let j = B.length - 1; j >= 0; j--) {
      L[i][j] = A[i] === B[j] ? L[i + 1][j + 1] + 1 : Math.max(L[i + 1][j], L[i][j + 1]);
    }
  }
  const out: { kind: " " | "-" | "+"; text: string }[] = [];
  let i = 0, j = 0;
  while (i < A.length && j < B.length) {
    if (A[i] === B[j]) { out.push({ kind: " ", text: A[i] }); i++; j++; }
    else if (L[i + 1][j] >= L[i][j + 1]) { out.push({ kind: "-", text: A[i] }); i++; }
    else { out.push({ kind: "+", text: B[j] }); j++; }
  }
  while (i < A.length) out.push({ kind: "-", text: A[i++] });
  while (j < B.length) out.push({ kind: "+", text: B[j++] });
  return out;
}

// The changed lines with a little context, which is what an agent reads. A whole
// draft echoed back with three markers in it is the thing this exists to avoid.
export function diffHunks(before: string, after: string, ctx = 2): string[] | null {
  const d = lineDiff(before, after);
  if (!d) return null;
  const keep = new Set<number>();
  d.forEach((x, n) => {
    if (x.kind === " ") return;
    for (let k = Math.max(0, n - ctx); k <= Math.min(d.length - 1, n + ctx); k++) keep.add(k);
  });
  if (!keep.size) return [];
  const lines: string[] = [];
  let last = -99;
  [...keep].sort((a, b) => a - b).forEach((n) => {
    if (n > last + 1) lines.push("…");
    lines.push(d[n].kind + " " + d[n].text);
    last = n;
  });
  return lines;
}

export const loadDrafts = (): DraftsFile => readJson<DraftsFile>(DRAFTS, { drafts: [] });
export const loadPulls = (): PullsFile => readJson<PullsFile>(PULLS, { pulls: {} });

// Human-authored and gitignored, so these backups are the only recovery surface.
// Identical to saveItems; if a third one appears, that is the time to factor it.
export function saveDrafts(file: DraftsFile, by: string): void {
  if (fs.existsSync(DRAFTS)) {
    fs.copyFileSync(DRAFTS, `${DRAFTS}.prev-${Date.now()}.bak`);
    const baks = fs.readdirSync(KROOT).filter((f) => f.startsWith("drafts.json.prev-")).sort();
    for (const old of baks.slice(0, Math.max(0, baks.length - 20))) fs.unlinkSync(path.join(KROOT, old));
  }
  atomicWrite(DRAFTS, file, by, `drafts=${file.drafts.length}`);
}

// A pull consumes the text that was there when it was taken. The owner can edit
// a draft afterwards, or offer it again, and either act means what is waiting is
// no longer what the agent read. So a pull older than the owner's last touch is
// spent rather than binding.
//
// Keyed on the id alone, a draft consumed once stayed consumed forever: every
// later revision was invisible to every session while the board went on showing
// the draft as offered. That combination is the worst one, because the board's
// confirmation is what stops the owner re-sending.
export function isPulled(p: PullsFile, d: Draft): boolean {
  const pull = p.pulls[d.id];
  if (!pull) return false;
  const taken = Date.parse(pull.at);
  // An unreadable pull timestamp cannot prove the draft was read, and silence
  // reads as nothing to report. An unprovable pull shows the draft, never hides it.
  if (!Number.isFinite(taken)) return false;
  const touched = Math.max(Date.parse(d.updatedAt) || 0,
                           d.triggered ? Date.parse(d.triggered) || 0 : 0);
  return touched <= taken;
}

// A template is never "waiting to be pulled": using it does not consume it, so
// it would otherwise sit in the queue forever asking to be dealt with.
// Who a draft is for, split by kind. null means anyone, which is the default and
// what every pre-existing draft carries.
export function recipientsOf(d: Draft): { boards: string[]; agents: string[] } | null {
  if (!d.to?.length) return null;
  return {
    boards: d.to.filter((x) => x.startsWith("board:")).map((x) => x.slice(6)),
    agents: d.to.filter((x) => x.startsWith("agent:")).map((x) => x.slice(6)),
  };
}

// The one rule every surface asks: the CLI sweep, the session-start line and any
// future push. Three surfaces asking three copies of this question is the drift
// session-start-line.sh already warns about in its own header.
//
// Fail-closed on purpose. A reader who cannot say who they are does NOT see a
// draft addressed to an agent: the owner's private text going to the wrong reader
// is the one failure here that cannot be taken back.
export function visibleTo(d: Draft, who: { slug?: string; alias?: string }): boolean {
  const r = recipientsOf(d);
  if (!r) return !who.slug || !d.slug || d.slug === who.slug;   // unaddressed: as before
  if (who.alias && r.agents.includes(who.alias)) return true;
  return !!who.slug && r.boards.includes(who.slug);
}

export function pendingDrafts(drafts: Draft[], p: PullsFile, slug?: string, alias?: string): Draft[] {
  return drafts
    .filter((d) => !d.isTemplate && !isPulled(p, d))
    .filter((d) => visibleTo(d, { slug, alias }))
    .sort((a, b) =>
      Number(!!b.triggered) - Number(!!a.triggered) ||
      Date.parse(a.createdAt) - Date.parse(b.createdAt));
}

export type HarvestedCard = Omit<Card, "createdAt" | "updatedAt">;

// Merge a fresh harvest into the existing board. Machine lane only: harvest
// decides lanes, overrides (agent `move`) win, manual cards persist, and a
// vanished card with a human note is kept as stale instead of deleted.
export function mergeSync(boardDir: string, harvested: HarvestedCard[], by: string, force = false) {
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
        titleBrief: old?.titleBrief, // harvest can't write one; the agent's survives
        createdAt: old?.createdAt ?? now,
        updatedAt: old && old.lane === lane ? old.updatedAt : now,
      };
    });

    const seen = new Set(cards.map((c) => c.id));
    for (const old of prev.cards) {
      if (seen.has(old.id)) continue;
      if (old.source.kind === "manual") { cards.push(old); continue; }
      // read the array, not the derived string: an entry can carry notes while
      // its derived field is empty, and deleting that card would lose them
      if (notesOf(notes[old.id]).length) {
        cards.push({ ...old, lane: "stale", staleReason: "source item no longer found", updatedAt: now });
        delta.stale++;
      } else {
        delta.gone++;
        // GC the override with the card: ids are content hashes, so a later
        // identical re-add would silently inherit a stale lane otherwise.
        delete prev.overrides[old.id];
      }
    }

    // A harvest that finds NOTHING where a populated board stood is a broken
    // scanner, not an emptied project — a cap, a moved docs dir, a bad root.
    // Sync would otherwise delete every card and GC the overrides with them,
    // and board.json is the one store with no undo. So: refuse, and say what
    // would have gone. Narrow on purpose (zero yield only): a partial drop is a
    // legitimate outcome, and the rotated backup below covers it.
    if (!force && !cards.length && prev.cards.length) {
      throw new CliError(
        `harvest found no cards, but the board holds ${prev.cards.length} — refusing to empty it`,
        `check the sources first (are the doc paths still there? did a rename move docs/?); ` +
        `if the board really should be empty, kanban.sh sync --force`);
    }
    const file = path.join(boardDir, "board.json");
    // board.json used to be the only store without a rotated backup, which is
    // how one bad sync became unrecoverable. Cheap: these files are small.
    if (fs.existsSync(file)) {
      fs.copyFileSync(file, `${file}.prev-${Date.now()}.bak`);
      const baks = fs.readdirSync(boardDir).filter((f) => f.startsWith("board.json.prev-")).sort();
      for (const old of baks.slice(0, Math.max(0, baks.length - 20))) fs.unlinkSync(path.join(boardDir, old));
    }
    const board: Board = { cards, overrides: prev.overrides, tombstones, syncedAt: now };
    atomicWrite(file, board, by, `cards=${cards.length}`);
    return { board, delta, overridesHeld, notesPreserved: Object.keys(notes).filter((id) => notesOf(notes[id]).length).length };
  });
}
