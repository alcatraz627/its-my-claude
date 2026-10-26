// The one composer and parser for decision-page answer strings, plus whether
// each pending page can still reach the session that asked. The kanban server,
// the decision-page command and bfb (through that command) all use this, so an
// answer means the same thing wherever it was written.
//
// The format is held byte for byte to what the old page produced; the golden
// fixture beside this file (golden/) is the contract.

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { seenAgoByAlias, reachOf } from "../kanban/ipc-reach.ts";

export const DP_ROOT = path.join(os.homedir(), ".claude", "assets", "decision-pages");

export type Cfg = {
  title?: string; copyHeader?: string; notes?: boolean;
  decisions?: { id: string; note?: string; none?: boolean; noneCode?: string; options?: { code: string; rec?: boolean }[] }[];
  sections?: { id: string; note?: string }[];
  origin?: { session?: string };
};
export type State = {
  d: Record<string, string>; dnotes: Record<string, string>;
  screens: Record<string, { agree: boolean; note: string }>; endnotes: string;
};

const codesOf = (d: NonNullable<Cfg["decisions"]>[number]) =>
  [...(d.options || []).map((o) => o.code), ...(d.none ? [d.noneCode || "z"] : [])];
const recOf = (d: NonNullable<Cfg["decisions"]>[number]) => (d.options || []).find((o) => o.rec)?.code;

// What the page shows before the owner touches it: every recommendation picked,
// every seeded note in its box, every card agreed.
export function freshState(cfg: Cfg): State {
  const notes = cfg.notes !== false;
  const st: State = { d: {}, dnotes: {}, screens: {}, endnotes: "" };
  for (const d of cfg.decisions || []) {
    const r = recOf(d); if (r) st.d[d.id] = r;
    if (notes && d.note) st.dnotes[d.id] = d.note;
  }
  for (const s of cfg.sections || []) st.screens[s.id] = { agree: true, note: notes ? s.note || "" : "" };
  return st;
}

// Turn the owner's picks into the answer string. A missing state means the
// page as first drawn. Picks the config does not offer fall back to the
// recommendation, notes are trimmed, and notes are ignored on a notes:false
// page, because that is what the page itself would have read.
export function compose(cfg: Cfg, state: Partial<State> | null): string {
  const notes = cfg.notes !== false;
  const base = freshState(cfg);
  const s: State = {
    d: { ...base.d }, dnotes: { ...base.dnotes }, screens: { ...base.screens },
    endnotes: notes ? (state?.endnotes ?? "").trim() : "",
  };
  for (const d of cfg.decisions || []) {
    const v = state?.d?.[d.id];
    if (v && codesOf(d).includes(v)) s.d[d.id] = v;
    if (notes && state?.dnotes && d.id in state.dnotes) s.dnotes[d.id] = (state.dnotes[d.id] || "").trim();
    if (!s.dnotes[d.id]) delete s.dnotes[d.id];
  }
  for (const sec of cfg.sections || []) {
    const v = state?.screens?.[sec.id];
    if (v) s.screens[sec.id] = { agree: v.agree !== false, note: notes ? (v.note || "").trim() : "" };
  }
  const decisions = cfg.decisions || [];
  const lines = [(cfg.copyHeader || cfg.title || "answers") + ":"];
  if (decisions.length) lines.push(decisions.map((d) => d.id + (s.d[d.id] || recOf(d) || "?")).join(" "));
  for (const d of decisions) if (s.dnotes[d.id]) lines.push(`${d.id} note — ${s.dnotes[d.id]}`);
  let flagged = decisions.some((d) => s.d[d.id] !== recOf(d) || !!s.dnotes[d.id]);
  for (const sec of cfg.sections || []) {
    const v = s.screens[sec.id];
    if (!v.agree || v.note) {
      lines.push(`${sec.id}: ${v.agree ? "agree" : "DISAGREE"}${v.note ? " — " + v.note : ""}`);
      flagged = true;
    }
  }
  if (s.endnotes) { lines.push("notes:", s.endnotes); flagged = true; }
  if (!flagged) lines.push("all items: agree as drafted");
  return lines.join("\n");
}

// The inverse of compose: the picks and notes behind a stored answer. Lenient
// on purpose. An answer posted without the header line (some agents posted bare
// "D1a D2a") still parses, and multi-line notes continue until the next line
// that starts a known item.
export function parse(answer: string, cfg: Cfg): State {
  const decisions = cfg.decisions || [], sections = cfg.sections || [];
  const st: State = { d: {}, dnotes: {}, screens: {}, endnotes: "" };
  for (const d of decisions) st.dnotes[d.id] = "";
  for (const s of sections) st.screens[s.id] = { agree: true, note: "" };
  const lines = answer.replace(/\s+$/, "").split("\n");
  const isCodes = (ln: string) => decisions.length > 0 &&
    ln.split(" ").length === decisions.length && decisions.every((d, k) => ln.split(" ")[k]?.startsWith(d.id));
  // The header is the only line that ends in a colon other than "notes:".
  let i = lines[0]?.endsWith(":") && lines[0] !== "notes:" ? 1 : 0;
  if (decisions.length && isCodes(lines[i] || "")) {
    const toks = lines[i].split(" ");
    decisions.forEach((d, k) => { st.d[d.id] = toks[k].slice(d.id.length); });
    i++;
  }
  const secIds = sections.map((s) => s.id).sort((a, b) => b.length - a.length);
  let cur: ((more: string) => void) | null = null;
  for (; i < lines.length; i++) {
    const ln = lines[i];
    if (ln === "notes:") { st.endnotes = lines.slice(i + 1).join("\n"); break; }
    if (ln === "all items: agree as drafted") { cur = null; continue; }
    const dn = decisions.find((d) => ln.startsWith(`${d.id} note — `));
    if (dn) {
      st.dnotes[dn.id] = ln.slice(`${dn.id} note — `.length);
      cur = (m) => { st.dnotes[dn.id] += "\n" + m; };
      continue;
    }
    const sid = secIds.find((id) => ln.startsWith(`${id}: agree`) || ln.startsWith(`${id}: DISAGREE`));
    if (sid) {
      const rest = ln.slice(sid.length + 2);
      const agree = rest.startsWith("agree");
      const after = rest.slice(agree ? 5 : 8);
      st.screens[sid] = { agree, note: after.startsWith(" — ") ? after.slice(3) : "" };
      cur = (m) => { st.screens[sid].note += "\n" + m; };
      continue;
    }
    if (cur) cur(ln);
  }
  return st;
}

// For every page awaiting an answer: can the answer still reach the session
// that asked? One call for the whole list, because the lens refreshes it whole.
export function reachAll(root = DP_ROOT): Record<string, "hot" | "cold" | "absent" | "unknown"> {
  let pending: string[] = [];
  try {
    pending = fs.readFileSync(path.join(root, ".pending.txt"), "utf8").split("\n").map((x) => x.trim()).filter(Boolean);
  } catch { return {}; }
  const seen = seenAgoByAlias();
  const out: Record<string, any> = {};
  for (const slug of pending) {
    let session: string | undefined;
    try { session = JSON.parse(fs.readFileSync(path.join(root, slug, "config.json"), "utf8"))?.origin?.session; } catch {}
    out[slug] = reachOf(session, seen).state;
  }
  return out;
}

export function configOf(slug: string, root = DP_ROOT): Cfg | null {
  if (!/^[a-z0-9][a-z0-9._-]*$/.test(slug)) return null;
  try { return JSON.parse(fs.readFileSync(path.join(root, slug, "config.json"), "utf8")); } catch { return null; }
}
