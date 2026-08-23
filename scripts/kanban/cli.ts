#!/usr/bin/env bun
// Agent-facing CLI behind kanban.sh — mutates only board.json/ack.json (never
// notes.json, the server's), emits digest-sized deltas, refusals propose fixes.

import * as fs from "node:fs";
import * as path from "node:path";
import { execFileSync } from "node:child_process";
import {
  CliError, KROOT, REGISTRY, SERVER_INFO, LANES, LANDINGS, SHAPES, BRIEF_MAX, type Lane, type ItemShape,
  cardId, readJson, atomicWrite,
  canonicalRoot, slugFor, registry, registerBoard, loadBoard, loadNotes,
  loadAck, mergeSync, withBoardLock, parseNoteTags, TAG_LEGEND, notesOf, noteSeen, ackKey, refreshFacts,
  loadItems, loadLandings, withItemsLock, pendingItems, isClassified, isArchived, sessionId,
  loadSelection, renderSelection, loadPlan, tagsOn, findTag, TAG_PRESETS, presetFor, type TagKind,
  displayScope, PULLS, loadDrafts, loadPulls, pendingDrafts, isPulled, diffHunks,
  DRAFTS, saveDrafts, recipientsOf, selfAlias,
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
const BOOL_FLAGS = new Set(["json", "force", "undo", "keep-data", "cards", "unread", "ack", "needs-human", "clear", "all", "global", "templates"]);
const positional = rest.filter((a, i) => {
  if (a.startsWith("--")) return false;
  const prev = rest[i - 1];
  return !(prev?.startsWith("--") && !BOOL_FLAGS.has(prev.slice(2)));
});

// The human-lane stores (notes, selection, plan) belong to the server, so the
// CLI asks rather than writes. A refusal comes back as the server's own
// sentence, which is more specific than anything this side could invent.
async function post(route: string, body: unknown): Promise<any> {
  const info = readJson<{ port?: number }>(SERVER_INFO, {});
  if (!info.port) die("the board server is not running", `pm2 start kanban, or: kanban.sh check`);
  let res: Response;
  try {
    res = await fetch(`http://127.0.0.1:${info.port}${route}`, {
      method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body),
    });
  } catch (e: any) { return die(`could not reach the board server on :${info.port}`, `kanban.sh check`); }
  const out = await res.json().catch(() => ({}));
  if (!res.ok) die(out.error ?? `server said ${res.status}`, `fix the above and re-run`);
  return out;
}

function projectDir(): string {
  return path.resolve(flag("project") ?? process.cwd());
}

// Thrown, never process.exit: an exit inside withBoardLock skips the finally
// that releases the lock and bricks board writes for the sweep window (the
// UX-sim's headline finding). The single catch at the bottom prints and exits.
function die(msg: string, fix: string): never {
  throw new CliError(msg, fix);
}

// The board face shows this instead of a long title, so it has to read like a
// name: refuse an over-long one rather than truncate it, because a hard cut
// mid-clause is exactly the unreadable card face the brief exists to prevent.
// Characters as a reader counts them, not UTF-16 code units: an emoji is two
// units and one character, so .length halved the real cap on emoji-bearing text.
const charLen = (s: string) => [...s].length;
function checkBrief(raw: string | undefined, title: string): string | undefined {
  if (raw === undefined) return undefined;
  const t = raw.trim();
  if (!t) die("--brief is empty", `drop the flag, or give a summary phrase: --brief "wire the CSV export"`);
  const n = charLen(t);
  if (n > BRIEF_MAX) {
    die(`--brief is ${n} chars, cap is ${BRIEF_MAX}`,
        `summarise, don't truncate — a phrase the human can recognise the card by: --brief "${[...t].slice(0, 48).join("").trim()}…"`);
  }
  if (title && n > charLen(title)) die("--brief is longer than the title", `drop --brief; the title already is one`);
  return t;
}

// readJson throws a bare Error on a corrupt file, which reaches the user as a
// stack trace instead of the kanban:/fix: contract every other refusal honours.
function itemStore() {
  try { return { items: loadItems().items, landings: loadLandings() }; }
  catch (e: any) {
    die(`the owner's asks could not be read: ${e.message}`,
        `inspect or trash the broken file, then re-run; the boards are unaffected`);
  }
}

