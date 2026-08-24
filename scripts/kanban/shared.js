// shared.js — the behaviour every kanban surface has in common.
//
// Same reason as shared.css: the theme toggle, the tooltip and the page nav
// were re-implemented per page, so a fix landed on one surface and not the
// others. This is the one copy. Charter: UI-CHARTER.md.

// ---------- theme ----------
const applyTheme = (t) => {
  document.documentElement.dataset.theme = t;
  document.body.dataset.theme = t;
  localStorage.setItem("kanban-theme", t);
};
const toggleTheme = () =>
  applyTheme(document.documentElement.dataset.theme === "dark" ? "light" : "dark");
applyTheme(localStorage.getItem("kanban-theme") || "dark");

// ---------- time ----------
// Seconds matter for something just written, which the drafts page knew and the
// others did not. Converged on the more informative of the two rather than on
// whichever happened to be lifted first.
const ago = (ms) => {
  const s = Math.max(0, (Date.now() - ms) / 1000);
  if (s < 90) return `${Math.round(s)}s`;
  if (s < 5400) return `${Math.round(s / 60)}m`;
  if (s < 172800) return `${Math.round(s / 3600)}h`;
  return `${Math.round(s / 86400)}d`;
};

// a path's varying end is its identity, so shortening drops the head
function tailTrim(el) {
  const full = el.dataset.tip || el.title || el.textContent;
  el.dataset.tip = full; el.removeAttribute("title");
  // Spend the width on the part that names the thing. Every caller here is a
  // path, and "/Users/<someone>/" is eighteen characters that are the same on
  // every row, so a squeezed element spent all of them and then trimmed away
  // the half that identifies it ("…627/.claude"). A shell prompt solved this
  // decades ago. The tooltip still carries the real path, untouched.
  el.textContent = full.replace(/^\/Users\/[^/]+(?=\/)/, "~");
  let guard = 300;
  while (el.scrollWidth > el.clientWidth && el.textContent.length > 12 && guard--) {
    el.textContent = "…" + el.textContent.replace(/^…/, "").slice(3);
  }
}

// ---------- the tooltip ----------
// Delegated on [data-tip], so a re-render never orphans a listener, and driven
// by data-tip rather than title= so nothing double-fires.
(function tooltip() {
  if (document.getElementById("tip")) return;
  const t = document.createElement("div");
  t.id = "tip"; t.setAttribute("role", "tooltip"); t.setAttribute("aria-hidden", "true");
  document.body.appendChild(t);
  let timer = null, forEl = null;
  const hide = () => {
    clearTimeout(timer); forEl = null;
    t.classList.remove("on"); t.setAttribute("aria-hidden", "true");
    setTimeout(() => { if (!forEl) t.style.display = "none"; }, 120);
  };
  const show = (el) => {
    const body = el.dataset.tip; if (!body) return;
    t.replaceChildren();
    if (el.dataset.tiph) {
      const h = document.createElement("b"); h.className = "tiph"; h.textContent = el.dataset.tiph; t.append(h);
    }
    t.append(document.createTextNode(body));
    forEl = el;
    const r = el.getBoundingClientRect();
    t.style.display = "block";
    const b = t.getBoundingClientRect();
    let top = r.bottom + 9, below = true;
    if (top + b.height > innerHeight - 8) { top = Math.max(8, r.top - b.height - 9); below = false; }
    const left = Math.min(Math.max(8, r.left), Math.max(8, innerWidth - b.width - 8));
    t.style.top = `${top}px`; t.style.left = `${left}px`;
    t.classList.toggle("below", below); t.classList.toggle("above", !below);
    t.style.setProperty("--ax", `${Math.min(Math.max(10, r.left + r.width / 2 - left - 4.5), Math.max(10, b.width - 19))}px`);
    t.classList.add("on"); t.setAttribute("aria-hidden", "false");
  };
  document.addEventListener("pointerover", (e) => {
    const el = e.target.closest?.("[data-tip]");
    if (!el || el === forEl) return;
    clearTimeout(timer);
    timer = setTimeout(() => show(el), 260);
  });
  document.addEventListener("pointerout", (e) => {
    const el = e.target.closest?.("[data-tip]");
    if (el && !el.contains(e.relatedTarget)) hide();
  });
  addEventListener("scroll", hide, true);
  addEventListener("keydown", (e) => { if (e.key === "Escape") hide(); });
})();

