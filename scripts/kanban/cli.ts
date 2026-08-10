#!/usr/bin/env bun
// Agent-facing CLI behind kanban.sh — mutates only board.json/ack.json (never
// notes.json, the server's), emits digest-sized deltas, refusals propose fixes.

import * as fs from "node:fs";
import * as path from "node:path";
import { execFileSync } from "node:child_process";
import {
  CliError, KROOT, REGISTRY, SERVER_INFO, LANES, type Lane, cardId, readJson, atomicWrite,
  canonicalRoot, slugFor, registry, registerBoard, loadBoard, loadNotes,
  loadAck, mergeSync, withBoardLock, parseNoteTags, TAG_LEGEND, notesOf, noteSeen, ackKey, refreshFacts,
} from "./lib.ts";
import { harvest } from "./harvest.ts";

const args = process.argv.slice(2);
const verb = args[0] ?? "help";
const rest = args.slice(1);

function flag(name: string): string | undefined {
  const i = rest.indexOf(`--${name}`);
  return i >= 0 ? rest[i + 1] : undefined;
}
const hasFlag = (name: string) => rest.includes(`--${name}`);
// Boolean flags never consume the next token, so flag order can't silently
// swallow a positional (the sim + skeptic both flagged the old behavior).
const BOOL_FLAGS = new Set(["json", "force", "undo", "keep-data", "cards", "unread", "ack", "needs-human", "clear"]);
const positional = rest.filter((a, i) => {
  if (a.startsWith("--")) return false;
  const prev = rest[i - 1];
  return !(prev?.startsWith("--") && !BOOL_FLAGS.has(prev.slice(2)));
});

function projectDir(): string {
  return path.resolve(flag("project") ?? process.cwd());
}

// Thrown, never process.exit: an exit inside withBoardLock skips the finally
// that releases the lock and bricks board writes for the sweep window (the
// UX-sim's headline finding). The single catch at the bottom prints and exits.
function die(msg: string, fix: string): never {
  throw new CliError(msg, fix);
}

function boardFor(dir: string) {
  const root = canonicalRoot(dir);
  const slug = slugFor(root);
  const reg = registry();
  if (!reg.boards[slug]) die(`no board for ${root}`, `bun ${__dirname}/cli.ts init --project ${root}`);
  return { slug, root, boardDir: path.join(KROOT, "boards", slug) };
}

function serverPort(): number | null {
  const info = readJson<{ port?: number }>(SERVER_INFO, {});
  return info.port ?? null;
}

function urlFor(slug: string): string {
  const port = serverPort();
  return port ? `http://localhost:${port}/b/${slug}` : `(server not set up — see kanban.sh check)`;
}

function doSync(dir: string, by: string) {
  const { slug, root, boardDir } = dir === "init" ? registerBoard(process.cwd()) : boardFor(dir);
  refreshFacts(slug);
  const h = harvest(root);
  const { delta, overridesHeld, notesPreserved } = mergeSync(boardDir, h.cards, by);
  console.log(
    `synced ${slug}: ${delta.new} new, ${delta.moved} moved, ${delta.kept} unchanged, ` +
    `${delta.gone} gone, ${delta.stale} kept-as-stale` +
    (overridesHeld ? ` · overrides held: ${overridesHeld}` : "") +
    ` · notes preserved: ${notesPreserved} · ` +
    `scanned ${h.scanned.length} files${h.skipped.length ? ` · SKIPPED ${h.skipped.length}: ${h.skipped.slice(0, 3).join(", ")}` : ""}`,
  );
  return { slug, boardDir };
}