function draftStore() {
  try { return { drafts: loadDrafts().drafts, pulls: loadPulls() }; }
  catch (e: any) {
    die(`the owner's drafts could not be read: ${e.message}`,
        `inspect or trash the broken file, then re-run; the boards are unaffected`);
  }
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
  const { delta, overridesHeld, notesPreserved } = mergeSync(boardDir, h.cards, by, hasFlag("force"));
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
    const titleBrief = checkBrief(flag("brief"), title);
    const lane = (flag("lane") ?? "inbox") as Lane;
    if (!LANES.includes(lane)) die(`unknown lane ${lane}`, `one of: ${LANES.join(" ")}`);
    const { slug, boardDir } = boardFor(projectDir());
    withBoardLock(boardDir, () => {
      const board = loadBoard(boardDir);
      const id = cardId("manual", title);
      if (board.cards.some((c) => c.id === id)) die(`card ${id} already exists`, `kanban.sh move ${id} <lane>`);
      const now = new Date().toISOString();
      board.cards.push({ id, title, ...(titleBrief ? { titleBrief } : {}), lane, source: { path: "manual", kind: "manual" }, docs: [], createdAt: now, updatedAt: now });
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
  // The read side of the board's two selection states. The human ticks cards or
  // notes in the UI to say "this is what I mean"; without this verb that signal
  // reaches nobody, which is exactly the dead end pins.json already is.
  case "selected": {
    const { slug, boardDir } = boardFor(projectDir());
    const { name } = registry().boards[slug] ?? { name: slug };
    const sel = loadSelection(boardDir);
    if (hasFlag("json")) { console.log(JSON.stringify(sel)); break; }
    if (!sel.cards.length && !sel.notes.length) {
      console.log(`nothing selected on ${slug} — the owner has not ticked anything`);
      break;
    }
    console.log(renderSelection(boardDir, name, sel));
    break;
  }
  // Tags are the board's one cross-cutting axis: a milestone, a model lane, an
  // effort, an area. Writes go through the server because plan.json is the
  // human lane's file, the same way `drop --force` routes note deletion.
  case "tag": {
    const [id, spec] = positional;
    const { slug, boardDir } = boardFor(projectDir());
    if (!id) {
      // bare `tag` lists the vocabulary and what it is worth
      const plan = loadPlan(boardDir);
      if (hasFlag("json")) { console.log(JSON.stringify(plan.tags)); break; }
      if (!plan.tags.length) {
        console.log(`no tags on ${slug} yet.\n  kinds: ${TAG_PRESETS.map((t) => t.kind).join(" ")}` +
          `\n  add one: kanban.sh tag <card-id> milestone:M2`);
        break;
      }
      // A dropped card leaves its tags behind in plan.json, so a raw count here
      // promises cards the filter cannot produce. Counted against the live board
      // instead. This makes the NUMBER honest; the orphaned rows are still in the
      // store and their removal belongs on the drop path, which is server-side.
      const live = new Set(loadBoard(boardDir).cards.map((c) => c.id));
      const counts = new Map<string, number>();
      for (const [cid, ids] of Object.entries(plan.on)) {
        if (!live.has(cid)) continue;
        for (const t of ids) counts.set(t, (counts.get(t) ?? 0) + 1);
      }
      for (const t of plan.tags) console.log(`  ${t.kind}:${t.name}  ${counts.get(t.id) ?? 0} card(s)`);
      break;
    }
    if (!spec) die("usage", `kanban.sh tag <card-id> <kind>:<name>   (drop it with a leading -)`);
    const strip = spec.startsWith("-") ? spec.slice(1) : spec;
    const [kindRaw, ...rest] = strip.split(":");
    const name = rest.join(":");
    const kind = (name ? kindRaw : "plain") as TagKind;
    const value = name || kindRaw;
    if (!TAG_PRESETS.some((t) => t.kind === kind)) {
      die(`unknown tag kind ${kind}`, `one of: ${TAG_PRESETS.map((t) => t.kind).join(" ")}, or a bare name for a plain tag`);
    }
    const res = await post("/api/tag", { slug, op: spec.startsWith("-") ? "unapply" : "apply", cardId: id, kind, name: value });
    console.log(`${spec.startsWith("-") ? "removed" : "tagged"} ${id}: ${kind}:${value}`);
    break;
  }
  case "goal": {
    const [id, ...restWords] = positional;
    const { slug, boardDir } = boardFor(projectDir());
    if (!id) die("usage", `kanban.sh goal <card-id> "why this card exists"   (empty clears it)`);
    if (!restWords.length && !hasFlag("clear")) {
      const g = loadPlan(boardDir).goals[id];
      console.log(g ? g : `no goal on ${id}`);
      break;
    }
    const goal = hasFlag("clear") ? "" : restWords.join(" ");
    await post("/api/goal", { slug, cardId: id, goal });
    console.log(goal ? `goal set on ${id}: ${goal}` : `goal cleared on ${id}`);
    break;
  }
  case "after": {
    // Execution order: this card comes after those. Bare reads it; --clear drops it.
    const [id, ...ids] = positional;
    const { slug, boardDir } = boardFor(projectDir());
    if (!id) die("usage", `kanban.sh after <card-id> <id> [<id>…]   (bare reads it; --clear drops it)`);
    if (!ids.length && !hasFlag("clear")) {
      const a = loadPlan(boardDir).seq?.[id] ?? [];
      console.log(a.length ? `after: ${a.join(" ")}` : `no order on ${id}`);
      break;
    }
    const after = hasFlag("clear") ? [] : ids.flatMap((x) => x.split(","));
    await post("/api/after", { slug, cardId: id, after });
    console.log(after.length ? `${id} after ${after.join(" ")}` : `order cleared on ${id}`);
    break;
  }
  case "brief": {
    const [id, text] = positional;
    if (!id || (!text && !hasFlag("clear"))) die("usage", `kanban.sh brief <card-id> "one-line summary" | --clear`);
    const { slug, boardDir } = boardFor(projectDir());
    withBoardLock(boardDir, () => {
      const board = loadBoard(boardDir);
      const card = board.cards.find((c) => c.id === id);
      if (!card) die(`no card ${id} on ${slug}`, `kanban.sh status --project ${projectDir()} lists ids`);
      // the card's REAL title, not "": passing an empty one silently skipped the
      // longer-than-the-title check on the only path a harvested card can use
      const titleBrief = hasFlag("clear") ? undefined : checkBrief(text, card.title);
      if (titleBrief) card.titleBrief = titleBrief; else delete card.titleBrief;
      card.updatedAt = new Date().toISOString();
      atomicWrite(path.join(boardDir, "board.json"), board, "brief", `card=${id}`);
      console.log(titleBrief ? `brief set on ${id}: ${titleBrief}` : `brief cleared on ${id}`);
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
  // The owner's pending writing. Reads items.json without the server, so a
  // sweep works when the board is down — the same reason ack is a CLI verb.
  case "items": {
    const { items, landings } = itemStore();
    // Sweep landings whose ask is gone. The CLI owns this file, so the delete
    // path in the server cannot do it; ids are short and recyclable, and a
    // stale landing would make a fresh ask arrive pre-sorted and invisible.
    {
      const live = new Set(items.map((i) => i.id));
      const orphans = Object.keys(landings.landings).filter((id) => !live.has(id));
      if (orphans.length) {
        withItemsLock(() => {
          const file = loadLandings();
          for (const id of orphans) delete file.landings[id];
          atomicWrite(LANDINGS, file, "landing-gc", `dropped=${orphans.length}`);
        });
        for (const id of orphans) delete landings.landings[id];
      }
    }
    const scope = hasFlag("global") ? undefined : (() => {
      try { return boardFor(projectDir()).slug; } catch { return undefined; }
    })();
    const pending = pendingItems(items, landings, scope);
    const shown = hasFlag("all")
      ? items.filter((i) => !scope || i.slug === scope || !i.slug)
      : pending;
    if (hasFlag("json")) {
      console.log(JSON.stringify({ scope: scope ?? "all boards", pending: pending.length,
        items: shown.map((i) => ({ ...i, landing: landings.landings[i.id] ?? null })) }));
      break;
    }
    if (!shown.length) {
      console.log(scope ? `no owner items pending on ${scope}` : "no owner items pending");
      break;
    }
    console.log(`${pending.length} pending${scope ? ` on ${scope}` : ""}${hasFlag("all") ? ` · ${shown.length} shown` : ""}`);
    for (const i of shown) {
      const l = landings.landings[i.id];
      const mark = l ? (isArchived(landings, i.id) ? "archived" : l.shape) : i.starred ? "STARRED" : i.triggered ? "now" : "pending";
      // Origin and visibility are different facts and the owner sets them
      // separately, so an ask written on one board but shown on others has to
      // say both rather than collapsing to one slug.
      const scope = displayScope(i);
      const where = i.slug ?? "unassigned";
      const shownOn = !scope ? "shown everywhere"
        : i.boards?.length ? `shown on ${scope.join(", ")}`
        : "";
      console.log(`  ${i.id}  [${mark}] ${where}${shownOn ? ` · ${shownOn}` : ""}  ${i.body.split("\n")[0].slice(0, 72)}`);
    }
    console.log(`classify with: kanban.sh classify <item-id> <${SHAPES.join("|")}> [--card <card-id>] [--note "what you did"]`);
    break;
  }
  // Records what the agent DID with an item. Minting the card is `add`; this
  // verb only writes the verdict, so each does one thing and composes.
  case "classify": {
    const [id, shapeRaw] = positional;
    const shape = shapeRaw as ItemShape;
    // Sorting hides an ask from every rail and every session line, so it needs
    // the reversal drop/verify/unregister all have.
    if (id && hasFlag("undo")) {
      withItemsLock(() => {
        const file = loadLandings();
        if (!file.landings[id]) die(`item ${id} is not classified`, `kanban.sh items --all  # shows what is sorted`);
        delete file.landings[id];
        atomicWrite(LANDINGS, file, "classify-undo", `landings=${Object.keys(file.landings).length}`);
        console.log(`unclassified ${id}; it is pending again`);
      });
      break;
    }
    if (!id || !SHAPES.includes(shape)) {
      die("usage", `kanban.sh classify <item-id> <${SHAPES.join("|")}> [--card <card-id>] [--note "what you did"] · retract: kanban.sh classify <item-id> --undo`);
    }
    const card = flag("card");
    const note = flag("note");
    withItemsLock(() => {
      const { items } = loadItems();
      const it = items.find((x) => x.id === id);
      if (!it) die(`no item ${id}`, `kanban.sh items --all  # lists the ids`);
      if (card && !/^[a-f0-9]{12}$/.test(card)) die(`--card must be a 12-hex card id, got ${card}`, `kanban.sh show <card-id>`);
      // A card id that is not on any board is a typo, and recording it would
      // make the landing link dead on arrival.
      if (card) {
        const found = Object.keys(registry().boards).some((s) => {
          try { return loadBoard(path.join(KROOT, "boards", s)).cards.some((c) => c.id === card); } catch { return false; }
        });
        if (!found) die(`card ${card} is not on any board`, `kanban.sh add "<title>" then classify with the printed id`);
      }
      const file = loadLandings();
      const prior = file.landings[id];
      file.landings[id] = { shape, at: new Date().toISOString(),
        ...(card ? { cardId: card } : {}), ...(note ? { note } : {}), ...(sessionId() ? { by: sessionId() } : {}) };
      atomicWrite(LANDINGS, file, "classify", `landings=${Object.keys(file.landings).length}`);
      const msg = `${prior ? "re-classified" : "classified"} ${id} as ${shape}${card ? ` → card ${card}` : ""}`;
      if (hasFlag("json")) console.log(JSON.stringify({ id, shape, card: card ?? null, reclassified: !!prior }));
      else console.log(msg);
    });
    break;
  }
  // A draft is a document, so this verb has to be able to hand over the whole
  // text: `drafts <id>` prints one in full, which is what a pull reads from.
  case "drafts": {
    const { drafts, pulls } = draftStore();
    // Same orphan sweep as `items`, for the same reason: ids are short and
    // recyclable, so a stale pull would make a fresh draft arrive pre-consumed.
    {
      const live = new Set(drafts.map((d) => d.id));
      const orphans = Object.keys(pulls.pulls).filter((id) => !live.has(id));
      if (orphans.length) {
        withItemsLock(() => {
          const file = loadPulls();
          for (const id of orphans) delete file.pulls[id];
          atomicWrite(PULLS, file, "pull-gc", `dropped=${orphans.length}`);
        });
        for (const id of orphans) delete pulls.pulls[id];
      }
    }
    const [wanted] = positional;
    if (wanted) {
      const d = drafts.find((x) => x.id === wanted);
      if (!d) die(`no draft ${wanted}`, `kanban.sh drafts --all  # lists the ids`);
      const p = pulls.pulls[d.id];
      // The record and the verdict are different questions: a pull row can exist
      // and still be spent, because the owner has revised the draft since.
      const consumed = isPulled(pulls, d);
      if (hasFlag("json")) { console.log(JSON.stringify({ ...d, pull: p ?? null, consumed })); break; }
      console.log(`${d.id}  ${d.isTemplate ? "[template]" : consumed ? "[pulled]" : "[pending]"}${d.slug ? `  ${d.slug}` : ""}`);
      if (d.title) console.log(d.title);
      // A draft you already consumed and the owner has since revised is not new
      // text, it is a CHANGE, and reading 44 lines to find the 3 that moved is the
      // work this exists to remove. The diff leads because it is the news; the
      // body still follows, because a change out of context is not actionable.
      if (p && !consumed) {
        const hunks = p.text === undefined ? null : diffHunks(p.text, d.body);
        console.log("");
        console.log(`REVISED since you pulled it at ${p.at}${p.note ? ` ("${p.note}")` : ""}.`);
        if (hunks === null) {
          console.log(p.text === undefined
            ? "  No diff: this was pulled before revisions were recorded, or the draft was too large to snapshot."
            : "  No diff: the draft is too large to compare. Read it in full below.");
        } else if (!hunks.length) {
          console.log("  The text is unchanged; it came back because it was offered again.");
        } else {
          console.log("");
          for (const l of hunks) console.log("  " + l);
        }
        console.log("");
        console.log("--- the draft in full ---");
      }
      console.log("");
      console.log(d.body);
      if (!consumed && !d.isTemplate) console.log(`\nrecord what you make of it: kanban.sh pull ${d.id} [--card <card-id>] [--note "what you did"]`);
      break;
    }
    const scope = hasFlag("global") ? undefined : (() => {
      try { return boardFor(projectDir()).slug; } catch { return undefined; }
    })();
    const pending = pendingDrafts(drafts, pulls, scope, selfAlias());
    const shown = hasFlag("templates") ? drafts.filter((d) => d.isTemplate)
      : hasFlag("all") ? drafts.filter((d) => !scope || !d.slug || d.slug === scope)
      : pending;
    if (hasFlag("json")) {
      console.log(JSON.stringify({ scope: scope ?? "all boards", pending: pending.length,
        drafts: shown.map((d) => ({ ...d, pull: pulls.pulls[d.id] ?? null })) }));
      break;
    }
    if (!shown.length) {
      console.log(hasFlag("templates") ? "no templates" : scope ? `no drafts pending on ${scope}` : "no drafts pending");
      break;
    }
    console.log(`${pending.length} pending${scope ? ` on ${scope}` : ""}${shown.length !== pending.length ? ` · ${shown.length} shown` : ""}`);
    for (const d of shown) {
      const mark = d.isTemplate ? "template" : isPulled(pulls, d) ? "pulled" : d.triggered ? "now" : "pending";
      const head = d.title ?? d.body.split("\n").find((l) => l.trim()) ?? "(empty)";
      const lines = d.body.split("\n").length;
      const to = d.to?.length ? ` → ${d.to.join(" ")}` : "";
      console.log(`  ${d.id}  [${mark}] ${d.slug ?? "unassigned"}${to} · ${lines}L  ${head.slice(0, 60)}`);
    }
    console.log(`read one in full: kanban.sh drafts <draft-id>`);
    break;
  }
  // The pull is the moment a draft's content becomes project material, and it
  // goes through the agent so cards still come from docs the agent processed.
  // Who a draft is for. The owner normally sets this from the drafts page; the
  // verb exists so an agent can hand one on, and so the rule is testable without
  // a browser.
  case "to": {
    const [id, ...targets] = positional;
    if (!id) die("need a draft id", `kanban.sh to <draft-id> agent:<alias>|board:<slug> [...]  ·  --clear`);
    const { drafts } = loadDrafts();
    const d = drafts.find((x) => x.id === id);
    if (!d) die(`no draft ${id}`, `kanban.sh drafts --all  # lists the ids`);
    if (hasFlag("clear")) {
      delete d.to;
    } else {
      if (!targets.length) die("need at least one recipient", `kanban.sh to ${id} agent:<alias>   ·   --clear to address it to anyone`);
      for (const t of targets) {
        if (!/^(agent|board):.+$/.test(t)) {
          die(`"${t}" is not a recipient`, `use agent:<alias> or board:<slug> — kanban.sh status lists the board slugs`);
        }
        // Same refusal /api/pin makes: a recipient pointing at nothing is a draft
        // addressed to a place that does not exist, which reads as delivered.
        if (t.startsWith("board:") && !registry().boards[t.slice(6)]) {
          die(`no board ${t.slice(6)}`, `kanban.sh status   # lists the slugs`);
        }
      }
      d.to = [...new Set(targets)];
    }
    saveDrafts({ drafts }, "to");
    const r = recipientsOf(d);
    console.log(r ? `${id} is for ${d.to!.join(", ")}` : `${id} is for anyone`);
    break;
  }
  case "pull": {
    const [id] = positional;
    if (id && hasFlag("undo")) {
      withItemsLock(() => {
        const file = loadPulls();
        if (!file.pulls[id]) die(`draft ${id} is not pulled`, `kanban.sh drafts --all  # shows what is consumed`);
        delete file.pulls[id];
        atomicWrite(PULLS, file, "pull-undo", `pulls=${Object.keys(file.pulls).length}`);
        console.log(`un-pulled ${id}; it is pending again`);
      });
      break;
    }
    if (!id) die("usage", `kanban.sh pull <draft-id> [--card <card-id>] [--note "what you made of it"] · retract: kanban.sh pull <draft-id> --undo`);
    const card = flag("card");
    const note = flag("note");
    withItemsLock(() => {
      const { drafts } = loadDrafts();
      const d = drafts.find((x) => x.id === id);
      if (!d) die(`no draft ${id}`, `kanban.sh drafts --all  # lists the ids`);
      // Using a template does not consume it, so recording a pull against one
      // would retire something the owner means to reuse.
      if (d.isTemplate) die(`draft ${id} is a template, so it is reused rather than consumed`,
                            `copy its text into a new draft, or have the owner un-mark it in the browser`);
      if (card && !/^[a-f0-9]{12}$/.test(card)) die(`--card must be a 12-hex card id, got ${card}`, `kanban.sh show <card-id>`);
      let cardSlug: string | undefined;
      if (card) {
        cardSlug = Object.keys(registry().boards).find((s) => {
          try { return loadBoard(path.join(KROOT, "boards", s)).cards.some((c) => c.id === card); } catch { return false; }
        });
        if (!cardSlug) die(`card ${card} is not on any board`, `kanban.sh add "<title>" then pull with the printed id`);
      }
      const file = loadPulls();
      const prior = file.pulls[id];
      // The body is snapshotted so a later revision can be handed back as a diff.
      // Capped: a pull record is a receipt, and a pasted novel should not double
      // the store. Over the cap the diff is simply unavailable, which the reader
      // is told, rather than half a diff that looks whole.
      const PULL_SNAP = 120_000;
      const snap = d.body.length <= PULL_SNAP ? d.body : undefined;
      file.pulls[id] = { at: new Date().toISOString(),
        ...(card ? { cardId: card } : {}), ...(cardSlug ? { slug: cardSlug } : {}),
        ...(note ? { note } : {}), ...(sessionId() ? { by: sessionId() } : {}),
        ...(snap !== undefined ? { text: snap } : {}) };
      atomicWrite(PULLS, file, "pull", `pulls=${Object.keys(file.pulls).length}`);
      if (hasFlag("json")) console.log(JSON.stringify({ id, card: card ?? null, slug: cardSlug ?? null, repulled: !!prior }));
      else console.log(`${prior ? "re-pulled" : "pulled"} ${id}${card ? ` → card ${card}` : ""}`);
    });
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
    // Goal and tags live in plan.json, not on the card row, so an agent reading
    // the card object alone never saw them (vb-fable, 2026-08-22).
    const plan = loadPlan(boardDir);
    const goal = plan.goals[id] ?? null;
    const tags = tagsOn(plan, id).map((t) => ({ id: t.id, kind: t.kind, name: t.name }));
    const after = plan.seq?.[id] ?? [];
    if (hasFlag("json")) {
      console.log(JSON.stringify({ slug, root, card: { ...card, goal, tags, after }, note, override: board.overrides[id] ?? null }, null, 2));
      break;
    }
    console.log(`${card.id} · ${card.lane}${card.tag ? ` · ${card.tag}` : ""}${card.heading ? ` · ${card.heading}` : ""}`);
    console.log(card.title);
    if (goal) console.log(`goal: ${goal}`);
    if (tags.length) console.log(`tags: ${tags.map((t) => `${t.kind}:${t.name}`).join(" · ")}`);
    if (after.length) console.log(`after: ${after.join(" ")}`);
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
    // Tags and goal live in plan.json, which the server owns. Forget them there
    // so the store does not keep rows for a card that no longer exists.
    const plan = loadPlan(boardDir);
    if (plan.on[id]?.length || plan.goals[id]) {
      const port = serverPort();
      const res = port ? await fetch(`http://localhost:${port}/api/tag`, {
        method: "POST", headers: { "content-type": "application/json" },
        body: JSON.stringify({ slug, op: "forget", cardId: id }),
      }).catch(() => null) : null;
      if (res?.ok) console.error(`tags and goal forgotten (via server)`);
      else console.error(`tags and goal NOT removed from plan.json (server ${port ? "unreachable" : "not configured"}); they are never served, but re-run with the server up to clear them`);
    }
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
  sync [--project dir]     re-harvest; prints the delta digest. Refuses to empty
                           a populated board when the harvest finds nothing —
                           [--force] if that is genuinely right
  add "<title>" [--lane l] manual card (model-driven lifecycle, D4a); pass
                           [--brief "…"] whenever the title runs long
  after <id> <id…>         execution order: this card comes after those (bare reads; --clear)
  brief <id> "<text>"      the ${BRIEF_MAX}-char summary phrase the board face shows in
                           place of a long title — a name the human can scan and
                           recognise, not a description. The full title stays as
                           the card's description in the drawer. [--clear] drops it
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
  items [--all] [--global] the owner's own asks, unsorted first. They write these
                           from the board or the hub and never classify them;
                           sorting is your job. --all also shows sorted ones.
  classify <item-id> <shape> record what you did with an ask: task (minted a
                           card) · subtask · clarification · remark;
                           [--card <id>] links where it landed, [--note "…"]
                           says what you did, [--undo] retracts it
  to <id> <target>...      who a draft is for: agent:<alias> or board:<slug>, several
                           allowed. Absent means anyone, which is every draft's
                           default. An agent-addressed draft is invisible to every
                           other agent, so this is how the owner writes to one of
                           you rather than to whoever is standing here. [--clear]
  drafts [<draft-id>]      the owner's documents, the rung above an ask. Bare:
                           the pending ones. With an id: that draft in full,
                           which is what you read before pulling. [--all] adds
                           consumed ones, [--templates] lists reusables instead
  pull <draft-id>          consume a draft, recording what you made of it:
                           [--card <id>] links the card, [--note "…"] says what
                           you did, [--undo] retracts it. Templates are reused
                           rather than consumed, so they refuse a pull
  tag [<id> <kind>:<name>]  bare: the board's tag vocabulary and its card counts.
                           With a card: apply a tag, or drop it with a leading
                           "-" (kanban.sh tag ab12 -milestone:M2). Kinds:
                           ${TAG_PRESETS.map((t) => t.kind).join(" ")}. A milestone is
                           a tag several cards share, so "what is left for M2"
                           is a filter, not a rollup
  goal <id> "<why>"        one line saying why the card exists; bare reads it,
                           [--clear] drops it
  selected [--json]        what the owner has ticked on this board — cards and
                           notes they are pointing at right now, in full. They
                           may also have pushed it at you directly with the
                           board's "Send to agent" button
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