// ---------- one resize grip ----------
// The lanes, the right drawer and the left sidebar each grew their own copy of
// pointer capture, arrow keys and a persisted width. They differ only in which
// edge the grip hangs on, so this takes that as an argument. C11: the third
// copy is the one worth stopping.
//
// `width` reads the current size and `set` writes it (clamping and persistence
// belong to the caller, which knows its own floor). `before`/`after` exist for
// a surface that animates its width and must not animate a drag.
function wireGrip(grip, { width, set, edge = "right", step = 24, before, after } = {}) {
  if (!grip) return;
  let from = null;
  const sign = edge === "right" ? 1 : -1;
  grip.addEventListener("pointerdown", (e) => {
    from = { x: e.clientX, w: width() };
    grip.classList.add("on");
    if (before) before();
    try { grip.setPointerCapture(e.pointerId); } catch {}
    e.preventDefault(); e.stopPropagation();
  });
  grip.addEventListener("pointermove", (e) => {
    if (from) set(from.w + sign * (e.clientX - from.x));
  });
  const end = (e) => {
    if (!from) return;
    from = null; grip.classList.remove("on");
    if (after) after();
    try { grip.releasePointerCapture(e.pointerId); } catch {}
  };
  grip.addEventListener("pointerup", end);
  grip.addEventListener("pointercancel", end);
  // A grip nobody can tab to is not a control. The arrow that grows it is the
  // one pointing away from the edge it hangs on, so the key agrees with the drag.
  grip.tabIndex = 0;
  grip.addEventListener("keydown", (e) => {
    const grow = edge === "right" ? "ArrowRight" : "ArrowLeft";
    const shrink = edge === "right" ? "ArrowLeft" : "ArrowRight";
    if (e.key === grow) { set(width() + step); e.preventDefault(); }
    if (e.key === shrink) { set(width() - step); e.preventDefault(); }
  });
}

// ---------- the page chrome ----------
// Three views, reachable from all of them, with the same keys everywhere. The
// partial navigation graph was the audit's headline finding: you could not
// reach Asks from Drafts at all.
// The kinds' glyphs, keyed by id, built from the registry so the two cannot
// disagree. Kept as a name because three call sites already say NAV_ICON.x.
const NAV_ICON = Object.fromEntries(KINDS.map((k) => [k.id, k.icon]));
// one chevron, turned by CSS, so open and shut are one control rather than two
const CHEV_LR_ICON = `<svg width="14" height="14" viewBox="0 0 16 16" fill="none" aria-hidden="true"><path d="M9.8 3.5 5.3 8l4.5 4.5" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
const MARK_ICON = `<svg width="16" height="16" viewBox="0 0 16 16" fill="none"><rect x="1.6" y="2.4" width="4.6" height="11.2" rx="1.5" stroke="currentColor" stroke-width="1.3"/><rect x="7.6" y="2.4" width="4.6" height="7" rx="1.5" stroke="currentColor" stroke-width="1.3"/><path d="M14.4 5v6.6" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/></svg>`;
const HELP_ICON = `<svg width="15" height="15" viewBox="0 0 16 16" fill="none"><circle cx="8" cy="8" r="6.2" stroke="currentColor" stroke-width="1.3"/><path d="M6.3 6.2a1.75 1.75 0 1 1 1.9 1.85V9.4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/><circle cx="8.1" cy="11.6" r=".75" fill="currentColor"/></svg>`;
const CLOSE_ICON = `<svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="m4.6 4.6 6.8 6.8M11.4 4.6l-6.8 6.8" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/></svg>`;
const THEME_ICON = `<svg width="15" height="15" viewBox="0 0 16 16" fill="none"><circle cx="8" cy="8" r="5.6" stroke="currentColor" stroke-width="1.3"/><path d="M8 2.4a5.6 5.6 0 0 0 0 11.2V2.4Z" fill="currentColor"/></svg>`;