try {
switch (verb) {
  case "init": {
    const { slug, root } = registerBoard(projectDir());
    const { } = doSync(projectDir(), "init");
    console.log(`board ready: ${slug} (root ${root})\nopen: ${urlFor(slug)}`);
    break;
  }
  case "sync": {
    doSync(projectDir(), "sync");
    break;
  }
  case "add": {
    const title = positional[0];
    if (!title) die("add needs a title", `kanban.sh add "wire the export" [--lane backlog]`);
    const lane = (flag("lane") ?? "inbox") as Lane;
    if (!LANES.includes(lane)) die(`unknown lane ${lane}`, `one of: ${LANES.join(" ")}`);
    const { slug, boardDir } = boardFor(projectDir());
    withBoardLock(boardDir, () => {
      const board = loadBoard(boardDir);
      const id = cardId("manual", title);
      if (board.cards.some((c) => c.id === id)) die(`card ${id} already exists`, `kanban.sh move ${id} <lane>`);
      const now = new Date().toISOString();
      board.cards.push({ id, title, lane, source: { path: "manual", kind: "manual" }, docs: [], createdAt: now, updatedAt: now });
      atomicWrite(path.join(boardDir, "board.json"), board, "add", `cards=${board.cards.length}`);
      if (hasFlag("json")) console.log(JSON.stringify({ id, lane, slug }));
      else console.log(`added ${id} to ${lane} on ${slug}`);
    });
    break;
  }
  case "move": {
    const [id, laneRaw] = positional;
    const lane = laneRaw as Lane;
    if (!id || !LANES.includes(lane)) die("usage", `kanban.sh move <card-id> <${LANES.join("|")}>`);
    const { slug, boardDir } = boardFor(projectDir());
    withBoardLock(boardDir, () => {
      const board = loadBoard(boardDir);
      const card = board.cards.find((c) => c.id === id);
      if (!card) die(`no card ${id} on ${slug}`, `kanban.sh status --project ${projectDir()} lists ids`);
      card.lane = lane;
      card.updatedAt = new Date().toISOString();
      board.overrides[id] = { lane };
      atomicWrite(path.join(boardDir, "board.json"), board, "move", `card=${id}`);
      console.log(`moved ${id} → ${lane} (override recorded; survives sync)`);
    });
    break;
  }
  case "verify": {
    // Grade what "done" means (M3): how was this card's claimed state checked.
    const [id, gradeRaw] = positional;
    const GRADES = ["executed", "cited", "reasoned"] as const;
    if (!id) die("verify needs a card id", `kanban.sh verify <id> <${GRADES.join("|")}> [--needs-human] [--note "…"] · clear: kanban.sh verify <id> --clear`);
    const { slug, boardDir } = boardFor(projectDir());
    withBoardLock(boardDir, () => {
      const board = loadBoard(boardDir);
      const card = board.cards.find((c) => c.id === id);
      if (!card) die(`no card ${id} on ${slug}`, `kanban.sh status --cards lists ids`);
      if (hasFlag("clear")) {
        delete card.verify;
        atomicWrite(path.join(boardDir, "board.json"), board, "verify", `card=${id} cleared`);
        console.log(`verification cleared on ${id}`);
        return;
      }
      const grade = gradeRaw as (typeof GRADES)[number];
      if (!GRADES.includes(grade)) die(`grade must be one of ${GRADES.join("|")}`, `executed = ran the path · cited = file:line evidence · reasoned = argument only`);
      card.verify = { grade, ...(hasFlag("needs-human") ? { needsHuman: true } : {}), ...(flag("note") ? { note: flag("note")! } : {}), at: new Date().toISOString() };
      card.updatedAt = new Date().toISOString();
      atomicWrite(path.join(boardDir, "board.json"), board, "verify", `card=${id} ${grade}`);
      console.log(`verified ${id}: ${grade}${hasFlag("needs-human") ? " + needs-human" : ""} (survives sync)`);
    });
    break;
  }
  case "link": {
    const [id, doc] = positional;
    if (!id || !doc) die("usage", `kanban.sh link <card-id> <doc-path>`);
    const { boardDir, root } = boardFor(projectDir());
    withBoardLock(boardDir, () => {
      const board = loadBoard(boardDir);
      const card = board.cards.find((c) => c.id === id);
      if (!card) die(`no card ${id}`, `kanban.sh status lists ids`);
      const rel = path.isAbsolute(doc) ? path.relative(root, doc) : doc;
      if (!card.docs.includes(rel)) card.docs.push(rel);
      card.updatedAt = new Date().toISOString();
      atomicWrite(path.join(boardDir, "board.json"), board, "link", `card=${id}`);
      console.log(`linked ${rel} to ${id}`);
    });
    break;
  }
  case "notes": {
    const { slug, boardDir } = boardFor(projectDir());
    const notes = loadNotes(boardDir);
    const ack = loadAck(boardDir);
    const board = loadBoard(boardDir);
    const titles = new Map(board.cards.map((c) => [c.id, c.title]));
    // one row per NOTE, not per card: a card can carry several asks and each
    // gets its own pickup state
    const entries = Object.entries(notes).flatMap(([id, e]) =>
      notesOf(e).map((n) => [id, n, parseNoteTags(n.body)] as const));
    // --unread is the AGENT's queue: @me self-notes never nag it (tagged notes v1)
    const unread = entries.filter(([id, n, t]) => !t.me && !noteSeen(ack, id, n));
    const withTags = hasFlag("unread") ? unread : entries;
    const show = withTags;
    const ackNow = () => {
      const next = { ...ack, notes: { ...(ack.notes ?? {}) } };
      for (const [id, n] of unread) next.notes[ackKey(id, n)] = Date.now();
      next.lastAckTs = Date.now();
      atomicWrite(path.join(boardDir, "ack.json"), next, "ack");
    };
    if (hasFlag("json")) {
      const out = withTags.map(([id, n, t]) => ({ id, noteId: n.id, title: titles.get(id) ?? null, note: n.body, updatedAt: n.updatedAt, unread: !t.me && !noteSeen(ack, id, n), tags: t }));
      let acked = 0;
      if (hasFlag("ack")) { ackNow(); acked = unread.length; }
      console.log(JSON.stringify({ slug, notes: out, acked, legend: TAG_LEGEND }, null, 2));
      break;
    }
    if (show.length === 0) {
      console.log(hasFlag("unread") ? `no unread notes on ${slug}` : `no notes on ${slug}`);
    } else {
      for (const [id, n, t] of withTags.slice(0, 30)) {
        const marks = [t.act && "!now", ...t.skills, ...t.moves.map((l) => ">" + l), t.review && "#review-me", t.me && "@me"].filter(Boolean).join(" ");
        console.log(`[${id}#${n.id}] ${titles.get(id) ?? "(card gone)"}${marks ? `  [${marks}]` : ""}\n  ${n.body.split("\n").join("\n  ")} (${n.updatedAt})`);
      }
      if (show.length > 30) console.log(`… ${show.length - 30} more (open the board for all)`);
      const acts = withTags.filter(([, , t]) => t.act).length;
      const dirs = withTags.flatMap(([id, , t]) => [...t.skills.map((s) => `${s} on ${id}`), ...t.moves.map((l) => `move ${id} ${l}`)]);
      if (acts || dirs.length) console.log(`directives: ${acts} marked !now${dirs.length ? " · " + dirs.join(" · ") : ""}`);
      console.log(TAG_LEGEND);
    }
    if (hasFlag("ack")) {
      ackNow();
      console.log(`acked ${unread.length} unread`);
    }
    break;
  }
  case "status": {
    const reg = registry();
    const port = serverPort();
    // --project filters to one board (with or without --cards); bare status is machine-wide
    const wantOne = flag("project") !== undefined || hasFlag("cards");
    const onlySlug = wantOne ? slugFor(canonicalRoot(projectDir())) : null;
    const entries = Object.entries(reg.boards).filter(([s]) => !onlySlug || s === onlySlug);
    if (onlySlug && entries.length === 0) die(`no board for ${projectDir()}`, `kanban.sh init --project ${projectDir()}`);
    const boards = entries.map(([slug, b]) => {
      const board = loadBoard(path.join(KROOT, "boards", slug));
      const counts = Object.fromEntries(LANES.map((l) => [l, board.cards.filter((c) => c.lane === l).length]));
      return { slug, root: b.root, counts, syncedAt: board.syncedAt, cards: hasFlag("cards") ? board.cards : undefined };
    });
    if (hasFlag("json")) {
      console.log(JSON.stringify({ server: { port }, boards }, null, 2));
      break;
    }
    console.log(`server: ${port ? `port ${port}` : "NOT CONFIGURED"} · boards: ${entries.length}${onlySlug ? ` (filtered)` : ""}`);
    for (const b of boards) {
      const countStr = LANES.map((l) => `${l}:${b.counts[l]}`).join(" ");
      console.log(`  ${b.slug} (${b.root}) · ${countStr} · synced ${b.syncedAt ?? "never"}`);
      if (b.cards) for (const c of b.cards) console.log(`  ${c.id} [${c.lane}] ${c.title} (${c.source.path})`);
    }
    break;
  }
  case "open": {
    const { slug } = boardFor(projectDir());
    const url = urlFor(slug);
    if (!url.startsWith("http")) die("server not configured", "claim a port + start pm2 (see DESIGN.md build step) then retry");
    execFileSync("open", [url]);
    console.log(url);
    break;
  }
  case "check": {
    let bad = 0;
    const reg = registry();
    const port = serverPort();
    if (!port) { console.log("FAIL server.json has no port — fix: ports.sh claim kanban --tier 2, write ~/.claude/kanban/server.json, pm2 start"); bad++; }
    for (const [slug] of Object.entries(reg.boards)) {
      const board = loadBoard(path.join(KROOT, "boards", slug));
      const badLane = board.cards.find((c) => !LANES.includes(c.lane));
      if (badLane) { console.log(`FAIL ${slug}: card ${badLane.id} has unknown lane ${badLane.lane}`); bad++; }
    }
    if (port) {
      try {
        const res = await fetch(`http://localhost:${port}/api/boards`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        console.log(`ok server responds on :${port} (${Object.keys(reg.boards).length} boards)`);
      } catch (e: any) {
        console.log(`FAIL server not answering on :${port} (${e.message}) — fix: pm2 restart kanban (or pm2 start bun --name kanban -- ${__dirname}/server.ts --port ${port})`);
        bad++;
      }
    }
    try {
      const launchd = execFileSync("launchctl", ["list"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
      if (!/pm2/i.test(launchd)) {
        console.log("note: pm2 is not launchd-registered — the board will NOT survive a reboot. One-time fix (needs sudo, run it YOURSELF): pm2 startup   (run the command it prints, then: pm2 save)");
      }
    } catch { /* launchctl unavailable: nothing to report */ }
    console.log(bad === 0 ? "READY" : `${bad} problem(s)`);
    process.exit(bad === 0 ? 0 : 1);
  }
  case "show": {
    const id = positional[0];
    if (!id) die("show needs a card id", "kanban.sh show <card-id> [--json]");
    const { slug, root, boardDir } = boardFor(projectDir());
    const board = loadBoard(boardDir);
    const card = board.cards.find((c) => c.id === id);
    if (!card) die(`no card ${id} on ${slug}`, `kanban.sh status --cards lists ids`);
    const note = loadNotes(boardDir)[id] ?? null;
    if (hasFlag("json")) {
      console.log(JSON.stringify({ slug, root, card, note, override: board.overrides[id] ?? null }, null, 2));
      break;
    }
    console.log(`${card.id} · ${card.lane}${card.tag ? ` · ${card.tag}` : ""}${card.heading ? ` · ${card.heading}` : ""}`);
    console.log(card.title);
    console.log(`source: ${card.source.kind === "manual" ? "manual" : `${card.source.path}${card.source.line ? ":" + card.source.line : ""}`}${card.via ? ` · via ${card.via}` : ""}`);
    if (card.verify) console.log(`verified: ${card.verify.grade}${card.verify.needsHuman ? " + needs-human" : ""}${card.verify.note ? ` — ${card.verify.note}` : ""} (${card.verify.at})`);
    for (const s of card.subs ?? []) console.log(`  [${s.done ? "x" : " "}] ${s.title}`);
    if (card.docs.length) console.log(`docs: ${card.docs.join(" · ")}`);
    if (note?.note) console.log(`note (${note.updatedAt}): ${note.note}`);
    break;
  }
  case "drop": {
    const id = positional[0];
    if (!id) die("drop needs a card id", "kanban.sh drop <id> [--force] · undo: kanban.sh drop <id> --undo (flags go AFTER the id)");
    const { slug, boardDir } = boardFor(projectDir());
    if (hasFlag("undo")) {
      withBoardLock(boardDir, () => {
        const board = loadBoard(boardDir);
        if (!board.tombstones?.[id]) die(`no tombstone for ${id} on ${slug}`, `kanban.sh show ${id} — the card may simply be live`);
        delete board.tombstones[id];
        atomicWrite(path.join(boardDir, "board.json"), board, "drop-undo", `card=${id}`);
        console.log(`tombstone removed — ${id} returns on next sync if its source line still exists`);
      });
      break;
    }
    // Note deletion must happen BEFORE the card leaves the board: the server's
    // membership check (correctly) refuses notes on nonexistent cards.
    const preNote = loadNotes(boardDir)[id];
    if (preNote?.note) {
      // the card may hold several notes and --force deletes all of them, so
      // say how many rather than quoting 48 characters of the first
      const held = notesOf(preNote);
      if (!hasFlag("force")) {
        const what = held.length > 1
          ? `${held.length} human notes (first: "${held[0].body.slice(0, 40)}…")`
          : `a human note ("${preNote.note.slice(0, 48)}…")`;
        die(`card ${id} carries ${what}`, `kanban.sh drop ${id} --force drops the card AND ${held.length > 1 ? `all ${held.length} notes` : "the note"}`);
      }
      const port = serverPort();
      if (!port) die(`--force needs the server (single-writer: notes are server-owned) and none is configured`, `start the kanban pm2 service, then retry`);
      const res = await fetch(`http://localhost:${port}/api/note`, {
        method: "POST", headers: { "content-type": "application/json" },
        // `all` is the explicit wipe: dropping a card takes every note with it
        body: JSON.stringify({ slug, cardId: id, note: "", all: true }),
      }).catch(() => null);
      if (!res?.ok) die(`server would not delete the note (HTTP ${res?.status ?? "unreachable"})`, `check the kanban service, then retry`);
      console.error(`note deleted (via server, single-writer preserved)`);
    }
    withBoardLock(boardDir, () => {
      const board = loadBoard(boardDir);
      const card = board.cards.find((c) => c.id === id);
      if (!card) die(`no card ${id} on ${slug}`, `kanban.sh status --cards lists ids`);
      // Re-check under the lock: a note POSTed between the pre-lock read and
      // here would otherwise be orphaned (or dodge the no-force refusal).
      if (loadNotes(boardDir)[id]?.note) {
        die(`a note landed on ${id} while dropping`, `re-run: kanban.sh drop ${id}${hasFlag("force") ? " --force" : ""}`);
      }
      board.cards = board.cards.filter((c) => c.id !== id);
      delete board.overrides[id];
      if (card.source.kind !== "manual") {
        board.tombstones = { ...(board.tombstones ?? {}), [id]: new Date().toISOString() };
      }
      atomicWrite(path.join(boardDir, "board.json"), board, "drop", `card=${id}`);
      console.log(card.source.kind === "manual"
        ? `dropped ${id} (manual card, gone for good)`
        : `dropped ${id} (tombstoned — sync won't resurrect it; undo: kanban.sh drop ${id} --undo)`);
    });
    break;
  }
  case "unregister": {
    const reg = registry();
    // A given-but-unknown slug MUST error, never fall back to the CWD board:
    // this verb is destructive and a typo'd slug must not retarget it.
    if (positional[0] && !reg.boards[positional[0]]) {
      die(`no board ${positional[0]} in the registry`, `kanban.sh status lists boards`);
    }
    const slug = positional[0] ?? slugFor(canonicalRoot(projectDir()));
    if (!reg.boards[slug]) die(`no board ${slug} in the registry`, `kanban.sh status lists boards`);
    const boardDir = path.join(KROOT, "boards", slug);
    delete reg.boards[slug];
    atomicWrite(REGISTRY, reg, "unregister", `boards=${Object.keys(reg.boards).length}`);
    if (!hasFlag("keep-data") && fs.existsSync(boardDir)) {
      try {
        execFileSync("trash", [boardDir]);
        console.log(`unregistered ${slug}; board data trashed (recoverable from Trash)`);
      } catch {
        console.log(`unregistered ${slug}; board data left at ${boardDir} (trash unavailable — remove it yourself)`);
      }
    } else {
      console.log(`unregistered ${slug}${hasFlag("keep-data") ? `; data kept at ${boardDir}` : ""}`);
    }
    break;
  }
  default:
    console.log(`kanban.sh <verb>
  init [--project dir]     register + first sync + URL
  sync [--project dir]     re-harvest; prints the delta digest
  add "<title>" [--lane l] manual card (model-driven lifecycle, D4a)
  move <id> <lane>         override lane (survives sync)
  verify <id> <grade>      grade the card's claimed state: executed (ran it) ·
                           cited (file:line evidence) · reasoned (argument only);
                           [--needs-human] [--note "…"] [--clear]; survives sync
  link <id> <doc.md>       attach a doc to a card (survives sync)
  show <id> [--json]       one card: lane, tag, subs, docs, note
  notes [--unread] [--ack] human notes (D5a pull); --ack also displays, so plain
                           --unread is the read-only re-peek; --ack marks read.
                           note text may carry tags — @me self-note (excluded
                           from --unread) · !now act on pickup · /skill run it ·
                           >lane apply via move · #review-me human's queue
  drop <id> [--force|--undo] retire a card; doc-sourced ones tombstone (sync
                           won't resurrect); noted cards need --force
  unregister [slug] [--keep-data] remove a board everywhere (registry, status,
                           hub, HTTP); default trashes the board data too
  status [--cards] [--project dir] all boards; --project (or --cards) filters to one
  open                     open this project's board
  check                    self-verify (schema + server HTTP)

  --json on status/show/notes/add emits machine-readable JSON (flags go AFTER
  positional args). lanes: ${LANES.join(" ")}
  notes are deleted by saving an empty note (board UI, or POST /api/note with note:"")`);
}
} catch (e) {
  if (e instanceof CliError) {
    console.error(`kanban: ${e.message}\n  fix: ${e.fix}`);
    process.exit(1);
  }
  throw e;
}
