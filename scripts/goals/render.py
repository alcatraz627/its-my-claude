#!/usr/bin/env python3
"""The ruled render vocabulary for every /tasks view, over goal records.

Ported from task-table.sh (2026-09-05 to 09-18) without its store resolution:
the goal box (title as plain text, curved corners, a rail), the milestone band,
two lines per row with one trait per column, the nine states as ball and ASCII
twin, CLEAR NOW capped at three, and the 44-line height law that truncates
loudly. Rulings: skills/tasks/REDESIGN.md D1-D7, Q1a, D2b, D3a, D3b.
"""
import collections, hashlib, os, re, shutil, sys, time, unicodedata
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import goalstore as G

HEIGHT = 44
BOX_W = max(92, min(160, shutil.get_terminal_size(fallback=(92, 44)).columns - 2))
BALL_COL, ID_COL, MS_COL = 6, 11, 4

# Display width: emoji are two columns, box glyphs one, selectors zero.
VS16, VS15, ZWJ = "️", "︎", "‍"


def _base_w(ch):
    if unicodedata.east_asian_width(ch) in ("W", "F"): return 2
    if 0x1F300 <= ord(ch) <= 0x1FAFF: return 2
    return 1


def dwidth(s):
    n, i, L = 0, 0, len(s)
    while i < L:
        ch = s[i]
        if ch in (VS16, VS15) or unicodedata.category(ch) in ("Mn", "Me", "Cf"):
            i += 1; continue
        wch = _base_w(ch)
        if i + 1 < L and s[i + 1] == VS16: wch = 2
        elif i + 1 < L and s[i + 1] == VS15: wch = 1
        n += wch; i += 1
        while i < L:
            c = s[i]
            if c in (VS16, VS15) or unicodedata.category(c) in ("Mn", "Me"): i += 1; continue
            if 0x1F3FB <= ord(c) <= 0x1F3FF: i += 1; continue
            if c == ZWJ: i += 2 if i + 1 < L else 1; continue
            break
    return n


def dljust(s, wd): return s + " " * max(0, wd - dwidth(s))