// `active` is one of boards | asks | drafts. `onView` is optional: a page that
// switches in place (the hub) handles its own two views; a page that does not
// (drafts) navigates.
//
// Three zones (UNIFIED-SURFACES phase 0). Left is who and where, middle is what
// you are looking for here, right is what is true on every page plus this page's
// own group. A page supplies its identity, its find control and its actions; it
// never re-implements the parts that must not move, which is what "I shouldn't
// lose access to common things in the navbar across" asks for.
//
// `find` and `actions` are elements the page owns and this mounts; `help` is a
// handler, and the help control is ABSENT rather than dead on a page that has no
// modal yet (charter §7 states: a control that cannot act is hidden, never
// silently greyed).
// Text going into markup. Every page needs it, and a second copy in a page's
// own script is a redeclaration error rather than a shadow.
const esc = (s) => String(s ?? "").replace(/[&<>"]/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

// The name a person would call a body of prose: its first real line, with a
// markdown heading's marks taken off. Without the strip a crumb reads
// "All drafts / ## gcc-work" and a picker row reads "# Claude Instances global
// wiring", showing the syntax instead of the name. Shared because the crumb,
// the picker and the drafts list all name things this way and drifted apart.
function firstLineName(body, cap = 72) {
  const first = (body || "").split("\n").find((l) => l.trim()) ?? "";
  return first.replace(/^\s*#{1,6}\s+/, "").replace(/^\s*[-*+]\s+/, "").trim().slice(0, cap);
}

// One address grammar, from NAV-UNIFICATION.md §1: `All <kind> / <instance>`.
// The left half is always a link to that kind's index, so wherever you are you
// can step up one level and then across. Its label comes from the registry, so
// a kind reads the same word here as it does on its tab.
//
// Pass no instance and you get the index's own crumb, which is the whole left
// half and no separator: a kind's index is not an instance of itself.
function crumbFor(kindId, instance) {
  const k = kindById(kindId);
  const wrap = document.createElement("span");
  wrap.className = "ncrumb";
  const a = document.createElement("a");
  a.href = k?.href ?? "/";
  a.textContent = `All ${k?.indexLabel ?? (k?.label ?? kindId).toLowerCase()}`;
  a.dataset.tip = k ? `${k.tip} · press ${k.key}` : "";
  wrap.append(a);
  if (instance) {
    const sep = document.createElement("span");
    sep.textContent = "/";
    const now = document.createElement("strong");
    now.className = "ncrumb-now";
    now.textContent = instance;
    wrap.append(sep, now);
  }
  return wrap;
}

// The tabs' counts. Charter §7 asks the toolbar to state which kind you are in
// WITH its counts, which is what makes it an indicator rather than a navigator.
// Each kind counts itself (kinds.js), so a new kind's tab arrives counted and
// no page keeps a tally of its own.
//
// One request per kind, once per page: a second caller gets the first one's
// promise. A kind that cannot be reached answers null, NOT zero — an unknown
// count is not a count of none (§12), and an empty pill is hidden rather than
// asserting an emptiness nothing verified.
// Every instance of every kind, loaded once per page. The tab counts, the
// palette and the board's search are three views of one question — what is
// there, of each kind — and each used to ask it separately, so a kind wired
// into one was missing from the others.
//
// One request per kind: a second caller gets the first one's promise. A kind
// that cannot be reached answers null, NOT an empty array, because an unknown
// list is not an empty one (§12) and callers must be able to tell them apart.
let kindIndexP = null;
function kindIndex({ fresh = false } = {}) {
  if (fresh) kindIndexP = null;
  if (kindIndexP) return kindIndexP;
  kindIndexP = Promise.all(KINDS.map(async (k) => {
    if (!k.api || !k.listOf) return [k.id, null];
    try { return [k.id, k.listOf(await (await fetch(k.api)).json())]; }
    catch { return [k.id, null]; }
  })).then(Object.fromEntries);
  return kindIndexP;
}

// The tabs' counts. Charter §7 asks the toolbar to state which kind you are in
// WITH its counts, which is what makes it an indicator rather than a navigator.
// It counts the very list the palette offers, so the pill and the list can
// never disagree.
const kindCounts = (opts) => kindIndex(opts).then((ix) =>
  Object.fromEntries(KINDS.map((k) => [k.id, ix[k.id]?.length ?? null])));

// How an instance of a kind reads and where it goes, in one place, so the
// palette and search show the same row for the same thing. `text` is what a
// query matches against; `row` is what a person sees; `href` is the instance's
// own address, which is the cell NAV-UNIFICATION.md drew as empty for every
// kind but boards.
const KIND_ROW = {
  boards: {
    text: (b) => `${b.name} ${b.root}`,
    row: (b) => ({ id: b.slug, name: b.name, sub: b.root }),
    href: (b) => `/b/${b.slug}`,
  },
  asks: {
    text: (i) => i.body ?? "",
    row: (i) => ({ id: i.id, name: firstLineName(i.body),
                   sub: i.boardName ? `on ${i.boardName}` : "unassigned" }),
    href: (i) => `/?v=asks#${encodeURIComponent(i.id)}`,
  },
  drafts: {
    text: (d) => `${d.title ?? ""} ${d.body ?? ""}`,
    row: (d) => ({ id: d.id, name: d.title || firstLineName(d.body) || "(untitled)",
                   sub: `${(d.body || "").split("\n").length}L` }),
    href: (d) => `/drafts?d=${encodeURIComponent(d.id)}`,
  },
};

// Kinds in the order a search should offer them, which is not the order the tab
// bar shows (kinds.js: searchRank).
const searchKinds = () => KINDS.filter((k) => KIND_ROW[k.id])
  .slice().sort((a, b) => (a.searchRank ?? 99) - (b.searchRank ?? 99));

// "a, b and c" — for sentences that must name what was searched.
const andList = (xs) => xs.length < 2 ? (xs[0] ?? "")
  : `${xs.slice(0, -1).join(", ")} and ${xs[xs.length - 1]}`;

// The instances of one kind that match a query, already shaped for a row. A
// kind with no adapter yet is simply absent rather than half-rendered.
function kindMatches(ix, kindId, q, cap) {
  const a = KIND_ROW[kindId], list = ix?.[kindId];
  if (!a || !list) return [];
  const t = (q || "").trim().toLowerCase();
  return list.filter((x) => !t || a.text(x).toLowerCase().includes(t))
             .slice(0, cap)
             .map((x) => ({ kind: kindId, href: a.href(x), ...a.row(x) }));
}

function navbar({ mount, active, title, sub, crumb, identity, find, actions, counts = {},
                  peers, help, onView, aside }) {
  const el = typeof mount === "string" ? document.querySelector(mount) : mount;
  if (!el) return null;
  // add, never replace: a page may already carry a class its own CSS reads
  // (the board styles .brow .crumb, and losing that class loses the crumb)
  el.classList.add("navbar");
  el.innerHTML =
    `<div class="nz nzid">` +
      `<button class="nlogo" id="nbHome" aria-label="home"` +
      ` data-tip="Every board, your asks and your drafts (g b)">${MARK_ICON}</button>` +
      (crumb ? `<span class="ncrumb">${crumb}</span>` : "") +
      (identity ? `<span class="nident" id="nbIdent"></span><span class="nstatus" id="nbStatus"></span>`
                : `<span class="ntx"><h1 id="nbTitle"></h1><span class="nsub" id="nbSub"></span></span>`) +
    `</div>` +
    `<div class="nz nzfind" id="nbFind"></div>` +
    `<div class="nz nzcommon">` +
      // The panel's own toggle, at the edge the panel meets. It stays exactly
      // here whether the panel is open or shut, so the control does not move
      // out from under the pointer that is using it; only the chevron turns.
      (aside ? `<button class="icon ghost nasidetog" id="nbAside"></button>` : "") +
      // Every kind this app has, from kinds.js. Label, route, key, tip and hue
      // all come from the one declaration, so a fourth kind is one entry there
      // and nothing here. The hue rides an inline custom property rather than a
      // CSS rule per kind, for the same reason: a rule per kind is a list.
      `<div class="views" role="tablist">` +
        KINDS.map((k) =>
          `<a href="${k.href}" data-v="${k.id}" data-k="${k.key}" role="tab"
              class="${k.id === active ? "on" : ""}" style="--nav-hue:var(${k.hue})"
              data-tip="${k.tip} · press ${k.key}">
             <span class="vi">${k.icon}</span><span class="vt">${k.label}</span>
             <span class="vn">${counts[k.id] ?? ""}</span></a>`).join("") +
      `</div>` +
      `<span class="npeers" id="nbPeers"></span>` +
      `<span class="npage" id="nbActions"></span>` +
      `<button class="icon ghost" id="nbTheme" data-tip="Light and dark (t)" aria-label="toggle theme">${THEME_ICON}</button>` +
      (help ? `<button class="icon ghost" id="nbHelp" data-tip="Shortcuts, terminology and how it works (?)" aria-label="help">${HELP_ICON}</button>` : "") +
    `</div>`;
  if (identity) document.getElementById("nbIdent").append(identity);
  else { document.getElementById("nbTitle").textContent = title ?? "";
         document.getElementById("nbSub").textContent = sub ?? ""; }
  if (aside) {
    const b = document.getElementById("nbAside");
    b.innerHTML = CHEV_LR_ICON;
    const paint = () => {
      const shut = aside.isCollapsed();
      b.classList.toggle("shut", shut);
      b.setAttribute("aria-label", shut ? "show the side panel" : "hide the side panel");
      b.setAttribute("aria-expanded", String(!shut));
      b.dataset.tip = (shut ? "Show the side panel" : "Hide the side panel") + " (|)";
    };
    b.onclick = () => { aside.toggle(); paint(); };
    paint();
    aside.repaint = paint;
  }
  document.getElementById("nbHome").onclick = () => { location.href = "/"; };
  document.getElementById("nbTheme").onclick = toggleTheme;
  if (help) document.getElementById("nbHelp").onclick = help;
  // A group that scrolls with no sign of it is a hidden control, and one that
  // overflows with no scroll at all paints on top of its neighbour. Marking
  // whether anything is really cut off lets the fade switch itself off, and the
  // re-measure matters because overflow is a function of the window rather than
  // of one render. Both scrolling groups in the bar want the same treatment.
  const markOverflow = (el) => {
    if (!el) return;
    const mark = () => el.dataset.of = el.scrollWidth > el.clientWidth + 1 ? "x" : "none";
    mark();
    if (typeof ResizeObserver === "function") new ResizeObserver(mark).observe(el);
    addEventListener("resize", mark);
  };
  if (find) { document.getElementById("nbFind").append(find); markOverflow(find); }
  if (actions) {
    const np = document.getElementById("nbActions");
    np.append(actions);
    markOverflow(np);
  }

  // The bar sheds in a fixed order when it runs out of room, instead of letting
  // whatever happens to sit last in the DOM fall off the right edge. On a board
  // with a longer name and two live peers, that was "Send to agent" — the point
  // of the whole app — while an ellipsised path kept its pixels.
  //
  // The signal is the page group scrolling: if this board's verbs do not fit,
  // the bar is over-subscribed. What goes first is the path, because the crumb
  // beside it already names the board, and then the tab labels, because a tab
  // is an indicator and a glyph with a count still says which kind you are in.
  // A control that has scrolled off says nothing at all.
  //
  // Hysteresis, because shedding changes the very width that decides to shed:
  // it tightens the moment anything is cut and loosens only once the slack is
  // wider than the labels cost, so it cannot flutter between the two states.
  // Measure the UN-SHED state every time and decide from that, rather than
  // asking how much slack is left: the zones flex, so they absorb every spare
  // pixel and the leftover is always zero whether or not there is room. Reading
  // it that way could only ever tighten, never loosen.
  //
  // Deterministic, so it settles: the same question is asked of the same state
  // and gets the same answer, which is what stops it flickering between the two.
  const tighten = () => {
    const np = document.getElementById("nbActions");
    if (!np || !np.firstChild) return;
    const was = el.dataset.tight;
    delete el.dataset.tight;
    const cutWithLabels = np.scrollWidth - np.clientWidth;   // forces the reflow
    if (cutWithLabels > 1) el.dataset.tight = "1";
    else if (was) delete el.dataset.tight;
  };
  tighten();
  // Observe the GROUP, not just the bar: the bar's own box does not change when
  // its contents grow, so watching only the bar meant this never re-ran once the
  // board's verbs and peers actually landed.
  if (typeof ResizeObserver === "function") {
    const ro = new ResizeObserver(tighten);
    ro.observe(el);
    const np = document.getElementById("nbActions");
    if (np) { ro.observe(np); new MutationObserver(tighten).observe(np, { childList: true, subtree: true }); }
  }
  addEventListener("resize", tighten);
  if (peers) document.getElementById("nbPeers").append(peers);
  // Counts land after first paint: the bar must not wait on a fetch per kind to
  // draw. A page may pass its own for a kind it already holds; anything it does
  // not name is asked for. Re-asked when the tab comes back into view, because
  // a count that was true when you left is the staleness §12 calls dishonest.
  const showCounts = (c) => el.querySelectorAll(".views a").forEach((a) => {
    const n = c[a.dataset.v];
    a.querySelector(".vn").textContent = n == null ? "" : n;
  });
  const loadCounts = (fresh) =>
    kindCounts({ fresh }).then((c) => showCounts({ ...c, ...counts }));
  loadCounts(false);
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") loadCounts(true);
  });
  // a page that switches in place intercepts; everything else navigates
  if (onView) {
    el.querySelectorAll(".views a").forEach((a) => {
      a.onclick = (e) => {
        const v = a.dataset.v;
        // Whether a kind switches in place or navigates is the kind's own
        // property, not a name check against one id.
        if (!kindById(v)?.inPage) return;        // a real page, let it navigate
        e.preventDefault(); onView(v);
      };
    });
  }
  return el;
}

// g-then-a-letter, for pages that do not own their key map. The board does own
// it, and `g` there already edits a card's goal, so the board reaches the same
// places with `b` (its go-to picker) instead. One letter, two meanings, and the
// page that got there first keeps it.
let gArmed = null;
// g-then-first-letter, derived: a new kind gets its letter for free unless one
// is taken, and the board owns `g` for a card's goal so it uses `b` instead.
const GO = Object.fromEntries(KINDS.map((k) => [k.id[0], k.href]));

// ---------- help tabs any surface can host ----------
// Two of the board's tabs say nothing board-specific. The charter is one file
// every page can render, and a term entry has the same shape whatever surface
// owns the word, so both are tab specs rather than markup a page copies.
const HTAB_ICON_TERMS = `<svg width="15" height="15" viewBox="0 0 16 16" fill="none"><path d="M2.4 3.2A1.4 1.4 0 0 1 3.8 1.8H8v12.4H3.8a1.4 1.4 0 0 1-1.4-1.4V3.2ZM8 1.8h4.2a1.4 1.4 0 0 1 1.4 1.4v9.6a1.4 1.4 0 0 1-1.4 1.4H8" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/></svg>`;
const HTAB_ICON_CHARTER = `<svg width="15" height="15" viewBox="0 0 16 16" fill="none"><path d="M3.9 1.9v12.2" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/><path d="M3.9 2.7h8.4l-1.9 2.7 1.9 2.7H3.9" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/></svg>`;

// Renders UI-CHARTER.md rather than restating it. A copy of its rulings kept
// per page would be the charter's own anti-pattern, "a second list of what the
// first list already says", and wrong the first time a ruling landed.
const charterTab = () => ({
  id: "charter", label: "Charter", sub: "What we agreed", icon: HTAB_ICON_CHARTER,
  build: async (pane) => {
    if (!pane || pane.dataset.built) return;
    pane.innerHTML = `<div class="cnote">Reading UI-CHARTER.md\u2026</div>`;
    try {
      const res = await fetch("/api/charter");
      const out = await res.json();
      if (!res.ok) throw new Error(out.error ?? `HTTP ${res.status}`);
      pane.innerHTML = `<div class="cdoc">${out.html}</div>`;
      pane.dataset.built = "1";
    } catch (e) {
      // An empty pane would read as "the charter says nothing", which is the
      // worse of the two wrong answers.
      pane.innerHTML = `<div class="cnote">The charter could not be read: ${esc(e.message)}.
        It lives beside the server as UI-CHARTER.md.</div>`;
    }
  },
});

// One entry per thing this surface has a word for: what it is, what it sits
// next to, and the two sentences that stop it being misused. A term with no
// vignette drawn for it gets one column rather than an empty framed box.
const termsTab = (terms, { intro = "" } = {}) => ({
  id: "terms", label: "Taxonomy", sub: "What is it called", icon: HTAB_ICON_TERMS,
  build: (pane) => {
    if (!pane || pane.dataset.built) return;
    pane.innerHTML = intro + terms.map((t) => `
      <div class="term${t.vig ? "" : " novig"}">
        ${t.vig ? `<div class="shot">${t.vig}</div>` : ""}
        <div>
          <h4>${esc(t.title)}</h4>
          <p>${esc(t.p)}</p>
          ${t.rel?.length ? `<div class="rel">${t.rel.map((r) =>
            `<span class="chip tag k-plain" style="pointer-events:none"><i class="tdot"></i><span>${esc(r)}</span></span>`).join("")}</div>` : ""}
          <div class="use">
            <span class="do"><b>Do</b><i>${esc(t.do)}</i></span>
            <span class="dont"><b>Not</b><i>${esc(t.dont)}</i></span>
          </div>
        </div>
      </div>`).join("");
    pane.dataset.built = "1";
  },
});

// ---------- the help modal ----------
// The board's modal is the one the owner asked to reuse, so this is that shape
// rather than a new one: a titled dialog, a tab strip on the quieter ground,
// one scrolling pane at a time, Esc the only way out.
//
// Two ways in, because the board's panes are long hand-written tables and
// moving them into JavaScript would be a rewrite, not a reuse. A page that
// already has the markup gets ADOPTED — this takes over the tab strip, the
// close and the Escape, and leaves the panes alone. A page that has none gets
// one BUILT from a tab spec. Either way the behaviour has one implementation.
function helpModal({ id = "help", title = "Help", sub = "", tabs = [], onOpen, onShow } = {}) {
  let el = document.getElementById(id);
  const adopted = !!el;
  if (!el) {
    el = document.createElement("div");
    el.id = id;
    el.setAttribute("role", "dialog");
    el.setAttribute("aria-modal", "true");
    el.setAttribute("aria-label", "help");
    el.innerHTML =
      `<div class="box">` +
        `<div class="htitle"><span class="hmark">${MARK_ICON}</span>` +
          `<span class="htx"><b></b><i></i></span><span class="hsp"></span>` +
          `<button class="hclose icon" type="button" aria-label="close" data-tip="Close (Esc)">${CLOSE_ICON}</button></div>` +
        (tabs.length > 1 ? `<div class="htabs" role="tablist">` +
          tabs.map((t, i) => `<button class="htab${i ? "" : " on"}" data-pane="${id}-${t.id}" role="tab"` +
            ` aria-selected="${i ? "false" : "true"}"><span class="hi">${t.icon ?? ""}</span>` +
            `<span class="ht"><b></b><i></i></span></button>`).join("") +
        `</div>` : "") +
        tabs.map((t, i) => `<div class="hpane${i ? "" : " on"}" id="${id}-${t.id}" role="tabpanel"></div>`).join("") +
      `</div>`;
    document.body.appendChild(el);
    el.querySelector(".htitle .htx b").textContent = title;
    el.querySelector(".htitle .htx i").textContent = sub;
    // textContent, not innerHTML: a label is a label, never markup
    [...el.querySelectorAll(".htab")].forEach((b, i) => {
      b.querySelector(".ht b").textContent = tabs[i].label;
      b.querySelector(".ht i").textContent = tabs[i].sub ?? "";
    });
  }
  const panes = () => [...el.querySelectorAll(".hpane")];
  const strip = () => [...el.querySelectorAll(".htab")];
  const show = (tab) => {
    strip().forEach((t) => { const on = t === tab;
      t.classList.toggle("on", on); t.setAttribute("aria-selected", String(on)); });
    panes().forEach((p) => p.classList.toggle("on", p.id === tab.dataset.pane));
    // a host may fill a pane the first time it is shown rather than up front
    if (onShow) onShow(tab.dataset.pane, document.getElementById(tab.dataset.pane));
  };
  const close = () => { if (el.style.display !== "flex") return; el.style.display = "none"; };
  const open = () => {
    if (el.style.display === "flex") return close();
    el.style.display = "flex";
    tabs.forEach((t) => { if (t.build) t.build(document.getElementById(`${id}-${t.id}`)); });
    if (onOpen) onOpen(el);
    strip()[0]?.focus();
  };
  strip().forEach((t) => { t.onclick = () => show(t); });
  if (!adopted) {
    el.querySelector(".hclose")?.addEventListener("click", close);
    // Esc only, and only when this one is open (charter §9)
    addEventListener("keydown", (e) => { if (e.key === "Escape" && el.style.display === "flex") close(); });
  }
  return { el, open, close, show, adopted };
}

// The keys THIS file binds, written once. helpModal() renders them, so the
// reference and the behaviour cannot disagree: change a binding above and the
// modal changes with it.
const SHARED_KEYS = [
  { group: "Go", rows: [["1", "Boards"], ["2", "Your asks"], ["3", "Drafts"],
                        ["g b", "the hub"], ["g a", "your asks"], ["g d", "drafts"]] },
  { group: "Everywhere", rows: [["t", "light and dark"], ["?", "this reference"],
                                ["esc", "close it"]] },
];
const keysTable = (groups) => `<table><tbody>` + groups.map((g) =>
  `<tr><td colspan="2" class="grouphead"></td></tr>` +
  g.rows.map(() => `<tr><td></td><td></td></tr>`).join("")).join("") + `</tbody></table>`;
// built as structure first and filled as text, so a label can never be markup
function fillKeys(pane, groups) {
  pane.innerHTML = keysTable(groups);
  const rows = [...pane.querySelectorAll("tr")];
  let i = 0;
  for (const g of groups) {
    rows[i++].querySelector("td").textContent = g.group;
    for (const [key, what] of g.rows) {
      const tds = rows[i++].querySelectorAll("td");
      tds[0].replaceChildren(...key.split(" ").map((k) => {
        const el = document.createElement("kbd"); el.textContent = k; return el; }));
      tds[1].textContent = what;
    }
  }
}

// ? opens the page's help, on every page that mounted one
let theHelp = null;
const registerHelp = (h) => { theHelp = h; return h; };

// One key map for all three, so the entrance behaves like the board.
// A page that already owns a richer key map says so with data-keys="own" on
// <html> and handles t and the view digits itself. The board does: its keys are
// suppressed while a modal, a picker or the note popover is open, and this
// handler has no such guard, so without the opt-out t would fire twice and would
// fire inside overlays that deliberately swallow it.
addEventListener("keydown", (e) => {
  if (document.documentElement.dataset.keys === "own") return;
  // optional call: a keydown whose target is the document has no .matches, and
  // the throw used to take the whole handler with it
  if (e.target.matches?.("input,textarea,[contenteditable]")) return;
  if (e.metaKey || e.ctrlKey || e.altKey) return;
  if (gArmed) { clearTimeout(gArmed); gArmed = null;
    if (GO[e.key]) { location.href = GO[e.key]; return; } }
  if (e.key === "g") { gArmed = setTimeout(() => { gArmed = null; }, 1400); return; }
  if (e.key === "?" && theHelp) { theHelp.open(); return; }
  if (e.key === "t") return toggleTheme();
  const hit = document.querySelector(`.views a[data-k="${e.key}"]`);
  if (hit) hit.click();
});