def ellip(s, wd):
    """Trim to width at a word, never from the middle, marking that text continues."""
    if wd <= 1: return ""
    if dwidth(s) <= wd: return s
    cut, acc = "", 0
    for ch in s:
        cw = dwidth(ch)
        if acc + cw > wd - 1: break
        cut += ch; acc += cw
    sp = cut.rfind(" ")
    return (cut[:sp] if sp > wd // 2 else cut) + "…"


def wrap(text, width):
    words, lines, cur = text.split(), [], ""
    for wd in words:
        if cur and dwidth(cur) + 1 + dwidth(wd) > width: lines.append(cur); cur = wd
        else: cur = (cur + " " + wd) if cur else wd
    if cur: lines.append(cur)
    return lines or [""]


def age(iso):
    try: t = time.mktime(time.strptime(iso, "%Y-%m-%dT%H:%M:%SZ")) - time.timezone
    except Exception: return ""
    m = (time.time() - t) / 60
    return f"{int(m)}m" if m < 60 else (f"{m/60:.0f}h" if m < 48 * 60 else f"{m/1440:.0f}d")


# The nine states: ball carries urgency in colour, twin the same fact in shape.
BALL = {"owner-gate": "\U0001F534", "blocked": "\U0001F7E0", "active": "\U0001F535",
        "ready": "\U0001F7E2", "review": "\U0001F7E3", "unassigned": "⚪",
        "delegated": "\U0001F91D", "deferred": "\U0001F4A4", "done": "✅"}
TWIN = {"owner-gate": "!", "blocked": "~", "active": "▶", "ready": "○", "review": "=",
        "unassigned": "·", "delegated": "@", "deferred": "\U0001F5D1\uFE0F", "done": "x"}
LEGEND_NAME = {"owner-gate": "needs you", "blocked": "after a task", "active": "running",
               "ready": "ready", "review": "in review", "unassigned": "unassigned",
               "delegated": "delegated", "deferred": "deferred", "done": "done"}
LEGEND_ORDER = ["owner-gate", "blocked", "active", "ready", "review", "unassigned", "delegated", "deferred", "done"]
# The ball answers "can this goal continue without the owner": a gate anywhere says no;
# otherwise ready beats running, because work waiting to be taken is more continuable.
BALL_RANK = ["owner-gate", "ready", "active", "review", "blocked", "unassigned", "delegated", "deferred", "done"]
TRAIT_MARK = ["◆", "◇", "▪", "▫"]
TRAIT_KEYS = ["lane", "tier", "kind", "domain"]

DOMAIN_EMOJI = {
    "tasks": "⚙️", "goals": "\U0001F3AF", "hooks": "\U0001FA9D", "ui": "\U0001F3A8", "ops": "\U0001F527",
    "docs": "\U0001F4C4", "rules": "\U0001F4D0", "skills": "\U0001F9E9", "forge": "\U0001F3ED",
    "foundry": "\U0001F52C", "runner": "\U0001F3C3", "walmart": "\U0001F6D2", "kit": "\U0001F9F0",
    "build": "\U0001F528", "contract": "\U0001F4DC", "architecture": "\U0001F9F1", "auth": "\U0001F511",
    "console": "\U0001F4BB", "tests": "\U0001F9EA", "memory": "\U0001F9E0", "kanban": "\U0001F4CB",
    "ipc": "\U0001F4E1", "plan": "\U0001F9ED", "synth": "\U0001F9EC", "gcc": "\U0001F9E9",
}
FALLBACK_EMOJI = ["\U0001F300", "\U0001F537", "\U0001F536", "\U0001F7E3", "\U0001F7E4",
                  "\U0001F9FF", "\U0001FA90", "\U0001F340", "\U0001F53A", "\U0001F9CA"]


def goal_emoji(rec):
    """Stable for the life of the goal: majority domain over EVERY row, else a hash of the id."""
    doms = [str(t.get("domain") or "").lower() for t in rec["tasks"] if t.get("domain")]
    if doms:
        top, n = collections.Counter(doms).most_common(1)[0]
        if top in DOMAIN_EMOJI and n * 2 >= len(doms): return DOMAIN_EMOJI[top]
    h = int(hashlib.sha1(rec["id"].encode()).hexdigest()[:8], 16)
    return FALLBACK_EMOJI[h % len(FALLBACK_EMOJI)]


def goal_ball(rec, states):
    have = set(states.values())
    for s in BALL_RANK:
        if s in have: return BALL[s]
    return BALL["unassigned"]


def meter(closed, total):
    if not total: return "▱" * 10
    filled = 10 if closed >= total else int(closed * 10 / total)
    return "▰" * filled + "▱" * (10 - filled)


def states_of(rec):
    return {t["id"]: G.effective_state(t, rec) for t in rec["tasks"]}


def milestones_closed(rec, states):
    """Met by status, or every row under it done: the same count in the header and the box."""
    n = 0
    for m in rec["milestones"]:
        rows = [t for t in rec["tasks"] if t["milestone"] == m["id"]]
        if m["status"] == "met" or (rows and all(states[t["id"]] == "done" for t in rows)):
            n += 1
    return n


def open_rows(rec, states):
    return [t for t in rec["tasks"] if states[t["id"]] != "done"]


def gates_of(rec, states):
    return [t for t in rec["tasks"] if states[t["id"]] == "owner-gate"]


def trait_values(t):
    seen, vals = set(), []
    for k in TRAIT_KEYS:
        v = str(t.get(k) or "").strip()
        if v.casefold() in seen: v = ""
        if v: seen.add(v.casefold())
        vals.append(v)
    return vals


def trait_widths(rows):
    ws = []
    for i in range(len(TRAIT_MARK)):
        w = 4
        for t in rows:
            v = trait_values(t)[i]
            if v: w = max(w, min(24, dwidth(v)))
        ws.append(w + 3)
    return ws


class Out:
    """Lines under the height law. Reserve the footer, then fit or refuse loudly."""

    def __init__(self, detail=False):
        self.lines, self.detail, self.hidden, self.footer = [], detail, [], 0

    def w(self, s=""): self.lines.append(s)

    def cap(self): return HEIGHT - self.footer

    def fits(self, n): return self.detail or len(self.lines) + n <= self.cap()


def row_lines(t, state, idw, traitws, gid_tag=""):
    """The row: ball twin #id subject, then one trait line with the note riding it when it fits."""
    b, tw = BALL[state], TWIN[state]
    title_w = BOX_W - (ID_COL + idw + 1) + 1
    head = "│" + " " * (BALL_COL - 2) + b + " " + tw + " " + dljust(f"#{t['id']}{gid_tag}", idw) + " " + ellip(t["subject"], title_w)
    note = t.get("note") or ""
    if t.get("gate"): note = t["gate"]["text"] + "  ▸ " + t["gate"]["do"]
    elif state == "blocked": note = "after #" + " #".join(t.get("blocked_by", []))
    if state == "delegated": note = f"delegated to {t.get('delegated_to')}" + (" · " + note if note else "")
    vals = trait_values(t)
    has_traits = any(vals)
    lines = [head]
    if has_traits:
        cells = "".join(dljust(mk + " " + ellip(v or "—", cw - 3), cw) for mk, v, cw in zip(TRAIT_MARK, vals, traitws)).rstrip()
        room = BOX_W - ID_COL + 1 - sum(traitws) - 2
        if note and room >= 28 and dwidth("» " + note) <= room:
            lines.append("│" + " " * (ID_COL - 2) + dljust(cells, sum(traitws)) + "  » " + note); note = ""
        else:
            lines.append("│" + " " * (ID_COL - 2) + cells)
    if note:
        lines.append("│" + " " * (ID_COL - 2) + ellip("» " + note, BOX_W - ID_COL + 1))
    return lines


def _title_lines(s):
    """A title whole on one line when it fits; wrapped at words only when it does not."""
    return [s] if dwidth(s) <= BOX_W else wrap(s, BOX_W)


def goal_box(out, rec, states, idw, traitws, only_open=True, tag="", title=True):
    """One goal as a closed box, or a title plus one railless row when it has one row (D3a).
    `tag` qualifies ids only where they leave the box (the hidden list); inside it #N is enough."""
    rows = [t for t in rec["tasks"] if (states[t["id"]] != "done" or not only_open)]
    if not rows and only_open:
        rows = []
    ball = goal_ball(rec, {t["id"]: states[t["id"]] for t in rows} if rows else {})
    em = goal_emoji(rec)
    ms_total = len(rec["milestones"]); ms_closed = milestones_closed(rec, states)
    nxt = next((m for m in rec["milestones"] if m["status"] == "open" and any(t["milestone"] == m["id"] and states[t["id"]] != "done" for t in rec["tasks"])), None)
    acc_p = sum(1 for a in rec["accept"] if a["status"] == "proven"); acc_t = len(rec["accept"])
    title_s = f"{ball} · {em}  {rec['outcome']}"
    ag = age(rec["updated"])
    if rec.get("direction"):
        out.w(ellip("\U0001F9ED " + rec["direction"], BOX_W))
    if len(rows) <= 1:
        if title:
            for ln in _title_lines(title_s + f"  ·  {ag}"): out.w(ln)
        out.w(f"     {meter(ms_closed, ms_total)}  {ms_closed} of {ms_total} milestone{'s' if ms_total != 1 else ''}   ·   ✅ {acc_p} of {acc_t} accepted" + (f"   ·   next: {ellip(nxt['name'], 40)}" if nxt else ""))
        for t in rows:
            for ln in row_lines(t, states[t["id"]], idw, traitws):
                out.w("    " + ln[1:])
        return
    need = 4 + 1
    if not out.fits(need + len(row_lines(rows[0], states[rows[0]["id"]], idw, traitws))):
        out.hidden.extend(f"#{t['id']}{tag}" for t in rows)
        out.w(ellip(f"{ball} · {em}  {rec['outcome']}   ·   {len(rows)} rows not on screen, --detail or /tasks left {rec['id'][:6]}", BOX_W))
        return
    if title:
        for ln in _title_lines(title_s): out.w(ln)
    out.w("╭▏" + "─" * (BOX_W - MS_COL + 1) + f"  ·  {ag}")
    out.w(f"│  {meter(ms_closed, ms_total)}  {ms_closed} of {ms_total} milestone{'s' if ms_total != 1 else ''}   ·   ✅ {acc_p} of {acc_t} accepted" + (f"   ·   next: {ellip(nxt['name'], 40)}" if nxt else ""))
    unproven = [a for a in rec["accept"] if a["status"] != "proven"]
    if unproven and not open_rows(rec, states):
        out.w("│  built, not accepted: " + ellip("; ".join(f"{a['kind']}: {a['text']}" for a in unproven), BOX_W - 24))
    out.w("│")
    drawn_any = False
    for m in sorted(rec["milestones"], key=lambda m: m.get("order", 0)):
        mrows = [t for t in rows if t["milestone"] == m["id"]]
        if not mrows: continue
        mrows = sorted(mrows, key=lambda t: (states[t["id"]] != "owner-gate", int(t["id"])))
        first = row_lines(mrows[0], states[mrows[0]["id"]], idw, traitws)
        if not out.fits(2 + len(first) + 1):
            out.hidden.extend(f"#{t['id']}{tag}" for t in mrows); continue
        if drawn_any: out.w("│")
        out.w("│  ▸ " + ellip(m["name"], BOX_W - 6) + ("  ⚠ name too thin" if len(re.sub(r"[^A-Za-z]", "", m["name"])) < 3 else ""))
        out.w("│    " + "─" * min(len(m["name"]), 40))
        drawn_any = True
        for t in mrows:
            ls = row_lines(t, states[t["id"]], idw, traitws)
            if not out.fits(len(ls) + 1):
                out.hidden.append(f"#{t['id']}{tag}"); continue
            for ln in ls: out.w(ln)
    out.w("╰▏")


def legend(out, states_used, traitws_used=True, extra=""):
    present = [s for s in LEGEND_ORDER if s in states_used]
    if present:
        out.w("  " + "   ".join(f"{BALL[s]} {LEGEND_NAME[s]} ({TWIN[s]})" for s in present))
    out.w("  " + "─" * (BOX_W - 4))
    parts = (["◆ lane   ◇ tier   ▪ kind   ▫ domain   »  note, gate or wait"] if traitws_used else [])
    parts.append(f"height {len(out.lines) + 1}/{HEIGHT}")
    if extra: parts.append(extra)
    parts.append("-h for flags")
    out.w("  " + "   ·   ".join(parts))


def hidden_line(out):
    if out.hidden:
        ids = " ".join(out.hidden[:26]) + (" …" if len(out.hidden) > 26 else "")
        out.w(f"  ⚠ {len(out.hidden)} row(s) not on screen: {ids}   ·   --detail shows all")


def scope_line(goals, sid, cwd, project, all_flag):
    if all_flag: return f"scope: every goal, {len(goals)} record(s)"
    if project: return f"scope: project {os.path.basename(project.rstrip('/'))}, {len(goals)} goal(s)"
    root = G.repo_root(cwd)
    mine = G.session_goal(sid) if sid else None
    return (f"scope: this session's goal" + (" plus " if len(goals) > 1 else "") if mine else "scope: ") \
        + (f"live goals touching {os.path.basename(root)}" if len(goals) > (1 if mine else 0) or not mine else "") \
        + f"  ·  {len(goals)} goal(s)"


# quiet style: one glyph per row, no rails, no trait markers, one line per row
# when it fits. Built 2026-09-23 after the owner read the first real render:
# "visually spread out, the balls and icons are messy, hard to discern what is what".

def quiet_row(t, state, idw, trait_col, note_ok=True):
    tw = TWIN[state]
    traits = "  ".join(v for v in trait_values(t) if v)
    subj = ellip(t["subject"], max(20, trait_col - idw - 8))
    line = "    " + tw + " " + dljust(f"#{t['id']}", idw) + " " + subj
    if traits:
        line = dljust(line, trait_col) + "  " + ellip(traits, BOX_W - trait_col - 2)
    lines = [line]
    note = t.get("note") or ""
    if t.get("gate"): note = "needs you: " + t["gate"]["do"]
    elif state == "blocked": note = "after #" + " #".join(t.get("blocked_by", []))
    if state == "delegated": note = f"with {t.get('delegated_to')}" + (" · " + note if note else "")
    if note and note_ok:
        lines.append(" " * (idw + 7) + ellip(note, BOX_W - idw - 7))
    return lines


def quiet_goal(out, rec, states, idw, trait_col, only_open=True, tag=""):
    rows = [t for t in rec["tasks"] if states[t["id"]] != "done"] if only_open else list(rec["tasks"])
    # A goal with nothing open is held for acceptance, so it reads as in review, not unassigned.
    ball_state = next((s for s in BALL_RANK if s in {states[t["id"]] for t in rows}), "review" if rec["tasks"] else "unassigned")
    ms_total = len(rec["milestones"]); ms_closed = milestones_closed(rec, states)
    acc_p = sum(1 for a in rec["accept"] if a["status"] == "proven"); acc_t = len(rec["accept"])
    nxt = next((m for m in sorted(rec["milestones"], key=lambda m: m.get("order", 0))
                if any(t["milestone"] == m["id"] and states[t["id"]] != "done" for t in rec["tasks"])), None)
    head = TWIN[ball_state] + " " + ellip(rec["outcome"], BOX_W - 8)
    if not out.fits(2 + (len(quiet_row(rows[0], states[rows[0]["id"]], idw, trait_col)) if rows else 0)):
        out.hidden.extend(f"#{t['id']}{tag}" for t in rows)
        out.w(ellip(head + f"   ({len(rows)} rows not on screen)", BOX_W)); return
    out.w(dljust(head, BOX_W - 5) + " " + age(rec["updated"]))
    meter_line = f"  milestones {ms_closed}/{ms_total} {meter(ms_closed, ms_total)}   accepted {acc_p}/{acc_t}"
    if nxt: meter_line += "   next: " + ellip(nxt["name"].split(":")[0], 24)
    unproven = [a for a in rec["accept"] if a["status"] != "proven"]
    if unproven and not rows: meter_line += "   built, not accepted"
    out.w(meter_line)
    if rec.get("direction"): out.w("  " + ellip(rec["direction"], BOX_W - 2))
    for m in sorted(rec["milestones"], key=lambda m: m.get("order", 0)):
        mrows = sorted([t for t in rows if t["milestone"] == m["id"]], key=lambda t: (states[t["id"]] != "owner-gate", int(t["id"])))
        if not mrows: continue
        first = quiet_row(mrows[0], states[mrows[0]["id"]], idw, trait_col)
        if not out.fits(1 + len(first)):
            out.hidden.extend(f"#{t['id']}{tag}" for t in mrows); continue
        if ms_total > 1 or len(rec["milestones"]) > 1:
            out.w("  ▸ " + ellip(m["name"], BOX_W - 4))
        for t in mrows:
            ls = quiet_row(t, states[t["id"]], idw, trait_col)
            if not out.fits(len(ls)):
                out.hidden.append(f"#{t['id']}{tag}"); continue
            for ln in ls: out.w(ln)


def quiet_legend(out, states_used, extra=""):
    present = [s for s in LEGEND_ORDER if s in states_used]
    parts = [f"{TWIN[s]} {LEGEND_NAME[s]}" for s in present]
    parts.append(f"height {len(out.lines) + 1}/{HEIGHT}")
    if extra: parts.append(extra)
    out.w("  " + "   ".join(parts))


# The card, the default since the owner's two rulings of 2026-09-24: a frame per
# goal, rows in burst / stop / after order, colour only where the agent stops for
# someone, the holder column only when a goal has several holders, the ledger
# table for a goal with many rows, the stage strip for a milestone-heavy goal,
# acceptance at the bottom, "to finish" as a sentence.
STOP_GLYPH = {"you": "\U0001F3D3", "seat": "\U0001F431", "peer": "\U0001F91D", "closure": "\U0001F9F7"}
STOP_WORD = {"you": "you", "seat": "a seat", "peer": "a peer", "closure": "closure pain"}
LEDGER_AT = 6      # a goal with this many open rows draws its rows as a table
STRIP_AT = 3       # a goal with this many milestones holding open rows draws the stage strip


def holder_of(t, rec):
    st = G.stop_of(t, rec)
    if st == "you": return "you"
    if st == "seat": return t.get("delegated_to") or "seat"
    if st == "peer": return "peer"
    return t.get("lane") or "nobody"


def stop_reason(t, rec):
    st = G.stop_of(t, rec)
    if st == "you": return "you: " + t["gate"]["do"]
    if st == "seat": return f"seat: {t.get('delegated_to')}, unconfirmed"
    if st == "peer": return "peer: " + (t.get("note") or "awaiting a review")
    if st == "closure": return "closure pain: " + t["closure"]
    return ""


def _frame_top(project, outcome, ag, width):
    head = f"┌ {project} ── "
    tail = f" ── {ag} ┐"
    room = width - dwidth(head) - dwidth(tail)
    return head + dljust(ellip(outcome, room), room).replace(" " * 2, "  ") + tail


def card(out, rec, states, tag="", share=None):
    W = BOX_W
    inner = W - 3
    def line(s): out.w("│ " + dljust(ellip(s, inner - 1), inner - 1) + " │")
    seg = G.burst_split(rec)
    rows = [t for t in rec["tasks"] if states[t["id"]] != "done"]
    order = {"burst": 0, "stop": 1, "after": 2}
    rows.sort(key=lambda t: (order[seg[t["id"]]], int(t["id"])))
    holders = {holder_of(t, rec) for t in rows}
    multi = len(holders) > 1
    ms_open = [m for m in rec["milestones"] if any(t["milestone"] == m["id"] for t in rows)]
    project = os.path.basename((rec.get("projects") or ["?"])[0].rstrip("/")) or "?"
    if project == ".claude": project = "gcc"
    n_acc = sum(1 for a in rec["accept"] if a["status"] != "proven")
    ms_total = len(rec["milestones"]); ms_closed = milestones_closed(rec, states)
    nxt = next((m for m in sorted(rec["milestones"], key=lambda m: m.get("order", 0)) if m in ms_open), None)
    first_stop = next((t for t in rows if seg[t["id"]] == "stop"), None)
    # The chrome is priced first; the rows take what is left, and the rest are named
    # inside the card rather than the whole goal vanishing (the old F5 defect).
    chrome = 3 + (1 if ms_total or len(ms_open) >= STRIP_AT else 0) + len(rec["accept"]) + (1 if G.unconsumed_notes(rec) else 0)
    chrome += 1 + (1 if len(rows) >= LEDGER_AT else 0)   # the held-rows line, and the ledger header
    if not out.detail and not out.fits(chrome + 1):
        out.hidden.extend(f"#{t['id']}{tag}" for t in rows)
        out.w(ellip(f"┌ {project} ── {rec['outcome']}   ({len(rows)} rows not on screen)", W)); return
    budget = 10**6 if out.detail else out.cap() - len(out.lines) - chrome - 1
    if share is not None and not out.detail: budget = min(budget, share)
    shown = []
    used = 0
    for t in rows:
        cost = 1 if len(rows) >= LEDGER_AT else (2 if (G.stop_of(t, rec) or states[t["id"]] == "blocked" or t.get("note")) else 1)
        if used + cost > budget: break
        shown.append(t); used += cost
    held = rows[len(shown):]
    out.hidden.extend(f"#{t['id']}{tag}" for t in held)
    rows_all, rows = rows, shown
    out.w(_frame_top(project, rec["outcome"], age(rec["updated"]), W))
    fin = f"to finish: {len(rows_all)} row{'s' if len(rows_all) != 1 else ''}, {ms_total - ms_closed} milestone{'s' if ms_total - ms_closed != 1 else ''}, {n_acc} acceptance row{'s' if n_acc != 1 else ''}"
    if first_stop: fin += f" · first stop: {STOP_WORD[G.stop_of(first_stop, rec)]} at #{first_stop['id']}"
    elif rows: fin += " · no stop: the agent can run to the end"
    if nxt: fin += " · next " + milestone_label(nxt, 28)
    line(fin)
    if len(ms_open) >= STRIP_AT:
        strip = "  ".join(f"[ {milestone_label(m, 16)} {min((STOP_GLYPH.get(G.stop_of(t, rec)) or TWIN[states[t['id']]] for t in rows if t['milestone'] == m['id']), key=lambda g: 0 if g in STOP_GLYPH.values() else 1)} ]" for m in ms_open)
        line(strip)
    if rows and len(rows_all) >= LEDGER_AT:
        idw = max(len(t["id"]) + 1 for t in rows)
        hw = max((dwidth(holder_of(t, rec)) for t in rows), default=6) if multi else 0
        line("  st  " + dljust("id", idw) + ("  " + dljust("holder", hw) if multi else "") + "  subject" + " " * 34 + "  waits on")
        for t in rows:
            st = G.stop_of(t, rec)
            g = STOP_GLYPH[st] if st else TWIN[states[t["id"]]]
            wait = stop_reason(t, rec) if st else ("after #" + " #".join(t["blocked_by"]) if states[t["id"]] == "blocked" else "")
            line("  " + dljust(g, 3) + " " + dljust("#" + t["id"], idw) + ("  " + dljust(holder_of(t, rec), hw) if multi else "") + "  " + dljust(ellip(t["subject"], 40), 40) + "  " + wait)
    else:
        cur = None
        idw = max((len(t["id"]) + 1 for t in rows), default=2)
        hw = max((dwidth(holder_of(t, rec)) for t in rows), default=0) if multi else 0
        for t in rows:
            s = seg[t["id"]]
            label = dljust(s if s != cur else "", 6); cur = s
            st = G.stop_of(t, rec)
            g = STOP_GLYPH[st] if st else TWIN[states[t["id"]]]
            traits = "  ".join(v for v in (t.get("lane") if not multi else None, t.get("tier"), t.get("kind"), t.get("domain")) if v)
            head = label + (dljust(holder_of(t, rec), hw) + " " if multi else "") + dljust(g, 2) + " " + dljust("#" + t["id"], idw) + " "
            reason = stop_reason(t, rec) if st else ("after #" + " #".join(t["blocked_by"]) if states[t["id"]] == "blocked" else (t.get("note") or ""))
            room = inner - 1 - dwidth(head) - (dwidth(traits) + 2 if traits else 0)
            subj = t["subject"]
            if dwidth(subj) <= room and (not reason or dwidth(subj) + 4 + dwidth(reason) <= room):
                body = subj + (f"  → {reason}" if reason else "")
                line(head + dljust(body, room) + ("  " + traits if traits else ""))
            else:
                line(head + dljust(ellip(subj, room), room) + ("  " + traits if traits else ""))
                if reason: line(" " * dwidth(head) + "↳ " + reason)
    if held:
        line(f"… +{len(held)} row{'s' if len(held) != 1 else ''} not on screen · /tasks left {rec['id'][:6]} or --detail")
    if not rows_all and rec["status"] == "live" and n_acc:
        line("stop  " + STOP_GLYPH["you"] + " accept  prove the rows below, or say what still misses")
    if rec["accept"]:
        for a in rec["accept"]:
            mark = "✓" if a["status"] == "proven" else "◻"
            text_w = inner - 14
            ev = ""
            if a.get("evidence"):
                # the text is what the owner checks; the evidence is clipped first
                text_w = max(30, min(dwidth(a["text"]), (inner - 14) * 3 // 5))
                ev = " · by " + ellip(a["evidence"], inner - 14 - text_w - 6)
            line(f"{mark} {a['kind']:<10} " + dljust(ellip(a["text"], text_w), text_w if ev else 0) + ev)
    un = G.unconsumed_notes(rec)
    if un: line(f"\U0001F4DD {len(un)} unread note{'s' if len(un) != 1 else ''} · gs notes {rec['id'][:6]}")
    out.w("└" + "─" * (W - 2) + "┘")


def card_legend(out, stops_used, extra=""):
    parts = [f"{STOP_GLYPH[s]} {STOP_WORD[s]}" for s in ("you", "seat", "closure") if s in stops_used]
    if "peer" in stops_used and "seat" not in stops_used: parts.append(f"{STOP_GLYPH['peer']} a peer")
    parts += ["▶ running", "○ ready", "🗑️ deferred"]
    parts.append(f"height {len(out.lines) + 1}/{HEIGHT}")
    if extra: parts.append(extra)
    out.w("  " + "   ".join(parts))


# A milestone wears an emoji (owner, 2026-09-24: "add before DEC / PARTS a proper
# emoji"). Set one with `gs milestone … --emoji`, else the first keyword hit, else a
# stable pick from a neutral set by the milestone's order.
MS_EMOJI = [
    ("decision", "\U0001F4CB"), ("dec", "\U0001F4CB"), ("rule", "\U0001F4CB"),
    ("part", "\U0001F9E9"), ("table", "\U0001F9E9"), ("export", "\U0001F4E4"), ("import", "\U0001F4E5"),
    ("store", "\U0001F5C4️"), ("record", "\U0001F5C4️"), ("view", "\U0001F441️"), ("render", "\U0001F441️"),
    ("surface", "\U0001F5A5️"), ("skill", "\U0001F5A5️"), ("hook", "\U0001FA9D"), ("deploy", "\U0001F680"),
    ("release", "\U0001F680"), ("ship", "\U0001F680"), ("test", "\U0001F9EA"), ("suite", "\U0001F9EA"), ("green", "\U0001F9EA"),
    ("auth", "\U0001F511"), ("login", "\U0001F511"), ("ui", "\U0001F3A8"), ("page", "\U0001F3A8"), ("design", "\U0001F3A8"),
    ("doc", "\U0001F4C4"), ("write", "\U0001F4DD"), ("review", "\U0001F50D"), ("audit", "\U0001F50D"), ("data", "\U0001F4CA"),
    ("metric", "\U0001F4CA"), ("job", "\U0001F3C3"), ("quota", "\U0001F6A6"), ("limit", "\U0001F6A6"), ("pause", "\U0001F6A6"),
    ("tab", "\U0001F516"), ("board", "\U0001F4CC"), ("feed", "\U0001F4E1"), ("socket", "\U0001F4E1"), ("cache", "\U0001F9CA"),
]
MS_FALLBACK = ["\U0001F537", "\U0001F536", "\U0001F7E9", "\U0001F7E7", "\U0001F7EA", "\U0001F7E6", "\U0001F7E8", "\U0001F7EB"]


def milestone_emoji(m):
    """The acronym head (before the colon) decides first; the rest of the name only when the head says nothing."""
    if m.get("emoji"): return m["emoji"]
    head, _, rest = m["name"].lower().partition(":")
    for part in (head, rest):
        for key, em in MS_EMOJI:
            if re.search(r"\b" + key, part): return em
    return MS_FALLBACK[(m.get("order", 1) - 1) % len(MS_FALLBACK)]


def milestone_label(m, width=40):
    return milestone_emoji(m) + " " + ellip(m["name"].split(":")[0], width)


# State-first card (owner, 2026-09-24: "useful and usable are different"). A goal is
# in one state; the state fixes the sentence the card leads with and the ask it shows.
ACCEPT_ASK = {"reviewed": "read it and say it answers", "visual": "look at it and say it reads",
              "functional": "try it and say it works", "deployed": "see it live and say so", "other": "check it and say so"}


def short_name(outcome, width=52):
    """The goal's name for a title: the first clause, never the whole paragraph."""
    head = re.split(r"[:;,.]| and | so that | while ", outcome, maxsplit=1)[0].strip()
    return ellip(head if len(head) >= 12 else outcome, width)


def goal_state(rec, states):
    rows = open_rows(rec, states)
    unproven = [a for a in rec["accept"] if a["status"] != "proven"]
    d, verdict = G.drift(rec)
    if rec["status"] == "parked": return "parked"
    if verdict in ("drifting", "park-due"): return "drifting"
    if not rec["tasks"] and not rows: return "not started"
    stops = {G.stop_of(t, rec) for t in rows}
    if not rows: return "waiting on you" if unproven else "met"
    if "you" in stops: return "waiting on you"
    if G.burst_split(rec) and any(G.burst_split(rec)[t["id"]] == "burst" for t in rows): return "moving"
    if stops - {None}: return "waiting on others"
    return "moving"


def waited_since(rec, states):
    """When the current wait began: the newest stop row's last write, else the goal's."""
    ts = [t["updated"] for t in open_rows(rec, states) if G.stop_of(t, rec)] or [rec["updated"]]
    return age(max(ts))


def state_card(out, rec, states, share=None):
    W = BOX_W; inner = W - 3
    def line(s): out.w("│ " + dljust(ellip(s, inner - 1), inner - 1) + " │")
    def wrapped(prefix, text):
        for i, ln in enumerate(wrap(text, inner - 1 - dwidth(prefix))):
            line((prefix if i == 0 else " " * dwidth(prefix)) + ln)
    state = goal_state(rec, states)
    rows = open_rows(rec, states)
    seg = G.burst_split(rec)
    unproven = [a for a in rec["accept"] if a["status"] != "proven"]
    proven = [a for a in rec["accept"] if a["status"] == "proven"]
    done = [t for t in rec["tasks"] if states[t["id"]] == "done"]
    project = os.path.basename((rec.get("projects") or ["?"])[0].rstrip("/")) or "?"
    if project == ".claude": project = "gcc"
    name = short_name(rec["outcome"])
    since = waited_since(rec, states)
    # the lead sentence, per state
    if state == "waiting on you":
        asks = [t for t in rows if G.stop_of(t, rec) == "you"]
        rest = [t for t in rows if G.stop_of(t, rec) != "you"]
        if rest:
            lead = f"waiting on you for {since}: {len(asks)} row{'s' if len(asks) != 1 else ''}; {len(rest)} more in flight for others"
        else:
            lead = f"waiting on you for {since}: " + (f"{len(asks)} row{'s' if len(asks) != 1 else ''}" if asks else "") + (" and " if asks and unproven else "") + (f"{len(unproven)} acceptance row{'s' if len(unproven) != 1 else ''} to accept" if unproven else "")
    elif state == "moving":
        burst = [t for t in rows if seg[t["id"]] == "burst"]
        first_stop = next((t for t in rows if seg[t["id"]] == "stop"), None)
        lead = f"moving: {len(burst)} row{'s' if len(burst) != 1 else ''} the agent takes alone" + (f", then stops for {STOP_WORD[G.stop_of(first_stop, rec)]} at #{first_stop['id']}" if first_stop else ", then the goal is built")
    elif state == "waiting on others":
        who = sorted({STOP_WORD[G.stop_of(t, rec)] for t in rows if G.stop_of(t, rec)})
        lead = f"waiting on {', '.join(who)} for {since}; nothing for you"
    elif state == "drifting":
        lead = f"drifting: no write for {int(G.drift(rec)[0])} days · gs revive|park|drop {rec['id'][:6]}"
    elif state == "not started":
        lead = "not started: no rows yet"
    elif state == "met":
        lead = "met: every row done and every acceptance row proven · gs met"
    else:
        lead = state
    head = f"┌ {project} · {name} "
    tail = f" {lead} ┐"
    fill = W - dwidth(head) - dwidth(tail)
    if fill < 2:
        out.w(head + "─" * max(1, W - dwidth(head) - 1) + "┐"); line(lead)
    else:
        out.w(head + "─" * fill + tail)
    budget = 10**6 if out.detail or share is None else share
    used = [0]
    def budgeted(prefix, text):
        n = len(wrap(text, inner - 1 - dwidth(prefix)))
        if used[0] + n > budget: return False
        wrapped(prefix, text); used[0] += n; return True
    # the asks first: what the reader does. Acceptance is asked only once the rows are built.
    asks = [t for t in rows if G.stop_of(t, rec) == "you"]
    others = [t for t in rows if G.stop_of(t, rec) != "you"]
    for t in asks:
        budgeted(f"  🏓 #{t['id']} ", t["subject"] + "  →  you: " + t["gate"]["do"])
    if not others:
        for a in unproven:
            is_callout = (a.get("source") or "").startswith("callout:")
            text = ("callout to retire: " + a["text"].split(": ", 1)[-1]) if is_callout else a["text"]
            budgeted(f"  🏓 {a['id']} ", f"{ACCEPT_ASK.get(a['kind'], 'check it')}: {text}")
    # then the work for everyone else, in burst / stop / after order, held rows counted
    held = 0; cur = None
    for t in sorted(others, key=lambda t: ({"burst": 0, "stop": 1, "after": 2}[seg[t["id"]]], int(t["id"]))):
        st = G.stop_of(t, rec)
        label = dljust(seg[t["id"]] if seg[t["id"]] != cur else "", 6)
        g = STOP_GLYPH[st] if st else TWIN[states[t["id"]]]
        reason = stop_reason(t, rec) if st else ("after #" + " #".join(t["blocked_by"]) if states[t["id"]] == "blocked" else "")
        if held or not budgeted(f"  {label}{g} #{t['id']} ", t["subject"] + (f"  →  {reason}" if reason else "")):
            held += 1; out.hidden.append(f"#{t['id']}")
        else: cur = seg[t["id"]]
    if held: line(f"  … +{held} more row{'s' if held != 1 else ''} · /tasks left {rec['id'][:6]} or --detail")
    if others and unproven: line(f"  then accept: {len(unproven)} row{'s' if len(unproven) != 1 else ''} once the work is built")
    # then what happened, folded to one line, and the proofs, one line each
    if done:
        last = max(done, key=lambda t: t.get("closed") or t["updated"])
        ms_names = [milestone_label(m, 14) for m in rec["milestones"] if m["status"] == "met" or (any(t["milestone"] == m["id"] for t in rec["tasks"]) and all(states[t["id"]] == "done" for t in rec["tasks"] if t["milestone"] == m["id"]))]
        line(f"  built: {len(done)} of {len(rec['tasks'])} rows done" + (f", milestones {' '.join(ms_names)}" if ms_names else "") + f" · last: #{last['id']} {ellip(last['subject'], 30)} ({age(last.get('closed') or last['updated'])})")
    for a in proven:
        line(f"  ✓ {a['kind']} " + ellip(a["text"], max(24, (inner - 14) // 2)) + " · proof: " + (a.get("evidence") or "none"))
    un = G.unconsumed_notes(rec)
    if un: line(f"  📝 {len(un)} unread note{'s' if len(un) != 1 else ''} · gs notes {rec['id'][:6]}")
    out.w("└" + "─" * (W - 2) + "┘")
    return state


def state_header(goals, st):
    counts = collections.Counter(goal_state(g, st[g["id"]]) for g in goals)
    you = counts.get("waiting on you", 0)
    parts = [f"{len(goals)} goal{'s' if len(goals) != 1 else ''}"]
    if you: parts.append(f"{you} waiting on you")
    if counts.get("moving"): parts.append(f"{counts['moving']} moving")
    if counts.get("waiting on others"): parts.append(f"{counts['waiting on others']} waiting on others")
    if counts.get("drifting"): parts.append(f"{counts['drifting']} DRIFTING")
    if counts.get("not started"): parts.append(f"{counts['not started']} not started")
    fire = "nothing burning" if not counts.get("drifting") else "see the drifting goal"
    return "TASKS  " + " · ".join(parts) + "   ·   " + (f"your move on {you}" if you else fire)


# Editorial card, the default since 2026-09-24 night: the owner hit their attention
# limit, so the agent picked seat-editorial V1 and built it. A goal opens with a
# plain sentence naming its state; every mark below is an ask addressed to the
# reader; the agent's own work is one sentence; no row ids (they live on /tasks left).
WORDS = {0: "no", 1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine", 10: "ten"}


def words(n): return WORDS.get(n, str(n))


def plural(n, one, many=None): return f"{words(n)} {one if n == 1 else (many or one + 's')}"


def editorial_header(goals, st):
    counts = collections.Counter(goal_state(g, st[g["id"]]) for g in goals)
    n = len(goals)
    you = counts.get("waiting on you", 0)
    if n == 1:
        s = goal_state(goals[0], st[goals[0]["id"]])
        return {"waiting on you": "One goal, waiting on you.", "met": "One goal, one command from met.",
                "moving": "One goal, moving.", "waiting on others": "One goal, waiting on other people.",
                "drifting": "One goal, drifting."}.get(s, f"One goal, {s}.")
    parts = [f"{plural(n, 'goal').capitalize()}."]
    if you: parts.append(f"{words(you).capitalize()} {'is' if you == 1 else 'are'} waiting on you.")
    if counts.get("moving"): parts.append(f"{words(counts['moving']).capitalize()} moving.")
    if counts.get("waiting on others"): parts.append(f"{words(counts['waiting on others']).capitalize()} waiting on other people.")
    if counts.get("met"): parts.append(f"{words(counts['met']).capitalize()} {'is' if counts['met'] == 1 else 'are'} one command from met.")
    if counts.get("drifting"): parts.append(f"{words(counts['drifting']).capitalize()} drifting.")
    if not you and not counts.get("drifting"): parts.append("Nothing needs you.")
    return " ".join(parts)


def editorial_card(out, rec, states, share=None):
    W = BOX_W; inner = W - 3
    def para(text, indent="", glyph=""):
        first = glyph + (" " if glyph else "")
        lines = wrap(text, inner - 1 - dwidth(indent) - dwidth(first))
        for i, ln in enumerate(lines):
            out.w("│ " + dljust(indent + (first if i == 0 else " " * dwidth(first)) + ln, inner - 1) + " │")
    def blank(): out.w("│ " + " " * (inner - 1) + " │")
    state = goal_state(rec, states)
    rows = open_rows(rec, states)
    seg = G.burst_split(rec)
    unproven = [a for a in rec["accept"] if a["status"] != "proven"]
    proven = [a for a in rec["accept"] if a["status"] == "proven"]
    done = [t for t in rec["tasks"] if states[t["id"]] == "done"]
    project = os.path.basename((rec.get("projects") or ["?"])[0].rstrip("/")) or "?"
    if project == ".claude": project = "gcc"
    asks = [t for t in rows if G.stop_of(t, rec) == "you"]
    stops = [t for t in rows if G.stop_of(t, rec) in ("seat", "peer", "closure")]
    burst = [t for t in rows if seg[t["id"]] == "burst"]
    after = [t for t in rows if seg[t["id"]] == "after" and states[t["id"]] != "deferred"]
    deferred = [t for t in rows if states[t["id"]] == "deferred"]
    name = short_name(rec["outcome"], W - 14 - len(project))
    head = f"┌ {project} · {name} "
    out.w(head + "─" * max(1, W - dwidth(head) - 1) + "┐")
    # the lead
    if state == "waiting on you" and not rows:
        lead = f"Built, not accepted. Every row is done, but {plural(len(unproven), 'acceptance row')} of {words(len(rec['accept']))} {'is a read' if len(unproven) == 1 else 'are reads'} only you can make, so the goal sits where it is until you look."
    elif state == "waiting on you":
        lead = f"{plural(len(rows), 'row').capitalize()} stand{'s' if len(rows) == 1 else ''} between here and the outcome" + (f", and {plural(len(unproven), 'acceptance row')} {'is' if len(unproven) == 1 else 'are'} unproven" if unproven else "") + f". {words(len(asks)).capitalize()} of the {words(len(rows))} {'is' if len(asks) == 1 else 'are'} yours."
    elif state == "waiting on others":
        who = sorted({STOP_WORD[G.stop_of(t, rec)] for t in stops})
        lead = f"Nothing for you here. {words(len(stops)).capitalize()} other hand{'s' if len(stops) != 1 else ''} hold it: {', '.join(who)}."
    elif state == "moving":
        lead = f"Moving. {plural(len(burst), 'row').capitalize()} the agent takes without stopping" + (f", then it stops for {STOP_WORD[G.stop_of(stops[0], rec)]}" if stops else ", then the goal is built") + "."
    elif state == "met":
        lead = f"Met in all but name. {'The one row is' if len(done) == 1 else f'All {words(len(done))} rows are'} closed and {'the one acceptance row is' if len(proven) == 1 else f'all {words(len(proven))} acceptance rows are'} proven."
    elif state == "drifting":
        lead = f"Drifting. Nothing has been written here for {int(G.drift(rec)[0])} days."
    elif state == "not started":
        lead = "Not started. No rows yet."
    else:
        lead = state.capitalize() + "."
    para(lead)
    # the asks, second person
    if asks or (unproven and not [t for t in rows if G.stop_of(t, rec) != "you"]) or stops:
        blank()
    for t in asks:
        para(f"{t['subject']}: {t['gate']['do']}.", glyph=STOP_GLYPH["you"])
    if not [t for t in rows if G.stop_of(t, rec) != "you"]:
        for a in unproven:
            is_callout = (a.get("source") or "").startswith("callout:")
            text = a["text"].split(": ", 1)[-1] if is_callout else a["text"]
            ask = ACCEPT_ASK.get(a["kind"], "check it and say so").capitalize()
            para(f"{ask}: {text}." + (" This is your callout to retire." if is_callout else ""), glyph=STOP_GLYPH["you"])
    for t in stops:
        st = G.stop_of(t, rec)
        reason = {"seat": f"{t.get('delegated_to')} holds it, unconfirmed", "peer": (t.get("note") or "awaiting a review"), "closure": t.get("closure", "")}[st]
        para(f"{t['subject']}: {reason}.", glyph=STOP_GLYPH[st])
    # the agent's own work, one sentence
    if burst or after or deferred:
        blank()
        bits = []
        if burst:
            ms = collections.Counter(next((milestone_emoji(m) for m in rec["milestones"] if m["id"] == t["milestone"]), "") for t in burst)
            bits.append(f"{plural(len(burst), 'row').capitalize()} the agent can take without stopping" + (": " + ", ".join(f"{n} under {e}" for e, n in ms.items() if e) if len(ms) > 1 else "") + ".")
        if after: bits.append(f"{words(len(after)).capitalize()} more wait behind them.")
        if deferred: bits.append(f"{words(len(deferred)).capitalize()} deferred: " + "; ".join(t["subject"] for t in deferred[:2]) + ".")
        if unproven and [t for t in rows if G.stop_of(t, rec) != "you"]:
            bits.append(f"{plural(len(unproven), 'acceptance row').capitalize()} wait{'s' if len(unproven) == 1 else ''} for the work to be built.")
        para(" ".join(bits), glyph="▶" if burst else "~")
    # the close
    tail = []
    if state == "met": tail.append(f"Say the word: gs met {rec['id'][:6]}.")
    elif state == "waiting on you" and not rows: tail.append(f"{plural(len(unproven), 'read').capitalize()} from met. Nothing else is in the way.")
    un = G.unconsumed_notes(rec)
    if un: tail.append(f"{plural(len(un), 'unread note').capitalize()}: gs notes {rec['id'][:6]}.")
    if tail:
        blank(); para(" ".join(tail))
    out.w("└" + "─" * (W - 2) + "┘")
    return state
